import 'dart:async';
import 'dart:math';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/identity_events.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_persistence/database/daos/paired_device_dao.dart';
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_server_core/src/identity/server_identity_store.dart';
import 'package:cc_server_core/src/paired_device_secrets_port.dart';
import 'package:cc_server_core/src/relay/paired_peer_auth.dart';
import 'package:cc_server_core/src/relay/relay_remote_transport.dart';
import 'package:cc_server_core/src/remote_event_forwarder.dart';

void _i(String m) => CcHostLog.info('RemoteRelayHost: $m');
void _w(String m) => CcHostLog.warning('RemoteRelayHost: $m');

/// Joins the server's N-way relay room as its **owner** — an injectable seam
/// so tests can drive an in-process broker.
typedef RelayOwnerJoin =
    Future<RelaySignalingChannel> Function({
      required String room,
      required String ownerToken,
      required List<String> admit,
      String? peerId,
    });

/// Makes cc_server the owner of ONE signaling room that every relayed client
/// (desktop, web, phone — any platform) reaches it through when no direct
/// path exists (PRD 15 §2/§4).
///
/// The host:
///  * joins `identity.relayRoom` as the room owner (`ownerToken` proves
///    ownership to the broker across reconnects; a squatted room surfaces
///    loudly as `owner conflict`),
///  * publishes the **admission-hash set** derived from every active paired
///    device's PSK and live-updates it as devices are minted/revoked (the
///    broker evicts a revoked device's live connection immediately),
///  * accepts per-client sessions: a joining client sends a cleartext
///    `hello` naming its device id, the host builds a PSK-scoped
///    [RelayRemoteTransport] for that peer, runs the standard mutual PSK
///    handshake (+ identity signature) and serves its authenticated
///    [RemoteRpcSession] — identical semantics to the direct-WSS path.
///
/// The device id in a hello is routing information, not authentication: a
/// peer claiming a foreign device cannot open or seal frames under that
/// device's PSK, so its handshake fails closed.
class RemoteRelayHost {
  /// Creates a [RemoteRelayHost].
  RemoteRelayHost({
    required this.signalingUrl,
    required this.identity,
    required this.dispatcher,
    required this.devicesDao,
    required this.secrets,
    required this.eventBus,
    required this.workspaceResolver,
    this.repoOps,
    this.watchQueries,
    this.workspaceExists,
    this.resolveRole,
    RemoteRateLimiterPool? rateLimiters,
    RelayOwnerJoin? ownerJoin,
  }) : rateLimiters = rateLimiters ?? RemoteRateLimiterPool(),
       _ownerJoin =
           ownerJoin ??
           (({
             required String room,
             required String ownerToken,
             required List<String> admit,
             String? peerId,
           }) => RelaySignalingChannel.joinAsOwner(
             signalingUrl: signalingUrl,
             room: room,
             ownerToken: ownerToken,
             admit: admit,
             peerId: peerId,
           ));

  /// The broker this host dials as the room owner (`wss://…`).
  final String signalingUrl;

  /// The server identity (room id, owner token, Ed25519 signing key).
  final ServerIdentity identity;

  /// Shared RPC dispatcher.
  final RpcDispatcher dispatcher;

  /// Paired-device metadata DAO, from the server-global database: a device is
  /// paired with the server, not with one workspace and survives a workspace
  /// being deleted.
  final PairedDeviceDao devicesDao;

  /// Per-device PSK secure store.
  final PairedDeviceSecretsPort secrets;

  /// Domain event bus for push.
  final DomainEventBus eventBus;

  /// Resolves the workspaces a session may switch between.
  final RemoteWorkspaceResolver workspaceResolver;

  /// Registry existence gate forwarded to each session's
  /// [SubscriptionManager]: a workspace-scoped subscription naming an
  /// unregistered workspace is refused before its handler opens (and thereby
  /// CREATES) that workspace's database file.
  final WorkspaceExistsChecker? workspaceExists;

  /// Membership gate forwarded to each session (`tools/call` workspace_id
  /// check + subscription membership gate) and to the event forwarder
  /// (workspace-targeted events are dropped for non-members). Null (bare test
  /// hosts) skips the gates; production wiring always supplies it.
  final WorkspaceRoleResolver? resolveRole;

