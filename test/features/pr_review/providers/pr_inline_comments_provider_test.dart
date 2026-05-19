import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_inline_thread.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/providers/pr_inline_comments_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// PR identities the suite keys its provider families by: same number in two
/// different repos, plus a plain second key for isolation checks.
const _prRefA = (workspaceId: 'ws1', repoFullName: 'acme/one', number: 1);
const _prRefB = (workspaceId: 'ws1', repoFullName: 'acme/two', number: 2);
const _prRef42 = (workspaceId: 'ws1', repoFullName: 'acme/one', number: 42);

void main() {
  group('PrInlineCommentsController', () {
    late PrInlineCommentsController controller;
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          activeRepoProvider.overrideWith((ref) => null),
          prDetailProvider(_prRefA).overrideWith((ref) => Stream.value(null)),
          prReviewRepositoryProvider.overrideWithValue(
            const EmptyPrReviewRepository(),
          ),
        ],
      );
      controller = container.read(
        prInlineCommentsControllerProvider(_prRefA).notifier,
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('starts with no threads', () {
      expect(controller.threads, isEmpty);
    });

    test('create adds a thread and returns it', () {
      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 42,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'print("hello");',
        suggestedCode: 'print("hello");',
        authorBody: 'Consider using a logger.',
      );

      expect(thread.filePath, 'lib/main.dart');
      expect(thread.line, 42);
      expect(thread.lineEnd, 42);
      expect(thread.side, 'RIGHT');
      expect(thread.kind, PrInlineThreadKind.comment);
      expect(thread.originalCode, 'print("hello");');
      expect(thread.entries.length, 1);
      expect(thread.entries.first.author, 'You');
      expect(thread.entries.first.body, 'Consider using a logger.');
      expect(thread.resolved, false);
      expect(controller.threads.length, 1);
    });

    test('create with lineEnd anchors multi-line range', () {
      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 10,
        lineEnd: 15,
        side: 'RIGHT',
        kind: PrInlineThreadKind.suggestion,
        originalCode: 'old code',
        suggestedCode: 'new code',
        authorBody: 'Replace this block.',
      );

      expect(thread.line, 10);
      expect(thread.lineEnd, 15);
      expect(thread.isMultiLine, true);
    });

    test('create assigns unique incrementing IDs', () {
      final t1 = controller.create(
        filePath: 'a.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'a',
        suggestedCode: 'a',
        authorBody: 'a',
      );
      final t2 = controller.create(
        filePath: 'b.dart',
        line: 2,
        side: 'LEFT',
        kind: PrInlineThreadKind.suggestion,
        originalCode: 'b',
        suggestedCode: 'b',
        authorBody: 'b',
      );

      expect(t1.id, isNot(equals(t2.id)));
      expect(controller.threads.length, 2);
    });

    test('create stamps the signed-in GitHub user as the author', () async {
      // A just-written comment must read as its real author (login + avatar),
      // not an anonymous "You", while the forge round-trips.
      final identified = ProviderContainer(
        overrides: [
          activeRepoProvider.overrideWith((ref) => null),
          prDetailProvider(_prRefA).overrideWith((ref) => Stream.value(null)),
          prReviewRepositoryProvider.overrideWithValue(
            const EmptyPrReviewRepository(),
          ),
          githubUserProvider.overrideWith(
            (ref) async => const GitHubUser(
              login: 'octocat',
              avatarUrl: 'https://example.com/octocat.png',
            ),
          ),
        ],
      );
      addTearDown(identified.dispose);
      // Let the identity resolve: entries read its latest value at write time.
      await identified.read(githubUserProvider.future);
      final ctl = identified.read(
        prInlineCommentsControllerProvider(_prRefA).notifier,
      );

      final thread = ctl.create(
        filePath: 'lib/foo.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Nice!',
      );

      expect(thread.entries.first.author, 'octocat');
      expect(
        thread.entries.first.authorAvatarUrl,
        'https://example.com/octocat.png',
      );

      ctl.reply(threadId: thread.id, body: 'following up');
      final reply = ctl.byId(thread.id)!.entries.last;
      expect(reply.author, 'octocat');
      expect(reply.authorAvatarUrl, 'https://example.com/octocat.png');
    });

    test('entries fall back to You while the identity is unresolved', () {
      // The default container's github.currentUser lookup has no server to
      // answer it here, so the neutral placeholder author stays.
      final thread = controller.create(
        filePath: 'lib/foo.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Nice!',
      );

      expect(thread.entries.first.author, 'You');
      expect(thread.entries.first.authorAvatarUrl, isNull);
    });

    test('forFile returns threads for a given file', () {
      controller.create(
        filePath: 'lib/a.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'a',
        suggestedCode: 'a',
        authorBody: 'A',
      );
      controller.create(
        filePath: 'lib/b.dart',
        line: 2,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'b',
        suggestedCode: 'b',
        authorBody: 'B',
      );
      controller.create(
        filePath: 'lib/a.dart',
        line: 3,
        side: 'LEFT',
        kind: PrInlineThreadKind.suggestion,
        originalCode: 'a2',
        suggestedCode: 'a2',
        authorBody: 'A2',
      );

      final aThreads = controller.forFile('lib/a.dart');
      expect(aThreads.length, 2);
      expect(aThreads.every((t) => t.filePath == 'lib/a.dart'), true);

      final bThreads = controller.forFile('lib/b.dart');
      expect(bThreads.length, 1);
      expect(bThreads.first.filePath, 'lib/b.dart');

      final empty = controller.forFile('lib/nonexistent.dart');
      expect(empty, isEmpty);
    });

    test('forAnchor finds thread covering the given line/side', () {
      controller.create(
        filePath: 'lib/main.dart',
        line: 10,
        lineEnd: 20,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'block',
        suggestedCode: 'block',
        authorBody: 'Consider refactoring.',
      );

      final found = controller.forAnchor(
        filePath: 'lib/main.dart',
        line: 15,
        side: 'RIGHT',
      );
      expect(found, isNotNull);
      expect(found!.line, 10);
      expect(found.lineEnd, 20);
    });

    test('forAnchor returns null when line is outside range', () {
      controller.create(
        filePath: 'lib/main.dart',
        line: 10,
        lineEnd: 20,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'block',
        suggestedCode: 'block',
        authorBody: 'block',
      );

      final notFound = controller.forAnchor(
        filePath: 'lib/main.dart',
        line: 25,
        side: 'RIGHT',
      );
      expect(notFound, null);
    });

    test('forAnchor returns null when side differs', () {
      controller.create(
        filePath: 'lib/main.dart',
        line: 10,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'body',
      );

      final notFound = controller.forAnchor(
        filePath: 'lib/main.dart',
        line: 10,
        side: 'LEFT',
      );
      expect(notFound, null);
    });

    test('reply adds an entry to the thread', () {
      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'First',
      );

      controller.reply(threadId: thread.id, body: 'Second', author: 'Bob');

      final updatedThread = controller.state.threads.firstWhere(
        (t) => t.id == thread.id,
      );
      expect(updatedThread.entries.length, 2);
      expect(updatedThread.entries[1].author, 'Bob');
      expect(updatedThread.entries[1].body, 'Second');
    });

    test('reply ignores empty/whitespace body', () {
      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'First',
      );

      controller.reply(threadId: thread.id, body: '   ');
      expect(thread.entries.length, 1);
    });

    test('reply ignores nonexistent threadId', () {
      controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'First',
      );

      controller.reply(threadId: 'nonexistent', body: 'Hello');
      expect(controller.threads.first.entries.length, 1);
    });

    test('toggleResolved toggles the resolved flag', () {
      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'First',
      );

      expect(thread.resolved, false);

      controller.toggleResolved(thread.id);

      final updated = controller.threads.first;
      expect(updated.resolved, true);

      controller.toggleResolved(thread.id);

      final toggledBack = controller.threads.first;
      expect(toggledBack.resolved, false);
    });

    test('toggleResolved ignores nonexistent threadId', () {
      controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'First',
      );

      controller.toggleResolved('nonexistent');
      expect(controller.threads.first.resolved, false);
    });

    test('threads getter returns unmodifiable view', () {
      final threads = controller.threads;
      expect(threads, isA<List<PrInlineThread>>());
      expect(threads.isEmpty, true);
    });

    test('isSuggestion is true for suggestion kind', () {
      final t = controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.suggestion,
        originalCode: 'old',
        suggestedCode: 'new',
        authorBody: 'Try this instead.',
      );

      expect(t.isSuggestion, true);
      expect(t.kind, PrInlineThreadKind.suggestion);
    });
  });

  group('PrInlineCommentsController — updateEntry', () {
    late PrInlineCommentsController controller;
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          activeRepoProvider.overrideWith((ref) => null),
          prDetailProvider(_prRefA).overrideWith((ref) => Stream.value(null)),
          prReviewRepositoryProvider.overrideWithValue(
            const EmptyPrReviewRepository(),
          ),
        ],
      );
      controller = container.read(
        prInlineCommentsControllerProvider(_prRefA).notifier,
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('updateEntry modifies entry body', () {
      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'old',
        suggestedCode: 'old',
        authorBody: 'Original body',
      );

      controller.updateEntry(
        threadId: thread.id,
        entryId: thread.entries.first.id,
        newBody: 'Updated body',
      );

      expect(controller.threads.first.entries.first.body, 'Updated body');
    });

    test('updateEntry ignores nonexistent threadId', () {
      controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'First',
      );

      controller.updateEntry(
        threadId: 'nonexistent',
        entryId: 'some-entry',
        newBody: 'New',
      );

      expect(controller.threads.first.entries.first.body, 'First');
    });

    test('updateEntry ignores nonexistent entryId', () {
      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'First',
      );

      controller.updateEntry(
        threadId: thread.id,
        entryId: 'nonexistent-entry',
        newBody: 'New',
      );

      expect(controller.threads.first.entries.first.body, 'First');
    });
  });

  group('PrInlineCommentsController — syncState', () {
    late PrInlineCommentsController controller;
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          activeRepoProvider.overrideWith((ref) => null),
          prDetailProvider(_prRefA).overrideWith((ref) => Stream.value(null)),
          prReviewRepositoryProvider.overrideWithValue(
            const EmptyPrReviewRepository(),
          ),
        ],
      );
      controller = container.read(
        prInlineCommentsControllerProvider(_prRefA).notifier,
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('create without context sets syncState to local', () {
      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Test',
      );

      expect(thread.syncState, PrInlineSyncState.local);
    });

    test('isMultiLine is false when line == lineEnd', () {
      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 5,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Test',
      );

      expect(thread.isMultiLine, false);
    });

    test('toggleResolved after multiple operations', () {
      final t1 = controller.create(
        filePath: 'a.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'a',
        suggestedCode: 'a',
        authorBody: 'a',
      );
      controller.create(
        filePath: 'b.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'b',
        suggestedCode: 'b',
        authorBody: 'b',
      );

      controller.toggleResolved(t1.id);
      expect(controller.threads[0].resolved, true);
      expect(controller.threads[1].resolved, false);
    });

    test('forAnchor with multiple threads across files', () {
      controller.create(
        filePath: 'a.dart',
        line: 10,
        lineEnd: 15,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'a',
        suggestedCode: 'a',
        authorBody: 'a',
      );
      controller.create(
        filePath: 'b.dart',
        line: 10,
        lineEnd: 15,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'b',
        suggestedCode: 'b',
        authorBody: 'b',
      );

      final foundA = controller.forAnchor(
        filePath: 'a.dart',
        line: 12,
        side: 'RIGHT',
      );
      expect(foundA, isNotNull);

      final foundB = controller.forAnchor(
        filePath: 'b.dart',
        line: 12,
        side: 'RIGHT',
      );
      expect(foundB, isNotNull);

      final notFound = controller.forAnchor(
        filePath: 'c.dart',
        line: 12,
        side: 'RIGHT',
      );
      expect(notFound, isNull);
    });
  });

  group('PrInlineSyncState enum', () {
    test('has five values', () {
      expect(PrInlineSyncState.values, hasLength(5));
      expect(PrInlineSyncState.values, contains(PrInlineSyncState.local));
      expect(
        PrInlineSyncState.values,
        contains(PrInlineSyncState.pendingReview),
      );
      expect(PrInlineSyncState.values, contains(PrInlineSyncState.pending));
      expect(PrInlineSyncState.values, contains(PrInlineSyncState.synced));
      expect(PrInlineSyncState.values, contains(PrInlineSyncState.error));
    });
  });

  group('PrInlineThreadKind enum', () {
    test('has two values', () {
      expect(PrInlineThreadKind.values, hasLength(2));
      expect(PrInlineThreadKind.values, contains(PrInlineThreadKind.comment));
      expect(
        PrInlineThreadKind.values,
        contains(PrInlineThreadKind.suggestion),
      );
    });
  });

  group('prInlineCommentsControllerProvider', () {
    test('creates a unique controller per PR number', () {
      final container = ProviderContainer(
        overrides: [
          activeRepoProvider.overrideWithValue(null),
          prDetailProvider(_prRefA).overrideWith((ref) => const Stream.empty()),
          prDetailProvider(_prRefB).overrideWith((ref) => const Stream.empty()),
          prReviewRepositoryProvider.overrideWith(
            (ref) => const EmptyPrReviewRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final c1 = container.read(prInlineCommentsControllerProvider(_prRefA).notifier);
      final c2 = container.read(prInlineCommentsControllerProvider(_prRefB).notifier);

      expect(identical(c1, c2), false);
    });

    test('returns same controller for same PR number', () {
      final container = ProviderContainer(
        overrides: [
          activeRepoProvider.overrideWithValue(null),
          prDetailProvider(_prRef42).overrideWith((ref) => const Stream.empty()),
          prReviewRepositoryProvider.overrideWith(
            (ref) => const EmptyPrReviewRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);

      final a = container.read(prInlineCommentsControllerProvider(_prRef42).notifier);
      final b = container.read(prInlineCommentsControllerProvider(_prRef42).notifier);

      expect(identical(a, b), true);
    });
  });

  group('PrInlineCommentsController — retryPost', () {
    late PrInlineCommentsController controller;
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          activeRepoProvider.overrideWith((ref) => null),
          prDetailProvider(_prRefA).overrideWith((ref) => Stream.value(null)),
          prReviewRepositoryProvider.overrideWithValue(
            const EmptyPrReviewRepository(),
          ),
        ],
      );
      controller = container.read(
        prInlineCommentsControllerProvider(_prRefA).notifier,
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('retryPost does nothing without context', () async {
      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Test',
      );

      await controller.retryPost(thread.id);
    });

    test('retryPost ignores nonexistent thread id', () async {
      await controller.retryPost('nonexistent');
    });

    test('retryPost ignores non-error thread', () async {
      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Test',
      );

      expect(thread.syncState, PrInlineSyncState.local);

      await controller.retryPost(thread.id);

      expect(controller.threads.first.syncState, PrInlineSyncState.local);
    });

    test('retryPost ignores thread with empty entries', () async {
      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: '',
      );

      await controller.retryPost(thread.id);
    });
  });

  group('PrInlineCommentsController — forAnchor edge cases', () {
    late PrInlineCommentsController controller;
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          activeRepoProvider.overrideWith((ref) => null),
          prDetailProvider(_prRefA).overrideWith((ref) => Stream.value(null)),
          prReviewRepositoryProvider.overrideWithValue(
            const EmptyPrReviewRepository(),
          ),
        ],
      );
      controller = container.read(
        prInlineCommentsControllerProvider(_prRefA).notifier,
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('forAnchor returns null for empty threads', () {
      final found = controller.forAnchor(
        filePath: 'lib/nonexistent.dart',
        line: 1,
        side: 'RIGHT',
      );
      expect(found, isNull);
    });

    test('forAnchor matches exact line on edge boundary', () {
      controller.create(
        filePath: 'lib/main.dart',
        line: 10,
        lineEnd: 20,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'block',
        suggestedCode: 'block',
        authorBody: 'Test',
      );

      final foundStart = controller.forAnchor(
        filePath: 'lib/main.dart',
        line: 10,
        side: 'RIGHT',
      );
      expect(foundStart, isNotNull);

      final foundEnd = controller.forAnchor(
        filePath: 'lib/main.dart',
        line: 20,
        side: 'RIGHT',
      );
      expect(foundEnd, isNotNull);
    });

    test('forAnchor returns null when file path differs', () {
      controller.create(
        filePath: 'lib/a.dart',
        line: 10,
        lineEnd: 20,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Test',
      );

      final found = controller.forAnchor(
        filePath: 'lib/b.dart',
        line: 15,
        side: 'RIGHT',
      );
      expect(found, isNull);
    });
  });

  group('PrInlineCommentsController — updateEntry in multi-entry threads', () {
    late PrInlineCommentsController controller;
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          activeRepoProvider.overrideWith((ref) => null),
          prDetailProvider(_prRefA).overrideWith((ref) => Stream.value(null)),
          prReviewRepositoryProvider.overrideWithValue(
            const EmptyPrReviewRepository(),
          ),
        ],
      );
      controller = container.read(
        prInlineCommentsControllerProvider(_prRefA).notifier,
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('updateEntry in reply modifies correct entry', () {
      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'First',
      );
      controller.reply(threadId: thread.id, body: 'Second', author: 'Bob');

      final firstEntryId = thread.entries.first.id;
      controller.updateEntry(
        threadId: thread.id,
        entryId: firstEntryId,
        newBody: 'Updated first',
      );

      expect(controller.threads.first.entries.first.body, 'Updated first');
      expect(controller.threads.first.entries[1].body, 'Second');
    });
  });

  group('PrInlineCommentsController — resolve state checks', () {
    late PrInlineCommentsController controller;
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer(
        overrides: [
          activeRepoProvider.overrideWith((ref) => null),
          prDetailProvider(_prRefA).overrideWith((ref) => Stream.value(null)),
          prReviewRepositoryProvider.overrideWithValue(
            const EmptyPrReviewRepository(),
          ),
        ],
      );
      controller = container.read(
        prInlineCommentsControllerProvider(_prRefA).notifier,
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('thread starts unresolved', () {
      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Test',
      );
      expect(thread.resolved, false);
    });

    test('toggleResolved flips flag multiple times', () {
      final thread = controller.create(
        filePath: 'lib/main.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: 'code',
        suggestedCode: 'code',
        authorBody: 'Test',
      );

      controller.toggleResolved(thread.id);
      expect(controller.threads.first.resolved, true);

      controller.toggleResolved(thread.id);
      expect(controller.threads.first.resolved, false);

      controller.toggleResolved(thread.id);
      expect(controller.threads.first.resolved, true);
    });

    test('threads getter is unmodifiable', () {
      final threads = controller.threads;
      expect(
        () => threads.add(
          PrInlineThread(
            id: 'test',
            filePath: '',
            line: 0,
            side: '',
            kind: PrInlineThreadKind.comment,
            originalCode: '',
            suggestedCode: '',
            entries: const [],
          ),
        ),
        throwsA(isA<UnsupportedError>()),
      );
    });
  });

  group('PrInlineThread — computed properties', () {
    test('isMultiLine true when lineEnd > line', () {
      final thread = PrInlineThread(
        id: '1',
        filePath: 'f.dart',
        line: 5,
        lineEnd: 10,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: '',
        suggestedCode: '',
        entries: const [],
      );
      expect(thread.isMultiLine, true);
    });

    test('isMultiLine false when lineEnd equals line', () {
      final thread = PrInlineThread(
        id: '2',
        filePath: 'f.dart',
        line: 5,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: '',
        suggestedCode: '',
        entries: const [],
      );
      expect(thread.isMultiLine, false);
    });

    test('isSuggestion true for suggestion kind', () {
      final thread = PrInlineThread(
        id: '3',
        filePath: 'f.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.suggestion,
        originalCode: '',
        suggestedCode: 'new',
        entries: const [],
      );
      expect(thread.isSuggestion, true);
    });

    test('syncState defaults to local', () {
      final thread = PrInlineThread(
        id: '4',
        filePath: 'f.dart',
        line: 1,
        side: 'RIGHT',
        kind: PrInlineThreadKind.comment,
        originalCode: '',
        suggestedCode: '',
        entries: const [],
      );
      expect(thread.syncState, PrInlineSyncState.local);
    });
  });
}
