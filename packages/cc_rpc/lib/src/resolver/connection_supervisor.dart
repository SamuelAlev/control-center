import 'dart:async';
import 'dart:math';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/src/channel/remote_rpc_channel_port.dart';
import 'package:cc_rpc/src/client/remote_rpc_client.dart';
import 'package:cc_rpc/src/crypto/server_identity.dart';
import 'package:cc_rpc/src/resolver/reachability_resolver.dart';

/// Lifecycle phase of a supervised server connection.
enum ServerConnectionPhase {
  /// First connect in progress.
  connecting,

  /// A path is live and healthy.
  connected,

  /// The live path died; re-resolving (reconnect-and-resume).
  reconnecting,

  /// The server presented a different identity than the pinned fingerprint —
  /// terminal until the user re-pairs (TOFU is not a dialog).
  identityMismatch,

  /// [ServerConnectionSupervisor.close] was called.
  closed,
}

/// A snapshot of the supervised connection for status UI (the connection
/// pill: path + latency + relayed/insecure flags).
class ServerConnectionStatus {
  /// Creates a [ServerConnectionStatus].
  const ServerConnectionStatus({
    required this.phase,
    this.path,
    this.latency,
    this.attempt = 0,
    this.insecure = false,
    this.error,
  });

  /// Current phase.
  final ServerConnectionPhase phase;

  /// The live path when [phase] is [ServerConnectionPhase.connected].
  final ConnectionPath? path;

  /// Last measured round-trip latency on the live path.
  final Duration? latency;

  /// Reconnect attempt counter (0 while healthy).
  final int attempt;

  /// Whether the descriptor allows plaintext off-loopback (`--insecure`) —
  /// surfaced loudly by every client UI.
  final bool insecure;

  /// Last failure detail (diagnostics; no secrets).
  final String? error;

  /// Whether the live path relays through a broker.
  bool get relayed => path != null && !path!.isDirect;
}

/// Owns one server connection for the life of the app: resolve → connect →
/// monitor health → fail over (PRD 15 §1/§8).
///
/// Semantics per the PRD clarifications:
///  * **Hysteresis** — the live path is held until it fails health checks
///    ([maxMissedPings] consecutive misses) or the channel closes; a "better"
///    path appearing mid-session never causes a switch. Upgrades happen on
///    the next natural reconnect because every reconnect is a fresh full
///    resolve.
///  * **Reconnect-and-resume** — a path switch tears the RPC session down and
///    emits a fresh [RemoteRpcClient] on [clients]; subscriptions re-register
///    (`ResilientRpcClient` does this transparently).
///  * **Descriptor refresh** — after each connect the server's current
///    descriptor is fetched (`connection.describe`) and persisted via the
///    `onDescriptorUpdated` callback, so rotated tunnel URLs propagate.
///  * **TOFU** — the first verified fingerprint is pinned via the
///    `onFingerprintPinned` callback; any later mismatch is terminal
///    ([ServerConnectionPhase.identityMismatch]), never a retry loop.
class ServerConnectionSupervisor {
  /// Creates a supervisor. Call [start] to connect.
  ServerConnectionSupervisor({
    required ConnectionDescriptor descriptor,
    required this.deviceId,
    required String psk,
    String? pinnedFingerprint,
    ReachabilityResolver? resolver,
    this.pingInterval = const Duration(seconds: 10),
    this.maxMissedPings = 3,
    this.descriptorRefreshInterval = const Duration(minutes: 5),
    Future<void> Function()? beforeReconnect,
    void Function(ConnectionDescriptor descriptor)? onDescriptorUpdated,
    void Function(String fingerprint)? onFingerprintPinned,
  }) : _descriptor = descriptor,
       _psk = psk,
       _pin = pinnedFingerprint ?? '',
       _resolver = resolver ?? ReachabilityResolver(),
       _beforeReconnect = beforeReconnect,
       _onDescriptorUpdated = onDescriptorUpdated,
       _onFingerprintPinned = onFingerprintPinned;

