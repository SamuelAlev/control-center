import 'dart:async';
import 'dart:math';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/debug_log.dart';
import 'package:cc_remote/media_proxy.dart';
import 'package:cc_remote/pairing/pairing_store.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Coarse connection status the UI binds to the connection chip / connect screen.
enum RemoteStatus {
  /// No pairing record — show "Scan the QR code from your Mac".
  notPaired,

  /// Resolving the best path + authenticating (or auto-reconnecting).
  connecting,

  /// A path is live and authenticated — RPC works.
  connected,

  /// Repeated connect failures. The auto-loop keeps retrying; the UI offers a
  /// manual retry and a same-network hint.
  connectionFailed,

  /// The server presented a different identity than the pinned fingerprint —
  /// terminal until the user re-pairs. There is no "continue anyway".
  identityMismatch,

  /// A pairing offer arrived via the URL fragment and is awaiting explicit
  /// user confirmation before it is saved / connected (it used to auto-pair,
  /// a one-click MITM vector — VULN-004).
  pendingPairing,
}

/// [RemoteStatus] plus a user-facing [reason] (sentence case).
class RemoteUiState {
  const RemoteUiState._(this.status, {this.reason});

  /// Not paired.
  const RemoteUiState.notPaired()
    : this._(RemoteStatus.notPaired, reason: null);

  /// Connecting.
  const RemoteUiState.connecting()
    : this._(RemoteStatus.connecting, reason: null);

  /// Connected.
  const RemoteUiState.connected()
    : this._(RemoteStatus.connected, reason: null);

  /// Connection failed with a human-facing [reason].
  const RemoteUiState.connectionFailed(String reason)
    : this._(RemoteStatus.connectionFailed, reason: reason);

  /// The server's identity no longer matches the pinned fingerprint.
  const RemoteUiState.identityMismatch()
    : this._(RemoteStatus.identityMismatch, reason: null);

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

/// Owns the full phone→server connection lifecycle and exposes it as a single
/// [RemoteUiState] stream plus one stable [RemoteRpcClient].
///
/// The heavy lifting lives in cc_rpc (PRD 15): a [ServerConnectionSupervisor]
/// probes every path in the stored [ConnectionDescriptor] (LAN / tailnet /
/// wss / broker relay), connects the best reachable one, authenticates with
/// the device PSK, verifies the server's identity against the TOFU-pinned
/// fingerprint, health-pings and auto-reconnects with backoff. A
/// [ResilientRpcClient] wraps it as ONE stable client whose `subscribe()`
/// streams survive reconnects — [clientStream] therefore emits exactly once
/// per pairing session and feature providers never need to re-bind.
///
/// This class adds only the phone-session concerns: the pairing store (and the
/// VULN-004 confirm gate for fragment-delivered offers), the initial-connect
/// retry loop (the supervisor's `start` throws on first failure), persisting
/// descriptor refreshes + the pinned fingerprint, mapping supervisor status to
/// [RemoteUiState] and the persisted active-workspace selection.
class RemoteSession {
  /// Creates a [RemoteSession].
  RemoteSession();

  static const int _failureThreshold = 2;

  final PairingStore _store = PairingStore();
  SharedPreferences? _prefs;

  ServerConnectionSupervisor? _supervisor;
  StreamSubscription<ServerConnectionStatus>? _statusSub;

  // The one stable RPC client (null until the first successful connect of this
  // pairing session). It survives reconnects — the supervisor swaps transports
  // underneath it — so it is emitted on [clientStream] exactly once.
  ResilientRpcClient? _client;
  final StreamController<RemoteRpcClient> _clientController =
      StreamController<RemoteRpcClient>.broadcast();

  final StreamController<RemoteUiState> _uiState =
      StreamController<RemoteUiState>.broadcast();

  // The active workspace id. Persisted so a refresh reopens the same workspace;
  // seeded onto the client as `activeWorkspaceId` (the stateless server has no
  // session binding — each request carries it as `workspace_id`).
  String? _activeWorkspaceId;
  final StreamController<String?> _workspaceController =
      StreamController<String?>.broadcast();

