import 'dart:async';
import 'dart:convert';
import 'dart:js_interop';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_remote/debug_log.dart';
import 'package:cc_remote/net/rpc_channel.dart';
import 'package:cc_remote/rtc/signaling_client.dart';
import 'package:web/web.dart' as web;

/// A thin WebRTC DataChannel client built directly on `package:web` +
/// `dart:js_interop` — **not** `flutter_webrtc` (whose native code breaks
/// `flutter build web`).
///
/// The phone is the **offerer**: it creates the peer connection with the STUN
/// servers from the QR, creates a data channel named `cc`, creates and applies
/// its local offer, trickles ICE candidates, and exchanges the offer/answer/ICE
/// with the desktop through a [SignalingClient]. The desktop is the answerer —
/// it receives the channel via `RTCPeerConnection.onDataChannel`.
///
/// Implements [RemoteRpcChannelPort]: decoded JSON frames flow out of
/// [incoming], [send] JSON-encodes onto the channel, and [state]/[isOpen]/
/// [close] surface the lifecycle. [fingerprints] exposes both DTLS
/// fingerprints after connect so the PSK handshake can bind the proof to this
/// exact session.
class RtcTransport implements RemoteRpcChannelPort {
  /// Creates a transport that will use [iceServers] (STUN URLs from the QR).
  RtcTransport(this.iceServers);

  /// STUN server URLs for ICE.
  final List<String> iceServers;

  web.RTCPeerConnection? _pc;
  web.RTCDataChannel? _dc;
  StreamSubscription<SignalingFrame>? _signalSub;
  late final StreamController<Map<String, dynamic>> _incoming =
      StreamController<Map<String, dynamic>>.broadcast(
        onListen: _flushPendingIncoming,
      );
  // Frames received while [incoming] has no listener. The handshake reader and
  // the post-handshake approval/RPC reader subscribe at different moments, so a
  // frame the desktop sends in between (e.g. `awaiting_approval` right after
  // auth) would be dropped by a plain broadcast stream. Buffered and flushed on
  // the next listen.
  final List<Map<String, dynamic>> _pendingIncoming = [];
  final StreamController<RemoteChannelState> _state =
      StreamController<RemoteChannelState>.broadcast();

  Completer<void>? _openCompleter;
  bool _closing = false;

  /// Hard cap on a single inbound frame before decode, and on the pre-listener
  /// buffer — symmetric with the desktop transport (finding #8). A small JSON
  /// protocol has no legitimate megabyte frames.
  static const int _maxFrameBytes = 256 * 1024;
  static const int _maxPendingFrames = 64;

  @override
  Stream<Map<String, dynamic>> get incoming => _incoming.stream;

  @override
  Stream<RemoteChannelState> get state => _state.stream;

  @override
  bool get isOpen => _dc != null && _dc!.readyState == 'open' && !_closing;