  /// The paired device credential id.
  final String deviceId;

  /// Health-ping cadence on the live path.
  final Duration pingInterval;

  /// Consecutive missed pings that declare the path dead.
  final int maxMissedPings;

  /// How often the server's descriptor is re-fetched while connected.
  final Duration descriptorRefreshInterval;

  final String _psk;
  final ReachabilityResolver _resolver;
  final Future<void> Function()? _beforeReconnect;
  final void Function(ConnectionDescriptor descriptor)? _onDescriptorUpdated;
  final void Function(String fingerprint)? _onFingerprintPinned;

  ConnectionDescriptor _descriptor;
  String _pin;
  RemoteRpcClient? _client;
  ResolvedConnection? _connection;
  bool _closed = false;
  bool _reconnecting = false;
  int _missedPings = 0;
  Timer? _pingTimer;
  Timer? _describeTimer;
  StreamSubscription<Object?>? _stateSub;

  final StreamController<ServerConnectionStatus> _status =
      StreamController<ServerConnectionStatus>.broadcast();
  final StreamController<RemoteRpcClient> _clients =
      StreamController<RemoteRpcClient>.broadcast();

  ServerConnectionStatus _current = const ServerConnectionStatus(
    phase: ServerConnectionPhase.connecting,
  );

  /// Status snapshots; a new listener receives changes from now on — read
  /// [current] for the initial value.
  Stream<ServerConnectionStatus> get status => _status.stream;

  /// The latest status snapshot.
  ServerConnectionStatus get current => _current;

  /// A fresh authenticated client per (re)connect.
  Stream<RemoteRpcClient> get clients => _clients.stream;

  /// The live client, when connected.
  RemoteRpcClient? get client => _client;

  /// The current (possibly server-refreshed) descriptor.
  ConnectionDescriptor get descriptor => _descriptor;

  /// Replaces the descriptor from a trusted local source (e.g. the desktop
  /// re-spawned its loopback server on a new ephemeral port inside
  /// `beforeReconnect`). Refuses a foreign server id.
  void adoptDescriptor(ConnectionDescriptor updated) {
    if (updated.serverId != _descriptor.serverId) {
      return;
    }
    _descriptor = updated;
  }

  /// The pinned server fingerprint ('' until first verified connect).
  String get pinnedFingerprint => _pin;

  /// Connects for the first time. Throws on failure so boot flows can show a
  /// setup screen; once this has succeeded, later drops auto-reconnect
  /// forever (until [close] or an identity mismatch).
  Future<RemoteRpcClient> start() async {
    _emit(
      const ServerConnectionStatus(phase: ServerConnectionPhase.connecting),
    );
    final connection = await _connectOnce();
    _adopt(connection);
    return connection.client;
  }

  Future<ResolvedConnection> _connectOnce() async {
    final connection = await _resolver.connect(
      _descriptor,
      deviceId: deviceId,
      psk: _psk,
      pinnedFingerprint: _pin.isEmpty ? null : _pin,
    );
    if (_pin.isEmpty && connection.serverFingerprint.isNotEmpty) {
      _pin = connection.serverFingerprint;
      _onFingerprintPinned?.call(_pin);
    }
    return connection;
  }

  void _adopt(ResolvedConnection connection) {
    if (_closed) {
      unawaited(connection.client.close());
      return;
    }
    _connection = connection;
    _client = connection.client;
    _missedPings = 0;
    _stateSub = connection.client.connectionState.listen((state) {
      if (state == RemoteChannelState.closed) {
        _onPathDead('transport closed');
      }
    });
    _emit(
      ServerConnectionStatus(
        phase: ServerConnectionPhase.connected,
        path: connection.path,
        latency: connection.latency,
        insecure: _descriptor.insecureAllowed,
      ),
    );
    if (!_clients.isClosed) {
      _clients.add(connection.client);
    }
    _startHealthLoop();
    unawaited(_refreshDescriptor());
    _describeTimer = Timer.periodic(
      descriptorRefreshInterval,
      (_) => unawaited(_refreshDescriptor()),
    );
  }

