import 'dart:async';
import 'dart:convert';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/features/remote_control/domain/services/remote_pairing_lifecycle.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_mcp/src/mcp_tool_dispatcher.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/cc_server_core.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/remote_control/data/repositories/paired_device_secrets_repository.dart';
import 'package:control_center/features/remote_control/data/signaling/signaling_client.dart';
import 'package:control_center/features/remote_control/data/signaling/signaling_message.dart';
import 'package:control_center/features/remote_control/data/transport/webrtc_peer_manager.dart';
import 'package:control_center/features/remote_control/data/transport/webrtc_remote_transport.dart';
import 'package:control_center/features/remote_control/providers/remote_control_config_provider.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';

/// Bundles everything live for one connected device.
///
/// The [signaling] client outlives any single phone connection: it stays joined
/// to the broker room for the device's whole lifetime so a phone can reconnect
/// (refresh) without the desktop restarting. [rpc]/[forwarder]/[transport] are
/// the per-*connection* artifacts — torn down and nulled when the phone leaves,
/// rebuilt when it reconnects.
class _DeviceSession {
  _DeviceSession({required this.signaling, required this.signalingPeerId});
  final SignalingClient signaling;

  /// This desktop's broker peer id for **this room only** — a fresh random value
  /// generated per device session, never derived from a QR field. An attacker
  /// who saw the pairing link therefore can't use a known id to evict the
  /// desktop's socket or occupy its room slot (finding #7).
  final String signalingPeerId;

  // Cancelled in [_teardown]/[_disposeSessionArtifacts], not in the method that
  // creates them — the cancel_subscriptions lint can't see that.
  // ignore: cancel_subscriptions
  StreamSubscription<SignalingMessage>? signalingSub;
  RemoteRpcSession? rpc;
  RemoteEventForwarder? forwarder;
  RemoteRpcChannelPort? transport;

  /// Subscription to the live transport's state, used to drive teardown when the
  /// data channel closes (ICE/DTLS death) instead of relying solely on the
  /// untrusted broker's `peer-left` (finding #13).
  // ignore: cancel_subscriptions
  StreamSubscription<RemoteChannelState>? transportStateSub;

  /// The peer id of the phone currently negotiating/connected over this room
  /// (captured from its offer). Lets a `peer-left` from a *superseded* phone
  /// connection be ignored, so a fast refresh doesn't tear down the connection
  /// the new tab just established.
  String? phonePeerId;

  /// Serializes signaling-frame handling for this device. Broker frames arrive
  /// on a broadcast stream whose listener returns before its async work
  /// finishes, so two frames (e.g. a `peer-left` and the reconnect's `offer`)
  /// would otherwise interleave at await points and clobber shared state
  /// (`phonePeerId`, the peer connection). Chaining each handler onto this
  /// future processes them strictly in order.
  Future<void> signalChain = Future<void>.value();
}

/// Orchestrates the desktop side of remote control.
///
/// Owns one [WebRtcPeerManager] (one peer connection per paired device) and one
/// [SignalingClient] per active device (the room = the device id). When a
/// phone's data channel arrives it:
///   1. checks the device is `active` and its PSK exists (else denies closed),
///   2. runs a PSK nonce challenge bound to the pinned DTLS fingerprint,
///   3. starts a [RemoteRpcSession] + [RemoteEventForwarder]; the session is
///      stateless (each request carries its own `workspace_id`).
///
/// The signaling client stays joined to the room for the device's lifetime: a
/// phone disconnecting (`peer-left`, e.g. a browser refresh) ends only the live
/// RTC/RPC connection (see [_endSession]) — the desktop remains in the room so
/// the phone can reconnect without a desktop restart. Only revoking a device
/// (status → revoked / row deleted, observed via `watchConnectable`) or [stop]
/// fully tears the room presence down via [_teardown]; the PSK is already gone,
/// so a revoked device fails closed on reconnect.
class RemoteControlServer {
  /// Creates a [RemoteControlServer].
  RemoteControlServer({
    required RemoteControlConfig config,
    required this.dispatcher,
    required this.devicesDao,
    required this.secrets,
    required this.eventBus,
    required this.workspaceResolver,
    this.repoOps,
    this.watchQueries,
    this.onRunningChanged,
  }) : _config = config {
    _peerManager = WebRtcPeerManager(
      stunUrls: config.stunUrls,
      onRemoteChannel: _onRemoteChannel,
      onOutboundSignal: _onOutboundSignal,
      onConnectionLost: (deviceId) => unawaited(_endSession(deviceId)),
    );
  }

