/// A pure-Dart, stateless WebSocket signaling broker for Control Center.
///
/// cc_server and its clients (desktop, web, phone) rendezvous through this
/// broker when the server is not directly reachable: the server joins its
/// relay room as the **owner** and every client joins with an **admission
/// token**; JSON-RPC frames then relay as opaque, end-to-end-encrypted
/// `signal` payloads. The broker is a **dumb relay**: it understands
/// `join` / `signal` / `admit` / `turn-request` / `bye` from a client and
/// emits `joined` / `admit-ok` / `peer-joined` / `peer-left` /
/// `turn-credentials` / `error` of its own, but it **never** inspects,
/// stores, or interprets a `signal` payload. It holds no application data and
/// never sees a pairing PSK — admission tokens are one-way HMAC derivations
/// of a device PSK, useless for anything but room admission, and the frames
/// it forwards are sealed (`RelayFrameCrypto`) before they reach it.
///
/// ## Room model (N-capacity, invite-gated)
///
/// Rooms are keyed by the server's relay room code (≥128-bit entropy) and
/// hold at most [SignalingBroker.maxPeersPerRoom] peers (default 16): one
/// **owner** (the cc_server) plus N clients.
///
/// * The owner joins with `owner: true` and an `ownerToken`; the broker
///   stores only `sha256(ownerToken)` at room creation and verifies the
///   preimage on every re-claim, so a wedged owner socket can always be
///   superseded by the real server but never by a client.
/// * A client join MUST carry a `token` whose `sha256` hex is in the room's
///   admitted set — published and updated by the owner via `admit` frames.
///   "Knows the room id" is NOT sufficient admission (PRD 15 §4): a joiner
///   with a valid room id but no invite-derived token is refused before any
///   frame is relayed, with the uniform error `not admitted` (which is also
///   the answer for a nonexistent room, so the broker is not a room oracle).
/// * Removing an admission hash evicts any connected peer that joined with
///   it (live revocation).
///
/// ### Trust model
///
/// The broker is untrusted for confidentiality and integrity (E2E crypto and
/// the mutual PSK handshake carry those) and is only a best-effort
/// availability dependency. A hostile party that learns a room id can squat
/// it by claiming ownership first; the legitimate server detects this as an
/// `owner conflict` and surfaces it loudly. Squatting yields no data — every
/// relayed frame is ciphertext under per-device keys the squatter lacks.
///
/// ## TURN credential issuance (PRD 15 §3)
///
/// When started with a coturn shared secret, the broker mints short-lived
/// TURN credentials for admitted room members on request, using coturn's
/// `static-auth-secret` HMAC-SHA1 scheme (`username = <expiry>:<label>`,
/// `credential = base64(HMAC-SHA1(secret, username))`). Credentials are
/// ephemeral by construction — never stored, never reused across requests.
library;

import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Default port the CLI binds when `--port` is not supplied.
const int defaultSignalingPort = 8788;

/// Default network interface the CLI binds when `--host` is not supplied.
const String defaultSignalingHost = '0.0.0.0';

