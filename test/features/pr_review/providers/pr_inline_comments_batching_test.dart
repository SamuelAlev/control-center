import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pending_review_comment.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Records what a review submission carried, and can be told to fail.
class _RecordingRepository extends EmptyPrReviewRepository {
  const _RecordingRepository(this.log, {this.failWith});

  final List<
    ({int prNumber, String event, String? body, List<PendingReviewComment> c})
  >
  log;
  final Object? failWith;

  @override
  Future<void> submitReview({
    required int prNumber,
    required String event,
    String? body,
    List<PendingReviewComment> comments = const [],
  }) async {
    log.add((prNumber: prNumber, event: event, body: body, c: comments));
    if (failWith != null) {
      throw failWith!;
    }
  }

  @override
  Future<void> replyToReviewComment({
    required int prNumber,
    required int parentCommentId,
    required String body,
  }) async {
    log.add((
      prNumber: prNumber,
      event: 'REPLY:$parentCommentId',
      body: body,
      c: const [],
    ));
    if (failWith != null) {
      throw failWith!;
    }
  }

  @override
  Future<void> setReviewThreadResolved({
    required int prNumber,
    required String threadId,
    required bool resolved,
  }) async {
    log.add((
      prNumber: prNumber,
      event: 'RESOLVE:$threadId:$resolved',
      body: null,
      c: const [],
    ));
    if (failWith != null) {
      throw failWith!;
    }
  }

  @override
  Future<Map<String, dynamic>> postReviewComment({
    required int prNumber,
    required String commitSha,
    required String path,
    required int line,
    required String side,
    required String body,
    int? startLine,
    String? startSide,
  }) async {
    log.add((
      prNumber: prNumber,
      event: 'POST_COMMENT',
      body: body,
      c: const [],
    ));
    return {'id': 99};
  }
}

