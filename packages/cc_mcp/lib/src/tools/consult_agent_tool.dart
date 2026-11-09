import 'dart:convert';

import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_mcp/src/tools/peer_agent_messaging.dart';

/// MCP tool used by a plan-mode agent to consult a specialist agent for
/// expert confirmation on a specific topic.
///
/// Unlike `DelegateReviewTool`, this is lightweight — no review
/// associations, no review nodes, no PR context. The consulted agent is
/// added as a space participant, dispatched with a focused brief and
/// their response is expected back via the space message stream.
class ConsultAgentTool extends McpTool {
  /// Creates a new [ConsultAgentTool].
  ConsultAgentTool({
    required AgentRepository agents,
    required this._messaging,
    required this._messagingPort,
  }) : _peers = PeerAgentMessaging(agents: agents, messaging: _messaging);

  final PeerAgentMessaging _peers;
  final MessagingRepository _messaging;
  final MessagingPort _messagingPort;

  @override
  String get name => 'consult_agent';
  @override
  Set<ActionClass> get actionClasses => const {ActionClass.processSpawn};

  @override
  String get description =>
      'Consult a specialist agent for expert input on a specific topic. Name '
      'the specialist by to_agent_id or exact to_agent_name (use list_agents '
      'to find one; ambiguous or unknown names are rejected with the '
      'candidates — no fuzzy matching). The agent is added as a space '
      'participant, dispatched with a focused brief and their response '
      'appears in the conversation. Use when you need confirmation or '
      'specialist input for a planning decision. If no suitable agent exists, '
      'suggest hiring one.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'space_id': {'type': 'string', 'description': 'The plan space ID.'},
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace whose agents are eligible.',
      },
      'to_agent_id': {
        'type': 'string',
        'description': 'The specialist agent id (preferred).',
      },
      'to_agent_name': {
        'type': 'string',
        'description':
            'The specialist agent name (an exact, unique match in the '
            'workspace). Provide this OR to_agent_id.',
      },
      'topic': {
        'type': 'string',
        'description':
            'The expertise you are consulting them for (e.g. "security", '
            '"performance"). Framing for the brief, not used to pick the agent.',
      },
      'question': {
        'type': 'string',
        'description':
            'The specific question or decision you need specialist input on.',
      },
      'rationale': {
        'type': 'string',
        'description': 'Why this input is needed for the plan (optional).',
      },
      'agent_id': {
        'type': 'string',
        'description':
            'Your own agent id (the requester). Attributes the consulted '
            "agent's reply to you in the conversation (optional).",
      },
    },
    'required': ['space_id', 'workspace_id', 'topic', 'question'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawSpaceId = arguments['space_id'];
    if (rawSpaceId is! String) {
      return CallResult.error(
        'Missing or invalid argument: space_id (expected string)',
      );
    }
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final rawTopic = arguments['topic'];
    if (rawTopic is! String) {
      return CallResult.error(
        'Missing or invalid argument: topic (expected string)',
      );
    }
    final rawQuestion = arguments['question'];
    if (rawQuestion is! String) {
      return CallResult.error(
        'Missing or invalid argument: question (expected string)',
      );
    }

    final spaceId = rawSpaceId;
    final workspaceId = rawWorkspaceId;
    final topic = rawTopic;
    final question = rawQuestion;
    final rationale = arguments['rationale'] as String?;

    if (!await _messaging.spaceExists(workspaceId, spaceId)) {
      return CallResult.error('Space belongs to a different workspace.');
    }
    final resolution = await _peers.resolveRecipient(
      workspaceId: workspaceId,
      toAgentId: arguments['to_agent_id'] as String?,
      toAgentName: arguments['to_agent_name'] as String?,
    );
    if (resolution is UnresolvedRecipient) {
      return CallResult.error(resolution.message);
    }
    final match = (resolution as ResolvedRecipient).agent;
    final existingParticipants = await _messaging.getParticipants(
      workspaceId,
      spaceId,
    );
    final existingAgentIds = {
      for (final p in existingParticipants)
        if (!p.isUser) p.principalId,
    };

    if (!existingAgentIds.contains(match.id)) {
      await _messaging.addParticipant(workspaceId, spaceId, match.id);
    }

    await _messaging.sendMessage(
      workspaceId: workspaceId,
      spaceId: spaceId,
      content: '@${match.name} you are being consulted as "$topic". $question',
      senderId: 'system',
      senderType: 'system',
      messageType: 'system',
    );

    final brief = _buildConsultationBrief(
      agentName: match.name,
      topic: topic,
      question: question,
      rationale: rationale,
    );

    await _messagingPort.dispatchAgent(
      spaceId: spaceId,
      agentId: match.id,
      prompt: brief,
      workspaceId: workspaceId,
      inReplyToAgentId: arguments['agent_id'] as String?,
    );

    return CallResult.success(
      jsonEncode({
        'space_id': spaceId,
        'consulted_agent_id': match.id,
        'consulted_agent_name': match.name,
        'topic': topic,
        'question': question,
      }),
    );
  }

  String _buildConsultationBrief({
    required String agentName,
    required String topic,
    required String question,
    required String? rationale,
  }) {
    final rationaleSection = rationale != null ? '\nContext: $rationale\n' : '';
    return 'You have been consulted as the "$topic" specialist for a '
        'planning discussion.$rationaleSection\n'
        'The planning agent asks:\n$question\n\n'
        'Please respond with your expert assessment. Be concise and '
        'actionable. The planning agent will incorporate your input into '
        'the written plan.';
  }
}
