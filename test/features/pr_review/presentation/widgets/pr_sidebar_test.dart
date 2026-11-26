import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_label.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_reviewer.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/providers/forge_capabilities.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_checks_ui_notifier.dart';
import 'package:control_center/features/pr_review/presentation/widgets/picker_flyout.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_sidebar.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/misc.dart';

PrUser _user(String login) => PrUser(login: login, avatarUrl: '');

Repo _repo({ForgeHost forge = ForgeHost.github}) => Repo(
  id: 'repo-1',
  name: 'repo',
  path: '/tmp/repo',
  remoteOwner: 'owner',
  remoteName: 'repo',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
  forge: forge,
);

List<Override> _editableOverrides(
  PrSidebar sidebar, {
  required ForgeHost forge,
  PrReviewRepository repo = const EmptyPrReviewRepository(),
}) {
  return [
    ..._overrides(sidebar, const []),
    prRepoRowProvider(_prRef).overrideWith((ref) => _repo(forge: forge)),
    prRepositoryProvider(_prRef).overrideWith((ref) => repo),
    forgeCapabilitiesProvider.overrideWith((ref) async => kForgeCapabilities),
  ];
}

PrUserReviewer _reviewer(
  PrUser user, {
  PrReviewSubmissionState state = PrReviewSubmissionState.pending,
  bool isCodeOwner = false,
}) {
  return PrUserReviewer(user: user, isCodeOwner: isCodeOwner, state: state);
}

class _RecordingReviewRepo extends EmptyPrReviewRepository {
  final List<({int prNumber, List<String> users, List<String> teams})>
  requested = [];

  final List<({int prNumber, List<String> names})> removedLabels = [];

  @override
  Future<void> requestReviewers({
    required int prNumber,
    List<String> userLogins = const [],
    List<String> teamSlugs = const [],
  }) async {
    requested.add((prNumber: prNumber, users: userLogins, teams: teamSlugs));
  }

  @override
  Future<void> removeLabels({
    required int prNumber,
    required List<String> names,
  }) async {
    removedLabels.add((prNumber: prNumber, names: names));
  }
}

PullRequest _pr({
  int number = 1,
  PrState state = PrState.open,
  PrUser author = const PrUser(login: '', avatarUrl: ''),
  List<PrUser> requestedReviewers = const <PrUser>[],
  List<PrUser> assignees = const <PrUser>[],
  List<PrLabel> labels = const <PrLabel>[],
}) {
  return PullRequest(
    id: number,
    number: number,
    title: 'Test PR',
    body: '',
    state: state,
    isDraft: false,
    author: author,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
    repoFullName: 'o/r',
    htmlUrl: '',
    requestedReviewers: requestedReviewers,
    assignees: assignees,
    labels: labels,
  );
}

List<Override> _overrides(PrSidebar sidebar, List<PrReviewer> reviewers) {
  return [
    currentUserLoginProvider.overrideWith((ref) => ''),
    currentUserLoginForPrProvider(_prRef).overrideWith((ref) => ''),
    activeWorkspaceProvider.overrideWith((ref) => null),
    activeRepoProvider.overrideWith((ref) => null),
    prReviewRepositoryProvider.overrideWith(
      (ref) => const EmptyPrReviewRepository(),
    ),
    prReviewersProvider(
      _prRef,
    ).overrideWith((ref) => Stream<List<PrReviewer>>.value(reviewers)),
  ];
}

/// The PR identity PrSidebar's keyed providers use.
const _prRef = (
  workspaceId: 'ws',
  repoFullName: 'owner/repo',
  number: 42,
  forge: null,
);