  /// Runs the full offer/answer/ICE dance and completes once the DataChannel is
  /// open. Throws on timeout (strict/symmetric NAT, peer never answered) or if
  /// the peer leaves mid-handshake.
  Future<void> negotiate({
    required String room,
    required String peerId,
    required SignalingClient signaling,
    required String Function(String sdp) signOffer,
    Duration timeout = const Duration(seconds: 25),
  }) async {
    _setState(RemoteChannelState.connecting);

    final pc = _createPeerConnection();
    _pc = pc;

    final dc = pc.createDataChannel(_channelLabel);
    _dc = dc;
    _wireDataChannel(dc);
    _wireIce(pc, signaling, room, peerId);
    _wireConnectionState(pc);

    // Apply the desktop's answer and ICE candidates as they arrive.
    _signalSub = signaling.incoming.listen(
      (frame) => _onSignal(frame, pc),
      onDone: () => _fail(const SignalingException('Signaling closed')),
    );

    // Per the broker contract, `peer-joined` fires exactly once when the room
    // becomes shared (regardless of join order) — so we offer on it and the
    // offer always has a recipient. Offering earlier would be dropped (the
    // broker is a pure relay).
    try {
      rlog('rtc', 'waiting for the Mac to join room $room…');
      await signaling.incoming
          .where((f) => f.type == SignalingType.peerJoined)
          .first
          .timeout(
            timeout,
            onTimeout: () {
              rlog(
                'rtc',
                'no peer joined within ${timeout.inSeconds}s — is the Mac '
                    'online on the same broker/room?',
              );
              throw const IceConnectException('No peer joined the room');
            },
          );
    } on IceConnectException {
      rethrow;
    }
    rlog('rtc', 'peer joined — creating + sending offer');

    await _createAndSendOffer(pc, signaling, room, peerId, signOffer);

    // Wait for the DataChannel to open (ICE connectivity succeeds).
    final openCompleter = Completer<void>();
    _openCompleter = openCompleter;
    await openCompleter.future.timeout(
      timeout,
      onTimeout: () {
        rlog(
          'rtc',
          'data channel never opened within ${timeout.inSeconds}s — ICE could '
              'not connect (check STUN/NAT; same-machine should use host '
              'candidates)',
        );
        throw const IceConnectException(
          'Could not establish a peer connection',
        );
      },
    );
  }

  /// Both DTLS fingerprints (local = phone, remote = desktop), parsed from the
  /// negotiated SDP. Available once [negotiate] has completed.
  Future<({String local, String remote})> fingerprints() async {
    final pc = _pc;
    if (pc == null) {
      throw StateError('Not connected');
    }
    final local = _extractFingerprint(pc.localDescription?.sdp);
    final remote = _extractFingerprint(pc.remoteDescription?.sdp);
    if (local == null || remote == null) {
      throw StateError('DTLS fingerprints not available yet');
    }
    return (local: local, remote: remote);
  }

  @override
  Future<void> send(Map<String, dynamic> frame) async {
    final dc = _dc;
    if (dc == null || dc.readyState != 'open') {
      throw const RpcNotConnectedException();
    }
    dc.send(jsonEncode(frame).toJS);
  }

  @override
  Future<void> close() async {
    if (_closing) {
      return;
    }
    _closing = true;
    await _signalSub?.cancel();
    _signalSub = null;
    _completeOpen(const SignalingException('Closed'));
    try {
      _dc?.close();
    } catch (_) {
      // Best-effort.
    }
    try {
      _pc?.close();
    } catch (_) {
      // Best-effort.
    }
    _dc = null;
    _pc = null;
    _setState(RemoteChannelState.closed);
    if (!_incoming.isClosed) {
      await _incoming.close();
    }
    if (!_state.isClosed) {
      await _state.close();
    }
  }

  // --- internals ---------------------------------------------------------

  static const String _channelLabel = 'cc';

  web.RTCPeerConnection _createPeerConnection() {
    final iceServers = <web.RTCIceServer>[
      for (final url in this.iceServers) web.RTCIceServer(urls: url.toJS),
    ].toJS;
    final config = web.RTCConfiguration(iceServers: iceServers);
    return web.RTCPeerConnection(config);
  }

  /// Logs the peer-connection / ICE lifecycle to the console. Diagnostic only —
  /// no behavioural effect. The data channel opening is what `negotiate` awaits;
  /// these states show *why* it does or doesn't (gathering, checking, failed).
  void _wireConnectionState(web.RTCPeerConnection pc) {
    pc.oniceconnectionstatechange = ((web.Event _) {
      rlog('ice', 'iceConnectionState=${pc.iceConnectionState}');
    }).toJS;
    pc.onconnectionstatechange = ((web.Event _) {
      rlog('ice', 'connectionState=${pc.connectionState}');
    }).toJS;
    pc.onicegatheringstatechange = ((web.Event _) {
      rlog('ice', 'iceGatheringState=${pc.iceGatheringState}');
    }).toJS;
    pc.onicecandidateerror = ((web.Event e) {
      final err = e as web.RTCPeerConnectionIceErrorEvent;
      rlog(
        'ice',
        'candidate error code=${err.errorCode} url=${err.url} '
            'text="${err.errorText}"',
      );
    }).toJS;
  }

