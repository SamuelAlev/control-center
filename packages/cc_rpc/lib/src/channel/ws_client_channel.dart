import 'dart:async';

import 'package:cc_rpc/src/channel/frame_codec.dart';
import 'package:cc_rpc/src/channel/remote_rpc_channel_port.dart';
import 'package:cc_rpc/src/client/remote_channel_auth.dart';
import 'package:cc_rpc/src/client/remote_rpc_client.dart';
import 'package:cc_rpc/src/crypto/server_identity.dart';
import 'package:cc_rpc/src/transport_security_policy.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

/// Client-side [RemoteRpcChannelPort] over a [WebSocketChannel].
///
/// Cross-platform via `web_socket_channel` (a `dart:io` socket on the VM, a
/// browser `WebSocket` on web) — so the desktop in REMOTE mode and the web
/// build dial a `LocalRpcServer` with the *same* code. Buffers early frames so
/// the Noise handshake's first reply survives until a listener attaches.
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
  bool _aborted = false;

  /// A raw frame is one Noise record, not an assembled application message.
  static const int _maxFrameBytes = 64 * 1024;
  static const int _maxPendingFrames = 64;
  static const int _maxQueuedDecodes = 128;

  /// Decode asynchronously without allowing a fast socket to grow an
  /// unbounded queue or to reorder records around a slower decode.
  Future<void> _decodeChain = Future<void>.value();
  int _queuedDecodes = 0;

  void _start() {
    _open = true;
    _incoming.onListen = _flushPending;
    _state.add(RemoteChannelState.open);
    _ws.stream.listen(
      (data) {
        if (data is! String ||
            data.length > _maxFrameBytes ||
            _queuedDecodes >= _maxQueuedDecodes) {
          unawaited(close());
          return;
        }
        _queuedDecodes++;
        _decodeChain = _decodeChain.then((_) async {
          try {
            if (_aborted) {
              return;
            }
            final frame = await decodeJsonFrame(data);
            if (_aborted) {
              return;
            }
            if (_incoming.hasListener) {
              _incoming.add(frame);
            } else if (_pending.length >= _maxPendingFrames) {
              unawaited(close());
            } else {
              _pending.add(frame);
            }
          } catch (_) {
            // Invalid raw JSON cannot be interpreted as an encrypted record.
            unawaited(close());
          } finally {
            _queuedDecodes--;
          }
        });
      },
      onDone: () => unawaited(_onRemoteDone()),
      onError: (Object _) => unawaited(close()),
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

  Future<void> _onRemoteDone() async {
    if (_aborted || !_open) {
      return;
    }
    _open = false;
    _state.add(RemoteChannelState.closed);
    // The socket's done event follows its data events, but JSON decode can
    // still be in progress. End incoming only after every queued record.
    await _decodeChain;
    if (_aborted) {
      return;
    }
    unawaited(_incoming.close());
    unawaited(_state.close());
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
    final encoded = await encodeJsonFrame(frame);
    if (encoded.length > _maxFrameBytes) {
      throw StateError('WsClientChannel record exceeds wire cap');
    }
    if (!_open) {
      throw StateError('WsClientChannel is not open');
    }
    _ws.sink.add(encoded);
  }

  @override
  Future<void> close() async {
    if (_aborted) {
      return;
    }
    _aborted = true;
    if (_open) {
      _open = false;
      _state.add(RemoteChannelState.closed);
    }
    _pending.clear();
    // Local close (including malformed traffic) aborts queued decodes now.
    unawaited(_incoming.close());
    unawaited(_state.close());
    await _ws.sink.close();
  }
}

/// Connects to a cc-server's WSS endpoint and returns an initialized RPC
/// client over the authenticated Noise session.
///
/// The client proves its 32-byte pairing PSK, requires the server's signed
/// Ed25519 identity even on first contact, and rejects a changed
/// [pinnedFingerprint]. There is no plaintext fallback. Authentication
/// rejection yields [AuthRejectedException]; a changed pin yields
/// [ServerIdentityMismatchException]. [timeout] bounds the handshake and
/// [requestTimeout] bounds subsequent RPC calls.
Future<RemoteRpcClient> connectRemoteRpc({
  required Uri uri,
  required String deviceId,
  required String psk,
  String? pinnedFingerprint,
  bool insecureAllowed = false,
  Duration timeout = const Duration(seconds: 15),
  Duration requestTimeout = const Duration(seconds: 30),
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
    requestTimeout: requestTimeout,
  );
  return result.client;
}
