// The closed vocabularies a code execution is recorded in. Their wire names
// become database CHECK constraints and RPC values, so they never change; a new
// value is a schema step.

/// Where one `repl` call is: still running, or how it ended.
enum CodeExecutionStatus {
  /// Admitted and not finished yet. The record is written with this status
  /// when the host admits the script, so a script whose server dies still
  /// leaves a trace; it is finished exactly once, and a record still running
  /// when a server starts belonged to the previous process and is finished
  /// then. Never the status of a result the model reads.
  running('running'),

  /// The script returned or called `exit()`.
  completed('completed'),

  /// The script threw, or rejected, and nothing caught it.
  failed('failed'),

  /// The wall-clock deadline or the CPU budget ran out.
  timedOut('timed_out'),

  /// The run was stopped, or the caller cancelled the call.
  cancelled('cancelled'),

  /// The interpreter's heap limit was reached.
  memoryExceeded('memory_exceeded'),

  /// The script produced more output than the interpreter admits.
  outputExceeded('output_exceeded'),

  /// The runner misbehaved: it failed to start, reported less than full
  /// lockdown, broke the protocol, or died.
  sandboxError('sandbox_error'),

  /// The host refused the script before admitting it (source too large,
  /// code mode unavailable, another script of the run still running, no free
  /// runner slot before the deadline). A refused script did nothing, so it is
  /// a result the model and the transcript read but never a saved record.
  refused('refused');

  const CodeExecutionStatus(this.wire);

  /// The stable wire and storage name.
  final String wire;

  /// Every wire name, for a CHECK constraint.
  static List<String> get wireNames => [for (final s in values) s.wire];

  /// Whether the model reads this outcome as an error result.
  bool get isError => this != CodeExecutionStatus.completed;

  /// Whether this is how a script ended rather than [running].
  bool get isTerminal => this != CodeExecutionStatus.running;

  /// Parses [value], or returns null when it is not a known name.
  static CodeExecutionStatus? tryParse(String? value) {
    for (final s in values) {
      if (s.wire == value) {
        return s;
      }
    }
    return null;
  }

  /// Parses [value], throwing [ArgumentError] when it is not a known name.
  static CodeExecutionStatus parse(String value) =>
      tryParse(value) ??
      (throw ArgumentError.value(value, 'value', 'unknown execution status'));
}

/// How one nested tool call from a script ended.
enum NestedCallStatus {
  /// The tool ran and succeeded.
  completed('completed'),

  /// The tool ran and returned an error.
  failed('failed'),

  /// The gate refused it: a policy rule, a hook, a person, or no approver.
  denied('denied'),

  /// The script ended, or the run stopped, before the call settled.
  cancelled('cancelled'),

  /// The call's own deadline ran out.
  timedOut('timed_out'),

  /// The name is not in the run's callable set.
  unknownTool('unknown_tool'),

  /// The arguments were not a JSON object, or the tool rejected them before
  /// running.
  invalidArgs('invalid_args');

  const NestedCallStatus(this.wire);

  /// The stable wire and storage name.
  final String wire;

  /// Every wire name, for a CHECK constraint.
  static List<String> get wireNames => [for (final s in values) s.wire];

  /// Whether the script's promise resolves (true) or rejects (false).
  bool get resolves => this == NestedCallStatus.completed;

  /// The word the result text uses for this status in call lists and counts:
  /// `ok`, `failed`, `denied`, `cancelled` or `timed out`. Unknown tools and
  /// invalid arguments read as `failed`, which is what they are to the model.
  String get label => switch (this) {
    NestedCallStatus.completed => 'ok',
    NestedCallStatus.failed => 'failed',
    NestedCallStatus.denied => 'denied',
    NestedCallStatus.cancelled => 'cancelled',
    NestedCallStatus.timedOut => 'timed out',
    NestedCallStatus.unknownTool => 'failed',
    NestedCallStatus.invalidArgs => 'failed',
  };

  /// Parses [value], or returns null when it is not a known name.
  static NestedCallStatus? tryParse(String? value) {
    for (final s in values) {
      if (s.wire == value) {
        return s;
      }
    }
    return null;
  }

