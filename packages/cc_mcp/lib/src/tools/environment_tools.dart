import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_harness/tools.dart' show ActionClass;
import 'package:cc_mcp/src/tools/environment_read_tools.dart';

const Map<String, dynamic> _scope = {
  'workspace_id': {'type': 'string', 'description': 'The workspace.'},
  'space_id': {
    'type': 'string',
    'description': 'The space whose environment this acts on.',
  },
  // Declared so the tool bridge injects the running agent: it only fills
  // fields the schema names.
  'agent_id': {
    'type': 'string',
    'description':
        'The acting agent. Filled in automatically; you do not need to set it.',
  },
};

/// Shared shape of the environment tools.
///
/// Every tool takes `workspace_id` and `space_id` and derives the environment
/// from the space, so there is no name a caller could use to reach another
/// space's stack. The port refuses a space from another workspace.
abstract class EnvironmentTool extends McpTool {
  /// Creates an [EnvironmentTool].
  EnvironmentTool({required this.environments});

  /// The environment feature.
  final EnvironmentPort environments;

  /// The id recorded when a dispatcher supplied none. Deliberately not a
  /// plausible agent id, so audit surfaces show that nobody knows who acted.
  static const String unattributedAgentId = 'unattributed';

  /// Who a call is attributed to.
  static Principal principalOf(Map<String, dynamic> arguments) {
    final id = arguments['agent_id'];
    return AgentPrincipal(
      id is String && id.isNotEmpty ? id : unattributedAgentId,
    );
  }

  /// The run's own space and agent, never the model's. Without this an agent
  /// in one space could name another space and act on its environment.
  @override
  Set<String> get forcedScopeKeys => const {'space_id', 'agent_id'};

  /// Forcing a value is no use if none was supplied: the model's would stand.
  @override
  Set<String> get requiredScopeKeys => const {'workspace_id', 'space_id'};

  /// Headers can name any space; only a run's own secret names its own.
  @override
  bool get requiresRunGrant => true;

  /// Extra input properties.
  Map<String, dynamic> get extraProperties => const {};

  /// Extra required inputs.
  List<String> get extraRequired => const [];

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {..._scope, ...extraProperties},
    'required': ['workspace_id', 'space_id', ...extraRequired],
  };

  /// Does the work.
  Future<CallResult> act(
    String workspaceId,
    String spaceId,
    Map<String, dynamic> arguments,
  );

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String || workspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final spaceId = arguments['space_id'];
    if (spaceId is! String || spaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: space_id');
    }
    for (final key in extraRequired) {
      if (arguments[key] == null) {
        return CallResult.error('Missing argument: $key');
      }
    }
    try {
      return await act(workspaceId, spaceId, arguments);
    } on Exception catch (e) {
      return CallResult.error('$e');
    }
  }

  /// The space's environments as a result.
  Future<CallResult> report(String workspaceId, String spaceId) async {
    final list = await environments.environmentsFor(workspaceId, spaceId);
    return CallResult.success(
      jsonEncode({
        'environments': [for (final item in list) item.toJson()],
      }),
    );
  }
}

/// `environment_up`.
class EnvironmentUpTool extends EnvironmentTool {
  /// Creates an [EnvironmentUpTool].
  EnvironmentUpTool({required super.environments});

  @override
  String get name => 'environment_up';

  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.enclosureControl,
    ActionClass.hostExecution,
    ActionClass.processSpawn,
  };

  @override
  String get description =>
      "Starts the space's environment, or reuses it if it is already up. "
      'Returns once every component is ready or one has failed.';

  @override
  Map<String, dynamic> get extraProperties => const {
    'definition_id': {
      'type': 'string',
      'description': 'Which definition, when the space matches several.',
    },
    'options': {
      'type': 'object',
      'description': 'Values for the definition\'s options.',
    },
  };

  @override
  Future<CallResult> act(
    String workspaceId,
    String spaceId,
    Map<String, dynamic> arguments,
  ) async {
    final options = arguments['options'];
    final environment = await environments.ensure(
      workspaceId: workspaceId,
      spaceId: spaceId,
      definitionId: arguments['definition_id'] as String?,
      options: options is Map ? Map<String, dynamic>.from(options) : const {},
      by: EnvironmentTool.principalOf(arguments),
    );
    return CallResult.success(jsonEncode(environment.toJson()));
  }
}