  // The in-memory copy of the stored pairing record; updated (and re-saved)
  // when the server re-publishes its descriptor or the fingerprint is pinned.
  PairingRecord? _record;

  // The signed-media origin of the LIVE path, or null when there is none (not
  // connected, or connected through the broker relay — which carries RPC
  // frames, not byte ranges). Recomputed on every `connected` status because a
  // failover can land on a different address than the QR carried.
  RemoteMediaEndpoint? _mediaEndpoint;
  final StreamController<RemoteMediaEndpoint?> _mediaController =
      StreamController<RemoteMediaEndpoint?>.broadcast();

  bool _paired = false;
  bool _started = false;
  bool _disposed = false;
  bool _everConnected = false;
  bool _connecting = false;
  int _failures = 0;
  Completer<void>? _retryWake;
  final Random _jitter = Random();
  Object? _lastError;
  RemoteUiState _state = const RemoteUiState.notPaired();

  /// An unconfirmed pairing offer decoded from the boot URL fragment. Held
  /// until the user confirms or declines on the connect screen — never
  /// auto-saved (VULN-004).
  PairingRecord? _pendingFragment;

  /// The pending fragment-delivered pairing offer awaiting confirmation, or
  /// null. The connect screen reads this to show the server name in its gate.
  PairingRecord? get pendingPairingRecord => _pendingFragment;

  /// The stable JSON-RPC client, or `null` before the first successful connect
  /// of this pairing session. It survives reconnects, so holding it is safe;
  /// screens watch [clientStream] (via `rpcClientProvider`) to obtain it.
  RemoteRpcClient? get client => _client;

  /// Emits the stable [RemoteRpcClient] once per pairing session (it survives
  /// reconnects — subscriptions re-register transparently underneath it).
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

  /// The signed-media origin for the live connection, or null when there is
  /// none. See [RemoteMediaEndpoint] for why a relayed session has none.
  RemoteMediaEndpoint? get mediaEndpoint => _mediaEndpoint;

  /// [mediaEndpoint], plus subsequent changes (connect, failover, drop).
  Stream<RemoteMediaEndpoint?> get mediaEndpointStream =>
      _mediaController.stream;

