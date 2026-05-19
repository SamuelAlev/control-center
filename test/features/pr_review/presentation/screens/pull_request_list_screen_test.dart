import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/pr_review/domain/entities/enriched_pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/repositories/pr_review_repository.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_list_screen.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/misc.dart';

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
  String repoFullName = 'acme/alpha',
  String authorLogin = 'author',
}) {
  return PullRequest(
    id: number,
    number: number,
    title: title,
    body: '',
    state: PrState.open,
    isDraft: false,
    author: PrUser(login: authorLogin, avatarUrl: ''),
    createdAt: DateTime(2024, 6, 15),
    updatedAt: DateTime(2024, 6, 15),
    repoFullName: repoFullName,
    htmlUrl: 'https://github.com/$repoFullName/pull/$number',
    requestedReviewers: const [],
    assignees: const [],
  );
}

class _TestWorkspaceIdNotifier extends ActiveWorkspaceIdNotifier {
  @override
  String? build() => 'ws1';
}

/// Server reports itself NOT GitHub-authenticated — drives the "connect
/// GitHub" gate, which reads `prsByRepoProvider.authenticated`.
class _UnauthedPrsByRepoNotifier extends PrsByRepoNotifier {
  @override
  Future<PrsByRepoState> build() async => const PrsByRepoState(
    repos: [],
    hasMore: {},
    nextPage: {},
    loadingMore: {},
    authenticated: false,
  );
}

/// An authenticated but empty snapshot (server has a token, no PRs loaded) —
/// so the screen gets past its loading gate to the no-repos check.
class _EmptyAuthedPrsByRepoNotifier extends PrsByRepoNotifier {
  @override
  Future<PrsByRepoState> build() async => const PrsByRepoState(
    repos: [],
    hasMore: {},
    nextPage: {},
    loadingMore: {},
  );
}

/// A seeded snapshot: two repos, each with one open PR.
class _SeededPrsByRepoNotifier extends PrsByRepoNotifier {
  @override
  Future<PrsByRepoState> build() async => PrsByRepoState(
    repos: [
      RepoPullRequests(
        repo: _repo('rA', 'acme', 'alpha'),
        prs: [
          _pr(number: 1, title: 'Alpha change', repoFullName: 'acme/alpha'),
        ],
      ),
      RepoPullRequests(
        repo: _repo('rB', 'acme', 'beta'),
        prs: [_pr(number: 2, title: 'Beta change', repoFullName: 'acme/beta')],
      ),
    ],
    hasMore: const {},
    nextPage: const {},
    loadingMore: const {},
  );
}

Widget _host(List<Override> overrides) {
  return ProviderScope(
    overrides: overrides,
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
        body: CcTheme(
          data: CcThemeData.light(),
          child: const PullRequestListScreen(),
        ),
      ),
    ),
  );
}

void main() {
  late AppPreferences prefs;

  setUp(() {
    prefs = AppPreferences.inMemory();
  });

  void sizeView(WidgetTester tester) {
    tester.view.physicalSize = const Size(1200, 800);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  testWidgets('shows the connect-GitHub gate when the server is unauthed', (
    tester,
  ) async {
    sizeView(tester);
    await tester.pumpWidget(
      _host([
        appPreferencesProvider.overrideWithValue(prefs),
        activeWorkspaceIdProvider.overrideWith(_TestWorkspaceIdNotifier.new),
        prsByRepoProvider.overrideWith(_UnauthedPrsByRepoNotifier.new),
        currentUserLoginProvider.overrideWith((ref) => ''),
        prReviewRepositoryProvider.overrideWith(
          (ref) => const EmptyPrReviewRepository(),
        ),
      ]),
    );
    await tester.pump();

    expect(find.text('Pull requests'), findsOneWidget);
    expect(find.text('Connect GitHub to load pull requests'), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('shows the no-repositories gate when authed with no repos', (
    tester,
  ) async {
    sizeView(tester);
    await tester.pumpWidget(
      _host([
        appPreferencesProvider.overrideWithValue(prefs),
        activeWorkspaceIdProvider.overrideWith(_TestWorkspaceIdNotifier.new),
        reposForWorkspaceProvider(
          'ws1',
        ).overrideWith((ref) => Stream.value(const [])),
        prsByRepoProvider.overrideWith(_EmptyAuthedPrsByRepoNotifier.new),
        currentUserLoginProvider.overrideWith((ref) => ''),
        prReviewRepositoryProvider.overrideWith(
          (ref) => const EmptyPrReviewRepository(),
        ),
      ]),
    );
    await tester.pump();

    expect(find.text('No repositories configured'), findsOneWidget);
    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('lists every repo in the rail and shows the first repo\'s PRs', (
    tester,
  ) async {
    sizeView(tester);
    await tester.pumpWidget(
      _host([
        appPreferencesProvider.overrideWithValue(prefs),
        activeWorkspaceIdProvider.overrideWith(_TestWorkspaceIdNotifier.new),
        reposForWorkspaceProvider('ws1').overrideWith(
          (ref) => Stream.value([
            _repo('rA', 'acme', 'alpha'),
            _repo('rB', 'acme', 'beta'),
          ]),
        ),
        prsByRepoProvider.overrideWith(_SeededPrsByRepoNotifier.new),
        currentUserLoginProvider.overrideWith((ref) => 'author'),
        prReviewRepositoryProvider.overrideWith(
          (ref) => const EmptyPrReviewRepository(),
        ),
      ]),
    );
    await tester.pump();

    // Both repos appear in the left rail…
    expect(find.text('acme/alpha'), findsOneWidget);
    expect(find.text('acme/beta'), findsOneWidget);
    // …and the first repo (preselected) shows its PR in the detail, while the
    // second repo's PR is not rendered until its rail entry is picked.
    expect(find.text('Alpha change'), findsOneWidget);
    expect(find.text('Beta change'), findsNothing);

    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
