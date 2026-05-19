import 'package:control_center/features/pr_review/domain/entities/check_run.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_sidebar.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import '../../../../helpers/test_wrap.dart';

PrUser _user(String login) => PrUser(login: login, avatarUrl: '');

PullRequest _pr({
  int number = 1,
  List<PrUser> requestedReviewers = const <PrUser>[],
  List<PrUser> assignees = const <PrUser>[],
}) {
  return PullRequest(
    id: number,
    number: number,
    title: 'Test PR',
    body: '',
    state: PrState.open,
    isDraft: false,
    author: const PrUser(login: '', avatarUrl: ''),
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    repoFullName: 'o/r',
    htmlUrl: '',
    requestedReviewers: requestedReviewers,
    assignees: assignees,
  );
}

void main() {
  testWidgets('shows no reviewers and no assignees', (tester) async {
    final pr = _pr();

    await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: const [])));
    await tester.pump();
    expect(find.text('Reviewers'), findsOneWidget);
    expect(find.text('Assignees'), findsOneWidget);
    expect(find.text('No reviewers assigned'), findsOneWidget);
    expect(find.text('No assignees'), findsOneWidget);
  });

  testWidgets('shows requested reviewers with pending state', (tester) async {
    final reviewer = _user('reviewer1');
    final pr = _pr(requestedReviewers: [reviewer]);

    await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: const [])));
    expect(find.text('reviewer1'), findsOneWidget);
  });

  testWidgets('shows approved reviewer', (tester) async {
    final reviewer = _user('approver');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviews = [
      PrReviewSubmission(
        state: PrReviewSubmissionState.approved,
        author: reviewer,
        body: 'LGTM',
      ),
    ];

    await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: reviews)));
    expect(find.text('approver'), findsOneWidget);
  });

  testWidgets('shows changes requested state', (tester) async {
    final reviewer = _user('strict-reviewer');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviews = [
      PrReviewSubmission(
        state: PrReviewSubmissionState.changesRequested,
        author: reviewer,
        body: 'Please fix',
      ),
    ];

    await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: reviews)));
    expect(find.text('strict-reviewer'), findsOneWidget);
  });

  testWidgets('shows assignees', (tester) async {
    final assignee = _user('assignee1');
    final pr = _pr(assignees: [assignee]);

    await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: const [])));
    expect(find.text('assignee1'), findsOneWidget);
  });

    testWidgets('shows multiple reviewers with mixed states', (tester) async {
      final r1 = _user('approved');
      final r2 = _user('pending');
      final r3 = _user('changes-req');
      final pr = _pr(requestedReviewers: [r1, r2, r3]);
      final reviews = [
        PrReviewSubmission(
          state: PrReviewSubmissionState.approved,
          author: r1,
          body: '',
        ),
        PrReviewSubmission(
          state: PrReviewSubmissionState.changesRequested,
          author: r3,
          body: '',
        ),
      ];

      await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: reviews)));
      expect(find.text('approved'), findsOneWidget);
      expect(find.text('pending'), findsOneWidget);
      expect(find.text('changes-req'), findsOneWidget);
    });

  testWidgets('shows reviewer state icons for approved', (tester) async {
    final reviewer = _user('approver1');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviews = [
      PrReviewSubmission(
        state: PrReviewSubmissionState.approved,
        author: reviewer,
        body: '',
      ),
    ];

    await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: reviews)));

    expect(find.byIcon(LucideIcons.checkCircle2), findsOneWidget);
  });

  testWidgets('shows reviewer state icons for changes requested', (
    tester,
  ) async {
    final reviewer = _user('strict');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviews = [
      PrReviewSubmission(
        state: PrReviewSubmissionState.changesRequested,
        author: reviewer,
        body: '',
      ),
    ];

    await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: reviews)));

    expect(find.byIcon(LucideIcons.xCircle), findsOneWidget);
  });

  testWidgets('shows pending state icon for reviewers without review', (
    tester,
  ) async {
    final reviewer = _user('commenter');
    final pr = _pr(requestedReviewers: [reviewer]);

    await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: const [])));

    expect(find.byIcon(LucideIcons.clock), findsOneWidget);
  });

  testWidgets('shows multiple assignees', (tester) async {
    final a1 = _user('assignee1');
    final a2 = _user('assignee2');
    final a3 = _user('assignee3');
    final pr = _pr(assignees: [a1, a2, a3]);

    await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: const [])));
    expect(find.text('assignee1'), findsOneWidget);
    expect(find.text('assignee2'), findsOneWidget);
    expect(find.text('assignee3'), findsOneWidget);
  });

  testWidgets('renders user avatar from URL', (tester) async {
    const reviewer = PrUser(login: 'avataruser', avatarUrl: 'https://avatars.githubusercontent.com/u/1');
    final pr = _pr(requestedReviewers: [reviewer]);

    await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: const [])));

    expect(find.byType(GitHubUserAvatar), findsOneWidget);
  });

  testWidgets('renders initial avatar when no avatarUrl', (tester) async {
    const reviewer = PrUser(login: 'noavatar', avatarUrl: '');
    final pr = _pr(requestedReviewers: [reviewer]);

    await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: const [])));

    expect(find.text('N'), findsOneWidget);
  });

  testWidgets('renders question mark for empty login', (tester) async {
    const reviewer = PrUser(login: '', avatarUrl: '');
    final pr = _pr(requestedReviewers: [reviewer]);

    await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: const [])));

    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('renders tooltips on reviewer state dots', (tester) async {
    final reviewer = _user('tooltipuser');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviews = [
      PrReviewSubmission(
        state: PrReviewSubmissionState.approved,
        author: reviewer,
        body: 'LGTM',
      ),
    ];

    await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: reviews)));

    expect(find.byType(FTooltip), findsOneWidget);
  });

  group('PrSidebar checks section', () {
    // The rail no longer lists every workflow row (that detail lives in the
    // Actions tab); it shows a single rolled-up verdict that taps through.
    testWidgets('shows no checks message when empty', (tester) async {
      final pr = _pr();
      await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: const [], checks: const [])));
      expect(find.text('Checks'), findsOneWidget);
      expect(find.text('No checks have run yet'), findsOneWidget);
    });

    testWidgets('shows passing verdict', (tester) async {
      final pr = _pr();
      final checks = [
        CheckRun(
          name: 'build',
          status: CheckRunStatus.completed,
          conclusion: CheckRunConclusion.success,
          htmlUrl: '',
          completedAt: DateTime(2024, 1, 1, 12, 0),
        ),
      ];

      await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: const [], checks: checks)));
      expect(find.text('Passed'), findsOneWidget);
    });

    testWidgets('shows single failing verdict', (tester) async {
      final pr = _pr();
      final checks = [
        CheckRun(
          name: 'lint',
          status: CheckRunStatus.completed,
          conclusion: CheckRunConclusion.failure,
          htmlUrl: 'https://github.com/logs',
          completedAt: DateTime(2024, 1, 1, 12, 0),
        ),
      ];

      await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: const [], checks: checks)));
      expect(find.text('1 failing'), findsOneWidget);
    });

    testWidgets('shows multiple failing count in verdict', (tester) async {
      final pr = _pr();
      final checks = [
        CheckRun(
          name: 'lint',
          status: CheckRunStatus.completed,
          conclusion: CheckRunConclusion.failure,
          htmlUrl: '',
        ),
        CheckRun(
          name: 'test',
          status: CheckRunStatus.completed,
          conclusion: CheckRunConclusion.failure,
          htmlUrl: '',
        ),
        CheckRun(
          name: 'build',
          status: CheckRunStatus.completed,
          conclusion: CheckRunConclusion.success,
          htmlUrl: '',
        ),
      ];

      await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: const [], checks: checks)));
      expect(find.text('2 failing'), findsOneWidget);
    });

    testWidgets('shows running verdict for in-progress check', (tester) async {
      final pr = _pr();
      final checks = [
        CheckRun(
          name: 'deploy',
          status: CheckRunStatus.inProgress,
          conclusion: null,
          htmlUrl: '',
        ),
      ];

      await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: const [], checks: checks)));
      expect(find.text('Running'), findsOneWidget);
    });

    testWidgets('shows running verdict for queued check', (tester) async {
      final pr = _pr();
      final checks = [
        CheckRun(
          name: 'waiting',
          status: CheckRunStatus.queued,
          conclusion: null,
          htmlUrl: '',
        ),
      ];

      await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: const [], checks: checks)));
      expect(find.text('Running'), findsOneWidget);
    });

    testWidgets('failure outranks running in the rollup', (tester) async {
      final pr = _pr();
      final checks = [
        CheckRun(
          name: 'security',
          status: CheckRunStatus.completed,
          conclusion: CheckRunConclusion.failure,
          htmlUrl: '',
          completedAt: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        CheckRun(
          name: 'deploy',
          status: CheckRunStatus.inProgress,
          conclusion: null,
          htmlUrl: '',
        ),
      ];

      await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: const [], checks: checks)));
      expect(find.text('1 failing'), findsOneWidget);
    });

    testWidgets('shows neutral verdict', (tester) async {
      final pr = _pr();
      final checks = [
        CheckRun(
          name: 'coverage',
          status: CheckRunStatus.completed,
          conclusion: CheckRunConclusion.neutral,
          htmlUrl: '',
        ),
      ];

      await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: const [], checks: checks)));
      expect(find.text('Neutral'), findsOneWidget);
    });
  });

  group('PrSidebar all sections together', () {
    testWidgets('shows all sections with data', (tester) async {
      final reviewer = _user('reviewer1');
      final assignee = _user('assignee1');
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1.0;
      });

      final pr = _pr(
        requestedReviewers: [reviewer],
        assignees: [assignee],
      );
      final reviews = [
        PrReviewSubmission(
          state: PrReviewSubmissionState.approved,
          author: reviewer,
          body: 'LGTM',
        ),
      ];
      final checks = [
        CheckRun(
          name: 'build',
          status: CheckRunStatus.completed,
          conclusion: CheckRunConclusion.success,
          htmlUrl: '',
        ),
        CheckRun(
          name: 'lint',
          status: CheckRunStatus.completed,
          conclusion: CheckRunConclusion.failure,
          htmlUrl: 'https://logs',
        ),
      ];

      await tester.pumpWidget(testWrap(PrSidebar(pr: pr, reviews: reviews, checks: checks)));

      expect(find.text('Reviewers'), findsOneWidget);
      expect(find.text('Assignees'), findsOneWidget);
      expect(find.text('Checks'), findsOneWidget);
      expect(find.text('1 failing'), findsOneWidget);
      expect(find.text('reviewer1'), findsOneWidget);
      expect(find.text('assignee1'), findsOneWidget);
    });
  });
}
