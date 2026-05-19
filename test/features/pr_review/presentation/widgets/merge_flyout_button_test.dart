import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/domain/entities/check_run.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/widgets/merge_flyout_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../helpers/test_wrap.dart';

PullRequest _pr({
  bool isDraft = false,
  PrState state = PrState.open,
  List<PrUser> requestedReviewers = const [],
}) {
  return PullRequest(
    id: 1,
    number: 42,
    title: 'Test PR',
    body: 'PR body',
    state: state,
    isDraft: isDraft,
    author: const PrUser(login: 'author', avatarUrl: ''),
    createdAt: DateTime(2024, 1, 1),
    updatedAt: DateTime(2024, 6, 10),
    repoFullName: 'owner/repo',
    htmlUrl: 'https://github.com/owner/repo/pull/42',
    requestedReviewers: requestedReviewers,
  );
}

CheckRun _check({
  required String name,
  required CheckRunStatus status,
  required CheckRunConclusion conclusion,
}) {
  return CheckRun(
    name: name,
    status: status,
    conclusion: conclusion,
  );
}

PrReviewSubmission _review({
  required PrReviewSubmissionState state,
  required String login,
}) {
  return PrReviewSubmission(
    state: state,
    author: PrUser(login: login, avatarUrl: ''),
    body: '',
  );
}

/// Wraps [child] in [testWrap] and registers [DesignSystemTokens.light]
/// as a [ThemeExtension].
Widget _wrap(MergeFlyoutButton child) {
  return testWrap(
    Builder(
      builder: (context) => Theme(
        data: Theme.of(context).copyWith(
          extensions: [DesignSystemTokens.light()],
        ),
        child: child,
      ),
    ),
  );
}

