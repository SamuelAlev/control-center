import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:control_center/features/pr_review/domain/entities/pr_user.dart';
import 'package:control_center/features/pr_review/domain/entities/pull_request.dart';
import 'package:control_center/features/pr_review/domain/usecases/classify_pull_requests_use_case.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_list_screen.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_search_field.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Repo _repo(String id, String owner, String name) {
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

PullRequest _pr({
  required int number,
  required String title,
  String authorLogin = 'author',
  String body = '',
  bool isDraft = false,
  List<PrUser> requestedReviewers = const [],
}) {
  return PullRequest(
    id: number,
    number: number,
    title: title,
    body: body,
    state: PrState.open,
    isDraft: isDraft,
    author: PrUser(login: authorLogin, avatarUrl: ''),
    createdAt: DateTime(2024, 6, 15),
    updatedAt: DateTime(2024, 6, 15),
    repoFullName: 'owner/repo',
    htmlUrl: 'https://github.com/owner/repo/pull/$number',
    requestedReviewers: requestedReviewers,
    assignees: const [],
  );
}

class _EmptyDefaultFiltersNotifier extends PrListFiltersNotifier {
  @override
  PrListFilters build() => const PrListFilters();
}

class _TestWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws1';
}

void main() {
  late AppDatabase testDb;
  late SharedPreferences prefs;

  setUp(() async {
    testDb = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await testDb.close();
  });

  testWidgets('renders empty state with GitHub prompt when not authed', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
          isGitHubAuthenticatedProvider.overrideWith((ref) => false),
          currentUserLoginProvider.overrideWith((ref) => ''),
          prListDataProvider.overrideWith(
            (ref) => const AsyncValue.data(
              PrListData(priorityReviews: [], byRepo: []),
            ),
          ),
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
          home: Scaffold(
            body: FTheme(
              data: FThemes.zinc.light.desktop,
              child: const PullRequestListScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Pull requests'), findsOneWidget);
    expect(find.text('Connect GitHub to load pull requests'), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('renders empty state when all caught up', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
          isGitHubAuthenticatedProvider.overrideWith((ref) => true),
          currentUserLoginProvider.overrideWith((ref) => ''),
          activeWorkspaceIdProvider.overrideWith(_TestWorkspaceIdNotifier.new),
          reposForWorkspaceProvider('ws1').overrideWith(
            (ref) => Stream.value([
              Repo(
                id: 'r1',
                name: 'owner/repo',
                path: '/repos/owner/repo',
                githubOwner: 'owner',
                githubRepoName: 'repo',
                createdAt: DateTime(2024),
                updatedAt: DateTime(2024),
              ),
            ]),
          ),
          prListDataProvider.overrideWith(
            (ref) => const AsyncValue.data(
              PrListData(priorityReviews: [], byRepo: []),
            ),
          ),
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
          home: Scaffold(
            body: FTheme(
              data: FThemes.zinc.light.desktop,
              child: const PullRequestListScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('All caught up'), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('renders loading state', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
          isGitHubAuthenticatedProvider.overrideWith((ref) => true),
          currentUserLoginProvider.overrideWith((ref) => ''),
          prListDataProvider.overrideWith((ref) => const AsyncValue.loading()),
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
          home: Scaffold(
            body: FTheme(
              data: FThemes.zinc.light.desktop,
              child: const PullRequestListScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(FCircularProgress), findsWidgets);
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('renders error state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
          isGitHubAuthenticatedProvider.overrideWith((ref) => true),
          currentUserLoginProvider.overrideWith((ref) => ''),
          prListDataProvider.overrideWith(
            (ref) =>
                AsyncValue.error(Exception('Test error'), StackTrace.empty),
          ),
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
          home: Scaffold(
            body: FTheme(
              data: FThemes.zinc.light.desktop,
              child: const PullRequestListScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Failed to load'), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('renders the queue panel scoped to all open PRs', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _repo('r1', 'owner', 'repo');
    final pr = _pr(
      number: 101,
      title: 'Urgent security patch',
      authorLogin: 'security-team',
      requestedReviewers: [const PrUser(login: 'reviewer1', avatarUrl: '')],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
          isGitHubAuthenticatedProvider.overrideWith((ref) => true),
          currentUserLoginProvider.overrideWith((ref) => ''),
          prListDataProvider.overrideWith(
            (ref) => AsyncValue.data(
              PrListData(
                priorityReviews: const [],
                byRepo: [
                  RepoPullRequests(repo: repo, prs: [pr]),
                ],
              ),
            ),
          ),
          prListFiltersProvider.overrideWith(_EmptyDefaultFiltersNotifier.new),
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
          home: Scaffold(
            body: FTheme(
              data: FThemes.zinc.light.desktop,
              child: const PullRequestListScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // The decision lanes replace the old pinned "Priority reviews" carousel;
    // the queue panel opens scoped to all open PRs and renders the PR as a row.
    expect(find.text('All open PRs'), findsOneWidget);
    expect(find.text('Urgent security patch'), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('renders repository sections', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _repo('r1', 'owner', 'repo');
    final pr1 = _pr(number: 301, title: 'Feature A');
    final pr2 = _pr(number: 302, title: 'Feature B');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
          isGitHubAuthenticatedProvider.overrideWith((ref) => true),
          currentUserLoginProvider.overrideWith((ref) => ''),
          prListDataProvider.overrideWith(
            (ref) => AsyncValue.data(
              PrListData(
                priorityReviews: const [],
                byRepo: [
                  RepoPullRequests(repo: repo, prs: [pr1, pr2]),
                ],
              ),
            ),
          ),
          prListFiltersProvider.overrideWith(_EmptyDefaultFiltersNotifier.new),
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
          home: Scaffold(
            body: FTheme(
              data: FThemes.zinc.light.desktop,
              child: const PullRequestListScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('owner/repo'), findsOneWidget);
    expect(find.text('Feature A'), findsOneWidget);
    expect(find.text('Feature B'), findsOneWidget);
    // The relationship-filter rail has been replaced by the topbar search
    // field; the search field is what now lives in the header.
    expect(find.byType(PrSearchField), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('renders draft PRs as rows', (tester) async {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final repo = _repo('r1', 'owner', 'repo');
    final pr = _pr(number: 401, title: 'Draft feature', isDraft: true);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
          isGitHubAuthenticatedProvider.overrideWith((ref) => true),
          currentUserLoginProvider.overrideWith((ref) => ''),
          prListDataProvider.overrideWith(
            (ref) => AsyncValue.data(
              PrListData(
                priorityReviews: const [],
                byRepo: [
                  RepoPullRequests(repo: repo, prs: [pr]),
                ],
              ),
            ),
          ),
          prListFiltersProvider.overrideWith(_EmptyDefaultFiltersNotifier.new),
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
          home: Scaffold(
            body: FTheme(
              data: FThemes.zinc.light.desktop,
              child: const PullRequestListScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    // Draft state is conveyed by the row's status icon (with a "Draft"
    // tooltip), not a separate badge; the row itself renders.
    expect(find.text('Draft feature'), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('renders multiple PRs in a repo section', (tester) async {
    tester.view.physicalSize = const Size(1200, 2000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
    });

    final repo = _repo('r1', 'owner', 'repo');
    final reviewPr = _pr(
      number: 501,
      title: 'Critical fix',
      requestedReviewers: [const PrUser(login: 'reviewer1', avatarUrl: '')],
    );
    final normalPr = _pr(number: 503, title: 'Feature X');

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
          isGitHubAuthenticatedProvider.overrideWith((ref) => true),
          currentUserLoginProvider.overrideWith((ref) => ''),
          prListDataProvider.overrideWith(
            (ref) => AsyncValue.data(
              PrListData(
                priorityReviews: const [],
                byRepo: [
                  RepoPullRequests(repo: repo, prs: [reviewPr, normalPr]),
                ],
              ),
            ),
          ),
          prListFiltersProvider.overrideWith(_EmptyDefaultFiltersNotifier.new),
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
          home: Scaffold(
            body: FTheme(
              data: FThemes.zinc.light.desktop,
              child: const PullRequestListScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('owner/repo'), findsOneWidget);
    expect(find.text('Critical fix'), findsOneWidget);
    expect(find.text('Feature X'), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
