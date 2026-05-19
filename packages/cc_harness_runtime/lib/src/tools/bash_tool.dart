import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/src/tools/workspace_paths.dart';

/// Executes a shell command through CC's command policy + sandbox + UAC.
///
/// Delegates to a `HarnessCommandRunner`, which evaluates the command against
/// the mode's command policy (allow / prompt / deny), prompts via the
/// confirmation flow when required and runs the approved command inside the OS
/// sandbox. Because the runner performs its own gating, this tool sets
/// [selfGuards] so the loop does not also fire the approval callback.
class BashTool extends HarnessTool {
  /// Creates a [BashTool] backed by the given command runner.
  BashTool(this._runner);

  final HarnessCommandRunner _runner;

  @override
  String get name => 'bash';

  @override
  String get description =>
      'Execute a shell command and return its stdout and stderr. Commands are '
      'checked against the command policy and run inside the sandbox. Long '
      'output is truncated.';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.exec;

  @override
  bool get selfGuards => true;

  @override
  Map<String, dynamic> get inputSchema => {
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
    },
    'required': ['command'],
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

    final result = await _runner.run(
      command,
      workdir: cwd,
      timeoutSeconds: timeout,
      cancel: context.cancel,
    );

    if (result.denied) {
      return HarnessToolResult.error(
        result.denyReason ?? 'Command denied by policy.',
      );
    }

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
    if (result.timedOut) {
      buffer.write('\n[command timed out after ${timeout}s]');
    }
    final output = buffer.isEmpty
        ? '(no output, exit code ${result.exitCode})'
        : buffer.toString();
    return HarnessToolResult(
      content: 'exit code ${result.exitCode}\n$output',
      isError: !result.ok,
    );
  }
}