/// `environment_down`.
class EnvironmentDownTool extends EnvironmentTool {
  /// Creates an [EnvironmentDownTool].
  EnvironmentDownTool({required super.environments});

  @override
  String get name => 'environment_down';

  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.enclosureControl,
    ActionClass.hostExecution,
    ActionClass.processSpawn,
  };

  @override
  String get description =>
      "Stops the space's environment. Some tools lose data on stop: check "
      'the warnings in environment_status first.';

  @override
  Future<CallResult> act(
    String workspaceId,
    String spaceId,
    Map<String, dynamic> arguments,
  ) async {
    final environment = await environments.stop(
      workspaceId,
      spaceId,
      by: EnvironmentTool.principalOf(arguments),
    );
    return CallResult.success(jsonEncode(environment.toJson()));
  }
}

/// `environment_reset`.
class EnvironmentResetTool extends EnvironmentTool {
  /// Creates an [EnvironmentResetTool].
  EnvironmentResetTool({required super.environments});

  @override
  String get name => 'environment_reset';

  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.enclosureControl,
    ActionClass.hostExecution,
    ActionClass.processSpawn,
  };

  @override
  String get description =>
      "Returns the environment's data to its baseline, discarding changes.";

  @override
  Future<CallResult> act(
    String workspaceId,
    String spaceId,
    Map<String, dynamic> arguments,
  ) async {
    final environment = await environments.reset(
      workspaceId,
      spaceId,
      by: EnvironmentTool.principalOf(arguments),
    );
    return CallResult.success(jsonEncode(environment.toJson()));
  }
}

/// `environment_destroy`.
class EnvironmentDestroyTool extends EnvironmentTool {
  /// Creates an [EnvironmentDestroyTool].
  EnvironmentDestroyTool({required super.environments});

  @override
  String get name => 'environment_destroy';

  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.enclosureControl,
    ActionClass.hostExecution,
    ActionClass.processSpawn,
  };

  @override
  String get description =>
      "Destroys the space's environment and everything in it.";

  @override
  Future<CallResult> act(
    String workspaceId,
    String spaceId,
    Map<String, dynamic> arguments,
  ) async {
    await environments.destroy(
      workspaceId,
      spaceId,
      by: EnvironmentTool.principalOf(arguments),
    );
    return CallResult.success(jsonEncode({'ok': true}));
  }
}

/// `environment_restart`.
class EnvironmentRestartTool extends EnvironmentTool {
  /// Creates an [EnvironmentRestartTool].
  EnvironmentRestartTool({required super.environments});

  @override
  String get name => 'environment_restart';

  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.enclosureControl,
    ActionClass.hostExecution,
    ActionClass.processSpawn,
  };

  @override
  String get description => 'Restarts one process or service.';

  @override
  Map<String, dynamic> get extraProperties => const {
    'target': {
      'type': 'string',
      'description': 'A process id or a service name.',
    },
  };

  @override
  List<String> get extraRequired => const ['target'];

  @override
  Future<CallResult> act(
    String workspaceId,
    String spaceId,
    Map<String, dynamic> arguments,
  ) async {
    await environments.restart(
      workspaceId,
      spaceId,
      '${arguments['target']}',
      by: EnvironmentTool.principalOf(arguments),
    );
    return CallResult.success(jsonEncode({'ok': true}));
  }
}

/// `environment_exec`.
class EnvironmentExecTool extends EnvironmentTool {
  /// Creates an [EnvironmentExecTool].
  EnvironmentExecTool({required super.environments});

  @override
  String get name => 'environment_exec';

  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.hostExecution,
    ActionClass.processSpawn,
  };

  @override
  String get description => 'Runs a command inside one service.';

  @override
  Map<String, dynamic> get extraProperties => const {
    'service': {'type': 'string', 'description': 'The service.'},
    'command': {
      'type': 'array',
      'items': {'type': 'string'},
      'description': 'The command and its arguments.',
    },
  };

  @override
  List<String> get extraRequired => const ['service', 'command'];

  @override
  Future<CallResult> act(
    String workspaceId,
    String spaceId,
    Map<String, dynamic> arguments,
  ) async {
    final command = arguments['command'];
    if (command is! List || command.isEmpty) {
      return CallResult.error('command must be a non-empty array');
    }
    final result = await environments.exec(
      workspaceId,
      spaceId,
      service: '${arguments['service']}',
      command: [for (final part in command) '$part'],
      by: EnvironmentTool.principalOf(arguments),
    );
    return CallResult.success(jsonEncode(result.toJson()));
  }
}

