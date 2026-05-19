import 'dart:async';

import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_generation.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_lifecycle_repository.dart';
import 'package:control_center/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:control_center/features/pr_review/presentation/screens/compose_pull_request_screen.dart';
import 'package:control_center/features/pr_review/providers/compose_pr_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart' show PageWrapper;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';

import '../../../../helpers/test_wrap.dart';

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Repo _testRepo({
  String id = 'r1',
  String owner = 'owner',
  String name = 'repo',
}) {
  return Repo(
    id: id,
    name: '$owner/$name',
    path: '/repos/$owner/$name',
    githubOwner: owner,
    githubRepoName: name,
    createdAt: DateTime(2024),
    updatedAt: DateTime(2024),
  );
}

/// A fixed-value [ActiveWorkspaceIdNotifier] for tests.
class _FixedWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  _FixedWorkspaceIdNotifier(this._id);
  final String? _id;

  @override
  String? build() => _id;
}

/// A fixed-value [ActiveRepoIdNotifier] for tests.
class _FixedRepoIdNotifier extends ActiveRepoIdNotifier {
  _FixedRepoIdNotifier(this._id);
  final String? _id;

  @override
  String? build() => _id;
}

/// A `ComposePrNotifier` pre-filled with data so `canSubmit` is true.
class _PreFilledComposePrNotifier extends ComposePrNotifier {
  @override
  ComposePrState build() => const ComposePrState(
    base: 'main',
    head: 'feature/my-change',
    title: 'Fix critical bug',
  );
}

/// A fake [PrLifecycleRepository] that returns configurable results for
/// the compose-screen submit flow.
class _FakePrLifecycleRepository implements PrLifecycleRepository {
  int? submitResult;
  Object? submitError;
  int createDraftCallCount = 0;
  int createOnGitHubCallCount = 0;
  bool? lastDraftFlag;
  String lastPrId = '';
  String lastTitle = '';
  String lastBody = '';
  String lastHead = '';
  String lastBase = '';
  List<String> lastAssignees = const [];
  List<String> lastReviewerUsers = const [];
  List<String> lastReviewerTeams = const [];

  /// Override to stall [createOnGitHub]. When non-null, the returned future
  /// is used instead of the default instant-complete result. Useful for
  /// testing the loading state.
  Future<Map<String, dynamic>>? createOnGitHubOverride;

  @override
  Future<String> createDraft({
    required String workspaceId,
    required String title,
    required String body,
    String? diffSummary,
  }) async {
    createDraftCallCount++;
    if (submitError != null) {
      throw submitError!;
    }
    return 'draft-id';
  }

  @override
  Future<Map<String, dynamic>> createOnGitHub({
    required String prId,
    required String owner,
    required String repo,
    required String title,
    required String body,
    required String head,
    required String base,
    bool draft = false,
    List<String> assignees = const [],
    List<String> reviewerUsers = const [],
    List<String> reviewerTeams = const [],
  }) async {
    createOnGitHubCallCount++;
    lastPrId = prId;
    lastTitle = title;
    lastBody = body;
    lastHead = head;
    lastBase = base;
    lastDraftFlag = draft;
    lastAssignees = assignees;
    lastReviewerUsers = reviewerUsers;
    lastReviewerTeams = reviewerTeams;
    if (submitError != null) {
      throw submitError!;
    }
    if (createOnGitHubOverride != null) {
      return createOnGitHubOverride!;
    }
    return {'number': submitResult ?? 42};
  }

  @override
  Future<PrGeneration?> getById(String id) async => null;

  @override
  Future<void> updateDraft(
    String prId, {
    String? title,
    String? body,
    String? status,
    int? githubPrNumber,
    String? githubPrUrl,
  }) async {}

  @override
  Future<void> delete(String id) async {}

  @override
  Stream<List<PrGeneration>> watchByWorkspace(String workspaceId) =>
      const Stream.empty();
}

