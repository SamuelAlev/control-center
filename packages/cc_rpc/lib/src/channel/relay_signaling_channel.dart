import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:cc_rpc/src/transport_security_policy.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// A web-safe client of the Control Center signaling broker.
///
/// Speaks the invite-gated N-capacity room protocol (`cc_signaling_server`):
/// the cc_server joins its relay room as the **owner** (with the owner token
/// and the admitted-hash list), clients join with an **admission token**
/// derived from their device PSK and both sides exchange opaque sealed
/// `signal` payloads. Built on `web_socket_channel`, so the identical class
/// serves the headless server (VM), the desktop, the web build and the
/// phone PWA.
class RelaySignalingChannel {
  RelaySignalingChannel._(this._ws, this.room, this.peerId);

  /// The joined room code.
  final String room;

  /// This side's signaling peer id within the room.
  final String peerId;

  final WebSocketChannel _ws;
  StreamSubscription<dynamic>? _sub;
  final StreamController<Map<String, dynamic>> _incoming =
      StreamController<Map<String, dynamic>>.broadcast();
  bool _open = false;
  bool _closed = false;

  /// Decoded inbound broker frames (each a JSON object with a `type`).
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  /// Whether the socket is open and joined.
  bool get isOpen => _open;

  /// Connects to [signalingUrl] and joins [room] as its **owner** (cc_server).
  ///
  /// [ownerToken] proves room ownership across reconnects (the broker stores
  /// only its hash); [admit] replaces the room's admission-hash set. Throws
  /// [RelaySignalingException] on refusal (`owner conflict` = the room is
  /// squatted or the token rotated — surface loudly).
  static Future<RelaySignalingChannel> joinAsOwner({
    required String signalingUrl,
    required String room,
    required String ownerToken,
    required List<String> admit,
    String? peerId,
    Duration timeout = const Duration(seconds: 15),
  }) => _join(
    signalingUrl: signalingUrl,
    room: room,
    peerId: peerId ?? randomPeerId(),
    timeout: timeout,
    joinFields: {'owner': true, 'ownerToken': ownerToken, 'admit': admit},
  );

  /// Connects to [signalingUrl] and joins [room] as an admitted client,
  /// presenting the PSK-derived admission [token].
  static Future<RelaySignalingChannel> joinAsClient({
    required String signalingUrl,
    required String room,
    required String token,
    String? peerId,
    Duration timeout = const Duration(seconds: 15),
  }) => _join(
    signalingUrl: signalingUrl,
    room: room,
    peerId: peerId ?? randomPeerId(),
    timeout: timeout,
    joinFields: {'token': token},
  );

  static Future<RelaySignalingChannel> _join({
    required String signalingUrl,
    required String room,
    required String peerId,
    required Duration timeout,
    required Map<String, dynamic> joinFields,
  }) async {
    final uri = Uri.parse(signalingUrl);
    TransportSecurityPolicy.enforce(uri);
    final ws = WebSocketChannel.connect(uri);
    final channel = RelaySignalingChannel._(ws, room, peerId);
    try {
      await ws.ready.timeout(timeout);
    } catch (e) {
      throw RelaySignalingException('broker unreachable: $e');
    }
    channel._open = true;
    channel._sub = ws.stream.listen(
      (Object? data) {
        if (data is! String) {
          return;
        }
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map<String, dynamic>) {
            channel._incoming.add(decoded);
          }
        } catch (_) {
          // Ignore malformed frames.
        }
      },
      onDone: channel._handleClosed,
      onError: (Object _) => channel._handleClosed(),
      cancelOnError: true,
    );

    // Build the ack wait BEFORE sending join so an immediate error isn't lost.
    final ack = channel._incoming.stream
        .firstWhere(
          (f) => f['type'] == 'joined' || f['type'] == 'error',
          orElse: () => const {'type': 'error', 'error': 'closed before join'},
        )
        .timeout(timeout);
    channel.send({'type': 'join', 'room': room, 'from': peerId, ...joinFields});
    final Map<String, dynamic> frame;
    try {
      frame = await ack;
    } catch (e) {
      await channel.close();
      throw RelaySignalingException('no join ack: $e');
    }
    if (frame['type'] == 'error') {
      await channel.close();
      throw RelaySignalingException(
        (frame['error'] as String?) ?? 'join rejected by broker',
      );
    }
    channel._lastAck = RelayJoinAck.fromFrame(frame);
    return channel;
  }

  RelayJoinAck? _lastAck;

  /// The join acknowledgement (owner presence, peer count).
  RelayJoinAck get joinAck =>
      _lastAck ?? const RelayJoinAck(owner: false, ownerPresent: false);

  /// Sends a raw broker frame. No-op when the socket is closed.
  void send(Map<String, dynamic> frame) {
    if (!_open) {
      return;
    }
    _ws.sink.add(jsonEncode(frame));
  }

  /// Relays an opaque [payload] to [to] (a peer id), or to every other room
  /// member when [to] is null.
  void sendSignal({
    String? to,
    String kind = 'rpc',
    required Map<String, dynamic> payload,
  }) {
    send({
      'type': 'signal',
      'room': room,
      'from': peerId,
      'to': ?to,
      'kind': kind,
      'payload': payload,
    });
  }

  /// Owner-only: updates the room's admission-hash set.
  void admit({List<String> add = const [], List<String> remove = const []}) {
    send({
      'type': 'admit',
      'room': room,
      if (add.isNotEmpty) 'add': add,
      if (remove.isNotEmpty) 'remove': remove,
    });
  }

  /// Sends a `bye` (best-effort), then closes the socket.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    if (_open) {
      send({'type': 'bye', 'room': room, 'from': peerId});
    }
    _closed = true;
    _open = false;
    await _sub?.cancel();
    await _ws.sink.close();
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
  }

  void _handleClosed() {
    if (_closed) {
      return;
    }
    _open = false;
    if (!_incoming.isClosed) {
      _incoming.add(const {'type': 'peer-left', 'reason': 'socket-closed'});
      unawaited(_incoming.close());
    }
  }

  /// A fresh 12-byte random hex peer id.
  static String randomPeerId() {
    final rnd = Random.secure();
    return List<int>.generate(
      12,
      (_) => rnd.nextInt(256),
    ).map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

/// The broker's `joined` acknowledgement.
class RelayJoinAck {
  /// Creates a [RelayJoinAck].
  const RelayJoinAck({
    required this.owner,
    required this.ownerPresent,
    this.ownerPeer,
    this.peers = 0,
  });

  /// Parses the broker's `joined` frame.
  factory RelayJoinAck.fromFrame(Map<String, dynamic> frame) => RelayJoinAck(
    owner: frame['owner'] as bool? ?? false,
    ownerPresent: frame['ownerPresent'] as bool? ?? false,
    ownerPeer: frame['ownerPeer'] as String?,
    peers: (frame['peers'] as num?)?.toInt() ?? 0,
  );

  /// Whether this side owns the room.
  final bool owner;

  /// Whether the room's owner (the server) is currently connected.
  final bool ownerPresent;

  /// The owner's peer id, when present.
  final String? ownerPeer;

  /// How many other peers were already in the room.
  final int peers;
}

/// Thrown when the signaling broker refuses a join or is unreachable.
class RelaySignalingException implements Exception {
  /// Creates a [RelaySignalingException].
  const RelaySignalingException(this.message);

  /// Human-readable reason (never contains secrets).
  final String message;

  @override
  String toString() => 'RelaySignalingException: $message';
}
