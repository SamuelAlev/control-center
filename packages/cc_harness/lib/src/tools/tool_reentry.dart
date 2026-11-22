import 'package:cc_harness/src/cancellation_token.dart';
import 'package:cc_harness/src/tools/tool.dart';

/// How a call made through a [ToolReentry] ended.
enum ToolReentryStatus {
  /// The tool ran and returned a successful result.
  completed,

  /// The tool ran and returned an error result, or threw.
  failed,

  /// The gate refused the call: a pre-tool hook, the approval decision, or a
  /// missing approver. The tool never ran.
  denied,

  /// The call was cancelled: by the caller, by the run, or because the tool
  /// that made it settled first.
  cancelled,

  /// The call ran past its deadline and the loop stopped waiting for it.
  timedOut,

  /// The name is not on the run's admitted surface, or names a tool a script
  /// may not call.
  unknownTool,

  /// The arguments were not a JSON object.
  invalidArgs,
}

/// What the gate decided about one call.
enum ToolGateVerdict {
  /// Allowed without asking anyone: the tool needs no approval, policy
  /// allowed it, or the run approves automatically.
  allowed,

  /// A person was asked and approved it.
  approved,

  /// Refused, by a hook, by policy or by a person.
  denied,
}

/// The gate decision recorded for one call, with the reason a denial gave.
class ToolGateRecord {
  /// Creates a record.
  const ToolGateRecord(this.verdict, {this.reason});

  /// What the gate decided.
  final ToolGateVerdict verdict;

  /// Why the call was denied, as the model would read it; null otherwise.
  final String? reason;

  @override
  bool operator ==(Object other) =>
      other is ToolGateRecord &&
      other.verdict == verdict &&
      other.reason == reason;

  @override
  int get hashCode => Object.hash(verdict, reason);

  @override
  String toString() =>
      reason == null ? verdict.name : '${verdict.name}: $reason';
}

/// The settled state of one call made through a [ToolReentry].
class ToolReentryOutcome {
  /// Creates an outcome.
  const ToolReentryOutcome({
    required this.toolName,
    required this.toolCallId,
    required this.parentToolUseId,
    required this.result,
    required this.status,
    required this.duration,
    this.gate,
    this.personWait = Duration.zero,
    this.stillRunning,
  });

  /// The name the call asked for.
  final String toolName;

  /// The nested call's own id, `<parentToolUseId>/<n>` with n counting from
  /// one in call order. Its transcript events carry the same id.
  final String toolCallId;

  /// The id of the model-issued call that made this one.
  final String parentToolUseId;

  /// The tool's result. For a call that never ran it is an error result whose
  /// text says why, worded as the model would read it for a direct call.
  final HarnessToolResult result;

  /// How the call ended.
  final ToolReentryStatus status;

  /// The gate's decision, or null when the call ended before the gate
  /// decided (an unknown tool, invalid arguments, a cancelled queued call).
  final ToolGateRecord? gate;

  /// Wall-clock time from the call to its settlement, waits included.
  final Duration duration;

  /// The part of [duration] spent waiting on a person: the approval decision,
  /// and the whole execution of a tool that [HarnessTool.waitsOnPerson].
  final Duration personWait;

  /// The tool's own execution, when the gate gave up on the call (its
  /// deadline passed, or its caller stopped waiting) after the tool had
  /// started and before it returned; null otherwise. The gate settles such a
  /// call at once and never waits for it; this future is how the caller
  /// learns how the tool ended afterwards. Its cancellation token was
  /// cancelled: a tool that watches it stops (a `bash` command's process is
  /// killed), one that does not runs on.
  final Future<HarnessToolResult>? stillRunning;
}

/// Told when a nested call starts (`true`) and stops (`false`) waiting on a
/// person, so a caller can stop its own clock for exactly that time.
typedef PersonWaitListener = void Function(bool waiting);

/// The way back into the loop's gate for a tool that calls other tools.
///
/// The loop hands one to every call the model makes, through
/// [HarnessToolContext.reentry]. A nested call passes exactly the gate a
/// direct call passes, in the same order: the mode's tool surface, argument
/// validation, the pre-tool hook, the approval decision, execution under a
/// deadline and the run's cancellation, the post-tool hook and the completion
/// contract. There is no second policy path.
///
/// A nested call's own context has no reentry, so the tree is two levels deep.
abstract interface class ToolReentry {
  /// The tools a nested call may reach, by name: the run's admitted surface
  /// (resident, deferred and script-only tools) minus the loop-handled tools
  /// and every tool a script may not call ([HarnessTool.scriptCallable]).
  /// Never the raw registry.
  Map<String, HarnessTool> get callable;

  /// Calls [name] with [args] through the gate and settles with its outcome.
  ///
  /// Never throws. [args] must be a JSON object; anything else settles as
  /// [ToolReentryStatus.invalidArgs]. The call's deadline is the smaller of
  /// [timeout] and the loop's tool timeout, except for a tool that waits on a
  /// person, which keeps the loop's tool timeout only: its wait is not the
  /// caller's time. [cancel] cancels this call; so does the run, and the
  /// settling of the tool that made it. [onPersonWait] is told when the call
  /// starts and stops waiting on a person. [onToolStarted] is told once, with
  /// the gate's verdict, when the gate lets the call through and the tool
  /// itself starts: past it, the call can no longer be withdrawn.
  ///
  /// [site] is where in the caller's script the call was made (1-based line
  /// and column), when the caller runs one: a display hint carried to the
  /// call's `LoopToolCallStart` and nowhere else. The gate never reads it.
  /// Optional because most callers (and every test that drives the gate) run
  /// no script.
  Future<ToolReentryOutcome> call(
    String name,
    Object? args, {
    CancellationToken? cancel,
    Duration? timeout,
    PersonWaitListener? onPersonWait,
    void Function(ToolGateVerdict verdict)? onToolStarted,
    ({int line, int column})? site,
  });
}
