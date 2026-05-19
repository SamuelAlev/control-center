import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_host/src/log/cc_host_log.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// [RemoteRpcChannelPort] backed by a [WebSocket].
///
/// This is the transport for the **reachable-server** path (LAN / Tailnet /
/// VPS / same-origin web): a client dials `wss://…/rpc`, the server upgrades the
/// connection and frames flow as JSON text. Confidentiality + integrity come
/// from TLS at the socket layer (vs. DTLS for the WebRTC path); the same
/// `RemoteRpcSession` and PSK auth ride on top, transport-agnostic.
///
/// Mirrors `WebRtcRemoteTransport`: a frame-size cap and a pending-frame buffer
/// (the client's first `auth_challenge` can arrive before a listener attaches).
class WsRemoteTransport implements RemoteRpcChannelPort {
  /// Wraps an already-upgraded WebSocket. Call [start] once to begin reading.
  WsRemoteTransport(this._socket, {this.label = 'ws'});

  final WebSocket _socket;

  /// A short label for logs (e.g. the device id or peer address).
  final String label;

  /// Hard cap on a single inbound frame before decode (DoS guard). RPC frames
  /// are small JSON; anything larger is abusive and closes the channel.
  static const int _maxFrameBytes = 256 * 1024;

  /// Cap on frames buffered while no listener is attached.
  static const int _maxPendingFrames = 64;

  StreamController<Map<String, dynamic>>? _incomingController;
  StreamController<RemoteChannelState>? _stateController;
  StreamSubscription<dynamic>? _socketSub;
  final List<Map<String, dynamic>> _pendingIncoming = [];
  bool _closed = false;
  bool _open = false;

  void _ensureControllers() {
    _incomingController ??= StreamController<Map<String, dynamic>>.broadcast(
      onListen: _flushPendingIncoming,
    );
    _stateController ??= StreamController<RemoteChannelState>.broadcast();
  }

  void _flushPendingIncoming() {
    final controller = _incomingController;
    if (controller == null || _pendingIncoming.isEmpty) {
      return;
    }
    final buffered = List<Map<String, dynamic>>.of(_pendingIncoming);
    _pendingIncoming.clear();
    for (final frame in buffered) {
      controller.add(frame);
    }
  }

  /// Begins reading the socket. Idempotent.
  void start() {
    if (_socketSub != null) {
      return;
    }
    _ensureControllers();
    _open = _socket.readyState == WebSocket.open;
    _stateController?.add(
      _open ? RemoteChannelState.open : RemoteChannelState.connecting,
    );
    _socketSub = _socket.listen(
      _onData,
      onError: (Object e, StackTrace st) {
        CcHostLog.warning('WS error ($label): $e');
        unawaited(close());
      },
      onDone: () => unawaited(close()),
      cancelOnError: true,
    );
    // A freshly-upgraded socket is open; surface it so listeners don't miss it.
    if (_open) {
      CcHostLog.info('WS channel open ($label)');
    }
  }

  void _onData(dynamic data) {
    if (data is! String) {
      CcHostLog.warning('Ignoring non-text WS frame ($label)');
      return;
    }
    if (data.length > _maxFrameBytes) {
      CcHostLog.warning(
        'WS frame ($label) is ${data.length}B (> $_maxFrameBytes) — closing',
      );
      unawaited(close());
      return;
    }
    try {
      final decoded = jsonDecode(data) as Map<String, dynamic>;
      final controller = _incomingController;
      if (controller == null) {
        return;
      }
      if (controller.hasListener) {
        controller.add(decoded);
      } else {
        if (_pendingIncoming.length >= _maxPendingFrames) {
          CcHostLog.warning('WS pending buffer overflow ($label) — closing');
          unawaited(close());
          return;
        }
        _pendingIncoming.add(decoded);
      }
    } catch (e) {
      CcHostLog.warning('Malformed WS frame ($label): $e');
    }
  }

  @override
  Stream<Map<String, dynamic>> get incoming {
    _ensureControllers();
    return _incomingController!.stream;
  }

  @override
  Stream<RemoteChannelState> get state {
    _ensureControllers();
    return _stateController!.stream;
  }

  @override
  bool get isOpen => _open && !_closed && _socket.readyState == WebSocket.open;

  /// Ceiling on bytes accepted for this session but not yet handed to the
  /// socket.
  ///
  /// `WebSocket.add` is fire-and-forget over an UNBOUNDED internal controller:
  /// nothing in dart:io pushes back, so a slow peer (a phone on a bad link
  /// receiving full-list snapshots) grows the server's heap for as long as it
  /// stays connected. Every push path here is unawaited, so nobody upstream
  /// notices either.
  static const int _maxOutboundBytes = 8 * 1024 * 1024;

  int _outboundBytes = 0;
  Future<void> _sendChain = Future<void>.value();

  // `async` on purpose: every failure here must reach the caller as a REJECTED
  // FUTURE, never a synchronous throw. Call sites do
  // `unawaited(send(f).catchError(...))`, and a synchronous throw would escape
  // that guard entirely.
  @override
  Future<void> send(Map<String, dynamic> frame) async {
    if (!isOpen) {
      throw StateError('WsRemoteTransport ($label) is not open');
    }
    final encoded = jsonEncode(frame);
    if (_outboundBytes + encoded.length > _maxOutboundBytes) {
      // Saturated. Dropping the frame silently would leave the peer's mirror
      // quietly wrong; closing makes it reconnect and re-seed, which is the
      // only outcome that stays honest. Same posture as the >256 KB inbound
      // frame rule.
      CcHostLog.warning(
        'WsRemoteTransport ($label): peer is not draining '
        '($_outboundBytes bytes queued) — closing so it re-seeds',
      );
      unawaited(close());
      throw StateError('WsRemoteTransport ($label) outbound buffer is full');
    }
    _outboundBytes += encoded.length;
    // Writes are serialized through `addStream`, whose future completes only
    // once the socket has ACCEPTED the bytes. That is the only backpressure
    // signal dart:io's WebSocket exposes (it has no `flush`, no
    // `bufferedAmount`), and a WebSocket is ordered anyway so serializing
    // costs nothing that was not already implied.
    final queued = _sendChain.then((_) async {
      if (_closed || _socket.readyState != WebSocket.open) {
        return;
      }
      await _socket.addStream(Stream<String>.value(encoded));
    });
    _sendChain = queued.then(
      (_) => _outboundBytes -= encoded.length,
      onError: (Object _) => _outboundBytes -= encoded.length,
    );
    await queued;
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _open = false;
    await _socketSub?.cancel();
    _stateController?.add(RemoteChannelState.closed);
    try {
      await _socket.close();
    } catch (_) {
      // Already closed by the peer.
    }
    await _incomingController?.close();
    await _stateController?.close();
  }
}
