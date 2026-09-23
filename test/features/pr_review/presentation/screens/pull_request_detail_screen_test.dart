import 'dart:async';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/cache_repository.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/messaging/providers/editor_layout_cache_provider.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail_screen.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_detail_skeleton.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/editor/editor_tab_bar.dart';
import 'package:control_center/shared/editor/host/editor_layout_persistence.dart'
    show EditorLayoutPersistence;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp.router(
      localizationsDelegates: [
        ...AppLocalizations.localizationsDelegates,
        GlobalMaterialLocalizations.delegate, // ignore: deprecated_member_use
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate, // ignore: deprecated_member_use
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      routerConfig: GoRouter(
        initialLocation: '/',
        routes: [GoRoute(path: '/', builder: (_, _) => child)],
      ),
    ),
  );
}

/// No-op layout cache so the PR workbench's [EditorLayoutPersistence] never
/// reaches for the (unoverridden) RPC client during a widget test.
class _NoopCacheRepository implements CacheRepository {
  @override
  Future<String?> read(String workspaceId, String kind, String key) async =>
      null;
  @override
  Future<void> put(
    String workspaceId,
    String kind,
    String key,
    String payload,
  ) async {}
  @override
  Future<void> deleteEntry(String workspaceId, String kind, String key) async {}
  @override
  Future<void> deleteKind(String workspaceId, String kind) async {}
  @override
  Future<void> deleteKindWithPrefix(
    String workspaceId,
    String kind,
    String keyPrefix,
  ) async {}
}

/// The [PrRef] for this suite's screens: `owner/repo` in workspace `ws`.
PrRef _prRefOf(int number) =>
    (workspaceId: 'ws', repoFullName: 'owner/repo', number: number);