/// Pump enough time to clear ForUI FButton animation timers.
Future<void> _settleTimers(WidgetTester tester) async {
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  // ── Visibility ──────────────────────────────────────────────────────────

  testWidgets('renders merge button for open non-draft PR', (tester) async {
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(), owner: 'owner', repo: 'repo',
      checks: const [], reviews: const [],
    )));
    expect(find.text('Merge'), findsOneWidget);
  });

  testWidgets('renders nothing when PR is a draft', (tester) async {
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(isDraft: true), owner: 'owner', repo: 'repo',
      checks: const [], reviews: const [],
    )));
    expect(find.text('Merge'), findsNothing);
  });

  testWidgets('renders nothing when PR is closed', (tester) async {
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(state: PrState.closed), owner: 'owner', repo: 'repo',
      checks: const [], reviews: const [],
    )));
    expect(find.text('Merge'), findsNothing);
  });

  testWidgets('renders nothing when PR is merged', (tester) async {
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(state: PrState.merged), owner: 'owner', repo: 'repo',
      checks: const [], reviews: const [],
    )));
    expect(find.text('Merge'), findsNothing);
  });

  // ── Flyout open / close ────────────────────────────────────────────────

  testWidgets('tapping merge button opens flyout', (tester) async {
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(), owner: 'owner', repo: 'repo',
      checks: const [], reviews: const [],
    )));
    await tester.tap(find.text('Merge'));
    await tester.pump();
    await _settleTimers(tester);
    // Flyout title appears
    expect(find.text('Merge pull request'), findsAtLeastNWidgets(1));
  });

  testWidgets('tapping merge again closes flyout', (tester) async {
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(), owner: 'owner', repo: 'repo',
      checks: const [], reviews: const [],
    )));
    await tester.tap(find.text('Merge'));
    await tester.pump();
    await _settleTimers(tester);
    expect(find.text('Squash and merge'), findsOneWidget);

    await tester.tap(find.text('Merge'));
    await tester.pump();
    await _settleTimers(tester);
    expect(find.text('Squash and merge'), findsNothing);
  });

  // ── Merge method chips ─────────────────────────────────────────────────

  testWidgets('flyout shows three merge method chips', (tester) async {
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(), owner: 'owner', repo: 'repo',
      checks: const [], reviews: const [],
    )));
    await tester.tap(find.text('Merge'));
    await tester.pump();
    await _settleTimers(tester);
    expect(find.text('Squash and merge'), findsOneWidget);
    expect(find.text('Create a merge commit'), findsOneWidget);
    expect(find.text('Rebase and merge'), findsOneWidget);
  });

  testWidgets('commit fields shown for squash (default)', (tester) async {
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(), owner: 'owner', repo: 'repo',
      checks: const [], reviews: const [],
    )));
    await tester.tap(find.text('Merge'));
    await tester.pump();
    await _settleTimers(tester);
    expect(find.text('Commit title'), findsOneWidget);
    expect(find.text('Commit description'), findsOneWidget);
  });

  testWidgets('commit fields shown for merge commit', (tester) async {
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(), owner: 'owner', repo: 'repo',
      checks: const [], reviews: const [],
    )));
    await tester.tap(find.text('Merge'));
    await tester.pump();
    await _settleTimers(tester);
    await tester.tap(find.text('Create a merge commit'));
    await tester.pump();
    await _settleTimers(tester);
    expect(find.text('Commit title'), findsOneWidget);
    expect(find.text('Commit description'), findsOneWidget);
  });

  testWidgets('commit fields hidden for rebase', (tester) async {
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(), owner: 'owner', repo: 'repo',
      checks: const [], reviews: const [],
    )));
    await tester.tap(find.text('Merge'));
    await tester.pump();
    await _settleTimers(tester);
    await tester.tap(find.text('Rebase and merge'));
    await tester.pump();
    await _settleTimers(tester);
    expect(find.text('Commit title'), findsNothing);
    expect(find.text('Commit description'), findsNothing);
  });

  // ── Flyout merge button label ──────────────────────────────────────────

  testWidgets('flyout merge button says Merge pull request when clean', (tester) async {
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(), owner: 'owner', repo: 'repo',
      checks: const [], reviews: const [],
    )));
    await tester.tap(find.text('Merge'));
    await tester.pump();
    await _settleTimers(tester);
    // Both flyout title and flyout merge button say "Merge pull request"
    expect(find.text('Merge pull request'), findsNWidgets(2));
    expect(find.text('Force merge pull request'), findsNothing);
  });

  testWidgets('flyout merge button says Force merge when check failing', (tester) async {
    final checks = [_check(name: 'ci', status: CheckRunStatus.completed, conclusion: CheckRunConclusion.failure)];
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(), owner: 'owner', repo: 'repo',
      checks: checks, reviews: const [],
    )));
    await tester.tap(find.text('Merge'));
    await tester.pump();
    await _settleTimers(tester);
    expect(find.text('Force merge pull request'), findsOneWidget);
  });

  testWidgets('flyout merge button says Force merge when review pending', (tester) async {
    const reviewer = PrUser(login: 'reviewer', avatarUrl: '');
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(requestedReviewers: [reviewer]), owner: 'owner', repo: 'repo',
      checks: const [], reviews: const [],
    )));
    await tester.tap(find.text('Merge'));
    await tester.pump();
    await _settleTimers(tester);
    expect(find.text('Force merge pull request'), findsOneWidget);
  });

  // ── Warnings ───────────────────────────────────────────────────────────

  testWidgets('shows checks failing warning', (tester) async {
    final checks = [_check(name: 'ci', status: CheckRunStatus.completed, conclusion: CheckRunConclusion.failure)];
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(), owner: 'owner', repo: 'repo',
      checks: checks, reviews: const [],
    )));
    await tester.tap(find.text('Merge'));
    await tester.pump();
    await _settleTimers(tester);
    expect(find.text('Checks failing'), findsOneWidget);
  });

  testWidgets('shows reviews pending warning', (tester) async {
    const reviewer = PrUser(login: 'reviewer', avatarUrl: '');
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(requestedReviewers: [reviewer]), owner: 'owner', repo: 'repo',
      checks: const [], reviews: const [],
    )));
    await tester.tap(find.text('Merge'));
    await tester.pump();
    await _settleTimers(tester);
    expect(find.text('Some reviews are pending'), findsOneWidget);
  });

  testWidgets('shows both warnings when checks fail and reviews pending', (tester) async {
    const reviewer = PrUser(login: 'reviewer', avatarUrl: '');
    final checks = [_check(name: 'ci', status: CheckRunStatus.completed, conclusion: CheckRunConclusion.failure)];
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(requestedReviewers: [reviewer]), owner: 'owner', repo: 'repo',
      checks: checks, reviews: const [],
    )));
    await tester.tap(find.text('Merge'));
    await tester.pump();
    await _settleTimers(tester);
    expect(find.text('Checks failing'), findsOneWidget);
    expect(find.text('Some reviews are pending'), findsOneWidget);
  });

  testWidgets('no warnings when all clean', (tester) async {
    const reviewer = PrUser(login: 'reviewer', avatarUrl: '');
    final reviews = [_review(state: PrReviewSubmissionState.approved, login: 'reviewer')];
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(requestedReviewers: [reviewer]), owner: 'owner', repo: 'repo',
      checks: const [], reviews: reviews,
    )));
    await tester.tap(find.text('Merge'));
    await tester.pump();
    await _settleTimers(tester);
    expect(find.text('Checks failing'), findsNothing);
    expect(find.text('Some reviews are pending'), findsNothing);
  });

  // ── Icons ──────────────────────────────────────────────────────────────

  testWidgets('merge button has git-merge icon', (tester) async {
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(), owner: 'owner', repo: 'repo',
      checks: const [], reviews: const [],
    )));
    expect(find.byIcon(LucideIcons.gitMerge), findsOneWidget);
  });

  testWidgets('warnings show alert-triangle icon', (tester) async {
    final checks = [_check(name: 'ci', status: CheckRunStatus.completed, conclusion: CheckRunConclusion.failure)];
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(), owner: 'owner', repo: 'repo',
      checks: checks, reviews: const [],
    )));
    await tester.tap(find.text('Merge'));
    await tester.pump();
    await _settleTimers(tester);
    expect(find.byIcon(LucideIcons.alertTriangle), findsOneWidget);
  });

  // ── Merge readiness: main button text stays "Merge" regardless ─────────

  testWidgets('main button says Merge when blocked by failing check', (tester) async {
    final checks = [_check(name: 'ci', status: CheckRunStatus.completed, conclusion: CheckRunConclusion.failure)];
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(), owner: 'owner', repo: 'repo',
      checks: checks, reviews: const [],
    )));
    expect(find.text('Merge'), findsOneWidget);
  });

  testWidgets('main button says Merge when pending checks', (tester) async {
    final checks = [_check(name: 'ci', status: CheckRunStatus.inProgress, conclusion: CheckRunConclusion.success)];
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(), owner: 'owner', repo: 'repo',
      checks: checks, reviews: const [],
    )));
    expect(find.text('Merge'), findsOneWidget);
  });

  // ── Edge: pending check + approved reviews → clean merge ───────────────

  testWidgets('in-progress check with approved reviews is still clean', (tester) async {
    const reviewer = PrUser(login: 'reviewer', avatarUrl: '');
    final reviews = [_review(state: PrReviewSubmissionState.approved, login: 'reviewer')];
    final checks = [_check(name: 'ci', status: CheckRunStatus.inProgress, conclusion: CheckRunConclusion.success)];
    await tester.pumpWidget(_wrap(MergeFlyoutButton(
      pr: _pr(requestedReviewers: [reviewer]), owner: 'owner', repo: 'repo',
      checks: checks, reviews: reviews,
    )));
    await tester.tap(find.text('Merge'));
    await tester.pump();
    await _settleTimers(tester);
    // _allChecksPass uses isSuccess (conclusion check, not status), so in-progress
    // with success conclusion passes. Combined with approved reviews → clean.
    expect(find.text('Force merge pull request'), findsNothing);
  });
}
