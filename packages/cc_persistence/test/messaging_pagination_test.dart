import 'package:cc_domain/features/messaging/domain/value_objects/message_page.dart';
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
    // Channel row.
    await db.into(db.channelsTable).insert(
          const ChannelsTableCompanion(id: Value('c'), name: Value('t')),
        );
  });

  tearDown(() => db.close());

  Future<void> seed(int count) async {
    // Interleave user + agent messages, one second apart so ordering is stable.
    for (var i = 0; i < count; i++) {
      await db.into(db.channelMessagesTable).insert(
            ChannelMessagesTableCompanion(
              id: Value('m$i'),
              channelId: const Value('c'),
              senderId: Value(i.isEven ? 'user' : 'agent'),
              senderType: Value(i.isEven ? 'user' : 'agent'),
              content: Value('msg $i'),
              messageType: Value(i.isEven ? 'text' : 'agent_turn'),
              createdAt: Value(DateTime.utc(2026, 1, 1, 0, 0, i)),
            ),
          );
    }
  }

  test('paginates newest-first windows with a working cursor', () async {
    await seed(200);

    final page1 = await repo.getTopLevelMessagePage('c', limit: 80);
    expect(page1.messages.length, 80);
    expect(page1.hasMore, isTrue);
    expect(page1.nextCursor, isNotNull);
    // Newest 80 are the page (display ascending → last is the very newest).
    expect(page1.messages.last.id, 'm199');

    final page2 =
        await repo.getTopLevelMessagePage('c', limit: 80, cursor: page1.nextCursor);
    expect(page2.messages.length, 80);
    expect(page2.hasMore, isTrue);
    // Page 2 is strictly older than page 1's oldest.
    expect(
      page2.messages.last.createdAt.isBefore(page1.messages.first.createdAt),
      isTrue,
    );
    // No overlap between pages.
    final ids1 = page1.messages.map((m) => m.id).toSet();
    final ids2 = page2.messages.map((m) => m.id).toSet();
    expect(ids1.intersection(ids2), isEmpty);

    final page3 =
        await repo.getTopLevelMessagePage('c', limit: 80, cursor: page2.nextCursor);
    // 200 total → 80 + 80 + 40.
    expect(page3.messages.length, greaterThanOrEqualTo(40));
    expect(page3.hasMore, isFalse);
    expect(page3.nextCursor, isNull);
  });

  test('short history returns a single complete page', () async {
    await seed(10);
    final page = await repo.getTopLevelMessagePage('c', limit: 80);
    expect(page.messages.length, 10);
    expect(page.hasMore, isFalse);
    expect(page.messages.first.id, 'm0');
    expect(page.messages.last.id, 'm9');
  });

  test('empty channel yields an empty page', () async {
    final page = await repo.getTopLevelMessagePage('c', limit: 80);
    expect(page, isA<MessagePage>());
    expect(page.messages, isEmpty);
    expect(page.hasMore, isFalse);
  });
}