  /// Repo-RPC dispatcher exposed to relayed clients (`repo/call`).
  final RepoOpDispatcher? repoOps;

  /// Reactive watch-query registry (`sub/subscribe`).
  final WatchQueryRegistry? watchQueries;

  /// Per-user shared rate limiters (one budget across a user's sessions,
  /// shared with the direct-WSS path when the runtime passes one pool).
  final RemoteRateLimiterPool rateLimiters;

  final RelayOwnerJoin _ownerJoin;

  RelaySignalingChannel? _signaling;
  StreamSubscription<Map<String, dynamic>>? _signalSub;
  StreamSubscription<List<PairedDevicesTableData>>? _devicesSub;
  StreamSubscription<WorkspaceMemberRemoved>? _memberSub;

  /// deviceId → admission hash currently registered with the broker.
  final Map<String, String> _admitted = {};

  /// peerId → live or pending session.
  final Map<String, _PeerSession> _peers = {};

  bool _stopped = false;
  bool _connecting = false;
  int _backoffStep = 0;

  /// Whether the owner connection to the broker is currently up.
  bool get isConnected => _signaling?.isOpen ?? false;

  /// The number of live relayed client sessions.
  int get sessionCount => _peers.values.where((p) => p.session != null).length;

  int _finishedSessionChars = 0;

  /// Total sealed characters relayed through the broker this process
  /// lifetime (~bytes) — TURN-style relaying costs the operator real
  /// bandwidth, so it is surfaced, never silent (PRD 15 adversarial note).
  int get relayedChars {
    var live = 0;
    for (final p in _peers.values) {
      final t = p.transport;
      if (t != null) {
        live += t.sentChars + t.receivedChars;
      }
    }
    return _finishedSessionChars + live;
  }

  /// Connects to the broker and begins reconciling admissions against the
  /// paired-device table. Safe to call once; reconnects itself thereafter.
  Future<void> start() async {
    if (_stopped) {
      return;
    }
    _devicesSub = devicesDao.watchAll().listen(_reconcileDevices);
    // Live membership revocation: drop a removed member's attached workspace
    // subscriptions — they would otherwise keep streaming until disconnect.
    _memberSub = eventBus.on<WorkspaceMemberRemoved>().listen((e) {
      for (final peer in _peers.values.toList()) {
        final session = peer.session;
        if (session != null && session.rpc.userId == e.userId) {
          session.rpc.dropWorkspaceSubscriptions(e.workspaceId);
        }
      }
    });
    await _connect();
  }

  Future<void> _connect() async {
    if (_stopped || _connecting || _signaling != null) {
      return;
    }
    _connecting = true;
    try {
      final devices = await devicesDao.getAll();
      final admit = await _admissionHashes(devices);
      final signaling = await _ownerJoin(
        room: identity.relayRoom,
        ownerToken: identity.relayOwnerToken,
        admit: admit.values.toList(),
      );
      if (_stopped) {
        await signaling.close();
        return;
      }
      _admitted
        ..clear()
        ..addAll(admit);
      _signaling = signaling;
      _backoffStep = 0;
      _i(
        'owning relay room ${identity.relayRoom.substring(0, 6)}… '
        '(${admit.length} admitted devices)',
      );
      _signalSub = signaling.incoming.listen(
        _onBrokerFrame,
        onDone: _onSignalingClosed,
      );
    } on RelaySignalingException catch (e) {
      if (e.message.contains('owner conflict')) {
        // Someone squatted our room id. This is loud by design: relayed
        // clients cannot reach us until the broker GCs the squatter or the
        // operator rotates the room (which re-invites relay-only clients).
        _w(
          'RELAY ROOM SQUATTED: the broker refused our owner claim for room '
          '${identity.relayRoom.substring(0, 6)}… — relayed clients cannot '
          'connect. Retrying.',
        );
      } else {
        _w('relay join failed: $e');
      }
      _scheduleReconnect();
    } catch (e) {
      _w('relay join failed: $e');
      _scheduleReconnect();
    } finally {
      _connecting = false;
    }
  }

