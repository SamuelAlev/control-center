import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:cc_remote/debug_log.dart';
import 'package:web/web.dart' as web;

/// The set of message types exchanged with the signaling broker.
///
/// Mirrors the desktop's `SignalingMessageType` wire strings byte-for-byte so
/// the two ends and the broker agree on one envelope. The broker is a
/// stateless relay: it emits `joined`/`peer-joined`/`peer-left`/`error` and
/// relays `signal`/`join`/`bye` without interpreting `payload`.
enum SignalingType {
  join('join'),
  joined('joined'),
  peerJoined('peer-joined'),
  signal('signal'),
  bye('bye'),
  peerLeft('peer-left'),
  error('error');

  const SignalingType(this.wire);

  /// The wire string used in the JSON envelope.
  final String wire;

  /// Resolves a wire string back to the enum, or `null` when unknown.
  static SignalingType? fromWire(String? wire) {
    for (final v in SignalingType.values) {
      if (v.wire == wire) {
        return v;
      }
    }
    return null;
  }
}

/// One signaling frame exchanged with the broker or the peer behind it.
///
/// `kind` disambiguates `signal` payloads: `'offer'`, `'answer'`, or `'ice'`.
/// `payload` carries the opaque SDP (`{sdp, type}`) or ICE candidate
/// (`{candidate, sdpMid, sdpMLineIndex}`) blob. This is the exact shape the
/// desktop's `SignalingMessage` (de)serializes, so frames interoperate without
/// translation.
class SignalingFrame {
  /// Creates a [SignalingFrame].
  const SignalingFrame({
    required this.type,
    this.room,
    this.from,
    this.to,
    this.kind,
    this.payload,
    this.error,
  });

  /// Deserializes a frame from a JSON envelope.
  factory SignalingFrame.fromJson(Map<String, dynamic> json) {
    return SignalingFrame(
      type:
          SignalingType.fromWire(json['type'] as String?) ??
          SignalingType.error,
      room: json['room'] as String?,
      from: json['from'] as String?,
      to: json['to'] as String?,
      kind: json['kind'] as String?,
      payload: json['payload'] is Map<String, dynamic>
          ? json['payload'] as Map<String, dynamic>
          : null,
      error: json['error'] as String?,
    );
  }

  /// The envelope type.
  final SignalingType type;

  /// Room id (the pairing code).
  final String? room;

  /// Sender peer id.
  final String? from;

  /// Recipient peer id.
  final String? to;

  /// For `signal`: `'offer'`, `'answer'`, or `'ice'`.
  final String? kind;

  /// For `signal`: the opaque SDP or ICE-candidate blob.
  final Map<String, dynamic>? payload;

  /// For `error`: the broker's error text.
  final String? error;

  /// Serializes the envelope to JSON.
  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'type': type.wire};
    if (room != null) {
      json['room'] = room;
    }
    if (from != null) {
      json['from'] = from;
    }
    if (to != null) {
      json['to'] = to;
    }
    if (kind != null) {
      json['kind'] = kind;
    }
    if (payload != null) {
      json['payload'] = payload;
    }
    if (error != null) {
      json['error'] = error;
    }
    return json;
  }
}

/// A browser WebSocket signaling client speaking the broker envelope.
///
/// The phone joins the pairing room, then the [RtcTransport] relays the WebRTC
/// offer/answer/ICE through this connection. The broker only ever sees opaque
/// SDP/ICE blobs — never app data or the PSK.
class SignalingClient {
  /// Creates a [SignalingClient] for [signalingUrl] (a `wss://…` endpoint).
  SignalingClient(this.signalingUrl);

  /// The broker WebSocket URL.
  final String signalingUrl;

  web.WebSocket? _socket;
  final StreamController<SignalingFrame> _incoming =
      StreamController<SignalingFrame>.broadcast();
  bool _closed = false;

  /// Decoded inbound frames from the broker.
  Stream<SignalingFrame> get incoming => _incoming.stream;

  /// Whether the underlying socket is open.
  bool get isOpen =>
      _socket != null && _socket!.readyState == web.WebSocket.OPEN;

