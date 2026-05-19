import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_walkthrough_summary.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/review_artifact/review_stale_banner.dart';
import 'package:control_center/features/pr_review/providers/review_artifact_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

/// A review is a claim about ONE commit. Once the author pushes again, every
/// finding in it may be describing code that no longer exists — and a reader
/// with no way to tell has to treat the whole review as suspect, which is the
/// same as having no review at all.
///
/// The banner is deliberately silent in the ordinary case: one that appears on
/// every review is one nobody reads on the review that needed it.
void main() {
  PullRequest pr({String headSha = 'bbb2222'}) => PullRequest(
    id: 1,
    number: 42,
    title: 'Add the thing',
    body: '',
    state: PrState.open,
    isDraft: false,
    author: const PrUser(login: 'sam', avatarUrl: ''),
    createdAt: DateTime.utc(2026),
    updatedAt: DateTime.utc(2026),
    repoFullName: 'acme/widget',
    htmlUrl: '',
    headSha: headSha,
  );

  ReviewArtifact artifact({String? reviewedSha, bool withWalkthrough = true}) =>
      ReviewArtifact(
        verdict: const ReviewVerdict(
          overall: ReviewVerdictOverall.hold,
          confidence: 0.8,
          explanation: '',
          counts: {},
        ),
        markdown: '',
        headSha: reviewedSha,
        walkthrough: withWalkthrough
            ? ReviewWalkthroughSummary(
                headline: 'Adds the thing',
                headSha: reviewedSha,
              )
            : null,
      );

  Future<void> pump(
    WidgetTester tester, {
    required PullRequest pullRequest,
    ReviewArtifact? review,
    bool rerunning = false,
    VoidCallback? onRerun,
  }) => tester.pumpWidget(
    ProviderScope(
      overrides: [reviewArtifactProvider('space-1').overrideWithValue(review)],
      child: testWrap(
        ReviewStaleBanner(
          pr: pullRequest,
          spaceId: 'space-1',
          rerunning: rerunning,
          onRerun: onRerun ?? () {},
        ),
      ),
    ),
  );

  testWidgets('says so when the head moved past the reviewed commit', (
    tester,
  ) async {
    await pump(
      tester,
      pullRequest: pr(),
      review: artifact(reviewedSha: 'aaa1111'),
    );

    expect(find.byType(CcButton), findsOneWidget);
    // The reviewed commit is named, short-form. "Out of date" without saying
    // out of date SINCE WHAT leaves the reader unable to check the claim.
    expect(find.textContaining('aaa1111'), findsOneWidget);
  });

  testWidgets('a CLEAN review can go stale too', (tester) async {
    // A review with nothing to say authors no walkthrough, so the reviewed
    // commit has to come off the artifact itself. Sourcing it from the
    // narrative left exactly the reviews that PASSED unable to report that
    // they no longer described the pull request.
    await pump(
      tester,
      pullRequest: pr(),
      review: artifact(reviewedSha: 'aaa1111', withWalkthrough: false),
    );

    expect(find.byType(CcButton), findsOneWidget);
    expect(find.textContaining('aaa1111'), findsOneWidget);
  });

  testWidgets('stays out of the way on a current review', (tester) async {
    await pump(
      tester,
      pullRequest: pr(headSha: 'aaa1111'),
      review: artifact(reviewedSha: 'aaa1111'),
    );

    expect(find.byType(CcButton), findsNothing);
  });

  testWidgets('claims nothing when the review recorded no commit', (
    tester,
  ) async {
    // A review finalized before the commit was being recorded is not evidence
    // of staleness, and crying stale on a current review is worse than staying
    // quiet on an old one.
    await pump(tester, pullRequest: pr(), review: artifact());
    expect(find.byType(CcButton), findsNothing);
  });

  testWidgets('claims nothing when the PR head has not loaded', (tester) async {
    await pump(
      tester,
      pullRequest: pr(headSha: ''),
      review: artifact(reviewedSha: 'aaa1111'),
    );
    expect(find.byType(CcButton), findsNothing);
  });

  testWidgets('claims nothing before a review exists', (tester) async {
    await pump(tester, pullRequest: pr(), review: null);
    expect(find.byType(CcButton), findsNothing);
  });

  testWidgets('the way out is one press', (tester) async {
    // Telling someone their review is stale without offering the fix is a
    // notification, not a control.
    var started = 0;
    await pump(
      tester,
      pullRequest: pr(),
      review: artifact(reviewedSha: 'aaa1111'),
      onRerun: () => started++,
    );

    await tester.tap(find.byType(CcButton));
    await tester.pump();
    expect(started, 1);
  });

  testWidgets('a run already starting cannot be started twice', (tester) async {
    var started = 0;
    await pump(
      tester,
      pullRequest: pr(),
      review: artifact(reviewedSha: 'aaa1111'),
      rerunning: true,
      onRerun: () => started++,
    );

    await tester.tap(find.byType(CcButton), warnIfMissed: false);
    await tester.pump();
    expect(started, 0);
  });
}
