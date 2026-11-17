part of '../cc_server_runtime.dart';

/// Serializes every log write+flush through one chain. This matters twice:
///  * An [IOSink] throws "StreamSink is bound to a stream" if you `writeln`
///    while a previous `flush()` is still in flight, so overlapping the two
///    (e.g. two log lines back-to-back) crashes the process — the chain
///    guarantees the prior flush finishes before the next write starts.
///  * Flushing each line makes logs stream immediately even over a pipe (the
///    desktop spawns cc_server with piped, block-buffered stdio), instead of
///    batching into one late burst that reads as "the server hung on start".
Future<void> _logTail = Future<void>.value();

/// The rotating on-disk log, installed by [runCcServer] under `<dataDir>/logs`.
/// Null until the server boots (tests and the `pair`/`calendar` subcommands
/// leave it unset, so they log to stdio only).
/// How recently a conversation must have been touched for its worktree to keep
/// a live file watcher. Dormant ones are indexed on demand when they wake.
const Duration _watchActivityWindow = Duration(days: 7);

RotatingFileLogSink? _fileSink;

/// Where the boot in flight has spent its time, by announced phase.
final _BootTimeline _bootTimeline = _BootTimeline();

/// Attributes a boot's wall time, and the memory it took, to the phases
/// [_bootMark] announced.
///
/// The per-phase lines are info-level and the default level is warning, so a
/// slow boot used to leave nothing behind but the gap between the booting line
/// and the ready banner. This keeps the same numbers for one summary line that
/// always prints ([_announceBootSummary]).
///
/// Memory is the process's resident size at each phase's edges. Work started
/// in one phase and still running in the next (a load on another isolate) is
/// charged to whichever phase it lands in, so read the figures as "where to
/// look", not as an allocation profile.
class _BootTimeline {
  /// Creates a timeline that reads resident memory through [residentBytes].
  _BootTimeline({int Function()? residentBytes})
    : _residentBytes = residentBytes ?? (() => ProcessInfo.currentRss);

  final int Function() _residentBytes;
  final Stopwatch _clock = Stopwatch();
  final Map<String, int> _spentMs = {};
  final Map<String, int> _grewBytes = {};
  String? _open;
  int _openedAtMs = 0;
  int _openedAtBytes = 0;
  int _startedAtBytes = 0;

  /// What the process held when this boot began, in MiB: the runtime and the
  /// program itself, before the server has built anything.
  int get startedAtMb => _startedAtBytes ~/ (1024 * 1024);

  /// Starts a new boot: one process can boot more than one server (tests).
  void restart() {
    _spentMs.clear();
    _grewBytes.clear();
    _open = null;
    _startedAtBytes = _residentBytes();
    _clock
      ..reset()
      ..start();
  }

  /// Opens [label]; whatever was open ends here.
  void open(String label) {
    _end();
    _begin(label);
  }

  /// Ends the open phase. What runs until the next [open] is charged to
  /// `after <label>`: boot does real work between its announced phases (most
  /// of the object graph is built there), and leaving that out of the account
  /// hid more than half of what a boot allocates.
  void close() {
    final label = _end();
    if (label != null && !label.startsWith(_afterPrefix)) {
      _begin('$_afterPrefix$label');
    }
  }

  static const _afterPrefix = 'after ';

  void _begin(String label) {
    _open = label;
    _openedAtMs = _clock.elapsedMilliseconds;
    _openedAtBytes = _residentBytes();
  }

  String? _end() {
    final label = _open;
    if (label == null) {
      return null;
    }
    _open = null;
    _spentMs[label] =
        (_spentMs[label] ?? 0) + _clock.elapsedMilliseconds - _openedAtMs;
    _grewBytes[label] =
        (_grewBytes[label] ?? 0) + _residentBytes() - _openedAtBytes;
    return label;
  }

  /// `phase +38 MB, phase +21 MB`: the [top] phases that grew the process the
  /// most, each by at least [floorMb]. Empty when none did.
  String describeMemory({int top = 4, int floorMb = 5}) {
    _end();
    const mb = 1024 * 1024;
    final largest =
        _grewBytes.entries
            .where((phase) => phase.value >= floorMb * mb)
            .toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    return largest
        .take(top)
        .map((phase) => '${phase.key} +${phase.value ~/ mb} MB')
        .join(', ');
  }