Widget _app(PrSidebar sidebar) {
  return MaterialApp(
    localizationsDelegates: [
      ...appLocalizationsDelegates,
      ...GlobalMaterialLocalizations.delegates,
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
    await tester.pumpWidget(_wrap(PrSidebar(pr: pr, prRef: _prRef)));
    await tester.pump();
    // Section eyebrows (space-style collapsible sections).
    expect(find.text('Reviewers'), findsOneWidget);
    expect(find.text('Assignees'), findsOneWidget);
    expect(find.text('No reviewers assigned'), findsOneWidget);
    expect(find.text('No assignees'), findsOneWidget);
    expect(find.text('Labels'), findsOneWidget);
    expect(find.text('No labels yet'), findsOneWidget);
  });

  testWidgets('shows forge label chips with their names', (tester) async {
    final pr = _pr(
      labels: const [
        PrLabel(name: 'bug', color: 'd73a4a'),
        PrLabel(name: 'dependencies', color: '0366d6'),
      ],
    );
    await tester.pumpWidget(_wrap(PrSidebar(pr: pr, prRef: _prRef)));
    await tester.pump();
    expect(find.text('Labels'), findsOneWidget);
    expect(find.text('bug'), findsOneWidget);
    expect(find.text('dependencies'), findsOneWidget);
    expect(find.text('No labels yet'), findsNothing);
  });

  testWidgets('offers label editing when the forge supports labels', (
    tester,
  ) async {
    final repo = _RecordingReviewRepo();
    final pr = _pr(
      number: 42,
      labels: const [PrLabel(name: 'bug', color: 'd73a4a')],
    );
    final sidebar = PrSidebar(pr: pr, prRef: _prRef, canEdit: true);
    final container = ProviderContainer(
      overrides: _editableOverrides(
        sidebar,
        forge: ForgeHost.github,
        repo: repo,
      ),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(sidebar, container: container));
    await tester.pump();

    final addLabels = tester
        .widgetList<CompactPickerAddButton>(find.byType(CompactPickerAddButton))
        .map((button) => button.semanticLabel);
    expect(addLabels, contains('Add labels'));

    // The remove X is visible immediately without hovering.
    expect(find.byIcon(AppIcons.x), findsOneWidget);
    await tester.tap(find.byIcon(AppIcons.x));
    await tester.pump();
    expect(repo.removedLabels, hasLength(1));
    expect(repo.removedLabels.single.prNumber, 42);
    expect(repo.removedLabels.single.names, ['bug']);
  });

  testWidgets('hides label editing when the forge has no labels', (
    tester,
  ) async {
    final pr = _pr(
      labels: const [PrLabel(name: 'bug', color: 'd73a4a')],
    );
    final sidebar = PrSidebar(pr: pr, prRef: _prRef, canEdit: true);
    final container = ProviderContainer(
      overrides: _editableOverrides(sidebar, forge: ForgeHost.bitbucket),
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(_wrap(sidebar, container: container));
    await tester.pump();

    final addLabels = tester
        .widgetList<CompactPickerAddButton>(find.byType(CompactPickerAddButton))
        .map((button) => button.semanticLabel);
    expect(addLabels, isNot(contains('Add labels')));
    expect(find.text('bug'), findsOneWidget);
    expect(find.byIcon(AppIcons.x), findsNothing);
  });

  testWidgets(
    'hides X and extra trailing space when user has no permission to remove',
    (tester) async {
      final pr = _pr(
        labels: const [PrLabel(name: 'brand checker', color: '8e4452')],
      );

      final editableSidebar = PrSidebar(pr: pr, prRef: _prRef, canEdit: true);
      final editableContainer = ProviderContainer(
        overrides: _editableOverrides(editableSidebar, forge: ForgeHost.github),
      );
      addTearDown(editableContainer.dispose);
      await tester.pumpWidget(
        _wrap(editableSidebar, container: editableContainer),
      );
      await tester.pump();
      expect(find.byIcon(AppIcons.x), findsOneWidget);
      final editableWidth = tester.getSize(find.byType(CcColorTag)).width;

      final readOnlySidebar = PrSidebar(pr: pr, prRef: _prRef, canEdit: false);
      final readOnlyContainer = ProviderContainer(
        overrides: _editableOverrides(readOnlySidebar, forge: ForgeHost.github),
      );
      addTearDown(readOnlyContainer.dispose);
      await tester.pumpWidget(
        _wrap(readOnlySidebar, container: readOnlyContainer),
      );
      await tester.pump();
      expect(find.byIcon(AppIcons.x), findsNothing);
      final readOnlyWidth = tester.getSize(find.byType(CcColorTag)).width;
      expect(readOnlyWidth, lessThan(editableWidth));
    },
  );

  testWidgets('shows requested reviewers with pending state', (tester) async {
    final reviewer = _user('reviewer1');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviewers = [_reviewer(reviewer)];
    await tester.pumpWidget(
      _wrap(
        PrSidebar(pr: pr, prRef: _prRef),
        reviewers: reviewers,
      ),
    );
    await tester.pump();
    expect(find.text('reviewer1'), findsOneWidget);
  });

  testWidgets(
    'last reviewer row matches empty-section gap before the next header',
    (tester) async {
      final reviewer = _user('kilo-code-bot');
      final pr = _pr(requestedReviewers: [reviewer]);
      await tester.pumpWidget(
        _wrap(
          PrSidebar(pr: pr, prRef: _prRef),
          reviewers: [
            _reviewer(reviewer, state: PrReviewSubmissionState.commented),
          ],
        ),
      );
      await tester.pumpAndSettle();

      // Populated reviewer rows used to pad the last item, so the gap under
      // the avatar was 8px larger than the empty assignees/labels sections.
      final avatarBottom = tester
          .getBottomLeft(find.byType(GitHubUserAvatar))
          .dy;
      final assigneesTop = tester.getTopLeft(find.text('Assignees')).dy;
      final emptyBottom = tester.getBottomLeft(find.text('No assignees')).dy;
      final labelsTop = tester.getTopLeft(find.text('Labels')).dy;
      expect(
        assigneesTop - avatarBottom,
        closeTo(labelsTop - emptyBottom, 0.5),
      );
    },
  );

  testWidgets('shows approved reviewer', (tester) async {
    final reviewer = _user('approver');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviewers = [
      _reviewer(reviewer, state: PrReviewSubmissionState.approved),
    ];
    await tester.pumpWidget(
      _wrap(
        PrSidebar(pr: pr, prRef: _prRef),
        reviewers: reviewers,
      ),
    );
    await tester.pump();
    expect(find.text('approver'), findsOneWidget);
  });

  testWidgets('shows changes requested state', (tester) async {
    final reviewer = _user('strict-reviewer');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviewers = [
      _reviewer(reviewer, state: PrReviewSubmissionState.changesRequested),
    ];
    await tester.pumpWidget(
      _wrap(
        PrSidebar(pr: pr, prRef: _prRef),
        reviewers: reviewers,
      ),
    );
    await tester.pump();
    expect(find.text('strict-reviewer'), findsOneWidget);
  });

  testWidgets('shows assignees', (tester) async {
    final assignee = _user('assignee1');
    final pr = _pr(assignees: [assignee]);
    await tester.pumpWidget(_wrap(PrSidebar(pr: pr, prRef: _prRef)));
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
    await tester.pumpWidget(
      _wrap(
        PrSidebar(pr: pr, prRef: _prRef),
        reviewers: reviewers,
      ),
    );
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
    await tester.pumpWidget(
      _wrap(
        PrSidebar(pr: pr, prRef: _prRef),
        reviewers: reviewers,
      ),
    );
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
    await tester.pumpWidget(
      _wrap(
        PrSidebar(pr: pr, prRef: _prRef),
        reviewers: reviewers,
      ),
    );
    await tester.pump();
    expect(find.byIcon(AppIcons.xCircle), findsOneWidget);
  });

  testWidgets('shows pending state icon for reviewers without review', (
    tester,
  ) async {
    final reviewer = _user('commenter');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviewers = [_reviewer(reviewer)];
    await tester.pumpWidget(
      _wrap(
        PrSidebar(pr: pr, prRef: _prRef),
        reviewers: reviewers,
      ),
    );
    await tester.pump();
    expect(find.byIcon(AppIcons.clock), findsOneWidget);
  });

  testWidgets('shows multiple assignees', (tester) async {
    final a1 = _user('assignee1');
    final a2 = _user('assignee2');
    final a3 = _user('assignee3');
    final pr = _pr(assignees: [a1, a2, a3]);
    await tester.pumpWidget(_wrap(PrSidebar(pr: pr, prRef: _prRef)));
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
    await tester.pumpWidget(
      _wrap(
        PrSidebar(pr: pr, prRef: _prRef),
        reviewers: reviewers,
      ),
    );
    await tester.pump();
    expect(find.byType(GitHubUserAvatar), findsOneWidget);
  });

  testWidgets('renders initial avatar when no avatarUrl', (tester) async {
    const reviewer = PrUser(login: 'noavatar', avatarUrl: '');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviewers = [_reviewer(reviewer)];
    await tester.pumpWidget(
      _wrap(
        PrSidebar(pr: pr, prRef: _prRef),
        reviewers: reviewers,
      ),
    );
    await tester.pump();
    expect(find.text('N'), findsOneWidget);
  });

  testWidgets('renders question mark for empty login', (tester) async {
    const reviewer = PrUser(login: '', avatarUrl: '');
    final pr = _pr(requestedReviewers: [reviewer]);
    final reviewers = [_reviewer(reviewer)];
    await tester.pumpWidget(
      _wrap(
        PrSidebar(pr: pr, prRef: _prRef),
        reviewers: reviewers,
      ),
    );
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
    await tester.pumpWidget(
      _wrap(
        PrSidebar(pr: _pr(), prRef: _prRef),
        reviewers: [team],
      ),
    );
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
    await tester.pumpWidget(
      _wrap(
        PrSidebar(pr: pr, prRef: _prRef),
        reviewers: reviewers,
      ),
    );
    await tester.pump();
    expect(find.byType(CcTooltip), findsOneWidget);
  });

  group('PrSidebar checks section', () {
    testWidgets('shows no checks message when empty', (tester) async {
      final pr = _pr();
      await tester.pumpWidget(
        _wrap(PrSidebar(pr: pr, prRef: _prRef, checks: const [])),
      );
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
      await tester.pumpWidget(
        _wrap(PrSidebar(pr: pr, prRef: _prRef, checks: checks)),
      );
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
      await tester.pumpWidget(
        _wrap(PrSidebar(pr: pr, prRef: _prRef, checks: checks)),
      );
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
      await tester.pumpWidget(
        _wrap(PrSidebar(pr: pr, prRef: _prRef, checks: checks)),
      );
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
      await tester.pumpWidget(
        _wrap(PrSidebar(pr: pr, prRef: _prRef, checks: checks)),
      );
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
      await tester.pumpWidget(
        _wrap(PrSidebar(pr: pr, prRef: _prRef, checks: checks)),
      );
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
      await tester.pumpWidget(
        _wrap(PrSidebar(pr: pr, prRef: _prRef, checks: checks)),
      );
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
      await tester.pumpWidget(
        _wrap(PrSidebar(pr: pr, prRef: _prRef, checks: checks)),
      );
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
      await tester.pumpWidget(
        _wrap(PrSidebar(pr: pr, prRef: _prRef, checks: checks)),
      );
      expect(find.text('Checks'), findsOneWidget);
      expect(find.text('Neutral'), findsOneWidget);
      expect(find.byIcon(AppIcons.chevronRight), findsOneWidget);

      await tester.tap(find.text('Checks'));
      await tester.pumpAndSettle();
      expect(find.text('Neutral'), findsOneWidget);
    });

    testWidgets('tapping the row requests the actions tab', (tester) async {
      final pr = _pr();
      final sidebar = PrSidebar(
        pr: pr,
        prRef: _prRef,
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
        prRef: _prRef,
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
          PrSidebar(pr: pr, prRef: _prRef, checks: checks),
          reviewers: reviewers,
        ),
      );
      await tester.pump();
      expect(find.text('Status'), findsOneWidget);
      expect(find.text('Checks'), findsOneWidget);
      expect(find.text('Reviewers'), findsOneWidget);
      expect(find.text('Assignees'), findsOneWidget);
      expect(find.text('1 failing'), findsOneWidget);
      expect(find.text('reviewer1'), findsOneWidget);
      expect(find.text('assignee1'), findsOneWidget);
      expect(
        tester.getTopLeft(find.text('Status')).dy,
        lessThan(tester.getTopLeft(find.text('Checks')).dy),
      );
      expect(
        tester.getTopLeft(find.text('Checks')).dy,
        lessThan(tester.getTopLeft(find.text('Reviewers')).dy),
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
            currentUserLoginProvider.overrideWith((ref) => ''),
            currentUserLoginForPrProvider(_prRef).overrideWith((ref) => ''),
            activeWorkspaceProvider.overrideWith((ref) => null),
            activeRepoProvider.overrideWith((ref) => null),
            prReviewRepositoryProvider.overrideWith(
              (ref) => const EmptyPrReviewRepository(),
            ),
            prReviewersProvider(
              _prRef,
            ).overrideWith((ref) => Stream.value(const <PrReviewer>[])),
            prFileIndexProvider(
              _prRef,
            ).overrideWith((ref) => Stream.value(files)),
          ],
          child: MaterialApp(
            localizationsDelegates: [
              ...appLocalizationsDelegates,
              ...GlobalMaterialLocalizations.delegates,
            ],
            supportedLocales: AppLocalizations.supportedLocales,
            locale: const Locale('en'),
            home: CcTheme(
              data: CcThemeData.light(),
              child: Scaffold(
                body: PrSidebar(
                  pr: pr,
                  prRef: _prRef,
                  onOpenFileInDiff: tapped.add,
                ),
              ),
            ),
          ),
        ),
      );
      // Let the sections' expand animation settle so the file rows are no
      // longer clipped by the section's AnimatedSize (clipping blocks taps).
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.text('Files changed'), findsOneWidget);
      expect(find.text('a.dart'), findsOneWidget);
      expect(find.text('b.dart'), findsOneWidget);

      await tester.tap(find.text('b.dart'));
      await tester.pump();
      expect(tapped, [1]);
    });
  });

  group('PrSidebar accessibility', () {
    List<Override> editableWith(
      PrSidebar sidebar,
      List<PrReviewer> reviewers,
    ) => [
      ..._overrides(sidebar, reviewers),
      prRepoRowProvider(_prRef).overrideWith((ref) => _repo()),
      prRepositoryProvider(
        _prRef,
      ).overrideWith((ref) => const EmptyPrReviewRepository()),
      forgeCapabilitiesProvider.overrideWith((ref) async => kForgeCapabilities),
    ];

    testWidgets('a reviewer row is one announcement: name and verdict', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final alice = _user('alice');
      await tester.pumpWidget(
        _wrap(
          PrSidebar(
            pr: _pr(requestedReviewers: [alice]),
            prRef: _prRef,
          ),
          reviewers: [
            _reviewer(alice, state: PrReviewSubmissionState.approved),
          ],
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.bySemanticsLabel('alice, Approved'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('a pending reviewer reads "Review requested", not "your"', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final bob = _user('bob');
      await tester.pumpWidget(
        _wrap(
          PrSidebar(
            pr: _pr(requestedReviewers: [bob]),
            prRef: _prRef,
          ),
          reviewers: [_reviewer(bob)],
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(find.bySemanticsLabel('bob, Review requested'), findsOneWidget);
      handle.dispose();
    });

    testWidgets('remove reviewer is reachable without hovering and shows on '
        'keyboard focus', (tester) async {
      final handle = tester.ensureSemantics();
      final alice = _user('alice');
      final sidebar = PrSidebar(
        pr: _pr(requestedReviewers: [alice]),
        prRef: _prRef,
        canEdit: true,
      );
      final container = ProviderContainer(
        overrides: editableWith(sidebar, [_reviewer(alice)]),
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(_wrap(sidebar, container: container));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // No pointer anywhere: the button is still in the tree, labeled and
      // focusable — it was only built under the mouse before.
      final remove = find.bySemanticsLabel('Remove alice');
      expect(remove, findsOneWidget);
      expect(
        tester.getSemantics(remove),
        isSemantics(
          label: 'Remove alice',
          isButton: true,
          isFocusable: true,
          hasTapAction: true,
        ),
      );

      final xIcon = find.byIcon(AppIcons.x);
      double opacity() => tester
          .widget<Opacity>(
            find.ancestor(of: xIcon, matching: find.byType(Opacity)).first,
          )
          .opacity;
      expect(opacity(), 0);

      Focus.of(tester.element(xIcon)).requestFocus();
      await tester.pump();
      await tester.pump();
      expect(opacity(), 1);
      handle.dispose();
    });

    testWidgets('a section header exposes its expanded state on the toggle', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      final alice = _user('alice');
      await tester.pumpWidget(
        _wrap(
          PrSidebar(
            pr: _pr(requestedReviewers: [alice]),
            prRef: _prRef,
          ),
          reviewers: [_reviewer(alice)],
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final header = find.bySemanticsLabel('Reviewers, 1');
      expect(
        tester.getSemantics(header),
        isSemantics(
          isButton: true,
          hasExpandedState: true,
          isExpanded: true,
          hasTapAction: true,
        ),
      );

      await tester.tap(find.text('Reviewers'));
      await tester.pumpAndSettle(const Duration(seconds: 1));
      expect(
        tester.getSemantics(header),
        isSemantics(hasExpandedState: true, isExpanded: false),
      );
      handle.dispose();
    });

    testWidgets('a changed-file row names its line counts', (tester) async {
      final handle = tester.ensureSemantics();
      final pr = _pr();
      final files = <PrFile>[
        PrFile(
          filename: 'lib/src/a.dart',
          status: PrFileStatus.modified,
          additions: 12,
          deletions: 3,
          patch: '',
        ),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._overrides(PrSidebar(pr: pr, prRef: _prRef), const []),
            prFileIndexProvider(
              _prRef,
            ).overrideWith((ref) => Stream.value(files)),
          ],
          child: _app(PrSidebar(pr: pr, prRef: _prRef)),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));

      expect(
        find.bySemanticsLabel(
          'a.dart, lib/src, Lines added: 12, lines removed: 3',
        ),
        findsOneWidget,
      );
      handle.dispose();
    });
  });

  group('PrSidebar re-request review', () {
    List<Override> reRequestOverrides(
      PrSidebar sidebar,
      List<PrReviewer> reviewers, {
      ForgeHost forge = ForgeHost.github,
      PrReviewRepository repo = const EmptyPrReviewRepository(),
    }) => [
      ..._overrides(sidebar, reviewers),
      prRepoRowProvider(_prRef).overrideWith((ref) => _repo(forge: forge)),
      prRepositoryProvider(_prRef).overrideWith((ref) => repo),
      forgeCapabilitiesProvider.overrideWith((ref) async => kForgeCapabilities),
    ];

    for (final state in [
      PrReviewSubmissionState.approved,
      PrReviewSubmissionState.changesRequested,
      PrReviewSubmissionState.commented,
    ]) {
      testWidgets(
        'hover reveals re-request button with tooltip for ${state.name} '
        'reviewer and tapping requests review',
        (tester) async {
          final repo = _RecordingReviewRepo();
          final alice = _user('alice');
          final sidebar = PrSidebar(
            pr: _pr(number: 42, requestedReviewers: [alice]),
            prRef: _prRef,
            canEdit: true,
          );
          final container = ProviderContainer(
            overrides: reRequestOverrides(
              sidebar,
              [_reviewer(alice, state: state)],
              repo: repo,
            ),
          );
          addTearDown(container.dispose);
          await tester.pumpWidget(_wrap(sidebar, container: container));
          await tester.pumpAndSettle(const Duration(seconds: 1));

          final gesture = await tester.createGesture(
            kind: PointerDeviceKind.mouse,
          );
          await gesture.addPointer();
          await gesture.moveTo(tester.getCenter(find.text('alice')));
          await tester.pump();

          final repeatIcon = find.byIcon(AppIcons.repeat);
          expect(repeatIcon, findsOneWidget);
          final tooltip = tester.widget<CcTooltip>(
            find.ancestor(of: repeatIcon, matching: find.byType(CcTooltip)),
          );
          expect(tooltip.message, 'Re-request review');

          await tester.tap(repeatIcon);
          await tester.pump();
          expect(repo.requested, hasLength(1));
          expect(repo.requested.single.prNumber, 42);
          expect(repo.requested.single.users, ['alice']);
          expect(repo.requested.single.teams, isEmpty);
          await gesture.removePointer();
        },
      );
    }

    testWidgets('re-requesting a reviewed team sends its slug', (tester) async {
      final repo = _RecordingReviewRepo();
      const team = PrTeamReviewer(
        name: 'Frontend',
        slug: 'fe',
        isCodeOwner: false,
        state: PrReviewSubmissionState.approved,
        reviewedBy: PrUser(login: 'dave', avatarUrl: ''),
      );
      final sidebar = PrSidebar(
        pr: _pr(number: 42),
        prRef: _prRef,
        canEdit: true,
      );
      final container = ProviderContainer(
        overrides: reRequestOverrides(sidebar, [team], repo: repo),
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(_wrap(sidebar, container: container));
      await tester.pumpAndSettle(const Duration(seconds: 1));

      await tester.tap(find.byIcon(AppIcons.repeat));
      await tester.pump();
      expect(repo.requested, hasLength(1));
      expect(repo.requested.single.prNumber, 42);
      expect(repo.requested.single.users, isEmpty);
      expect(repo.requested.single.teams, ['fe']);
    });

    testWidgets(
      'code-owner reviewer shows re-request without remove after review',
      (tester) async {
        final alice = _user('alice');
        final sidebar = PrSidebar(
          pr: _pr(number: 42, requestedReviewers: [alice]),
          prRef: _prRef,
          canEdit: true,
        );
        final container = ProviderContainer(
          overrides: reRequestOverrides(sidebar, [
            _reviewer(
              alice,
              state: PrReviewSubmissionState.changesRequested,
              isCodeOwner: true,
            ),
          ]),
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(_wrap(sidebar, container: container));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        expect(find.byIcon(AppIcons.repeat), findsOneWidget);
        expect(find.byIcon(AppIcons.x), findsNothing);
      },
    );

    testWidgets(
      'hides re-request for pending reviewer, PR author, read-only, '
      'closed/merged PRs, and unsupported forges',
      (tester) async {
        final alice = _user('alice');
        final author = _user('author');
        final cases =
            <({PullRequest pr, List<PrReviewer> reviewers, bool canEdit, ForgeHost forge})>[
              (
                pr: _pr(number: 42),
                reviewers: [
                  _reviewer(alice, state: PrReviewSubmissionState.pending),
                ],
                canEdit: true,
                forge: ForgeHost.github,
              ),
              (
                pr: _pr(number: 42, author: author),
                reviewers: [
                  _reviewer(author, state: PrReviewSubmissionState.commented),
                ],
                canEdit: true,
                forge: ForgeHost.github,
              ),
              (
                pr: _pr(number: 42),
                reviewers: [
                  _reviewer(alice, state: PrReviewSubmissionState.approved),
                ],
                canEdit: false,
                forge: ForgeHost.github,
              ),
              (
                pr: _pr(number: 42, state: PrState.closed),
                reviewers: [
                  _reviewer(alice, state: PrReviewSubmissionState.approved),
                ],
                canEdit: true,
                forge: ForgeHost.github,
              ),
              (
                pr: _pr(number: 42, state: PrState.merged),
                reviewers: [
                  _reviewer(alice, state: PrReviewSubmissionState.approved),
                ],
                canEdit: true,
                forge: ForgeHost.github,
              ),
              (
                pr: _pr(number: 42),
                reviewers: [
                  _reviewer(alice, state: PrReviewSubmissionState.approved),
                ],
                canEdit: true,
                forge: ForgeHost.gitlab,
              ),
              (
                pr: _pr(number: 42),
                reviewers: [
                  _reviewer(alice, state: PrReviewSubmissionState.approved),
                ],
                canEdit: true,
                forge: ForgeHost.bitbucket,
              ),
            ];

        for (final c in cases) {
          final sidebar = PrSidebar(
            pr: c.pr,
            prRef: _prRef,
            canEdit: c.canEdit,
          );
          final container = ProviderContainer(
            overrides: reRequestOverrides(
              sidebar,
              c.reviewers,
              forge: c.forge,
            ),
          );
          await tester.pumpWidget(_wrap(sidebar, container: container));
          await tester.pumpAndSettle(const Duration(seconds: 1));
          expect(
            find.byIcon(AppIcons.repeat),
            findsNothing,
            reason:
                'state=${c.pr.state} canEdit=${c.canEdit} forge=${c.forge}',
          );
          container.dispose();
        }
      },
    );

    testWidgets(
      're-request is reachable in semantics without hovering and reveals on '
      'keyboard focus',
      (tester) async {
        final handle = tester.ensureSemantics();
        final alice = _user('alice');
        final sidebar = PrSidebar(
          pr: _pr(number: 42, requestedReviewers: [alice]),
          prRef: _prRef,
          canEdit: true,
        );
        final container = ProviderContainer(
          overrides: reRequestOverrides(sidebar, [
            _reviewer(alice, state: PrReviewSubmissionState.approved),
          ]),
        );
        addTearDown(container.dispose);
        await tester.pumpWidget(_wrap(sidebar, container: container));
        await tester.pumpAndSettle(const Duration(seconds: 1));

        final button = find.bySemanticsLabel('Re-request review from alice');
        expect(button, findsOneWidget);
        expect(
          tester.getSemantics(button),
          isSemantics(
            label: 'Re-request review from alice',
            isButton: true,
            isFocusable: true,
            hasTapAction: true,
          ),
        );

        final repeatIcon = find.byIcon(AppIcons.repeat);
        double opacity() => tester
            .widget<Opacity>(
              find.ancestor(of: repeatIcon, matching: find.byType(Opacity)).first,
            )
            .opacity;
        expect(opacity(), 0);

        Focus.of(tester.element(repeatIcon)).requestFocus();
        await tester.pump();
        await tester.pump();
        expect(opacity(), 1);
        handle.dispose();
      },
    );

    testWidgets('renders and reveals re-request in RTL', (tester) async {
      final alice = _user('alice');
      final sidebar = PrSidebar(
        pr: _pr(number: 42, requestedReviewers: [alice]),
        prRef: _prRef,
        canEdit: true,
      );
      final container = ProviderContainer(
        overrides: reRequestOverrides(sidebar, [
          _reviewer(alice, state: PrReviewSubmissionState.approved),
        ]),
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: _app(sidebar),
          ),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 1));

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer();
      await gesture.moveTo(tester.getCenter(find.text('alice')));
      await tester.pump();

      expect(find.byIcon(AppIcons.repeat), findsOneWidget);
      expect(find.byIcon(AppIcons.x), findsOneWidget);
      await gesture.removePointer();
    });
  });
}
