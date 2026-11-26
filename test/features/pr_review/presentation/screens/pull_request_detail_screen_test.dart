import 'dart:async';

import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/repositories/cache_repository.dart';
import 'package:cc_domain/features/pr_review/domain/entities/issue_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_code_review_comment.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_commit.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_review_submission.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/sources/pr_diff_source.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/messaging/providers/editor_layout_cache_provider.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail_screen.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_isolate_worker.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_detail_skeleton.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_diff_view/toolbar_chips.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/rigs/providers/rig_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/editor/editor_tab_bar.dart';
import 'package:control_center/shared/editor/host/editor_layout_persistence.dart'
    show EditorLayoutPersistence;
import 'package:control_center/shared/widgets/mouse_navigation_handler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/fake_rpc_client.dart';

Widget _wrap(Widget child) {
  return ProviderScope(
    child: MaterialApp.router(
      localizationsDelegates: [
        ...appLocalizationsDelegates,
        ...GlobalMaterialLocalizations.delegates,
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
PrRef _prRefOf(int number) => (
  workspaceId: 'ws',
  repoFullName: 'owner/repo',
  number: number,
  forge: null,
);

void main() {
  setUpAll(() => DiffWorkerPool.debugForceInline = true);
  tearDownAll(() {
    DiffWorkerPool.debugForceInline = false;
    return DiffWorkerPool.instance.shutdown();
  });

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
              // The screen resolves the forge registry and side providers
              // (repo permission, profile lookups) through the RPC client; a
              // client that never answers would leave request-timeout timers
              // pending. An always-empty host answers them; every stream the
              // assertions touch is overridden below.
              rpcClientProvider.overrideWithValue(
                (FakeRpcHost()..onCall = (op, args) => const {}).client(),
              ),
              prDetailProvider(
                _prRefOf(42),
              ).overrideWith((ref) => Stream.value(_samplePr())),
              githubUserProvider.overrideWith((ref) async => null),
              forgeConnectionsProvider.overrideWith((ref) async => []),
              rigCapabilitiesProvider.overrideWith((ref) async => []),
              // The screen resolves its detail only for a repo linked to the
              // workspace (`prRepoRowProvider` fail-closed gate), so an empty
              // stream would render "not found". Link owner/repo.
              reposForWorkspaceProvider.overrideWith(
                (ref, workspaceId) => Stream.value([
                  Repo(
                    id: 'repo-1',
                    name: 'repo',
                    path: '/tmp/repo',
                    remoteOwner: 'owner',
                    remoteName: 'repo',
                    createdAt: DateTime.utc(2026),
                    updatedAt: DateTime.utc(2026),
                  ),
                ]),
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
        expect(after.queryParameters['tab'], 'pr.diff');
        expect(after.queryParameters['commits'], sha);

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

    testWidgets(
      'headSha change on Overview before visiting Diff does not show DiffUpdateChip',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final detailController = StreamController<PullRequest?>();
        addTearDown(detailController.close);
        var filesLoadCount = 0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...baseOverrides(),
              rpcClientProvider.overrideWithValue(
                (FakeRpcHost()..onCall = (op, args) => const {}).client(),
              ),
              prDetailProvider(
                _prRefOf(42),
              ).overrideWith((ref) => detailController.stream),
              githubUserProvider.overrideWith((ref) async => null),
              forgeConnectionsProvider.overrideWith((ref) async => []),
              rigCapabilitiesProvider.overrideWith((ref) async => []),
              reposForWorkspaceProvider.overrideWith(
                (ref, workspaceId) => Stream.value([
                  Repo(
                    id: 'repo-1',
                    name: 'repo',
                    path: '/tmp/repo',
                    remoteOwner: 'owner',
                    remoteName: 'repo',
                    createdAt: DateTime.utc(2026),
                    updatedAt: DateTime.utc(2026),
                  ),
                ]),
              ),
              prFileIndexProvider(_prRefOf(42)).overrideWith(
                (ref) => Stream.value([
                  PrFile(
                    filename: 'a.dart',
                    status: PrFileStatus.modified,
                    additions: 1,
                    deletions: 0,
                    patch: '',
                  ),
                ]),
              ),
              prFilesLoadProvider(_prRefOf(42)).overrideWith((ref) {
                filesLoadCount++;
                return Stream.value(
                  PrFilesLoad(
                    files: [
                      PrFile(
                        filename: 'file_v$filesLoadCount.dart',
                        status: PrFileStatus.modified,
                        additions: 1,
                        deletions: 0,
                        patch: '@@ -1 +1 @@\n-old\n+new',
                      ),
                    ],
                    isComplete: true,
                  ),
                );
              }),
              prDiffProvider(_prRefOf(42)).overrideWith(
                (ref) => Stream.value('diff'),
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

        detailController.add(_samplePr(headSha: 'sha-1'));
        await tester.pump();
        await tester.pump();

        detailController.add(_samplePr(headSha: 'sha-2'));
        await tester.pump();
        await tester.pump();

        // Switch from Overview to Diff for the first time.
        tester.widget<EditorTabBar>(find.byType(EditorTabBar)).onTabSelected(1);
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(DiffUpdateChip), findsNothing);
        expect(filesLoadCount, 1);
        expect(find.textContaining('file_v1.dart'), findsWidgets);

        await tester.pumpWidget(Container());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      'switching back from Overview to previously visited Diff after headSha change auto-refreshes',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 2400);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final detailController = StreamController<PullRequest?>();
        addTearDown(detailController.close);
        var filesLoadCount = 0;

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...baseOverrides(),
              rpcClientProvider.overrideWithValue(
                (FakeRpcHost()..onCall = (op, args) => const {}).client(),
              ),
              prDetailProvider(
                _prRefOf(42),
              ).overrideWith((ref) => detailController.stream),
              githubUserProvider.overrideWith((ref) async => null),
              forgeConnectionsProvider.overrideWith((ref) async => []),
              rigCapabilitiesProvider.overrideWith((ref) async => []),
              reposForWorkspaceProvider.overrideWith(
                (ref, workspaceId) => Stream.value([
                  Repo(
                    id: 'repo-1',
                    name: 'repo',
                    path: '/tmp/repo',
                    remoteOwner: 'owner',
                    remoteName: 'repo',
                    createdAt: DateTime.utc(2026),
                    updatedAt: DateTime.utc(2026),
                  ),
                ]),
              ),
              prFileIndexProvider(_prRefOf(42)).overrideWith(
                (ref) => Stream.value([
                  PrFile(
                    filename: 'file_v$filesLoadCount.dart',
                    status: PrFileStatus.modified,
                    additions: 1,
                    deletions: 0,
                    patch: '',
                  ),
                ]),
              ),
              prFilesLoadProvider(_prRefOf(42)).overrideWith((ref) {
                filesLoadCount++;
                return Stream.value(
                  PrFilesLoad(
                    files: [
                      PrFile(
                        filename: 'file_v$filesLoadCount.dart',
                        status: PrFileStatus.modified,
                        additions: 1,
                        deletions: 0,
                        patch: '@@ -1 +1 @@\n-old\n+new',
                      ),
                    ],
                    isComplete: true,
                  ),
                );
              }),
              prDiffProvider(_prRefOf(42)).overrideWith(
                (ref) => Stream.value('diff'),
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

        detailController.add(_samplePr(headSha: 'sha-1'));
        await tester.pump();
        await tester.pump();

        // Visit Diff tab first.
        tester.widget<EditorTabBar>(find.byType(EditorTabBar)).onTabSelected(1);
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        expect(filesLoadCount, 1);

        // Switch back to Overview.
        tester.widget<EditorTabBar>(find.byType(EditorTabBar)).onTabSelected(0);
        await tester.pump();
        await tester.pump();

        // A new commit pushes while the user is on Overview.
        detailController.add(_samplePr(headSha: 'sha-2'));
        await tester.pump();
        await tester.pump();

        // Switch back to Diff: it should auto-refresh without requiring the chip button.
        tester.widget<EditorTabBar>(find.byType(EditorTabBar)).onTabSelected(1);
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        expect(find.byType(DiffUpdateChip), findsNothing);
        expect(filesLoadCount, 2);
        expect(find.textContaining('file_v2.dart'), findsWidgets);

        await tester.pumpWidget(Container());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      'clicking PR detail tabs adds to history and Back returns to latest visited tab',
      (tester) async {
        tester.view.physicalSize = const Size(1600, 1200);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final router = GoRouter(
          initialLocation: '/workspaces/ws/pull-requests',
          routes: [
            ShellRoute(
              builder: (context, state, child) => Consumer(
                builder: (context, ref, _) => MouseNavigationHandler(
                  historyController: ref.read(
                    navigationHistoryProvider.notifier,
                  ),
                  child: child,
                ),
              ),
              routes: [
                GoRoute(
                  path: '/workspaces/:workspaceId/pull-requests',
                  builder: (_, _) => const SizedBox(key: Key('pr-list-stub')),
                ),
                GoRoute(
                  path: '/workspaces/:workspaceId/pull-requests/:owner/:repo/:prNumber',
                  builder: (_, state) => CcTheme(
                    data: CcThemeData.light(),
                    child: PullRequestDetailScreen(
                      workspaceId: state.pathParameters['workspaceId']!,
                      owner: state.pathParameters['owner']!,
                      repo: state.pathParameters['repo']!,
                      prNumber: int.parse(state.pathParameters['prNumber']!),
                      focusedTabKey: state.uri.queryParameters['tab'],
                      pendingCommentId: int.tryParse(
                        state.uri.queryParameters['comment'] ?? '',
                      ),
                      scopedCommits: prCommitsFromQuery(
                        state.uri.queryParameters,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);

        final container = ProviderContainer(
          overrides: [
            ...baseOverrides(),
            rpcClientProvider.overrideWithValue(
              (FakeRpcHost()..onCall = (op, args) => const {}).client(),
            ),
            prDetailProvider(
              _prRefOf(42),
            ).overrideWith((ref) => Stream.value(_samplePr())),
            githubUserProvider.overrideWith((ref) async => null),
            forgeConnectionsProvider.overrideWith((ref) async => []),
            rigCapabilitiesProvider.overrideWith((ref) async => []),
            reposForWorkspaceProvider.overrideWith(
              (ref, workspaceId) => Stream.value([_sampleRepo()]),
            ),
          ],
        );
        addTearDown(container.dispose);

        NavigationHistoryController nav() =>
            container.read(navigationHistoryProvider.notifier);

        Future<void> settle() async {
          for (var i = 0; i < 6; i++) {
            await tester.pump(const Duration(milliseconds: 50));
          }
        }

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              localizationsDelegates: [
                ...appLocalizationsDelegates,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              routerConfig: router,
            ),
          ),
        );
        await tester.pumpAndSettle();

        router.go('/workspaces/ws/pull-requests/owner/repo/42');
        await settle();
        expect(router.state.uri.queryParameters['tab'], 'pr.overview');

        // Click the Diff tab: adds a history entry.
        tester.widget<EditorTabBar>(find.byType(EditorTabBar)).onTabSelected(1);
        await settle();
        expect(router.state.uri.queryParameters['tab'], 'pr.diff');

        // Back returns to Overview; Forward returns to Diff.
        nav().goBack();
        await settle();
        expect(router.state.uri.queryParameters['tab'], 'pr.overview');
        expect(
          tester.widget<EditorTabBar>(find.byType(EditorTabBar)).selectedIndex,
          0,
        );

        nav().goForward();
        await settle();
        expect(router.state.uri.queryParameters['tab'], 'pr.diff');
        expect(
          tester.widget<EditorTabBar>(find.byType(EditorTabBar)).selectedIndex,
          1,
        );

        // Leave PR detail and step Back: returns to Diff (latest visited tab).
        router.go('/workspaces/ws/pull-requests');
        await tester.pumpAndSettle();
        nav().goBack();
        await settle();
        expect(router.state.uri.queryParameters['tab'], 'pr.diff');
        expect(
          tester.widget<EditorTabBar>(find.byType(EditorTabBar)).selectedIndex,
          1,
        );

        await tester.pumpWidget(Container());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      'comment notification scrolls to Diff thread from offstage and stale cache',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final files = [
          for (var i = 0; i < 25; i++)
            PrFile(
              filename: i == 24 ? 'z_target.dart' : 'file_$i.dart',
              status: PrFileStatus.modified,
              additions: 2,
              deletions: 0,
              patch:
                  '@@ -1,3 +1,5 @@\n line1\n+addedA_$i\n+addedB_$i\n line4\n line5',
            ),
        ];
        final reviewComment = PrCodeReviewComment(
          id: 901,
          body: 'Target diff review comment',
          user: const PrUser(login: 'reviewer', avatarUrl: ''),
          path: 'z_target.dart',
          position: 2,
          line: 2,
          side: 'RIGHT',
          createdAt: DateTime.utc(2026, 9, 2),
          threadId: 'THREAD_901',
        );
        var commentSubCount = 0;

        final router = GoRouter(
          initialLocation: '/workspaces/ws/pull-requests/owner/repo/42',
          routes: [
            ShellRoute(
              builder: (context, state, child) => Consumer(
                builder: (context, ref, _) => MouseNavigationHandler(
                  historyController: ref.read(
                    navigationHistoryProvider.notifier,
                  ),
                  child: child,
                ),
              ),
              routes: [
                GoRoute(
                  path: '/workspaces/:workspaceId/pull-requests/:owner/:repo/:prNumber',
                  builder: (_, state) => CcTheme(
                    data: CcThemeData.light(),
                    child: PullRequestDetailScreen(
                      workspaceId: state.pathParameters['workspaceId']!,
                      owner: state.pathParameters['owner']!,
                      repo: state.pathParameters['repo']!,
                      prNumber: int.parse(state.pathParameters['prNumber']!),
                      focusedTabKey: state.uri.queryParameters['tab'],
                      pendingCommentId: int.tryParse(
                        state.uri.queryParameters['comment'] ?? '',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);

        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              ...baseOverrides(),
              rpcClientProvider.overrideWithValue(
                (FakeRpcHost()..onCall = (op, args) => const {}).client(),
              ),
              prDetailProvider(
                _prRefOf(42),
              ).overrideWith((ref) => Stream.value(_samplePr())),
              githubUserProvider.overrideWith((ref) async => null),
              forgeConnectionsProvider.overrideWith((ref) async => []),
              rigCapabilitiesProvider.overrideWith((ref) async => []),
              reposForWorkspaceProvider.overrideWith(
                (ref, workspaceId) => Stream.value([_sampleRepo()]),
              ),
              prFileIndexProvider(
                _prRefOf(42),
              ).overrideWith((ref) => Stream.value(files)),
              prFilesLoadProvider(_prRefOf(42)).overrideWith(
                (ref) => Stream.value(PrFilesLoad(files: files, isComplete: true)),
              ),
              prReviewCommentsProvider(_prRefOf(42)).overrideWith((ref) {
                commentSubCount++;
                // First subscription returns stale empty list; invalidation
                // yields the fresh list containing comment 901.
                return Stream.value(
                  commentSubCount == 1 ? const [] : [reviewComment],
                );
              }),
            ],
            child: MaterialApp.router(
              localizationsDelegates: [
                ...appLocalizationsDelegates,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              routerConfig: router,
            ),
          ),
        );
        await tester.pump();
        await tester.pump();

        // Visit Diff once so PrDiffTab stays mounted offstage, then return to Overview.
        tester.widget<EditorTabBar>(find.byType(EditorTabBar)).onTabSelected(1);
        await tester.pump();
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));
        tester.widget<EditorTabBar>(find.byType(EditorTabBar)).onTabSelected(0);
        await tester.pump();
        await tester.pump();
        expect(
          tester.widget<EditorTabBar>(find.byType(EditorTabBar)).selectedIndex,
          0,
        );

        // Notification deep-links to comment 901 in Diff.
        router.go(
          '/workspaces/ws/pull-requests/owner/repo/42?tab=pr.diff&comment=901',
        );
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        expect(
          tester.widget<EditorTabBar>(find.byType(EditorTabBar)).selectedIndex,
          1,
        );
        expect(commentSubCount, greaterThanOrEqualTo(2));
        expect(find.text('Target diff review comment'), findsOneWidget);

        await tester.pumpWidget(Container());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );

    testWidgets(
      'comment notification scrolls to Overview issue comment and outdated review thread',
      (tester) async {
        tester.view.physicalSize = const Size(1400, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final issueComments = [
          for (var i = 1; i <= 15; i++)
            IssueComment(
              id: 500 + i,
              body: i == 15
                  ? 'Target overview issue comment'
                  : 'Filler issue comment #$i with several words of context.',
              user: const PrUser(login: 'commenter', avatarUrl: ''),
              createdAt: DateTime.utc(2026, 9, 2, 0, i),
            ),
        ];
        final outdatedReview = PrReviewSubmission(
          id: 800,
          state: PrReviewSubmissionState.commented,
          author: const PrUser(login: 'reviewer', avatarUrl: ''),
          body: 'Review summary',
          submittedAt: DateTime.utc(2026, 9, 2, 1),
        );
        final outdatedComment = PrCodeReviewComment(
          id: 702,
          reviewId: 800,
          body: 'Outdated thread target comment',
          user: const PrUser(login: 'reviewer', avatarUrl: ''),
          path: 'old.dart',
          position: null,
          line: null,
          isOutdated: true,
          isResolved: true,
          createdAt: DateTime.utc(2026, 9, 2, 1),
          threadId: 'THREAD_702',
        );

        final router = GoRouter(
          initialLocation: '/workspaces/ws/pull-requests/owner/repo/42',
          routes: [
            ShellRoute(
              builder: (context, state, child) => Consumer(
                builder: (context, ref, _) => MouseNavigationHandler(
                  historyController: ref.read(
                    navigationHistoryProvider.notifier,
                  ),
                  child: child,
                ),
              ),
              routes: [
                GoRoute(
                  path: '/workspaces/:workspaceId/pull-requests/:owner/:repo/:prNumber',
                  builder: (_, state) => CcTheme(
                    data: CcThemeData.light(),
                    child: PullRequestDetailScreen(
                      workspaceId: state.pathParameters['workspaceId']!,
                      owner: state.pathParameters['owner']!,
                      repo: state.pathParameters['repo']!,
                      prNumber: int.parse(state.pathParameters['prNumber']!),
                      focusedTabKey: state.uri.queryParameters['tab'],
                      pendingCommentId: int.tryParse(
                        state.uri.queryParameters['comment'] ?? '',
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
        addTearDown(router.dispose);

        final container = ProviderContainer(
          overrides: [
            ...baseOverrides(),
            rpcClientProvider.overrideWithValue(
              (FakeRpcHost()..onCall = (op, args) => const {}).client(),
            ),
            prDetailProvider(
              _prRefOf(42),
            ).overrideWith((ref) => Stream.value(_samplePr())),
            githubUserProvider.overrideWith((ref) async => null),
            forgeConnectionsProvider.overrideWith((ref) async => []),
            rigCapabilitiesProvider.overrideWith((ref) async => []),
            reposForWorkspaceProvider.overrideWith(
              (ref, workspaceId) => Stream.value([_sampleRepo()]),
            ),
            prIssueCommentsProvider(
              _prRefOf(42),
            ).overrideWith((ref) => Stream.value(issueComments)),
            prReviewsProvider(
              _prRefOf(42),
            ).overrideWith((ref) => Stream.value([outdatedReview])),
            prReviewCommentIndexProvider(
              _prRefOf(42),
            ).overrideWith((ref) => Stream.value([outdatedComment])),
            prReviewCommentsProvider(
              _prRefOf(42),
            ).overrideWith((ref) => Stream.value([outdatedComment])),
            prFilesLoadProvider(_prRefOf(42)).overrideWith(
              (ref) => Stream.value(
                const PrFilesLoad(files: [], isComplete: true),
              ),
            ),
            prFileIndexProvider(
              _prRefOf(42),
            ).overrideWith((ref) => Stream.value(const [])),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp.router(
              localizationsDelegates: [
                ...appLocalizationsDelegates,
                ...GlobalMaterialLocalizations.delegates,
              ],
              supportedLocales: AppLocalizations.supportedLocales,
              locale: const Locale('en'),
              routerConfig: router,
            ),
          ),
        );
        for (var i = 0; i < 8; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }

        // Issue comment deep link scrolls Overview timeline to comment 515.
        router.go(
          '/workspaces/ws/pull-requests/owner/repo/42?tab=pr.overview&comment=515',
        );
        for (var i = 0; i < 16; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(find.text('Target overview issue comment'), findsOneWidget);

        // Outdated review comment routed to Diff falls back to Overview and
        // expands + scrolls to the thread.
        router.go(
          '/workspaces/ws/pull-requests/owner/repo/42?tab=pr.diff&comment=702',
        );
        for (var i = 0; i < 20; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(
          tester.widget<EditorTabBar>(find.byType(EditorTabBar)).selectedIndex,
          0,
        );
        expect(find.text('Outdated thread target comment'), findsOneWidget);
        expect(router.state.uri.queryParameters['tab'], 'pr.overview');
        expect(router.state.uri.queryParameters['comment'], '702');

        // Back skips the transient Diff entry and lands cleanly on the prior
        // Overview entry instead of looping back into fallback.
        container.read(navigationHistoryProvider.notifier).goBack();
        for (var i = 0; i < 10; i++) {
          await tester.pump(const Duration(milliseconds: 50));
        }
        expect(router.state.uri.queryParameters['tab'], 'pr.overview');
        expect(router.state.uri.queryParameters['comment'], '515');

        await tester.pumpWidget(Container());
        await tester.pump(const Duration(milliseconds: 100));
      },
    );
  });
}

Repo _sampleRepo() => Repo(
  id: 'repo-1',
  name: 'repo',
  path: '/tmp/repo',
  remoteOwner: 'owner',
  remoteName: 'repo',
  createdAt: DateTime.utc(2026),
  updatedAt: DateTime.utc(2026),
);

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

PullRequest _samplePr({String headSha = ''}) {
  return PullRequest(
    id: 1,
    number: 42,
    title: 'Add logout links',
    body: '',
    state: PrState.open,
    isDraft: false,
    headSha: headSha,
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
