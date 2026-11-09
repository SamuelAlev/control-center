import 'dart:convert';

import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/orphaned_wait_sweep.dart';
import 'package:drift/native.dart';
import 'package:test/test.dart';

/// A restart ends every in-memory wait; the boot sweep must close exactly the
/// rows recorded before this process started and nothing newer.
void main() {
  late WorkspaceDatabase db;
  final bootedAt = DateTime.utc(2026, 11, 9, 12);
  final before = bootedAt.subtract(const Duration(minutes: 5));
  final after = bootedAt.add(const Duration(minutes: 5));

  setUp(() async {
    db = WorkspaceDatabase.forTesting(
      NativeDatabase.memory(),
      workspaceId: 'ws',
    );
    // Rows without their space/conversation parents: the sweep reads only
    // message type, metadata and time.
    await db.customStatement('PRAGMA foreign_keys = OFF');
  });
  tearDown(() => db.close());

  Future<void> question(
    String id,
    DateTime createdAt, {
    bool answered = false,
  }) => db
      .into(db.conversationMessagesTable)
      .insert(
        ConversationMessagesTableCompanion.insert(
          id: id,
          spaceId: 's',
          conversationId: 'c',
          senderId: 'agent-1',
          senderType: 'agent',
          content: 'Which branch?',
          messageType: const Value('user_question'),
          metadata: Value(jsonEncode({'answered': answered})),
          createdAt: Value(createdAt),
        ),
      );

  Future<void> wait(String id, DateTime createdAt) =>
      db.notificationFeedDao.insertAndPrune(
        NotificationFeedTableCompanion.insert(
          id: id,
          workspaceId: 'ws',
          method: NotificationFeedDao.agentAwaitingInputMethod,
          paramsJson: jsonEncode({NotificationFeedDao.waitIdKey: 'wait-$id'}),
          createdAt: Value(createdAt),
        ),
      );

  Future<Map<String, dynamic>> metadataOf(String id) async {
    final row = await (db.select(
      db.conversationMessagesTable,
    )..where((t) => t.id.equals(id))).getSingle();
    return jsonDecode(row.metadata!) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> paramsOf(String id) async {
    final row = await (db.select(
      db.notificationFeedTable,
    )..where((t) => t.id.equals(id))).getSingle();
    return jsonDecode(row.paramsJson) as Map<String, dynamic>;
  }

  test(
    'closes the questions and waits a restart orphaned, and only those',
    () async {
      await question('q-old', before);
      await question('q-answered', before, answered: true);
      await question('q-new', after);
      await wait('w-old', before);
      await wait('w-new', after);

      final swept = await sweepOrphanedWaitsIn(db, bootedAt);

      expect(swept.questions, 1);
      expect(swept.waits, 1);
      expect(await metadataOf('q-old'), {'answered': true, 'expired': true});
      expect(await metadataOf('q-answered'), {'answered': true});
      expect(await metadataOf('q-new'), {'answered': false});
      expect((await paramsOf('w-old'))['resolved_at'], isA<String>());
      expect((await paramsOf('w-new')).containsKey('resolved_at'), isFalse);
    },
  );

  test('a second sweep finds nothing left to close', () async {
    await question('q-old', before);
    await wait('w-old', before);
    await sweepOrphanedWaitsIn(db, bootedAt);

    final again = await sweepOrphanedWaitsIn(db, bootedAt);

    expect(again.questions, 0);
    expect(again.waits, 0);
  });
}