  /// The shared RPC dispatcher (one instance app-wide).
  final McpToolDispatcher dispatcher;

  /// Paired-device metadata DAO.
  final PairedDeviceDao devicesDao;

  /// Per-device PSK secure store.
  final PairedDeviceSecretsRepository secrets;

  /// Domain event bus for push.
  final DomainEventBus eventBus;

  /// Resolves the workspaces the phone can switch between.
  final RemoteWorkspaceResolver workspaceResolver;

  /// Repo-RPC dispatcher exposed to connected clients (`repo/call` / `op/list`).
  final RepoOpDispatcher? repoOps;

  /// Reactive watch-query registry (`sub/subscribe`).
  final WatchQueryRegistry? watchQueries;

  /// Callback when running state changes.
  void Function({required bool running})? onRunningChanged;

  RemoteControlConfig _config;
  late final WebRtcPeerManager _peerManager;
  final Map<String, _DeviceSession> _sessions = {};

  /// Per-device connection generation, bumped whenever a new offer is answered
  /// (a new peer connection is created) or the connection is ended. A parked
  /// [_onRemoteChannel] captures the generation it belongs to and, if a newer
  /// one has superseded it mid-handshake, cleans up only its own channel instead
  /// of mutating the device's *current* peer/session.
  final Map<String, int> _connGen = {};
  StreamSubscription<List<PairedDevicesTableData>>? _devicesSub;
  bool _running = false;
  final StreamController<Set<String>> _connectedController =
      StreamController<Set<String>>.broadcast();
  final StreamController<Set<String>> _awaitingController =
      StreamController<Set<String>>.broadcast();

  /// Emits the set of currently-connected device ids (those with a live RPC
  /// session) whenever a phone connects or disconnects.
  Stream<Set<String>> get connectedDevices => _connectedController.stream;

  /// Emits the set of device ids that have authenticated over WebRTC but are
  /// still `pendingConfirm` — a phone is on the line waiting for the user to
  /// confirm it on the desktop. Drives the "wants to connect" indicator.
  Stream<Set<String>> get awaitingApprovalDevices => _awaitingController.stream;

  void _emitConnected() {
    _connectedController.add(
      _sessions.entries
          .where((e) => e.value.rpc != null)
          .map((e) => e.key)
          .toSet(),
    );
  }

  void _emitAwaiting() {
    _awaitingController.add(
      _sessions.entries
          .where((e) => e.value.transport != null && e.value.rpc == null)
          .map((e) => e.key)
          .toSet(),
    );
  }

  /// Whether the server is currently listening for paired devices.
  bool get isRunning => _running;

  /// Updates configuration (signaling URL / STUN). Requires a restart to apply
  /// STUN/peer changes.
  void updateConfig(RemoteControlConfig config) => _config = config;

  /// Starts listening for active paired devices.
  Future<void> start() async {
    if (_running) {
      return;
    }
    // Latch `_running` synchronously, before the first await, so a concurrent or
    // duplicate start() (auto-start racing a manual toggle) bails at the guard
    // instead of opening a second set of signaling sockets into the same rooms.
    _running = true;
    AppLog.i(
      'RemoteControl',
      'Server starting (broker=${_config.signalingUrl})',
    );
    // Defensive: drop any prior subscription so we never run two device watchers.
    await _devicesSub?.cancel();
    _devicesSub = devicesDao.watchConnectable().listen(_syncDevices);
    // Seed currently-connectable devices (active + pending-confirmation), so the
    // desktop is already in the broker room when a freshly-paired phone scans.
    final all = await devicesDao.getAll();
    for (final d in all.where(
      (d) => d.status == 'active' || d.status == 'pendingConfirm',
    )) {
      await _ensureSignaling(d.id);
    }
    onRunningChanged?.call(running: true);
  }

