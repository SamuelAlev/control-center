import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/features/auth/domain/entities/api_credentials.dart';
import 'package:control_center/features/auth/presentation/screens/api_keys_screen.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/auth/providers/onboarding_providers.dart';
import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail_screen.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_list_screen.dart';
import 'package:control_center/features/settings/presentation/screens/settings_screen.dart';
import 'package:control_center/features/shell/presentation/layout/control_center_layout.dart';
import 'package:control_center/features/workspaces/presentation/screens/workspace_list_screen.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/router/guards.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

RouteBase _dummyRoute() =>
    GoRoute(path: '/', builder: (_, _) => const SizedBox());

GoRouterState _stateWithLocation(String matchedLocation) {
  final routingNotifier = ValueNotifier(RoutingConfig(routes: [_dummyRoute()]));
  final config = RouteConfiguration(
    routingNotifier,
    navigatorKey: GlobalKey<NavigatorState>(),
  );
  return GoRouterState(
    config,
    uri: Uri.parse(matchedLocation),
    matchedLocation: matchedLocation,
    fullPath: matchedLocation,
    pathParameters: const {},
    pageKey: ValueKey(matchedLocation),
  );
}

Workspace _workspaceRow({String id = 'ws-1', String name = 'Test'}) {
  return Workspace(
    id: id,
    name: name,
    createdAt: DateTime(2025),
    updatedAt: DateTime(2025),
  );
}

GoRouter _buildRouter({OnboardingGate gate = OnboardingGate.complete}) {
  final gateNotifier = ValueNotifier<OnboardingGate>(gate);
  return GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(),
    initialLocation: splashRoute,
    refreshListenable: gateNotifier,
    redirect: (context, state) =>
        onboardingGuard(context, state, gateNotifier, () => 'ws-1'),
    routes: [
      GoRoute(
        path: splashRoute,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const SizedBox.shrink(),
        ),
      ),
      GoRoute(
        path: onboardingRoute,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const OnboardingScreen(),
        ),
      ),
      // The picker is full-screen, outside the workspace shell.
      GoRoute(
        path: workspaceListRoute,
        pageBuilder: (context, state) => NoTransitionPage(
          key: state.pageKey,
          child: const WorkspaceListScreen(),
        ),
      ),
      // A bare `/workspaces/:workspaceId` enters the workspace dashboard.
      GoRoute(
        path: workspaceRoot(workspaceIdParam),
        redirect: (context, state) =>
            dashboardRoute(state.pathParameters['workspaceId']!),
      ),
      ShellRoute(
        builder: (context, state, child) => ControlCenterLayout(child: child),
        routes: [
          GoRoute(
            path: dashboardRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const DashboardScreen(),
            ),
          ),
          GoRoute(
            path: pullRequestsRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const PullRequestListScreen(),
            ),
            routes: [
              GoRoute(
                path: ':owner/:repo/:prNumber',
                pageBuilder: (context, state) {
                  final prNumber =
                      int.tryParse(state.pathParameters['prNumber'] ?? '') ?? 0;
                  return NoTransitionPage(
                    key: state.pageKey,
                    child: PullRequestDetailScreen(
                      owner: state.pathParameters['owner']!,
                      repo: state.pathParameters['repo']!,
                      prNumber: prNumber,
                    ),
                  );
                },
              ),
            ],
          ),
          GoRoute(
            path: apiKeysRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const ApiKeysScreen(),
            ),
          ),
          GoRoute(
            path: settingsRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const AdaptersSettingsScreen(),
            ),
          ),
        ],
      ),
    ],
  );
}

