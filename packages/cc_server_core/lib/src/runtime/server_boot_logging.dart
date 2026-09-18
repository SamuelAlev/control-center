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
void _bootMark(String label) => CcHostLog.info('cc_server: $label…');

/// Ceiling for a boot phase that reaches the NETWORK.
///
/// Boot must not depend on a remote host answering: the relay's signaling
/// broker and the mDNS/tunnel stack are both best-effort and both retry on
/// their own, so a slow or unreachable one should cost that feature, never the
/// server's startup. On timeout the phase is left running in the background and
/// boot proceeds.
Future<void> _bootStepBounded(
  String label,
  Future<void> Function() action, {
  required String onTimeout,
  Duration limit = const Duration(seconds: 10),
}) async {
  _bootMark(label);
  final startedAt = DateTime.now();
  try {
    // Split the synchronous head from the awaited tail. `.timeout()` cannot arm
    // its timer until `action()` returns a future, so work done synchronously
    // inside it is invisible to the bound AND freezes the event loop — which is
    // exactly how a "10s" timeout was observed firing 56s late. Timing the two
    // halves separately says which one is at fault instead of leaving it to
    // inference.
    final future = action();
    final syncMs = DateTime.now().difference(startedAt).inMilliseconds;
    if (syncMs >= 1000) {
      CcHostLog.warning(
        'cc_server: $label blocked the isolate for ${syncMs}ms BEFORE yielding '
        '— synchronous work on the boot path, not a slow peer',
      );
    }
    await future.timeout(limit);
    _bootDone(label, startedAt);
  } on TimeoutException {
    CcHostLog.warning(
      'cc_server: $label did not finish within ${limit.inSeconds}s — '
      'continuing boot ($onTimeout)',
    );
  } on Object catch (e) {
    CcHostLog.warning('cc_server: $label failed: $e ($onTimeout)');
  }
}

/// Closes a phase opened with [_bootMark]. Slow phases are called out at info
/// with their duration; quick ones only surface at the debug log level, so a
/// normal boot stays readable while still proving the phase finished.
void _bootDone(String label, DateTime startedAt) {
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
  line = '$stamp $line';
  // Persist to the rotating file first — synchronous + flushed — so a line
  // (including a crash record) survives even if the process dies immediately
  // after. Bounded on disk by the sink's size cap + retention (FINDINGS §132).
  _fileSink?.write(error != null ? '$line\n  $error' : line);
  _logTail = _logTail.then((_) async {
    try {
      if (isError) {
        stderr.writeln(line);
        if (error != null) {
          stderr.writeln('  $error');
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
