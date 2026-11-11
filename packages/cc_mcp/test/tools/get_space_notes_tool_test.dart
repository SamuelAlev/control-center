import 'dart:convert';

import 'package:cc_domain/features/messaging/domain/entities/space.dart';
import 'package:cc_domain/features/messaging/domain/ports/space_notes_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_mcp/src/tools/get_space_notes_tool.dart';
import 'package:test/test.dart';

void main() {
  late _FakeNotes notes;
  late _FakeMessaging messaging;
  late GetSpaceNotesTool tool;
  late Set<String> hidden;
  String? askedFor;

  setUp(() {
    notes = _FakeNotes();
    messaging = _FakeMessaging();
    hidden = {};
    askedFor = null;
    tool = GetSpaceNotesTool(
      notesPort: notes,
      messagingRepository: messaging,
      hiddenSpaces:
          ({required workspaceId, required callerConversationId}) async {
            askedFor = callerConversationId;
            return hidden;
          },
    );
  });

  test('refuses a review space the run\'s requester cannot see', () async {
    hidden = {'space-1'};
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'space_id': 'space-1',
      'caller_conversation_id': 'conv-1',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('cannot read this space'));
    expect(askedFor, 'conv-1');
  });

  test('missing workspace_id is refused', () async {
    final result = await tool.run({'space_id': 'space-1'});
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('workspace_id'));
  });

  test('refuses a space from another workspace', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'space_id': 'space-other',
    });
    expect(result.isError, isTrue);
    expect(result.content.first.text, contains('different workspace'));
  });

  test('returns null content when no notes exist', () async {
    final result = await tool.run({
      'workspace_id': 'ws-1',
      'space_id': 'space-1',
    });
    expect(result.isError, isFalse);
    final body = jsonDecode(result.content.first.text) as Map<String, dynamic>;
    expect(body['content'], isNull);
  });
}

class _FakeNotes implements SpaceNotesPort {
  @override
  Future<({String contentMarkdown, String updatedBy, DateTime updatedAt})?>
  getNote(String workspaceId, String spaceId) async => null;

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
