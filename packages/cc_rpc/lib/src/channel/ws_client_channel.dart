import 'dart:async';

import 'package:cc_rpc/src/channel/frame_codec.dart';
import 'package:cc_rpc/src/channel/remote_rpc_channel_port.dart';
import 'package:cc_rpc/src/client/remote_channel_auth.dart';
import 'package:cc_rpc/src/client/remote_rpc_client.dart';
import 'package:cc_rpc/src/transport_security_policy.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Client-side [RemoteRpcChannelPort] over a [WebSocketChannel].
///
/// Cross-platform via `web_socket_channel` (a `dart:io` socket on the VM, a
/// browser `WebSocket` on web) — so the desktop in REMOTE mode and the web
/// build dial a `LocalRpcServer` with the *same* code. Buffers early frames so
/// the auth handshake's first reply is never dropped before a listener attaches.
class WsClientChannel implements RemoteRpcChannelPort {
  WsClientChannel._(this._ws);

  /// Connects to [uri] (e.g. `ws://localhost:9030/rpc`) and begins reading.
  ///
  /// Enforces the TLS-or-loopback invariant: plaintext `ws://` may only
  /// target this machine unless the server's descriptor explicitly allows
  /// insecure transport ([insecureAllowed], the `--insecure` escape hatch).
  static Future<WsClientChannel> connect(
    Uri uri, {
    bool insecureAllowed = false,
  }) async {
    TransportSecurityPolicy.enforce(uri, insecureAllowed: insecureAllowed);
    final ws = WebSocketChannel.connect(uri);
    await ws.ready;
    return WsClientChannel._(ws).._start();
  }

  final WebSocketChannel _ws;
  final StreamController<Map<String, dynamic>> _incoming =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<RemoteChannelState> _state =
      StreamController<RemoteChannelState>.broadcast();
  final List<Map<String, dynamic>> _pending = [];
  bool _open = false;

  /// Cap on frames buffered while no listener has attached yet, mirroring the
  /// server's `WsRemoteTransport._maxPendingFrames`. Buffer-until-listener
  /// exists so the auth handshake's first reply is never dropped — but with no
  /// cap, a peer that streams frames at a client which never listens grows this
  /// list without limit. Overflow closes the channel, exactly as the server
  /// does: an unread channel is already broken.
  static const int _maxPendingFrames = 64;

  /// Tail of the decode chain: frames decode asynchronously (large ones in a
  /// worker isolate on the VM) but are DELIVERED strictly in arrival order —
  /// snapshot/response ordering is part of the protocol contract.
  Future<void> _decodeChain = Future.value();

  void _start() {
    _open = true;
    _incoming.onListen = _flushPending;
    _state.add(RemoteChannelState.open);
    _ws.stream.listen(
      (data) {
        if (data is! String) {
          return;
        }
        _decodeChain = _decodeChain.then((_) async {
          try {
            final frame = await decodeJsonFrame(data);
            if (_incoming.hasListener) {
              _incoming.add(frame);
            } else if (_pending.length >= _maxPendingFrames) {
              _onClosed();
            } else {
              _pending.add(frame);
            }
          } catch (_) {
            // Ignore malformed frames.
          }
        });
      },
      onDone: _onClosed,
      onError: (Object _) => _onClosed(),
      cancelOnError: true,
    );
  }

  void _flushPending() {
    if (_pending.isEmpty) {
      return;
    }
    final buffered = List<Map<String, dynamic>>.of(_pending);
    _pending.clear();
    for (final f in buffered) {
      _incoming.add(f);
    }
  }

  void _onClosed() {
    if (!_open) {
      return;
    }
    _open = false;
    if (!_state.isClosed) {
      _state.add(RemoteChannelState.closed);
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
      throw StateError('WsClientChannel is not open');
    }
    // Large frames encode off the UI isolate, mirroring the receive path.
    _ws.sink.add(await encodeJsonFrame(frame));
  }

  @override
  Future<void> close() async {
    _onClosed();
    await _ws.sink.close();
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
    if (!_state.isClosed) {
      await _state.close();
    }
  }
}

/// Connects to a cc-server's WSS endpoint, runs the PSK auth handshake and
/// returns a started [RemoteRpcClient] ready for `repo/call` / `sub/subscribe`.
///
/// The handshake (shared with the relay path, see `authenticateRemoteChannel`)
/// proves PSK possession both ways and verifies the server's Ed25519 identity
/// against [pinnedFingerprint] when one is supplied (TOFU pinning — a changed
/// fingerprint is a hard refusal). Throws [StateError] on auth failure or
/// timeout (fail closed).
Future<RemoteRpcClient> connectRemoteRpc({
  required Uri uri,
  required String deviceId,
  required String psk,
  String? pinnedFingerprint,
  bool insecureAllowed = false,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final channel = await WsClientChannel.connect(
    uri,
    insecureAllowed: insecureAllowed,
  );
  final result = await authenticateRemoteClient(
    channel: channel,
    deviceId: deviceId,
    psk: psk,
    pinnedFingerprint: pinnedFingerprint,
    timeout: timeout,
  );
  return result.client;
}
