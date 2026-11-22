import 'package:cc_harness/tools.dart';

/// Reads a background command's state, and the output it wrote since the
/// last `bash_output` call for it, by its handle (`b1`, `b2`, …).
///
/// Follows `bash` onto the surface (exec tier and self-guarded, so it is
/// present exactly where `bash` is) but only reads: it has no action class.
class BashOutputTool extends HarnessTool implements BackgroundCommandTool {
  /// Creates the tool over the run's background commands.
  BashOutputTool(this.backgroundCommands);

  @override
  final BackgroundCommandRegistry? backgroundCommands;

  /// The most new output one call returns; the rest stays readable through
  /// `read_output`.
  static const int maxNewOutputChars = 30000;

  @override
  String get name => 'bash_output';

  @override
  String get description =>
      'Check a background shell command started with bash '
      'run_in_background: its status (running, exited, timed out, killed), '
      'its exit code, and the output it wrote since the last check. Takes '
      'the handle bash returned (b1, b2, …).';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.exec;

  @override
  bool get selfGuards => true;

  @override
  Set<ActionClass> get actionClasses => const {};

  @override
  bool get scriptCallable => true;

  @override
  String get resultNote =>
      '{handle, status: "running" | "exited" | "timed_out" | "killed", '
      'exit_code: integer or null, new_output: string, output_handle}: '
      'new_output is only what the command wrote since the last check (its '
      'last 30,000 characters when more); read_output(output_handle) pages '
      'all of it. An unknown handle rejects and names the known ones.';

  @override
  bool get speculativeReadSafe => false;

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'handle': {
        'type': 'string',
        'description': 'The background command\'s handle, such as "b1".',
      },
    },
    'required': ['handle'],
  };

  @override
  Map<String, dynamic> get outputSchema => const {
    'type': 'object',
    'properties': {
      'handle': {'type': 'string'},
      'status': {
        'type': 'string',
        'enum': ['running', 'exited', 'timed_out', 'killed'],
      },
      'exit_code': {
        'type': ['integer', 'null'],
        'description': 'Set once the command finished.',
      },
      'new_output': {
        'type': 'string',
        'description': 'Output written since the last bash_output call.',
      },
      'output_handle': {
        'type': 'string',
        'description': 'Pass to read_output to page all of the output.',
      },
    },
    'required': [
      'handle',
      'status',
      'exit_code',
      'new_output',
      'output_handle',
    ],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final registry = backgroundCommands;
    if (registry == null) {
      return HarnessToolResult.error(
        'Background commands are not available in this run.',
      );
    }
    final handle = (args['handle'] as String?)?.trim() ?? '';
    final command = registry.byHandle(handle);
    if (command == null) {
      return HarnessToolResult.error(
        'No background command "$handle". ${registry.knownHandles()}',
      );
    }
    var fresh = command.takeNewOutput();
    var cut = 0;
    if (fresh.length > maxNewOutputChars) {
      cut = fresh.length - maxNewOutputChars;
      fresh = fresh.substring(cut);
    }
    final outputHandle = command.storedOutputHandle ?? command.outputHandle;
    final text =
        StringBuffer(command.noticeDelivered ? '$alreadyDeliveredLine\n' : '')
          ..write(command.stateLine)
          ..write('\nCommand: `${command.command}`');
    if (fresh.isEmpty) {
      text.write('\nNo new output since the last check.');
    } else {
      text
        ..write('\nNew output')
        ..write(cut > 0 ? ' (the first $cut characters left out)' : '')
        ..write(':\n')
        ..write(fresh);
    }
    text.write('\nAll output: read_output(handle: "$outputHandle")');
    return HarnessToolResult.success(
      text.toString(),
      structured: {
        'handle': command.handle,
        'status': _status(command.status),
        'exit_code': command.isLive ? null : command.exitCode,
        'new_output': fresh,
        'output_handle': outputHandle,
      },
    );
  }
}

/// Stops a background command by its handle.
///
/// Changes state the way stopping a process does, so it carries the process
/// class `bash` carries and follows `bash` onto the surface.
class BashKillTool extends HarnessTool implements BackgroundCommandTool {
  /// Creates the tool over the run's background commands.
  BashKillTool(this.backgroundCommands);

  @override
  final BackgroundCommandRegistry? backgroundCommands;

  @override
  String get name => 'bash_kill';

  @override
  String get description =>
      'Stop (kill) a background shell command started with bash '
      'run_in_background, by the handle bash returned (b1, b2, …). Its output '
      'stays readable.';

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.exec;

  @override
  bool get selfGuards => true;

  @override
  Set<ActionClass> get actionClasses => const {ActionClass.processSpawn};

  @override
  bool get scriptCallable => true;

  @override
  String get resultNote =>
      '{handle, status, exit_code: integer or null, output_handle}: the '
      'command and everything it started are stopped; read_output('
      'output_handle) still pages its output. An unknown handle rejects and '
      'names the known ones.';

  @override
  Map<String, dynamic> get inputSchema => const {
    'type': 'object',
    'properties': {
      'handle': {
        'type': 'string',
        'description': 'The background command\'s handle, such as "b1".',
      },
    },
    'required': ['handle'],
  };

  @override
  Map<String, dynamic> get outputSchema => const {
    'type': 'object',
    'properties': {
      'handle': {'type': 'string'},
      'status': {
        'type': 'string',
        'enum': ['running', 'exited', 'timed_out', 'killed'],
      },
      'exit_code': {
        'type': ['integer', 'null'],
      },
      'output_handle': {'type': 'string'},
    },
    'required': ['handle', 'status', 'exit_code', 'output_handle'],
  };

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async {
    final registry = backgroundCommands;
    if (registry == null) {
      return HarnessToolResult.error(
        'Background commands are not available in this run.',
      );
    }
    final handle = (args['handle'] as String?)?.trim() ?? '';
    final wasLive = registry.byHandle(handle)?.isLive ?? false;
    final command = await registry.kill(handle);
    if (command == null) {
      return HarnessToolResult.error(
        'No background command "$handle". ${registry.knownHandles()}',
      );
    }
    final outputHandle = command.storedOutputHandle ?? command.outputHandle;
    final head = wasLive
        ? (command.isLive
              ? '${command.handle} was sent a kill and has not exited yet'
              : command.stateLine)
        : '${command.stateLine}; nothing to stop';
    final delivered = command.noticeDelivered ? '$alreadyDeliveredLine\n' : '';
    return HarnessToolResult.success(
      '$delivered$head.\nAll output: read_output(handle: "$outputHandle")',
      structured: {
        'handle': command.handle,
        'status': _status(command.status),
        'exit_code': command.isLive ? null : command.exitCode,
        'output_handle': outputHandle,
      },
    );
  }
}

/// The first line of a `bash_output` or `bash_kill` result once the
/// command's exit notice reached the model, so it does not act on it twice.
const String alreadyDeliveredLine = 'Already delivered in the exit notice.';

String _status(BackgroundCommandStatus status) => switch (status) {
  BackgroundCommandStatus.running => 'running',
  BackgroundCommandStatus.exited => 'exited',
  BackgroundCommandStatus.timedOut => 'timed_out',
  BackgroundCommandStatus.killed => 'killed',
};
