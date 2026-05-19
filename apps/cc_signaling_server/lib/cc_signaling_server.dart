/// A pure-Dart, stateless WebSocket signaling broker for WebRTC pairing.
///
/// The Control Center desktop app and the `cc_remote` phone PWA rendezvous
/// through this broker to exchange opaque SDP/ICE blobs before establishing a
/// direct, end-to-end-encrypted WebRTC data channel. The broker is a **dumb
/// relay**: it understands `join` / `signal` / `bye` from a client and emits
/// `joined` / `peer-joined` / `peer-left` / `error` of its own, but it **never**
/// inspects, stores, or interprets a `signal` payload. It holds no application
/// data and never sees the pairing pre-shared key (PSK).
///
/// Rooms are keyed by the pairing code and hold at most
/// [SignalingBroker.maxPeersPerRoom] connected peers (2). A room is created on
/// the first `join` and torn down by a periodic sweep once it is idle (no
/// peers) or never filled past its TTL.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';

/// Default port the CLI binds when `--port` is not supplied.
const int defaultSignalingPort = 8788;

/// Default network interface the CLI binds when `--host` is not supplied.
const String defaultSignalingHost = '0.0.0.0';

/// A stateless WebSocket signaling relay for WebRTC pairing.
///
/// One [SignalingBroker] instance safely serves many concurrent connections;
/// Dart's single-threaded event loop serializes per-socket events, so no locks
/// are required. Construct one, call [start] to run the periodic garbage
/// collector (or drive [sweep] yourself with an injected clock in tests), and
/// feed every upgraded WebSocket to [handleConnection].
///
/// Wire protocol (all frames are JSON objects; only `type` is interpreted):
///
/// * Client → broker:
///   * `{"type":"join","room":"<code>","from":"<peerId>"}` — enter a room.
///   * `{"type":"signal","room","from","to"?,"kind","payload":{...}}` — relay
///     an opaque SDP/ICE blob to the other peer(s) verbatim.
///   * `{"type":"bye","room"}` — leave the room.
/// * Broker → client:
///   * `{"type":"joined","room":"<code>"}` — join ack.
///   * `{"type":"peer-joined","room":"<code>"}` — the room is now shared (sent
///     symmetrically to **both** peers the moment a second peer joins, so an
///     offerer can fire its offer on this regardless of join order).
///   * `{"type":"peer-left","room":"<code>","from":"<peerId>"}` — the named
///     peer left.
///   * `{"type":"error","error":"<message>"}` — e.g. `room full`.
class SignalingBroker {
  /// Creates a broker.
  ///
  /// [neverFilledTtl] reaps a room that never reached capacity this long after
  /// it was created (default 5 minutes). [idleTtl] reaps an empty room this
  /// long after its last peer left (default 60 seconds). [gcInterval] paces the
  /// periodic sweep started by [start]. Inject [now] for a deterministic clock
  /// and [log] to capture diagnostics in tests.
  SignalingBroker({
    this.maxPeersPerRoom = 2,
    this.maxRooms = 4096,
    this.maxConnections = 8192,
    this.maxFrameBytes = 64 * 1024,
    this.maxFramesPerWindow = 200,
    this.rateWindow = const Duration(seconds: 10),
    this.neverFilledTtl = const Duration(minutes: 5),
    this.idleTtl = const Duration(seconds: 60),
    this.gcInterval = const Duration(seconds: 30),
    DateTime Function()? now,
    void Function(String message)? log,
  }) : _now = now ?? DateTime.now,
       _log = log ?? _noopLog;

  /// Maximum number of connected peers a room will accept.
  final int maxPeersPerRoom;

  /// Hard cap on concurrently-tracked rooms. A new room beyond this is refused,
  /// so a flood of unique room codes can't exhaust memory/fds (finding #15).
  final int maxRooms;

  /// Hard cap on concurrently-open WebSocket connections. Beyond this, new
  /// upgrades are refused (finding #15).
  final int maxConnections;

  /// Maximum accepted size (bytes/chars) of a single inbound frame before JSON
  /// decode. A signaling frame is small SDP/ICE JSON; an oversized frame is
  /// dropped rather than decoded (CPU/memory DoS guard, finding #15).
  final int maxFrameBytes;

  /// Per-connection frame budget within [rateWindow]. Frames beyond the budget
  /// are dropped (token-bucket-style flood guard, finding #15).
  final int maxFramesPerWindow;

  /// Sliding window over which [maxFramesPerWindow] is counted.
  final Duration rateWindow;

  /// A room that never reached [maxPeersPerRoom] is reaped this long after it
  /// was created.
  final Duration neverFilledTtl;

  /// A room with zero peers is reaped this long after its last peer left.
  final Duration idleTtl;

