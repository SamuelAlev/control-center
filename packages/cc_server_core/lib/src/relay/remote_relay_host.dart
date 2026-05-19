import 'dart:async';
import 'dart:math';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:cc_server_core/src/relay/paired_peer_auth.dart';
import 'package:cc_server_core/src/relay/relay_remote_transport.dart';
import 'package:cc_server_core/src/relay/signaling_relay_client.dart';
import 'package:cc_server_core/src/remote_event_forwarder.dart';

void _i(String m) => CcHostLog.info('RemoteRelayHost: $m');
void _w(String m) => CcHostLog.warning('RemoteRelayHost: $m');

/// Lets [RemoteRelayHost] be unit-tested against an in-process broker by
/// injecting a client factory (default dials the real signaling URL).
typedef SignalingClientFactory = SignalingRelayClient Function(String url);

/// Makes cc_server the OWNER of each phone's connection even when the server is
/// not directly reachable: it dials the signaling broker as a peer, joins the
/// room named by the device id, and runs the phone's authenticated
/// `RemoteRpcSession` over an end-to-end-encrypted [RelayRemoteTransport].
///
/// The web/desktop app is pure passthrough — it only mints the pairing (which
/// calls [ensureDevice]) and shows the QR. The phone rendezvous in the broker
/// room; this host authenticates it (same PSK challenge as the direct WS path)
/// and serves its RPC. One [SignalingRelayClient] stays joined per active phone
/// device across reconnects, so a refreshed phone reclaims its room slot.
class RemoteRelayHost {
  /// Creates a [RemoteRelayHost].
  RemoteRelayHost({
    required this.signalingUrl,
    required this.dispatcher,
    required this.devicesDao,
    required this.secrets,
    required this.eventBus,
    required this.workspaceResolver,
    this.repoOps,
    this.watchQueries,
    SignalingClientFactory? signalingFactory,
    String Function()? peerIdFactory,
  })  : _signalingFactory = signalingFactory ?? SignalingRelayClient.new,
        _peerIdFactory = peerIdFactory ?? _randomPeerId;

  /// The broker this host dials as a peer (`wss://…`).
  final String signalingUrl;

  /// Shared RPC dispatcher.
  final RpcDispatcher dispatcher;

  /// Paired-device metadata DAO.
  final PairedDeviceDao devicesDao;

  /// Per-device PSK secure store.
  final PairedDeviceSecretsPort secrets;

  /// Domain event bus for push.
  final DomainEventBus eventBus;

  /// Resolves the workspaces a phone may switch between.
  final RemoteWorkspaceResolver workspaceResolver;

  /// Repo-RPC dispatcher exposed to the phone (`repo/call`).
  final RepoOpDispatcher? repoOps;

  /// Reactive watch-query registry (`sub/subscribe`).
  final WatchQueryRegistry? watchQueries;

  final SignalingClientFactory _signalingFactory;
  final String Function() _peerIdFactory;

  final Map<String, _DeviceRelay> _relays = {};
  StreamSubscription<List<PairedDevicesTableData>>? _devicesSub;
  bool _stopped = false;

  /// Whether a phone device's platform string maps to a relay-eligible phone.
  static bool isPhonePlatform(String? platform) =>
      platform == 'ios' || platform == 'android';

  /// Begins reconciling broker rooms against the paired-device table: joins a
  /// room for every `active` phone (at startup and the moment one is minted),
  /// and drops the relay when a phone is revoked. Watching the DAO is what lets
  /// `pairing.mint` "just work" without the catalog calling back into the host.
  Future<void> start() async {
    if (_stopped) {
      return;
    }
    _devicesSub = devicesDao.watchAll().listen(_reconcile);
  }

  void _reconcile(List<PairedDevicesTableData> devices) {
    if (_stopped) {
      return;
    }
    final activePhones = {
      for (final d in devices)
        if (d.status == PairedDeviceStatus.active && isPhonePlatform(d.platform))
          d.id,
    };
    for (final id in activePhones) {
      if (!_relays.containsKey(id)) {
        unawaited(ensureDevice(id));
      }
    }
    for (final id in _relays.keys.toList()) {
      if (!activePhones.contains(id)) {
        unawaited(removeDevice(id));
      }
    }
  }

  /// Begins relaying for [deviceId] — called by `pairing.mint` the moment a
  /// phone is paired, so the server is already waiting in the room when the
  /// phone scans the QR. Idempotent; a no-op if a relay is already running or
  /// the device is not an active phone / has no PSK.
  Future<void> ensureDevice(String deviceId) async {
    if (_stopped || _relays.containsKey(deviceId)) {
      return;
    }
    final row = await devicesDao.getById(deviceId);
    if (row == null ||
        row.status != PairedDeviceStatus.active ||
        !isPhonePlatform(row.platform)) {
      return;
    }
    final psk = await secrets.readPsk(deviceId);
    if (psk == null) {
      _w('no PSK for $deviceId — cannot relay');
      return;
    }
    final relay = _DeviceRelay(
      host: this,
      deviceId: deviceId,
      psk: psk,
      peerId: _peerIdFactory(),
    );
    _relays[deviceId] = relay;
    relay.connect();
  }

  /// Stops relaying for [deviceId] (e.g. on revoke).
  Future<void> removeDevice(String deviceId) async {
    final relay = _relays.remove(deviceId);
    await relay?.dispose();
  }

  /// Tears down every relay. The host is unusable afterwards.
  Future<void> stop() async {
    _stopped = true;
    await _devicesSub?.cancel();
    _devicesSub = null;
    final relays = _relays.values.toList();
    _relays.clear();
    for (final r in relays) {
      await r.dispose();
    }
  }