  /// Stops listening and tears down every session + peer.
  Future<void> stop() async {
    if (!_running) {
      return;
    }
    _running = false;
    await _devicesSub?.cancel();
    _devicesSub = null;
    for (final id in _sessions.keys.toList()) {
      await _teardown(id);
    }
    await _peerManager.closeAll();
    onRunningChanged?.call(running: false);
    AppLog.i('RemoteControl', 'Server stopped');
  }

  void _syncDevices(List<PairedDevicesTableData> connectable) {
    final connectableIds = connectable.map((d) => d.id).toSet();
    for (final d in connectable) {
      _ensureSignaling(d.id);
      // Approval moment: a device that just flipped to `active` while a phone is
      // already authenticated and waiting → start its held RPC session now.
      if (d.status == 'active') {
        final session = _sessions[d.id];
        if (session != null &&
            session.transport != null &&
            session.rpc == null) {
          _startSession(d.id, session.transport!, d);
        }
      }
    }
    // Tear down anything no longer connectable (revoked/deleted) and tell the
    // phone it was revoked so it forgets the pairing (finding #6).
    for (final id in _sessions.keys.toList()) {
      if (!connectableIds.contains(id)) {
        _teardown(id, pushRevoke: true);
      }
    }
  }

  Future<void> _ensureSignaling(String deviceId) async {
    if (_sessions.containsKey(deviceId)) {
      return;
    }
    // Fresh random broker peer id per room — NOT a QR value (finding #7). Stable
    // across this client's internal reconnects (so same-id eviction reclaims our
    // slot), but unknowable to anyone holding only the pairing link.
    final signalingPeerId = RemoteControlCrypto.generateRoomCode();
    final client = SignalingClient(
      url: Uri.parse(_config.signalingUrl),
      room: deviceId,
      peerId: signalingPeerId,
    );
    final session = _DeviceSession(
      signaling: client,
      signalingPeerId: signalingPeerId,
    );
    // Serialize handling so a `peer-left` and the reconnect's `offer` never
    // interleave at an await point (see [_DeviceSession.signalChain]).
    session.signalingSub = client.incoming.listen((msg) {
      // catchError at the tail keeps every link completing normally, so a throw
      // in one handler can never skip the next frame.
      session.signalChain = session.signalChain
          .then((_) => _onSignaling(deviceId, msg))
          .catchError((Object e, StackTrace st) {
            AppLog.e(
              'RemoteControl',
              'Signaling handler error ($deviceId): $e',
              e,
              st,
            );
          });
    });
    _sessions[deviceId] = session;
    try {
      await client.connect();
    } catch (e, st) {
      AppLog.e(
        'RemoteControl',
        'Signaling connect failed for $deviceId: $e',
        e,
        st,
      );
    }
  }

