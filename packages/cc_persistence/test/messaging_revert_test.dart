import 'package:cc_persistence/database/app_database.dart';
import 'package:cc_persistence/database/daos/messaging_dao.dart';
import 'package:cc_persistence/repositories/dao_messaging_repository.dart';
import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:test/test.dart';

void main() {
  late AppDatabase db;
  late DaoMessagingRepository repo;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DaoMessagingRepository(MessagingDao(db));
    await db.into(db.channelsTable).insert(
          const ChannelsTableCompanion(id: Value('c'), name: Value('t')),
        );
    for (var i = 0; i < 6; i++) {
      await db.into(db.channelMessagesTable).insert(
            ChannelMessagesTableCompanion(
              id: Value('m$i'),
              channelId: const Value('c'),
              senderId: const Value('user'),
              senderType: const Value('user'),
              content: Value('msg $i'),
              createdAt: Value(DateTime.utc(2026, 1, 1, 0, 0, i)),
            ),
          );
    }
  });

  tearDown(() => db.close());

  test('revertConversationTo hides newer messages, keeps the target', () async {
    final reverted = await repo.revertConversationTo('c', 'm2');
    expect(reverted, ['m3', 'm4', 'm5']);

    final live = await repo.getMessages('c');
    expect(live.map((m) => m.id), ['m0', 'm1', 'm2']);
  });

  test('inclusive revert hides the target too', () async {
    final reverted = await repo.revertConversationTo('c', 'm2', inclusive: true);
    expect(reverted, ['m2', 'm3', 'm4', 'm5']);
    final live = await repo.getMessages('c');
    expect(live.map((m) => m.id), ['m0', 'm1']);
  });

  test('unrevert restores the most-recent batch', () async {
    await repo.revertConversationTo('c', 'm4'); // reverts m5
    await repo.revertConversationTo('c', 'm2'); // reverts m3, m4 (m5 older batch)

    final restored = await repo.unrevertConversation('c');
    expect(restored.toSet(), {'m3', 'm4'});

    final live = await repo.getMessages('c');
    // m5 stays reverted (older batch); m3/m4 came back.
    expect(live.map((m) => m.id), ['m0', 'm1', 'm2', 'm3', 'm4']);
  });

  test('unrevert is a no-op when nothing is reverted', () async {
    final restored = await repo.unrevertConversation('c');
    expect(restored, isEmpty);
  });

  test('reverting an unknown message changes nothing', () async {
    final reverted = await repo.revertConversationTo('c', 'nope');
    expect(reverted, isEmpty);
    final live = await repo.getMessages('c');
    expect(live.length, 6);
  });
}
