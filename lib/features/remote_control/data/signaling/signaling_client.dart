import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/remote_control/data/signaling/signaling_message.dart';

/// WebSocket client for the pairing signaling broker.
///
/// Carries **only** opaque SDP/ICE blobs — it never sees app data or the PSK.
/// The desktop joins the pairing room (the QR's room code) and relays
/// `offer`/`answer`/`ice` frames to/from the phone.
///
/// **Stays joined for the device's lifetime.** Once connected it keeps a
/// presence in the room across phone connect/disconnect cycles, and silently
/// reconnects (with capped exponential backoff) and re-joins if the broker
/// socket drops — a broker blip, restart, or idle-room reap. This is what lets
/// a phone reconnect (e.g. a browser refresh) without the desktop being
/// restarted: the broker only emits `peer-joined` when a room *becomes shared*,
/// so the desktop must remain in the room for the next joiner to be noticed.
/// A broker drop is therefore **not** surfaced as a `peer-left` — only a real
/// peer leaving is — so the owner never mistakes a transient broker blip for
/// the phone hanging up.
class SignalingClient {
  /// Creates a [SignalingClient] for the broker at [url].
  SignalingClient({
    required this.url,
    required this.room,
    required this.peerId,
  });

  /// The broker WebSocket URL (`wss://…`).
  final Uri url;

  /// The pairing room code (shared via the QR).
  final String room;

  /// This peer's id (the desktop's app-instance id).
  final String peerId;

  /// First reconnect delay; doubles each attempt up to [_maxReconnectDelay].
  static const Duration _baseReconnectDelay = Duration(milliseconds: 500);

  /// Reconnect backoff ceiling.
  static const Duration _maxReconnectDelay = Duration(seconds: 10);

  WebSocket? _socket;
  StreamSubscription? _sub;
  bool _closed = false;
  Timer? _reconnectTimer;
  int _reconnectAttempts = 0;

  final _incoming = StreamController<SignalingMessage>.broadcast();

  /// Inbound signaling frames from the broker (peer `signal`/`peer-left`/
  /// `error`). Survives reconnects — it is closed only by [close].
  Stream<SignalingMessage> get incoming => _incoming.stream;

  /// Opens the WebSocket and joins [room], then keeps the membership alive by
  /// reconnecting on any unexpected socket close until [close] is called. A
  /// failed initial connect schedules a retry rather than throwing, so a broker
  /// that is briefly unreachable at startup doesn't strand the device.
  Future<void> connect() async {
    if (_closed) {
      return;
    }
    await _open();
  }

  /// Whether [uri] is an acceptable signaling endpoint: `wss://` everywhere, or
  /// plain `ws://` only to a loopback host (a local dev broker is a secure
  /// context). Plaintext `ws://` to a non-loopback host would expose room codes,
  /// peer ids, and SDP (DTLS fingerprints + internal-IP ICE) to a sniffer
  /// (finding #12) — so it is refused.
  static bool isSecureSignalingUrl(Uri uri) {
    if (uri.scheme == 'wss') {
      return true;
    }
    if (uri.scheme == 'ws') {
      final host = uri.host.toLowerCase();
      return host == 'localhost' || host == '127.0.0.1' || host == '::1';
    }
    return false;
  }

  /// Opens the socket and (re)joins the room. No-op if already open or closed.
  Future<void> _open() async {
    if (_closed || _socket != null) {
      return;
    }
    if (!isSecureSignalingUrl(url)) {
      AppLog.e(
        'RemoteControl',
        'Refusing insecure signaling URL "$url" — use wss:// (ws:// is allowed '
            'only for loopback). Not connecting.',
      );
      _closed = true;
      return;
    }
    AppLog.i('RemoteControl', 'Signaling: connecting to $url room=$room');
    final WebSocket socket;
    try {
      socket = await WebSocket.connect(
        url.toString(),
        // Avoid the default `dart` subprotocol some brokers reject.
        protocols: const ['cc-signaling'],
      );
    } catch (e) {
      AppLog.w('RemoteControl', 'Signaling connect failed (room=$room): $e');
      _scheduleReconnect();
      return;
    }
    if (_closed) {
      await socket.close();
      return;
    }
    _socket = socket;
    // A successful open resets the backoff so the next drop reconnects promptly.
    _reconnectAttempts = 0;
    _sub = socket.listen(
      _onData,
      onError: (Object e, StackTrace st) =>
          AppLog.e('RemoteControl', 'Signaling socket error: $e', e, st),
      onDone: _onDone,
    );
    await send(
      SignalingMessage(
        type: SignalingMessageType.join,
        room: room,
        from: peerId,
      ),
    );
  }

  void _onData(dynamic data) {
    if (data is! String) {
      return;
    }
    try {
      final json = jsonDecode(data);
      if (json is! Map<String, dynamic>) {
        return;
      }
      final msg = SignalingMessage.fromJson(json);
      // Surface only the frames a peer cares about; join acks are noise here.
      if (msg.type == SignalingMessageType.signal ||
          msg.type == SignalingMessageType.peerLeft ||
          msg.type == SignalingMessageType.error) {
        _incoming.add(msg);
      }
    } catch (e, st) {
      AppLog.e('RemoteControl', 'Signaling: bad frame: $e', e, st);
    }
  }

  void _onDone() {
    _sub = null;
    _socket = null;
    if (_closed) {
      return;
    }
    // A broker drop is not a peer leaving — do NOT surface a `peer-left` (that
    // would tear down a live RTC session, which survives a broker blip). Just
    // reconnect and re-join so the room presence — and the phone's ability to
    // reconnect — is restored.
    AppLog.w(
      'RemoteControl',
      'Signaling socket closed (room=$room) — reconnecting',
    );
    _scheduleReconnect();
  }

  void _scheduleReconnect() {
    if (_closed || _reconnectTimer != null) {
      return;
    }
    final shift = _reconnectAttempts.clamp(0, 5);
    final millis = (_baseReconnectDelay.inMilliseconds * (1 << shift)).clamp(
      _baseReconnectDelay.inMilliseconds,
      _maxReconnectDelay.inMilliseconds,
    );
    _reconnectAttempts++;
    _reconnectTimer = Timer(Duration(milliseconds: millis), () {
      _reconnectTimer = null;
      unawaited(_open());
    });
  }

  /// Sends a signaling frame to the broker.
  Future<void> send(SignalingMessage message) async {
    final socket = _socket;
    if (socket == null || _closed) {
      return;
    }
    socket.add(jsonEncode(message.toJson()));
  }

  /// Closes the connection. After this, [incoming] is done. Idempotent. Cancels
  /// any pending reconnect so a dropped socket doesn't resurrect the client.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    // Leave the room cleanly first so the broker frees our slot immediately,
    // rather than holding it on a half-closed socket — otherwise a stale
    // connection can keep a capacity-limited room "full" for the phone.
    final socket = _socket;
    if (socket != null) {
      try {
        socket.add(
          jsonEncode(
            SignalingMessage(
              type: SignalingMessageType.bye,
              room: room,
              from: peerId,
            ).toJson(),
          ),
        );
      } catch (_) {
        // Best-effort; the socket close below still tears us down.
      }
    }
    _closed = true;
    await _sub?.cancel();
    _sub = null;
    try {
      await _socket?.close();
    } catch (_) {
      // Already closed.
    }
    _socket = null;
    await _incoming.close();
  }
}
