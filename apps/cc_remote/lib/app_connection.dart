import 'dart:async';
import 'dart:math';

import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_remote/auth/psk_handshake.dart';
import 'package:cc_remote/debug_log.dart';
import 'package:cc_remote/pairing/pairing_store.dart';
import 'package:cc_remote/rtc/rtc_transport.dart';
import 'package:cc_remote/rtc/signaling_client.dart';
import 'package:cc_remote/net/relay_rpc_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Coarse connection status the UI binds to the connection chip / connect screen.
enum RemoteStatus {
  /// No pairing record — show "Scan the QR code from your Mac".
  notPaired,

  /// Opening signaling + negotiating ICE + running the handshake.
  connecting,

  /// Authenticated, but the desktop has not confirmed this device yet — the
  /// user must approve it on their Mac before RPC starts.
  awaitingApproval,

  /// Channel open and authenticated — RPC works.
  connected,

  /// Repeated connect failures (typically a strict/symmetric NAT). The auto-loop
  /// keeps retrying; the UI offers a manual retry and a same-Wi-Fi hint.
  connectionFailed,

  /// A pairing offer arrived via the URL fragment and is awaiting explicit
  /// user confirmation before it is saved / connected (it used to auto-pair,
  /// a one-click MITM vector — VULN-004).
  pendingPairing,
}

/// [RemoteStatus] plus a user-facing [reason] (sentence case).
class RemoteUiState {
  const RemoteUiState._(this.status, {this.reason});

  /// Not paired.
  const RemoteUiState.notPaired() : this._(RemoteStatus.notPaired, reason: null);

  /// Connecting.
  const RemoteUiState.connecting()
    : this._(RemoteStatus.connecting, reason: null);

  /// Authenticated, waiting for the user to confirm this device on their Mac.
  const RemoteUiState.awaitingApproval()
    : this._(RemoteStatus.awaitingApproval, reason: null);

  /// Connected.
  const RemoteUiState.connected()
    : this._(RemoteStatus.connected, reason: null);

  /// Connection failed with a human-facing [reason].
  const RemoteUiState.connectionFailed(String reason)
    : this._(RemoteStatus.connectionFailed, reason: reason);

  /// A fragment-delivered pairing offer is awaiting confirmation.
  const RemoteUiState.pendingPairing()
    : this._(RemoteStatus.pendingPairing, reason: null);

  /// The status.
  final RemoteStatus status;

  /// Optional human-facing detail (set for [RemoteStatus.connectionFailed]).
  final String? reason;

  /// Convenience for the UI.
  bool get isNotPaired => status == RemoteStatus.notPaired;
  bool get isConnected => status == RemoteStatus.connected;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RemoteUiState &&
          status == other.status &&
          reason == other.reason;

  @override
  int get hashCode => Object.hash(status, reason);
}

/// Thrown when no pairing record is available (the user has not scanned a QR).
class NotPairedException implements Exception {
  const NotPairedException();

  @override
  String toString() => 'Not paired';
}

/// SharedPreferences key for the last-used workspace id. Survives a refresh so
/// the phone reopens in the same workspace; if it no longer exists the session
/// falls back to the first available workspace.
const String kActiveWorkspaceIdPref = 'active_workspace_id';

/// Owns the full phone→Mac connection lifecycle and exposes it as a single
/// [RemoteUiState] stream plus a [RemoteRpcClient] stream.
///
/// It builds the [RemoteRpcChannelPort] that [RemoteRpcClient] calls on every
/// (re)connect: load the [PairingRecord], open a [SignalingClient], negotiate a
/// [RtcTransport] (or relay through the broker), run the [PskHandshake], await
/// the desktop's approval, then wrap the authenticated channel in a
/// [RemoteRpcClient], run the `initialize` capability handshake, and emit it.
/// Reconnect/exponential-backoff live HERE ([RemoteRpcClient] correlates frames
/// on a single channel but does not reconnect); this layer translates connect
/// outcomes + the channel's open/closed state into the UI state, and re-emits a
/// fresh client after every successful (re)connect so feature providers
/// re-subscribe on the new transport.
class RemoteSession {
  /// Creates a [RemoteSession].
  RemoteSession();