  /// Parses [value], throwing [ArgumentError] when it is not a known name.
  static NestedCallStatus parse(String value) =>
      tryParse(value) ??
      (throw ArgumentError.value(value, 'value', 'unknown call status'));
}

/// What the gate decided for a nested call that reached it.
///
/// Null on a call that never reached the gate (an unknown tool, arguments
/// that are not an object). The full decision, with the rule that matched, is
/// the `guard_decisions` row the gate writes; this is the summary the
/// execution's call row keeps.
enum NestedCallGateDecision {
  /// Ran without asking anyone.
  allowed('allowed'),

  /// Asked, and a person or a standing approval allowed it.
  approved('approved'),

  /// Refused by a policy rule, a hook, a person, or because nobody could be
  /// asked.
  denied('denied');

  const NestedCallGateDecision(this.wire);

  /// The stable wire and storage name.
  final String wire;

  /// Every wire name, for a CHECK constraint.
  static List<String> get wireNames => [for (final d in values) d.wire];

  /// Parses [value], or returns null when it is not a known name.
  static NestedCallGateDecision? tryParse(String? value) {
    for (final d in values) {
      if (d.wire == value) {
        return d;
      }
    }
    return null;
  }

  /// Parses [value], throwing [ArgumentError] when it is not a known name.
  static NestedCallGateDecision parse(String value) =>
      tryParse(value) ??
      (throw ArgumentError.value(value, 'value', 'unknown gate decision'));
}

/// Which surface ran a script.
enum CodeExecutionSurface {
  /// The built-in harness loop.
  harness('harness'),

  /// The MCP endpoint, for Claude Code, Codex and ACP runs.
  mcp('mcp');

  const CodeExecutionSurface(this.wire);

  /// The stable wire and storage name.
  final String wire;

  /// Every wire name, for a CHECK constraint.
  static List<String> get wireNames => [for (final s in values) s.wire];

  /// Parses [value], or returns null when it is not a known name.
  static CodeExecutionSurface? tryParse(String? value) {
    for (final s in values) {
      if (s.wire == value) {
        return s;
      }
    }
    return null;
  }

  /// Parses [value], throwing [ArgumentError] when it is not a known name.
  static CodeExecutionSurface parse(String value) =>
      tryParse(value) ??
      (throw ArgumentError.value(value, 'value', 'unknown surface'));
}

/// The fixed vocabulary of a code execution's `error_kind`: why a script
/// that did not complete ended, in words a filter, a counter and a client's
/// copy can rely on.
///
/// Every value is chosen by the host, never by the script or the runner: a
/// script's own error name (which the script picks, at any length) is kept
/// in the execution's payload, and the runner's report of how a script ended
/// only selects one of these. The database checks the column against
/// [values], so a kind outside it can never be stored.
// ignore: avoid_classes_with_only_static_members
abstract final class CodeExecutionErrorKind {
  /// The script threw, or rejected, and nothing caught it. Its error's name
  /// is in the payload.
  static const String scriptError = 'script_error';

  /// The script awaited a promise nothing could settle.
  static const String stalled = 'stalled';

  /// The interpreter's CPU budget ran out.
  static const String cpu = 'cpu';

  /// The interpreter's heap limit was reached.
  static const String heap = 'heap';

  /// The script wrote more output than the interpreter keeps.
  static const String output = 'output';

  /// The wall-clock deadline ran out.
  static const String deadline = 'deadline';

  /// The run, the caller or the person cancelled the script.
  static const String cancelled = 'cancelled';

  /// The server shut down while the script ran, or before it was admitted.
  static const String shutdown = 'shutdown';

  /// The server stopped (crashed, or was killed) while the script ran; the
  /// record was finished by the next start.
  static const String serverStopped = 'server_stopped';

  /// The runner reported an internal failure.
  static const String internal = 'internal';

  /// The runner could not be started, or was stopped before the script
  /// started.
  static const String start = 'start';

  /// The runner could not lock itself down fully.
  static const String lockdown = 'lockdown';

  /// The runner exited, or was killed by a signal, without finishing.
  static const String exited = 'exited';

