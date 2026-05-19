import 'package:cc_harness/src/cancellation_token.dart';

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
  });

  /// A policy / confirmation denial (the command never ran).
  factory HarnessCommandResult.deny(String reason) => HarnessCommandResult(
    exitCode: 126,
    stdout: '',
    stderr: reason,
    denied: true,
    denyReason: reason,
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

  /// Whether the command completed successfully.
  bool get ok => !denied && !timedOut && exitCode == 0;
}

/// Runs shell commands for the harness `bash` tool, applying Control Center's
/// command policy, confirmation (UAC), and OS sandbox.
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
  Future<HarnessCommandResult> run(
    String command, {
    String? workdir,
    int timeoutSeconds = 120,
    Map<String, String>? env,
    CancellationToken? cancel,
  });
}