  /// Derives deviceId → sha256(admission token) for every relay-eligible
  /// device (active, PSK present — every platform; the relay is the fallback
  /// path for desktop, web and phone alike).
  Future<Map<String, String>> _admissionHashes(
    List<PairedDevicesTableData> devices,
  ) async {
    final result = <String, String>{};
    for (final d in devices) {
      if (d.status != PairedDeviceStatus.active) {
        continue;
      }
      final psk = await secrets.readPsk(d.id);
      if (psk == null) {
        continue;
      }
      final token = RemoteControlCrypto.relayAdmissionToken(
        psk: psk,
        room: identity.relayRoom,
      );
      result[d.id] = RemoteControlCrypto.relayAdmissionHash(token);
    }
    return result;
  }

  Future<void> _reconcileDevices(List<PairedDevicesTableData> devices) async {
    if (_stopped) {
      return;
    }
    final signaling = _signaling;
    if (signaling == null || !signaling.isOpen) {
      return; // The next connect publishes the full set.
    }
    final next = await _admissionHashes(devices);
    final add = <String>[
      for (final e in next.entries)
        if (_admitted[e.key] != e.value) e.value,
    ];
    final removedDevices = <String>[
      for (final id in _admitted.keys)
        if (!next.containsKey(id)) id,
    ];
    final remove = [for (final id in removedDevices) _admitted[id]!];
    if (add.isEmpty && remove.isEmpty) {
      return;
    }
    signaling.admit(add: add, remove: remove);
    _admitted
      ..clear()
      ..addAll(next);
    // Revocation also ends any live session for the revoked device (the
    // broker evicts its socket; this covers the session object).
    for (final deviceId in removedDevices) {
      for (final peer in _peers.values.toList()) {
        if (peer.deviceId == deviceId) {
          _i('dropping relayed session for revoked device $deviceId');
          await _endPeer(peer);
        }
      }
    }
  }

  void _onBrokerFrame(Map<String, dynamic> frame) {
    final type = frame['type'];
    if (type == 'signal') {
      final from = frame['from'] as String?;
      if (from == null) {
        return;
      }
      if (frame['kind'] == 'hello') {
        final payload = frame['payload'];
        final deviceId = payload is Map ? payload['d'] : null;
        if (deviceId is String && deviceId.isNotEmpty) {
          unawaited(_startPeer(from, deviceId));
        }
        return;
      }
      if (frame['kind'] == 'rpc') {
        // Frames racing ahead of the transport's construction are buffered
        // per peer and replayed once the PSK is resolved.
        final pending = _peers[from];
        if (pending != null && pending.session == null) {
          final payload = frame['payload'];
          if (payload is Map && pending.buffer.length < 64) {
            pending.buffer.add(payload.cast<String, dynamic>());
          }
        }
      }
      return;
    }
    if (type == 'peer-left') {
      final from = frame['from'] as String?;
      final peer = from == null ? null : _peers[from];
      if (peer != null) {
        unawaited(_endPeer(peer));
      }
    }
  }

