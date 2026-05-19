import 'dart:async';
import 'dart:convert';

import 'package:cc_rpc/src/channel/remote_rpc_channel_port.dart';
import 'package:cc_rpc/src/client/remote_rpc_client.dart';
import 'package:cc_rpc/src/crypto/remote_control_crypto.dart';
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
  static Future<WsClientChannel> connect(Uri uri) async {
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

  void _start() {
    _open = true;
    _incoming.onListen = _flushPending;
    _state.add(RemoteChannelState.open);
    _ws.stream.listen(
      (data) {
        if (data is! String) {
          return;
        }
        try {
          final frame = jsonDecode(data) as Map<String, dynamic>;
          if (_incoming.hasListener) {
            _incoming.add(frame);
          } else {
            _pending.add(frame);
          }
        } catch (_) {
          // Ignore malformed frames.
        }
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
    _ws.sink.add(jsonEncode(frame));
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

/// Connects to a cc-server's WSS endpoint, runs the PSK auth handshake, and
/// returns a started [RemoteRpcClient] ready for `repo/call` / `sub/subscribe`.
///
/// The handshake mirrors `LocalRpcServer`: the client proves PSK possession
/// (HMAC over a fresh nonce; WSS binds empty DTLS fingerprints — TLS is the MITM
/// guard), verifies the server's matching proof, then waits for `approved`.
/// Throws [StateError] on auth failure or timeout (fail closed).
Future<RemoteRpcClient> connectRemoteRpc({
  required Uri uri,
  required String deviceId,
  required String psk,
  Duration timeout = const Duration(seconds: 15),
}) async {
  final channel = await WsClientChannel.connect(uri);

  // Attach the handshake listeners BEFORE sending auth so the replies (which
  // arrive only after the server reads our frame) are never missed.
  //
  // The server answers the auth frame with EITHER `auth_response` (its matching
  // proof — proceed) or `auth_denied` (the device is not paired, the key does
  // not match, or the credential expired). Wait for either so a rejection fails
  // fast with a clear message instead of stalling until [timeout].
  final authReply = channel.incoming
      .firstWhere(
        (f) => f['type'] == 'auth_response' || f['type'] == 'auth_denied',
      )
      .timeout(timeout);
  final approved = channel.incoming
      .firstWhere((f) => f['type'] == 'approved')
      .timeout(timeout);
  // Keep `approved`'s error handled even if we bail before awaiting it (a failed
  // auth makes the server close without ever sending `approved`, so this future
  // times out — without this it would surface as an unhandled async error).
  unawaited(approved.catchError((_) => <String, dynamic>{}));

  final nonce = RemoteControlCrypto.generateNonce();
  final proof = RemoteControlCrypto.respondToChallenge(
    nonce: nonce,
    psk: psk,
    localFingerprint: '',
    remoteFingerprint: '',
  );
  await channel.send({
    'type': 'auth',
    'device_id': deviceId,
    'nonce': nonce,
    'proof': proof,
  });

  final Map<String, dynamic> resp;
  try {
    resp = await authReply;
  } catch (e) {
    await channel.close();
    throw StateError('Server did not complete auth: $e');
  }
  if (resp['type'] == 'auth_denied') {
    await channel.close();
    throw StateError(
      'Server rejected the device. Confirm the device id is paired on the '
      'server and the pairing key matches the one the server issued.',
    );
  }
  final ok = RemoteControlCrypto.verifyChallengeResponse(
    nonce: nonce,
    psk: psk,
    localFingerprint: '',
    remoteFingerprint: '',
    response: resp['response'] as String? ?? '',
  );
  if (!ok) {
    await channel.close();
    throw StateError('Server auth proof mismatch');
  }
  try {
    await approved;
  } catch (e) {
    await channel.close();
    throw StateError('Server did not approve the device: $e');
  }

  final client = RemoteRpcClient(channel)..start();
  await client.initialize();
  return client;
}