/// A stateless WebSocket signaling relay with invite-gated N-capacity rooms.
///
/// One [SignalingBroker] instance safely serves many concurrent connections;
/// Dart's single-threaded event loop serializes per-socket events, so no
/// locks are required. Construct one, call [start] to run the periodic
/// garbage collector (or drive [sweep] yourself with an injected clock in
/// tests), and feed every upgraded WebSocket to [handleConnection].
///
/// Wire protocol (all frames are JSON objects; only broker-owned fields are
/// interpreted — `signal` payloads relay verbatim):
///
/// * Client → broker:
///   * `{"type":"join","room","from","owner":true,"ownerToken","admit":[..]}`
///     — claim/create a room as its owner (the server). `admit` (optional)
///     replaces the room's admitted-hash set.
///   * `{"type":"join","room","from","token":"<preimage>"}` — enter a room
///     as a client; `sha256(token)` must be admitted.
///   * `{"type":"admit","room","add":[..],"remove":[..]}` — owner-only
///     admission update; removing a hash evicts its connected peer.
///   * `{"type":"signal","room","from","to"?,"kind","payload":{...}}` —
///     relay an opaque blob. `from` is overwritten with the sender's joined
///     id (no in-room spoofing); `to` targets one peer, otherwise the frame
///     goes to every other peer.
///   * `{"type":"turn-request","room"}` — mint TURN credentials (members
///     only; empty `uris` when the broker has no TURN configured).
///   * `{"type":"bye","room"}` — leave the room.
/// * Broker → client:
///   * `{"type":"joined","room","owner":you-are-owner,"ownerPresent":bool,
///     "ownerPeer":id?,"peers":other-count}` — join ack.
///   * `{"type":"admit-ok","room","count":admitted-hash-count}`.
///   * `{"type":"peer-joined","room","from":peerId,"owner":bool}` —
///     sent to every existing peer when someone joins.
///   * `{"type":"peer-left","room","from":peerId,"owner":bool}`.
///   * `{"type":"turn-credentials","room","uris":[..],"username",
///     "credential","ttlSeconds"}`.
///   * `{"type":"error","error":"<message>"}` — `not admitted`,
///     `owner conflict`, `room full`, `invalid join`, `already joined`,
///     `server busy`, `not a member`, `not owner`.
class SignalingBroker {
  /// Creates a broker.
  ///
  /// [neverClaimedTtl] reaps a room whose owner never claimed it this long
  /// after creation (defensive; owner-created rooms are claimed at birth).
  /// [idleTtl] reaps an empty room this long after its last peer left.
  /// [gcInterval] paces the periodic sweep started by [start]. Inject [now]
  /// for a deterministic clock and [log] to capture diagnostics in tests.
  /// [turnSecret]/[turnUris]/[turnTtl] enable TURN credential minting.
  SignalingBroker({
    this.maxPeersPerRoom = 16,
    this.maxRooms = 4096,
    this.maxConnections = 8192,
    this.maxFrameBytes = 64 * 1024,
    this.maxFramesPerWindow = 200,
    this.maxRoomFramesPerWindow = 2000,
    this.rateWindow = const Duration(seconds: 10),
    this.neverClaimedTtl = const Duration(minutes: 5),
    this.idleTtl = const Duration(seconds: 60),
    this.gcInterval = const Duration(seconds: 30),
    this.turnSecret = '',
    this.turnUris = const [],
    this.turnTtl = const Duration(hours: 6),
    DateTime Function()? now,
    void Function(String message)? log,
  }) : _now = now ?? DateTime.now,
       _log = log ?? _noopLog;

  /// Maximum number of connected peers a room will accept (owner + clients).
  final int maxPeersPerRoom;

  /// Hard cap on concurrently-tracked rooms. A new room beyond this is
  /// refused, so a flood of unique room codes can't exhaust memory/fds.
  final int maxRooms;

  /// Hard cap on concurrently-open WebSocket connections.
  final int maxConnections;

  /// Maximum accepted size (bytes/chars) of a single inbound frame before
  /// JSON decode.
  final int maxFrameBytes;

  /// Per-connection frame budget within [rateWindow].
  final int maxFramesPerWindow;

  /// Per-room aggregate frame budget within [rateWindow] — one hostile
  /// admitted joiner can't spin the broker's CPU for a whole room unnoticed
  /// (PRD 15 adversarial note). Frames over the budget are dropped + logged.
  final int maxRoomFramesPerWindow;

  /// Sliding window over which the frame budgets are counted.
  final Duration rateWindow;

  /// A room that never had an owner claim is reaped this long after it was
  /// created.
  final Duration neverClaimedTtl;

  /// A room with zero peers is reaped this long after its last peer left.
  final Duration idleTtl;

  /// Cadence of the periodic garbage-collection sweep started by [start].
  final Duration gcInterval;

  /// coturn `static-auth-secret`; empty disables TURN minting.
  final String turnSecret;

  /// TURN server URIs handed to clients (e.g. `turn:turn.example.com:3478`).
  final List<String> turnUris;

  /// Lifetime of minted TURN credentials.
  final Duration turnTtl;

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