  /// The runner broke the protocol: a malformed, unknown, misplaced or too
  /// deeply nested frame, or one it should have refused itself.
  static const String protocol = 'protocol';

  /// The runner wrote a frame over the frame cap.
  static const String frameTooLarge = 'frame_too_large';

  /// The runner sent more calls than it was allowed.
  static const String callCap = 'call_cap';

  /// The runner wrote more output than it was allowed.
  static const String outputOverrun = 'output_overrun';

  /// The runner sent more `store` frames, or more stored bytes, than a
  /// script may.
  static const String storeOverrun = 'store_overrun';

  /// The runner stopped reading what the host wrote to it.
  static const String stdinStalled = 'stdin_stalled';

  /// The runner neither finished nor died within its deadline and the grace
  /// periods after it, and the host gave up on it.
  static const String unresponsive = 'unresponsive';

  /// The host failed while running the script.
  static const String hostError = 'host_error';

  /// Refused: the `repl` call id was unusable.
  static const String invalidToolCallId = 'invalid_tool_call_id';

  /// Refused: no free execution id was found for the call.
  static const String executionId = 'execution_id';

  /// Refused: code mode is not available on this host.
  static const String unavailable = 'unavailable';

  /// Refused: the source is over the size limit.
  static const String sourceTooLarge = 'source_too_large';

  /// Refused: the run's tool catalog could not be built.
  static const String catalog = 'catalog';

  /// Refused: another script of the same run is still running.
  static const String runBusy = 'run_busy';

  /// Refused: no runner slot became free before the deadline.
  static const String serverBusy = 'server_busy';

  /// Refused: the run has no run log, so its scripts cannot be recorded, and
  /// a script that cannot be recorded does not run.
  static const String noRunLog = 'no_run_log';

  /// Refused: the record of the script could not be written, so it did not
  /// run.
  static const String auditUnavailable = 'audit_unavailable';

  /// Refused: the space the run belongs to was deleted, so a record of the
  /// script could not be kept with it, and the script did not run.
  static const String spaceGone = 'space_gone';

  /// Every kind, for a CHECK constraint and for validation.
  static const List<String> values = [
    scriptError,
    stalled,
    cpu,
    heap,
    output,
    deadline,
    cancelled,
    shutdown,
    serverStopped,
    internal,
    start,
    lockdown,
    exited,
    protocol,
    frameTooLarge,
    callCap,
    outputOverrun,
    storeOverrun,
    stdinStalled,
    unresponsive,
    hostError,
    invalidToolCallId,
    executionId,
    unavailable,
    sourceTooLarge,
    catalog,
    runBusy,
    serverBusy,
    noRunLog,
    auditUnavailable,
    spaceGone,
  ];

  /// Whether [kind] is in the vocabulary.
  static bool isKnown(String? kind) => kind != null && values.contains(kind);

  /// The kinds after which a run stops sending tools through scripts: the
  /// server could not run, start or record the script, so no other script
  /// would have fared better. After one, the run calls its script-only tools
  /// directly, through the same mode filter, gate and approval as any tool
  /// that loads on first use, for the rest of its life.
  ///
  /// The test is whether a different script could have changed the outcome.
  /// Not counted, because the script (or the model's call) decides them:
  /// [scriptError], [stalled], [cpu], [heap], [output], [deadline] and the
  /// limits a script asks for, [cancelled], [sourceTooLarge], [runBusy] (a
  /// script of the same run is still running), [invalidToolCallId] (one
  /// call's id), and every way the runner can end once the script runs
  /// ([internal], [exited], [protocol], [frameTooLarge], [callCap],
  /// [outputOverrun], [storeOverrun], [stdinStalled], [unresponsive],
  /// [hostError]): the runner is the script's own process, so a script can
  /// provoke each of them. [serverStopped] is only ever written by the boot
  /// sweep and never answers a call.
  static const Set<String> withdrawsScripts = {
    unavailable,
    serverBusy,
    auditUnavailable,
    shutdown,
    start,
    lockdown,
    executionId,
    noRunLog,
    spaceGone,
    catalog,
  };
}
