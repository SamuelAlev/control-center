import 'dart:async';
import 'dart:io';

import 'package:cc_domain/features/fleet/domain/value_objects/lease_protocol.dart';
import 'package:cc_domain/features/fleet/domain/value_objects/worker_capabilities.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_worker/src/capability_detector.dart';
import 'package:cc_worker/src/fleet_client.dart';
import 'package:cc_worker/src/job_executor.dart';
import 'package:cc_worker/src/worker_config.dart';
import 'package:path/path.dart' as p;

/// Drives one `cc_worker` session end to end: connect, register, heartbeat,
/// poll for leases and dispatch each to a [JobExecutor].
///
/// Holds no durable state. On a dropped connection, an incompatible protocol,
/// or [stop], it tears down; a process supervisor (systemd, launchd, the
/// operator) restarts it.
class WorkerRunner {
  /// Creates a [WorkerRunner] from [config].
  WorkerRunner(this.config);

  static const Duration _heartbeatInterval = Duration(seconds: 20);
  static const Duration _pollInterval = Duration(seconds: 2);

  /// The worker configuration.
  final WorkerConfig config;

  final Map<String, JobExecutor> _active = <String, JobExecutor>{};
  final Completer<int> _exit = Completer<int>();

  RemoteRpcClient? _rpc;
  FleetClient? _client;
  WorkerCapabilities? _caps;
  String? _workerId;
  Timer? _heartbeatTimer;
  Timer? _pollTimer;
  StreamSubscription<RemoteChannelState>? _stateSub;
  bool _stopping = false;
  int _consecutiveRpcFailures = 0;

  /// How many consecutive heartbeat/poll failures end the process. At the 20s
  /// heartbeat / 2s poll cadence this is a couple of minutes of a server that
  /// answers but refuses — long enough to ride out a restart, short enough to
  /// not sit dead for a shift.
  static const int _maxConsecutiveRpcFailures = 30;

  /// Runs the worker until the connection drops or [stop] is called, returning
  /// the process exit code. Throws with a clear message on an incompatible
  /// protocol version or a failed initial connection.
  Future<int> run() async {
    final caps = await detectCapabilities();
    _caps = caps;
    _log('detected capabilities: ${caps.toJsonString()}');
    await _connect();
    await _register();
    _heartbeatTimer =
        Timer.periodic(_heartbeatInterval, (_) => unawaited(_sendHeartbeat()));
    _pollTimer = Timer.periodic(_pollInterval, (_) => unawaited(_pollOnce()));
    _stateSub = _rpc!.connectionState.listen((state) {
      if (state == RemoteChannelState.closed) {
        _log('server connection closed');
        unawaited(stop());
      }
    });
    _log('worker ${_workerId ?? config.deviceId} online; polling for jobs');
    return _exit.future;
  }

  /// Tears everything down: stops the timers, cancels running jobs, closes the
  /// RPC client and completes [run]. Idempotent.
  Future<void> stop({int exitCode = 0}) async {
    if (_stopping) {
      return;
    }
    _stopping = true;
    _heartbeatTimer?.cancel();
    _pollTimer?.cancel();
    await _stateSub?.cancel();
    // Await each cancellation: `cancel()` now escalates to SIGKILL and waits
    // for the child to actually exit, so the worker cannot exit while still
    // holding a running subprocess against a lease the server thinks is dead.
    for (final executor in _active.values.toList()) {
      await executor.cancel();
    }
    await _rpc?.close();
    if (!_exit.isCompleted) {
      _exit.complete(exitCode);
    }
  }

  /// Opens the RPC channel — the PSK handshake when a key is supplied, else a
  /// plain channel for a loopback dev server.
  Future<void> _connect() async {
    final uri = _rpcUri(config.serverUrl);
    final insecure = uri.scheme == 'ws';
    final psk = config.psk;
    if (psk != null && psk.isNotEmpty) {
      _rpc = await connectRemoteRpc(
        uri: uri,
        deviceId: config.deviceId,
        psk: psk,
        insecureAllowed: insecure,
      );
    } else {
      final channel =
          await WsClientChannel.connect(uri, insecureAllowed: insecure);
      final client = RemoteRpcClient(channel)..start();
      await client.initialize();
      _rpc = client;
    }
    _client = FleetClient(_rpc!);
    _log('connected to $uri');
  }