  /// `412ms (phase 180ms, phase 98ms)`: the total and the [top] slowest
  /// phases that took at least [floorMs].
  String describe({int top = 4, int floorMs = 10}) {
    _end();
    final slowest =
        _spentMs.entries.where((phase) => phase.value >= floorMs).toList()
          ..sort((a, b) => b.value.compareTo(a.value));
    final total = '${_clock.elapsedMilliseconds}ms';
    if (slowest.isEmpty) {
      return total;
    }
    final phases = slowest
        .take(top)
        .map((phase) => '${phase.key} ${phase.value}ms')
        .join(', ');
    return '$total ($phases)';
  }
}

/// This process's resident memory in MiB, as the OS reports it.
int _residentMemoryMb() => ProcessInfo.currentRss ~/ (1024 * 1024);

/// Prints what the boot spent its time on and what the process holds, next to
/// the ready banner. Visible at the default log level: it is one line per
/// boot, and it is the line a "the server starts slowly" report needs.
void _announceBootSummary() {
  final grew = _bootTimeline.describeMemory();
  _announce(
    'cc_server: boot took ${_bootTimeline.describe()}, '
    '${_residentMemoryMb()} MB resident, up from '
    '${_bootTimeline.startedAtMb} MB when boot began'
    '${grew.isEmpty ? '' : ' ($grew)'}',
  );
}

void _configureBootLogging(CcServerConfig config) {
  _logLevel = config.logLevel;
  _bootTimeline.restart();

  // A rotating on-disk log under the data dir, so a long-lived headless server
  // keeps a bounded, persistent record (and a crash trail) beyond ephemeral
  // stdio (FINDINGS §130/§132). Every log seam below tees into it via _emitLog.
  _fileSink = RotatingFileLogSink(directory: '${config.dataDir}/logs');

  CcHostLog.sink = (level, message, [error, stackTrace]) {
    final severity = _hostSeverity(level);
    if (severity.index < config.logLevel.index) {
      return;
    }
    _emitLog(
      severity == CcServerLogLevel.error,
      '[${level.name}] $message',
      error,
    );
  };

  // The Drift-backed repositories log through their own seam; route it to the
  // same stdout/stderr so server persistence diagnostics are visible.
  CcPersistenceLog.sink = (level, message, [error, stackTrace]) {
    final severity = _persistenceSeverity(level);
    if (severity.index < config.logLevel.index) {
      return;
    }
    _emitLog(
      severity == CcServerLogLevel.error,
      '[${level.name}] $message',
      error,
    );
  };

  // Domain services (reconcilers, listeners, the pipeline engine) log through
  // the shared-kernel seam; route it to the same stdout/stderr.
  CcDomainLog.sink = (level, message, [error, stackTrace]) {
    final severity = _domainSeverity(level);
    if (severity.index < config.logLevel.index) {
      return;
    }
    _emitLog(
      severity == CcServerLogLevel.error,
      '[${level.name}] $message',
      error,
    );
  };

  // Route infrastructure diagnostics to stdio and the rotating log file.
  CcInfraLog.sink = (level, message, [error, stackTrace]) {
    final severity = _infraSeverity(level);
    if (severity.index < config.logLevel.index) {
      return;
    }
    _emitLog(
      severity == CcServerLogLevel.error,
      '[${level.name}] $message',
      error,
    );
  };

  // Configure infrastructure traces from --log-level / CC_SERVER_LOG_LEVEL.
  CcInfraLog.level = switch (config.logLevel) {
    CcServerLogLevel.debug => CcInfraLogLevel.debug,
    CcServerLogLevel.info => CcInfraLogLevel.info,
    CcServerLogLevel.warning => CcInfraLogLevel.warning,
    CcServerLogLevel.error => CcInfraLogLevel.error,
  };

  // First line the moment the sink is live, so the console shows the server is
  // alive immediately — the DB open + model/registry wiring below run silently
  // for a bit and (piped, block-buffered stdout aside) that used to read as a
  // hung start. Emitted directly, bypassing the level filter (and its `[level]`
  // prefix): the lifecycle lines always print, whatever `--log-level` says.
  _emitLog(false, 'cc_server: booting (data: ${config.dataDir})…');
}

