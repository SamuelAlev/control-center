import 'dart:convert';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/messaging_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
/// MCP tool used by a plan-mode agent to consult a specialist agent for
/// expert confirmation on a specific topic.
///
/// Unlike `DelegateReviewTool`, this is lightweight — no review
/// associations, no review nodes, no PR context. The consulted agent is
/// added as a channel participant, dispatched with a focused brief, and
/// their response is expected back via the channel message stream.
class ConsultAgentTool extends McpTool {
  /// Creates a new [ConsultAgentTool].
  ConsultAgentTool({
    required AgentRepository agents,
    required MessagingRepository messaging,
    required MessagingPort messagingPort,
  })  : _agents = agents,
        _messaging = messaging,
        _messagingPort = messagingPort;

  final AgentRepository _agents;
  final MessagingRepository _messaging;
  final MessagingPort _messagingPort;

  @override
  String get name => 'consult_agent';

  @override
  String get description =>
      'Consult a specialist agent for expert input on a specific topic. '
      'The best-matching agent by skills is added as a channel participant, '
      'dispatched with a focused brief, and their response appears in the '
      'channel. Use when you need confirmation or specialist input for '
      'a planning decision. If no matching agent exists, use propose_hire.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'channel_id': {
        'type': 'string',
        'description': 'The plan channel ID.',
      },
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace whose agents are eligible.',
      },
      'topic': {
        'type': 'string',
        'description':
            'Expertise needed (e.g. "security", "performance", "flutter", '
            '"architecture"). Matched against agent skills and titles.',
      },
      'question': {
        'type': 'string',
        'description':
            'The specific question or decision you need specialist input on.',
      },
      'rationale': {
        'type': 'string',
        'description':
            'Why this input is needed for the plan (optional).',
      },
      'agent_id': {
        'type': 'string',
        'description':
            'Your own agent id (the requester). Attributes the consulted '
            "agent's reply to you in the channel (optional).",
      },
    },
    'required': ['channel_id', 'workspace_id', 'topic', 'question'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final rawChannelId = arguments['channel_id'];
    if (rawChannelId is! String) {
      return CallResult.error(
        'Missing or invalid argument: channel_id (expected string)',
      );
    }
    final rawWorkspaceId = arguments['workspace_id'];
    if (rawWorkspaceId is! String) {
      return CallResult.error(
        'Missing or invalid argument: workspace_id (expected string)',
      );
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

    final channelId = rawChannelId;
    final workspaceId = rawWorkspaceId;
    final topic = rawTopic;
    final question = rawQuestion;
    final rationale = arguments['rationale'] as String?;

    final candidates =
        await _agents.watchByWorkspace(workspaceId).first;
    final existingParticipants = await _messaging.getParticipants(channelId);
    final existingAgentIds = existingParticipants
        .map((p) => p.agentId)
        .toSet();

    final match = _findBestMatch(candidates, topic);
    if (match == null) {
      return CallResult.error(
        'No agent matching topic "$topic" found in workspace $workspaceId. '
        'Use propose_hire to suggest hiring a specialist.',
      );
    }

    if (!existingAgentIds.contains(match.id)) {
      await _messaging.addParticipant(channelId, match.id);
    }

    await _messaging.sendMessage(
      channelId: channelId,
      content:
          '@${match.name} you are being consulted as "$topic". $question',
      senderId: 'system',
      senderType: 'agent',
      messageType: 'system',
    );

    final brief = _buildConsultationBrief(
      agentName: match.name,
      topic: topic,
      question: question,
      rationale: rationale,
    );

    await _messagingPort.dispatchAgent(
      channelId: channelId,
      agentId: match.id,
      prompt: brief,
      workspaceId: workspaceId,
      inReplyToAgentId: arguments['agent_id'] as String?,
    );

    return CallResult.success(
      jsonEncode({
        'channel_id': channelId,
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
    final rationaleSection = rationale != null
        ? '\nContext: $rationale\n'
        : '';
    return 'You have been consulted as the "$topic" specialist for a '
        'planning discussion.$rationaleSection\n'
        'The planning agent asks:\n$question\n\n'
        'Please respond with your expert assessment. Be concise and '
        'actionable. The planning agent will incorporate your input into '
        'the written plan.';
  }

  Agent? _findBestMatch(List<Agent> agents, String topic) {
    final needle = topic.toLowerCase();
    Agent? best;
    var bestScore = 0;
    for (final agent in agents) {
      final score = _scoreMatch(agent, needle);
      if (score > bestScore) {
        bestScore = score;
        best = agent;
      }
    }
    return bestScore == 0 ? null : best;
  }

  int _scoreMatch(Agent agent, String needle) {
    var score = 0;
    final title = agent.title.toLowerCase();
    if (title.contains(needle)) {
      score += 2;
    }
    for (final skill in agent.skills.toList()) {
      if (skill.toLowerCase().contains(needle)) {
        score += 3;
      }
    }
    if (agent.name.toLowerCase().contains(needle)) {
      score += 1;
    }
    return score;
  }
}