  static String _randomPeerId() {
    final rnd = Random.secure();
    final bytes = List<int>.generate(12, (_) => rnd.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}

/// One device's long-lived broker presence, plus the at-most-one phone session
/// currently running over it.
class _DeviceRelay {
  _DeviceRelay({
    required this.host,
    required this.deviceId,
    required this.psk,
    required this.peerId,
  });

  final RemoteRelayHost host;
  final String deviceId;
  final String psk;
  final String peerId;

  SignalingRelayClient? _signaling;
  StreamSubscription<Map<String, dynamic>>? _signalSub;
  _RelaySession? _session;
  bool _disposed = false;
  bool _connecting = false;
  int _backoffStep = 0;

  /// Connects to the broker and joins the room, retrying with backoff on drop.
  void connect() {
    if (_disposed || _connecting || _signaling != null) {
      return;
    }
    _connecting = true;
    unawaited(_connectImpl());
  }

  Future<void> _connectImpl() async {
    final client = host._signalingFactory(host.signalingUrl);
    try {
      await client.connect(room: deviceId, peerId: peerId);
    } catch (e) {
      _connecting = false;
      _w('relay join failed for $deviceId: $e');
      _scheduleReconnect();
      return;
    }
    if (_disposed) {
      await client.close(room: deviceId, peerId: peerId);
      return;
    }
    _signaling = client;
    _connecting = false;
    _backoffStep = 0;
    _i('relaying for $deviceId (joined room as $peerId)');
    _signalSub = client.incoming.listen(
      _onBrokerFrame,
      onDone: _onSignalingClosed,
    );
  }

  void _onBrokerFrame(Map<String, dynamic> frame) {
    final type = frame['type'];
    if (type == 'peer-joined') {
      // The phone is present — start a fresh authenticated session. Any prior
      // session for a superseded phone connection is torn down first.
      unawaited(_startSession());
    }
    // `peer-left` and relayed `signal`s are handled by the active transport.
  }

  Future<void> _startSession() async {
    final signaling = _signaling;
    if (_disposed || signaling == null) {
      return;
    }
    // Replace any prior session (e.g. a phone refresh re-joined the room).
    await _session?.dispose();
    _session = null;

    final transport = RelayRemoteTransport(
      signaling: signaling,
      room: deviceId,
      peerId: peerId,
      psk: psk,
    );
    final auth = await authenticatePairedPeer(
      transport,
      devicesDao: host.devicesDao,
      secrets: host.secrets,
      warn: _w,
    );
    if (auth == null) {
      // Fail closed: no sealed denial (the PSK may be gone) — just drop the
      // transport; the phone's auth await times out and it retries.
      await transport.close();
      return;
    }

    final rpc = RemoteRpcSession(
      deviceId: auth.row.id,
      channel: transport,
      dispatcher: host.dispatcher,
      workspaceResolver: host.workspaceResolver,
      capability: SessionCapability.fromPlatform(auth.row.platform),
      repoOps: host.repoOps,
      watchQueries: host.watchQueries,
    );
    final forwarder = RemoteEventForwarder(
      eventBus: host.eventBus,
      channel: transport,
      deviceId: auth.row.id,
    );
    final session = _RelaySession(transport: transport, rpc: rpc, forwarder: forwarder);
    _session = session;
    await rpc.start();
    forwarder.start();
    await host.devicesDao.markSeen(auth.row.id, DateTime.now());
    try {
      await transport.send(const {'type': 'approved'});
    } catch (_) {
      // Best effort.
    }
    session.stateSub = transport.state.listen((s) {
      if (s == RemoteChannelState.closed) {
        unawaited(_endSession(session));
      }
    });
    _i('relay session up for $deviceId');
  }

  Future<void> _endSession(_RelaySession session) async {
    if (identical(_session, session)) {
      _session = null;
    }
    await session.dispose();
    // The SignalingRelayClient stays joined so the phone can reconnect.
  }

  void _onSignalingClosed() {
    if (_disposed) {
      return;
    }
    _i('relay signaling dropped for $deviceId — reconnecting');
    unawaited(_teardownSignaling());
    _scheduleReconnect();
  }

  Future<void> _teardownSignaling() async {
    await _signalSub?.cancel();
    _signalSub = null;
    await _session?.dispose();
    _session = null;
    final s = _signaling;
    _signaling = null;
    await s?.close(room: deviceId, peerId: peerId);
  }

  void _scheduleReconnect() {
    if (_disposed) {
      return;
    }
    // Exponential backoff capped at 30s, with jitter.
    final base = (1 << _backoffStep.clamp(0, 5)) * 500;
    _backoffStep++;
    final jitter = Random().nextInt(400);
    final delay = Duration(milliseconds: base.clamp(500, 30000) + jitter);
    Timer(delay, () {
      if (!_disposed) {
        connect();
      }
    });
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await _teardownSignaling();
  }
}

/// Bundles one phone connection's session artifacts for teardown.
class _RelaySession {
  _RelaySession({
    required this.transport,
    required this.rpc,
    required this.forwarder,
  });

  final RelayRemoteTransport transport;
  final RemoteRpcSession rpc;
  final RemoteEventForwarder forwarder;
  StreamSubscription<RemoteChannelState>? stateSub;
  bool _disposed = false;

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await stateSub?.cancel();
    await forwarder.dispose();
    await rpc.stop();
    await transport.close();
  }
}
