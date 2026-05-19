import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_infra/src/ports/workspace_filesystem_port.dart';

/// Update agent tool.
class UpdateAgentTool extends McpTool {
  /// Creates a new [Update agent tool].
  UpdateAgentTool({
    required AgentRepository repository,
    required WorkspaceFilesystemPort filesystem,
  }) : _repository = repository,
       _filesystem = filesystem;

  @override
  bool get requiresApproval => true;

  @override
  ApprovalPayload? buildConfirmationRequest(Map<String, dynamic> arguments) {
    final id = arguments['agent_id'];
    return ApprovalPayload(
      title: 'Update agent',
      detail: 'About to mutate agent ${id ?? 'unknown'}.',
    );
  }

  final AgentRepository _repository;
  final WorkspaceFilesystemPort _filesystem;

  @override
  String get name => 'update_agent';

  @override
  String get description =>
      "Updates an agent's configuration including name, adapter, model, skills, and AGENTS.md content.";

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace the agent belongs to.',
      },
      'agent_id': {
        'type': 'string',
        'description': 'The agent ID to update.',
      },
      'name': {
        'type': 'string',
        'description': 'Updated agent name.',
      },
      'title': {
        'type': 'string',
        'description': 'Updated human-readable title.',
      },
      'adapter': {
        'type': 'string',
        'description': 'Updated inference adapter ID (e.g. "claude", "pi").',
      },
      'model': {
        'type': 'string',
        'description': 'Updated model ID.',
      },
      'skills': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Updated list of skill names.',
      },
      'reports_to': {
        'type': 'string',
        'description':
            'Updated reports-to agent ID (NOT the name). Use list_agents '
            'to look up the id. Pass an empty string to clear.',
      },
      'persona': {
        'type': 'string',
        'description': 'Updated persona description.',
      },
      'agent_md_content': {
        'type': 'string',
        'description':
            "Updated content for the agent's AGENTS.md file.",
      },
    },
    'required': ['workspace_id', 'agent_id'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final rawAgentId = arguments['agent_id'];
    if (rawAgentId is! String) {
      return CallResult.error('Missing or invalid argument: agent_id (expected string)');
    }
    final agentId = rawAgentId;

    final existing = await _repository.getById(agentId);
    if (existing == null) {
      return CallResult.error('Agent not found: $agentId');
    }
    if (existing.workspaceId != rawWorkspaceId) {
      return CallResult.error('Agent belongs to a different workspace.');
    }

    final rawName = arguments['name'];
    final rawTitle = arguments['title'];
    final rawAdapter = arguments['adapter'];
    final rawModel = arguments['model'];
    final rawReportsTo = arguments['reports_to'];
    final rawPersona = arguments['persona'];
    final rawSkills = arguments['skills'];
    final rawAgentMdContent = arguments['agent_md_content'];
    final name = rawName is String ? rawName : existing.name;
    final title = rawTitle is String ? rawTitle : existing.title;
    final adapter =
        arguments.containsKey('adapter')
            ? (rawAdapter is String ? rawAdapter : null)
            : existing.adapterId;
    final model =
        arguments.containsKey('model')
            ? (rawModel is String ? rawModel : null)
            : existing.modelId;
    final reportsTo =
        arguments.containsKey('reports_to')
            ? (rawReportsTo is String ? rawReportsTo : null)
            : existing.reportsTo;
    final persona =
        arguments.containsKey('persona')
            ? (rawPersona is String ? rawPersona : null)
            : existing.persona;
    final skills =
        (rawSkills is List)
            ? rawSkills.map((s) => s.toString()).toList()
            : existing.skills.toList();
    final agentMdContent = rawAgentMdContent is String ? rawAgentMdContent : null;

    if (agentMdContent != null) {
      final slug = existing.agentMdPath.split('/').last.replaceAll('.md', '');
      await _filesystem.writeAgentFile(existing.workspaceId, slug, agentMdContent);
    }

    if (skills.isNotEmpty) {
      final slug = existing.agentMdPath.split('/').last.replaceAll('.md', '');
      await _filesystem.syncAgentSkillLinks(existing.workspaceId, slug, skills);
    }

    final updated = Agent(
      id: existing.id,
      name: name,
      title: title,
      agentMdPath: existing.agentMdPath,
      workspaceId: existing.workspaceId,
      reportsTo: reportsTo,
      skills: AgentSkills(skills),
      persona: persona,
      adapterId: adapter,
      modelId: model,
      createdAt: existing.createdAt,
    );

    await _repository.upsert(updated);

    return CallResult.success(
      jsonEncode({
        'id': updated.id,
        'name': updated.name,
        'title': updated.title,
        'adapter': updated.adapterId,
        'model': updated.modelId,
        'skills': updated.skills.toList(),
        'reports_to': updated.reportsTo,
        'status': 'updated',
      }),
    );
  }
}