  static const int _failureThreshold = 2;
  static const Duration _stableThreshold = Duration(seconds: 5);

  final PairingStore _store = PairingStore();
  SharedPreferences? _prefs;

  // The active RPC client (null while disconnected/reconnecting). Replaced on
  // every successful (re)connect — WebRTC channels are not reusable after close.
  RemoteRpcClient? _currentClient;
  StreamSubscription<RemoteChannelState>? _channelStateSub;
  // Listens for the desktop's `revoked` control frame (the pairing was revoked
  // on the Mac) so we forget it instead of spinning on a dead PSK.
  StreamSubscription<Map<String, dynamic>>? _revokedSub;
  final StreamController<RemoteRpcClient> _clientController =
      StreamController<RemoteRpcClient>.broadcast();

  final StreamController<RemoteUiState> _uiState =
      StreamController<RemoteUiState>.broadcast();

  // The active workspace id. Persisted so a refresh reopens the same workspace;
  // seeded onto every new client as `activeWorkspaceId` (the stateless server
  // has no session binding — each request carries it as `workspace_id`).
  String? _activeWorkspaceId;
  final StreamController<String?> _workspaceController =
      StreamController<String?>.broadcast();

  bool _paired = false;
  bool _started = false;
  bool _disposed = false;
  bool _awaitingApproval = false;
  bool _everConnected = false;
  bool _connecting = false;
  int _failures = 0;
  int _backoffStep = 0;
  Timer? _stableTimer;
  final Random _jitter = Random();
  Object? _lastError;
  // The phone's stable signaling peer id, loaded once from [PairingStore] in
  // [start] (persisted so a refresh reuses it).
  late final String _phonePeerId;
  RemoteUiState _state = const RemoteUiState.notPaired();
  /// An unconfirmed pairing offer decoded from the boot URL fragment. Held
  /// until the user confirms or declines on the connect screen — never
  /// auto-saved (VULN-004).
  PairingRecord? _pendingFragment;

  /// The pending fragment-delivered pairing offer awaiting confirmation, or
  /// null. The connect screen reads this to show the host in its gate.
  PairingRecord? get pendingPairingRecord => _pendingFragment;

  /// The active JSON-RPC client, or `null` when not connected. Screens should
  /// prefer watching [clientStream] (via `rpcClientProvider`) so they re-bind
  /// automatically after a reconnect swaps the client.
  RemoteRpcClient? get client => _currentClient;

  /// Emits the active [RemoteRpcClient] on every successful (re)connect. Feature
  /// providers watch this and re-subscribe when a new client arrives.
  Stream<RemoteRpcClient> get clientStream => _clientController.stream;

  /// The UI connection state, plus subsequent transitions.
  Stream<RemoteUiState> get uiState => _uiState.stream;

  /// The latest UI state.
  RemoteUiState get currentUiState => _state;

  /// Whether the session has been [RemoteStatus.connected] at least once. The
  /// router uses this to keep the full-screen status flow only for the *initial*
  /// connection; later transient drops are surfaced in-app.
  bool get hasEverConnected => _everConnected;

  /// The active workspace id (persisted), plus subsequent changes.
  String? get activeWorkspaceId => _activeWorkspaceId;
  Stream<String?> get activeWorkspaceStream => _workspaceController.stream;

  /// Boot: consume the URL fragment (first scan), load prefs, then connect.
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    _prefs = await SharedPreferences.getInstance();
    _activeWorkspaceId = _prefs?.getString(kActiveWorkspaceIdPref);
    // If the desktop revokes this device, forget the pairing and return to the
    // connect screen instead of spinning on reconnect with a dead PSK.
    // Load the stable peer id before any connect (so a refresh reuses it).
    _phonePeerId = await _store.loadOrCreatePeerId();
    rlog('boot', 'session starting (phonePeerId=$_phonePeerId, '
        'workspace=$_activeWorkspaceId)');