  /// Registers the worker and aborts on a protocol mismatch.
  Future<void> _register() async {
    final caps = _caps!;
    final registration = WorkerRegistration(
      name: config.name,
      capsJson: caps.toJsonString(),
      protocolVersion: kFleetProtocolVersion,
      platform: caps.os,
    );
    final result = await _client!.registerWorker(
      registration: registration,
      workerId: config.deviceId,
    );
    if (!result.compatible) {
      throw StateError(
        'Incompatible fleet protocol: worker speaks v$kFleetProtocolVersion, '
        'server speaks v${result.serverProtocolVersion}. Upgrade cc_worker to '
        'match the server release (there is no compat window).',
      );
    }
    _workerId = result.workerId;
    _log('registered as worker ${result.workerId}');
  }

  Future<void> _sendHeartbeat() async {
    final id = _workerId;
    if (id == null || _stopping) {
      return;
    }
    try {
      await _client!.heartbeat(
        workerId: id,
        protocolVersion: kFleetProtocolVersion,
        capsJson: _caps!.toJsonString(),
      );
      _consecutiveRpcFailures = 0;
    } catch (e) {
      _logError('heartbeat failed: $e');
      _noteRpcFailure('heartbeat');
    }
  }

  /// Counts consecutive heartbeat/poll failures and tears the worker down past
  /// [_maxConsecutiveRpcFailures].
  ///
  /// A worker whose socket stays OPEN while the server rejects its calls used
  /// to spin forever, logging every 2s and doing nothing — invisible to the
  /// supervisor that could have restarted it, and still holding leases the
  /// server believes are being worked. Exiting non-zero hands the decision to
  /// systemd/launchd, which is the component that knows how to restart.
  void _noteRpcFailure(String what) {
    _consecutiveRpcFailures++;
    if (_consecutiveRpcFailures < _maxConsecutiveRpcFailures) {
      return;
    }
    _logError(
      '$what failed $_consecutiveRpcFailures times in a row — exiting for the '
      'supervisor to restart',
    );
    unawaited(stop(exitCode: 75)); // EX_TEMPFAIL
  }

  Future<void> _pollOnce() async {
    final id = _workerId;
    if (id == null || _stopping) {
      return;
    }
    try {
      final result = await _client!.poll(
        workerId: id,
        activeJobIds: _active.keys.toList(),
      );
      for (final offer in result.leases) {
        _startJob(offer);
      }
      _consecutiveRpcFailures = 0;
      for (final jobId in result.cancelledJobIds) {
        final executor = _active[jobId];
        if (executor != null) {
          _log('server cancelled job $jobId');
          await executor.cancel();
        }
      }
    } catch (e) {
      _logError('poll failed: $e');
      _noteRpcFailure('poll');
    }
  }

  void _startJob(LeaseOffer offer) {
    if (_active.containsKey(offer.jobId)) {
      return;
    }
    if (_active.length >= config.maxJobs) {
      // The server decides what to OFFER; only the worker knows what its host
      // can take. Without this every offer started immediately, so a
      // mis-pinned burst (or a scheduler bug) turned the worker into a fork
      // bomb. Declining leaves the lease to expire and be re-offered.
      _log(
        'declining job ${offer.jobId}: at capacity '
        '(${_active.length}/${config.maxJobs})',
      );
      return;
    }
    final executor = JobExecutor(
      lease: offer,
      client: _client!,
      cacheDir: _cacheDir(),
    );
    _active[offer.jobId] = executor;
    unawaited(executor.done.whenComplete(() {
      _active.remove(offer.jobId);
      _log('job ${offer.jobId} finished');
    }));
    executor.start();
    _log('started job ${offer.jobId} (kind=${offer.kind})');
  }

  /// Resolves (and creates) the materialization cache root. Honors
  /// `CC_WORKER_CACHE`, defaulting to a `cc_worker_cache` dir under the system
  /// temp dir.
  String _cacheDir() {
    final override = Platform.environment['CC_WORKER_CACHE'];
    final dir = override != null && override.isNotEmpty
        ? override
        : p.join(Directory.systemTemp.path, 'cc_worker_cache');
    Directory(dir).createSync(recursive: true);
    return dir;
  }

  /// Normalizes the operator-supplied server URL to a `ws`/`wss` `/rpc` URI.
  Uri _rpcUri(String raw) {
    var uri = Uri.parse(raw);
    final scheme = switch (uri.scheme) {
      'http' => 'ws',
      'https' => 'wss',
      'wss' => 'wss',
      _ => 'ws',
    };
    if (uri.scheme != scheme) {
      uri = uri.replace(scheme: scheme);
    }
    if (uri.path.isEmpty || uri.path == '/') {
      uri = uri.replace(path: '/rpc');
    }
    return uri;
  }

  void _log(String message) {
    stdout.writeln('[cc_worker] $message');
  }

  void _logError(String message) {
    stderr.writeln('[cc_worker] $message');
  }
}
