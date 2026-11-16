import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/review_space_association.dart';
import 'package:cc_domain/core/domain/repositories/review_space_repository.dart';
import 'package:cc_host/cc_host.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/catalog/conversation_outline_ops.dart';
import 'package:cc_server_core/src/catalog/pr_data_gate.dart';
import 'package:cc_server_core/src/catalog/pr_repo_visibility.dart';
import 'package:test/test.dart';

import '../helpers/test_database.dart';

/// `messaging.getConversationOutline` and `messaging.watchMessagesRange` read
/// a conversation's content: only for a caller the space gate admits, only
/// for a space of the call's workspace, and only for a conversation that
/// belongs to the space named.
void main() {
  late GlobalDatabase global;
  late WorkspaceDatabaseManager dbs;
  late DaoMessagingRepository messaging;
  late RepoOp outline;
  late WatchQuery range;
  late String space;
  late String conv;
  late String otherSpace;
  late String otherConv;
  late String foreignSpace;
  late String foreignConv;

  setUp(() async {
    global = createTestGlobalDatabase();
    dbs = createTestWorkspaceDatabases(global: global);
    await seedTestWorkspace(global, dbs, 'ws1');
    await seedTestWorkspace(global, dbs, 'ws2');
    messaging = DaoMessagingRepository(dbs);
    final conversations = DaoConversationRepository(dbs);

    Future<(String, String)> spaceWith(String ws, List<String> ids) async {
      final s = (await messaging.createSpace(ws, 'chat', const [])).id;
      final c = await messaging.ensureStandingConversation(ws, s);
      for (final id in ids) {
        await messaging.sendMessage(
          workspaceId: ws,
          spaceId: s,
          conversationId: c,
          content: id,
          senderId: 'gina',
          senderType: 'user',
          id: id,
        );
      }
      return (s, c);
    }

    (space, conv) = await spaceWith('ws1', ['m1', 'm2', 'm3']);
    (otherSpace, otherConv) = await spaceWith('ws1', ['o1']);
    (foreignSpace, foreignConv) = await spaceWith('ws2', ['f1']);

    final pack = buildConversationOutlineOps(
      messaging: messaging,
      conversations: conversations,
      prData: PrDataGate(
        reviewSpaces: const _NoReviewSpaces(),
        resolve: (_, _) async => RepoVisibility.empty,
        watch: (_, _) => const Stream.empty(),
        // nora may not read any space's repositories.
        spaceRead: const _RefuseUser('nora'),
      ),
    );
    outline = pack.ops.single;
    range = pack.watches.single;
  });

  tearDown(() async {
    await dbs.closeAll();
    await global.close();
  });

  Future<Object?> callOutline(
    String user, {
    required String space,
    required String conv,
    String ws = 'ws1',
  }) => outline.handler(
    RepoOpContext(
      args: {'space_id': space, 'conversation_id': conv},
      workspaceId: ws,
      deviceId: 'dev',
      userId: user,
    ),
  );

  Future<Map<String, dynamic>> firstRange(
    String user, {
    required String space,
    required String conv,
    required String anchor,
    Object? before = 5,
    Object? after = 5,
    String ws = 'ws1',
  }) => range
      .handler(
        WatchQueryContext(
          args: {
            'space_id': space,
            'conversation_id': conv,
            'anchor_id': anchor,
            'before': before,
            'after': after,
          },
          workspaceId: ws,
          deviceId: 'dev',
          userId: user,
        ),
      )
      .first;

  test('the outline is one compact array per live message', () async {
    final result =
        (await callOutline('gina', space: space, conv: conv))!
            as Map<String, dynamic>;
    final entries = result['entries'] as List;
    expect([for (final e in entries) (e as List).first], ['m1', 'm2', 'm3']);
    final first = entries.first as List;
    expect(first, hasLength(10));
    expect(first[1], isA<int>());
    expect(first.sublist(2), ['gina', 'user', 'text', 2, null, null, 0, 0]);
  });

  test('the range emits the lite wire with both edges', () async {
    final frame = await firstRange(
      'gina',
      space: space,
      conv: conv,
      anchor: 'm2',
      before: 0,
      after: 0,
    );
    final messages = frame['messages'] as List;
    expect((messages.single as Map)['id'], 'm2');
    expect((messages.single as Map)['revision'], 0);
    expect(frame['has_older'], isTrue);
    expect(frame['has_newer'], isTrue);
  });

  test('counts clamp to 0..200', () async {
    final frame = await firstRange(
      'gina',
      space: space,
      conv: conv,
      anchor: 'm2',
      before: -4,
      after: 100000,
    );
    expect(
      [for (final m in frame['messages'] as List) (m as Map)['id']],
      ['m2', 'm3'],
    );
    expect(frame['has_older'], isTrue);
  });

  test('a caller the space gate refuses reads neither', () async {
    await expectLater(
      callOutline('nora', space: space, conv: conv),
      throwsA(isA<AuthException>()),
    );
    await expectLater(
      firstRange('nora', space: space, conv: conv, anchor: 'm1'),
      throwsA(isA<AuthException>()),
    );
  });

  test("another workspace's space is refused", () async {
    await expectLater(
      callOutline('gina', space: foreignSpace, conv: foreignConv),
      throwsA(isA<WorkspaceMismatchException>()),
    );
    await expectLater(
      firstRange('gina', space: foreignSpace, conv: foreignConv, anchor: 'f1'),
      throwsA(isA<WorkspaceMismatchException>()),
    );
  });

  test('a conversation of another space is refused', () async {
    // The caller may read `space`, and names another space's conversation.
    await expectLater(
      callOutline('gina', space: space, conv: otherConv),
      throwsA(isA<NotFoundException>()),
    );
    await expectLater(
      firstRange('gina', space: space, conv: otherConv, anchor: 'o1'),
      throwsA(isA<NotFoundException>()),
    );
    // Under its own space it reads.
    final own =
        (await callOutline('gina', space: otherSpace, conv: otherConv))!
            as Map<String, dynamic>;
    expect((own['entries'] as List).single, isA<List<Object?>>());
    // Another workspace's conversation, under a space of this one.
    await expectLater(
      callOutline('gina', space: space, conv: foreignConv),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('the anchor of another conversation is not found', () async {
    await expectLater(
      firstRange('gina', space: space, conv: conv, anchor: 'o1'),
      throwsA(isA<NotFoundException>()),
    );
    await expectLater(
      firstRange('gina', space: space, conv: conv, anchor: 'missing'),
      throwsA(isA<NotFoundException>()),
    );
  });

  test('counts must be numbers', () async {
    await expectLater(
      firstRange('gina', space: space, conv: conv, anchor: 'm1', before: null),
      throwsA(isA<ValidationException>()),
    );
  });
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
}