  Future<void> _onSignaling(String deviceId, SignalingMessage msg) async {
    if (msg.type != SignalingMessageType.signal) {
      if (msg.type == SignalingMessageType.peerLeft) {
        await _onPeerLeft(deviceId, msg.from);
      }
      return;
    }
    final payload = msg.payload ?? const {};
    switch (msg.kind) {
      case 'offer':
        // Gate: connectable (active / pending-confirm) + PSK present + not
        // expired. Past-TTL credentials are purged here so a leaked link can't
        // be redeemed indefinitely (finding #3).
        final gate = await _gate(deviceId);
        if (!gate.ok) {
          await _peerManager.closePeer(deviceId);
          return;
        }
        final psk = gate.psk!;
        // Mandatory SDP signature — a real pre-DTLS PSK-possession gate. An
        // attacker without the PSK cannot produce a valid signature, so a
        // forged/unsigned offer never reaches setRemoteDescription/DTLS and can
        // never dispose the live authenticated peer (findings #9/#11/#19/#10).
        final sig = payload['sdp_sig'] as String?;
        final sdp = payload['sdp'] as String? ?? '';
        if (sig == null ||
            !RemoteControlCrypto.verifySdpSignature(sdp, psk, sig)) {
          AppLog.w(
            'RemoteControl',
            'Rejecting offer from $deviceId — '
                '${sig == null ? 'missing' : 'invalid'} SDP signature',
          );
          await _peerManager.closePeer(deviceId);
          return;
        }
        // Only a PSK-proven offer may (re)claim this connection: record which
        // phone it belongs to so a later `peer-left` from a superseded one (fast
        // refresh) can be ignored.
        _sessions[deviceId]?.phonePeerId = msg.from;
        try {
          // A new peer connection supersedes any prior in-flight one for this
          // device; bump the generation so a parked [_onRemoteChannel] for the
          // old peer won't tear down this new connection.
          _connGen[deviceId] = (_connGen[deviceId] ?? 0) + 1;
          final answer = await _peerManager.answerOffer(deviceId, payload);
          final session = _sessions[deviceId];
          if (session != null) {
            // Fire-and-forget: the answer is relayed over signaling; we don't
            // block the handler on the broker round-trip.
            unawaited(
              session.signaling.send(
                SignalingMessage(
                  type: SignalingMessageType.signal,
                  room: deviceId,
                  from: session.signalingPeerId,
                  kind: 'answer',
                  payload: answer,
                ),
              ),
            );
          }
        } catch (e, st) {
          AppLog.e(
            'RemoteControl',
            'answerOffer failed for $deviceId: $e',
            e,
            st,
          );
        }
      case 'ice':
        try {
          await _peerManager.addRemoteCandidate(deviceId, payload);
        } catch (e) {
          AppLog.w('RemoteControl', 'addRemoteCandidate($deviceId): $e');
        }
    }
  }

  void _onOutboundSignal(
    String deviceId, {
    required String kind,
    required Map<String, dynamic> payload,
  }) {
    final session = _sessions[deviceId];
    session?.signaling.send(
      SignalingMessage(
        type: SignalingMessageType.signal,
        room: deviceId,
        from: session.signalingPeerId,
        kind: kind,
        payload: payload,
      ),
    );
  }

  /// Authorizes a connect for [deviceId]: the device must be connectable
  /// (`active`/`pendingConfirm`), still hold a PSK, and not be past its
  /// `expiresAt`. An expired credential/offer is purged (PSK + row) so it fails
  /// closed — turning a once-permanent backdoor into a time-boxed one. Logs the
  /// denial reason; returns `(ok, row, psk)` for the caller.
  Future<({bool ok, PairedDevicesTableData? row, String? psk})> _gate(
    String deviceId,
  ) async {
    final row = await devicesDao.getById(deviceId);
    final psk = await secrets.readPsk(deviceId);
    final connectable =
        row != null &&
        (row.status == PairedDeviceStatus.active ||
            row.status == PairedDeviceStatus.pendingConfirm);
    if (!connectable || psk == null) {
      AppLog.w(
        'RemoteControl',
        'Denying connect from $deviceId — '
            'row=${row == null ? 'missing' : row.status}, '
            'psk=${psk == null ? 'missing' : 'present'}',
      );
      return (ok: false, row: row, psk: psk);
    }
    if (RemotePairingLifecycle.isExpired(row.expiresAt, DateTime.now())) {
      AppLog.w(
        'RemoteControl',
        'Credential expired for $deviceId (expiresAt=${row.expiresAt}) — '
            'purging and denying',
      );
      await _purge(deviceId);
      return (ok: false, row: row, psk: null);
    }
    return (ok: true, row: row, psk: psk);
  }

  /// Fails a device closed: deletes its PSK and metadata row. The
  /// `watchConnectable` stream then drives [_teardown].
  Future<void> _purge(String deviceId) async {
    await _safe(() => secrets.deletePsk(deviceId), deviceId, 'purge.deletePsk');
    await _safe(() => devicesDao.remove(deviceId), deviceId, 'purge.remove');
  }

