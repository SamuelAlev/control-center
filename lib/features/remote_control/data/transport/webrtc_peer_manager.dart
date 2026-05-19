import 'dart:async';

import 'package:control_center/core/utils/app_log.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Owning callback fired when a paired phone's data channel arrives.
typedef OnRemoteChannel =
    void Function(String deviceId, RTCDataChannel channel);

/// Outbound-signaling callback: the manager produced an SDP/ICE blob that must
/// be relayed to [deviceId] over the signaling broker.
typedef OnOutboundSignal =
    void Function(
      String deviceId, {
      required String kind,
      required Map<String, dynamic> payload,
    });

/// Manages one [RTCPeerConnection] per paired device.
///
/// The desktop is the **answerer**: the phone creates the offer (and the data
/// channel), so this manager only ever answers offers and receives the channel
/// via `onDataChannel`. ICE servers are STUN-only by policy (no TURN relay) —
/// ICE transparently uses a direct LAN path when co-located and hole-punches
/// via STUN when remote. Trickle ICE: each local candidate is forwarded as it
/// gathers.
class WebRtcPeerManager {
  /// Creates a [WebRtcPeerManager].
  WebRtcPeerManager({
    required this.stunUrls,
    required this.onRemoteChannel,
    required this.onOutboundSignal,
    this.onConnectionLost,
  });

  /// STUN server URLs (`stun:stun.l.google.com:19302`, …). No TURN — by design.
  final List<String> stunUrls;

  /// Called when a phone's data channel opens.
  final OnRemoteChannel onRemoteChannel;

  /// Called for each local ICE candidate / SDP answer to relay to the peer.
  final OnOutboundSignal onOutboundSignal;

  /// Called when a peer connection reaches a terminal failed/closed state, so
  /// the owner can tear the session down promptly rather than waiting on the
  /// untrusted broker's `peer-left`. `Disconnected` is intentionally *not*
  /// reported — it is often a transient ICE blip that recovers.
  final void Function(String deviceId)? onConnectionLost;

  final Map<String, RTCPeerConnection> _peers = {};

  /// Negotiated DTLS fingerprints per device — `local` is this desktop's (from
  /// the answer SDP), `remote` is the phone's (from the offer SDP). Captured in
  /// [answerOffer] and consumed by the PSK challenge to bind the proof to this
  /// exact DTLS session.
  final Map<String, ({String? local, String? remote})> _fingerprints = {};

  static final RegExp _fingerprintRegExp = RegExp(
    r'a=fingerprint:\S+\s+([0-9A-Fa-f:]+)',
  );

  static String? _extractFingerprint(String? sdp) =>
      sdp == null ? null : _fingerprintRegExp.firstMatch(sdp)?.group(1);

  /// The negotiated DTLS fingerprints for [deviceId] (`local` = this desktop,
  /// `remote` = the phone), or nulls when unknown. These are the same
  /// `a=fingerprint:` hex strings the phone reads from its own side.
  ({String? local, String? remote}) fingerprints(String deviceId) =>
      _fingerprints[deviceId] ?? (local: null, remote: null);

  Map<String, dynamic> get _configuration => {
    'iceServers': <Map<String, dynamic>>[
      {'urls': stunUrls},
    ],
    // Aggregate ICE gathering so the answer carries candidates promptly.
    'iceTransportPolicy': 'all',
    'sdpSemantics': 'unified-plan',
  };

  /// Whether a peer connection is currently tracked for [deviceId].
  bool hasPeer(String deviceId) => _peers.containsKey(deviceId);

  /// Answers an inbound offer from [deviceId] and returns the answer SDP
  /// payload (`{sdp, type:'answer'}`).
  ///
  /// Creates a fresh peer connection, wires its data-channel + ICE callbacks,
  /// applies the offer, and produces the answer. Local ICE candidates are
  /// forwarded immediately (trickle) via [onOutboundSignal].
  Future<Map<String, dynamic>> answerOffer(
    String deviceId,
    Map<String, dynamic> offer,
  ) async {
    var pc = _peers[deviceId];
    if (pc != null) {
      // An existing peer for this device is reconnecting; tear it down first.
      await _disposePeer(deviceId);
    }
    // No legacy media constraints: this is a data-channel-only, Unified-Plan
    // connection. Passing the Plan-B `OfferToReceiveAudio/Video` constraints
    // makes libwebrtc lay out spurious audio/video m-lines, so the answer's
    // m-line order no longer mirrors the phone's data-only offer and the phone
    // rejects it ("order of m-lines in answer doesn't match order in offer").
    pc = await createPeerConnection(_configuration);
    _peers[deviceId] = pc;

    pc.onDataChannel = (channel) {
      AppLog.i('RemoteControl', 'Received data channel from $deviceId');
      onRemoteChannel(deviceId, channel);
    };
    pc.onIceCandidate = (candidate) {
      onOutboundSignal(
        deviceId,
        kind: 'ice',
        payload: {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        },
      );
    };
    pc.onConnectionState = (state) {
      AppLog.d('RemoteControl', 'PC $deviceId state=$state');
      // Terminal failure/close → tell the owner so it tears the session down
      // promptly (finding #13). Disconnected is omitted: it's often a transient
      // ICE blip that recovers, and the data channel's own close still drives
      // teardown if it doesn't.
      if (state == RTCPeerConnectionState.RTCPeerConnectionStateFailed ||
          state == RTCPeerConnectionState.RTCPeerConnectionStateClosed) {
        onConnectionLost?.call(deviceId);
      }
    };

    final remoteSdp = RTCSessionDescription(
      offer['sdp'] as String?,
      offer['type'] as String? ?? 'offer',
    );
    await pc.setRemoteDescription(remoteSdp);

    final answer = await pc.createAnswer();
    await pc.setLocalDescription(answer);

    // Capture both DTLS fingerprints now that the SDP is negotiated: the phone's
    // from its offer, ours from our answer. The PSK challenge binds to these.
    _fingerprints[deviceId] = (
      local: _extractFingerprint(answer.sdp),
      remote: _extractFingerprint(offer['sdp'] as String?),
    );

    return {'sdp': answer.sdp, 'type': 'answer'};
  }

  /// Applies a remote ICE candidate from [deviceId].
  Future<void> addRemoteCandidate(
    String deviceId,
    Map<String, dynamic> candidate,
  ) async {
    final pc = _peers[deviceId];
    if (pc == null) {
      AppLog.w('RemoteControl', 'No peer for ICE from $deviceId');
      return;
    }
    await pc.addCandidate(
      RTCIceCandidate(
        candidate['candidate'] as String?,
        candidate['sdpMid'] as String?,
        candidate['sdpMLineIndex'] as int?,
      ),
    );
  }

  /// Tears down the peer connection for [deviceId] (e.g. on revoke/disconnect).
  Future<void> closePeer(String deviceId) => _disposePeer(deviceId);

  /// Tears down every peer connection (e.g. on remote-control stop).
  Future<void> closeAll() async {
    final ids = _peers.keys.toList();
    await Future.wait(ids.map(_disposePeer));
  }

  Future<void> _disposePeer(String deviceId) async {
    _fingerprints.remove(deviceId);
    final pc = _peers.remove(deviceId);
    if (pc == null) {
      return;
    }
    try {
      await pc.close();
    } catch (_) {
      // Already closed.
    }
    try {
      await pc.dispose();
    } catch (_) {
      // Already disposed.
    }
  }
}