  /// Opens the socket, joins [room] as [peerId], and awaits the broker's
  /// `joined` ack. Throws on connect/timeout/error.
  Future<void> connect({
    required String room,
    required String peerId,
    Duration timeout = const Duration(seconds: 15),
  }) async {
    if (_socket != null) {
      throw StateError('SignalingClient already connected');
    }

    // Refuse plaintext signaling to a non-loopback host (finding #12): `ws://`
    // would expose the room code, peer ids, and SDP (DTLS fingerprints +
    // internal-IP ICE) to any network sniffer. `wss://` is required; `ws://` is
    // allowed only for a local dev broker (a secure context).
    if (!_isSecureSignalingUrl(signalingUrl)) {
      throw const SignalingException(
        'Insecure signaling URL — use wss:// (ws:// only for localhost)',
      );
    }

    final openCompleter = Completer<void>();

    // No WebSocket subprotocol: a browser hard-fails the handshake if it offers
    // one the broker doesn't echo back (and our broker is a pure JSON relay with
    // nothing to negotiate). The native desktop client (`dart:io`) is lenient
    // about this, but Chrome is not — offering 'cc-signaling' here aborts the
    // connection against any broker that doesn't select it.
    rlog('ws', 'opening socket → $signalingUrl');
    final socket = web.WebSocket(signalingUrl);
    _socket = socket;

    socket.onopen = ((web.Event _) {
      rlog('ws', 'socket open (readyState=${socket.readyState})');
      if (!openCompleter.isCompleted) {
        openCompleter.complete();
      }
    }).toJS;
    socket.onerror = ((web.Event _) {
      rlog('ws', 'socket error event (readyState=${socket.readyState})');
      if (!openCompleter.isCompleted) {
        openCompleter.completeError(
          const SignalingException('Signaling socket error'),
        );
      }
    }).toJS;
    socket.onclose = ((web.Event e) {
      final close = e as web.CloseEvent;
      rlog(
        'ws',
        'socket closed code=${close.code} clean=${close.wasClean} '
            'reason="${close.reason}"',
      );
      if (!openCompleter.isCompleted) {
        openCompleter.completeError(
          SignalingException(
            'Signaling socket closed before open (code ${close.code})',
          ),
        );
      }
      _handleClosed();
    }).toJS;
    socket.onmessage = ((web.Event e) {
      _handleMessage(e as web.MessageEvent);
    }).toJS;

    await openCompleter.future.timeout(
      timeout,
      onTimeout: () {
        rlog('ws', 'timed out waiting for socket to open (${timeout.inSeconds}s)');
        throw TimeoutException('Signaling socket did not open');
      },
    );

    // Await the broker's `joined` ack — or an `error` (e.g. "room full"). Build
    // the wait BEFORE sending `join` so an immediate error isn't missed, and use
    // `orElse` so a socket close surfaces as a clear exception rather than the
    // opaque `StateError: No element` from `Stream.first` on a done stream.
    rlog('ws', 'sending join room=$room as $peerId');
    final ackFuture = _incoming.stream.firstWhere(
      (f) => f.type == SignalingType.joined || f.type == SignalingType.error,
      orElse: () => const SignalingFrame(
        type: SignalingType.error,
        error: 'connection closed before the join was acknowledged',
      ),
    );
    send(SignalingFrame(type: SignalingType.join, room: room, from: peerId));
    final ack = await ackFuture.timeout(
      timeout,
      onTimeout: () {
        rlog('ws', 'no joined ack from broker (${timeout.inSeconds}s)');
        throw TimeoutException('No joined ack from broker');
      },
    );
    if (ack.type == SignalingType.error) {
      rlog('ws', 'join rejected: ${ack.error}');
      throw SignalingException(ack.error ?? 'Join rejected by broker');
    }
    rlog('ws', 'joined ack received');
  }

  /// Sends a frame to the broker. No-op when the socket is not open.
  void send(SignalingFrame frame) {
    final socket = _socket;
    if (socket == null || socket.readyState != web.WebSocket.OPEN) {
      return;
    }
    socket.send(jsonEncode(frame.toJson()).toJS);
  }

  /// Leaves the room cleanly before closing.
  void sendBye({String? room, String? from}) {
    send(SignalingFrame(type: SignalingType.bye, room: room, from: from));
  }

  /// Closes the socket. Idempotent.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    final socket = _socket;
    _socket = null;
    if (socket != null && socket.readyState < web.WebSocket.CLOSING) {
      socket.close();
    }
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
  }

  // --- internals ---------------------------------------------------------

  /// Whether [url] is an acceptable signaling endpoint: `wss://` anywhere, or
  /// plain `ws://` only to a loopback host (a local dev broker is a secure
  /// context). Mirrors the desktop's check.
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

  void _handleMessage(web.MessageEvent event) {
    if (_closed) {
      return;
    }
    final data = event.data;
    if (!data.isA<JSString>()) {
      // Only text frames carry JSON; ignore binary.
      return;
    }
    try {
      final decoded = jsonDecode((data as JSString).toDart);
      if (decoded is Map<String, dynamic>) {
        final frame = SignalingFrame.fromJson(decoded);
        if (frame.type == SignalingType.error) {
          rlog('ws', 'broker error: ${frame.error}');
        } else if (frame.type != SignalingType.signal || frame.kind != 'ice') {
          // Log everything except the noisy per-candidate ICE relays.
          final kind = frame.kind != null ? '/${frame.kind}' : '';
          rlog('ws', 'recv ${frame.type.wire}$kind from=${frame.from}');
        }
        _incoming.add(frame);
      }
    } catch (_) {
      // Ignore malformed frames.
    }
  }

  void _handleClosed() {
    if (_closed) {
      return;
    }
    _closed = true;
    if (!_incoming.isClosed) {
      _incoming.close();
    }
  }
}

/// Thrown on a signaling-level failure (socket error, close, broker error).
class SignalingException implements Exception {
  const SignalingException(this.message);

  final String message;

  @override
  String toString() => 'SignalingException: $message';
}
