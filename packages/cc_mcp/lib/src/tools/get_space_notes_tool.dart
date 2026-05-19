import 'dart:convert';

import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/ports/space_notes_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// MCP tool that reads a space's shared Notes / handoff document (PRD 16
/// §11). Agents call this to pick up context a human (or another agent) left
/// behind, so a handoff carries state instead of re-explaining.
class GetSpaceNotesTool extends McpTool {
  /// Creates a [GetSpaceNotesTool].
  GetSpaceNotesTool({
    required SpaceNotesPort notesPort,
    required MessagingRepository messagingRepository,
  }) : _notesPort = notesPort,
       _messaging = messagingRepository;

  final SpaceNotesPort _notesPort;
  final MessagingRepository _messaging;

  @override
  String get name => 'get_space_notes';

  @override
  String get description =>
      'Reads the shared notes/handoff document for a space. '
      'Use this to pick up context from a prior human or agent turn — '
      'decisions, TODOs and state that survived across the handoff.';

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
        'description': 'The space whose notes to read.',
      },
    },
    'required': ['workspace_id', 'space_id'],
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

    // Workspace isolation: a bare space_id is NOT proof of ownership.
    final spaces = await _messaging
        .watchSpacesByWorkspace(workspaceId)
        .first;
    if (!spaces.any((c) => c.id == spaceId)) {
      return CallResult.error('Space belongs to a different workspace.');
    }

    final note = await _notesPort.getNote(workspaceId, spaceId);

    if (note == null) {
      return CallResult.success(
        jsonEncode({
          'space_id': spaceId,
          'content': null,
          'message': 'No notes document exists for this space yet.',
        }),
      );
    }

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