  void _wireDataChannel(web.RTCDataChannel dc) {
    dc.binaryType = 'arraybuffer';
    dc.onopen = ((web.Event _) {
      rlog('rtc', 'data channel onopen');
      _onOpened();
    }).toJS;
    dc.onclose = ((web.Event _) {
      rlog('rtc', 'data channel onclose');
      _onClosed();
    }).toJS;
    dc.onerror = ((web.Event _) {
      rlog('rtc', 'data channel onerror');
      _onClosed();
    }).toJS;
    dc.onmessage = ((web.Event e) {
      final event = e as web.MessageEvent;
      final data = event.data;
      if (data.isA<JSString>()) {
        final text = (data as JSString).toDart;
        if (text.length > _maxFrameBytes) {
          rlog('rtc', 'inbound frame too large (${text.length}B) — closing');
          unawaited(close());
          return;
        }
        final map = decodeFrame(text);
        if (map != null) {
          _emitIncoming(map);
        }
      }
    }).toJS;
  }

  void _wireIce(
    web.RTCPeerConnection pc,
    SignalingClient signaling,
    String room,
    String peerId,
  ) {
    pc.onicecandidate = ((web.Event e) {
      final event = e as web.RTCPeerConnectionIceEvent;
      final candidate = event.candidate;
      // A null candidate marks end-of-gathering; nothing to relay.
      if (candidate == null) {
        rlog('ice', 'local ICE gathering complete');
        return;
      }
      // `typ host` = same-machine/LAN, `srflx` = STUN reflexive (STUN works),
      // `relay` = TURN. No srflx on a remote network ⇒ STUN is misconfigured.
      final typ =
          RegExp(r'typ (\w+)').firstMatch(candidate.candidate)?.group(1) ?? '?';
      rlog('ice', 'local candidate typ=$typ');
      signaling.send(
        SignalingFrame(
          type: SignalingType.signal,
          room: room,
          from: peerId,
          kind: 'ice',
          payload: <String, dynamic>{
            'candidate': candidate.candidate,
            if (candidate.sdpMid != null) 'sdpMid': candidate.sdpMid,
            if (candidate.sdpMLineIndex != null)
              'sdpMLineIndex': candidate.sdpMLineIndex,
          },
        ),
      );
    }).toJS;
  }

  Future<void> _createAndSendOffer(
    web.RTCPeerConnection pc,
    SignalingClient signaling,
    String room,
    String peerId,
    String Function(String sdp) signOffer,
  ) async {
    // `setLocalDescription()` with no argument tells the browser to create AND
    // set its canonical offer in one step. We must relay THAT exact description.
    // A separate `createOffer()` produces a *different* offer (fresh ICE
    // ufrag/pwd), so sending it while the real local description is the implicit
    // one makes the desktop's (correct) answer fail to apply against our actual
    // local description — "order of m-lines in answer doesn't match order in
    // offer" — and our trickled ICE (tagged with the real ufrag) get rejected by
    // the desktop too.
    await pc.setLocalDescription().toDart;
    final local = pc.localDescription;
    final sdp = local?.sdp;
    if (local == null || sdp == null) {
      throw const IceConnectException('Could not create an offer');
    }
    // Sign the offer SDP with the PSK so the desktop can prove PSK possession
    // before it answers / brings up DTLS (mandatory pre-DTLS gate, finding #9).
    // The desktop now *rejects* an unsigned/invalid offer, so this is required.
    final sdpSig = signOffer(sdp);
    rlog('rtc', 'offer sent (signed) — awaiting answer');
    signaling.send(
      SignalingFrame(
        type: SignalingType.signal,
        room: room,
        from: peerId,
        kind: 'offer',
        payload: <String, dynamic>{
          'sdp': sdp,
          'type': local.type,
          'sdp_sig': sdpSig,
        },
      ),
    );
  }

