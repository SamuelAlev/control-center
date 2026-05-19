import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/utils/decision_lane.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime.now();

  PullRequest createPr({
    int number = 42,
    String title = 'PR',
    PrState state = PrState.open,
    bool isDraft = false,
    PrChecksStatus checksStatus = PrChecksStatus.none,
    PrMergeableState mergeableState = PrMergeableState.unknown,
    List<PrUser> requestedReviewers = const [],
    DateTime? updatedAt,
  }) {
    return PullRequest(
      id: number,
      number: number,
      title: title,
      body: '',
      state: state,
      isDraft: isDraft,
      author: const PrUser(login: 'dev', avatarUrl: ''),
      createdAt: now,
      updatedAt: updatedAt ?? now,
      repoFullName: 'org/repo',
      htmlUrl: 'https://github.com/org/repo/pull/$number',
      requestedReviewers: requestedReviewers,
      checksStatus: checksStatus,
      mergeableState: mergeableState,
    );
  }

  group('mergeable state scenarios', () {
    test('PR with clean mergeable state and no reviewers is in ready lane', () {
      final pr = createPr(
        mergeableState: PrMergeableState.clean,
        requestedReviewers: const [],
        checksStatus: PrChecksStatus.passing,
      );
      final lanes = classifyDecisionLanes(pr, awaitingMe: false);
      expect(lanes.contains(DecisionLane.ready), isTrue);
    });

    test('PR with unknown mergeable state and no reviewers is ready (fallback)', () {
      final pr = createPr(
        mergeableState: PrMergeableState.unknown,
        requestedReviewers: const [],
        checksStatus: PrChecksStatus.passing,
      );
      final lanes = classifyDecisionLanes(pr, awaitingMe: false);
      expect(lanes.contains(DecisionLane.ready), isTrue);
    });
  });
}
