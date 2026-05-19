import 'dart:async';

import 'package:cc_rpc/cc_rpc.dart';

/// A [RemoteRpcChannelPort] that carries ONE client's JSON-RPC frames over
/// the server's N-way relay room, end-to-end-encrypted with that client's
/// device PSK and chunked/backpressured for bulk payloads (PRD 15 §11).
///
/// The server keeps a single [RelaySignalingChannel] joined to its room as
/// the owner (`RemoteRelayHost` owns it); one transport spans one client
/// connection, scoped to that client's signaling [peer] id: inbound frames
/// are accepted only `from` that peer, outbound frames are addressed `to` it.
/// The broker only ever relays ciphertext ([ChunkedRelaySession] seals every
/// frame, including flow-control credits).
///
/// [close] stops bridging without dropping the room membership.
class RelayRemoteTransport implements RemoteRpcChannelPort {
  /// Wraps the already-joined [signaling] owner space for [peer], sealing
  /// with [psk]. [replay] carries payloads that arrived between the client's
  /// hello and this transport's construction — they are fed through the
  /// codec in arrival order before live traffic.
  RelayRemoteTransport({
    required RelaySignalingChannel signaling,
    required this.peer,
    required String psk,
    List<Map<String, dynamic>> replay = const [],
  }) : _signaling = signaling {
    _session = ChunkedRelaySession(
      psk: psk,
      sendPayload: (payload) {
        sentChars += _payloadChars(payload);
        _signaling.sendSignal(to: peer, payload: payload);
      },
      onFrame: (frame) {
        if (_incoming.hasListener) {
          _incoming.add(frame);
        } else {
          _pending.add(frame);
        }
      },
      onProgress: (p) {
        if (!_progress.isClosed) {
          _progress.add(p);
        }
      },
    );
    _incoming.onListen = _flushPending;
    _state.add(RemoteChannelState.open);
    _open = true;
    _sub = _signaling.incoming.listen(_onSignal, onDone: _onClosed);
    for (final payload in replay) {
      _session.handlePayload(payload);
    }
  }

  /// The client's signaling peer id this transport is bound to.
  final String peer;

  final RelaySignalingChannel _signaling;
  late final ChunkedRelaySession _session;

  final StreamController<Map<String, dynamic>> _incoming =
      StreamController<Map<String, dynamic>>.broadcast();
  final StreamController<RemoteChannelState> _state =
      StreamController<RemoteChannelState>.broadcast();
  final StreamController<RelayTransferProgress> _progress =
      StreamController<RelayTransferProgress>.broadcast();
  final List<Map<String, dynamic>> _pending = [];
  StreamSubscription<Map<String, dynamic>>? _sub;
  bool _open = false;

  /// Progress of large transfers on this link.
  Stream<RelayTransferProgress> get transferProgress => _progress.stream;

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
    if (_pending.isEmpty) {
      return;
    }
    final buffered = List<Map<String, dynamic>>.of(_pending);
    _pending.clear();
    for (final f in buffered) {
      _incoming.add(f);
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
    await _session.sendFrame(frame);
  }

  @override
  Future<void> close() async {
    _onClosed();
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
      _session.handlePayload(cast);
    }
  }

  void _onClosed() {
    if (!_open) {
      return;
    }
    _open = false;
    _session.close();
    unawaited(_sub?.cancel());
    if (!_state.isClosed) {
      _state.add(RemoteChannelState.closed);
      unawaited(_state.close());
    }
    if (!_incoming.isClosed) {
      unawaited(_incoming.close());
    }
    if (!_progress.isClosed) {
      unawaited(_progress.close());
    }
  }
}
