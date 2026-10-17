import 'dart:async';
import 'dart:io';

import 'package:cc_host/src/log/cc_host_log.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// [RemoteRpcChannelPort] backed by a [WebSocket].
///
/// On the reachable-server path, a client dials `wss://…/rpc` and the server
/// upgrades the connection. This adapter carries bounded Noise records;
/// authentication and application confidentiality belong to SecureRpcChannel.
/// It buffers a bounded number of early handshake records until a listener
/// attaches and drains queued JSON decodes before signaling remote EOF.
class WsRemoteTransport implements RemoteRpcChannelPort {
  /// Wraps an already-upgraded WebSocket. Call [start] once to begin reading.
  WsRemoteTransport(this._socket, {this.label = 'ws'});

  final WebSocket _socket;

  /// A short label for logs (e.g. the device id or peer address).
  final String label;

  /// A Noise record fits comfortably under 64 KiB; assembled application
  /// frames use a separate, larger limit inside SecureRpcChannel.
  static const int _maxFrameBytes = 64 * 1024;

  /// Cap on frames buffered while no listener is attached.
  static const int _maxPendingFrames = 64;
  static const int _maxQueuedDecodes = 128;

  StreamController<Map<String, dynamic>>? _incomingController;
  StreamController<RemoteChannelState>? _stateController;
  StreamSubscription<dynamic>? _socketSub;
  final List<Map<String, dynamic>> _pendingIncoming = [];
  bool _closed = false;
  bool _open = false;

  /// Preserve socket order across asynchronous JSON decodes, with bounded
  /// admission before either a listener or the decoder can be overwhelmed.
  Future<void> _decodeChain = Future<void>.value();
  int _queuedDecodes = 0;

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
      onDone: () => unawaited(_onRemoteDone()),
      cancelOnError: true,
    );
    // A freshly-upgraded socket is open; surface it so listeners don't miss it.
    if (_open) {
      CcHostLog.info('WS channel open ($label)');
    }
  }

  void _onData(dynamic data) {
    if (data is! String ||
        data.length > _maxFrameBytes ||
        _queuedDecodes >= _maxQueuedDecodes) {
      CcHostLog.warning('Invalid or excessive WS record ($label) — closing');
      unawaited(close());
      return;
    }
    _queuedDecodes++;
    // Register before any await; a later record must never overtake this one.
    _decodeChain = _decodeChain
        .then((_) => _deliverFrame(data))
        .whenComplete(() => _queuedDecodes--);
  }

  Future<void> _deliverFrame(String data) async {
    if (_closed) {
      return;
    }
    try {
      final decoded = await decodeJsonFrame(data);
      if (_closed) {
        return;
      }
      final controller = _incomingController;
      if (controller == null || controller.isClosed) {
        return;
      }
      if (controller.hasListener) {
        controller.add(decoded);
      } else if (_pendingIncoming.length >= _maxPendingFrames) {
        CcHostLog.warning('WS pending buffer overflow ($label) — closing');
        unawaited(close());
      } else {
        _pendingIncoming.add(decoded);
      }
    } catch (e) {
      CcHostLog.warning('Malformed WS record ($label): $e');
      unawaited(close());
    }
  }

  Future<void> _onRemoteDone() async {
    if (_closed) {
      return;
    }
    _open = false;
    await _decodeChain;
    if (!_closed) {
      await close();
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
  /// `WebSocket.add` is fire-and-forget over an unbounded internal controller;
  /// queued Noise records must count against a separate total backpressure cap.
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
    // Encode before admission; register the future before awaiting earlier
    // sends so concurrent records keep their original socket order.
    final encodedFuture = encodeJsonFrame(frame).then((encoded) {
      if (encoded.length > _maxFrameBytes) {
        throw StateError('WsRemoteTransport ($label) record exceeds wire cap');
      }
      if (_outboundBytes + encoded.length > _maxOutboundBytes) {
        // A saturated peer must reconnect rather than silently lose a record.
        CcHostLog.warning(
          'WsRemoteTransport ($label): peer is not draining '
          '($_outboundBytes bytes queued) — closing',
        );
        unawaited(close());
        throw StateError('WsRemoteTransport ($label) outbound buffer is full');
      }
      _outboundBytes += encoded.length;
      return encoded;
    });
    // Observed by the chain below only once earlier frames are written; a
    // rejection before then must not surface as an unhandled zone error.
    unawaited(encodedFuture.then<void>((_) {}, onError: (Object _) {}));
    final queued = _sendChain.then((_) async {
      final encoded = await encodedFuture;
      try {
        if (_closed || _socket.readyState != WebSocket.open) {
          return;
        }
        // `addStream`'s future completes only once the socket has ACCEPTED
        // the bytes. That is the only backpressure signal dart:io's
        // WebSocket exposes.
        await _socket.addStream(Stream<String>.value(encoded));
      } finally {
        _outboundBytes -= encoded.length;
      }
    });
    // A failed send must not wedge every later frame behind a completed
    // error. The caller of this send still observes the error via [queued].
    _sendChain = queued.catchError((Object _) {});
    await queued;
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _open = false;
    _pendingIncoming.clear();
    _stateController?.add(RemoteChannelState.closed);
    await _socketSub?.cancel();
    try {
      await _socket.close();
    } catch (_) {
      // Already closed by the peer.
    } finally {
      // Paused consumers must not hold socket teardown or key disposal.
      unawaited(_incomingController?.close());
      unawaited(_stateController?.close());
    }
  }
}
