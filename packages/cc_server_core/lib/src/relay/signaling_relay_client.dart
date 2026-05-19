import 'dart:async';
import 'dart:convert';

import 'package:web_socket_channel/web_socket_channel.dart';

/// A pure-Dart client of the signaling broker, used by cc_server to RENDEZVOUS
/// with a phone when the server is not directly reachable.
///
/// cc_server joins a room (the device id) as one of the broker's two peers and
/// relays the phone's JSON-RPC through `signal` frames. This mirrors the phone's
/// `SignalingClient` and the desktop's, but is pure Dart (`web_socket_channel`
/// on the VM) so it runs in the headless binary with no Flutter. The broker is a
/// dumb relay and never sees plaintext — the frames it carries are sealed with
/// the pairing PSK (see `RelayRemoteTransport` / `RelayFrameCrypto`).
///
/// Wire envelope (matches `SignalingBroker`): client sends `join` / `signal` /
/// `bye`; the broker emits `joined` / `peer-joined` / `peer-left` / `error`.
class SignalingRelayClient {
  /// Creates a client for [signalingUrl] (a `wss://…` or loopback `ws://` URL).
  SignalingRelayClient(this.signalingUrl);

  /// The broker WebSocket URL.
  final String signalingUrl;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _sub;
  final StreamController<Map<String, dynamic>> _incoming =
      StreamController<Map<String, dynamic>>.broadcast();
  bool _open = false;
  bool _closed = false;

  /// Decoded inbound broker frames (each a JSON object with a `type`).
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  /// Whether the socket is open and joined.
  bool get isOpen => _open;

  /// Opens the socket, joins [room] as [peerId], and awaits the broker's
  /// `joined` ack. Throws on insecure URL, connect failure, timeout, or a
  /// rejecting `error` (e.g. "room full").
  Future<void> connect({
    required String room,
    required String peerId,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_channel != null) {
      throw StateError('SignalingRelayClient already connected');
    }
    if (!_isSecureSignalingUrl(signalingUrl)) {
      throw const SignalingRelayException(
        'Insecure signaling URL — use wss:// (ws:// only for localhost)',
      );
    }

    final channel = WebSocketChannel.connect(Uri.parse(signalingUrl));
    _channel = channel;
    await channel.ready.timeout(timeout);
    _open = true;
    _sub = channel.stream.listen(
      (Object? data) {
        if (data is! String) {
          return;
        }
        try {
          final decoded = jsonDecode(data);
          if (decoded is Map<String, dynamic>) {
            _incoming.add(decoded);
          }
        } catch (_) {
          // Ignore malformed frames.
        }
      },
      onDone: _handleClosed,
      onError: (Object _) => _handleClosed(),
      cancelOnError: true,
    );

    // Wait for `joined` (or a rejecting `error`); build the wait BEFORE sending
    // `join` so an immediate error isn't missed.
    final ack = _incoming.stream
        .firstWhere(
          (f) => f['type'] == 'joined' || f['type'] == 'error',
          orElse: () => const {'type': 'error', 'error': 'closed before join'},
        )
        .timeout(timeout);
    send({'type': 'join', 'room': room, 'from': peerId});
    final frame = await ack;
    if (frame['type'] == 'error') {
      throw SignalingRelayException(
        (frame['error'] as String?) ?? 'join rejected by broker',
      );
    }
  }

  /// Sends a raw broker frame. No-op when the socket is closed.
  void send(Map<String, dynamic> frame) {
    final channel = _channel;
    if (channel == null || !_open) {
      return;
    }
    channel.sink.add(jsonEncode(frame));
  }

  /// Sends a `bye` for [room] from [peerId] (best-effort), then closes.
  Future<void> close({String? room, String? peerId}) async {
    if (_closed) {
      return;
    }
    if (_open && room != null) {
      send({'type': 'bye', 'room': room, 'from': ?peerId});
    }
    _closed = true;
    _open = false;
    await _sub?.cancel();
    await _channel?.sink.close();
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

  /// `wss://` anywhere, or `ws://` only to a loopback host (a local dev broker
  /// is a secure context). Mirrors the phone/desktop checks.
  static bool _isSecureSignalingUrl(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      return false;
    }
    if (uri.scheme == 'wss') {
      return true;
    }
    if (uri.scheme == 'ws') {
      final host = uri.host.toLowerCase();
      return host == 'localhost' || host == '127.0.0.1' || host == '::1';
    }
    return false;
  }
}

/// Thrown when the signaling relay client cannot join or stay in a room.
class SignalingRelayException implements Exception {
  /// Creates a [SignalingRelayException].
  const SignalingRelayException(this.message);

  /// Human-readable reason.
  final String message;

  @override
  String toString() => 'SignalingRelayException: $message';
}