final _repo = Repo(
  id: 'r1',
  name: 'control-center',
  path: '/tmp/cc',
  remoteOwner: 'acme',
  remoteName: 'control-center',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

PullRequest _pr(int number) => PullRequest(
  id: number,
  number: number,
  title: 'A change',
  body: '',
  state: PrState.open,
  isDraft: false,
  author: null,
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  repoFullName: 'acme/control-center',
  htmlUrl: 'https://github.com/acme/control-center/pull/$number',
  headSha: 'deadbeef',
);

/// The PR identity every provider in this suite is keyed by.
const _prRef = (
  workspaceId: 'ws1',
  repoFullName: 'acme/control-center',
  number: 7,
);

ProviderContainer _container(PrReviewRepository repository) {
  final container = ProviderContainer(
    overrides: [
      prRepoRowProvider(_prRef).overrideWith((ref) => _repo),
      prRepositoryProvider(_prRef).overrideWith((ref) => repository),
      prDetailProvider(_prRef).overrideWith((ref) => Stream.value(_pr(7))),
    ],
  );
  addTearDown(container.dispose);
  return container;
}

Future<PrInlineCommentsController> _controller(
  ProviderContainer container,
) async {
  // The controller resolves its posting context from the PR stream, so let the
  // first value land before anything is written.
  container.listen(prDetailProvider(_prRef), (_, _) {}, fireImmediately: true);
  await container.read(prDetailProvider(_prRef).future);
  return container.read(prInlineCommentsControllerProvider(_prRef).notifier);
}

typedef _Call = ({
  int prNumber,
  String event,
  String? body,
  List<PendingReviewComment> c,
});

List<_Call> _log() => <_Call>[];

void main() {
  group('batched review comments', () {
    test('a batched comment is queued, not posted', () async {
      final log = _log();
      final container = _container(_RecordingRepository(log));
      final ctl = await _controller(container);

      final thread = ctl.create(
        filePath: 'lib/a.dart',
        line: 13,
        lineEnd: 19,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'x',
        suggestedCode: '',
        authorBody: 'This block needs a comment.',
        batched: true,
      );

      expect(thread.syncState, PrInlineSyncState.pendingReview);
      expect(thread.isPendingReview, isTrue);
      expect(ctl.pendingReviewThreads, hasLength(1));
      // Nothing reached the forge: that is the whole point of batching.
      expect(log, isEmpty);
    });

    test('an unbatched comment still posts immediately', () async {
      final log = _log();
      final container = _container(_RecordingRepository(log));
      final ctl = await _controller(container);

      ctl.create(
        filePath: 'lib/a.dart',
        line: 4,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'x',
        suggestedCode: '',
        authorBody: 'nit: spacing',
      );
      await Future<void>.delayed(Duration.zero);

      expect(ctl.pendingReviewThreads, isEmpty);
      expect(log.single.event, 'POST_COMMENT');
    });

    test('submitting sends every queued comment with the verdict', () async {
      final log = _log();
      final container = _container(_RecordingRepository(log));
      final ctl = await _controller(container);

      ctl.create(
        filePath: 'lib/a.dart',
        line: 13,
        lineEnd: 19,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'x',
        suggestedCode: '',
        authorBody: 'range comment',
        batched: true,
      );
      ctl.create(
        filePath: 'lib/b.dart',
        line: 3,
        side: 'LEFT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'y',
        suggestedCode: '',
        authorBody: 'single-line comment',
        batched: true,
      );

      await ctl.submitPendingReview(event: 'REQUEST_CHANGES', body: '  ');

      final call = log.single;
      expect(call.event, 'REQUEST_CHANGES');
      // A whitespace-only summary is no summary.
      expect(call.body, isNull);
      expect(call.c, hasLength(2));

      final ranged = call.c.first;
      // GitHub anchors a range at its LAST line and carries the first
      // separately — sending `line: 13` would attach the comment to the wrong
      // row and drop the range.
      expect(ranged.path, 'lib/a.dart');
      expect(ranged.line, 19);
      expect(ranged.startLine, 13);
      expect(ranged.startSide, 'RIGHT');
      expect(ranged.toWire()['start_line'], 13);

      final single = call.c.last;
      expect(single.line, 3);
      expect(single.side, 'LEFT');
      expect(single.startLine, isNull);
      expect(single.toWire().containsKey('start_line'), isFalse);

      // The forge owns them now; keeping local copies would double-render them
      // next to the ones that come back down the comment stream.
      expect(ctl.pendingReviewThreads, isEmpty);
      expect(ctl.threads, isEmpty);
    });

    test('a failed submit keeps the comments and marks them', () async {
      final log = _log();
      final container = _container(
        _RecordingRepository(log, failWith: StateError('422')),
      );
      final ctl = await _controller(container);

      ctl.create(
        filePath: 'lib/a.dart',
        line: 5,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'x',
        suggestedCode: '',
        authorBody: 'keep me',
        batched: true,
      );

      await expectLater(
        ctl.submitPendingReview(event: 'APPROVE'),
        throwsA(isA<StateError>()),
      );

      // Written work is never silently discarded by a failure.
      expect(ctl.threads, hasLength(1));
      expect(ctl.threads.single.syncState, PrInlineSyncState.error);
      expect(ctl.threads.single.entries.single.body, 'keep me');
    });

    test('discard drops queued comments and nothing else', () async {
      final log = _log();
      final container = _container(_RecordingRepository(log));
      final ctl = await _controller(container);

      ctl.create(
        filePath: 'lib/a.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'x',
        suggestedCode: '',
        authorBody: 'queued',
        batched: true,
      );
      final posted = ctl.create(
        filePath: 'lib/a.dart',
        line: 2,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'x',
        suggestedCode: '',
        authorBody: 'posted',
        batched: false,
      );
      await Future<void>.delayed(Duration.zero);

      ctl.discardPendingReview();

      expect(ctl.pendingReviewThreads, isEmpty);
      expect(ctl.threads.map((t) => t.id), [posted.id]);
    });

    test('replying to a forge conversation posts to the forge', () async {
      final log = _log();
      final container = _container(_RecordingRepository(log));
      final ctl = await _controller(container);

      // A synthesised server thread is NOT in the controller's state — the old
      // `reply` looked it up by id, found nothing and returned, so every reply
      // to a GitHub conversation silently did nothing.
      final serverThread = PrInlineThread(
        id: 'server-4242',
        filePath: 'lib/a.dart',
        line: 13,
        lineEnd: 19,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: '',
        suggestedCode: '',
        serverId: 4242,
        threadId: 'THREAD_1',
        syncState: PrInlineSyncState.synced,
        entries: [PrInlineEntry(id: 'e', author: 'them', body: 'why?')],
      );

      await ctl.replyTo(serverThread, '  because  ');

      // Trimmed, and addressed to the conversation's ROOT comment id.
      expect(log.single.event, 'REPLY:4242');
      expect(log.single.body, 'because');
    });

    test('replying to a local draft stays local', () async {
      final log = _log();
      final container = _container(_RecordingRepository(log));
      final ctl = await _controller(container);

      final draft = ctl.create(
        filePath: 'lib/a.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'x',
        suggestedCode: '',
        authorBody: 'queued',
        batched: true,
      );

      await ctl.replyTo(draft, 'a reply');

      expect(ctl.threads.single.entries, hasLength(2));
      expect(ctl.threads.single.entries.last.body, 'a reply');
      expect(log, isEmpty);
    });

    test('an empty reply is not posted', () async {
      final log = _log();
      final container = _container(_RecordingRepository(log));
      final ctl = await _controller(container);

      await ctl.replyTo(
        PrInlineThread(
          id: 'server-1',
          filePath: 'lib/a.dart',
          line: 1,
          side: 'RIGHT',
          kind: PrInlineThreadKind.comment,
          originalCode: '',
          suggestedCode: '',
          serverId: 1,
          entries: [PrInlineEntry(id: 'e', author: 'them', body: 'x')],
        ),
        '   ',
      );

      expect(log, isEmpty);
    });

    test('resolving a forge conversation writes through', () async {
      final log = _log();
      final container = _container(_RecordingRepository(log));
      final ctl = await _controller(container);

      await ctl.setServerThreadResolved(threadId: 'THREAD_1', resolved: true);

      expect(log.single.event, 'RESOLVE:THREAD_1:true');
    });

    test('a failed reply throws so the caller can keep the text', () async {
      final log = _log();
      final container = _container(
        _RecordingRepository(log, failWith: StateError('403')),
      );
      final ctl = await _controller(container);

      await expectLater(
        ctl.replyTo(
          PrInlineThread(
            id: 'server-1',
            filePath: 'lib/a.dart',
            line: 1,
            side: 'RIGHT',
            kind: PrInlineThreadKind.comment,
            originalCode: '',
            suggestedCode: '',
            serverId: 1,
            entries: [PrInlineEntry(id: 'e', author: 'them', body: 'x')],
          ),
          'keep me',
        ),
        throwsA(isA<StateError>()),
      );
    });

    test('canPost is false without a connected pull request', () {
      final container = ProviderContainer(
        overrides: [
          prRepositoryProvider(_prRef).overrideWith((ref) => null),
          prDetailProvider(_prRef).overrideWith((ref) => Stream.value(null)),
        ],
      );
      addTearDown(container.dispose);
      final ctl = container.read(
        prInlineCommentsControllerProvider(_prRef).notifier,
      );

      expect(ctl.canPost, isFalse);
      expect(
        ctl.submitPendingReview(event: 'APPROVE'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