  /// Cadence of the periodic garbage-collection sweep started by [start].
  final Duration gcInterval;

  final DateTime Function() _now;
  final void Function(String message) _log;

  final Map<String, _Room> _rooms = {};
  int _connectionCount = 0;
  Timer? _gcTimer;
  bool _closed = false;

  /// The number of WebSocket connections currently open.
  int get connectionCount => _connectionCount;

  /// Starts the periodic garbage collector. Idempotent.
  void start() {
    if (_closed) {
      return;
    }
    _gcTimer ??= Timer.periodic(gcInterval, (_) => sweep());
  }

  /// Whether a room with [code] currently exists.
  bool roomExists(String code) => _rooms.containsKey(code);

  /// The number of rooms currently tracked.
  int get roomCount => _rooms.length;

  /// The number of peers currently connected in [code]'s room (0 if absent).
  int peerCount(String code) => _rooms[code]?.peers.length ?? 0;

  /// Runs one garbage-collection sweep and returns the number of rooms reaped.
  ///
  /// A room is reaped when it has no peers and has been idle longer than
  /// [idleTtl], or when it never reached capacity and is older than
  /// [neverFilledTtl]. Reaped rooms that still hold a live peer have that
  /// peer's socket closed.
  int sweep() {
    if (_closed) {
      return 0;
    }
    final now = _now();
    final reaped = <String>[];
    for (final entry in _rooms.entries) {
      final room = entry.value;
      final age = now.difference(room.createdAt);
      final idle = now.difference(room.lastActivityAt);
      final empty = room.peers.isEmpty;
      final reap =
          (empty && idle > idleTtl) ||
          (!room.everFilled && age > neverFilledTtl);
      if (reap) {
        reaped.add(entry.key);
        for (final p in room.peers) {
          p.removed = true;
          _closeQuietly(p.socket);
        }
      }
    }
    for (final code in reaped) {
      _rooms.remove(code);
    }
    return reaped.length;
  }