  Future<void> _onRemoteChannel(String deviceId, RTCDataChannel channel) async {
    // The generation this channel belongs to. If a newer offer (or a teardown)
    // bumps it while we await below, this invocation has been superseded: it
    // must clean up only its OWN channel and never touch the device's current
    // peer/session (which now belong to a newer connection).
    final gen = _connGen[deviceId] ?? 0;
    bool superseded() => (_connGen[deviceId] ?? 0) != gen;

    // A fresh data channel supersedes any prior live connection for this device
    // (the phone reconnected). Drop the old RPC/forwarder/transport first so
    // they don't leak or double-handle frames. The signaling client and the new
    // peer connection are untouched.
    await _disposeSessionArtifacts(deviceId);

    // Wire the transport BEFORE the async gate below. The phone sends its
    // auth_challenge the instant its channel opens — typically before these DB +
    // keychain reads resolve — so starting capture now (the transport buffers
    // until a listener attaches) means that first frame is read, not dropped.
    final transport = WebRtcRemoteTransport(channel, deviceId: deviceId)
      ..start();

    final gate = await _gate(deviceId);
    if (!gate.ok || superseded()) {
      AppLog.w(
        'RemoteControl',
        superseded()
            ? 'Channel from $deviceId superseded before auth — dropping'
            : 'Closing channel from $deviceId — not authorized',
      );
      await transport.close();
      // Only deny the device's *current* peer; a superseded peer was already
      // disposed by the newer offer's answerOffer.
      if (!superseded()) {
        await _peerManager.closePeer(deviceId);
      }
      return;
    }
    final row = gate.row!;
    final psk = gate.psk!;

    // Layer (b): PSK nonce challenge bound to this session's DTLS fingerprints.
    // The desktop sends a challenge frame; the phone must reply with the correct
    // HMAC before the RPC session starts.
    final authenticated = await _authenticate(transport, deviceId, psk);
    if (!authenticated || superseded()) {
      AppLog.w(
        'RemoteControl',
        superseded()
            ? 'Channel from $deviceId superseded during auth — dropping'
            : 'Auth failed for $deviceId — closing',
      );
      await transport.close();
      if (!superseded()) {
        await _peerManager.closePeer(deviceId);
      }
      return;
    }

    // TOFU DTLS-fingerprint pinning (finding #17): the phone's DTLS identity is
    // pinned on first active connect; a later connect presenting a *different*
    // fingerprint — a second device that obtained the PSK — is denied, even
    // though it can pass the live nonce challenge.
    final remoteFp = _peerManager.fingerprints(deviceId).remote ?? '';
    final pinned = row.remoteFingerprint;
    if (pinned != null &&
        pinned.isNotEmpty &&
        !RemoteControlCrypto.constantTimeEquals(
          utf8.encode(pinned),
          utf8.encode(remoteFp),
        )) {
      AppLog.w(
        'RemoteControl',
        'DTLS fingerprint mismatch for $deviceId — denying (pinned identity '
            'differs from this connection)',
      );
      await transport.close();
      await _peerManager.closePeer(deviceId);
      return;
    }

    // Hold the authenticated transport on the session and drive teardown from it
    // (finding #13): if the data channel dies, end the session promptly instead
    // of waiting on the untrusted broker's `peer-left`.
    _sessions[deviceId]?.transport = transport;
    _wireTransportTeardown(deviceId, transport);

    // Re-approval after a long idle period (finding #3): a dormant approved
    // device is not silently resumed — it drops back to pending so the user must
    // re-approve it, making the reconnect visible rather than automatic.
    if (row.status == PairedDeviceStatus.active &&
        RemotePairingLifecycle.needsReapproval(
          row.lastSeenAt,
          DateTime.now(),
        )) {
      AppLog.i(
        'RemoteControl',
        'Device $deviceId idle too long — requiring re-approval',
      );
      await devicesDao.requireReapproval(
        deviceId,
        expiresAt: RemotePairingLifecycle.offerExpiry(DateTime.now()),
      );
      await _sendAwaitingApproval(transport);
      _emitAwaiting();
      return;
    }

    if (row.status == PairedDeviceStatus.active) {
      await _startSession(deviceId, transport, row);
      return;
    }

    // pendingConfirm: a human must approve this device on the desktop first.
    // Tell the phone to show a "waiting for approval" state; the RPC session is
    // started by [_syncDevices] the moment the user confirms (status → active).
    AppLog.i(
      'RemoteControl',
      'Device $deviceId authenticated — awaiting user confirmation',
    );
    await _sendAwaitingApproval(transport);
    _emitAwaiting();
  }

