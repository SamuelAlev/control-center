import 'dart:async';

import 'package:cc_rpc/src/channel/relay_signaling_channel.dart';
import 'package:cc_rpc/src/channel/remote_rpc_channel_port.dart';
import 'package:cc_rpc/src/crypto/remote_control_crypto.dart';

/// The client half of the broker-relayed RPC path — the guaranteed
/// NAT-traversal fallback (PRD 15 §2/§3).
///
/// Joins with the PSK-derived admission token and addresses records to the
/// room owner. `SecureRpcChannel` owns encryption and flow control above this
/// raw record adapter, exactly as it does above a direct WebSocket.
class RelayClientChannel implements RemoteRpcChannelPort {
  RelayClientChannel._(this._signaling);

  /// Connects through [signalingUrl]'s broker into the server's relay [room].
  ///
  /// Derives the admission token from [psk] + [room]; when the server is not
  /// yet in the room (a restart gap), waits up to [ownerWait] for it to
  /// appear before failing. Once the owner is present, announces [deviceId]
  /// with a cleartext `hello` so the server can locate its stored PSK.
  /// This is routing metadata only; the Noise handshake authenticates the
  /// device and server before application records may flow. Throws
  /// [RelaySignalingException] on broker refusal
  /// (`not admitted` = the device was revoked or the room rotated).
  static Future<RelayClientChannel> connect({
    required String signalingUrl,
    required String room,
    required String deviceId,
    required String psk,
    String? peerId,
    Duration timeout = const Duration(seconds: 15),
    Duration ownerWait = const Duration(seconds: 20),
  }) async {
    final signaling = await RelaySignalingChannel.joinAsClient(
      signalingUrl: signalingUrl,
      room: room,
      token: RemoteControlCrypto.relayAdmissionToken(psk: psk, room: room),
      peerId: peerId,
      timeout: timeout,
    );
    final channel = RelayClientChannel._(signaling);
    try {
      await channel._start(ownerWait);
      channel._signaling.sendSignal(
        to: channel._ownerPeer,
        kind: 'hello',
        payload: {'d': deviceId},
      );
    } catch (_) {
      await channel.close();
      rethrow;
    }
    return channel;
  }

  final RelaySignalingChannel _signaling;
  String? _ownerPeer;
  StreamSubscription<Map<String, dynamic>>? _sub;

  /// The internal fan-out of signaling frames, plus the subscription this
  /// channel takes on it. Both are owned here and released in [_onClosed]:
  /// the controller used to be closed ONLY from the incoming subscription's
  /// `onDone`, which `_onClosed()` prevents from ever firing (it cancels
  /// `_sub` first) — so every relay link ended by `peer-left` or a reconnect
  /// leaked one controller plus one listener pinning this channel alive.
  StreamController<Map<String, dynamic>>? _events;
  StreamSubscription<Map<String, dynamic>>? _eventsSub;

  final StreamController<Map<String, dynamic>> _incoming =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<RemoteChannelState> _state =
      StreamController<RemoteChannelState>.broadcast();
  final List<Map<String, dynamic>> _pending = [];
  Timer? _pendingEofTimer;
  bool _pendingEof = false;
  bool _open = false;

  /// Cap on frames buffered before a listener attaches (mirrors the server's
  /// `WsRemoteTransport._maxPendingFrames`).
  static const int _maxPendingFrames = 64;