  /// Serves one WebSocket connection (one peer) for its lifetime.
  ///
  /// The peer must send a `join` frame before signaling. The returned future
  /// completes when the socket closes; it never completes with an error.
  Future<void> handleConnection(WebSocket socket) async {
    // Connection cap (finding #15): refuse new sockets past the limit so a flood
    // can't exhaust fds/memory. The broker is treated as untrusted/unreliable,
    // so this is a self-protection backstop, not the security boundary.
    if (_closed || _connectionCount >= maxConnections) {
      _send(socket, const <String, dynamic>{
        'type': 'error',
        'error': 'server busy',
      });
      _closeQuietly(socket);
      return;
    }
    _connectionCount++;

    String? roomCode;
    _Peer? self;
    var detached = false;

    // Per-connection sliding-window rate limit (finding #15): drop frames that
    // exceed the budget rather than letting one socket spin CPU.
    final rateHits = Queue<DateTime>();
    bool withinRate() {
      final now = _now();
      final cutoff = now.subtract(rateWindow);
      while (rateHits.isNotEmpty && !rateHits.first.isAfter(cutoff)) {
        rateHits.removeFirst();
      }
      if (rateHits.length >= maxFramesPerWindow) {
        return false;
      }
      rateHits.add(now);
      return true;
    }

    void cleanup() {
      if (detached) {
        return;
      }
      detached = true;
      final code = roomCode;
      final peer = self;
      roomCode = null;
      self = null;
      if (code != null && peer != null) {
        _leave(code, peer, notify: true);
      }
    }

    final done = Completer<void>();
    final subscription = socket.listen(
      (dynamic data) {
        if (!withinRate()) {
          _log('rate limit exceeded on a connection, dropping frame');
          return;
        }
        final frame = _decode(data);
        if (frame == null) {
          return;
        }
        final type = frame['type'] as Object?;
        if (type == 'join') {
          if (roomCode != null) {
            _send(socket, const <String, dynamic>{
              'type': 'error',
              'error': 'already joined',
            });
            return;
          }
          final joined = _handleJoin(socket, frame);
          if (joined != null) {
            roomCode = joined.code;
            self = joined.peer;
          }
        } else if (type == 'signal') {
          _handleSignal(frame, roomCode, self);
        } else if (type == 'bye') {
          final code = roomCode;
          final peer = self;
          roomCode = null;
          self = null;
          if (code != null && peer != null) {
            _leave(code, peer, notify: true);
          }
          _closeQuietly(socket);
        } else {
          _log('unknown frame type ${jsonEncode(type)}, ignoring');
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _log('socket error: $error');
      },
      onDone: done.complete,
    );

    try {
      await done.future;
    } finally {
      cleanup();
      await subscription.cancel();
      _connectionCount--;
    }
  }

  /// Stops the garbage collector, closes every live peer socket, and clears all
  /// rooms. The broker is unusable after this.
  Future<void> close() async {
    _closed = true;
    _gcTimer?.cancel();
    _gcTimer = null;
    for (final room in _rooms.values) {
      for (final p in room.peers) {
        p.removed = true;
        _closeQuietly(p.socket);
      }
    }
    _rooms.clear();
  }

  _JoinResult? _handleJoin(WebSocket socket, Map<String, dynamic> frame) {
    final code = _string(frame['room']);
    final peerId = _string(frame['from']);
    if (code == null || peerId == null) {
      _send(socket, const <String, dynamic>{
        'type': 'error',
        'error': 'invalid join',
      });
      _closeQuietly(socket);
      return null;
    }
    // Room cap (finding #15): refuse to create a NEW room past the limit so a
    // flood of unique room codes can't exhaust memory. Joining an existing room
    // is unaffected.
    if (!_rooms.containsKey(code) && _rooms.length >= maxRooms) {
      _send(socket, const <String, dynamic>{
        'type': 'error',
        'error': 'server busy',
      });
      _closeQuietly(socket);
      return null;
    }
    final room = _rooms.putIfAbsent(code, () => _Room(code, _now()));
    // Same-peer-id eviction: a join carrying an id already present in the room
    // is the same logical peer reconnecting (a desktop re-establishing signaling
    // after a blip, or a duplicate join from a transient second instance). Drop
    // the stale connection so the newcomer claims its slot instead of bouncing
    // off "room full". The evicted socket's own cleanup is a no-op — it has
    // already been removed here — so no spurious `peer-left` is emitted.
    final stale = room.peers.where((p) => p.id == peerId).toList();
    for (final p in stale) {
      p.removed = true;
      room.peers.remove(p);
      _closeQuietly(p.socket);
      _log('evicted stale peer "$peerId" from room "$code" (reconnect)');
    }
    if (room.peers.length >= maxPeersPerRoom) {
      _send(socket, const <String, dynamic>{
        'type': 'error',
        'error': 'room full',
      });
      _closeQuietly(socket);
      return null;
    }
    final peer = _Peer(peerId, socket);
    final wasOccupied = room.peers.isNotEmpty;
    room.peers.add(peer);
    room.lastActivityAt = _now();
    if (room.peers.length >= maxPeersPerRoom) {
      room.everFilled = true;
    }
    _send(socket, <String, dynamic>{'type': 'joined', 'room': code});
    // Symmetric peer-joined: the moment a room becomes shared, both peers are
    // notified — the existing peer learns a peer arrived, and the new joiner
    // learns a peer is already present. An offerer can therefore fire its offer
    // on peer-joined regardless of which side joined first.
    if (wasOccupied) {
      for (final p in room.peers) {
        _send(p.socket, <String, dynamic>{'type': 'peer-joined', 'room': code});
      }
    }
    return _JoinResult(code, peer);
  }

  void _handleSignal(
    Map<String, dynamic> frame,
    String? roomCode,
    _Peer? self,
  ) {
    if (roomCode == null || self == null) {
      _log('signal from a peer that has not joined, dropping');
      return;
    }
    final room = _rooms[roomCode];
    if (room == null) {
      _log('signal for missing room "$roomCode", dropping');
      return;
    }
    final to = _string(frame['to']);
    var delivered = false;
    for (final p in room.peers) {
      if (identical(p, self)) {
        continue;
      }
      if (to != null && p.id != to) {
        continue;
      }
      _send(p.socket, frame);
      delivered = true;
    }
    if (!delivered) {
      _log('signal with no recipient in room "$roomCode", dropping');
    }
  }

  void _leave(String roomCode, _Peer peer, {required bool notify}) {
    final room = _rooms[roomCode];
    if (room == null) {
      return;
    }
    if (!room.peers.remove(peer)) {
      return;
    }
    peer.removed = true;
    room.lastActivityAt = _now();
    if (notify) {
      for (final p in room.peers) {
        _send(p.socket, <String, dynamic>{
          'type': 'peer-left',
          'room': roomCode,
          // The leaver's id lets the remaining peer ignore a stale `peer-left`
          // from a superseded connection — e.g. a phone refresh where the new
          // tab's offer races ahead of the old socket's close — instead of
          // tearing down the connection it just established.
          'from': peer.id,
        });
      }
    }
    // Empty rooms are intentionally left in place for the idle GC sweep to reap.
  }

  void _send(WebSocket socket, Map<String, dynamic> frame) {
    if (socket.readyState != WebSocket.open) {
      return;
    }
    try {
      socket.add(jsonEncode(frame));
    } catch (error) {
      _log('failed to send frame: $error');
    }
  }

  void _closeQuietly(WebSocket socket) {
    if (socket.readyState == WebSocket.open) {
      unawaited(socket.close());
    }
  }

  Map<String, dynamic>? _decode(dynamic data) {
    String text;
    if (data is String) {
      // Reject an oversized frame before decode (finding #15) — signaling JSON is
      // small; anything this large is abusive.
      if (data.length > maxFrameBytes) {
        _log('frame exceeds $maxFrameBytes bytes, dropping');
        return null;
      }
      text = data;
    } else if (data is List<int>) {
      if (data.length > maxFrameBytes) {
        _log('frame exceeds $maxFrameBytes bytes, dropping');
        return null;
      }
      text = utf8.decode(data);
    } else {
      _log('unsupported frame encoding, ignoring');
      return null;
    }
    try {
      final decoded = jsonDecode(text);
      if (decoded is! Map<String, dynamic>) {
        _log('frame is not a JSON object, ignoring');
        return null;
      }
      return decoded;
    } catch (error) {
      _log('malformed JSON frame, ignoring: $error');
      return null;
    }
  }
}

/// Resolves a JSON value to a [String], or null when missing or non-string.
String? _string(Object? value) => value is String ? value : null;

void _noopLog(String message) {}

/// The room code and peer object produced by a successful join.
class _JoinResult {
  _JoinResult(this.code, this.peer);