void main() {
  late AppPreferences prefs;

  setUp(() async {
    prefs = AppPreferences.inMemory();
  });

  List baseOverrides({int prNumber = 42}) {
    return [
      appPreferencesProvider.overrideWithValue(prefs),
      codeFontFamilyProvider.overrideWithValue('Fira Code'),
      activeRepoProvider.overrideWith((ref) => null),
      workspacesProvider.overrideWith(
        (ref) => const Stream<List<Workspace>>.empty(),
      ),
      editorLayoutCacheRepositoryProvider.overrideWithValue(
        _NoopCacheRepository(),
      ),
    ];
  }

  group('PullRequestDetailScreen', () {
    testWidgets('loading workbench tabs remain switchable', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            prDetailProvider(
              _prRefOf(42),
            ).overrideWith((ref) => const Stream.empty()),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                workspaceId: 'ws',
                owner: 'owner',
                repo: 'repo',
                prNumber: 42,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byType(PrOverviewSkeleton), findsOneWidget);
      final tabBar = tester.widget<EditorTabBar>(find.byType(EditorTabBar));
      expect(tabBar.selectedIndex, 0);
      tabBar.onTabSelected(1);
      await tester.pump();
      expect(
        tester.widget<EditorTabBar>(find.byType(EditorTabBar)).selectedIndex,
        1,
      );
      expect(find.byType(PrDiffTabSkeleton), findsOneWidget);
      expect(find.byType(PrOverviewSkeleton), findsNothing);

      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('renders not found state when PR is null', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(prNumber: 99),
            prDetailProvider(
              _prRefOf(99),
            ).overrideWith((ref) => Stream.value(null)),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                workspaceId: 'ws',
                owner: 'owner',
                repo: 'repo',
                prNumber: 99,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Pull request not found'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('not found state shows helpful message', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(prNumber: 999),
            prDetailProvider(
              _prRefOf(999),
            ).overrideWith((ref) => Stream.value(null)),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                workspaceId: 'ws',
                owner: 'owner',
                repo: 'repo',
                prNumber: 999,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.text('It may have been merged, closed, or moved.'),
        findsOneWidget,
      );
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('error state shows error message', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            prDetailProvider(_prRefOf(42)).overrideWithValue(
              AsyncValue.error(Exception('Failed'), StackTrace.empty),
            ),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                workspaceId: 'ws',
                owner: 'owner',
                repo: 'repo',
                prNumber: 42,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Couldn\'t load this pull request'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('error state shows exception text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            prDetailProvider(_prRefOf(42)).overrideWithValue(
              AsyncValue.error(
                Exception('rate limit exceeded'),
                StackTrace.empty,
              ),
            ),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                workspaceId: 'ws',
                owner: 'owner',
                repo: 'repo',
                prNumber: 42,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      // Raw exception text is tucked behind a "Show details" disclosure so it
      // never greets the user by default.
      expect(find.textContaining('rate limit exceeded'), findsNothing);
      await tester.tap(find.text('Show details'));
      await tester.pump();
      expect(find.textContaining('rate limit exceeded'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('not found state shows icon and page wrapper', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(prNumber: 555),
            prDetailProvider(
              _prRefOf(555),
            ).overrideWith((ref) => Stream.value(null)),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                workspaceId: 'ws',
                owner: 'owner',
                repo: 'repo',
                prNumber: 555,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Pull request not found'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('error state shows couldn\'t-load title', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(),
            prDetailProvider(_prRefOf(42)).overrideWithValue(
              AsyncValue.error(Exception('timeout'), StackTrace.empty),
            ),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                workspaceId: 'ws',
                owner: 'owner',
                repo: 'repo',
                prNumber: 42,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(find.text('Couldn\'t load this pull request'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets('not found state renders not found text', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...baseOverrides(prNumber: 404),
            prDetailProvider(
              _prRefOf(404),
            ).overrideWith((ref) => Stream.value(null)),
          ],
          child: _wrap(
            CcTheme(
              data: CcThemeData.light(),
              child: const PullRequestDetailScreen(
                workspaceId: 'ws',
                owner: 'owner',
                repo: 'repo',
                prNumber: 404,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Pull request not found'), findsOneWidget);
      await tester.pumpWidget(Container());
      await tester.pump(const Duration(milliseconds: 100));
    });

    testWidgets(
      'a timeline commit opens the diff and back does not rebuild the provider',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        const sha = 'abcdef1234567890';
        final hostKey = GlobalKey<_CommitScopeHostState>();
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...baseOverrides(),
              prDetailProvider(
                _prRefOf(42),
              ).overrideWith((ref) => Stream.value(_samplePr())),
              githubUserProvider.overrideWith((ref) async => null),
              forgeConnectionsProvider.overrideWith((ref) async => []),
              rigCapabilitiesProvider.overrideWith((ref) async => []),
              reposForWorkspaceProvider.overrideWith(
                (ref, workspaceId) => const Stream.empty(),
              ),
              prCommitsProvider(
                _prRefOf(42),
              ).overrideWith((ref) => Stream.value([_sampleCommit(sha)])),
            ],
            child: _wrap(
              CcTheme(
                data: CcThemeData.light(),
                child: _CommitScopeHost(key: hostKey),
              ),
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        expect(find.text('Something went wrong'), findsNothing);
        expect(find.text('Activity'), findsOneWidget);
        final commitLink = find.textContaining('abcdef1');
        expect(commitLink, findsOneWidget);
        await tester.ensureVisible(commitLink);
        final before = GoRouter.of(
          tester.element(find.byType(PullRequestDetailScreen)),
        ).state.uri;
        expect(
          tester.widget<EditorTabBar>(find.byType(EditorTabBar)).selectedIndex,
          0,
        );

        await tester.tap(commitLink);
        await tester.pump();
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('Something went wrong'), findsNothing);
        expect(
          tester.widget<EditorTabBar>(find.byType(EditorTabBar)).selectedIndex,
          1,
        );
        final after = GoRouter.of(
          tester.element(find.byType(PullRequestDetailScreen)),
        ).state.uri;
        expect(after.path, before.path);
        expect(after.queryParameters, before.queryParameters);

        hostKey.currentState!.setCommits({sha});
        await tester.pump();
        await tester.pump();
        hostKey.currentState!.setCommits(const {});
        await tester.pump();
        await tester.pump();

        expect(tester.takeException(), isNull);
        expect(find.text('Something went wrong'), findsNothing);
        expect(find.byType(EditorTabBar), findsOneWidget);

        await tester.pumpWidget(Container());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}

class _CommitScopeHost extends StatefulWidget {
  const _CommitScopeHost({super.key});

  @override
  State<_CommitScopeHost> createState() => _CommitScopeHostState();
}

class _CommitScopeHostState extends State<_CommitScopeHost> {
  Set<String> _commits = const {};

  void setCommits(Set<String> commits) => setState(() => _commits = commits);

  @override
  Widget build(BuildContext context) {
    return PullRequestDetailScreen(
      workspaceId: 'ws',
      owner: 'owner',
      repo: 'repo',
      prNumber: 42,
      scopedCommits: _commits,
    );
  }
}

PullRequest _samplePr() {
  return PullRequest(
    id: 1,
    number: 42,
    title: 'Add logout links',
    body: '',
    state: PrState.open,
    isDraft: false,
    author: const PrUser(login: 'octocat', avatarUrl: ''),
    createdAt: DateTime.utc(2026, 9, 1),
    updatedAt: DateTime.utc(2026, 9, 2),
    repoFullName: 'owner/repo',
    htmlUrl: 'https://github.com/owner/repo/pull/42',
    commitsCount: 1,
  );
}

PrCommit _sampleCommit(String sha) {
  return PrCommit(
    sha: sha,
    message: 'Fix the logout link',
    author: const PrUser(login: 'octocat', avatarUrl: ''),
    date: DateTime.utc(2026, 9, 2),
  );
}