void main() {
  // ---------------------------------------------------------------------------
  // Route path constants & helpers
  // ---------------------------------------------------------------------------
  group('Route path constants', () {
    test(
      'apiKeysRoute',
      () => expect(apiKeysRoute('w1'), '/workspaces/w1/api-keys'),
    );
    test('onboardingRoute', () => expect(onboardingRoute, '/onboarding'));
    test(
      'dashboardRoute',
      () => expect(dashboardRoute('w1'), '/workspaces/w1/dashboard'),
    );
    test(
      'pullRequestsRoute',
      () => expect(pullRequestsRoute('w1'), '/workspaces/w1/pull-requests'),
    );
    test('workspaceListRoute', () => expect(workspaceListRoute, '/workspaces'));
    test(
      'settingsRoute',
      () => expect(settingsRoute('w1'), '/workspaces/w1/settings'),
    );
  });

  group('pullRequestDetailRoute', () {
    test('positive number', () {
      expect(
        pullRequestDetailRoute('w1', 'acme/web', 42),
        '/workspaces/w1/pull-requests/acme/web/42',
      );
    });
    test('zero', () {
      expect(
        pullRequestDetailRoute('w1', 'acme/web', 0),
        '/workspaces/w1/pull-requests/acme/web/0',
      );
    });
    test('large number', () {
      expect(
        pullRequestDetailRoute('w1', 'acme/web', 99999),
        '/workspaces/w1/pull-requests/acme/web/99999',
      );
    });
    test('negative number', () {
      expect(
        pullRequestDetailRoute('w1', 'acme/web', -1),
        '/workspaces/w1/pull-requests/acme/web/-1',
      );
    });
  });

  group('workspace root routes', () {
    test('workspaceRoot simple id', () {
      expect(workspaceRoot('abc123'), '/workspaces/abc123');
    });
    test('workspaceRoot uuid', () {
      expect(
        workspaceRoot('550e8400-e29b-41d4-a716-446655440000'),
        '/workspaces/550e8400-e29b-41d4-a716-446655440000',
      );
    });
  });

  // ---------------------------------------------------------------------------
  // onboardingGuard
  // ---------------------------------------------------------------------------
  group('onboardingGuard', () {
    testWidgets(
      'redirects to onboarding when incomplete and not on onboarding',
      (tester) async {
        await tester.pumpWidget(const SizedBox());
        final context = tester.element(find.byType(SizedBox));
        final notifier = ValueNotifier<OnboardingGate>(
          OnboardingGate.incomplete,
        );

        final result = onboardingGuard(
          context,
          _stateWithLocation('/dashboard'),
          notifier,
          () => 'ws-1',
        );

        expect(result, onboardingRoute);
        notifier.dispose();
      },
    );

    testWidgets('stays on onboarding when gate flips to complete mid-flow', (
      tester,
    ) async {
      // The workspace step satisfies the gate before step 3 (voice model) is
      // shown — the guard must not eject the user mid-flow. The screen
      // navigates to the dashboard itself once the final step is completed.
      await tester.pumpWidget(const SizedBox());
      final context = tester.element(find.byType(SizedBox));
      final notifier = ValueNotifier<OnboardingGate>(OnboardingGate.complete);

      final result = onboardingGuard(
        context,
        _stateWithLocation('/onboarding'),
        notifier,
        () => 'ws-1',
      );

      expect(result, isNull);
      notifier.dispose();
    });

    testWidgets('returns null when complete and on dashboard', (tester) async {
      await tester.pumpWidget(const SizedBox());
      final context = tester.element(find.byType(SizedBox));
      final notifier = ValueNotifier<OnboardingGate>(OnboardingGate.complete);

      final result = onboardingGuard(
        context,
        _stateWithLocation('/dashboard'),
        notifier,
        () => 'ws-1',
      );

      expect(result, isNull);
      notifier.dispose();
    });

    testWidgets('returns null when incomplete but already on onboarding', (
      tester,
    ) async {
      await tester.pumpWidget(const SizedBox());
      final context = tester.element(find.byType(SizedBox));
      final notifier = ValueNotifier<OnboardingGate>(OnboardingGate.incomplete);

      final result = onboardingGuard(
        context,
        _stateWithLocation('/onboarding'),
        notifier,
        () => 'ws-1',
      );

      expect(result, isNull);
      notifier.dispose();
    });

    testWidgets('returns null for any valid route when complete', (
      tester,
    ) async {
      await tester.pumpWidget(const SizedBox());
      final context = tester.element(find.byType(SizedBox));
      final notifier = ValueNotifier<OnboardingGate>(OnboardingGate.complete);
      final routes = <String>[
        '/dashboard',
        '/pull-requests',
        '/pull-requests/acme/web/1',
        '/agents',
        '/workspaces',
        '/workspaces/abc',
        '/inbox',
        '/settings',
        '/api-keys',
      ];

      for (final route in routes) {
        final result = onboardingGuard(
          context,
          _stateWithLocation(route),
          notifier,
          () => 'ws-1',
        );
        expect(result, isNull, reason: 'Expected null for route $route');
      }

      notifier.dispose();
    });

    testWidgets(
      'redirects to onboarding for any non-onboarding route when incomplete',
      (tester) async {
        await tester.pumpWidget(const SizedBox());
        final context = tester.element(find.byType(SizedBox));
        final notifier = ValueNotifier<OnboardingGate>(
          OnboardingGate.incomplete,
        );
        final routes = <String>[
          '/dashboard',
          '/pull-requests',
          '/pull-requests/acme/web/1',
          '/agents',
          '/workspaces',
          '/workspaces/abc',
          '/inbox',
          '/settings',
          '/api-keys',
        ];

        for (final route in routes) {
          final result = onboardingGuard(
            context,
            _stateWithLocation(route),
            notifier,
            () => 'ws-1',
          );
          expect(
            result,
            onboardingRoute,
            reason: 'Expected onboarding redirect for route $route',
          );
        }

        notifier.dispose();
      },
    );

    testWidgets('handles ValueNotifier updates between calls', (tester) async {
      await tester.pumpWidget(const SizedBox());
      final context = tester.element(find.byType(SizedBox));
      final notifier = ValueNotifier<OnboardingGate>(OnboardingGate.incomplete);

      expect(
        onboardingGuard(
          context,
          _stateWithLocation('/dashboard'),
          notifier,
          () => 'ws-1',
        ),
        onboardingRoute,
      );

      notifier.value = OnboardingGate.complete;

      expect(
        onboardingGuard(
          context,
          _stateWithLocation('/dashboard'),
          notifier,
          () => 'ws-1',
        ),
        isNull,
      );

      expect(
        onboardingGuard(
          context,
          _stateWithLocation('/onboarding'),
          notifier,
          () => 'ws-1',
        ),
        isNull,
      );

      notifier.dispose();
    });

    testWidgets('matchedLocation with trailing slash still matches', (
      tester,
    ) async {
      await tester.pumpWidget(const SizedBox());
      final context = tester.element(find.byType(SizedBox));
      final notifier = ValueNotifier<OnboardingGate>(OnboardingGate.incomplete);

      final result = onboardingGuard(
        context,
        _stateWithLocation('/onboarding/'),
        notifier,
        () => 'ws-1',
      );

      expect(result, isNull);
      notifier.dispose();
    });

    testWidgets('keeps the user on splash while loading', (tester) async {
      await tester.pumpWidget(const SizedBox());
      final context = tester.element(find.byType(SizedBox));
      final notifier = ValueNotifier<OnboardingGate>(OnboardingGate.loading);

      expect(
        onboardingGuard(
          context,
          _stateWithLocation(splashRoute),
          notifier,
          () => 'ws-1',
        ),
        isNull,
      );
      expect(
        onboardingGuard(
          context,
          _stateWithLocation('/dashboard'),
          notifier,
          () => 'ws-1',
        ),
        splashRoute,
      );
      expect(
        onboardingGuard(
          context,
          _stateWithLocation('/onboarding'),
          notifier,
          () => 'ws-1',
        ),
        splashRoute,
      );

      notifier.dispose();
    });

    testWidgets('leaves splash for dashboard once gate resolves complete', (
      tester,
    ) async {
      await tester.pumpWidget(const SizedBox());
      final context = tester.element(find.byType(SizedBox));
      final notifier = ValueNotifier<OnboardingGate>(OnboardingGate.complete);

      expect(
        onboardingGuard(
          context,
          _stateWithLocation(splashRoute),
          notifier,
          () => 'ws-1',
        ),
        dashboardRoute('ws-1'),
      );

      notifier.dispose();
    });

    testWidgets('leaves splash for onboarding once gate resolves incomplete', (
      tester,
    ) async {
      await tester.pumpWidget(const SizedBox());
      final context = tester.element(find.byType(SizedBox));
      final notifier = ValueNotifier<OnboardingGate>(OnboardingGate.incomplete);

      expect(
        onboardingGuard(
          context,
          _stateWithLocation(splashRoute),
          notifier,
          () => 'ws-1',
        ),
        onboardingRoute,
      );

      notifier.dispose();
    });
  });

  // ---------------------------------------------------------------------------
  // onboardingGateProvider
  // ---------------------------------------------------------------------------
  //
  // The gate provider stitches together credentials, gh-CLI status, and
  // workspaces. The key invariant we care about (and that fixes the
  // onboarding flash) is that the gate is `loading` until every input
  // resolves, then transitions to complete/incomplete. The router-level
  // guard tests above cover the user-visible behavior of that transition.
  group('onboardingGateProvider', () {
    test('is loading until credentials are loaded', () {
      final container = ProviderContainer(
        overrides: [
          isCredentialsLoadedProvider.overrideWith((ref) => false),
          credentialsProvider.overrideWith(_StubCredentialsNotifier.new),
          workspacesProvider.overrideWithValue(
            const AsyncValue<List<Workspace>>.loading(),
          ),
          isGitHubAuthenticatedProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(onboardingGateProvider), OnboardingGate.loading);
    });

    test('is loading until the workspaces stream emits', () {
      final container = ProviderContainer(
        overrides: [
          isCredentialsLoadedProvider.overrideWith((ref) => true),
          credentialsProvider.overrideWith(
            () => _StubCredentialsNotifier(hasPat: true),
          ),
          workspacesProvider.overrideWithValue(
            const AsyncValue<List<Workspace>>.loading(),
          ),
          isGitHubAuthenticatedProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(onboardingGateProvider), OnboardingGate.loading);
    });

    test('resolves to complete when authed with a workspace', () async {
      final container = ProviderContainer(
        overrides: [
          credentialsProvider.overrideWith(
            () => _StubCredentialsNotifier(hasPat: true),
          ),
          workspacesProvider.overrideWithValue(
            AsyncValue.data([_workspaceRow()]),
          ),
          isGitHubAuthenticatedProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      container.read(onboardingGateProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(onboardingGateProvider), OnboardingGate.complete);
    });

    test('resolves to incomplete when authed without a workspace', () async {
      final container = ProviderContainer(
        overrides: [
          credentialsProvider.overrideWith(
            () => _StubCredentialsNotifier(hasPat: true),
          ),
          workspacesProvider.overrideWithValue(
            const AsyncValue<List<Workspace>>.data([]),
          ),
          isGitHubAuthenticatedProvider.overrideWithValue(true),
        ],
      );
      addTearDown(container.dispose);

      container.read(onboardingGateProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(onboardingGateProvider), OnboardingGate.incomplete);
    });
  });

  // ---------------------------------------------------------------------------
  // router structure (built inline to avoid ref.onDispose interaction)
  // ---------------------------------------------------------------------------
  group('router structure', () {
    test('has expected top-level routes', () {
      final router = _buildRouter();
      addTearDown(router.dispose);
      final routes = router.configuration.routes;

      final routePaths = routes.whereType<GoRoute>().map((r) => r.path).toSet();
      expect(routePaths, contains(onboardingRoute));
      // The picker is now a top-level route (outside the workspace shell).
      expect(routePaths, contains(workspaceListRoute));
      // A bare `/workspaces/:workspaceId` is the workspace-root redirect.
      expect(routePaths, contains(workspaceRoot(workspaceIdParam)));

      final shellRoutes = routes.whereType<ShellRoute>().expand(
        (s) => s.routes,
      );
      final shellPaths = shellRoutes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toSet();

      // Shell children use absolute, workspace-prefixed patterns.
      expect(shellPaths, contains(dashboardRoute(workspaceIdParam)));
      expect(shellPaths, contains(pullRequestsRoute(workspaceIdParam)));
      expect(shellPaths, contains(apiKeysRoute(workspaceIdParam)));
      expect(shellPaths, contains(settingsRoute(workspaceIdParam)));
    });

    test('pull-requests route has nested :owner/:repo/:prNumber route', () {
      final router = _buildRouter();
      addTearDown(router.dispose);
      final shellRoutes = router.configuration.routes
          .whereType<ShellRoute>()
          .expand((s) => s.routes);
      final prRoute = shellRoutes.whereType<GoRoute>().firstWhere(
        (r) => r.path == pullRequestsRoute(workspaceIdParam),
      );

      final subPaths = prRoute.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toSet();
      expect(subPaths, contains(':owner/:repo/:prNumber'));
    });

    test('workspace picker is a top-level route, not in the shell', () {
      final router = _buildRouter();
      addTearDown(router.dispose);

      final topLevelPaths = router.configuration.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toSet();
      expect(topLevelPaths, contains(workspaceListRoute));

      final shellPaths = router.configuration.routes
          .whereType<ShellRoute>()
          .expand((s) => s.routes)
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toSet();
      // The list route no longer lives inside the shell, and there is no
      // `:workspaceId` child under it (the prefix moved onto shell children).
      expect(shellPaths, isNot(contains(workspaceListRoute)));
    });

    test('redirect is configured', () {
      final router = _buildRouter();
      addTearDown(router.dispose);

      expect(router.configuration.topRedirect, isNotNull);
    });

    test('exposes a non-empty route list', () {
      final router = _buildRouter();
      addTearDown(router.dispose);

      expect(router.configuration.routes, isNotEmpty);
    });

    test('declares the splash route at the top level', () {
      final router = _buildRouter();
      addTearDown(router.dispose);

      final routePaths = router.configuration.routes
          .whereType<GoRoute>()
          .map((r) => r.path)
          .toSet();
      expect(routePaths, contains(splashRoute));
    });
  });

  group('app_router route paths', () {
    test('splashRoute is /splash', () {
      expect(splashRoute, '/splash');
    });

    test('newsfeedSettingsRoute is /workspaces/w1/newsfeed/settings', () {
      expect(newsfeedSettingsRoute('w1'), '/workspaces/w1/newsfeed/settings');
    });

    test('settingsAppearanceRoute is /workspaces/w1/settings/appearance', () {
      expect(
        settingsAppearanceRoute('w1'),
        '/workspaces/w1/settings/appearance',
      );
    });

    test('settingsAdaptersRoute is /workspaces/w1/settings/adapters', () {
      expect(settingsAdaptersRoute('w1'), '/workspaces/w1/settings/adapters');
    });

    test('settingsAgentsRoute is /workspaces/w1/settings/agents', () {
      expect(settingsAgentsRoute('w1'), '/workspaces/w1/settings/agents');
    });

    test('settingsReposRoute is /workspaces/w1/settings/repositories', () {
      expect(settingsReposRoute('w1'), '/workspaces/w1/settings/repositories');
    });

    test('settingsSkillsRoute is /workspaces/w1/settings/skills', () {
      expect(settingsSkillsRoute('w1'), '/workspaces/w1/settings/skills');
    });

    test('messagingRoute is /workspaces/w1/messaging', () {
      expect(messagingRoute('w1'), '/workspaces/w1/messaging');
    });

    test('newsfeedArticleRoute generates correct path', () {
      expect(
        newsfeedArticleRoute('w1', 'abc123'),
        '/workspaces/w1/newsfeed/article/abc123',
      );
    });

    test('newsfeedArticleRoute with UUID', () {
      expect(
        newsfeedArticleRoute('w1', '550e8400-e29b-41d4-a716-446655440000'),
        '/workspaces/w1/newsfeed/article/550e8400-e29b-41d4-a716-446655440000',
      );
    });

    test('settings route is declared in the shell', () {
      final router = _buildRouter();
      addTearDown(router.dispose);
      final shellRoutes = router.configuration.routes
          .whereType<ShellRoute>()
          .expand((s) => s.routes);
      final settingsRouteDef = shellRoutes.whereType<GoRoute>().firstWhere(
        (r) => r.path == settingsRoute(workspaceIdParam),
      );
      expect(settingsRouteDef.path, settingsRoute(workspaceIdParam));
    });
  });
}

class _StubCredentialsNotifier extends CredentialsNotifier {
  _StubCredentialsNotifier({this.hasPat = false});
  final bool hasPat;
  @override
  Future<ApiCredentials> build() async {
    return ApiCredentials(
      githubToken: hasPat ? 'stub-pat' : '',
      ticketingApiKey: '',
    );
  }
}