/// Runs a boot phase, announcing it before and timing it after.
///
/// Boot is a long sequence of awaits with logging only at a few landmarks, so a
/// phase that got slow (the database open on a multi-GB file, a credential
/// probe blocked on a keyring) presented as a server hung after its last line
/// with no way to attribute the wait. Announcing BEFORE the await is the point:
/// the phase in flight is the one to blame.
///
/// Completion is ALWAYS logged, not just when slow. With a slow-only rule a fast
/// phase leaves its own start line as the last thing on screen, so the next
/// (unannounced) phase's stall gets blamed on it. The rule now is simple: a
/// `…` line with no matching `✓` is the phase still running.
Future<T> _bootStep<T>(String label, Future<T> Function() action) async {
  _bootMark(label);
  final startedAt = DateTime.now();
  final result = await action();
  _bootDone(label, startedAt);
  return result;
}

/// Announces a boot phase that is about to start. Use directly for a stretch of
/// SYNCHRONOUS construction, which [_bootStep] cannot wrap but which can still
/// take real time (dylib loads, catalog parsing, building the tool registry).
/// The phase runs until the next mark or its [_bootDone].
void _bootMark(String label) {
  _bootTimeline.open(label);
  CcHostLog.info('cc_server: $label…');
}

/// Starts a boot phase that reaches the NETWORK and returns without waiting
/// for it.
///
/// Boot must not depend on a remote host answering: the relay's signaling
/// broker and the mDNS/tunnel stack are both best-effort and both retry on
/// their own, so a slow or unreachable one should cost that feature, never the
/// server's startup. Waiting for them, even with a bound, still put a remote
/// round trip in front of the ready banner on every start: measured on an
/// otherwise idle data dir, the relay dial was 2.8s of a 3.0s first boot and
/// 0.4s of every 0.7s boot after it. The phase reports its own outcome
/// instead: how long it took (a warning past [slowAfter]) or why it failed,
/// with [meanwhile] saying what is missing until it lands.
void _bootStepInBackground(
  String label,
  Future<void> Function() action, {
  required String meanwhile,
  Duration slowAfter = const Duration(seconds: 10),
}) {
  CcHostLog.info('cc_server: $label (in the background)…');
  final clock = Stopwatch()..start();
  final Future<void> running;
  try {
    running = action();
  } on Object catch (e) {
    CcHostLog.warning('cc_server: $label failed: $e ($meanwhile)');
    return;
  }
  // The synchronous head of `action()` runs right here, on the boot path, and
  // freezes the event loop for as long as it takes. Timing it apart from the
  // awaited tail says which one is at fault.
  final syncMs = clock.elapsedMilliseconds;
  if (syncMs >= 1000) {
    CcHostLog.warning(
      'cc_server: $label blocked the isolate for ${syncMs}ms BEFORE yielding '
      '— synchronous work on the boot path, not a slow peer',
    );
  }
  unawaited(
    running.then(
      (_) {
        final line = 'cc_server: ✓ $label (${clock.elapsedMilliseconds}ms)';
        if (clock.elapsed >= slowAfter) {
          CcHostLog.warning('$line — until then: $meanwhile');
        } else {
          CcHostLog.info(line);
        }
      },
      onError: (Object e) {
        CcHostLog.warning('cc_server: $label failed: $e ($meanwhile)');
      },
    ),
  );
}

/// Closes a phase opened with [_bootMark]. Slow phases are called out at info
/// with their duration; quick ones only surface at the debug log level, so a
/// normal boot stays readable while still proving the phase finished.
void _bootDone(String label, DateTime startedAt) {
  _bootTimeline.close();
  final elapsedMs = DateTime.now().difference(startedAt).inMilliseconds;
  if (elapsedMs >= 1000) {
    CcHostLog.info('cc_server: ✓ $label (${elapsedMs}ms)');
  } else if (CcInfraLog.isEnabled(CcInfraLogLevel.debug)) {
    CcHostLog.info('cc_server: ✓ $label (${elapsedMs}ms)');
  }
}

/// Maps each logging façade's severity onto the server's canonical
/// [CcServerLogLevel] so `--log-level` filters every seam uniformly. The
/// switches are exhaustive on purpose: a new façade tier fails to compile
/// here until it is classified.
CcServerLogLevel _hostSeverity(CcHostLogLevel level) => switch (level) {
  CcHostLogLevel.info => CcServerLogLevel.info,
  CcHostLogLevel.warning => CcServerLogLevel.warning,
  CcHostLogLevel.error => CcServerLogLevel.error,
};

CcServerLogLevel _persistenceSeverity(CcPersistenceLogLevel level) =>
    switch (level) {
      CcPersistenceLogLevel.info => CcServerLogLevel.info,
      CcPersistenceLogLevel.warning => CcServerLogLevel.warning,
      CcPersistenceLogLevel.error => CcServerLogLevel.error,
    };