  /// The joined room code.
  final String code;

  /// The peer object added to the room.
  final _Peer peer;
}

/// One connected WebSocket peer within a room.
class _Peer {
  _Peer(this.id, this.socket);

  /// The peer id supplied in the join frame.
  final String id;

  /// The live WebSocket.
  final WebSocket socket;

  /// Whether this peer has been removed from its room (guards double cleanup).
  bool removed = false;
}

/// One signaling room holding at most [SignalingBroker.maxPeersPerRoom] peers.
class _Room {
  _Room(this.code, DateTime createdAt)
    : createdAt = createdAt,
      lastActivityAt = createdAt;

  /// The room code (the pairing code).
  final String code;

  /// When the room was created (first join).
  final DateTime createdAt;

  /// Updated on every join/leave; used for idle GC.
  DateTime lastActivityAt;

  /// The connected peers (at most [SignalingBroker.maxPeersPerRoom]).
  final List<_Peer> peers = [];

  /// Whether the room ever reached capacity.
  bool everFilled = false;
}

/// A bound [HttpServer] and the [SignalingBroker] serving it.
///
/// Returned by [serveSignaling] so callers (and tests) can read the chosen
/// [port] and shut both down together via [close].
class SignalingServerHandle {
  /// Creates a handle wrapping [server] and [broker].
  SignalingServerHandle({required this.server, required this.broker});

  /// The bound HTTP server upgrading WebSocket requests.
  final HttpServer server;

  /// The broker relaying signaling for [server].
  final SignalingBroker broker;

  /// The actual port the server bound (equal to the requested port unless 0).
  int get port => server.port;

  /// Closes the broker and the server.
  Future<void> close() async {
    await broker.close();
    await server.close(force: true);
  }
}

/// Binds an [HttpServer] that upgrades WebSocket requests at any path and hands
/// each connection to a [SignalingBroker].
///
/// Pass [port] `0` to bind an ephemeral port and read the chosen value from the
/// returned handle's [SignalingServerHandle.port]. When [broker] is omitted a
/// new one is created with default TTLs and its garbage collector is started.
/// [log] receives diagnostics from the serve loop (the broker itself uses its
/// own injected `log` callback).
Future<SignalingServerHandle> serveSignaling({
  Object host = defaultSignalingHost,
  int port = defaultSignalingPort,
  SignalingBroker? broker,
  void Function(String message)? log,
}) async {
  final logger = log ?? _noopLog;
  final effective = broker ?? (SignalingBroker(log: logger)..start());
  // HttpServer.bind accepts either an [InternetAddress] or a hostname string;
  // passing the host through verbatim keeps "localhost"/"0.0.0.0" working.
  final server = await HttpServer.bind(host, port);
  unawaited(_serveLoop(server, effective, logger));
  return SignalingServerHandle(server: server, broker: effective);
}

Future<void> _serveLoop(
  HttpServer server,
  SignalingBroker broker,
  void Function(String message) log,
) async {
  await for (final request in server) {
    if (!WebSocketTransformer.isUpgradeRequest(request)) {
      request.response
        ..statusCode = HttpStatus.badRequest
        ..write('WebSocket upgrade required.');
      await request.response.close();
      continue;
    }
    try {
      final socket = await WebSocketTransformer.upgrade(request);
      unawaited(broker.handleConnection(socket));
    } catch (error) {
      log('websocket upgrade failed: $error');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {
        // Response already torn down by the failed upgrade.
      }
    }
  }
}