  /// Tells the phone to hold in its "waiting for approval" state. Best-effort —
  /// the phone re-derives state on reconnect if the send fails.
  Future<void> _sendAwaitingApproval(RemoteRpcChannelPort transport) async {
    try {
      await transport.send(const {'type': 'awaiting_approval'});
    } catch (_) {
      // Best-effort.
    }
  }

  /// Drives session teardown from the transport's own close (finding #13). A
  /// dead data channel (ICE/DTLS failure, peer gone) ends the session even if
  /// the broker never delivers a `peer-left`. The subscription is cancelled in
  /// [_disposeSessionArtifacts] before the transport is closed, so a deliberate
  /// teardown does not re-enter via this listener.
  void _wireTransportTeardown(String deviceId, RemoteRpcChannelPort transport) {
    final session = _sessions[deviceId];
    if (session == null) {
      return;
    }
    session.transportStateSub?.cancel();
    session.transportStateSub = transport.state.listen((s) {
      if (s == RemoteChannelState.closed) {
        AppLog.i(
          'RemoteControl',
          'Transport for $deviceId closed — ending session',
        );
        unawaited(_endSession(deviceId));
      }
    });
  }

  /// Starts the live RPC session + event forwarder for an authenticated,
  /// confirmed device, and signals the phone that it is approved. Idempotent per
  /// session (guarded by callers checking `rpc == null`).
  Future<void> _startSession(
    String deviceId,
    RemoteRpcChannelPort transport,
    PairedDevicesTableData row,
  ) async {
    final rpc = RemoteRpcSession(
      deviceId: deviceId,
      channel: transport,
      dispatcher: dispatcher,
      workspaceResolver: workspaceResolver,
      // A WebRTC peer is a companion phone — restrict it from privileged ops
      // (pairing.* etc.) regardless of the platform string it was paired with.
      capability: SessionCapability.fromPlatform(row.platform),
      repoOps: repoOps,
      watchQueries: watchQueries,
    );
    final forwarder = RemoteEventForwarder(
      eventBus: eventBus,
      channel: transport,
      deviceId: deviceId,
    );
    await rpc.start();
    forwarder.start();
    // Tell the phone it may proceed (it holds in "awaiting approval" until now).
    try {
      await transport.send(const {'type': 'approved'});
    } catch (_) {
      // Best-effort.
    }
    // Pin the phone's DTLS fingerprint on first active connect (TOFU, finding
    // #17). Later connects are checked against this in [_onRemoteChannel].
    if (row.remoteFingerprint == null) {
      final fp = _peerManager.fingerprints(deviceId).remote;
      if (fp != null && fp.isNotEmpty) {
        await devicesDao.setRemoteFingerprint(deviceId, fp);
      }
    }
    await devicesDao.markSeen(deviceId, DateTime.now());
    final existing = _sessions[deviceId];
    if (existing != null) {
      existing
        ..rpc = rpc
        ..forwarder = forwarder
        ..transport = transport;
    }
    _emitConnected();
    _emitAwaiting();
    AppLog.i('RemoteControl', 'Session up for $deviceId');
  }