  /// Whether [code]'s room currently has a live owner connection.
  bool ownerPresent(String code) => _rooms[code]?.owner != null;

  /// The number of admitted hashes registered for [code]'s room.
  int admittedCount(String code) => _rooms[code]?.admittedHashes.length ?? 0;

  /// Runs one garbage-collection sweep and returns the number of rooms
  /// reaped: empty past [idleTtl], or never owner-claimed past
  /// [neverClaimedTtl]. A room with a live owner is never reaped.
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
          (!room.everClaimed && age > neverClaimedTtl);
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
  /// The peer must send a `join` frame before anything else. The returned
  /// future completes when the socket closes; it never completes with an
  /// error.
  Future<void> handleConnection(WebSocket socket) async {
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
        // Per-room aggregate budget: charged for every frame from a joined
        // peer, so one hostile member can't starve the broker for the room.
        final joinedRoom = roomCode == null ? null : _rooms[roomCode];
        if (joinedRoom != null && !joinedRoom.withinRate(_now, rateWindow, maxRoomFramesPerWindow)) {
          _log('room "${joinedRoom.code}" over aggregate rate, dropping frame');
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
        } else if (type == 'admit') {
          _handleAdmit(socket, frame, roomCode, self);
        } else if (type == 'turn-request') {
          _handleTurnRequest(socket, roomCode, self);
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

  /// Stops the garbage collector, closes every live peer socket, and clears
  /// all rooms. The broker is unusable after this.
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
    if (code == null || peerId == null || code.isEmpty || peerId.isEmpty) {
      return _refuse(socket, 'invalid join');
    }
    final asOwner = frame['owner'] == true;
    if (asOwner) {
      return _handleOwnerJoin(socket, frame, code, peerId);
    }
    return _handleClientJoin(socket, frame, code, peerId);
  }

  _JoinResult? _handleOwnerJoin(
    WebSocket socket,
    Map<String, dynamic> frame,
    String code,
    String peerId,
  ) {
    final ownerToken = _string(frame['ownerToken']);
    if (ownerToken == null || ownerToken.isEmpty) {
      return _refuse(socket, 'invalid join');
    }
    var room = _rooms[code];
    if (room == null) {
      if (_rooms.length >= maxRooms) {
        return _refuse(socket, 'server busy');
      }
      room = _Room(code, _now(), ownerHash: _sha256Hex(ownerToken));
      _rooms[code] = room;
    } else if (_sha256Hex(ownerToken) != room.ownerHash) {
      // Wrong owner token — either a client trying to escalate, or the
      // legitimate server discovering its room was squatted. Loud + uniform.
      _log('owner conflict in room "$code"');
      return _refuse(socket, 'owner conflict');
    } else {
      // Valid re-claim: supersede any wedged prior owner connection.
      final stale = room.owner;
      if (stale != null) {
        stale.removed = true;
        room.peers.remove(stale);
        room.owner = null;
        _closeQuietly(stale.socket);
        _log('evicted stale owner from room "$code" (owner re-claim)');
      }
    }
    room.everClaimed = true;
    _evictSamePeerId(room, peerId, code);
    if (room.peers.length >= maxPeersPerRoom) {
      return _refuse(socket, 'room full');
    }
    final admit = frame['admit'];
    if (admit is List) {
      room.admittedHashes
        ..clear()
        ..addAll(admit.whereType<String>().map((h) => h.toLowerCase()));
    }
    final peer = _Peer(peerId, socket, isOwner: true);
    room.owner = peer;
    _finishJoin(room, peer);
    return _JoinResult(code, peer);
  }

  _JoinResult? _handleClientJoin(
    WebSocket socket,
    Map<String, dynamic> frame,
    String code,
    String peerId,
  ) {
    final token = _string(frame['token']);
    final room = _rooms[code];
    // Uniform refusal: a missing room, a missing token, and a bad token are
    // indistinguishable to the joiner — the broker is not a room oracle and
    // a valid room id alone is not admission (PRD 15 acceptance).
    if (room == null || token == null || token.isEmpty) {
      return _refuse(socket, 'not admitted');
    }
    final hash = _sha256Hex(token);
    if (!room.admittedHashes.contains(hash)) {
      _log('unadmitted join refused for room "$code"');
      return _refuse(socket, 'not admitted');
    }
    _evictSamePeerId(room, peerId, code);
    if (room.peers.length >= maxPeersPerRoom) {
      return _refuse(socket, 'room full');
    }
    final peer = _Peer(peerId, socket, admissionHash: hash);
    _finishJoin(room, peer);
    return _JoinResult(code, peer);
  }

  void _evictSamePeerId(_Room room, String peerId, String code) {
    final stale = room.peers.where((p) => p.id == peerId).toList();
    for (final p in stale) {
      p.removed = true;
      room.peers.remove(p);
      if (identical(room.owner, p)) {
        room.owner = null;
      }
      _closeQuietly(p.socket);
      _log('evicted stale peer "$peerId" from room "$code" (reconnect)');
    }
  }

  void _finishJoin(_Room room, _Peer peer) {
    final existing = List<_Peer>.of(room.peers);
    room.peers.add(peer);
    room.lastActivityAt = _now();
    _send(peer.socket, <String, dynamic>{
      'type': 'joined',
      'room': room.code,
      'owner': peer.isOwner,
      'ownerPresent': room.owner != null,
      if (room.owner != null) 'ownerPeer': room.owner!.id,
      'peers': existing.length,
    });
    for (final p in existing) {
      _send(p.socket, <String, dynamic>{
        'type': 'peer-joined',
        'room': room.code,
        'from': peer.id,
        'owner': peer.isOwner,
      });
    }
  }

  _JoinResult? _refuse(WebSocket socket, String error) {
    _send(socket, <String, dynamic>{'type': 'error', 'error': error});
    _closeQuietly(socket);
    return null;
  }

  void _handleAdmit(
    WebSocket socket,
    Map<String, dynamic> frame,
    String? roomCode,
    _Peer? self,
  ) {
    if (roomCode == null || self == null) {
      _send(socket, const <String, dynamic>{
        'type': 'error',
        'error': 'not a member',
      });
      return;
    }
    final room = _rooms[roomCode];
    if (room == null) {
      return;
    }
    if (!identical(room.owner, self)) {
      _send(socket, const <String, dynamic>{
        'type': 'error',
        'error': 'not owner',
      });
      return;
    }
    final add = frame['add'];
    if (add is List) {
      room.admittedHashes.addAll(
        add.whereType<String>().map((h) => h.toLowerCase()),
      );
    }
    final remove = frame['remove'];
    if (remove is List) {
      for (final h in remove.whereType<String>()) {
        final hash = h.toLowerCase();
        room.admittedHashes.remove(hash);
        // Live revocation: a peer admitted under this hash loses its slot now.
        final evicted = room.peers
            .where((p) => p.admissionHash == hash)
            .toList();
        for (final p in evicted) {
          _log('evicting revoked peer "${p.id}" from room "$roomCode"');
          _leave(roomCode, p, notify: true);
          _closeQuietly(p.socket);
        }
      }
    }
    _send(socket, <String, dynamic>{
      'type': 'admit-ok',
      'room': roomCode,
      'count': room.admittedHashes.length,
    });
  }

  void _handleTurnRequest(WebSocket socket, String? roomCode, _Peer? self) {
    if (roomCode == null || self == null || !_rooms.containsKey(roomCode)) {
      _send(socket, const <String, dynamic>{
        'type': 'error',
        'error': 'not a member',
      });
      return;
    }
    if (turnSecret.isEmpty || turnUris.isEmpty) {
      _send(socket, <String, dynamic>{
        'type': 'turn-credentials',
        'room': roomCode,
        'uris': const <String>[],
      });
      return;
    }
    final expiry =
        _now().add(turnTtl).millisecondsSinceEpoch ~/ 1000;
    final label = _randomHex(4);
    final username = '$expiry:$label';
    final credential = base64.encode(
      Hmac(sha1, utf8.encode(turnSecret)).convert(utf8.encode(username)).bytes,
    );
    _send(socket, <String, dynamic>{
      'type': 'turn-credentials',
      'room': roomCode,
      'uris': turnUris,
      'username': username,
      'credential': credential,
      'ttlSeconds': turnTtl.inSeconds,
    });
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
    // Stamp the sender's real id — an admitted peer must not be able to
    // spoof another member's `from` (defense in depth; the E2E seal already
    // makes forged frames undecryptable).
    final outbound = <String, dynamic>{...frame, 'from': self.id};
    final to = _string(frame['to']);
    var delivered = false;
    for (final p in room.peers) {
      if (identical(p, self)) {
        continue;
      }
      if (to != null && p.id != to) {
        continue;
      }
      _send(p.socket, outbound);
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
    if (identical(room.owner, peer)) {
      room.owner = null;
    }
    room.lastActivityAt = _now();
    if (notify) {
      for (final p in room.peers) {
        _send(p.socket, <String, dynamic>{
          'type': 'peer-left',
          'room': roomCode,
          // The leaver's id lets a peer ignore a stale `peer-left` from a
          // superseded connection instead of tearing down a live session.
          'from': peer.id,
          'owner': peer.isOwner,
        });
      }
    }
    // Empty rooms are intentionally left for the idle GC sweep to reap.
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

  static String _sha256Hex(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  static String _randomHex(int bytes) {
    final rnd = Random.secure();
    return List<int>.generate(bytes, (_) => rnd.nextInt(256))
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
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
  _Peer(this.id, this.socket, {this.isOwner = false, this.admissionHash});

  /// The peer id supplied in the join frame.
  final String id;

  /// The live WebSocket.
  final WebSocket socket;

  /// Whether this peer claimed the room as its owner (the cc_server).
  final bool isOwner;

  /// The admitted hash this client joined with (null for the owner); lets a
  /// revoked hash evict its live peer.
  final String? admissionHash;

  /// Whether this peer has been removed from its room (guards double
  /// cleanup).
  bool removed = false;
}

/// One signaling room: an owner (the server) plus admitted client peers.
class _Room {
  _Room(this.code, DateTime createdAt, {required this.ownerHash})
    : createdAt = createdAt,
      lastActivityAt = createdAt;

  /// The room code (the server's relay room id).
  final String code;

  /// When the room was created (first join).
  final DateTime createdAt;

  /// `sha256` hex of the owner token declared at creation; every owner
  /// re-claim must present the preimage.
  final String ownerHash;

  /// Updated on every join/leave; used for idle GC.
  DateTime lastActivityAt;

  /// The connected peers (owner included).
  final List<_Peer> peers = [];

  /// The live owner connection, when present.
  _Peer? owner;

  /// Whether an owner ever successfully claimed this room.
  bool everClaimed = false;

  /// `sha256` hex admission hashes currently allowed to join.
  final Set<String> admittedHashes = <String>{};

  /// Timestamps of recent frames from all members (aggregate rate cap).
  final Queue<DateTime> _frameHits = Queue<DateTime>();

  /// Charges one frame against the room's aggregate budget.
  bool withinRate(
    DateTime Function() now,
    Duration window,
    int maxFrames,
  ) {
    final t = now();
    final cutoff = t.subtract(window);
    while (_frameHits.isNotEmpty && !_frameHits.first.isAfter(cutoff)) {
      _frameHits.removeFirst();
    }
    if (_frameHits.length >= maxFrames) {
      return false;
    }
    _frameHits.add(t);
    return true;
  }
}

/// A bound [HttpServer] and the [SignalingBroker] serving it.
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

/// Binds an [HttpServer] that upgrades WebSocket requests at any path and
/// hands each connection to a [SignalingBroker].
///
/// Pass [port] `0` to bind an ephemeral port and read the chosen value from
/// the returned handle's [SignalingServerHandle.port]. When [broker] is
/// omitted a new one is created with default TTLs and its garbage collector
/// is started.
Future<SignalingServerHandle> serveSignaling({
  Object host = defaultSignalingHost,
  int port = defaultSignalingPort,
  SignalingBroker? broker,
  void Function(String message)? log,
}) async {
  final logger = log ?? _noopLog;
  final effective = broker ?? (SignalingBroker(log: logger)..start());
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
