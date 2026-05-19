import 'dart:convert';
import 'dart:io';
import 'package:cc_domain/features/pr_review/domain/value_objects/pending_review_comment.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/demo/demo_pr_cache.dart';
import 'package:cc_server_core/src/demo/demo_pr_review_repository.dart';
import 'package:cc_server_core/src/demo/demo_runtime.dart';
import 'package:test/test.dart';
import '../helpers/test_database.dart';

/// The demo's offline PR surface, exercised against a real workspace
/// database.
///
/// This file exists because the write-back lane shipped with a dead button:
/// `markFileAsViewed` wrote a `viewed` BOOL into the cache JSON while the
/// decoder reads the `viewed_state` ENUM NAME — the write "succeeded" and the
/// watch stream re-emitted the old state. Nothing else covered this class.
void main() {
  late DirectoryShim dirs;
  late SeedDatabases dbs;
  const workspaceId = 'ws-demo-pr';
  late WorkspaceDatabase db;

  setUp(() async {
    dirs = DirectoryShim.create('cc_demo_pr_repo');
    dbs = openSeedDatabases(dirs.path);
    await dbs.global.workspaceRegistryDao.upsertWorkspace(
      WorkspacesTableCompanion(
        id: const Value(workspaceId),
        name: const Value('Parced'),
        createdAt: Value(DateTime.now()),
        updatedAt: Value(DateTime.now()),
      ),
    );
    db = dbs.workspaces.of(workspaceId);
    await seedFiles(db);
  });

  tearDown(() async {
    await dbs.close();
    await dirs.delete();
  });

  DemoPrReviewRepository build() => DemoPrReviewRepository(
    db: db,
    owner: 'parced',
    repo: 'closing',
    visitor: kDemoVisitorAuthor,
  );

  group('markFileAsViewed', () {
    test('flips the state the decoder actually reads (watch round-trip)', () async {
      final repo = build();

      final before = await repo.watchFiles(412).first;
      expect(before.first.viewerViewedState.name, 'unviewed');

      await repo.markFileAsViewed(
        prNumber: 412,
        externalId: 'PR_412',
        path: 'lib/escrow/timeline.dart',
        viewed: true,
      );

      // The watch lane re-decodes from the same row: the toggle must be
      // visible HERE, not only in the raw JSON. This is the exact regression.
      final after = await repo.watchFiles(412).first;
      expect(after.first.viewerViewedState.name, 'viewed');

      await repo.markFileAsViewed(
        prNumber: 412,
        externalId: 'PR_412',
        path: 'lib/escrow/timeline.dart',
        viewed: false,
      );
      final roundTrip = await repo.watchFiles(412).first;
      expect(roundTrip.first.viewerViewedState.name, 'unviewed');
    });
  });

  group('comments and reviews', () {
    test('posted comments land on the watch stream as the visitor', () async {
      final repo = build();
      final result = await repo.postReviewComment(
        prNumber: 412,
        commitSha: 'abc',
        path: 'lib/escrow/timeline.dart',
        line: 42,
        side: 'RIGHT',
        body: 'Two closings can share an acceptance date.',
      );
      expect(result['id'], isA<int>());

      final comments = await repo.watchReviewComments(412).first;
      final posted = comments.singleWhere((c) => c.id == result['id']);
      expect(posted.user?.login, 'you');
      expect(posted.body, contains('acceptance date'));
    });

    test('replies join the parent thread', () async {
      final repo = build();
      final parent = await repo.postReviewComment(
        prNumber: 412,
        commitSha: 'abc',
        path: 'lib/escrow/timeline.dart',
        line: 42,
        side: 'RIGHT',
        body: 'Blocking: the shared timeline.',
      );
      await repo.replyToReviewComment(
        prNumber: 412,
        parentCommentId: parent['id'] as int,
        body: 'Keying by acceptance event instead.',
      );

      final comments = await repo.watchReviewComments(412).first;
      final reply = comments.firstWhere(
        (c) => c.inReplyToId == parent['id'],
      );
      expect(reply.threadId, isNotNull);
      expect(reply.threadId, comments.firstWhere((c) => c.id == parent['id']).threadId);
    });

    test('submitting a review materializes its pending inline comments',
        () async {
      final repo = build();
      await repo.submitReview(
        prNumber: 412,
        event: 'REQUEST_CHANGES',
        body: 'One blocking concern, rest approved.',
        comments: const [
          PendingReviewComment(
            path: 'lib/escrow/timeline.dart',
            line: 30,
            side: 'RIGHT',
            body: 'Name the holiday table.',
          ),
        ],
      );

      final comments = await repo.watchReviewComments(412).first;
      expect(
        comments.any((c) => c.body == 'Name the holiday table.'),
        isTrue,
      );
      final reviews = await repo.watchReviews(412).first;
      expect(reviews.last.state.name, 'changesRequested');
      expect(reviews.last.author?.login, 'you');
    });

    test('concurrent writes do not collide ids or drop rows', () async {
      final repo = build();
      // Ten interleaved posts: the read-modify-write spans awaits, so without
      // the write lock several calls computed the same `_nextId` and the
      // later put dropped the earlier comment.
      final results = await Future.wait([
        for (var i = 0; i < 10; i++)
          repo.postReviewComment(
            prNumber: 412,
            commitSha: 'abc',
            path: 'lib/escrow/timeline.dart',
            line: 40 + i,
            side: 'RIGHT',
            body: 'comment $i',
          ),
      ]);
      final ids = results.map((r) => r['id'] as int).toSet();
      expect(ids, hasLength(10), reason: 'ids must be unique');

      final comments = await repo.watchReviewComments(412).first;
      expect(
        comments.where((c) => c.user?.login == 'you'),
        hasLength(10),
      );
    });
  });

  group('reactions', () {
    test('toggling on and off round-trips the visitor', () async {
      final repo = build();
      await repo.toggleReviewCommentReaction(
        commentId: 8801,
        prNumber: 412,
        content: 'THUMBS_UP',
        add: true,
      );
      var comments = await repo.watchReviewComments(412).first;
      var seeded = comments.firstWhere((c) => c.id == 8801);
      expect(seeded.reactions.any((r) => r.usernames.contains('you')), isTrue);

      await repo.toggleReviewCommentReaction(
        commentId: 8801,
        prNumber: 412,
        content: 'THUMBS_UP',
        add: false,
      );
      comments = await repo.watchReviewComments(412).first;
      seeded = comments.firstWhere((c) => c.id == 8801);
      expect(seeded.reactions.any((r) => r.usernames.contains('you')), isFalse);
    });
  });
}