  /// Runs the PSK challenge as the **responder**: the phone is the initiator
  /// (it sends `auth_challenge`), the desktop verifies the phone's proof and
  /// replies with `auth_response` the phone can verify. Both sides bind their
  /// HMAC to this session's DTLS fingerprints, so a broker that swapped
  /// fingerprints mid-negotiation makes the proofs disagree and auth fails.
  Future<bool> _authenticate(
    RemoteRpcChannelPort transport,
    String deviceId,
    String psk,
  ) async {
    // Wait briefly for the channel to be open before exchanging frames.
    if (!transport.isOpen) {
      final opened = await transport.state
          .firstWhere(
            (s) =>
                s == RemoteChannelState.open || s == RemoteChannelState.closed,
            // ignore: lines_longer_than_80_chars
          )
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () => RemoteChannelState.closed,
          )
          .then((s) => s == RemoteChannelState.open);
      if (!opened) {
        return false;
      }
    }

    // DTLS fingerprints of THIS session: `local` is this desktop's (from the
    // answer SDP), `remote` is the phone's (from the offer SDP) — the same two
    // strings the phone reads from its side.
    final fps = _peerManager.fingerprints(deviceId);
    final localFp = fps.local ?? '';
    final remoteFp = fps.remote ?? '';

    // The phone sends `auth_challenge` first: a nonce plus a proof that it holds
    // the PSK (computed from the phone's perspective: HMAC(psk, n|phone|desktop)).
    final Map<String, dynamic> challenge;
    try {
      challenge = await transport.incoming
          .firstWhere((f) => f['type'] == 'auth_challenge')
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      AppLog.w('RemoteControl', 'No auth_challenge from $deviceId: $e');
      return false;
    }

    final nonce = challenge['nonce'] as String? ?? '';
    if (nonce.isEmpty) {
      AppLog.w('RemoteControl', 'Empty auth nonce from $deviceId — denying');
      return false;
    }

    // Verify the phone's proof (mutual auth). From the desktop's side the phone's
    // fingerprint is `remoteFp` and our own is `localFp`, so the phone's local →
    // remote order maps to (remoteFp, localFp) here.
    final proof = challenge['proof'] as String?;
    if (proof == null ||
        !RemoteControlCrypto.verifyChallengeResponse(
          nonce: nonce,
          psk: psk,
          localFingerprint: remoteFp,
          remoteFingerprint: localFp,
          response: proof,
        )) {
      AppLog.w('RemoteControl', 'Auth proof mismatch for $deviceId — denying');
      return false;
    }