/// `environment_run_task`.
class EnvironmentRunTaskTool extends EnvironmentTool {
  /// Creates an [EnvironmentRunTaskTool].
  EnvironmentRunTaskTool({required super.environments});

  @override
  String get name => 'environment_run_task';

  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.hostExecution,
    ActionClass.networkEgress,
    ActionClass.processSpawn,
  };

  @override
  String get description =>
      'Runs a named task of the definition, such as `test` or `lint`, and '
      'waits for it. Output comes back fenced as untrusted data.';

  @override
  Map<String, dynamic> get extraProperties => const {
    'task_id': {'type': 'string', 'description': 'The task.'},
    'arguments': {
      'type': 'array',
      'items': {'type': 'string'},
      'description': 'Extra arguments.',
    },
  };

  @override
  List<String> get extraRequired => const ['task_id'];

  @override
  Future<CallResult> act(
    String workspaceId,
    String spaceId,
    Map<String, dynamic> arguments,
  ) async {
    final extra = arguments['arguments'];
    final run = await environments.runTask(
      workspaceId,
      spaceId,
      '${arguments['task_id']}',
      arguments: extra is List ? [for (final item in extra) '$item'] : const [],
      by: EnvironmentTool.principalOf(arguments),
    );
    return CallResult.success(
      jsonEncode({
        'status': run.status.name,
        'exit_code': run.exitCode,
        'error': run.error,
        'output': '<untrusted-output>\n${run.output}\n</untrusted-output>',
      }),
    );
  }
}

/// `environment_launch_app`.
class EnvironmentLaunchAppTool extends EnvironmentTool {
  /// Creates an [EnvironmentLaunchAppTool].
  EnvironmentLaunchAppTool({required super.environments});

  @override
  String get name => 'environment_launch_app';

  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.hostExecution,
    ActionClass.processSpawn,
  };

  @override
  String get description =>
      "Builds and opens the space's desktop app on the server's screen. A "
      'window appears for the person using that machine, so launch it only '
      'when you need it. Drive it with app_use.';

  @override
  Map<String, dynamic> get extraProperties => const {
    'component_id': {'type': 'string', 'description': 'The app component.'},
    'rebuild': {'type': 'boolean', 'description': 'Rebuild and relaunch.'},
  };

  @override
  List<String> get extraRequired => const ['component_id'];

  @override
  Future<CallResult> act(
    String workspaceId,
    String spaceId,
    Map<String, dynamic> arguments,
  ) async {
    await environments.launchApp(
      workspaceId,
      spaceId,
      '${arguments['component_id']}',
      rebuild: arguments['rebuild'] == true,
      by: EnvironmentTool.principalOf(arguments),
    );
    return report(workspaceId, spaceId);
  }
}

/// `environment_stop_app`.
class EnvironmentStopAppTool extends EnvironmentTool {
  /// Creates an [EnvironmentStopAppTool].
  EnvironmentStopAppTool({required super.environments});

  @override
  String get name => 'environment_stop_app';

  @override
  Set<ActionClass> get actionClasses => const {
    ActionClass.hostExecution,
    ActionClass.processSpawn,
  };

  @override
  String get description => "Closes the space's desktop app.";

  @override
  Map<String, dynamic> get extraProperties => const {
    'component_id': {'type': 'string', 'description': 'The app component.'},
  };

  @override
  List<String> get extraRequired => const ['component_id'];

  @override
  Future<CallResult> act(
    String workspaceId,
    String spaceId,
    Map<String, dynamic> arguments,
  ) async {
    await environments.stopApp(
      workspaceId,
      spaceId,
      '${arguments['component_id']}',
      by: EnvironmentTool.principalOf(arguments),
    );
    return report(workspaceId, spaceId);
  }
}

/// Every environment tool.
List<EnvironmentTool> buildEnvironmentTools(EnvironmentPort environments) => [
  EnvironmentStatusTool(environments: environments),
  EnvironmentUpTool(environments: environments),
  EnvironmentDownTool(environments: environments),
  EnvironmentResetTool(environments: environments),
  EnvironmentDestroyTool(environments: environments),
  EnvironmentRestartTool(environments: environments),
  EnvironmentExecTool(environments: environments),
  EnvironmentLogsTool(environments: environments),
  EnvironmentRunTaskTool(environments: environments),
  EnvironmentLaunchAppTool(environments: environments),
  EnvironmentStopAppTool(environments: environments),
];
