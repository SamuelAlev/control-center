import 'package:cc_harness/context.dart'
    show ToolCallForm, ToolCallForms, buildToolOutputScope, toolCallIn;
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/workspace_paths.dart';

/// Executes a shell command through CC's command policy + sandbox + UAC.
///
/// Delegates to a `HarnessCommandRunner`, which evaluates the command against
/// the mode's command policy (allow / prompt / deny), prompts via the
/// confirmation flow when required and runs the approved command inside the OS
/// sandbox. Because the runner performs its own gating, this tool sets
/// [selfGuards] so the loop does not also fire the approval callback.
///
/// With `run_in_background: true` the command starts the same way (same
/// runner, policy, approval and sandbox) and the call returns as soon as it
/// is spawned, with a handle (`b1`, `b2`, …) in the run's
/// [BackgroundCommandRegistry]. A script may not start one: a background
/// process must not outlive the script that started it.
class BashTool extends HarnessTool implements BackgroundCommandTool {
  /// Creates a [BashTool] backed by the given command runner. Without
  /// [backgroundCommands], `run_in_background` is refused.
  BashTool(this._runner, {this.backgroundCommands});

  final HarnessCommandRunner _runner;

  @override
  final BackgroundCommandRegistry? backgroundCommands;

  static const String _scriptRefusal =
      'bash with run_in_background cannot be called from a script: a '
      'background command must not outlive the script that started it. Run '
      'the command in the foreground from the script, or call bash with '
      'run_in_background directly.';

  @override
  String get name => 'bash';

  /// What a script receives from a foreground command; a script cannot
  /// start one in the background.
  @override
  String get resultNote =>
      '{output: string, exit_code: 0, timed_out: false}: stdout, then '
      '`[stderr]` and stderr. A nonzero exit or a timeout rejects with '
      '`exit code N` and the output.';

  @override
  String get description =>
      'Execute a shell command and return its stdout and stderr. Commands are '
      'checked against the command policy and run inside the sandbox. Long '
      'output is truncated. With run_in_background the command keeps running '
      'and the call returns a handle at once (for builds, test suites, '
      'servers); you get a notice when it finishes.';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.exec;

  @override
  bool get selfGuards => true;

  /// The shell command.
  @override
  String? executedContent(Map<String, dynamic> args) =>
      switch (args['command']) {
        final String command => command,
        _ => null,
      };

  @override
  Map<String, dynamic> get inputSchema => withRequiredCallDescription({
    'type': 'object',
    'properties': {
      'command': {
        'type': 'string',
        'description': 'The shell command to execute.',
      },
      'timeout': {
        'type': 'integer',
        'description': 'Timeout in seconds (default 120).',
        'default': 120,
      },
      'cwd': {
        'type': 'string',
        'description': 'Working directory for the command.',
      },
      'run_in_background': {
        'type': 'boolean',
        'description':
            'Start the command and return at once with a handle (b1, b2, …) '
            'instead of waiting for it. At most 4 run at once; each is '
            'killed at its timeout and when the run ends.',
      },
      'timeout_seconds': {
        'type': 'integer',
        'description':
            'With run_in_background: seconds before the command is killed '
            '(default 600, at most 3600).',
      },
      'notify': {
        'type': 'string',
        'maxLength': BackgroundNotify.maxPatternChars,
        'description':
            'With run_in_background: a simple pattern (literal text, '
            'classes such as [0-9] or \\d, ".", "^", "\$", "|" between '
            'branches, "(?i)" to ignore case, one quantifier per branch; no '
            'groups). Each output line that matches is sent to you while the '
            'command keeps running (such as "listening on|FAILED"), so you '
            'need not poll.',
      },
    },
    'required': ['command'],
  });

  @override
  String? scriptArgumentRefusal(Map<String, dynamic> args) =>
      args['run_in_background'] == true ? _scriptRefusal : null;

