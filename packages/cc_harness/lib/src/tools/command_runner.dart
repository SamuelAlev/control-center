import 'package:cc_harness/src/cancellation_token.dart';
import 'package:cc_harness/src/tools/tool_reentry.dart';

/// Outcome of running a shell command through the harness command runner.
class HarnessCommandResult {
  /// Creates a command result.
  const HarnessCommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
    this.denied = false,
    this.denyReason,
    this.timedOut = false,
    this.personVerdict,
  });

  /// A policy / confirmation denial (the command never ran).
  factory HarnessCommandResult.deny(
    String reason, {
    ToolGateVerdict? personVerdict,
  }) => HarnessCommandResult(
    exitCode: 126,
    stdout: '',
    stderr: reason,
    denied: true,
    denyReason: reason,
    personVerdict: personVerdict,
  );

  /// Process exit code (126 when denied, 124 on timeout).
  final int exitCode;

  /// Captured standard output.
  final String stdout;

  /// Captured standard error.
  final String stderr;

  /// Whether the command was blocked by policy or the user.
  final bool denied;

  /// Why the command was denied, when [denied].
  final String? denyReason;

  /// Whether the command was killed by the timeout.
  final bool timedOut;

  /// What a person decided about the cards raised for this command, when
  /// one was: [ToolGateVerdict.approved] when every one was approved,
  /// [ToolGateVerdict.denied] when one was declined. A card the runner
  /// raised before running the command and a person declined also makes it
  /// [denied]; one the run's gateway raised for a request the command made
  /// while it ran (a push, a commit signature, an environment command)
  /// leaves it run, but declined. Null when nobody was asked.
  final ToolGateVerdict? personVerdict;

  /// Whether the command completed successfully.
  bool get ok => !denied && !timedOut && exitCode == 0;
}

/// Hears a command while it runs: when it was spawned and each piece of its
/// output as it arrives (standard output and standard error interleaved).
///
/// A foreground `bash` call needs neither, since it reads the result. A
/// background command returns to the model as soon as it is spawned and is
/// read while it runs, so it starts with an observer.
class HarnessCommandObserver {
  /// Creates an observer.
  const HarnessCommandObserver({
    this.onStarted,
    this.onOutput,
    this.sweepAfterExit = false,
  });

  /// Called once, right after the process was spawned (after every policy
  /// check and approval). Never called for a command that was refused or
  /// could not be spawned.
  final void Function()? onStarted;

  /// Called with each decoded chunk of output, in arrival order.
  final void Function(String chunk)? onOutput;

  /// Whether a cancel that arrives after the command exited still ends what
  /// the command left running (a daemon it started). A background command's
  /// cancel after its exit means its run ended; a foreground command's means
  /// nothing, so a dev server it left up stays up.
  final bool sweepAfterExit;
}

/// Runs shell commands for the harness `bash` tool, applying Control Center's
/// command policy, confirmation (UAC) and OS sandbox.
///
/// The infrastructure implementation reuses the same policy + sandbox stack the
/// external-CLI transports use, so a command the built-in loop runs is gated
/// exactly like one an external agent runs.
abstract interface class HarnessCommandRunner {
  /// Runs [command] (via `bash -lc`) inside the sandbox and returns the result.
  ///
  /// Applies the command policy first: a `deny` returns a denied result, a
  /// `prompt` requests confirmation (denied result if rejected), an `allow`
  /// proceeds. Output beyond a sane size is head/tail-truncated.
  ///
  /// [personWait] is told `true` when the runner starts waiting for a person
  /// (a confirmation) and `false` when that wait ends, so the caller's clocks
  /// do not count it. A runner that never asks anyone never calls it.
  ///
  /// [parentToolCallId] is set when the command belongs to a call a code mode
  /// script made (`HarnessToolContext.parentToolCallId`): the id of the
  /// script's own tool call, so an approval card the command raises can say
  /// it came from that script. Null for a command the model ran directly.
  ///
  /// [observer] hears the spawn and the output as it arrives
  /// ([HarnessCommandObserver]); a runner that cannot stream calls
  /// `onStarted` when it starts the command and `onOutput` once with the
  /// whole output at the end.
  Future<HarnessCommandResult> run(
    String command, {
    String? workdir,
    int timeoutSeconds = 120,
    Map<String, String>? env,
    CancellationToken? cancel,
    PersonWaitListener? personWait,
    String? parentToolCallId,
    HarnessCommandObserver? observer,
  });
}
