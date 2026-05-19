import 'dart:convert';

import 'package:cc_domain/features/governance/domain/repositories/agent_runtime_state_repository.dart';
import 'package:cc_domain/features/governance/domain/services/agent_presence_service.dart';
import 'package:cc_domain/features/governance/domain/services/heartbeat_monitor_service.dart';
import 'package:cc_domain/features/governance/domain/services/org_chart_service.dart';
import 'package:cc_domain/features/governance/domain/value_objects/heartbeat_status.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_node.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';

/// Records a heartbeat for an agent (alive / idle / stuck), updating its
/// runtime liveness.
class AgentHeartbeatTool extends McpTool {
  /// Creates an [AgentHeartbeatTool].
  AgentHeartbeatTool({required HeartbeatMonitorService service})
    : _service = service;

  final HeartbeatMonitorService _service;

  @override
  String get name => 'agent_heartbeat';

  @override
  String get description =>
      'Phones home to report liveness (alive, idle, or stuck). Keeps the agent '
      'visible as online; going quiet flips runtime health to recently-lost '
      'then offline.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string', 'description': 'Workspace ID.'},
      'agent_id': {'type': 'string', 'description': 'Agent id.'},
      'status': {
        'type': 'string',
        'enum': ['alive', 'idle', 'stuck'],
        'description': 'Reported liveness (default alive).',
      },
      'run_id': {'type': 'string', 'description': 'Current run id.'},
      'note': {'type': 'string', 'description': 'What the agent is doing.'},
    },
    'required': ['workspace_id', 'agent_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final agentId = arguments['agent_id'];
    if (agentId is! String) {
      return CallResult.error('Missing or invalid argument: agent_id');
    }
    final state = await _service.recordHeartbeat(
      workspaceId: workspaceId,
      agentId: agentId,
      status: HeartbeatStatus.fromStorage(arguments['status'] as String?),
      runId: arguments['run_id'] as String?,
      note: arguments['note'] as String?,
    );
    return CallResult.success(
      jsonEncode({
        'agent_id': state.agentId,
        'reported_status': state.reportedStatus.name,
        'last_heartbeat_at': state.lastHeartbeatAt?.toIso8601String(),
      }),
    );
  }
}

/// Lists the derived runtime health of every agent in a workspace.
class ListRuntimeHealthTool extends McpTool {
  /// Creates a [ListRuntimeHealthTool].
  ListRuntimeHealthTool({required AgentRuntimeStateRepository repository})
    : _repository = repository;

  final AgentRuntimeStateRepository _repository;

  @override
  String get name => 'list_runtime_health';

  @override
  String get description =>
      'Lists each agent\'s runtime liveness: reported status, last heartbeat, '
      'and derived health (online, recently_lost, offline, about_to_gc).';

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
    final now = DateTime.now();
    final states = await _repository.listByWorkspace(workspaceId);
    return CallResult.success(
      jsonEncode({
        'runtimes': [
          for (final s in states)
            {
              'agent_id': s.agentId,
              'reported_status': s.reportedStatus.name,
              'health': s.healthAt(now).name,
              'last_heartbeat_at': s.lastHeartbeatAt?.toIso8601String(),
              'current_run_id': s.currentRunId,
            },
        ],
        'count': states.length,
      }),
    );
  }
}

/// Reports each agent's presence: availability × workload with the running /
/// queued / capacity counts.
class ListAgentPresenceTool extends McpTool {
  /// Creates a [ListAgentPresenceTool].
  ListAgentPresenceTool({required AgentPresenceService service})
    : _service = service;

  final AgentPresenceService _service;

  @override
  String get name => 'list_agent_presence';

  @override
  String get description =>
      'Reports each agent\'s presence — availability (online/unstable/offline/'
      'archived) and workload (working/queued/idle) with running, queued and '
      'concurrency-capacity counts.';

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
    final presence = await _service.presenceForWorkspace(workspaceId);
    return CallResult.success(
      jsonEncode({
        'presence': [
          for (final entry in presence.entries)
            {
              'agent_id': entry.key,
              'availability': entry.value.availability.name,
              'workload': entry.value.workload.name,
              'running_count': entry.value.runningCount,
              'queued_count': entry.value.queuedCount,
              'capacity': entry.value.capacity,
              'summary': entry.value.summary,
            },
        ],
        'count': presence.length,
      }),
    );
  }
}

/// Returns the agent org chart as a nested reporting tree.
class GetOrgChartTool extends McpTool {
  /// Creates a [GetOrgChartTool].
  GetOrgChartTool({required OrgChartService service}) : _service = service;

  final OrgChartService _service;

  @override
  String get name => 'get_org_chart';

  @override
  String get description =>
      'Returns the agent reporting tree (org chart): the CEO at the root with '
      'specialists nested under their managers via reports_to.';

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
    final roots = await _service.buildTree(workspaceId);
    return CallResult.success(
      jsonEncode({
        'roots': roots.map(_nodeJson).toList(),
        'count': roots.length,
      }),
    );
  }

  Map<String, dynamic> _nodeJson(OrgNode node) => {
    'agent_id': node.agent.id,
    'name': node.agent.name,
    'title': node.agent.title,
    'role': node.agent.role?.name,
    'lifecycle_status': node.agent.lifecycleStatus.name,
    'reports': node.reports.map(_nodeJson).toList(),
  };
}