  Future<void> _startPeer(String peerId, String deviceId) async {
    if (_stopped) {
      return;
    }
    // A re-hello from the same peer id replaces any prior session (client
    // retry after a half-open connection).
    final prior = _peers[peerId];
    if (prior != null) {
      await _endPeer(prior);
    }
    final pending = _PeerSession(peerId: peerId, deviceId: deviceId);
    _peers[peerId] = pending;

    final row = await devicesDao.getById(deviceId);
    final psk = await secrets.readPsk(deviceId);
    if (row == null || row.status != PairedDeviceStatus.active || psk == null) {
      _w('hello from $peerId for unknown/inactive device — ignoring');
      _peers.remove(peerId);
      return;
    }
    final signaling = _signaling;
    if (signaling == null || !identical(_peers[peerId], pending)) {
      return;
    }
    final transport = RelayRemoteTransport(
      signaling: signaling,
      peer: peerId,
      psk: psk,
      replay: List.of(pending.buffer),
    );
    pending.buffer.clear();
    pending.transport = transport;

    final auth = await authenticatePairedPeer(
      transport,
      devicesDao: devicesDao,
      secrets: secrets,
      identity: identity,
      warn: _w,
    );
    if (auth == null || auth.row.id != deviceId) {
      // Fail closed — the peer could not prove the PSK it claimed.
      await transport.close();
      if (identical(_peers[peerId], pending)) {
        _peers.remove(peerId);
      }
      return;
    }
    final userId = auth.row.userId;
    if (userId == null || userId.isEmpty) {
      _w('Rejecting relay session for ${auth.row.id} — no bound user');
      await transport.close();
      if (identical(_peers[peerId], pending)) {
        _peers.remove(peerId);
      }
      return;
    }
    final rpc = RemoteRpcSession(
      deviceId: auth.row.id,
      userId: userId,
      channel: transport,
      dispatcher: dispatcher,
      workspaceResolver: workspaceResolver,
      workspaceExists: workspaceExists,
      resolveRole: resolveRole,
      capability: SessionCapability.fromPlatform(auth.row.platform),
      repoOps: repoOps,
      watchQueries: watchQueries,
      rateLimiter: rateLimiters.forUser(userId),
    );
    final roleResolver = resolveRole;
    final forwarder = RemoteEventForwarder(
      eventBus: eventBus,
      channel: transport,
      deviceId: auth.row.id,
      userId: userId,
      isMember: roleResolver == null
          ? null
          : (workspaceId) async =>
                await roleResolver(workspaceId, userId) != null,
    );
    pending.session = _LiveSession(
      transport: transport,
      rpc: rpc,
      forwarder: forwarder,
    );
    await rpc.start();
    forwarder.start();
    await devicesDao.markSeen(auth.row.id, DateTime.now());
    try {
      await transport.send(const {'type': 'approved'});
    } catch (_) {
      // Best effort.
    }
    pending.session!.stateSub = transport.state.listen((s) {
      if (s == RemoteChannelState.closed) {
        unawaited(_endPeer(pending));
      }
    });
    _i('relay session up for device $deviceId (peer $peerId)');
  }

  Future<void> _endPeer(_PeerSession peer) async {
    if (identical(_peers[peer.peerId], peer)) {
      _peers.remove(peer.peerId);
    }
    final t = peer.transport;
    if (t != null) {
      _finishedSessionChars += t.sentChars + t.receivedChars;
    }
    await peer.dispose();
  }

  void _onSignalingClosed() {
    if (_stopped) {
      return;
    }
    _i('relay signaling dropped — reconnecting');
    unawaited(_teardownSignaling());
    _scheduleReconnect();
  }

  Future<void> _teardownSignaling() async {
    await _signalSub?.cancel();
    _signalSub = null;
    final peers = _peers.values.toList();
    _peers.clear();
    for (final p in peers) {
      final t = p.transport;
      if (t != null) {
        _finishedSessionChars += t.sentChars + t.receivedChars;
      }
      await p.dispose();
    }
    final s = _signaling;
    _signaling = null;
    _admitted.clear();
    await s?.close();
  }

  void _scheduleReconnect() {
    if (_stopped) {
      return;
    }
    final base = (1 << _backoffStep.clamp(0, 5)) * 500;
    _backoffStep++;
    final jitter = Random().nextInt(400);
    final delay = Duration(milliseconds: base.clamp(500, 30000) + jitter);
    Timer(delay, () {
      if (!_stopped) {
        unawaited(_connect());
      }
    });
  }

  /// Tears down every session and leaves the room. The host is unusable
  /// afterwards.
  Future<void> stop() async {
    _stopped = true;
    await _devicesSub?.cancel();
    _devicesSub = null;
    await _memberSub?.cancel();
    _memberSub = null;
    await _teardownSignaling();
  }
}

/// One relayed client connection: pending (hello received, PSK resolving)
/// or live (authenticated session running).
class _PeerSession {
  _PeerSession({required this.peerId, required this.deviceId});

  final String peerId;
  final String deviceId;

  /// Payloads that arrived before the transport existed.
  final List<Map<String, dynamic>> buffer = [];

  RelayRemoteTransport? transport;
  _LiveSession? session;
  bool _disposed = false;

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }
    _disposed = true;
    await session?.dispose();
    session = null;
    await transport?.close();
    transport = null;
  }
}

/// Bundles one live connection's artifacts for teardown.
class _LiveSession {
  _LiveSession({
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