  Future<void> _start(Duration ownerWait) async {
    var ownerPeer = _signaling.joinAck.ownerPeer;
    final events = StreamController<Map<String, dynamic>>.broadcast();
    _events = events;
    _sub = _signaling.incoming.listen(
      events.add,
      onDone: () {
        // The fan-out can still have queued RPC records. Its ordered onDone,
        // rather than the signaling state, is the safe EOF boundary.
        unawaited(events.close());
      },
    );

    if (ownerPeer == null) {
      // The server is momentarily absent (restart / broker blip). Wait for
      // its owner join instead of failing the whole connection attempt.
      try {
        final joined = await events.stream
            .firstWhere((f) => f['type'] == 'peer-joined' && f['owner'] == true)
            .timeout(ownerWait);
        ownerPeer = joined['from'] as String?;
      } on TimeoutException {
        throw const RelaySignalingException(
          'server is not connected to the relay room',
        );
      }
    }
    if (ownerPeer == null || ownerPeer.isEmpty) {
      throw const RelaySignalingException('relay room has no owner peer');
    }
    _ownerPeer = ownerPeer;

    _incoming.onListen = _flushPending;

    _eventsSub = events.stream.listen((frame) {
      final type = frame['type'];
      if (type == 'signal' &&
          frame['from'] == _ownerPeer &&
          frame['kind'] == 'close') {
        _onClosed();
        unawaited(_signaling.close());
        return;
      }
      if (type == 'signal' &&
          frame['from'] == _ownerPeer &&
          frame['kind'] == 'rpc') {
        final payload = frame['payload'];
        if (payload is Map) {
          final record = payload.cast<String, dynamic>();
          if (_incoming.hasListener) {
            _incoming.add(record);
          } else if (_pending.length >= _maxPendingFrames) {
            unawaited(close());
          } else {
            _pending.add(record);
          }
        }
        return;
      }
      if (type == 'peer-left' &&
          (frame['from'] == _ownerPeer || frame['reason'] == 'socket-closed')) {
        // The server left (or our broker socket died) — this connection is
        // over; the resolver owns reconnecting.
        _onClosed();
      }
    }, onDone: _onClosed);

    _open = true;
    _state.add(RemoteChannelState.open);
  }

  void _flushPending() {
    for (final frame in _pending) {
      _incoming.add(frame);
    }
    _pending.clear();
    if (_pendingEof) {
      _pendingEofTimer?.cancel();
      _pendingEof = false;
      unawaited(_incoming.close());
    }
  }

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  @override
  Stream<RemoteChannelState> get state => _state.stream;

  @override
  bool get isOpen => _open;

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    if (!_open) {
      throw StateError('RelayClientChannel is not open');
    }
    _signaling.sendSignal(to: _ownerPeer, payload: frame);
  }

  @override
  Future<void> close() async {
    _onClosed(abort: true);
    await _signaling.close();
  }

  void _onClosed({bool abort = false}) {
    if (!_open) {
      if (abort && _pendingEof) {
        _pendingEofTimer?.cancel();
        _pendingEof = false;
        _pending.clear();
        unawaited(_incoming.close());
      }
      return;
    }
    _open = false;
    unawaited(_sub?.cancel());
    _sub = null;
    // Release the internal fan-out too — see the field docs: cancelling `_sub`
    // means the `onDone` that used to close it can never fire.
    unawaited(_eventsSub?.cancel());
    _eventsSub = null;
    final events = _events;
    _events = null;
    if (events != null && !events.isClosed) {
      unawaited(events.close());
    }
    if (!_state.isClosed) {
      _state.add(RemoteChannelState.closed);
    }
    if (abort) _pending.clear();
    if (!abort && _pending.isNotEmpty) {
      // A pre-listener record remains bounded and available to its first
      // listener, even when the peer leaves in the same socket burst.
      _pendingEof = true;
      _pendingEofTimer = Timer(const Duration(seconds: 5), () {
        _pendingEof = false;
        _pending.clear();
        unawaited(_incoming.close());
      });
    } else {
      unawaited(_incoming.close());
    }
    unawaited(_state.close());
  }

  /// Probes the relay path: joins the room with the admission token, reads
  /// owner presence + round-trip latency from the join ack and leaves.
  /// Returns null when the path is unusable (unreachable broker, refused
  /// admission, or no server in the room).
  static Future<Duration?> probe({
    required String signalingUrl,
    required String room,
    required String psk,
    Duration timeout = const Duration(seconds: 3),
  }) async {
    final started = DateTime.now();
    RelaySignalingChannel? signaling;
    try {
      signaling = await RelaySignalingChannel.joinAsClient(
        signalingUrl: signalingUrl,
        room: room,
        token: RemoteControlCrypto.relayAdmissionToken(psk: psk, room: room),
        timeout: timeout,
      );
      if (!signaling.joinAck.ownerPresent) {
        return null;
      }
      return DateTime.now().difference(started);
    } catch (_) {
      return null;
    } finally {
      unawaited(signaling?.close());
    }
  }
}