  /// Boot: consume the URL fragment (first scan), load prefs, then connect.
  Future<void> start() async {
    if (_started) {
      return;
    }
    _started = true;
    _prefs = await SharedPreferences.getInstance();
    _activeWorkspaceId = _prefs?.getString(kActiveWorkspaceIdPref);
    rlog('boot', 'session starting (workspace=$_activeWorkspaceId)');

    final offer = await _store.decodeFragmentOffer();
    if (offer != null) {
      // VULN-004: a fragment-delivered pairing offer is held UNCONFIRMED —
      // never auto-saved / auto-connected (any page could open the PWA with a
      // forged `#<payload>`). The connect screen shows the server name and
      // requires explicit confirmation before we persist or connect anything.
      _pendingFragment = offer;
      rlog(
        'boot',
        'pairing offer from URL fragment — awaiting confirmation: '
            '$offer',
      );
      _setState(const RemoteUiState.pendingPairing());
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

    if (!_paired) {
      _setState(const RemoteUiState.notPaired());
      return;
    }
    // Fire and forget: outcomes arrive over [uiState] / [clientStream].
    unawaited(_connectAndBind());
  }

  /// Manual retry from the connection-failed state: resets the failure counter
  /// so the UI flips back to "connecting" and wakes the initial-connect loop
  /// (post-first-connect reconnects are supervisor-owned and already running).
  Future<void> retry() async {
    _failures = 0;
    _lastError = null;
    if (_paired) {
      _setState(const RemoteUiState.connecting());
    }
    final wake = _retryWake;
    if (wake != null && !wake.isCompleted) {
      wake.complete();
      return;
    }
    if (_client == null && _supervisor == null && !_connecting) {
      unawaited(_connectAndBind());
    }
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
    // Replacing a pairing replaces the whole trust context, including any
    // previously pinned fingerprint and live connection.
    await _teardownConnection();
    await _store.save(offer);
    _paired = true;
    _everConnected = false;
    _failures = 0;
    _lastError = null;
    rlog('boot', 'confirmed fragment pairing: $offer');
    if (!_disposed) {
      unawaited(_connectAndBind());
    }
  }

  /// Declines the pending fragment-delivered pairing: discards the offer and
  /// falls back to any previously-stored record (or stays not-paired).
  Future<void> declinePendingPairing() async {
    _pendingFragment = null;
    final stored = await _store.load();
    _paired = stored != null;
    rlog('boot', 'declined fragment pairing; stored=${stored != null}');
    if (!_paired) {
      _setState(const RemoteUiState.notPaired());
      return;
    }
    if (!_disposed && _client == null && !_connecting) {
      _setState(const RemoteUiState.connecting());
      unawaited(_connectAndBind());
    }
  }

  /// Drops the pairing record and disconnects — returns to the connect screen.
  /// Also the escape hatch from [RemoteStatus.identityMismatch]: forgetting
  /// the pairing clears the stale pin so the user can re-pair from a fresh QR.
  Future<void> unpair() async {
    await _teardownConnection();
    await _store.clear();
    _record = null;
    _paired = false;
    _everConnected = false;
    _failures = 0;
    _lastError = null;
    _setState(const RemoteUiState.notPaired());
  }

  /// Points the session at [workspaceId]: persists it (survives refresh), seeds
  /// the client and notifies workspace observers. Picking is local — the
  /// stateless server has no binding to set.
  Future<void> setActiveWorkspace(String workspaceId) async {
    if (_activeWorkspaceId == workspaceId) {
      return;
    }
    _activeWorkspaceId = workspaceId;
    _client?.activeWorkspaceId = workspaceId;
    await _prefs?.setString(kActiveWorkspaceIdPref, workspaceId);
    if (!_workspaceController.isClosed) {
      _workspaceController.add(workspaceId);
    }
  }

  /// Releases all resources.
  Future<void> dispose() async {
    _disposed = true;
    _retryWake?.complete();
    await _teardownConnection();
    if (!_uiState.isClosed) {
      await _uiState.close();
    }
    if (!_clientController.isClosed) {
      await _clientController.close();
    }
    if (!_workspaceController.isClosed) {
      await _workspaceController.close();
    }
    if (!_mediaController.isClosed) {
      await _mediaController.close();
    }
  }

  // --- The connect lifecycle ---------------------------------------------

  /// Builds the supervisor from the stored record, runs the initial-connect
  /// retry loop (the supervisor throws on FIRST failure; once it has connected
  /// it auto-reconnects forever), then wraps it in the one stable
  /// [ResilientRpcClient] and emits it.
  Future<void> _connectAndBind() async {
    if (_disposed || _connecting || _client != null) {
      return;
    }
    _connecting = true;
    try {
      final record = await _store.load();
      if (record == null) {
        rlog('connect', 'no pairing record on load — not paired');
        _paired = false;
        _setState(const RemoteUiState.notPaired());
        return;
      }
      _record = record;
      rlog(
        'connect',
        'starting supervisor: ${record.descriptor} '
            '(pin=${record.pinnedFingerprint.isEmpty ? 'none' : 'set'}, '
            'expired=${record.isExpired})',
      );

      final supervisor = ServerConnectionSupervisor(
        descriptor: record.descriptor,
        deviceId: record.deviceId,
        psk: record.psk,
        pinnedFingerprint: record.pinnedFingerprint.isEmpty
            ? null
            : record.pinnedFingerprint,
        onDescriptorUpdated: _persistDescriptor,
        onFingerprintPinned: _persistPinnedFingerprint,
      );
      _supervisor = supervisor;
      _statusSub = supervisor.status.listen(_onSupervisorStatus);
      _setState(const RemoteUiState.connecting());

      // Initial-connect retry loop with exponential backoff + jitter. The
      // supervisor owns reconnects only AFTER its first success.
      var backoffStep = 0;
      while (!_disposed && _paired) {
        try {
          await supervisor.start();
          break;
        } on ServerIdentityMismatchException catch (e, s) {
          rlog(
            'connect',
            'server identity mismatch — terminal',
            error: e,
            stack: s,
          );
          _setState(const RemoteUiState.identityMismatch());
          await _teardownConnection(keepState: true);
          // Idempotent: covers an unpair() racing this attempt, where the
          // teardown above no longer holds this supervisor.
          await supervisor.close();
          return;
        } catch (e, s) {
          rlog('connect', 'attempt failed', error: e, stack: s);
          _lastError = e;
          _failures++;
          if (_failures >= _failureThreshold) {
            _setState(RemoteUiState.connectionFailed(_friendlyReason(e)));
          }
        }
        final base = (1000 * (1 << backoffStep.clamp(0, 5))).clamp(1000, 30000);
        backoffStep++;
        final delay = Duration(
          milliseconds: base + _jitter.nextInt((base * 0.3).round() + 1),
        );
        rlog('connect', 'retry scheduled in ${delay.inMilliseconds}ms');
        final wake = Completer<void>();
        _retryWake = wake;
        await Future.any(<Future<void>>[
          Future<void>.delayed(delay),
          wake.future,
        ]);
        _retryWake = null;
      }
      if (_disposed || !_paired) {
        await _teardownConnection();
        // An unpair()/dispose() that raced a succeeding start() already tore
        // the session fields down — close the locally adopted supervisor too
        // (idempotent when the teardown above got it).
        await supervisor.close();
        return;
      }

      _failures = 0;
      _lastError = null;
      final client = ResilientRpcClient(supervisor);
      _client = client;
      await _resolveActiveWorkspace(client);
      client.activeWorkspaceId = _activeWorkspaceId;
      if (!_clientController.isClosed) {
        _clientController.add(client);
      }
      rlog('rpc', 'client ready (workspace=$_activeWorkspaceId)');
    } finally {
      _connecting = false;
    }
  }

  /// Maps the supervisor's connection phases onto the phone's UI states.
  void _onSupervisorStatus(ServerConnectionStatus status) {
    if (_disposed || !_paired) {
      return;
    }
    switch (status.phase) {
      case ServerConnectionPhase.connecting:
        // Keep showing "failed" during background retries past the threshold
        // (each retry re-enters connecting; flapping the banner helps no one).
        if (_failures < _failureThreshold) {
          _setState(const RemoteUiState.connecting());
        }
      case ServerConnectionPhase.connected:
        _everConnected = true;
        _failures = 0;
        _lastError = null;
        final path = status.path;
        rlog(
          'rpc',
          'connected via ${path?.toJson()['t']} '
              '(relayed=${status.relayed}, latency=${status.latency?.inMilliseconds}ms)',
        );
        _setMediaEndpoint(_endpointFor(path));
        _setState(const RemoteUiState.connected());
      case ServerConnectionPhase.reconnecting:
        if (status.attempt >= _failureThreshold) {
          _setState(
            RemoteUiState.connectionFailed(
              _friendlyReason(_lastError ?? status.error),
            ),
          );
        } else {
          _setState(const RemoteUiState.connecting());
        }
      case ServerConnectionPhase.identityMismatch:
        rlog(
          'rpc',
          'server identity mismatch on reconnect — terminal '
              '(${status.error})',
        );
        _setState(const RemoteUiState.identityMismatch());
      case ServerConnectionPhase.closed:
        // We initiate closes (unpair / re-pair / dispose) and set the state
        // on those paths.
        break;
    }
  }

  /// Builds the signed-media origin for [path], or null when this path has no
  /// HTTP origin (the broker relay) or no pairing credential is loaded.
  RemoteMediaEndpoint? _endpointFor(ConnectionPath? path) {
    final probe = path?.probeUri;
    final record = _record;
    if (probe == null || record == null) {
      return null;
    }
    if (record.deviceId.isEmpty || record.psk.isEmpty) {
      return null;
    }
    return RemoteMediaEndpoint(
      // `probeUri` carries the origin plus (for a wss path) a path prefix we
      // must not keep — the media routes are absolute on the server.
      httpBase: Uri(
        scheme: probe.scheme,
        host: probe.host,
        port: probe.hasPort ? probe.port : null,
      ),
      deviceId: record.deviceId,
      psk: record.psk,
    );
  }

  void _setMediaEndpoint(RemoteMediaEndpoint? next) {
    if (_disposed || _mediaEndpoint == next) {
      return;
    }
    _mediaEndpoint = next;
    if (!_mediaController.isClosed) {
      _mediaController.add(next);
    }
  }

  /// The server re-published its descriptor over a live path (rotated tunnel
  /// URL, moved LAN IP) — persist it so the next boot dials current addresses.
  void _persistDescriptor(ConnectionDescriptor descriptor) {
    final updated = _record?.copyWith(descriptor: descriptor);
    if (updated == null) {
      return;
    }
    _record = updated;
    rlog('pairing', 'descriptor refreshed: $descriptor');
    unawaited(_store.save(updated));
  }

  /// First verified connect pinned the server's identity (TOFU) — persist it
  /// so every later connect enforces the pin.
  void _persistPinnedFingerprint(String fingerprint) {
    final updated = _record?.copyWith(pinnedFingerprint: fingerprint);
    if (updated == null) {
      return;
    }
    _record = updated;
    rlog('pairing', 'server fingerprint pinned');
    unawaited(_store.save(updated));
  }

  /// Tears down the client + supervisor (the client owns the supervisor once
  /// built). [keepState] preserves a terminal UI state (identity mismatch).
  Future<void> _teardownConnection({bool keepState = false}) async {
    await _statusSub?.cancel();
    _statusSub = null;
    // The signed URLs were minted against a path that is going away (and, on
    // unpair, against a credential that is being destroyed). Drop them so no
    // surface keeps fetching from a dead origin.
    _setMediaEndpoint(null);
    final client = _client;
    final supervisor = _supervisor;
    _client = null;
    _supervisor = null;
    if (client != null) {
      // Closing the resilient client also closes its supervisor.
      await client.close();
    } else if (supervisor != null) {
      await supervisor.close();
    }
    // Callers set the follow-up state; nothing to do here even when
    // [keepState] is false.
  }

  /// Resolves the active workspace against the live list: keeps the persisted
  /// id when it still exists, otherwise falls back to the first workspace (and
  /// persists that). No-op when there are no workspaces yet.
  Future<void> _resolveActiveWorkspace(RemoteRpcClient client) async {
    try {
      final rows = await client.listWorkspaces();
      final ids = rows.map((w) => w['id']).whereType<String>().toSet();
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

  void _setState(RemoteUiState next) {
    if (_disposed || next == _state) {
      return;
    }
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

  String _friendlyReason(Object? error) {
    if (error is NotPairedException) {
      return 'Not paired — scan the QR code from your Mac';
    }
    if (error != null) {
      switch (classifyConnectionError(error)) {
        case ConnectionFailureKind.unreachable:
          return "Couldn't reach your server on any path — check it's "
              'running, or try the same network';
        case ConnectionFailureKind.identityMismatch:
          return "The server's identity changed — if it was reinstalled, "
              're-pair this device';
        case ConnectionFailureKind.authRejected:
          return 'The server rejected this device — re-pair it from your Mac';
        case ConnectionFailureKind.unknown:
          break;
      }
    }
    // In debug builds, surface the real error on the connect screen itself so
    // the cause is visible without opening DevTools. Stripped from release.
    if (kDebugMode && error != null) {
      return "Couldn't connect — tap to retry  [${error.runtimeType}: $error]";
    }
    return "Couldn't connect — tap to retry";
  }
}
