import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_edit_notifier.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _RecordingRepo extends EmptyPrReviewRepository {
  String? lastPrBody;
  int updatePrCalls = 0;
  int? lastCommentId;
  String? lastCommentBody;
  List<String> addedLabels = const [];
  List<String> removedLabels = const [];
  Completer<void>? gate;

  @override
  Future<void> updatePullRequest({
    required int prNumber,
    String? title,
    String? body,
  }) async {
    updatePrCalls++;
    lastPrBody = body;
    final wait = gate;
    if (wait != null) {
      await wait.future;
    }
  }

  @override
  Future<void> updateIssueComment({
    required int prNumber,
    required int commentId,
    required String body,
  }) async {
    lastCommentId = commentId;
    lastCommentBody = body;
  }

  @override
  Future<void> addLabels({
    required int prNumber,
    required List<String> names,
  }) async {
    addedLabels = names;
  }

  @override
  Future<void> removeLabels({
    required int prNumber,
    required List<String> names,
  }) async {
    removedLabels = names;
  }
}

void main() {
  const prRef = (workspaceId: 'ws', repoFullName: 'acme/cc', number: 42);

  late _RecordingRepo repo;
  late ProviderContainer container;

  setUp(() {
    repo = _RecordingRepo();
    container = ProviderContainer(
      overrides: [
        prRepositoryProvider(prRef).overrideWith((ref) => repo),
        prDetailProvider(prRef).overrideWith((ref) => Stream.value(null)),
        prIssueCommentsProvider(
          prRef,
        ).overrideWith((ref) => Stream.value(const [])),
      ],
    );
    // autoDispose: keep the notifier alive across async gaps.
    container.listen(prEditProvider(prRef), (_, _) {});
  });

  tearDown(() => container.dispose());

  test(
    'toggleTaskListItem PATCHes the box and keeps the HTML comment',
    () async {
      final notifier = container.read(prEditProvider(prRef).notifier);
      const body =
          ' - [ ] <!-- rebase-check -->If you want to rebase/retry this PR, '
          'check this box';
      final error = await notifier.toggleTaskListItem(
        currentBody: body,
        index: 0,
      );
      expect(error, isNull);
      expect(repo.lastPrBody, contains('[x]'));
      expect(repo.lastPrBody, contains('<!-- rebase-check -->'));
      expect(
        container.read(prEditProvider(prRef)).optimisticBody,
        repo.lastPrBody,
      );
    },
  );

  test(
    'toggleTaskListItem is ignored while a body save is in flight',
    () async {
      repo.gate = Completer<void>();
      final notifier = container.read(prEditProvider(prRef).notifier);
      const body = '- [ ] one\n- [ ] two';
      final first = notifier.toggleTaskListItem(currentBody: body, index: 0);
      await Future<void>.delayed(Duration.zero);
      final second = await notifier.toggleTaskListItem(
        currentBody: body,
        index: 1,
      );
      expect(second, isNull);
      expect(repo.updatePrCalls, 1);
      repo.gate!.complete();
      await first;
      expect(repo.updatePrCalls, 1);
    },
  );

  test('toggleCommentTaskListItem PATCHes the named comment', () async {
    final notifier = container.read(prEditProvider(prRef).notifier);
    final error = await notifier.toggleCommentTaskListItem(
      commentId: 9,
      currentBody: '- [ ] please rebase',
      index: 0,
    );
    expect(error, isNull);
    expect(repo.lastCommentId, 9);
    expect(repo.lastCommentBody, '- [x] please rebase');
    expect(
      container.read(prEditProvider(prRef)).optimisticComments[9],
      '- [x] please rebase',
    );
  });

  test('applyLabelChanges adds and removes in one pass', () async {
    final notifier = container.read(prEditProvider(prRef).notifier);
    final error = await notifier.applyLabelChanges(
      add: const ['bug'],
      remove: const ['wip'],
    );
    expect(error, isNull);
    expect(repo.addedLabels, ['bug']);
    expect(repo.removedLabels, ['wip']);
    expect(container.read(prEditProvider(prRef)).pendingLabels, isEmpty);
  });
}
