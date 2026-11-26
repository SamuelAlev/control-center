import 'dart:async';

import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_timeline_event.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_domain/features/pr_review/domain/sources/pr_diff_source.dart';
import 'package:control_center/features/pr_review/providers/pr_detail_polling_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

class _TrackingRepository extends EmptyPrReviewRepository {
  int invalidateDiffCalls = 0;
  int invalidatePrCalls = 0;

  @override
  Future<void> invalidateDiff(int prNumber) async {
    invalidateDiffCalls++;
  }

  @override
  Future<void> invalidatePullRequest(int prNumber) async {
    invalidatePrCalls++;
  }
}

const _pr = (
  workspaceId: 'ws',
  repoFullName: 'owner/repo',
  number: 42,
  forge: null,
);

void main() {
  group('PrDetailPollingNotifier', () {
    test(
      'notifyDiffStale and clearDiffStaleIfFresh handle passive vs busted staleness',
      () {
        final container = ProviderContainer();
        addTearDown(container.dispose);

        final sub = container.listen(prDetailPollingProvider(_pr), (_, _) {});
        addTearDown(sub.close);

        final notifier = container.read(prDetailPollingProvider(_pr).notifier);
        expect(container.read(prDetailPollingProvider(_pr)).hasDiffUpdate, isFalse);

        notifier.notifyDiffStale();
        expect(container.read(prDetailPollingProvider(_pr)).hasDiffUpdate, isTrue);

        notifier.clearDiffStaleIfFresh();
        expect(container.read(prDetailPollingProvider(_pr)).hasDiffUpdate, isFalse);

        // Worktree mutations require an explicit server cache bust and must not
        // be cleared by a passive stream emission.
        notifier.notifyDiffStale(bustServerCache: true);
        expect(container.read(prDetailPollingProvider(_pr)).hasDiffUpdate, isTrue);
        notifier.clearDiffStaleIfFresh();
        expect(container.read(prDetailPollingProvider(_pr)).hasDiffUpdate, isTrue);
      },
    );

    test(
      'refreshDiffIfStale skips invalidateDiff for passive staleness and busts when flagged',
      () async {
        final repo = _TrackingRepository();
        var diffCalls = 0;
        var indexCalls = 0;
        var loadCalls = 0;

        final container = ProviderContainer(
          overrides: [
            prRepositoryProvider(_pr).overrideWithValue(repo),
            prDiffProvider(_pr).overrideWith((ref) {
              diffCalls++;
              return Stream.value('diff-$diffCalls');
            }),
            prFileIndexProvider(_pr).overrideWith((ref) {
              indexCalls++;
              return Stream.value(const <PrFile>[]);
            }),
            prFilesLoadProvider(_pr).overrideWith((ref) {
              loadCalls++;
              return Stream.value(
                const PrFilesLoad(files: <PrFile>[], isComplete: true),
              );
            }),
          ],
        );
        addTearDown(container.dispose);

        final pollingSub = container.listen(
          prDetailPollingProvider(_pr),
          (_, _) {},
        );
        final diffSub = container.listen(prDiffProvider(_pr), (_, _) {});
        final indexSub = container.listen(prFileIndexProvider(_pr), (_, _) {});
        final loadSub = container.listen(prFilesLoadProvider(_pr), (_, _) {});
        addTearDown(pollingSub.close);
        addTearDown(diffSub.close);
        addTearDown(indexSub.close);
        addTearDown(loadSub.close);

        await Future<void>.delayed(Duration.zero);

        final notifier = container.read(prDetailPollingProvider(_pr).notifier);

        // No-op when not stale.
        await notifier.refreshDiffIfStale();
        expect(diffCalls, 1);
        expect(indexCalls, 1);
        expect(loadCalls, 1);
        expect(repo.invalidateDiffCalls, 0);

        // Passive staleness re-fetches active providers without busting server cache.
        notifier.notifyDiffStale();
        await notifier.refreshDiffIfStale();
        expect(repo.invalidateDiffCalls, 0);
        expect(diffCalls, 2);
        expect(indexCalls, 2);
        expect(loadCalls, 2);
        expect(container.read(prDetailPollingProvider(_pr)).hasDiffUpdate, isFalse);
        expect(container.read(prDetailPollingProvider(_pr)).refreshingDiff, isFalse);

        // Busted staleness drops server cache before re-fetching.
        notifier.notifyDiffStale(bustServerCache: true);
        await notifier.refreshDiffIfStale();
        expect(repo.invalidateDiffCalls, 1);
        expect(diffCalls, 3);
        expect(indexCalls, 3);
        expect(loadCalls, 3);
      },
    );

    test(
      'refreshDiff toggles refreshingDiff and guards concurrent calls',
      () async {
        final repo = _TrackingRepository();
        final loadController = StreamController<PrFilesLoad>.broadcast();
        addTearDown(loadController.close);

        final container = ProviderContainer(
          overrides: [
            prRepositoryProvider(_pr).overrideWithValue(repo),
            prDiffProvider(_pr).overrideWith((ref) => Stream.value('diff')),
            prFileIndexProvider(_pr)
                .overrideWith((ref) => Stream.value(const <PrFile>[])),
            prFilesLoadProvider(_pr).overrideWith((ref) => loadController.stream),
          ],
        );
        addTearDown(container.dispose);

        final states = <bool>[];
        final pollingSub = container.listen(
          prDetailPollingProvider(_pr),
          (_, next) => states.add(next.refreshingDiff),
        );
        final loadSub = container.listen(prFilesLoadProvider(_pr), (_, _) {});
        addTearDown(pollingSub.close);
        addTearDown(loadSub.close);

        loadController.add(const PrFilesLoad(files: [], isComplete: true));
        await Future<void>.delayed(Duration.zero);

        final notifier = container.read(prDetailPollingProvider(_pr).notifier);
        notifier.notifyDiffStale();

        final first = notifier.refreshDiff();
        expect(container.read(prDetailPollingProvider(_pr)).refreshingDiff, isTrue);
        expect(container.read(prDetailPollingProvider(_pr)).hasDiffUpdate, isFalse);

        // Second concurrent call is ignored while first is in flight.
        await notifier.refreshDiff();
        expect(repo.invalidateDiffCalls, 1);

        loadController.add(const PrFilesLoad(files: [], isComplete: true));
        await first;
        expect(container.read(prDetailPollingProvider(_pr)).refreshingDiff, isFalse);
        expect(states, containsAllInOrder([true, false]));
      },
    );

    test(
      'refreshAll clears hasDiffUpdate and resets server-cache-bust flag',
      () async {
        final repo = _TrackingRepository();
        final container = ProviderContainer(
          overrides: [
            prRepositoryProvider(_pr).overrideWithValue(repo),
            prDetailProvider(_pr)
                .overrideWith((ref) => Stream<PullRequest?>.value(null)),
            prReviewCommentsProvider(_pr).overrideWith(
              (ref) => Stream.value(const <PrCodeReviewComment>[]),
            ),
            prReviewCommentIndexProvider(_pr).overrideWith(
              (ref) => Stream.value(const <PrCodeReviewComment>[]),
            ),
            prIssueCommentsProvider(_pr)
                .overrideWith((ref) => Stream.value(const <IssueComment>[])),
            prReviewsProvider(_pr).overrideWith(
              (ref) => Stream.value(const <PrReviewSubmission>[]),
            ),
            prReviewersProvider(_pr)
                .overrideWith((ref) => Stream.value(const <PrReviewer>[])),
            prTimelineEventsProvider(_pr)
                .overrideWith((ref) => Stream.value(const <PrTimelineEvent>[])),
            prCheckRunsProvider(_pr)
                .overrideWith((ref) => Stream.value(const <CheckRun>[])),
            prCommitsProvider(_pr)
                .overrideWith((ref) => Stream.value(const <PrCommit>[])),
            prDiffProvider(_pr).overrideWith((ref) => Stream.value('')),
            prFileIndexProvider(_pr)
                .overrideWith((ref) => Stream.value(const <PrFile>[])),
            prFilesLoadProvider(_pr).overrideWith(
              (ref) => Stream.value(
                const PrFilesLoad(files: <PrFile>[], isComplete: true),
              ),
            ),
          ],
        );
        addTearDown(container.dispose);

        final sub = container.listen(prDetailPollingProvider(_pr), (_, _) {});
        addTearDown(sub.close);

        final notifier = container.read(prDetailPollingProvider(_pr).notifier);
        notifier.notifyDiffStale(bustServerCache: true);

        await notifier.refreshAll();
        expect(repo.invalidatePrCalls, 1);
        expect(container.read(prDetailPollingProvider(_pr)).hasDiffUpdate, isFalse);
        expect(container.read(prDetailPollingProvider(_pr)).refreshing, isFalse);

        // Passive staleness after refreshAll no longer inherits the old bust flag.
        notifier.notifyDiffStale();
        await notifier.refreshDiffIfStale();
        expect(repo.invalidateDiffCalls, 0);
      },
    );
  });
}