  Future<void> _onSignal(SignalingFrame frame, web.RTCPeerConnection pc) async {
    if (frame.type != SignalingType.signal) {
      return;
    }
    try {
      switch (frame.kind) {
        case 'answer':
          final payload = frame.payload;
          if (payload != null) {
            rlog('rtc', 'remote answer received — applying');
            await pc
                .setRemoteDescription(
                  web.RTCSessionDescriptionInit(
                    type: (payload['type'] as String?) ?? 'answer',
                    sdp: (payload['sdp'] as String?) ?? '',
                  ),
                )
                .toDart;
          }
        case 'ice':
          final payload = frame.payload;
          if (payload != null) {
            await pc
                .addIceCandidate(
                  web.RTCIceCandidateInit(
                    candidate: (payload['candidate'] as String?) ?? '',
                    sdpMid: payload['sdpMid'] as String?,
                    sdpMLineIndex: payload['sdpMLineIndex'] as int?,
                  ),
                )
                .toDart;
          }
      }
    } catch (e, s) {
      // A bad remote description/candidate shouldn't tear down the whole
      // negotiation — later candidates may still succeed.
      rlog('rtc', 'failed to apply remote ${frame.kind}', error: e, stack: s);
    }
  }

  void _onOpened() {
    _completeOpen(null);
    _setState(RemoteChannelState.open);
  }

  void _onClosed() {
    _fail(const SignalingException('DataChannel closed'));
  }

  void _fail(Object error) {
    _completeOpen(error);
    if (!_closing && !_state.isClosed) {
      _setState(RemoteChannelState.closed);
    }
  }

  void _completeOpen(Object? error) {
    final completer = _openCompleter;
    _openCompleter = null;
    if (completer == null || completer.isCompleted) {
      return;
    }
    if (error != null) {
      completer.completeError(error);
    } else {
      completer.complete();
    }
  }

  void _setState(RemoteChannelState s) {
    if (!_state.isClosed) {
      _state.add(s);
    }
  }

  /// Delivers [frame] to a live [incoming] listener, or buffers it until one
  /// attaches — so a frame that arrives in the gap between the handshake reader
  /// and the next reader is never silently dropped.
  void _emitIncoming(Map<String, dynamic> frame) {
    if (_incoming.isClosed) {
      return;
    }
    if (_incoming.hasListener) {
      _incoming.add(frame);
    } else {
      if (_pendingIncoming.length >= _maxPendingFrames) {
        rlog('rtc', 'pending buffer overflow — closing');
        unawaited(close());
        return;
      }
      _pendingIncoming.add(frame);
    }
  }

  void _flushPendingIncoming() {
    if (_pendingIncoming.isEmpty || _incoming.isClosed) {
      return;
    }
    final buffered = List<Map<String, dynamic>>.of(_pendingIncoming);
    _pendingIncoming.clear();
    for (final frame in buffered) {
      _incoming.add(frame);
    }
  }

  /// Extracts the DTLS fingerprint hash from an SDP `a=fingerprint:` line.
  String? _extractFingerprint(String? sdp) {
    if (sdp == null) {
      return null;
    }
    final match = _fingerprintRegExp.firstMatch(sdp);
    return match?.group(1);
  }

  static final RegExp _fingerprintRegExp = RegExp(
    r'a=fingerprint:\S+\s+([0-9A-Fa-f:]+)',
  );
}

/// Thrown when ICE cannot establish a peer connection within the deadline — the
/// hallmark of a strict/symmetric NAT that STUN-only (no TURN) cannot traverse.
/// The UI surfaces this as "couldn't connect remotely — try same Wi-Fi".
class IceConnectException implements Exception {
  const IceConnectException(this.message);

  final String message;

  @override
  String toString() => 'IceConnectException: $message';
}

/// Decodes a JSON text frame into a map, or returns `null`.
Map<String, dynamic>? decodeFrame(String text) {
  try {
    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
  } catch (_) {
    // Not a JSON object — ignore.
  }
  return null;
}
