import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/channel_notes_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// MCP tool that updates a channel's shared Notes / handoff document (PRD 16
/// §11). Agents call this to leave context for the next human or agent — a
/// frictionless handoff so the next turn doesn't start from scratch.
///
/// The doc is a single markdown column updated by authoritative LWW (no
/// expected version). Concurrent editing is made VISIBLE via the presence
/// lane's soft-claim, not locked — both writers see each other's claim.
class UpdateChannelNotesTool extends McpTool {
  /// Creates an [UpdateChannelNotesTool].
  UpdateChannelNotesTool({
    required ChannelNotesPort notesPort,
    required MessagingRepository messagingRepository,
  }) : _notesPort = notesPort,
       _messaging = messagingRepository;

  final ChannelNotesPort _notesPort;
  final MessagingRepository _messaging;

  @override
  String get name => 'update_channel_notes';

  @override
  String get description =>
      'Updates the shared notes/handoff document for a channel. '
      'Write the full document content (it replaces the previous version). '
      'Use this to record decisions, state and instructions for the next '
      'human or agent who picks up this channel.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace the channel belongs to.',
      },
      'channel_id': {
        'type': 'string',
        'description': 'The channel whose notes to update.',
      },
      'content': {
        'type': 'string',
        'description': 'The new full markdown content of the notes document.',
      },
      'agent_id': {
        'type': 'string',
        'description': 'The calling agent\'s ID (for attribution).',
      },
    },
    'required': ['workspace_id', 'channel_id', 'content'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final channelId = arguments['channel_id'];
    if (channelId is! String) {
      return CallResult.error(
        'Missing or invalid argument: channel_id (expected string)',
      );
    }
    final content = arguments['content'];
    if (content is! String || content.isEmpty) {
      return CallResult.error(
        'Missing or invalid argument: content (expected non-empty string)',
      );
    }
    final agentId = arguments['agent_id'] as String? ?? 'unknown';

    // Workspace isolation: a bare channel_id is NOT proof of ownership.
    final channels = await _messaging
        .watchChannelsByWorkspace(workspaceId)
        .first;
    if (!channels.any((c) => c.id == channelId)) {
      return CallResult.error('Channel belongs to a different workspace.');
    }

    final note = await _notesPort.upsertNote(
      workspaceId: workspaceId,
      channelId: channelId,
      contentMarkdown: content,
      updatedBy: 'agent:$agentId',
    );

    return CallResult.success(
      jsonEncode({
        'channel_id': channelId,
        'content': note.contentMarkdown,
        'updated_by': note.updatedBy,
        'updated_at': note.updatedAt.toIso8601String(),
      }),
    );
  }
}
