import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/space_notes_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// MCP tool that updates a space's shared Notes / handoff document (PRD 16
/// §11). Agents call this to leave context for the next human or agent — a
/// frictionless handoff so the next turn doesn't start from scratch.
///
/// The doc is a single markdown column updated by authoritative LWW (no
/// expected version). Concurrent editing is made VISIBLE via the presence
/// lane's soft-claim, not locked — both writers see each other's claim.
class UpdateSpaceNotesTool extends McpTool {
  /// Creates an [UpdateSpaceNotesTool].
  UpdateSpaceNotesTool({
    required SpaceNotesPort notesPort,
    required MessagingRepository messagingRepository,
  }) : _notesPort = notesPort,
       _messaging = messagingRepository;

  final SpaceNotesPort _notesPort;
  final MessagingRepository _messaging;

  @override
  String get name => 'update_space_notes';

  @override
  String get description =>
      'Updates the shared notes/handoff document for a space. '
      'Write the full document content (it replaces the previous version). '
      'Use this to record decisions, state and instructions for the next '
      'human or agent who picks up this space.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {
        'type': 'string',
        'description': 'The workspace the space belongs to.',
      },
      'space_id': {
        'type': 'string',
        'description': 'The space whose notes to update.',
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
    'required': ['workspace_id', 'space_id', 'content'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final spaceId = arguments['space_id'];
    if (spaceId is! String) {
      return CallResult.error(
        'Missing or invalid argument: space_id (expected string)',
      );
    }
    final content = arguments['content'];
    if (content is! String || content.isEmpty) {
      return CallResult.error(
        'Missing or invalid argument: content (expected non-empty string)',
      );
    }
    final agentId = arguments['agent_id'] as String? ?? 'unknown';

    // Workspace isolation: a bare space_id is NOT proof of ownership.
    final spaces = await _messaging
        .watchSpacesByWorkspace(workspaceId)
        .first;
    if (!spaces.any((c) => c.id == spaceId)) {
      return CallResult.error('Space belongs to a different workspace.');
    }

    final note = await _notesPort.upsertNote(
      workspaceId: workspaceId,
      spaceId: spaceId,
      contentMarkdown: content,
      updatedBy: 'agent:$agentId',
    );

    return CallResult.success(
      jsonEncode({
        'space_id': spaceId,
        'content': note.contentMarkdown,
        'updated_by': note.updatedBy,
        'updated_at': note.updatedAt.toIso8601String(),
      }),
    );
  }
}
