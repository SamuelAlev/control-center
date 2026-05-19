import 'dart:convert';

import 'package:cc_domain/features/governance/domain/entities/runtime_profile.dart';
import 'package:cc_domain/features/governance/domain/repositories/runtime_profile_repository.dart';
import 'package:cc_domain/features/governance/domain/value_objects/protocol_family.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:uuid/uuid.dart';

const _uuid = Uuid();

Map<String, dynamic> _profileJson(RuntimeProfile p) => {
  'id': p.id,
  'name': p.name,
  'protocol_family': p.protocolFamily.name,
  'command': p.command,
  'fixed_args': p.fixedArgs,
  'description': p.description,
};

/// Creates a reusable custom runtime profile (protocol + command + fixed args).
class CreateRuntimeProfileTool extends McpTool {
  /// Creates a [CreateRuntimeProfileTool].
  CreateRuntimeProfileTool({required RuntimeProfileRepository repository})
    : _repository = repository;

  final RuntimeProfileRepository _repository;

  @override
  String get name => 'create_runtime_profile';

  @override
  String get description =>
      'Defines a reusable runtime profile wrapping a protocol family, a CLI '
      'command and fixed launch arguments. Agents register against a profile '
      'to make their backing runtime configurable.';

  @override
  bool get requiresApproval => true;

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'name': {'type': 'string', 'description': 'Profile name.'},
      'command': {'type': 'string', 'description': 'Executable to launch.'},
      'protocol_family': {
        'type': 'string',
        'enum': ['claude', 'acp', 'pi', 'codex', 'cli'],
        'description': 'Protocol family (default cli).',
      },
      'fixed_args': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Fixed launch arguments.',
      },
      'description': {'type': 'string', 'description': 'Optional details.'},
    },
    'required': ['workspace_id', 'name', 'command'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final name = arguments['name'];
    if (name is! String) {
      return CallResult.error('Missing or invalid argument: name');
    }
    final command = arguments['command'];
    if (command is! String) {
      return CallResult.error('Missing or invalid argument: command');
    }
    final rawArgs = arguments['fixed_args'];
    final now = DateTime.now();
    final profile = RuntimeProfile(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      name: name,
      command: command,
      protocolFamily: ProtocolFamily.fromStorage(
        arguments['protocol_family'] as String?,
      ),
      fixedArgs: rawArgs is List
          ? rawArgs.map((e) => e.toString()).toList()
          : const [],
      description: arguments['description'] as String?,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.upsert(profile);
    return CallResult.success(jsonEncode(_profileJson(profile)));
  }
}

/// Lists the custom runtime profiles defined in a workspace.
class ListRuntimeProfilesTool extends McpTool {
  /// Creates a [ListRuntimeProfilesTool].
  ListRuntimeProfilesTool({required RuntimeProfileRepository repository})
    : _repository = repository;

  final RuntimeProfileRepository _repository;

  @override
  String get name => 'list_runtime_profiles';

  @override
  String get description =>
      'Lists the custom runtime profiles defined in a workspace.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
    },
    'required': ['workspace_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final profiles = await _repository.listByWorkspace(workspaceId);
    return CallResult.success(
      jsonEncode({
        'runtime_profiles': profiles.map(_profileJson).toList(),
        'count': profiles.length,
      }),
    );
  }
}
