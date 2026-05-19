import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_infra/src/usecases/hire_agent_use_case.dart';

/// Hire agent tool.
class HireAgentTool extends McpTool {
  /// Creates a new [Hire agent tool].
  HireAgentTool({
    required HireAgentUseCase hireAgent,
  }) : _hireAgent = hireAgent;

  @override
  bool get requiresApproval => true;

  @override
  ApprovalPayload? buildConfirmationRequest(Map<String, dynamic> arguments) {
    final name = arguments['name'];
    return ApprovalPayload(
      title: 'Hire agent',
      detail:
          'An agent is about to be added to the workspace: ${name ?? 'unnamed'}.',
    );
  }

  final HireAgentUseCase _hireAgent;

  @override
  String get name => 'hire_agent';

  @override
  String get description =>
      'Registers a new AI agent with a name, title, skills, and AGENTS.md content.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace ID to hire the agent in.',
      },
      'name': {
        'type': 'string',
        'description': 'Unique agent name (e.g. "architect").',
      },
      'title': {
        'type': 'string',
        'description': 'Human-readable title (e.g. "System Architect").',
      },
      'skills': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'List of skill names the agent should have.',
      },
      'reports_to': {
        'type': 'string',
        'description':
            'ID of the agent this one reports to (NOT the name). '
            'Use list_agents to look up the id of the manager. '
            'Omit for a top-level agent.',
      },
      'persona': {
        'type': 'string',
        'description': 'Optional persona description.',
      },
      'agent_md_content': {
        'type': 'string',
        'description':
            "Full content for the agent's AGENTS.md file. "
            'Skills and reports_to provided as parameters will be linked '
            'separately from this content.',
      },
    },
    'required': ['workspace_id', 'name', 'title', 'agent_md_content'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id (expected string)');
    }
    final rawName = arguments['name'];
    if (rawName is! String) {
      return CallResult.error('Missing or invalid argument: name (expected string)');
    }
    final rawTitle = arguments['title'];
    if (rawTitle is! String) {
      return CallResult.error('Missing or invalid argument: title (expected string)');
    }
    final rawAgentMdContent = arguments['agent_md_content'];
    if (rawAgentMdContent is! String) {
      return CallResult.error('Missing or invalid argument: agent_md_content (expected string)');
    }
    final rawSkills = arguments['skills'];
    final rawReportsTo = arguments['reports_to'];
    final rawPersona = arguments['persona'];
    final skills =
        (rawSkills is List)
            ? rawSkills.map((s) => s.toString()).toList()
            : <String>[];
    final reportsTo = rawReportsTo is String ? rawReportsTo : null;
    final persona = rawPersona is String ? rawPersona : null;

    final agent = await _hireAgent.hire(
      workspaceId: rawWorkspaceId,
      name: rawName,
      title: rawTitle,
      agentMdContent: rawAgentMdContent,
      skills: skills,
      reportsTo: reportsTo,
      persona: persona,
    );

    return CallResult.success(
      jsonEncode({
        'id': agent.id,
        'name': agent.name,
        'title': agent.title,
        'skills': agent.skills.toList(),
        'reports_to': agent.reportsTo,
        'status': 'created',
      }),
    );
  }
}

