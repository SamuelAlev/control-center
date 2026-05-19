import 'dart:async';
import 'dart:convert';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/remote_control/data/transport/webrtc_peer_manager.dart'
    show WebRtcPeerManager;
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// [RemoteRpcChannelPort] backed by a single WebRTC [RTCDataChannel].
///
/// The desktop is the **answerer**: the phone creates the data channel, so the
/// desktop receives it via `RTCPeerConnection.onDataChannel` and hands it here.
/// This class only owns the channel lifecycle (decode `onMessage` → [incoming],
/// `send` → `dataChannel.send`) — the peer connection itself is owned by
/// [WebRtcPeerManager]. DTLS encrypts the underlying SCTP transport, so frames
/// are confidential and integrity-protected end-to-end.
class WebRtcRemoteTransport implements RemoteRpcChannelPort {
  WebRtcRemoteTransport(this._channel, {required this.deviceId});

  final RTCDataChannel _channel;

  /// The paired-device id this channel serves (for logging / session lookup).
  final String deviceId;

  StreamController<Map<String, dynamic>>? _incomingController;
  StreamController<RemoteChannelState>? _stateController;
  StreamSubscription<RTCDataChannelState>? _stateSub;
  StreamSubscription<RTCDataChannelMessage>? _messageSub;
  bool _closed = false;

  /// Hard cap on a single inbound frame before decode. A remote-control frame is
  /// small JSON; anything this large is abusive. The desktop holds GitHub tokens
  /// and runs agents, so an unbounded `jsonDecode` on the main isolate is a DoS
  /// vector (finding #8). Over-cap frames close the channel.
  static const int _maxFrameBytes = 256 * 1024;

  /// Cap on frames buffered while no listener is attached. For a pending device
  /// no listener attaches for the entire human-approval window, so an attacker
  /// who reached the channel could otherwise buffer without bound.
  static const int _maxPendingFrames = 64;

  /// Frames that arrived while [incoming] had no listener. A plain broadcast
  /// stream drops such events — fatal here because the phone fires its
  /// `auth_challenge` the instant its channel opens, before the desktop's
  /// `_authenticate` subscribes (and again between the handshake reader and the
  /// RPC reader). Buffered here and flushed when a listener attaches.
  final List<Map<String, dynamic>> _pendingIncoming = [];

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

  /// Wires the channel callbacks. Must be called once after construction,
  /// before the channel is expected to deliver frames.
  void start() {
    _ensureControllers();
    _stateSub = _channel.stateChangeStream.listen(_onState);
    _messageSub = _channel.messageStream.listen(_onMessage);
    // Emit the current state so subscribers don't miss an already-open channel.
    _onState(_channel.state);
  }

  void _onState(RTCDataChannelState? s) {
    final mapped = switch (s) {
      RTCDataChannelState.RTCDataChannelOpen => RemoteChannelState.open,
      RTCDataChannelState.RTCDataChannelConnecting =>
        RemoteChannelState.connecting,
      _ => RemoteChannelState.closed,
    };
    _stateController?.add(mapped);
    if (mapped == RemoteChannelState.open) {
      AppLog.i('RemoteControl', 'DataChannel open for device $deviceId');
    } else if (mapped == RemoteChannelState.closed && !_closed) {
      AppLog.i('RemoteControl', 'DataChannel closed for device $deviceId');
    }
  }

  void _onMessage(RTCDataChannelMessage message) {
    if (message.isBinary) {
      AppLog.w('RemoteControl', 'Ignoring binary frame from $deviceId');
      return;
    }
    final text = message.text;
    // Reject an oversized frame before decode (finding #8) — a small JSON
    // protocol has no legitimate megabyte frames, and decoding one on the main
    // isolate would pin the UI / risk OOM. Close the abusive channel.
    if (text.length > _maxFrameBytes) {
      AppLog.w(
        'RemoteControl',
        'Frame from $deviceId is ${text.length}B (> $_maxFrameBytes) — '
            'closing channel',
      );
      unawaited(close());
      return;
    }
    try {
      final decoded = jsonDecode(text) as Map<String, dynamic>;
      final controller = _incomingController;
      if (controller == null) {
        return;
      }
      // Deliver to a live listener, else buffer until one attaches (see
      // [_pendingIncoming]) so an early frame is never silently dropped.
      if (controller.hasListener) {
        controller.add(decoded);
      } else {
        if (_pendingIncoming.length >= _maxPendingFrames) {
          AppLog.w(
            'RemoteControl',
            'Pending buffer overflow for $deviceId '
                '(> $_maxPendingFrames frames) — closing channel',
          );
          unawaited(close());
          return;
        }
        _pendingIncoming.add(decoded);
      }
    } catch (e, st) {
      AppLog.e(
        'RemoteControl',
        'Malformed JSON-RPC frame from $deviceId: $e',
        e,
        st,
      );
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
  bool get isOpen =>
      _channel.state == RTCDataChannelState.RTCDataChannelOpen && !_closed;

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    if (!isOpen) {
      throw StateError(
        'RemoteRpcChannelPort for $deviceId is not open (state=${_channel.state})',
      );
    }
    await _channel.send(RTCDataChannelMessage(jsonEncode(frame)));
  }

  @override
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    await _messageSub?.cancel();
    await _stateSub?.cancel();
    _stateController?.add(RemoteChannelState.closed);
    try {
      await _channel.close();
    } catch (_) {
      // Channel may already be closed by the peer.
    }
    await _incomingController?.close();
    await _stateController?.close();
  }
}
