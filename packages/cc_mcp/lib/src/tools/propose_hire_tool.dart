import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:uuid/uuid.dart';

/// MCP tool used by the CEO to propose hiring a new specialist when no
/// existing agent fits a needed role. Posts a `hire_proposal` channel
/// message; the user approves it from the UI which then triggers the
/// real `hire_agent` flow.
class ProposeHireTool extends McpTool {
  /// Creates a new [ProposeHireTool].
  ProposeHireTool({required MessagingRepository messaging})
    : _messaging = messaging;

  final MessagingRepository _messaging;

  @override
  String get name => 'propose_hire';

  @override
  String get description =>
      'Propose hiring a new specialist agent for a review. Posts a hire '
      'proposal card in the channel — the user must approve before the '
      'agent is created. Use this when delegate_review returns an '
      'unmatched role.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'channel_id': {
        'type': 'string',
        'description': 'The review channel ID where the proposal is posted.',
      },
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace where the agent would be hired.',
      },
      'name': {
        'type': 'string',
        'description': 'Proposed agent name (slug-friendly).',
      },
      'title': {
        'type': 'string',
        'description': 'Human-readable title.',
      },
      'skills': {
        'type': 'array',
        'items': {'type': 'string'},
        'description': 'Skills to attach to the new agent.',
      },
      'persona': {
        'type': 'string',
        'description': 'Optional persona description.',
      },
      'rationale': {
        'type': 'string',
        'description': 'Why this hire is needed for this review.',
      },
    },
    'required': [
      'channel_id',
      'workspace_id',
      'name',
      'title',
      'skills',
      'rationale',
    ],
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
    final rawName = arguments['name'];
    if (rawName is! String) {
      return CallResult.error(
        'Missing or invalid argument: name (expected string)',
      );
    }
    final rawTitle = arguments['title'];
    if (rawTitle is! String) {
      return CallResult.error(
        'Missing or invalid argument: title (expected string)',
      );
    }
    final rawSkills = arguments['skills'];
    if (rawSkills is! List) {
      return CallResult.error(
        'Missing or invalid argument: skills (expected array)',
      );
    }
    final rawRationale = arguments['rationale'];
    if (rawRationale is! String) {
      return CallResult.error(
        'Missing or invalid argument: rationale (expected string)',
      );
    }

    final messageId = const Uuid().v4();
    final skills =
        rawSkills.whereType<String>().toList(growable: false);
    final persona = arguments['persona'];

    final metadata = <String, dynamic>{
      'workspaceId': rawWorkspaceId,
      'name': rawName,
      'title': rawTitle,
      'skills': skills,
      'rationale': rawRationale,
      if (persona is String) 'persona': persona,
      'status': 'pending',
    };

    await _messaging.sendMessage(
      channelId: rawChannelId,
      content:
          'Proposing to hire **$rawName** ($rawTitle).\n\n$rawRationale',
      senderId: 'system',
      senderType: 'agent',
      messageType: 'hire_proposal',
      metadata: metadata,
      id: messageId,
    );

    return CallResult.success(
      jsonEncode({
        'message_id': messageId,
        'channel_id': rawChannelId,
        'status': 'pending_approval',
      }),
    );
  }
}
