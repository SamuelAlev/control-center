/// Pure-Dart, stateless WebSocket signaling broker for Control Center.
///
/// Dumb relay: understands `join` / `signal` / `admit` / `turn-request` /
/// `bye` and emits broker frames, but never inspects `signal` payloads or
/// pairing PSKs (admission tokens are one-way HMAC of a device PSK; frames
/// are sealed before arrival).
///
/// Rooms (≤[SignalingBroker.maxPeersPerRoom], default 16): owner joins with
/// `ownerToken` (broker stores `sha256` only); clients need an admitted
/// `sha256(token)` — room id alone is refused as `not admitted` (same as a
/// missing room). Removing an admission hash evicts that peer.
///
/// Broker is untrusted for confidentiality; room-id squatters get
/// `owner conflict` and only ciphertext. With a coturn secret, mints
/// ephemeral TURN creds (`static-auth-secret` HMAC-SHA1); never stored.
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

/// Stateless WebSocket signaling relay with invite-gated N-capacity rooms.
///
/// Call [start] (or drive [sweep] with an injected clock) and feed sockets to
/// [handleConnection]. JSON frames; only broker fields are interpreted —
/// `signal` payloads relay verbatim. `from` on signal is overwritten (no
/// spoofing). Client types: `join` (owner/`ownerToken` or client/`token`),
/// `admit`, `signal`, `turn-request`, `bye`. Broker types: `joined`,
/// `admit-ok`, `peer-joined`, `peer-left`, `turn-credentials`, `error`
/// (`not admitted`, `owner conflict`, `room full`, …).
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
    this.dataBytesPerWindow = 8 * 1024 * 1024,
    this.roomDataBytesPerWindow = 32 * 1024 * 1024,
    this.dataBurstBytes = 512 * 1024,
    this.roomDataBurstBytes = 2 * 1024 * 1024,
    this.neverClaimedTtl = const Duration(minutes: 5),
    this.idleTtl = const Duration(seconds: 60),
    this.gcInterval = const Duration(seconds: 30),
    this.turnSecret = '',
    this.turnUris = const [],
    this.turnTtl = const Duration(hours: 6),
    DateTime Function()? now,
    void Function(String message)? log,
  }) : assert(rateWindow > Duration.zero),
       assert(dataBytesPerWindow > 0 && roomDataBytesPerWindow > 0),
       assert(dataBurstBytes >= maxFrameBytes),
       assert(roomDataBurstBytes >= maxFrameBytes),
       _dataFrameFloor = min(
         _minimumDataChargeBytes,
         min(dataBurstBytes, roomDataBurstBytes),
       ),
       _now = now ?? DateTime.now,
       _log = log ?? _noopLog;

  /// Maximum number of connected peers a room will accept (owner + clients).
  final int maxPeersPerRoom;

  /// Window and ceiling for same-peer-id evictions (see `_evictSamePeerId`).
  /// A real reconnect storm is a handful; a loop is an attack.
  static const Duration _evictionWindow = Duration(seconds: 30);

  /// Max same-id evictions per [_evictionWindow] before joins are refused.
  static const int _maxEvictionsPerWindow = 3;

  /// Ceiling on bytes queued to one peer before it is closed as too slow.
  static const int _maxOutboundBufferBytes = 8 * 1024 * 1024;

  // Keep reading WebSocket control/close frames while data waits for quota.
  // Shared Noise peers have a 64-record credit window; these bounds leave
  // room for that window without accepting an unbounded admitted flood.
  static const int _maxInboundBufferBytes = 4 * 1024 * 1024;
  static const int _maxInboundBufferFrames = 256;
  static const int _maxTotalInboundBufferBytes = 128 * 1024 * 1024;
  int _bufferedDataBytes = 0;

  /// Charge even tiny purported records enough to bound fake-encrypted floods.
  /// Genuine Noise credits share the same pacing without ever being dropped.
  static const int _minimumDataChargeBytes = 8 * 1024;
  final int _dataFrameFloor;

  /// Per-socket outbound queue state (see [_send]).
  final Map<WebSocket, _Outbox> _outbox = {};

  /// One active quota reservation per socket, plus a bounded data FIFO.
  final Map<WebSocket, _DataWaiter> _pendingData = {};

  /// Weak keys do not retain a slow socket after its outbox is detached.
  final Expando<bool> _closingSockets = Expando<bool>();

  /// Hard cap on concurrently-tracked rooms. A new room beyond this is
  /// refused, so a flood of unique room codes can't exhaust memory/fds.
  final int maxRooms;

  /// Hard cap on concurrently-open WebSocket connections.
  final int maxConnections;

  /// Maximum accepted size (bytes/chars) of a single inbound frame before
  /// JSON decode.
  final int maxFrameBytes;

  /// Per-connection control frame budget within [rateWindow]. Over-budget
  /// control frames are dropped; Noise records never use this budget.
  final int maxFramesPerWindow;

  /// Per-room aggregate control frame budget within [rateWindow].
  final int maxRoomFramesPerWindow;

  /// Window for control budgets and sustained encrypted-record byte rates.
  final Duration rateWindow;

  /// Per-connection and per-room sustained inbound encrypted bytes per window.
  /// Data is paced, never silently dropped. Charge the complete outer wire
  /// frame (or the minimum floor for tiny records), never decrypted content.
  final int dataBytesPerWindow;
  final int roomDataBytesPerWindow;

  /// Maximum initial/accumulated burst, independently per peer and room.
  /// Each must accommodate at least one [maxFrameBytes] wire frame.
  final int dataBurstBytes;
  final int roomDataBurstBytes;

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

  /// The number of sockets currently holding outbound-queue state.
  ///
  /// Visible so a test can pin that this map is bounded by the LIVE
  /// connections: it is keyed by [WebSocket] and a stale entry retains that
  /// socket's whole object graph for the process lifetime.
  int get outboxCount => _outbox.length;

  /// Number of peers with an active encrypted-record quota reservation.
  int get pendingDataCount => _pendingData.length;

  /// All admitted data bytes buffered in the bounded per-peer FIFOs.
  int get pendingDataBytes => _bufferedDataBytes;

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
    final dataBucket = _ByteBucket(
      dataBurstBytes,
      dataBytesPerWindow,
      rateWindow,
      _now(),
    );
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

    final dataQueue =
        Queue<
          ({Map<String, dynamic> frame, int bytes, _Room room, _Peer peer})
        >();
    var queuedBytes = 0;
    var drainingData = false;
    void discardData() {
      _bufferedDataBytes -= queuedBytes;
      queuedBytes = 0;
      dataQueue.clear();
    }

    Future<void> drainData() async {
      if (drainingData) return;
      drainingData = true;
      try {
        while (dataQueue.isNotEmpty &&
            !detached &&
            _closingSockets[socket] != true) {
          final record = dataQueue.first;
          final waiter = _DataWaiter(
            record.bytes,
            max(record.bytes, _dataFrameFloor),
            dataBucket,
            record.room,
          );
          _pendingData[socket] = waiter;
          record.room.requestData(waiter);
          final allowed = await waiter.done.future;
          if (identical(_pendingData[socket], waiter)) {
            _pendingData.remove(socket);
          }
          if (dataQueue.isEmpty)
            break; // Connection cleanup already released it.
          dataQueue.removeFirst();
          queuedBytes -= record.bytes;
          _bufferedDataBytes -= record.bytes;
          if (allowed &&
              !detached &&
              _closingSockets[socket] != true &&
              socket.readyState == WebSocket.open &&
              !record.peer.removed &&
              identical(_rooms[roomCode], record.room)) {
            _handleSignal(record.frame, roomCode, record.peer);
          }
        }
      } finally {
        drainingData = false;
        if (detached || _closingSockets[socket] == true) discardData();
      }
    }

    void cleanup() {
      if (detached) {
        return;
      }
      detached = true;
      _cancelPendingData(socket);
      discardData();
      final code = roomCode;
      final peer = self;
      roomCode = null;
      self = null;
      if (code != null && peer != null) {
        _leave(code, peer, notify: true);
      }
    }

    final done = Completer<void>();
    late final StreamSubscription<dynamic> subscription;
    subscription = socket.listen(
      (dynamic data) {
        if (detached || _closingSockets[socket] == true) return;
        final preJoin = roomCode == null;
        if (preJoin && !withinRate()) {
          _log('pre-join control rate limit exceeded, dropping frame');
          return;
        }
        final bytes = data is String
            ? _utf8Length(data)
            : data is List<int>
            ? data.length
            : 0;
        final frame = _decode(data, bytes);
        if (frame == null) {
          if (!preJoin) withinRate();
          return;
        }
        final joinedRoom = roomCode == null ? null : _rooms[roomCode];
        final peer = self;
        // A logical per-peer close is an ordering barrier for ciphertext, not
        // an out-of-band control message. The owner keeps its room socket open
        // after this close; forwarding it early loses the final RPC response.
        final orderedSignal =
            joinedRoom != null &&
            peer != null &&
            !peer.removed &&
            frame['type'] == 'signal' &&
            frame['to'] is String &&
            (frame['to'] as String).isNotEmpty &&
            frame['payload'] is Map &&
            (frame['kind'] == 'close' ||
                (frame['kind'] == 'rpc' &&
                    (frame['payload'] as Map)['type'] == 'secure' &&
                    (frame['payload'] as Map)['v'] == 1 &&
                    (frame['payload'] as Map)['c'] is String));
        if (orderedSignal) {
          if (dataQueue.length >= _maxInboundBufferFrames ||
              queuedBytes + bytes > _maxInboundBufferBytes ||
              _bufferedDataBytes + bytes > _maxTotalInboundBufferBytes) {
            // A conforming Noise sender stops at its credit window. A peer
            // that ignores it is disconnected, never silently reordered.
            _closeQuietly(socket);
            return;
          }
          dataQueue.add((
            frame: frame,
            bytes: bytes,
            room: joinedRoom,
            peer: peer,
          ));
          queuedBytes += bytes;
          _bufferedDataBytes += bytes;
          unawaited(drainData());
          return;
        }
        if (!preJoin && !withinRate()) {
          _log('control rate limit exceeded on a connection, dropping frame');
          return;
        }
        if (joinedRoom != null &&
            !joinedRoom.withinRate(_now, rateWindow, maxRoomFramesPerWindow)) {
          _log('room "${joinedRoom.code}" over control rate, dropping frame');
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
          final leaving = self;
          roomCode = null;
          self = null;
          if (code != null && leaving != null) {
            _leave(code, leaving, notify: true);
          }
          _closeQuietly(socket);
        } else {
          _log('unknown frame type ${jsonEncode(type)}, ignoring');
        }
      },
      onError: (Object error, StackTrace stackTrace) {
        _log('socket error: $error');
        _cancelPendingData(socket);
      },
      onDone: done.complete,
    );
    // An outbound failure also invalidates any active quota reservation.
    unawaited(
      socket.done.then(
        (_) => _cancelPendingData(socket),
        onError: (Object _) => _cancelPendingData(socket),
      ),
    );

    try {
      await done.future;
    } finally {
      cleanup();
      await subscription.cancel();
      // The outbox is keyed by the socket, so an entry left behind pins that
      // WebSocket — and through it its consumer, protocol transformer and the
      // detached socket — for the process lifetime. Only the paths that route
      // through `_closeQuietly` (a refusal, an eviction, `bye`) dropped it;
      // an ordinary remote disconnect arrives here instead, which leaked one
      // entry per connection the broker had ever answered. Any write still
      // in flight completes against the detached `_Outbox` and is discarded.
      _outbox.remove(socket);
      _closingSockets[socket] = null;
      _connectionCount--;
    }
  }

  /// Stops the garbage collector, closes every live peer socket and clears
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
    // Sockets that never joined a room are not peers, so nothing above drops
    // their queue state.
    _outbox.clear();
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
      room = _Room(
        code,
        _now(),
        ownerHash: _sha256Hex(ownerToken),
        dataBucket: _ByteBucket(
          roomDataBurstBytes,
          roomDataBytesPerWindow,
          rateWindow,
          _now(),
        ),
        now: _now,
      );
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
    if (!_evictSamePeerId(room, peerId, code)) {
      // Too many collisions on this id too fast — see `_evictSamePeerId`.
      return _refuse(socket, 'not admitted');
    }
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
    // Uniform refusal: a missing room, a missing token and a bad token are
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
    if (!_evictSamePeerId(room, peerId, code)) {
      // Too many collisions on this id too fast — see `_evictSamePeerId`.
      // Refused with the SAME uniform message as any other denial, so this is
      // not an oracle for "who is in the room".
      return _refuse(socket, 'not admitted');
    }
    if (room.peers.length >= maxPeersPerRoom) {
      return _refuse(socket, 'room full');
    }
    final peer = _Peer(peerId, socket, admissionHash: hash);
    _finishJoin(room, peer);
    return _JoinResult(code, peer);
  }

  /// Drops any peer already holding [peerId] so a RECONNECT replaces its own
  /// stale socket. Returns false when the join must be refused instead.
  ///
  /// Peer ids are broadcast to the room in `peer-joined` frames, so without a
  /// bound any admitted client could evict any other member on demand, over
  /// and over — a cheap in-room denial of service (the E2E crypto means
  /// nothing is READ, but the target is repeatedly disconnected). Genuine
  /// reconnects are rare and bursty-at-most; an attack is a loop. So the
  /// eviction is rate-limited per (room, peer id): past
  /// [_maxEvictionsPerWindow] in [_evictionWindow] the JOIN is refused and the
  /// incumbent keeps its socket.
  bool _evictSamePeerId(_Room room, String peerId, String code) {
    final stale = room.peers.where((p) => p.id == peerId).toList();
    if (stale.isEmpty) {
      return true;
    }
    final now = _now();
    final recent = (room.recentEvictions[peerId] ?? const <DateTime>[])
        .where((t) => now.difference(t) < _evictionWindow)
        .toList();
    if (recent.length >= _maxEvictionsPerWindow) {
      room.recentEvictions[peerId] = recent;
      _log(
        'refusing join for peer "$peerId" in room "$code": '
        '${recent.length} evictions within ${_evictionWindow.inSeconds}s',
      );
      return false;
    }
    for (final p in stale) {
      p.removed = true;
      room.peers.remove(p);
      if (identical(room.owner, p)) {
        room.owner = null;
      }
      _closeQuietly(p.socket);
      _log('evicted stale peer "$peerId" from room "$code" (reconnect)');
    }
    room.recentEvictions[peerId] = [...recent, now];
    // Bound the bookkeeping itself: only ids seen in the window are kept.
    room.recentEvictions.removeWhere(
      (_, times) => times.every((t) => now.difference(t) >= _evictionWindow),
    );
    return true;
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
    final expiry = _now().add(turnTtl).millisecondsSinceEpoch ~/ 1000;
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
    if (roomCode == null || self == null || self.removed) {
      _log('signal from a peer that has not joined, dropping');
      return;
    }
    final room = _rooms[roomCode];
    if (room == null || !room.peers.contains(self)) {
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

  /// Queues [frame] to [socket] with outbound backpressure.
  ///
  /// Dart's WebSocket buffers unboundedly when a peer stops reading, so one
  /// slow (or deliberately stalled) admitted client could accumulate every
  /// relayed frame in BROKER memory — the inbound side has a 64 KiB frame
  /// cap and separate control/data budgets, but each recipient can stall.
  ///
  /// Writes are serialized through `addStream`, whose future completes only
  /// once the socket has ACCEPTED the bytes: that is the only backpressure
  /// signal dart:io's WebSocket exposes (no `flush`, no `bufferedAmount`), and
  /// a WebSocket is ordered anyway. Past [_maxOutboundBufferBytes] still
  /// un-accepted, the peer is closed — a client that cannot keep up with its
  /// own room is not a client any more. Same shape as
  /// `WsRemoteTransport.send`.
  void _send(WebSocket socket, Map<String, dynamic> frame) {
    if (_closingSockets[socket] == true) return;
    if (socket.readyState != WebSocket.open) {
      return;
    }
    final String payload;
    try {
      payload = jsonEncode(frame);
    } catch (error) {
      _log('failed to encode frame: $error');
      return;
    }
    final outbox = _outbox.putIfAbsent(socket, _Outbox.new);
    if (outbox.queuedBytes + payload.length > _maxOutboundBufferBytes) {
      _log(
        'closing a peer that is not draining '
        '(${outbox.queuedBytes ~/ 1024} KB queued)',
      );
      _closeQuietly(socket);
      return;
    }
    outbox.queuedBytes += payload.length;
    final queued = outbox.chain.then((_) async {
      if (socket.readyState != WebSocket.open) {
        return;
      }
      await socket.addStream(Stream<String>.value(payload));
    });
    outbox.chain = queued.then(
      (_) => outbox.queuedBytes -= payload.length,
      onError: (Object error) {
        outbox.queuedBytes -= payload.length;
        _log('failed to send frame: $error');
      },
    );
  }

  void _cancelPendingData(WebSocket socket) {
    final waiter = _pendingData.remove(socket);
    waiter?.room.cancelData(waiter);
  }

  /// Closes [socket] once anything already queued to it has been accepted.
  ///
  /// [_send] is asynchronous, so closing immediately would discard a refusal
  /// error frame. A stalled write is given five seconds to finish; a bound
  /// addStream that finishes later retries the close without retaining a timer.
  void _closeQuietly(WebSocket socket) {
    _closingSockets[socket] = true;
    _cancelPendingData(socket);
    final outbox = _outbox.remove(socket);
    if (outbox != null) {
      unawaited(
        outbox.chain
            .timeout(const Duration(seconds: 5))
            .catchError((Object _) {})
            .whenComplete(() => _closeNow(socket, retry: outbox.chain)),
      );
      return;
    }
    _closeNow(socket);
  }

  void _closeNow(WebSocket socket, {Future<void>? retry}) {
    if (socket.readyState == WebSocket.open) {
      try {
        unawaited(socket.close());
      } on StateError {
        // An addStream can temporarily bind the sink. Retry once that queued
        // write finishes, without creating another timer or outbound queue.
        if (retry != null) {
          unawaited(retry.then((_) => _closeNow(socket)));
        }
      }
    }
  }

  Map<String, dynamic>? _decode(dynamic data, int bytes) {
    if (bytes > maxFrameBytes) {
      _log('frame exceeds $maxFrameBytes bytes, dropping');
      return null;
    }
    try {
      String text;
      if (data is String) {
        text = data;
      } else if (data is List<int>) {
        text = utf8.decode(data);
      } else {
        _log('unsupported frame encoding, ignoring');
        return null;
      }
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

  static int _utf8Length(String value) {
    var bytes = 0;
    for (final rune in value.runes) {
      bytes += rune <= 0x7f
          ? 1
          : rune <= 0x7ff
          ? 2
          : rune <= 0xffff
          ? 3
          : 4;
    }
    return bytes;
  }

  static String _sha256Hex(String value) =>
      sha256.convert(utf8.encode(value)).toString();

  static String _randomHex(int bytes) {
    final rnd = Random.secure();
    return List<int>.generate(
      bytes,
      (_) => rnd.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
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
/// One peer's serialized outbound queue: the chain that orders writes and the
/// bytes handed to it that the socket has not accepted yet.
class _Outbox {
  Future<void> chain = Future<void>.value();
  int queuedBytes = 0;
}

class _Room {
  _Room(
    this.code,
    DateTime createdAt, {
    required this.ownerHash,
    required _ByteBucket dataBucket,
    required DateTime Function() now,
  }) : createdAt = createdAt,
       lastActivityAt = createdAt,
       _dataBucket = dataBucket,
       _now = now;

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

  /// When each peer id was last evicted by a same-id join, for the
  /// collision-eviction rate limit (see `_evictSamePeerId`).
  final Map<String, List<DateTime>> recentEvictions = {};

  /// The live owner connection, when present.
  _Peer? owner;

  /// Whether an owner ever successfully claimed this room.
  bool everClaimed = false;

  /// `sha256` hex admission hashes currently allowed to join.
  final Set<String> admittedHashes = <String>{};
  final _ByteBucket _dataBucket;
  final DateTime Function() _now;
  final Queue<_DataWaiter> _waitingData = Queue<_DataWaiter>();
  Timer? _dataTimer;

  /// FIFO among waiting peers, with one pending quota reservation per socket.
  /// One room timer services all peers, and is canceled when the last leaves.
  void requestData(_DataWaiter waiter) {
    _waitingData.add(waiter);
    _drainData();
  }

  void cancelData(_DataWaiter waiter) {
    if (_waitingData.remove(waiter)) {
      waiter.finish(false);
      _dataTimer?.cancel();
      _dataTimer = null;
      _drainData();
    }
  }

  void _drainData() {
    _dataTimer?.cancel();
    _dataTimer = null;
    while (_waitingData.isNotEmpty) {
      final waiter = _waitingData.first;
      final now = _now();
      final peerDelay = waiter.peerBucket.delay(waiter.charge, now);
      final roomDelay = _dataBucket.delay(waiter.charge, now);
      final delay = peerDelay > roomDelay ? peerDelay : roomDelay;
      if (delay > Duration.zero) {
        _dataTimer = Timer(delay, _drainData);
        return;
      }
      _waitingData.removeFirst();
      waiter.peerBucket.spend(waiter.charge);
      _dataBucket.spend(waiter.charge);
      waiter.finish(true);
    }
  }

  /// Timestamps of recent frames from all members (aggregate rate cap).
  final Queue<DateTime> _frameHits = Queue<DateTime>();

  /// Charges one frame against the room's aggregate budget.
  bool withinRate(DateTime Function() now, Duration window, int maxFrames) {
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

/// Continuous byte budget with a bounded burst. Refilling by elapsed time
/// avoids retaining per-record timestamps across long transfers.
class _ByteBucket {
  _ByteBucket(this.capacity, this.bytesPerWindow, this.window, this._updated)
    : _available = capacity.toDouble();

  final int capacity;
  final int bytesPerWindow;
  final Duration window;
  DateTime _updated;
  double _available;

  Duration delay(int bytes, DateTime now) {
    final elapsed = now.difference(_updated).inMicroseconds;
    if (elapsed > 0) {
      _available = min(
        capacity.toDouble(),
        _available + elapsed * bytesPerWindow / window.inMicroseconds,
      );
      _updated = now;
    }
    if (_available >= bytes) return Duration.zero;
    final micros =
        ((bytes - _available) * window.inMicroseconds / bytesPerWindow).ceil();
    return Duration(microseconds: max(1000, micros));
  }

  void spend(int bytes) => _available -= bytes;
}

class _DataWaiter {
  _DataWaiter(this.bytes, this.charge, this.peerBucket, this.room);

  final int bytes;
  final int charge;
  final _ByteBucket peerBucket;
  final _Room room;
  final Completer<bool> done = Completer<bool>();
  bool allowed = false;

  void finish(bool accepted) {
    allowed = accepted;
    done.complete(accepted);
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
