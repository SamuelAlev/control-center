import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/database/daos/messaging_dao.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/features/messaging/data/services/db_conversation_mode_resolver.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late DbConversationModeResolver resolver;
  late MessagingDao dao;

  setUp(() async {
    db = createTestDatabase();
    dao = MessagingDao(db);
    resolver = DbConversationModeResolver(dao);
  });

  tearDown(() async {
    await db.close();
  });

  // Helper: insert a channel with the given mode.
  Future<void> insertChannel(String id, String name, {ConversationMode mode = ConversationMode.chat}) async {
    await dao.insertChannel(ChannelsTableCompanion(
      id: Value(id),
      name: Value(name),
      mode: Value(mode.toDbValue()),
    ));
  }

  group('resolveForConversation', () {
    test('returns chat for null conversationId', () async {
      final mode = await resolver.resolveForConversation(null);
      expect(mode, ConversationMode.chat);
    });

    test('returns chat for empty conversationId', () async {
      final mode = await resolver.resolveForConversation('');
      expect(mode, ConversationMode.chat);
    });

    test('returns chat for unknown channel id', () async {
      final mode = await resolver.resolveForConversation('nonexistent');
      expect(mode, ConversationMode.chat);
    });

    test('returns chat for channel with default mode', () async {
      await insertChannel('ch-1', 'Test Channel');
      final mode = await resolver.resolveForConversation('ch-1');
      expect(mode, ConversationMode.chat);
    });

    test('returns review for channel in review mode', () async {
      await insertChannel('ch-review', 'Review Channel', mode: ConversationMode.review);
      final mode = await resolver.resolveForConversation('ch-review');
      expect(mode, ConversationMode.review);
    });

    test('returns plan for channel in plan mode', () async {
      await insertChannel('ch-plan', 'Plan Channel', mode: ConversationMode.plan);
      final mode = await resolver.resolveForConversation('ch-plan');
      expect(mode, ConversationMode.plan);
    });

    test('returns updated mode after mode change', () async {
      await insertChannel('ch-mode', 'Mode Channel');
      expect(await resolver.resolveForConversation('ch-mode'), ConversationMode.chat);

      await dao.updateChannelMode('ch-mode', ConversationMode.plan.toDbValue());
      expect(await resolver.resolveForConversation('ch-mode'), ConversationMode.plan);
    });
  });
}