  void _startHealthLoop() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(pingInterval, (_) => unawaited(_ping()));
  }

  bool _pingSupported = true;

  Future<void> _ping() async {
    final client = _client;
    if (client == null || _closed || _reconnecting || !_pingSupported) {
      return;
    }
    final started = DateTime.now();
    try {
      await client.call('connection.ping', const {});
      _missedPings = 0;
      _emit(
        ServerConnectionStatus(
          phase: ServerConnectionPhase.connected,
          path: _connection?.path,
          latency: DateTime.now().difference(started),
          insecure: _descriptor.insecureAllowed,
        ),
      );
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.opUnknown) {
        // Older server without the ping op: rely on transport-close detection.
        _pingSupported = false;
        return;
      }
      // The server answered — the path is alive even if the op errored.
      _missedPings = 0;
    } catch (_) {
      _missedPings++;
      if (_missedPings >= maxMissedPings) {
        _onPathDead('health checks failed ($_missedPings consecutive)');
      }
    }
  }

  Future<void> _refreshDescriptor() async {
    final client = _client;
    if (client == null || _closed) {
      return;
    }
    try {
      final data = await client.call('connection.describe', const {});
      final wire = data['descriptor'];
      if (wire is! Map) {
        return;
      }
      final updated = ConnectionDescriptor.fromJson(
        wire.cast<String, dynamic>(),
      );
      if (updated.serverId != _descriptor.serverId) {
        return; // Never adopt a foreign descriptor.
      }
      if (updated != _descriptor) {
        _descriptor = updated;
        _onDescriptorUpdated?.call(updated);
      }
    } catch (_) {
      // Older server or transient failure — the stored descriptor stands.
    }
  }

  void _onPathDead(String reason) {
    if (_closed || _reconnecting) {
      return;
    }
    _teardownLive();
    unawaited(_reconnectLoop(reason));
  }

  void _teardownLive() {
    _pingTimer?.cancel();
    _pingTimer = null;
    _describeTimer?.cancel();
    _describeTimer = null;
    unawaited(_stateSub?.cancel());
    _stateSub = null;
    final client = _client;
    _client = null;
    _connection = null;
    if (client != null) {
      unawaited(client.close());
    }
  }

  Future<void> _reconnectLoop(String reason) async {
    _reconnecting = true;
    var attempt = 0;
    final rnd = Random();
    while (!_closed) {
      attempt++;
      _emit(
        ServerConnectionStatus(
          phase: ServerConnectionPhase.reconnecting,
          attempt: attempt,
          insecure: _descriptor.insecureAllowed,
          error: reason,
        ),
      );
      try {
        await _beforeReconnect?.call();
        final connection = await _connectOnce();
        _reconnecting = false;
        _adopt(connection);
        return;
      } on ServerIdentityMismatchException catch (e) {
        _reconnecting = false;
        _emit(
          ServerConnectionStatus(
            phase: ServerConnectionPhase.identityMismatch,
            insecure: _descriptor.insecureAllowed,
            error: e.toString(),
          ),
        );
        return;
      } catch (e) {
        reason = e.toString();
      }
      // Exponential backoff capped at 30s, with jitter.
      final base = (1000 * (1 << (attempt - 1).clamp(0, 5))).clamp(1000, 30000);
      await Future<void>.delayed(
        Duration(milliseconds: base + rnd.nextInt(base ~/ 3 + 1)),
      );
    }
    _reconnecting = false;
  }

  void _emit(ServerConnectionStatus status) {
    _current = status;
    if (!_status.isClosed) {
      _status.add(status);
    }
  }

  /// Tears the connection down permanently.
  Future<void> close() async {
    if (_closed) {
      return;
    }
    _closed = true;
    _teardownLive();
    _emit(const ServerConnectionStatus(phase: ServerConnectionPhase.closed));
    await _status.close();
    await _clients.close();
  }
}
