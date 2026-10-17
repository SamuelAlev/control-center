import 'dart:async';

import 'package:cc_rpc/cc_rpc.dart'
    show RelaySignalingChannel, RemoteChannelState, RemoteRpcChannelPort;

/// Raw records for one peer of the server's N-way broker room.
///
/// `SecureRpcChannel` owns encryption above this adapter. It addresses every
/// response to this peer and never broadcasts another device's traffic.
/// Closing the peer does not close the server's shared room membership.
class RelayRemoteTransport implements RemoteRpcChannelPort {
  /// [replay] contains records buffered while the host resolved this peer.
  RelayRemoteTransport({
    required this._signaling,
    required this.peer,
    List<Map<String, dynamic>> replay = const [],
  }) {
    _incoming.onListen = _flushPending;
    _state.add(RemoteChannelState.open);
    _open = true;
    _sub = _signaling.incoming.listen(_onSignal, onDone: _onClosed);
    for (final payload in replay) {
      _deliver(payload);
    }
  }

  /// The client's signaling peer id this transport is bound to.
  final String peer;

  final RelaySignalingChannel _signaling;

  final StreamController<Map<String, dynamic>> _incoming =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<RemoteChannelState> _state =
      StreamController<RemoteChannelState>.broadcast();
  final List<Map<String, dynamic>> _pending = [];
  Timer? _pendingEofTimer;
  bool _pendingEof = false;
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _open = false;

  /// Sealed characters sent over the relay on this link (~bytes; relay-usage
  /// accounting so a self-hosting operator sees what the broker carries).
  int sentChars = 0;

  /// Sealed characters received over the relay on this link.
  int receivedChars = 0;

  static int _payloadChars(Map<String, dynamic> payload) {
    var chars = 0;
    for (final value in payload.values) {
      if (value is String) {
        chars += value.length;
      }
    }
    return chars;
  }

  void _flushPending() {
    for (final frame in _pending) {
      _incoming.add(frame);
    }
    _pending.clear();
    if (_pendingEof) {
      _pendingEofTimer?.cancel();
      _pendingEof = false;
      unawaited(_incoming.close());
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
      throw StateError('RelayRemoteTransport is not open');
    }
    sentChars += _payloadChars(frame);
    _signaling.sendSignal(to: peer, payload: frame);
  }

  @override
  Future<void> close() async {
    try {
      if (_open) {
        _signaling.sendSignal(to: peer, kind: 'close', payload: const {});
      }
    } catch (_) {
      // The broker may already be gone; local teardown is unconditional.
    } finally {
      _onClosed(abort: true);
    }
  }

  void _onSignal(Map<String, dynamic> frame) {
    final type = frame['type'];
    if (type == 'peer-left') {
      if (frame['from'] == peer || frame['reason'] == 'socket-closed') {
        // This client (or our broker socket) went away — end this
        // connection's session. The host keeps the room joined.
        _onClosed();
      }
      return;
    }
    if (type != 'signal' || frame['from'] != peer || frame['kind'] != 'rpc') {
      return;
    }
    final payload = frame['payload'];
    if (payload is Map) {
      final cast = payload.cast<String, dynamic>();
      receivedChars += _payloadChars(cast);
      _deliver(cast);
    }
  }

  void _deliver(Map<String, dynamic> frame) {
    if (!_open) {
      return;
    }
    if (_incoming.hasListener) {
      _incoming.add(frame);
    } else if (_pending.length >= 64) {
      _onClosed(abort: true);
    } else {
      _pending.add(frame);
    }
  }

  void _onClosed({bool abort = false}) {
    if (!_open) {
      if (abort && _pendingEof) {
        _pendingEofTimer?.cancel();
        _pendingEof = false;
        _pending.clear();
        unawaited(_incoming.close());
      }
      return;
    }
    _open = false;
    unawaited(_sub?.cancel());
    _state.add(RemoteChannelState.closed);
    unawaited(_state.close());
    if (abort) {
      _pending.clear();
    }
    if (!abort && _pending.isNotEmpty) {
      // Deliver bounded pre-listener records that preceded the peer's EOF.
      _pendingEof = true;
      _pendingEofTimer = Timer(const Duration(seconds: 5), () {
        _pendingEof = false;
        _pending.clear();
        unawaited(_incoming.close());
      });
    } else {
      unawaited(_incoming.close());
    }
  }
}
