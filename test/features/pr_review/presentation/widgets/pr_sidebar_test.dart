import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_checks_ui_notifier.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_sidebar.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

PrUser _user(String login) => PrUser(login: login, avatarUrl: '');

PrUserReviewer _reviewer(
  PrUser user, {
  PrReviewSubmissionState state = PrReviewSubmissionState.pending,
}) {
  return PrUserReviewer(user: user, isCodeOwner: false, state: state);
}

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

List<Override> _overrides(PrSidebar sidebar, List<PrReviewer> reviewers) {
  return [
    githubAuthTokenProvider.overrideWith((ref) => ''),
    currentUserLoginProvider.overrideWith((ref) => ''),
    activeWorkspaceProvider.overrideWith((ref) => null),
    activeRepoProvider.overrideWith((ref) => null),
    prReviewRepositoryProvider.overrideWith(
      (ref) => const EmptyPrReviewRepository(),
    ),
    prReviewersProvider(
      sidebar.pr.number,
    ).overrideWith((ref) => Stream<List<PrReviewer>>.value(reviewers)),
  ];
}

Widget _app(PrSidebar sidebar) {
  return MaterialApp(
    localizationsDelegates: [
      ...AppLocalizations.localizationsDelegates,
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    supportedLocales: AppLocalizations.supportedLocales,
    locale: const Locale('en'),
    home: CcTheme(
      data: CcThemeData.light(),
      child: Scaffold(body: sidebar),
    ),
  );
}

Widget _wrap(
  PrSidebar sidebar, {
  List<PrReviewer> reviewers = const [],
  ProviderContainer? container,
}) {
  final app = _app(sidebar);
  if (container != null) {
    return UncontrolledProviderScope(container: container, child: app);
  }
  return ProviderScope(overrides: _overrides(sidebar, reviewers), child: app);
}

void main() {
  testWidgets('shows no reviewers and no assignees', (tester) async {
    final pr = _pr();
    await tester.pumpWidget(_wrap(PrSidebar(pr: pr)));
    await tester.pump();
    // Section eyebrows are upper-cased (channel-style collapsible sections).
    expect(find.text('REVIEWERS'), findsOneWidget);
    expect(find.text('ASSIGNEES'), findsOneWidget);
    expect(find.text('No reviewers assigned'), findsOneWidget);
    expect(find.text('No assignees'), findsOneWidget);
  });

  testWidgets('shows requested reviewers with pending state', (tester) async {
    final reviewer = _user('reviewer1');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviewers = [_reviewer(reviewer)];
    await tester.pumpWidget(_wrap(PrSidebar(pr: pr), reviewers: reviewers));
    await tester.pump();
    expect(find.text('reviewer1'), findsOneWidget);
  });

  testWidgets('shows approved reviewer', (tester) async {
    final reviewer = _user('approver');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviewers = [
      _reviewer(reviewer, state: PrReviewSubmissionState.approved),
    ];
    await tester.pumpWidget(_wrap(PrSidebar(pr: pr), reviewers: reviewers));
    await tester.pump();
    expect(find.text('approver'), findsOneWidget);
  });

  testWidgets('shows changes requested state', (tester) async {
    final reviewer = _user('strict-reviewer');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviewers = [
      _reviewer(reviewer, state: PrReviewSubmissionState.changesRequested),
    ];
    await tester.pumpWidget(_wrap(PrSidebar(pr: pr), reviewers: reviewers));
    await tester.pump();
    expect(find.text('strict-reviewer'), findsOneWidget);
  });

  testWidgets('shows assignees', (tester) async {
    final assignee = _user('assignee1');
    final pr = _pr(assignees: [assignee]);
    await tester.pumpWidget(_wrap(PrSidebar(pr: pr)));
    expect(find.text('assignee1'), findsOneWidget);
  });

  testWidgets('shows multiple reviewers with mixed states', (tester) async {
    final r1 = _user('approved');
    final r2 = _user('pending');
    final r3 = _user('changes-req');
    final pr = _pr(requestedReviewers: [r1, r2, r3]);
    final reviewers = [
      _reviewer(r1, state: PrReviewSubmissionState.approved),
      _reviewer(r2, state: PrReviewSubmissionState.pending),
      _reviewer(r3, state: PrReviewSubmissionState.changesRequested),
    ];
    await tester.pumpWidget(_wrap(PrSidebar(pr: pr), reviewers: reviewers));
    await tester.pump();
    expect(find.text('approved'), findsOneWidget);
    expect(find.text('pending'), findsOneWidget);
    expect(find.text('changes-req'), findsOneWidget);
  });

  testWidgets('shows reviewer state icons for approved', (tester) async {
    final reviewer = _user('approver1');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviewers = [
      _reviewer(reviewer, state: PrReviewSubmissionState.approved),
    ];
    await tester.pumpWidget(_wrap(PrSidebar(pr: pr), reviewers: reviewers));
    await tester.pump();
    expect(find.byIcon(AppIcons.checkCircle2), findsOneWidget);
  });

  testWidgets('shows reviewer state icons for changes requested', (
    tester,
  ) async {
    final reviewer = _user('strict');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviewers = [
      _reviewer(reviewer, state: PrReviewSubmissionState.changesRequested),
    ];
    await tester.pumpWidget(_wrap(PrSidebar(pr: pr), reviewers: reviewers));
    await tester.pump();
    expect(find.byIcon(AppIcons.xCircle), findsOneWidget);
  });

  testWidgets('shows pending state icon for reviewers without review', (
    tester,
  ) async {
    final reviewer = _user('commenter');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviewers = [_reviewer(reviewer)];
    await tester.pumpWidget(_wrap(PrSidebar(pr: pr), reviewers: reviewers));
    await tester.pump();
    expect(find.byIcon(AppIcons.clock), findsOneWidget);
  });

  testWidgets('shows multiple assignees', (tester) async {
    final a1 = _user('assignee1');
    final a2 = _user('assignee2');
    final a3 = _user('assignee3');
    final pr = _pr(assignees: [a1, a2, a3]);
    await tester.pumpWidget(_wrap(PrSidebar(pr: pr)));
    expect(find.text('assignee1'), findsOneWidget);
    expect(find.text('assignee2'), findsOneWidget);
    expect(find.text('assignee3'), findsOneWidget);
  });

  testWidgets('renders user avatar from URL', (tester) async {
    const reviewer = PrUser(
      login: 'avataruser',
      avatarUrl: 'https://avatars.githubusercontent.com/u/1',
    );
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviewers = [_reviewer(reviewer)];
    await tester.pumpWidget(_wrap(PrSidebar(pr: pr), reviewers: reviewers));
    await tester.pump();
    expect(find.byType(GitHubUserAvatar), findsOneWidget);
  });

  testWidgets('renders initial avatar when no avatarUrl', (tester) async {
    const reviewer = PrUser(login: 'noavatar', avatarUrl: '');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviewers = [_reviewer(reviewer)];
    await tester.pumpWidget(_wrap(PrSidebar(pr: pr), reviewers: reviewers));
    await tester.pump();
    expect(find.text('N'), findsOneWidget);
  });

  testWidgets('renders question mark for empty login', (tester) async {
    const reviewer = PrUser(login: '', avatarUrl: '');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviewers = [_reviewer(reviewer)];
    await tester.pumpWidget(_wrap(PrSidebar(pr: pr), reviewers: reviewers));
    await tester.pump();
    expect(find.text('?'), findsOneWidget);
  });

  testWidgets('renders team logo from URL', (tester) async {
    const team = PrTeamReviewer(
      name: 'Eng',
      slug: 'eng',
      avatarUrl: 'https://avatars.githubusercontent.com/t/1',
      isCodeOwner: false,
      state: PrReviewSubmissionState.pending,
    );
    await tester.pumpWidget(_wrap(PrSidebar(pr: _pr()), reviewers: [team]));
    await tester.pump();
    expect(find.text('Eng'), findsOneWidget);
    expect(find.byType(GitHubUserAvatar), findsOneWidget);
  });

  testWidgets('renders tooltips on reviewer state dots', (tester) async {
    final reviewer = _user('tooltipuser');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviewers = [
      _reviewer(reviewer, state: PrReviewSubmissionState.approved),
    ];
    await tester.pumpWidget(_wrap(PrSidebar(pr: pr), reviewers: reviewers));
    await tester.pump();
    expect(find.byType(CcTooltip), findsOneWidget);
  });

  group('PrSidebar checks section', () {
    testWidgets('shows no checks message when empty', (tester) async {
      final pr = _pr();
      await tester.pumpWidget(_wrap(PrSidebar(pr: pr, checks: const [])));
      expect(find.text('CHECKS'), findsOneWidget);
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
      await tester.pumpWidget(_wrap(PrSidebar(pr: pr, checks: checks)));
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
      await tester.pumpWidget(_wrap(PrSidebar(pr: pr, checks: checks)));
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
      await tester.pumpWidget(_wrap(PrSidebar(pr: pr, checks: checks)));
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
      await tester.pumpWidget(_wrap(PrSidebar(pr: pr, checks: checks)));
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
      await tester.pumpWidget(_wrap(PrSidebar(pr: pr, checks: checks)));
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
      await tester.pumpWidget(_wrap(PrSidebar(pr: pr, checks: checks)));
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
      await tester.pumpWidget(_wrap(PrSidebar(pr: pr, checks: checks)));
      expect(find.text('Neutral'), findsOneWidget);
    });

    testWidgets('is a single row, not a collapsible section', (tester) async {
      final pr = _pr();
      final checks = [
        CheckRun(
          name: 'coverage',
          status: CheckRunStatus.completed,
          conclusion: CheckRunConclusion.neutral,
          htmlUrl: '',
        ),
      ];
      await tester.pumpWidget(_wrap(PrSidebar(pr: pr, checks: checks)));
      expect(find.text('CHECKS'), findsOneWidget);
      expect(find.text('Neutral'), findsOneWidget);
      expect(find.byIcon(AppIcons.chevronRight), findsOneWidget);

      await tester.tap(find.text('CHECKS'));
      await tester.pumpAndSettle();
      expect(find.text('Neutral'), findsOneWidget);
    });

    testWidgets('tapping the row requests the actions tab', (tester) async {
      final pr = _pr();
      final sidebar = PrSidebar(
        pr: pr,
        checks: [
          CheckRun(
            name: 'coverage',
            status: CheckRunStatus.completed,
            conclusion: CheckRunConclusion.neutral,
            htmlUrl: '',
          ),
        ],
      );
      final container = ProviderContainer(overrides: _overrides(sidebar, []));
      addTearDown(container.dispose);
      await tester.pumpWidget(_wrap(sidebar, container: container));

      await tester.tap(find.text('Neutral'));
      await tester.pump();

      final ui = container.read(prChecksUiProvider);
      expect(ui.requestedTabIndex, kPrActionsTabIndex);
      expect(ui.scrollToWorkflow, isNull);
    });

    testWidgets('tapping a failing rollup opens the first failing workflow', (
      tester,
    ) async {
      final pr = _pr();
      final sidebar = PrSidebar(
        pr: pr,
        checks: [
          CheckRun(
            name: 'lint',
            status: CheckRunStatus.completed,
            conclusion: CheckRunConclusion.failure,
            htmlUrl: '',
          ),
        ],
      );
      final container = ProviderContainer(overrides: _overrides(sidebar, []));
      addTearDown(container.dispose);
      await tester.pumpWidget(_wrap(sidebar, container: container));

      await tester.tap(find.text('1 failing'));
      await tester.pump();

      final ui = container.read(prChecksUiProvider);
      expect(ui.requestedTabIndex, kPrActionsTabIndex);
      expect(ui.scrollToWorkflow, 'lint');
    });
  });

  group('PrSidebar all sections together', () {
    testWidgets('shows all sections with data', (tester) async {
      final reviewer = _user('reviewer1');
      final assignee = _user('assignee1');
      tester.view.physicalSize = const Size(600, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final pr = _pr(requestedReviewers: [reviewer], assignees: [assignee]);
      final reviewers = [
        _reviewer(reviewer, state: PrReviewSubmissionState.approved),
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
      await tester.pumpWidget(
        _wrap(
          PrSidebar(pr: pr, checks: checks),
          reviewers: reviewers,
        ),
      );
      await tester.pump();
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('CHECKS'), findsOneWidget);
      expect(find.text('REVIEWERS'), findsOneWidget);
      expect(find.text('ASSIGNEES'), findsOneWidget);
      expect(find.text('1 failing'), findsOneWidget);
      expect(find.text('reviewer1'), findsOneWidget);
      expect(find.text('assignee1'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('STATUS')).dy,
        lessThan(tester.getTopLeft(find.text('CHECKS')).dy),
      );
      expect(
        tester.getTopLeft(find.text('CHECKS')).dy,
        lessThan(tester.getTopLeft(find.text('REVIEWERS')).dy),
      );
    });
  });

  group('PrSidebar files section', () {
    testWidgets('lists changed files and reports taps by index', (
      tester,
    ) async {
      // Tall viewport so every section (Status … Files changed) fits without
      // overflow — the panel scrolls in the app but is rendered bare here.
      tester.view.physicalSize = const Size(500, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final pr = _pr();
      final tapped = <int>[];
      final files = [
        PrFile(
          filename: 'lib/a.dart',
          status: PrFileStatus.modified,
          additions: 3,
          deletions: 1,
          patch: '',
        ),
        PrFile(
          filename: 'lib/b.dart',
          status: PrFileStatus.added,
          additions: 9,
          deletions: 0,
          patch: '',
        ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            githubAuthTokenProvider.overrideWith((ref) => ''),
            currentUserLoginProvider.overrideWith((ref) => ''),
            activeWorkspaceProvider.overrideWith((ref) => null),
            activeRepoProvider.overrideWith((ref) => null),
            prReviewRepositoryProvider.overrideWith(
              (ref) => const EmptyPrReviewRepository(),
            ),
            prReviewersProvider(
              pr.number,
            ).overrideWith((ref) => Stream.value(const <PrReviewer>[])),
            prFilesProvider(
              pr.number,
            ).overrideWith((ref) => Stream.value(files)),
          ],
          child: MaterialApp(
            localizationsDelegates: [
              ...AppLocalizations.localizationsDelegates,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: CcTheme(
              data: CcThemeData.light(),
              child: Scaffold(
                body: PrSidebar(pr: pr, onOpenFileInDiff: tapped.add),
              ),
            ),
          ),
        ),
      );
      // Let the sections' expand animation settle so the file rows are no
      // longer clipped by the section's AnimatedSize (clipping blocks taps).
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('FILES CHANGED'), findsOneWidget);
      expect(find.text('a.dart'), findsOneWidget);
      expect(find.text('b.dart'), findsOneWidget);

      await tester.tap(find.text('b.dart'));
      await tester.pump();
      expect(tapped, [1]);
    });
  });
}