  @override
  Map<String, dynamic> get outputSchema => const {
    'type': 'object',
    'properties': {
      'output': {
        'type': 'string',
        'description':
            'Standard output, then standard error after a `[stderr]` line.',
      },
      'exit_code': {'type': 'integer'},
      'timed_out': {'type': 'boolean'},
    },
    'required': ['output', 'exit_code', 'timed_out'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final command = args['command'];
    if (command is! String || command.trim().isEmpty) {
      return HarnessToolResult.error('Missing or invalid argument: command');
    }
    // A bash call has no scannable target; the transcript shows this instead
    // of an opaque command line, so a call without one is rejected.
    final missingDescription = missingCallDescription(args);
    if (missingDescription != null) {
      return missingDescription;
    }
    final background = args['run_in_background'] == true;
    // Clamp the model-supplied timeout to a sane range (1s–1h) so a runaway or
    // absurd value can't wedge the run.
    final timeout = ((args['timeout'] as num?)?.toInt() ?? 120).clamp(1, 3600);
    final rawCwd = args['cwd'] as String?;
    final String cwd;
    if (rawCwd == null || rawCwd.isEmpty) {
      cwd = context.workingDirectory;
    } else {
      // Commands run where the agent's files are: inside the workspace (the
      // overlay cwd or the shared conversation worktrees). A cwd pointing at
      // an original repo checkout — or anywhere else on the host — is refused.
      final resolved = resolveInsideWorkspace(
        context.workingDirectory,
        rawCwd,
        sharedRoots: context.sharedRoots,
      );
      if (resolved == null) {
        return HarnessToolResult.error(
          outsideWorkspaceMessage(
            'run a command',
            rawCwd,
            workspaceRoot: context.workingDirectory,
            sharedRoots: context.sharedRoots,
          ),
        );
      }
      cwd = resolved;
    }

    if (background) {
      return _startInBackground(command, cwd, args, context);
    }

    final result = await _runner.run(
      command,
      workdir: cwd,
      timeoutSeconds: timeout,
      cancel: context.cancel,
      personWait: context.personWait,
      parentToolCallId: context.parentToolCallId,
    );

    // The runner is this tool's guard: a refusal is a denial, not a failure,
    // and what a person decided is the call's decision
    // ([HarnessToolResult.guardVerdict]).
    if (result.denied) {
      return HarnessToolResult(
        content: result.denyReason ?? 'Command denied by policy.',
        isError: true,
        outcome: ToolOutcome.denied,
        guardVerdict: ToolGateVerdict.denied,
      );
    }
    final declined = result.personVerdict == ToolGateVerdict.denied;

    final buffer = StringBuffer();
    if (result.stdout.isNotEmpty) {
      buffer.write(result.stdout);
    }
    if (result.stderr.isNotEmpty) {
      if (buffer.isNotEmpty) {
        buffer.write('\n');
      }
      buffer
        ..write('[stderr]\n')
        ..write(result.stderr);
    }
    final structured = {
      'output': buffer.toString(),
      'exit_code': result.exitCode,
      'timed_out': result.timedOut,
    };
    if (result.timedOut) {
      buffer.write('\n[command timed out after ${timeout}s]');
    }
    final output = buffer.isEmpty
        ? '(no output, exit code ${result.exitCode})'
        : buffer.toString();
    return HarnessToolResult(
      content: 'exit code ${result.exitCode}\n$output',
      isError: !result.ok || declined,
      structured: structured,
      // A person declined a request the command made while it ran (the run
      // gateway's card for a push, say): the command ran, but what it was
      // stopped from doing is a denial.
      outcome: declined ? ToolOutcome.denied : null,
      guardVerdict: result.personVerdict,
    );
  }

  Future<HarnessToolResult> _startInBackground(
    String command,
    String cwd,
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    // Also refused here, not only by [scriptArgumentRefusal]: an `eval` cell
    // or any other nested caller must not start a process that outlives it.
    if (context.parentToolCallId != null) {
      return const HarnessToolResult(
        content: _scriptRefusal,
        isError: true,
        outcome: ToolOutcome.denied,
        guardVerdict: ToolGateVerdict.denied,
      );
    }
    final registry = backgroundCommands;
    if (registry == null) {
      return HarnessToolResult.error(
        'Background commands are not available in this run. Run the command '
        'without run_in_background.',
      );
    }
    // A notify pattern is checked before anything starts.
    BackgroundNotify? notify;
    final pattern = args['notify'];
    if (pattern != null) {
      final refusal = pattern is String
          ? notifyPatternRefusal(pattern)
          : 'notify must be a string holding a pattern.';
      if (refusal != null) {
        return HarnessToolResult.error('$refusal Nothing was started.');
      }
      notify = BackgroundNotify(pattern as String);
    }
    final seconds =
        ((args['timeout_seconds'] as num?)?.toInt() ??
                BackgroundCommandRegistry.defaultTimeoutSeconds)
            .clamp(1, BackgroundCommandRegistry.maxTimeoutSeconds);
    final start = await registry.start(
      command: command,
      timeout: Duration(seconds: seconds),
      scope: buildToolOutputScope(context),
      callCancel: context.cancel,
      notify: notify,
      launch: (kill, observer, timeoutSeconds) => _runner.run(
        command,
        workdir: cwd,
        timeoutSeconds: timeoutSeconds,
        cancel: kill,
        personWait: context.personWait,
        observer: observer,
      ),
    );
    switch (start) {
      case BackgroundRefused(:final message):
        return HarnessToolResult.error(message);
      case BackgroundNotStarted(:final result):
        if (result.denied) {
          return HarnessToolResult(
            content: result.denyReason ?? 'Command denied by policy.',
            isError: true,
            outcome: ToolOutcome.denied,
            guardVerdict: ToolGateVerdict.denied,
          );
        }
        final reason = [
          result.stderr,
          result.stdout,
        ].where((part) => part.trim().isNotEmpty).join('\n');
        return HarnessToolResult.error(
          'The background command did not start'
          '${reason.isEmpty ? '' : ': $reason'}',
        );
      case BackgroundStarted(command: final started):
        return HarnessToolResult.success(
          backgroundStartedText(started, forms: registry.callForms),
        );
    }
  }
}

/// What a started background command's `bash` call returns: the handle and
/// how to follow up, with `bash_output` and `bash_kill` in the [forms] the
/// run calls them in.
String backgroundStartedText(
  BackgroundCommand command, {
  required ToolCallForms forms,
}) {
  final h = command.handle;
  final scripted = forms('bash_kill') == ToolCallForm.script;
  return 'Started background command $h (killed after '
      '${formatBackgroundDuration(command.timeout)} if it is still running).\n'
      'Output so far, and all of it after it ends: '
      'read_output(handle: "${command.outputHandle}")\n'
      'Status or stop${scripted ? ', from a `repl` script' : ''}: '
      '${toolCallIn(forms, 'bash_output', 'handle: "$h"')} / '
      '${toolCallIn(forms, 'bash_kill', 'handle: "$h"')}\n'
      'When it finishes you get a notice with its exit code and the end of its '
      'output. If you would end your turn while it runs, the run waits for it '
      'first.'
      '${command.notify == null ? '' : '\nOutput lines matching notify are sent to you as they appear (at most ${BackgroundNotify.maxDeliveries} times).'}';
}
