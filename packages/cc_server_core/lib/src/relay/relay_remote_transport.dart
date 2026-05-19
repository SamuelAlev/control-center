import 'dart:async';
import 'dart:convert';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/relay/signaling_relay_client.dart';

/// A [RemoteRpcChannelPort] that carries one phone's JSON-RPC frames over the
/// signaling broker, end-to-end-encrypted with the pairing PSK.
///
/// It is the relay twin of `WsRemoteTransport`: the `RemoteRpcSession` consumes
/// [incoming] and calls [send] exactly the same way, unaware that frames are
/// sealed ([RelayFrameCrypto]) and tunnelled as broker `signal`/`kind:'rpc'`
/// payloads. The broker only ever relays ciphertext.
///
/// One transport spans a single phone connection. It does NOT own the
/// [SignalingRelayClient] — the relay host keeps that joined to the room across
/// phone reconnects (so a refreshed phone reclaims its slot), and builds a fresh
/// transport per connection. [close] therefore stops bridging without dropping
/// the room membership.
class RelayRemoteTransport implements RemoteRpcChannelPort {
  /// Wraps the already-joined [signaling] client. [room] is the device id,
  /// [peerId] this server's signaling peer id, and [psk] the pairing key.
  RelayRemoteTransport({
    required SignalingRelayClient signaling,
    required this.room,
    required this.peerId,
    required String psk,
  }) : _signaling = signaling,
       _psk = psk {
    _state.add(RemoteChannelState.open);
    _open = true;
    _sub = _signaling.incoming.listen(_onSignal, onDone: _onClosed);
  }

  /// The broker room (the paired device id).
  final String room;

  /// This server's signaling peer id within the room.
  final String peerId;

  final SignalingRelayClient _signaling;
  final String _psk;

  final StreamController<Map<String, dynamic>> _incoming =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<RemoteChannelState> _state =
      StreamController<RemoteChannelState>.broadcast();
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _open = false;

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  @override
  Stream<RemoteChannelState> get state => _state.stream;

  @override
  bool get isOpen => _open;

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    if (!_open) {
      throw StateError('RelayRemoteTransport is not open');
    }
    final sealed = RelayFrameCrypto.seal(jsonEncode(frame), _psk);
    _signaling.send({
      'type': 'signal',
      'room': room,
      'from': peerId,
      'kind': 'rpc',
      'payload': {'e': sealed},
    });
  }

  @override
  Future<void> close() async {
    _onClosed();
  }

  void _onSignal(Map<String, dynamic> frame) {
    final type = frame['type'];
    if (type == 'peer-left') {
      // The phone (or its socket) went away — end this connection's session.
      // The host keeps the SignalingRelayClient joined for the next attempt.
      _onClosed();
      return;
    }
    if (type != 'signal' || frame['kind'] != 'rpc') {
      return;
    }
    final payload = frame['payload'];
    if (payload is! Map || payload['e'] is! String) {
      return;
    }
    final String clear;
    try {
      clear = RelayFrameCrypto.open(payload['e'] as String, _psk);
    } on RelayFrameAuthException {
      // A frame we can't authenticate is hostile/corrupt — drop it. Never feed
      // unauthenticated bytes to the RPC session.
      return;
    }
    try {
      final decoded = jsonDecode(clear);
      if (decoded is Map<String, dynamic>) {
        _incoming.add(decoded);
      }
    } catch (_) {
      // Malformed inner JSON — drop.
    }
  }

  void _onClosed() {
    if (!_open) {
      return;
    }
    _open = false;
    unawaited(_sub?.cancel());
    if (!_state.isClosed) {
      _state.add(RemoteChannelState.closed);
      unawaited(_state.close());
    }
    if (!_incoming.isClosed) {
      unawaited(_incoming.close());
    }
  }
}
