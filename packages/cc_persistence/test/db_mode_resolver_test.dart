import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_persistence/repositories/db_mode_resolver.dart';
import 'package:test/test.dart';

import 'helpers/test_database.dart';

void main() {
  const ws = 'ws-1';
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DbModeResolver resolver;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, ws);
    resolver = DbModeResolver(dbs);
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  MessagingDao dao(String workspaceId) => dbs.of(workspaceId).messagingDao;

  // Helper: insert a channel with the given mode.
  Future<void> insertChannel(
    String id,
    String name, {
    Mode mode = Mode.chat,
  }) async {
    await dao(ws).insertChannel(
      ChannelsTableCompanion(
        id: Value(id),
        name: Value(name),
        workspaceId: const Value(ws),
        mode: Value(mode.toDbValue()),
      ),
    );
  }

  group('resolveForConversation', () {
    test('returns chat for null conversationId', () async {
      final mode = await resolver.resolveForConversation(ws, null);
      expect(mode, Mode.chat);
    });

    test('returns chat for empty conversationId', () async {
      final mode = await resolver.resolveForConversation(ws, '');
      expect(mode, Mode.chat);
    });

    test('returns chat for unknown channel id', () async {
      final mode = await resolver.resolveForConversation(ws, 'nonexistent');
      expect(mode, Mode.chat);
    });

    test('returns chat for channel with default mode', () async {
      await insertChannel('ch-1', 'Test Channel');
      final mode = await resolver.resolveForConversation(ws, 'ch-1');
      expect(mode, Mode.chat);
    });

    test('returns review for channel in review mode', () async {
      await insertChannel('ch-review', 'Review Channel', mode: Mode.review);
      final mode = await resolver.resolveForConversation(ws, 'ch-review');
      expect(mode, Mode.review);
    });

    test('returns plan for channel in plan mode', () async {
      await insertChannel('ch-plan', 'Plan Channel', mode: Mode.plan);
      final mode = await resolver.resolveForConversation(ws, 'ch-plan');
      expect(mode, Mode.plan);
    });

    test('returns updated mode after mode change', () async {
      await insertChannel('ch-mode', 'Mode Channel');
      expect(await resolver.resolveForConversation(ws, 'ch-mode'), Mode.chat);

      await dao(ws).updateChannelMode('ch-mode', Mode.plan.toDbValue());
      expect(await resolver.resolveForConversation(ws, 'ch-mode'), Mode.plan);
    });
  });
}
