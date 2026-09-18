import 'dart:convert';

import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/ports/space_notes_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_mcp/src/tools/update_space_notes_tool.dart';
import 'package:test/test.dart';

void main() {
  late _FakeNotes notes;
  late _FakeMessaging messaging;
  late UpdateSpaceNotesTool tool;

  setUp(() {
    notes = _FakeNotes();
    messaging = _FakeMessaging();
    tool = UpdateSpaceNotesTool(
      notesPort: notes,
      messagingRepository: messaging,
    );
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({
      'space_id': 'space-1',
      'content': 'hello',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('refuses a space from another workspace', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'space_id': 'space-other',
      'content': 'hello',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('different workspace'));
  });

  test('writes the full document for a space in the workspace', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'space_id': 'space-1',
      'content': 'handoff notes',
      'agent_id': 'agent-1',
    });
    expect(result.isError, isFalse);
    expect(notes.lastContent, 'handoff notes');
    expect(notes.lastUpdatedBy, 'agent:agent-1');
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['content'], 'handoff notes');
  });
}

class _FakeNotes implements SpaceNotesPort {
  String? lastContent;
  String? lastUpdatedBy;

  @override
  Future<({String contentMarkdown, String updatedBy, DateTime updatedAt})>
  upsertNote({
    required String workspaceId,
    required String spaceId,
    required String contentMarkdown,
    required String updatedBy,
  }) async {
    lastContent = contentMarkdown;
    lastUpdatedBy = updatedBy;
    return (
      contentMarkdown: contentMarkdown,
      updatedBy: updatedBy,
      updatedAt: DateTime(2026),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}

class _FakeMessaging implements MessagingRepository {
  @override
  Stream<List<Space>> watchSpacesByWorkspace(String workspaceId) =>
      Stream.value([
        Space(
          id: 'space-1',
          name: 'Work',
          workspaceId: workspaceId,
          createdAt: DateTime(2026),
          updatedAt: DateTime(2026),
        ),
      ]);

  @override
  dynamic noSuchMethod(Invocation invocation) {}
}