/// Wraps [child] with providers needed for [ComposePullRequestScreen] to
/// show the compose form (repo + auth) and an optional [lifecycle] for the
/// submit flow. Uses a [GoRouter] so navigation during submit works.
///
/// Set `preFillForm` to true to override `composePrProvider` with a notifier
Widget _wrapComposeScreen(
  Widget child, {
  Repo? repo,
  String token = 'fake-token',
  String? workspaceId,
  _FakePrLifecycleRepository? lifecycle,
  bool preFillForm = false,
}) {
  return ProviderScope(
    overrides: [
      // Auth — must be non-empty for isGitHubAuthenticatedProvider to be true.
      githubAuthTokenProvider.overrideWith((ref) => token),
      // Active repo.
      activeRepoProvider.overrideWith((ref) => repo),
      // Fixed workspace ID and repo ID notifiers.
      activeWorkspaceIdProvider
          .overrideWith(() => _FixedWorkspaceIdNotifier(workspaceId)),
      activeRepoIdProvider
          .overrideWith(() => _FixedRepoIdNotifier(repo?.id)),
      // Workspace listing.
      if (workspaceId != null)
        workspacesProvider.overrideWith(
          (ref) => Stream.value([
            Workspace(
              id: workspaceId,
              name: 'Test',
              createdAt: DateTime(2024),
              updatedAt: DateTime(2024),
            ),
          ]),
        )
      else
        workspacesProvider.overrideWith(
          (ref) => const Stream<List<Workspace>>.empty(),
        ),
      // Compose form — optionally pre-filled.
      if (preFillForm)
        composePrProvider.overrideWith(_PreFilledComposePrNotifier.new),
      // Repository — stub that avoids GitHub API calls and DB timers.
      prReviewRepositoryProvider
          .overrideWith((ref) => const EmptyPrReviewRepository()),
      // Override repos-for-workspace to avoid drift database stream queries
      // (which leave pending timers on dispose).
      reposForWorkspaceProvider
          .overrideWith((ref, workspaceId) => const Stream<List<Repo>>.empty()),
      // Lifecycle repo — fake for submit control.
      if (lifecycle != null)
        prLifecycleRepositoryProvider.overrideWithValue(lifecycle),
      // Branch providers — return empty to avoid GitHub API calls.
      repoBranchesProvider.overrideWith((ref) => const <String>[]),
      defaultBranchProvider.overrideWith((ref) => ''),
      prTemplatesProvider.overrideWith((ref) => const <PrTemplateOption>[]),
      // Diff comparison — return null to avoid hitting the real GitHub API.
      branchComparisonProvider.overrideWith((ref, key) => null),
    ],
    child: MaterialApp.router(
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => FTheme(
              data: FThemes.zinc.light.desktop,
              child: Scaffold(body: child),
            ),
          ),
          GoRoute(
            path: '/pull-requests/:number',
            builder: (_, state) =>
                Text('PR ${state.pathParameters['number']}'),
          ),
          GoRoute(
            path: '/pull-requests',
            builder: (_, _) => const Text('PR list'),
          ),
        ],
      ),
    ),
  );
}