CcServerLogLevel _domainSeverity(CcDomainLogLevel level) => switch (level) {
  CcDomainLogLevel.info => CcServerLogLevel.info,
  CcDomainLogLevel.warning => CcServerLogLevel.warning,
  CcDomainLogLevel.error => CcServerLogLevel.error,
};

CcServerLogLevel _infraSeverity(CcInfraLogLevel level) => switch (level) {
  CcInfraLogLevel.debug => CcServerLogLevel.debug,
  CcInfraLogLevel.info => CcServerLogLevel.info,
  CcInfraLogLevel.warning => CcServerLogLevel.warning,
  CcInfraLogLevel.error => CcServerLogLevel.error,
};

void _emitLog(bool isError, String line, [Object? error]) {
  // Wall-clock prefix on every line. Without it a boot log shows WHICH phase
  // was last but not how long the gap after it was, so "it hangs here" and "it
  // pauses here" are indistinguishable in a pasted log — which cost real time
  // chasing the wrong phase.
  final now = DateTime.now();
  String two(int v) => v.toString().padLeft(2, '0');
  final stamp =
      '${two(now.hour)}:${two(now.minute)}:${two(now.second)}'
      '.${now.millisecond.toString().padLeft(3, '0')}';
  // Every line is redacted, whoever wrote it: a token interpolated into a
  // message or carried by an exception's text never reaches stdio or disk.
  line = '$stamp ${redactSecrets(line)}';
  final detail = error == null ? null : redactSecrets('$error');
  // Persist to the rotating file first — synchronous + flushed — so a line
  // (including a crash record) survives even if the process dies immediately
  // after. Bounded on disk by the sink's size cap + retention (FINDINGS §132).
  _fileSink?.write(detail != null ? '$line\n  $detail' : line);
  _logTail = _logTail.then((_) async {
    try {
      if (isError) {
        stderr.writeln(line);
        if (detail != null) {
          stderr.writeln('  $detail');
        }
        await stderr.flush();
      } else {
        stdout.writeln(line);
        await stdout.flush();
      }
    } catch (_) {
      // Broken pipe / closed stdio — drop the line rather than crash boot.
    }
  });
}

/// The resolved `--log-level`, mirrored at file scope so [_announce] can honour
/// it without threading the config through every warm-up closure.
CcServerLogLevel _logLevel = CcServerLogLevel.warning;

/// Emits a headline lifecycle line that is visible at the DEFAULT log level.
///
/// `--log-level` defaults to `warning`, so every [CcHostLog.info] line — the
/// whole `_bootMark`/`_bootDone` narration included — is dropped unless the
/// operator opts into `info`. That is the right default for per-phase chatter,
/// but it also silenced the one thing a FIRST boot most needs to explain: the
/// several minutes it spends fetching multi-hundred-megabyte on-device models
/// over the network. With nothing on the log for that stretch, a slow link and
/// a hung server are indistinguishable.
///
/// So a handful of rare, high-value events use this lane instead. It is not a
/// bypass: `--log-level error` still silences it, and callers must only use it
/// for events that fire when real work happens (a model already on disk logs
/// nothing), never per-request or per-phase.
void _announce(String line) {
  if (_logLevel.index > CcServerLogLevel.warning.index) {
    return;
  }
  _emitLog(false, line);
}

/// Routes one on-device model's install lifecycle to the right log lane:
/// [ModelLogLevel.notice] onto [_announce] (visible on a default-verbosity
/// first boot, which is the whole point — see [_announce]), failures onto the
/// normal warning seam. [what] names the model family, e.g. `'embedding model'`.
void _modelLog(ModelLogLevel level, String what, String message) =>
    switch (level) {
      ModelLogLevel.notice => _announce('cc_server: $what: $message'),
      ModelLogLevel.warning => CcHostLog.warning('cc_server: $what: $message'),
    };

/// Records an uncaught top-level server error to stderr **and** the rotating
/// on-disk log, so a crash in an async reconciler/timer that would otherwise
/// vanish leaves a persistent trail (FINDINGS §130). Safe to call before the
/// file sink is installed (it degrades to stderr only). Wire it as the handler
/// of a `runZonedGuarded` around the server run.
void recordUncaughtServerError(Object error, StackTrace stack) {
  _emitLog(true, 'cc_server: uncaught error: $error', stack);
}