    final offer = await _store.decodeFragmentOffer();
    if (offer != null) {
      // VULN-004: a fragment-delivered pairing offer is held UNCONFIRMED —
      // never auto-saved / auto-connected (any page could open the PWA with a
      // forged `#<payload>`). The connect screen shows the host and requires
      // explicit confirmation before we persist or connect anything.
      _pendingFragment = offer;
      rlog('boot', 'pairing offer from URL fragment — awaiting confirmation: '
          '$offer');
      final pending = const RemoteUiState.pendingPairing();
      _state = pending;
      if (!_uiState.isClosed) {
        _uiState.add(pending);
      }
      return;
    }

    final stored = await _store.load();
    _paired = stored != null;
    rlog(
      'boot',
      stored != null
          ? 'paired from stored record: $stored'
          : 'no pairing record — staying on connect screen',
    );

    _reevaluate();

    if (_paired && !_disposed) {
      // Fire and forget: outcomes arrive over [uiState] / [clientStream].
      _connectAndBind();
    }
  }

  /// Manual retry from the connection-failed state: resets the failure counter
  /// so the UI flips back to "connecting" and triggers an immediate reconnect.
  Future<void> retry() async {
    _failures = 0;
    _lastError = null;
    _backoffStep = 0;
    _reevaluate();
    _connectAndBind();
  }

  /// Confirms the pending fragment-delivered pairing: saves it (replacing any
  /// existing record) and connects. Must be triggered by the user from the
  /// connect screen's confirmation gate — a fragment offer is never auto-saved
  /// (VULN-004).
  Future<void> confirmPendingPairing() async {
    final offer = _pendingFragment;
    if (offer == null) {
      return;
    }
    _pendingFragment = null;
    await _store.save(offer);
    _paired = true;
    rlog('boot', 'confirmed fragment pairing: $offer');
    _reevaluate();
    if (!_disposed) {
      _connectAndBind();
    }
  }

  /// Declines the pending fragment-delivered pairing: discards the offer and
  /// falls back to any previously-stored record (or stays not-paired).
  Future<void> declinePendingPairing() async {
    _pendingFragment = null;
    final stored = await _store.load();
    _paired = stored != null;
    rlog('boot', 'declined fragment pairing; stored=${stored != null}');
    _reevaluate();
    if (_paired && !_disposed) {
      _connectAndBind();
    }
  }

  /// Drops the pairing record and disconnects — returns to the connect screen.
  Future<void> unpair() async {
    await _teardownClient();
    await _store.clear();
    _paired = false;
    _everConnected = false;
    _failures = 0;
    _lastError = null;
    _reevaluate();
  }

  /// Points the session at [workspaceId]: persists it (survives refresh), seeds
  /// the active client, and notifies workspace observers. Picking is local — the
  /// stateless server has no binding to set.
  Future<void> setActiveWorkspace(String workspaceId) async {
    if (_activeWorkspaceId == workspaceId) {
      return;
    }
    _activeWorkspaceId = workspaceId;
    _currentClient?.activeWorkspaceId = workspaceId;
    await _prefs?.setString(kActiveWorkspaceIdPref, workspaceId);
    if (!_workspaceController.isClosed) {
      _workspaceController.add(workspaceId);
    }
  }

  /// Releases all resources.
  Future<void> dispose() async {
    _disposed = true;
    _stableTimer?.cancel();
    _stableTimer = null;
    await _teardownClient();
    if (!_uiState.isClosed) {
      await _uiState.close();
    }
    if (!_clientController.isClosed) {
      await _clientController.close();
    }
    if (!_workspaceController.isClosed) {
      await _workspaceController.close();
    }
  }

  // --- The connect + reconnect lifecycle --------------------------------

  Future<void> _connectAndBind() async {
    if (_disposed || _connecting || _currentClient != null) {
      return;
    }
    _connecting = true;
    _reevaluate();
    try {
      final channel = await _connect();
      if (_disposed) {
        await channel.close();
        return;
      }
      final client = RemoteRpcClient(channel, timeout: const Duration(seconds: 30))
        ..start();
      // Capability handshake — also confirms the server speaks repo/call +
      // subscriptions before we issue any.
      try {
        await client.initialize(clientName: 'cc-remote', clientVersion: '0.1.0');
      } catch (e, s) {
        rlog('rpc', 'initialize failed', error: e, stack: s);
        // Non-fatal: an older host may not advertise initialize; proceed.
      }
      await _resolveActiveWorkspace(client);
      client.activeWorkspaceId = _activeWorkspaceId;

      // Replace the previous client (a reconnect creates a brand-new transport).
      final previous = _currentClient;
      _currentClient = client;
      _channelStateSub?.cancel();
      _channelStateSub = channel.state.listen((s) {
        if (s == RemoteChannelState.closed) {
          _onChannelLost();
        }
      });
      _revokedSub?.cancel();
      _revokedSub = channel.incoming
          .where((f) => f['type'] == 'revoked')
          .listen((_) {
            rlog('rpc', 'desktop revoked this device — forgetting pairing');
            unpair();
          });
      if (!_clientController.isClosed) {
        _clientController.add(client);
      }
      // Tear the superseded client down once observers have moved to the new one.
      if (previous != null) {
        unawaited(previous.close());
      }

      _failures = 0;
      _lastError = null;
      _scheduleStableReset();
      _reevaluate();
      rlog('rpc', 'client ready (workspace=$_activeWorkspaceId)');
    } catch (e, s) {
      if (_disposed) {
        return;
      }
      rlog('rpc', 'connect/bind failed', error: e, stack: s);
      _lastError = e;
      _failures++;
      _reevaluate();
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  void _onChannelLost() {
    if (_disposed) {
      return;
    }
    rlog('rpc', 'channel lost — will reconnect');
    _stableTimer?.cancel();
    _stableTimer = null;
    _channelStateSub?.cancel();
    _channelStateSub = null;
    _revokedSub?.cancel();
    _revokedSub = null;
    // Drop the dead client so [client] is null while reconnecting and
    // [_connectAndBind] can build a fresh one. Its subscriptions stop emitting;
    // feature providers re-subscribe on the next [clientStream] emission.
    _currentClient = null;
    _reevaluate();
    _scheduleReconnect();
  }

  Future<void> _teardownClient() async {
    _stableTimer?.cancel();
    _stableTimer = null;
    _channelStateSub?.cancel();
    _channelStateSub = null;
    _revokedSub?.cancel();
    _revokedSub = null;
    final client = _currentClient;
    _currentClient = null;
    await client?.close();
  }

  /// Resolves the active workspace against the live list: keeps the persisted
  /// id when it still exists, otherwise falls back to the first workspace (and
  /// persists that). No-op when there are no workspaces yet.
  Future<void> _resolveActiveWorkspace(RemoteRpcClient client) async {
    try {
      final rows = await client.listWorkspaces();
      final ids = rows
          .map((w) => w['id'])
          .whereType<String>()
          .toSet();
      final current = _activeWorkspaceId;
      if (current != null && ids.contains(current)) {
        return;
      }
      if (ids.isEmpty) {
        return;
      }
      final first = rows.first['id'];
      if (first is String) {
        _activeWorkspaceId = first;
        await _prefs?.setString(kActiveWorkspaceIdPref, first);
        if (!_workspaceController.isClosed) {
          _workspaceController.add(first);
        }
      }
    } catch (e) {
      rlog('rpc', 'workspace resolve failed: $e');
    }
  }

  /// Resets the reconnect backoff only after the channel has stayed open for
  /// [_stableThreshold]; cancelled by [_onChannelLost] if it drops first.
  void _scheduleStableReset() {
    _stableTimer?.cancel();
    _stableTimer = Timer(_stableThreshold, () {
      _backoffStep = 0;
    });
  }

  void _scheduleReconnect() {
    if (_disposed || !_paired) {
      return;
    }
    // Exponential backoff capped at ~30s with up to 30% jitter.
    final base = (1000 * (1 << _backoffStep.clamp(0, 5))).clamp(1000, 30000);
    final jitterMs = _jitter.nextInt((base * 0.3).round() + 1);
    final delay = Duration(milliseconds: base + jitterMs);
    _backoffStep++;
    rlog('rpc', 'reconnect scheduled in ${delay.inMilliseconds}ms');
    Future<void>.delayed(delay, _connectAndBind);
  }

  // --- The injected channel factory --------------------------------------

  Future<RemoteRpcChannelPort> _connect() async {
    rlog('connect', 'attempt #${_failures + 1} starting');
    final record = await _store.load();
    if (record == null) {
      rlog('connect', 'no pairing record on load — not paired');
      _paired = false;
      _reevaluate();
      throw const NotPairedException();
    }
    rlog(
      'connect',
      'record mode=${record.mode} room=${record.room} '
          'signaling=${record.signalingUrl} stun=${record.stunUrls} '
          'expired=${record.isExpired}',
    );

    if (record.isRelay) {
      return _connectRelay(record);
    }
    return _connectWebrtc(record);
  }

  /// Relay path: rendezvous with cc_server in the broker room and tunnel
  /// E2E-encrypted RPC through it.
  Future<RemoteRpcChannelPort> _connectRelay(PairingRecord record) async {
    final signaling = SignalingClient(record.signalingUrl);
    final channel = RelayRpcChannel(
      signaling: signaling,
      room: record.room,
      peerId: _phonePeerId,
      psk: record.psk,
    );
    try {
      rlog('relay', 'joining room ${record.room} → ${record.signalingUrl}');
      await signaling.connect(room: record.room, peerId: _phonePeerId);
      await channel.awaitReady();
      rlog('relay', 'server present — authenticating');
      await _authenticateRelay(
        channel,
        deviceId: record.room,
        psk: record.psk,
      );
      rlog('relay', 'authenticated — awaiting approval');
      await _awaitApproval(channel);
      rlog('relay', 'approved — channel ready');
      _failures = 0;
      _lastError = null;
      return channel;
    } catch (e, s) {
      rlog('relay', 'attempt failed', error: e, stack: s);
      _lastError = e;
      _failures++;
      await channel.close();
      _reevaluate();
      rethrow;
    }
  }

  /// Sends the cc_server PSK auth frame over [channel] and verifies the server's
  /// matching proof.
  Future<void> _authenticateRelay(
    RemoteRpcChannelPort channel, {
    required String deviceId,
    required String psk,
  }) async {
    final nonce = PskHandshake.generateNonce();
    final proof = PskHandshake.challengeResponse(
      nonce: nonce,
      psk: psk,
      localFingerprint: '',
      remoteFingerprint: '',
    );
    final replyFuture = channel.incoming
        .firstWhere(
          (f) => f['type'] == 'auth_response' || f['type'] == 'auth_denied',
        )
        .timeout(const Duration(seconds: 15));
    await channel.send({
      'type': 'auth',
      'device_id': deviceId,
      'nonce': nonce,
      'proof': proof,
    });
    final reply = await replyFuture;
    if (reply['type'] == 'auth_denied') {
      throw const SignalingException('Your computer rejected this device');
    }
    if (reply['response'] != proof) {
      throw const SignalingException('Server auth proof mismatch');
    }
  }

  Future<RemoteRpcChannelPort> _connectWebrtc(PairingRecord record) async {
    final signaling = SignalingClient(record.signalingUrl);
    try {
      rlog('signaling', 'connecting → ${record.signalingUrl}');
      await signaling.connect(room: record.room, peerId: _phonePeerId);
      rlog('signaling', 'joined room ${record.room}');

      final transport = RtcTransport(record.stunUrls);
      rlog('rtc', 'negotiating as offerer (stun=${record.stunUrls})');
      await transport.negotiate(
        room: record.room,
        peerId: _phonePeerId,
        signaling: signaling,
        // Sign the offer with the PSK so the desktop can verify possession
        // before answering / DTLS (mandatory pre-DTLS gate).
        signOffer: (sdp) => PskHandshake.signSdp(sdp, record.psk),
      );
      rlog('rtc', 'data channel open');

      final fps = await transport.fingerprints();
      rlog('handshake', 'running PSK handshake (DTLS-bound)');
      await PskHandshake.run(
        channel: transport,
        psk: record.psk,
        localFp: fps.local,
        remoteFp: fps.remote,
      );
      rlog('handshake', 'authenticated — awaiting desktop approval');

      await _awaitApproval(transport);
      rlog('handshake', 'approved — channel ready');

      _failures = 0;
      _lastError = null;
      return transport;
    } catch (e, s) {
      rlog('connect', 'attempt failed', error: e, stack: s);
      _lastError = e;
      _failures++;
      await signaling.close();
      _reevaluate();
      rethrow;
    }
  }

  /// Waits for the desktop's `approved` control frame after the PSK handshake.
  Future<void> _awaitApproval(RemoteRpcChannelPort channel) async {
    final completer = Completer<void>();
    late StreamSubscription<Map<String, dynamic>> sub;
    sub = channel.incoming.listen(
      (frame) {
        switch (frame['type']) {
          case 'approved':
            if (!completer.isCompleted) {
              completer.complete();
            }
          case 'awaiting_approval':
            rlog('approval', 'desktop is waiting for you to confirm this device');
            if (!_awaitingApproval) {
              _awaitingApproval = true;
              _reevaluate();
            }
        }
      },
      onError: (Object e) {
        if (!completer.isCompleted) {
          completer.completeError(e);
        }
      },
      onDone: () {
        if (!completer.isCompleted) {
          completer.completeError(
            const SignalingException('Channel closed while awaiting approval'),
          );
        }
      },
    );
    try {
      await completer.future.timeout(
        const Duration(minutes: 5),
        onTimeout: () {
          throw const SignalingException('Timed out waiting for approval');
        },
      );
    } finally {
      _awaitingApproval = false;
      await sub.cancel();
    }
  }

  void _reevaluate() {
    if (_disposed) {
      return;
    }
    final RemoteUiState next;
    if (!_paired) {
      next = const RemoteUiState.notPaired();
    } else if (_currentClient != null && _currentClient!.isOpen) {
      _everConnected = true;
      next = const RemoteUiState.connected();
    } else if (_awaitingApproval) {
      next = const RemoteUiState.awaitingApproval();
    } else if (_failures >= _failureThreshold) {
      next = RemoteUiState.connectionFailed(_friendlyReason(_lastError));
    } else {
      next = const RemoteUiState.connecting();
    }

    if (next != _state) {
      rlog(
        'state',
        '${_state.status.name} → ${next.status.name}'
            '${next.reason != null ? ' (${next.reason})' : ''}'
            ' [failures=$_failures]',
      );
      _state = next;
      if (!_uiState.isClosed) {
        _uiState.add(next);
      }
    }
  }

  String _friendlyReason(Object? error) {
    if (error is IceConnectException) {
      return "Couldn't connect remotely — try the same Wi-Fi as your Mac";
    }
    if (error is NotPairedException) {
      return 'Not paired — scan the QR code from your Mac';
    }
    if (error is SignalingException &&
        error.message.toLowerCase().contains('full')) {
      return 'The pairing room is full — your Mac may already be connected. '
          'Restart Control Center on your Mac, then tap to retry.';
    }
    // In debug builds, surface the real error on the connect screen itself so
    // the cause is visible without opening DevTools. Stripped from release.
    if (kDebugMode && error != null) {
      return "Couldn't connect — tap to retry  [${error.runtimeType}: $error]";
    }
    return "Couldn't connect — tap to retry";
  }
}
