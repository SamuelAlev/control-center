import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:cc_host/src/log/cc_host_log.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// [RemoteRpcChannelPort] backed by a [WebSocket].
///
/// This is the transport for the **reachable-server** path (LAN / Tailnet /
/// VPS / same-origin web): a client dials `wss://…/rpc`, the server upgrades the
/// connection, and frames flow as JSON text. Confidentiality + integrity come
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

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    if (!isOpen) {
      throw StateError('WsRemoteTransport ($label) is not open');
    }
    _socket.add(jsonEncode(frame));
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
