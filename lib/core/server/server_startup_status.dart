import 'package:flutter/foundation.dart';

/// Desktop server startup and reconnect phases shared by pre-app and app UI.
enum ServerStartupPhase {
  /// Locating and launching the local server process.
  starting,

  /// Establishing the authenticated connection.
  connecting,

  /// The server connection is ready for use.
  ready,

  /// Startup or reconnection failed; retain the original cause.
  failed,
}

/// A single startup attempt's phase and, when failed, its original cause.
class ServerStartupStatus {
  /// Creates a status update for the current server connection attempt.
  const ServerStartupStatus({required this.phase, this.error});

  /// Current phase of the local server or remote connection.
  final ServerStartupPhase phase;

  /// Original error when [phase] is [ServerStartupPhase.failed].
  final Object? error;
}

/// Null until startup begins; ready status hides the startup indicator.
///
/// Read by the activity panel. Production code writes it only through
/// [startupReporter]; tests may seed it directly to stand in for "some other
/// attempt wrote last".
final ValueNotifier<ServerStartupStatus?> serverStartupStatus =
    ValueNotifier<ServerStartupStatus?>(null);

/// The one writer of [serverStartupStatus].
///
/// A connection attempt is owned by whoever started it: the boot resolver, an
/// in-app switch or the setup screen. That owner wraps the attempt in [track],
/// which reports its first phase, `ready` once it resolves and `failed` with
/// the original error when it throws. Code running inside an attempt only
/// [advance]s its phase (the local spawn moves from starting to connecting), so
/// ready and failed are each written once, by the layer that knows the attempt
/// is over.
///
/// The local server's background reconnects are not attempts anyone awaits:
/// they report through a [StartupLease], which stops writing as soon as any
/// other report lands, so a health ping of a retired local child can never
/// replace a remote switch's progress or failure.
class StartupReporter {
  /// Creates a reporter writing to the given status notifier.
  StartupReporter(this._status);

  final ValueNotifier<ServerStartupStatus?> _status;

  /// The latest report, or null when no attempt is showing.
  ServerStartupStatus? get current => _status.value;

  /// Clears the indicator: a new attempt must not replay an old failure.
  void clear() => _status.value = null;

  /// Reports that the current attempt reached [phase].
  void advance(ServerStartupPhase phase) =>
      _status.value = ServerStartupStatus(phase: phase);

  /// Reports that the current attempt failed with [error].
  void fail(Object error) => _status.value = ServerStartupStatus(
    phase: ServerStartupPhase.failed,
    error: error,
  );

  /// Runs [attempt], reporting [initial] first, `ready` when it resolves and
  /// `failed` (rethrowing) when it throws.
  Future<T> track<T>(
    ServerStartupPhase initial,
    Future<T> Function() attempt,
  ) async {
    advance(initial);
    try {
      final result = await attempt();
      advance(ServerStartupPhase.ready);
      return result;
    } on Object catch (error) {
      fail(error);
      rethrow;
    }
  }

  /// Takes the indicator for a background attempt nobody awaits, starting at
  /// [phase]. See [StartupLease].
  StartupLease lease(ServerStartupPhase phase) {
    final lease = StartupLease._(this);
    lease.report(phase);
    return lease;
  }

  /// Whether a background attempt may take the indicator now: nothing is
  /// showing, the last attempt finished, or [lease] still holds it.
  bool isFree({StartupLease? lease}) {
    final value = _status.value;
    return value == null ||
        value.phase == ServerStartupPhase.ready ||
        (lease != null && lease.holds);
  }
}

/// A background attempt's hold on the startup indicator.
///
/// Holds it until any other report lands: every [report] first checks that the
/// indicator still shows the lease's own last write, and a lease that finds
/// something else there lets go for good. A `ready` report also releases it:
/// the attempt is over.
class StartupLease {
  StartupLease._(this._reporter);

  final StartupReporter _reporter;
  ServerStartupStatus? _last;
  bool _active = true;

  /// Whether the indicator still shows this lease's last report.
  bool get holds => _active && identical(_reporter.current, _last);

  /// Reports [phase] (with [error] for a failure) while this lease holds the
  /// indicator; a no-op once it has been released.
  void report(ServerStartupPhase phase, {Object? error}) {
    if (!_active) {
      return;
    }
    if (_last != null && !identical(_reporter.current, _last)) {
      _active = false;
      return;
    }
    final next = ServerStartupStatus(phase: phase, error: error);
    _reporter._status.value = next;
    _last = next;
    if (phase == ServerStartupPhase.ready) {
      _active = false;
    }
  }
}

/// The process-wide [StartupReporter] over [serverStartupStatus].
final StartupReporter startupReporter = StartupReporter(serverStartupStatus);