/// Seeds one PR's files + one seeded review comment, in the exact cache shape
/// the fixtures use (`PrCacheCodec` keys).
Future<void> seedFiles(WorkspaceDatabase db) async {
  const ws = 'ws-demo-pr';
  const key = 'parced/closing#412';
  await db.cacheDao.put(
    ws,
    DemoPrCacheKind.files,
    key,
    jsonEncode([
      {
        'filename': 'lib/escrow/timeline.dart',
        'status': 'modified',
        'additions': 14,
        'deletions': 6,
        'patch': '@@ -1,3 +1,4 @@',
        'viewed_state': 'unviewed',
      },
    ]),
  );
  await db.cacheDao.put(
    ws,
    DemoPrCacheKind.reviewComments,
    key,
    jsonEncode([
      {
        'id': 8801,
        'body': 'Blocking: two closings share one acceptance date.',
        'user': {'login': 'maya-ok', 'avatar_url': '', 'name': 'Maya'},
        'path': 'lib/escrow/timeline.dart',
        'position': 42,
        'created_at': '2026-08-30T10:00:00Z',
        'side': 'RIGHT',
        'diff_hunk': '',
        'line': 42,
        'thread_id': 'thread-412-1',
        'reactions': <Map<String, dynamic>>[
          {'content': 'THUMBS_UP', 'count': 1, 'usernames': ['dferrer']},
        ],
      },
    ]),
  );
  await db.cacheDao.put(
    ws,
    DemoPrCacheKind.reviews,
    key,
    jsonEncode(<Map<String, dynamic>>[]),
  );
}

/// A scoped temp directory that cleans up after itself.
class DirectoryShim {
  DirectoryShim(this.path);
  factory DirectoryShim.create(String prefix) {
    final dir = Directory.systemTemp.createTempSync(prefix);
    return DirectoryShim(dir.path);
  }

  final String path;

  Future<void> delete() async {
    try {
      Directory(path).deleteSync(recursive: true);
    } on FileSystemException {
      // Windows may still hold a handle; best effort.
    }
  }
}
