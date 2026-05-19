import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/utils/decision_lane.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.now();

  PullRequest createPr({
    int id = 1,
    int number = 42,
    String title = 'Add feature X',
    String body = '',
    PrState state = PrState.open,
    bool isDraft = false,
    PrChecksStatus checksStatus = PrChecksStatus.none,
    PrMergeableState mergeableState = PrMergeableState.unknown,
    List<PrUser> requestedReviewers = const [],
    DateTime? updatedAt,
  }) {
    return PullRequest(
      id: id,
      number: number,
      title: title,
      body: body,
      state: state,
      isDraft: isDraft,
      author: const PrUser(login: 'dev', avatarUrl: ''),
      createdAt: now,
      updatedAt: updatedAt ?? now,
      repoFullName: 'org/repo',
      htmlUrl: 'https://github.com/org/repo/pull/42',
      requestedReviewers: requestedReviewers,
      checksStatus: checksStatus,
      mergeableState: mergeableState,
    );
  }

  group('classifyDecisionLanes', () {
    test('draft PR is always draft lane only', () {
      final pr = createPr(
        isDraft: true,
        checksStatus: PrChecksStatus.passing,
        mergeableState: PrMergeableState.clean,
      );
      final lanes = classifyDecisionLanes(pr, awaitingMe: false);
      expect(lanes, {DecisionLane.draft});
    });

    test('failing checks land in attention', () {
      final pr = createPr(
        checksStatus: PrChecksStatus.failing,
        mergeableState: PrMergeableState.unstable,
      );
      final lanes = classifyDecisionLanes(pr, awaitingMe: false);
      expect(lanes.contains(DecisionLane.attention), isTrue);
    });

    test('stale PR lands in attention', () {
      final pr = createPr(
        updatedAt: now.subtract(const Duration(days: 15)),
        checksStatus: PrChecksStatus.passing,
        mergeableState: PrMergeableState.clean,
      );
      final lanes = classifyDecisionLanes(pr, awaitingMe: false);
      expect(lanes.contains(DecisionLane.attention), isTrue);
    });

    test('awaiting me lands in review', () {
      final pr = createPr(
        requestedReviewers: const [PrUser(login: 'me', avatarUrl: '')],
        checksStatus: PrChecksStatus.passing,
        mergeableState: PrMergeableState.clean,
      );
      final lanes = classifyDecisionLanes(pr, awaitingMe: true);
      expect(lanes.contains(DecisionLane.review), isTrue);
      expect(lanes.contains(DecisionLane.ready), isFalse);
    });

    test('clean mergeable state with no pending reviewers is ready', () {
      final pr = createPr(
        checksStatus: PrChecksStatus.passing,
        mergeableState: PrMergeableState.clean,
      );
      final lanes = classifyDecisionLanes(pr, awaitingMe: false);
      expect(lanes.contains(DecisionLane.ready), isTrue);
    });

    test('unknown mergeable state with no reviewers is ready (fallback)', () {
      final pr = createPr(
        checksStatus: PrChecksStatus.none,
        mergeableState: PrMergeableState.unknown,
      );
      final lanes = classifyDecisionLanes(pr, awaitingMe: false);
      expect(lanes.contains(DecisionLane.ready), isTrue);
    });

    test('unrecognized mergeable state with no reviewers is ready (fallback)', () {
      final pr = createPr(
        checksStatus: PrChecksStatus.none,
        mergeableState: PrMergeableState.unrecognized,
      );
      final lanes = classifyDecisionLanes(pr, awaitingMe: false);
      expect(lanes.contains(DecisionLane.ready), isTrue);
    });

    test('clean mergeable state with pending reviewers is not ready', () {
      final pr = createPr(
        checksStatus: PrChecksStatus.passing,
        mergeableState: PrMergeableState.clean,
        requestedReviewers: const [PrUser(login: 'alice', avatarUrl: '')],
      );
      final lanes = classifyDecisionLanes(pr, awaitingMe: false);
      expect(lanes.contains(DecisionLane.ready), isFalse);
      expect(lanes.contains(DecisionLane.inProgress), isTrue);
    });

    test('blocked mergeable state is not ready', () {
      final pr = createPr(
        checksStatus: PrChecksStatus.passing,
        mergeableState: PrMergeableState.blocked,
        requestedReviewers: const [PrUser(login: 'alice', avatarUrl: '')],
      );
      final lanes = classifyDecisionLanes(pr, awaitingMe: false);
      expect(lanes.contains(DecisionLane.ready), isFalse);
      expect(lanes.contains(DecisionLane.inProgress), isTrue);
    });

    test('pending checks with no other issues is inProgress', () {
      final pr = createPr(checksStatus: PrChecksStatus.pending);
      final lanes = classifyDecisionLanes(pr, awaitingMe: false);
      expect(lanes, {DecisionLane.inProgress});
    });

    test('no checks and no reviewers is ready (fallback)', () {
      final pr = createPr(checksStatus: PrChecksStatus.none);
      final lanes = classifyDecisionLanes(pr, awaitingMe: false);
      expect(lanes, {DecisionLane.ready});
    });

    test('no checks and no reviewers is ready (fallback)', () {
      final pr = createPr(checksStatus: PrChecksStatus.none);
      final lanes = classifyDecisionLanes(pr, awaitingMe: false);
      expect(lanes, {DecisionLane.ready});
    });
  });

  group('primaryLaneOf', () {
    test('returns attention when present', () {
      expect(
        primaryLaneOf({DecisionLane.attention, DecisionLane.ready}),
        DecisionLane.attention,
      );
    });

    test('returns review when attention is absent', () {
      expect(
        primaryLaneOf({DecisionLane.review, DecisionLane.ready}),
        DecisionLane.review,
      );
    });

    test('returns ready when attention and review are absent', () {
      expect(
        primaryLaneOf({DecisionLane.ready, DecisionLane.inProgress}),
        DecisionLane.ready,
      );
    });

    test('returns inProgress when only inProgress and draft', () {
      expect(
        primaryLaneOf({DecisionLane.inProgress, DecisionLane.draft}),
        DecisionLane.inProgress,
      );
    });

    test('returns draft as last resort', () {
      expect(primaryLaneOf({DecisionLane.draft}), DecisionLane.draft);
    });
  });
}