/// Sets the default test viewport to a reasonable desktop size so the
/// [PageWrapper] layout doesn't overflow.
void _setDesktopViewport(WidgetTester tester) {
  tester.view.physicalSize = const Size(1280, 900);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  group('empty state', () {
    testWidgets('shows EmptyConfigState when not authenticated', (
      tester,
    ) async {
      _setDesktopViewport(tester);
      await tester.pumpWidget(testWrap(const ComposePullRequestScreen()));
      await tester.pumpAndSettle();

      expect(find.text('No GitHub repository selected'), findsOneWidget);
      expect(
        find.text(
          'Select a workspace with a GitHub-linked repository to open a pull request.',
        ),
        findsOneWidget,
      );
      // Title bar still shows page identity.
      expect(find.text('Open a pull request'), findsOneWidget);
    });

    testWidgets('shows EmptyConfigState when repo has no GitHub remote', (
      tester,
    ) async {
      _setDesktopViewport(tester);
      await tester.pumpWidget(
        _wrapComposeScreen(
          const ComposePullRequestScreen(),
          repo: Repo(
            id: 'no-remote',
            name: 'no-remote',
            path: '/tmp/no-remote',
            githubOwner: '',
            githubRepoName: '',
            createdAt: DateTime(2024),
            updatedAt: DateTime(2024),
          ),
          token: 't',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No GitHub repository selected'), findsOneWidget);
    });
  });

  group('form fields', () {
    testWidgets('renders form when repo and auth are set', (tester) async {
      _setDesktopViewport(tester);

      await tester.pumpWidget(
        _wrapComposeScreen(
          const ComposePullRequestScreen(),
          repo: _testRepo(),
        ),
      );
      await tester.pumpAndSettle();

      // Page title and subtitle.
      expect(find.text('Open a pull request'), findsOneWidget);
      expect(
        find.text(
          "From a branch you've pushed — no agents or tickets involved",
        ),
        findsOneWidget,
      );

      // Breadcrumb actions: Cancel, Create as draft, Create pull request.
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Create as draft'), findsOneWidget);
      expect(find.text('Create pull request'), findsOneWidget);

      // Title field — label "Title" appears in the FTextField label and the
      // header label.
      expect(find.text('Title'), findsAtLeast(1));
      expect(find.text('PR title'), findsOneWidget);

      // Branch bar labels (English locale).
      expect(find.text('Base'), findsOneWidget);
      expect(find.text('Compare'), findsOneWidget);

      // Sidebar sections.
      expect(find.text('Reviewers'), findsOneWidget);
      expect(find.text('Assignees'), findsOneWidget);

      // "Pick branches" hint shown since no branches selected.
      expect(
        find.text(
          'Pick a base and compare branch to preview the changes.',
        ),
        findsOneWidget,
      );
    });
  });

  group('validation', () {
    testWidgets('submit buttons disabled when form is empty', (tester) async {
      _setDesktopViewport(tester);
      await tester.pumpWidget(
        _wrapComposeScreen(
          const ComposePullRequestScreen(),
          repo: _testRepo(),
        ),
      );
      await tester.pumpAndSettle();

      final createButton = tester.widget<FButton>(
        find.widgetWithText(FButton, 'Create pull request'),
      );
      expect(createButton.onPress, isNull);

      final draftButton = tester.widget<FButton>(
        find.widgetWithText(FButton, 'Create as draft'),
      );
      expect(draftButton.onPress, isNull);
    });

    testWidgets('submit buttons disabled when only title is filled', (
      tester,
    ) async {
      _setDesktopViewport(tester);
      await tester.pumpWidget(
        _wrapComposeScreen(
          const ComposePullRequestScreen(),
          repo: _testRepo(),
        ),
      );
      await tester.pumpAndSettle();

      // Enter title — propagates via the _titleController listener in
      // _ComposePullRequestScreenState.
      final titleField = find.widgetWithText(FTextField, 'Title');
      await tester.enterText(titleField, 'A pull request title');
      await tester.pumpAndSettle();

      final createButton = tester.widget<FButton>(
        find.widgetWithText(FButton, 'Create pull request'),
      );
      expect(createButton.onPress, isNull);
    });

    testWidgets('submit buttons enabled when form is complete', (
      tester,
    ) async {
      _setDesktopViewport(tester);

      await tester.pumpWidget(
        _wrapComposeScreen(
          const ComposePullRequestScreen(),
          repo: _testRepo(),
          preFillForm: true,
        ),
      );
      await tester.pumpAndSettle();

      final createButton = tester.widget<FButton>(
        find.widgetWithText(FButton, 'Create pull request'),
      );
      expect(createButton.onPress, isNotNull);

      final draftButton = tester.widget<FButton>(
        find.widgetWithText(FButton, 'Create as draft'),
      );
      expect(draftButton.onPress, isNotNull);
    });
  });

  group('submission', () {
    testWidgets('successful submit navigates to PR detail', (tester) async {
      _setDesktopViewport(tester);

      final lifecycle = _FakePrLifecycleRepository();

      await tester.pumpWidget(
        _wrapComposeScreen(
          const ComposePullRequestScreen(),
          repo: _testRepo(),
          workspaceId: 'ws1',
          lifecycle: lifecycle,
          preFillForm: true,
        ),
      );
      await tester.pumpAndSettle();

      // Verify button is enabled.
      final createButton = tester.widget<FButton>(
        find.widgetWithText(FButton, 'Create pull request'),
      );
      expect(createButton.onPress, isNotNull);

      // Tap Create pull request.
      await tester.tap(find.widgetWithText(FButton, 'Create pull request'));
      await tester.pumpAndSettle();

      // Lifecycle should have been called with draft = false.
      expect(lifecycle.createDraftCallCount, 1);
      expect(lifecycle.createOnGitHubCallCount, 1);
      expect(lifecycle.lastDraftFlag, false);
      expect(lifecycle.lastTitle, 'Fix critical bug');
      expect(lifecycle.lastBase, 'main');
      expect(lifecycle.lastHead, 'feature/my-change');

      // Navigation to the new PR detail route.
      expect(find.text('PR 42'), findsOneWidget);
    });

    testWidgets('create as draft passes draft flag', (tester) async {
      _setDesktopViewport(tester);

      final lifecycle = _FakePrLifecycleRepository();

      await tester.pumpWidget(
        _wrapComposeScreen(
          const ComposePullRequestScreen(),
          repo: _testRepo(),
          workspaceId: 'ws1',
          lifecycle: lifecycle,
          preFillForm: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FButton, 'Create as draft'));
      await tester.pumpAndSettle();

      expect(lifecycle.createOnGitHubCallCount, 1);
      expect(lifecycle.lastDraftFlag, true);

      // Navigation still happens on success.
      expect(find.text('PR 42'), findsOneWidget);
    });

    testWidgets('failed submit shows snackbar with error', (tester) async {
      _setDesktopViewport(tester);

      final lifecycle = _FakePrLifecycleRepository()
        ..submitError = Exception('Network error');

      await tester.pumpWidget(
        _wrapComposeScreen(
          const ComposePullRequestScreen(),
          repo: _testRepo(),
          workspaceId: 'ws1',
          lifecycle: lifecycle,
          preFillForm: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FButton, 'Create pull request'));
      await tester.pumpAndSettle();

      // SnackBar should be visible with the error text.
      expect(
        find.text('Failed: Exception: Network error'),
        findsOneWidget,
      );

      // Should still be on the compose screen (form visible).
      expect(find.text('Open a pull request'), findsOneWidget);
    });

    testWidgets('submit button shows loading indicator while submitting', (
      tester,
    ) async {
      _setDesktopViewport(tester);

      // Use a never-completing future so the button stays in loading state.
      final completer = Completer<Map<String, dynamic>>();
      final lifecycle = _FakePrLifecycleRepository()
        ..createOnGitHubOverride = completer.future;

      await tester.pumpWidget(
        _wrapComposeScreen(
          const ComposePullRequestScreen(),
          repo: _testRepo(),
          workspaceId: 'ws1',
          lifecycle: lifecycle,
          preFillForm: true,
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(FButton, 'Create pull request'));

      // After the tap but before the future settles, the button should be
      // disabled and show a progress indicator.
      await tester.pump();
      await tester.pump();

      final createButton = tester.widget<FButton>(
        find.widgetWithText(FButton, 'Create pull request'),
      );
      expect(createButton.onPress, isNull);

      // FCircularProgress should be present inside the button area.
      expect(find.byType(FCircularProgress), findsOneWidget);

      // Complete the submit to clean up.
      completer.complete({'number': 99});
      await tester.pumpAndSettle();
    });
  });
}
