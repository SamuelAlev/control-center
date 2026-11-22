import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_domain/features/notifications/domain/repositories/notification_feed_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/catalog/conversation_read_ops.dart';
import 'package:cc_server_core/src/catalog/pr_data_gate.dart';
import 'package:cc_server_core/src/catalog/pr_repo_visibility.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

/// `conversation_read.markRead` moves only the caller's cursor in one
/// conversation of the call's workspace, behind the space gate of the space
/// that owns it; `conversation_read.watchUserReads` streams only the caller's
/// own cursors.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late _AckLog acks;
  late RepoOp markRead;
  late WatchQuery watchReads;
  late String space;
  late String conv;
  late String otherConv;
  late String foreignConv;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws1');
    await seedTestWorkspace(global, dbs, 'ws2');
    final messaging = DaoMessagingRepository(dbs);
    final conversations = DaoConversationRepository(dbs);

    Future<String> conversationWithReply(String ws, String spaceId) async {
      final c = (await conversations.create(
        workspaceId: ws,
        spaceId: spaceId,
        title: 'thread',
      )).id;
      await messaging.sendMessage(
        workspaceId: ws,
        spaceId: spaceId,
        conversationId: c,
        content: 'hello',
        senderId: 'agent-1',
        senderType: 'agent',
      );
      return c;
    }

    space = (await messaging.createSpace('ws1', 'chat', const [])).id;
    conv = await conversationWithReply('ws1', space);
    otherConv = await conversationWithReply('ws1', space);
    final foreignSpace = (await messaging.createSpace(
      'ws2',
      'chat',
      const [],
    )).id;
    foreignConv = await conversationWithReply('ws2', foreignSpace);

    acks = _AckLog();
    final pack = buildConversationReadOps(
      reads: DaoConversationReadRepository(dbs),
      conversations: conversations,
      notificationFeed: acks,
      prData: PrDataGate(
        reviewSpaces: const _NoReviewSpaces(),
        resolve: (_, _) async => RepoVisibility.empty,
        watch: (_, _) => const Stream.empty(),
        // nora may not read any space.
        spaceRead: const _RefuseUser('nora'),
      ),
    );
    markRead = pack.ops.single;
    watchReads = pack.watches.single;
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Future<Object?> mark(String user, String conversation, {String ws = 'ws1'}) =>
      markRead.handler(
        RepoOpContext(
          args: {'workspace_id': ws, 'conversation_id': conversation},
          workspaceId: ws,
          deviceId: 'dev',
          userId: user,
        ),
      );

  Future<Set<String>> readsOf(String user) async {
    final frame = await watchReads
        .handler(
          WatchQueryContext(
            args: const {'workspace_id': 'ws1'},
            workspaceId: 'ws1',
            deviceId: 'dev',
            userId: user,
          ),
        )
        .first;
    return {
      for (final row in frame['reads'] as List)
        (row as Map)['conversation_id'] as String,
    };
  }

  test('reading one conversation leaves the others unread', () async {
    expect(await mark('gina', conv), {'ok': true});

    expect(await readsOf('gina'), {conv});
    expect(acks.calls, [('ws1', 'gina', space, conv)]);
  });

  test('a cursor is the reader\'s own', () async {
    await mark('gina', conv);

    expect(await readsOf('ivan'), isEmpty);
  });

  test('the space gate refuses a reader it does not admit', () async {
    await expectLater(mark('nora', conv), throwsA(isA<AuthException>()));

    expect(await readsOf('nora'), isEmpty);
    expect(acks.calls, isEmpty);
  });

  test('another workspace\'s conversation is not found', () async {
    await expectLater(
      mark('gina', foreignConv),
      throwsA(isA<NotFoundException>()),
    );

    expect(acks.calls, isEmpty);
  });

  test('the cursor sits at the newest message', () async {
    await mark('gina', otherConv);
    final frame = await watchReads
        .handler(
          const WatchQueryContext(
            args: {'workspace_id': 'ws1'},
            workspaceId: 'ws1',
            deviceId: 'dev',
            userId: 'gina',
          ),
        )
        .first;
    final row = (frame['reads'] as List).single as Map;
    expect(row['conversation_id'], otherConv);
    expect(FeedPosition.fromJson(row['last_read']), isNotNull);
  });
}

class _AckLog implements NotificationFeedRepository {
  final calls = <(String, String, String, String)>[];

  @override
  Future<void> markConversationMessagesRead(
    String workspaceId,
    String userId, {
    required String spaceId,
    required String conversationId,
  }) async => calls.add((workspaceId, userId, spaceId, conversationId));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoReviewSpaces implements ReviewSpaceRepository {
  const _NoReviewSpaces();

  @override
  Stream<List<ReviewSpaceAssociation>> watchAllBySpace(
    String workspaceId,
    String spaceId,
  ) => Stream.value(const []);

  @override
  Stream<List<ReviewSpaceAssociation>> watchByWorkspace(String workspaceId) =>
      Stream.value(const []);

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _RefuseUser implements SpaceReadGate {
  const _RefuseUser(this.userId);

  final String userId;

  @override
  Future<void> require(
    String workspaceId,
    String userId,
    String spaceId,
  ) async {
    if (userId == this.userId) {
      throw const AuthException('You may not read this space.');
    }
  }

  @override
  Future<Set<String>> unreadable(String workspaceId, String userId) async =>
      const {};

  @override
  Future<List<String>> exposedBy(String workspaceId, String? spaceId) async =>
      const [];
}
