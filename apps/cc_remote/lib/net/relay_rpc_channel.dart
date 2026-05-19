import 'dart:async';
import 'dart:convert';

import 'package:cc_remote/auth/relay_frame_crypto.dart';
import 'package:cc_remote/debug_log.dart';
import 'package:cc_remote/net/rpc_channel.dart';
import 'package:cc_rpc/cc_rpc.dart' hide RelayFrameCrypto, RelayFrameAuthException;
import 'package:cc_remote/rtc/signaling_client.dart';

/// A [RemoteRpcChannelPort] that carries JSON-RPC to cc_server THROUGH the
/// signaling broker, end-to-end-encrypted with the pairing PSK.
///
/// Used when cc_server owns the connection but is not directly reachable from
/// the phone (different networks / NAT): the phone and cc_server both join the
/// broker room (the device id) and relay frames as opaque `signal` payloads.
/// This is the phone twin of the server's `RelayRemoteTransport` — the broker
/// only ever sees ciphertext ([RelayFrameCrypto]).
class RelayRpcChannel implements RemoteRpcChannelPort {
  /// Wraps a [signaling] client for [room] (the device id), identifying as
  /// [peerId] and sealing with [psk]. Subscribes immediately so a `peer-joined`
  /// that arrives during the join handshake is never missed.
  RelayRpcChannel({
    required SignalingClient signaling,
    required this.room,
    required this.peerId,
    required String psk,
  })  : _signaling = signaling,
        _psk = psk {
    _sub = _signaling.incoming.listen(_onFrame, onDone: _onClosed);
  }

  /// The broker room — the paired device id.
  final String room;

  /// This phone's signaling peer id.
  final String peerId;

  final SignalingClient _signaling;
  final String _psk;

  final StreamController<Map<String, dynamic>> _incoming =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<RemoteChannelState> _state =
      StreamController<RemoteChannelState>.broadcast();
  StreamSubscription<SignalingFrame>? _sub;
  final Completer<void> _ready = Completer<void>();
  bool _open = false;

  /// Resolves once cc_server is present in the room (`peer-joined`), so callers
  /// only run the auth handshake when there is someone to answer it.
  Future<void> awaitReady({Duration timeout = const Duration(seconds: 20)}) {
    return _ready.future.timeout(
      timeout,
      onTimeout: () => throw const RpcNotConnectedException(
        'Timed out waiting for your computer to join the pairing room',
      ),
    );
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
      throw const RpcNotConnectedException();
    }
    final sealed = RelayFrameCrypto.seal(jsonEncode(frame), _psk);
    _signaling.send(
      SignalingFrame(
        type: SignalingType.signal,
        room: room,
        from: peerId,
        kind: 'rpc',
        payload: {'e': sealed},
      ),
    );
  }

  @override
  Future<void> close() async {
    if (!_open && _state.isClosed) {
      return;
    }
    _open = false;
    await _sub?.cancel();
    _sub = null;
    _signaling.sendBye(room: room, from: peerId);
    await _signaling.close();
    if (!_state.isClosed) {
      _state.add(RemoteChannelState.closed);
      await _state.close();
    }
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
  }

  void _onFrame(SignalingFrame frame) {
    switch (frame.type) {
      case SignalingType.peerJoined:
        if (!_ready.isCompleted) {
          _ready.complete();
          _open = true;
          _state.add(RemoteChannelState.open);
        }
      case SignalingType.peerLeft:
        rlog('relay', 'peer left room $room — closing channel');
        _onClosed();
      case SignalingType.signal:
        if (frame.kind != 'rpc') {
          return;
        }
        final payload = frame.payload;
        final sealed = payload?['e'];
        if (sealed is! String) {
          return;
        }
        try {
          final clear = RelayFrameCrypto.open(sealed, _psk);
          final decoded = jsonDecode(clear);
          if (decoded is Map<String, dynamic>) {
            _incoming.add(decoded);
          }
        } on RelayFrameAuthException {
          // A frame we can't authenticate is hostile/corrupt — drop it.
          rlog('relay', 'dropped a frame that failed authentication');
        } catch (_) {
          // Malformed inner JSON — drop.
        }
      case SignalingType.joined:
      case SignalingType.join:
      case SignalingType.bye:
      case SignalingType.error:
        break;
    }
  }

  void _onClosed() {
    if (_state.isClosed) {
      return;
    }
    _open = false;
    if (!_ready.isCompleted) {
      _ready.completeError(
        const RpcNotConnectedException('Pairing room closed before connecting'),
      );
    }
    _state.add(RemoteChannelState.closed);
    unawaited(_state.close());
    if (!_incoming.isClosed) {
      unawaited(_incoming.close());
    }
  }
}
