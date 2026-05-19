import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/channel_notes_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// MCP tool that reads a channel's shared Notes / handoff document (PRD 16
/// §11). Agents call this to pick up context a human (or another agent) left
/// behind, so a handoff carries state instead of re-explaining.
class GetChannelNotesTool extends McpTool {
  /// Creates a [GetChannelNotesTool].
  GetChannelNotesTool({
    required ChannelNotesPort notesPort,
    required MessagingRepository messagingRepository,
  }) : _notesPort = notesPort,
       _messaging = messagingRepository;

  final ChannelNotesPort _notesPort;
  final MessagingRepository _messaging;

  @override
  String get name => 'get_channel_notes';

  @override
  String get description =>
      'Reads the shared notes/handoff document for a channel. '
      'Use this to pick up context from a prior human or agent turn — '
      'decisions, TODOs and state that survived across the handoff.';

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
        'description': 'The channel whose notes to read.',
      },
    },
    'required': ['workspace_id', 'channel_id'],
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

    // Workspace isolation: a bare channel_id is NOT proof of ownership.
    final channels = await _messaging
        .watchChannelsByWorkspace(workspaceId)
        .first;
    if (!channels.any((c) => c.id == channelId)) {
      return CallResult.error('Channel belongs to a different workspace.');
    }

    final note = await _notesPort.getNote(workspaceId, channelId);

    if (note == null) {
      return CallResult.success(
        jsonEncode({
          'channel_id': channelId,
          'content': null,
          'message': 'No notes document exists for this channel yet.',
        }),
      );
    }

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