    // Reply so the phone can verify us, from the desktop's perspective:
    // HMAC(psk, nonce|desktopFp|phoneFp).
    final response = RemoteControlCrypto.respondToChallenge(
      nonce: nonce,
      psk: psk,
      localFingerprint: localFp,
      remoteFingerprint: remoteFp,
    );
    try {
      await transport.send({
        'type': 'auth_response',
        'nonce': nonce,
        'response': response,
      });
    } catch (e) {
      AppLog.w('RemoteControl', 'Auth response send failed ($deviceId): $e');
      return false;
    }
    return true;
  }

  /// Handles a `peer-left` for [deviceId]: the phone closed its broker socket
  /// (disconnect or refresh). Ends the live RTC/RPC session but **keeps the
  /// signaling client joined to the room** so the phone can reconnect without a
  /// desktop restart — the bug where a second refresh hung on "connecting" was
  /// this path tearing the desktop out of the room. [leaver] is the departing
  /// peer's id (from the broker); a `peer-left` from a *superseded* phone
  /// connection (the new tab's offer raced ahead of the old socket's close) is
  /// ignored so it doesn't kill the connection just established.
  Future<void> _onPeerLeft(String deviceId, String? leaver) async {
    final session = _sessions[deviceId];
    if (session == null) {
      return;
    }
    final current = session.phonePeerId;
    if (leaver != null && current != null && leaver != current) {
      AppLog.d(
        'RemoteControl',
        'Ignoring stale peer-left from $leaver for $deviceId (current=$current)',
      );
      return;
    }
    await _endSession(deviceId);
  }

  /// Ends the live connection for [deviceId] (RTC peer + RPC + forwarder) while
  /// leaving the signaling client joined to the room, ready to answer the
  /// phone's next offer. Idempotent.
  Future<void> _endSession(String deviceId) async {
    final session = _sessions[deviceId];
    if (session == null) {
      return;
    }
    // Supersede any in-flight [_onRemoteChannel] for this device so it won't
    // re-create / re-claim a session after we tear this one down.
    _connGen[deviceId] = (_connGen[deviceId] ?? 0) + 1;
    await _disposeSessionArtifacts(deviceId);
    await _safe(() => _peerManager.closePeer(deviceId), deviceId, 'closePeer');
    session.phonePeerId = null;
    AppLog.i(
      'RemoteControl',
      'Phone left $deviceId — connection ended, staying in room for reconnect',
    );
    _emitConnected();
    _emitAwaiting();
  }

  /// Disposes the per-connection artifacts (RPC session, event forwarder,
  /// transport) for [deviceId] and nulls them, leaving the signaling client and
  /// peer connection untouched. Safe to call when none exist. Each disposal step
  /// is isolated so a throw in one never leaks the others.
  Future<void> _disposeSessionArtifacts(String deviceId) async {
    final session = _sessions[deviceId];
    if (session == null) {
      return;
    }
    final forwarder = session.forwarder;
    final rpc = session.rpc;
    final transport = session.transport;
    final stateSub = session.transportStateSub;
    session
      ..forwarder = null
      ..rpc = null
      ..transport = null
      ..transportStateSub = null;
    // Cancel the teardown listener BEFORE closing the transport so the close
    // we trigger here doesn't re-enter [_endSession] via the listener.
    await _safe(() => stateSub?.cancel(), deviceId, 'transportStateSub.cancel');
    await _safe(() => forwarder?.dispose(), deviceId, 'forwarder.dispose');
    await _safe(() => rpc?.stop(), deviceId, 'rpc.stop');
    // rpc.stop() closes the channel; close() is idempotent, so this is a no-op
    // when rpc owned the transport and a real teardown when it didn't.
    await _safe(() => transport?.close(), deviceId, 'transport.close');
  }

  Future<void> _teardown(String deviceId, {bool pushRevoke = false}) async {
    final session = _sessions.remove(deviceId);
    if (session == null) {
      return;
    }
    // Supersede any in-flight [_onRemoteChannel]; the session is gone, so it
    // must not closePeer or re-claim against the device being torn down.
    _connGen[deviceId] = (_connGen[deviceId] ?? 0) + 1;
    // On a revoke, push a `revoked` frame so the phone clears its stored pairing
    // and returns to the connect screen, instead of spinning on reconnect with a
    // PSK that no longer authenticates (finding #6). Sent before close below.
    final transport = session.transport;
    if (pushRevoke && transport != null && transport.isOpen) {
      await _safe(
        () => transport.send(const {'type': 'revoked'}),
        deviceId,
        'revoke.push',
      );
    }
    await _safe(
      () => session.transportStateSub?.cancel(),
      deviceId,
      'transportStateSub.cancel',
    );
    await _safe(
      () => session.forwarder?.dispose(),
      deviceId,
      'forwarder.dispose',
    );
    await _safe(() => session.rpc?.stop(), deviceId, 'rpc.stop');
    await _safe(() => session.transport?.close(), deviceId, 'transport.close');
    await _safe(() => session.signalingSub?.cancel(), deviceId, 'signalingSub');
    await _safe(session.signaling.close, deviceId, 'signaling.close');
    await _safe(() => _peerManager.closePeer(deviceId), deviceId, 'closePeer');
    _connGen.remove(deviceId);
    AppLog.i('RemoteControl', 'Session torn down for $deviceId');
    _emitConnected();
    _emitAwaiting();
  }

  /// Runs a disposal [action], swallowing and logging any error so one failed
  /// step never aborts the rest of a teardown.
  Future<void> _safe(
    Future<void>? Function() action,
    String deviceId,
    String step,
  ) async {
    try {
      await action();
    } catch (e, st) {
      AppLog.w(
        'RemoteControl',
        'Teardown step "$step" failed for $deviceId: $e',
      );
      AppLog.d('RemoteControl', '$st');
    }
  }
}
