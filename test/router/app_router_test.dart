import 'package:control_center/router/guards.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

GoRouter buildRouter({OnboardingGate gate = OnboardingGate.complete}) {
  final gateNotifier = ValueNotifier<OnboardingGate>(gate);
  return GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(),
    initialLocation: dashboardRoute,
    refreshListenable: gateNotifier,
    redirect: (context, state) => onboardingGuard(context, state, gateNotifier),
    routes: [
      GoRoute(path: dashboardRoute, builder: (_, _) => const SizedBox()),
      GoRoute(
        path: pullRequestsRoute,
        builder: (_, _) => const SizedBox(),
        routes: [
          GoRoute(
            path: ':prNumber',
            redirect: (context, state) {
              final raw = state.pathParameters['prNumber'] ?? '';
              final parsed = int.tryParse(raw);
              if (parsed == null) {
                return pullRequestsRoute;
              }
              return null;
            },
            builder: (_, _) => const SizedBox(),
          ),
        ],
      ),
      GoRoute(
        path: workspaceListRoute,
        builder: (_, _) => const SizedBox(),
        routes: [
          GoRoute(path: ':workspaceId', builder: (_, _) => const SizedBox()),
        ],
      ),
      GoRoute(
        path: newsfeedRoute,
        builder: (_, _) => const SizedBox(),
        routes: [
          GoRoute(path: 'saved', builder: (_, _) => const SizedBox()),
          GoRoute(path: 'settings', builder: (_, _) => const SizedBox()),
          GoRoute(
            path: 'article/:articleId',
            builder: (_, _) => const SizedBox(),
          ),
        ],
      ),
      GoRoute(path: settingsAppearanceRoute, builder: (_, _) => const SizedBox()),
    ],
  );
}

GoRouter buildFullRouter({OnboardingGate gate = OnboardingGate.complete}) {
  final gateNotifier = ValueNotifier<OnboardingGate>(gate);
  return GoRouter(
    navigatorKey: GlobalKey<NavigatorState>(),
    initialLocation: splashRoute,
    refreshListenable: gateNotifier,
    redirect: (context, state) => onboardingGuard(context, state, gateNotifier),
    routes: [
      GoRoute(
        path: splashRoute,
        builder: (_, _) => const SizedBox(),
      ),
      GoRoute(
        path: onboardingRoute,
        builder: (_, _) => const SizedBox(),
      ),
      GoRoute(
        path: dashboardRoute,
        builder: (_, _) => const SizedBox(),
      ),
    ],
  );
}

void main() {
  group('OnboardingGuard via router', () {
    testWidgets('loading gate: non-splash routes redirect to splash', (
      tester,
    ) async {
      final router = buildFullRouter(gate: OnboardingGate.loading);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(dashboardRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, splashRoute);
    });

    testWidgets('loading gate: splash stays on splash', (tester) async {
      final router = buildFullRouter(gate: OnboardingGate.loading);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(splashRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, splashRoute);
    });

    testWidgets('loading gate: onboarding redirects to splash', (
      tester,
    ) async {
      final router = buildFullRouter(gate: OnboardingGate.loading);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(onboardingRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, splashRoute);
    });

    testWidgets('complete gate: splash redirects to dashboard', (
      tester,
    ) async {
      final router = buildFullRouter(gate: OnboardingGate.complete);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(splashRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, dashboardRoute);
    });

    testWidgets('complete gate: dashboard stays on dashboard', (
      tester,
    ) async {
      final router = buildFullRouter(gate: OnboardingGate.complete);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(dashboardRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, dashboardRoute);
    });

    testWidgets('complete gate: onboarding stays on onboarding', (
      tester,
    ) async {
      // The gate satisfies its criteria the moment the workspace is created
      // in step 2, but step 3 (voice model) still needs to be shown. The
      // onboarding screen navigates to the dashboard itself once the user
      // finishes or skips the final step.
      final router = buildFullRouter(gate: OnboardingGate.complete);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(onboardingRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, onboardingRoute);
    });

    testWidgets('incomplete gate: splash redirects to onboarding', (
      tester,
    ) async {
      final router = buildFullRouter(gate: OnboardingGate.incomplete);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(splashRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, onboardingRoute);
    });

    testWidgets('incomplete gate: onboarding stays on onboarding', (
      tester,
    ) async {
      final router = buildFullRouter(gate: OnboardingGate.incomplete);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(onboardingRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, onboardingRoute);
    });

    testWidgets('incomplete gate: dashboard redirects to onboarding', (
      tester,
    ) async {
      final router = buildFullRouter(gate: OnboardingGate.incomplete);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(dashboardRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, onboardingRoute);
    });
  });

  group('OnboardingGate enum', () {
    test('has three values', () {
      expect(OnboardingGate.values, hasLength(3));
    });

    test('values are loading, complete, incomplete', () {
      expect(OnboardingGate.values, contains(OnboardingGate.loading));
      expect(OnboardingGate.values, contains(OnboardingGate.complete));
      expect(OnboardingGate.values, contains(OnboardingGate.incomplete));
    });
  });

  group('Settings redirect', () {
    testWidgets('/settings is not defined in test router config', (
      tester,
    ) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(settingsRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains(settingsRoute));
    });
  });

  group('PR deep-link redirects', () {
    testWidgets('/pull-requests/abc (non-numeric) redirects to list', (
      tester,
    ) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go('/pull-requests/abc');
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains('/pull-requests'));
      expect(location, isNot(contains('abc')));
    });

    testWidgets('/pull-requests/0 navigates to detail (zero is valid int)', (
      tester,
    ) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go('/pull-requests/0');
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains('/pull-requests/0'));
    });

    testWidgets('/pull-requests/42 navigates to detail', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go('/pull-requests/42');
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains('/pull-requests/42'));
    });
  });

  group('Workspace deep-link routing', () {
    testWidgets('/workspaces/ empty path matches workspace route', (
      tester,
    ) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go('/workspaces/');
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains('/workspaces'));
    });

    testWidgets('/settings/appearance navigates correctly', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(settingsAppearanceRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains(settingsAppearanceRoute));
    });

    testWidgets('/settings/adapters navigates correctly', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(settingsAdaptersRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains(settingsAdaptersRoute));
    });

    testWidgets('/settings/agents navigates correctly', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(settingsAgentsRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains(settingsAgentsRoute));
    });

    testWidgets('/settings/repositories navigates correctly', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(settingsReposRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains(settingsReposRoute));
    });

    testWidgets('/settings/skills navigates correctly', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(settingsSkillsRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains(settingsSkillsRoute));
    });

    testWidgets('/messaging navigates correctly', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(messagingRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains(messagingRoute));
    });

    testWidgets('/api-keys navigates correctly', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(apiKeysRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains(apiKeysRoute));
    });

    testWidgets('/workspaces/valid-id matches detail route', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go('/workspaces/ws-123');
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains('/workspaces/ws-123'));
    });

    testWidgets('/workspaces empty list navigates correctly', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(workspaceListRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains(workspaceListRoute));
    });

    testWidgets('/agents route navigates correctly', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(agentsRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains(agentsRoute));
    });
  });

  group('GoRouter dispose', () {
    testWidgets('disposing router does not throw', (tester) async {
      final router = buildRouter();

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      expect(router.dispose, returnsNormally);
    });
  });

  group('onboardingGuard edge cases', () {
    testWidgets('loading gate: all app routes redirect to splash', (
      tester,
    ) async {
      final router = buildFullRouter(gate: OnboardingGate.loading);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      final routes = <String>[
        dashboardRoute,
        onboardingRoute,
        pullRequestsRoute,
        agentsRoute,
        workspaceListRoute,
        settingsRoute,
        apiKeysRoute,
      ];
      for (final route in routes) {
        router.go(route);
        await tester.pump();
        final location =
            router.routerDelegate.currentConfiguration.uri.toString();
        expect(
          location,
          splashRoute,
          reason: '$route should redirect to splash when loading',
        );
      }
    });

    testWidgets('incomplete gate: all app routes redirect to onboarding', (
      tester,
    ) async {
      final router = buildFullRouter(gate: OnboardingGate.incomplete);
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      final routes = <String>[
        dashboardRoute,
        pullRequestsRoute,
        agentsRoute,
        workspaceListRoute,
        settingsRoute,
        apiKeysRoute,
      ];
      for (final route in routes) {
        router.go(route);
        await tester.pump();
        final location =
            router.routerDelegate.currentConfiguration.uri.toString();
        expect(
          location,
          onboardingRoute,
          reason: '$route should redirect to onboarding when incomplete',
        );
      }
    });

    testWidgets('gate transitions from loading to complete', (tester) async {
      final gateNotifier = ValueNotifier<OnboardingGate>(
        OnboardingGate.loading,
      );
      final router = GoRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
        initialLocation: splashRoute,
        refreshListenable: gateNotifier,
        redirect: (context, state) =>
            onboardingGuard(context, state, gateNotifier),
        routes: [
          GoRoute(
            path: splashRoute,
            builder: (_, _) => const SizedBox(),
          ),
          GoRoute(
            path: onboardingRoute,
            builder: (_, _) => const SizedBox(),
          ),
          GoRoute(
            path: dashboardRoute,
            builder: (_, _) => const SizedBox(),
          ),
        ],
      );
      addTearDown(router.dispose);
      addTearDown(gateNotifier.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(dashboardRoute);
      await tester.pump();

      var location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, splashRoute);

      gateNotifier.value = OnboardingGate.complete;
      await tester.pump();

      router.go(dashboardRoute);
      await tester.pump();

      location = router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, dashboardRoute);
    });

    testWidgets('gate transitions from loading to incomplete', (
      tester,
    ) async {
      final gateNotifier = ValueNotifier<OnboardingGate>(
        OnboardingGate.loading,
      );
      final router = GoRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
        initialLocation: splashRoute,
        refreshListenable: gateNotifier,
        redirect: (context, state) =>
            onboardingGuard(context, state, gateNotifier),
        routes: [
          GoRoute(
            path: splashRoute,
            builder: (_, _) => const SizedBox(),
          ),
          GoRoute(
            path: onboardingRoute,
            builder: (_, _) => const SizedBox(),
          ),
          GoRoute(
            path: dashboardRoute,
            builder: (_, _) => const SizedBox(),
          ),
        ],
      );
      addTearDown(router.dispose);
      addTearDown(gateNotifier.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(dashboardRoute);
      await tester.pump();

      var location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, splashRoute);

      gateNotifier.value = OnboardingGate.incomplete;
      await tester.pump();

      router.go(dashboardRoute);
      await tester.pump();

      location = router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, onboardingRoute);
    });
  });

  group('deep linking edge cases', () {
    testWidgets('/pull-requests/ negative number navigates to detail', (
      tester,
    ) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go('/pull-requests/-5');
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains('/pull-requests/-5'));
    });

    testWidgets('/pull-requests/ empty path navigates to list', (
      tester,
    ) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go('/pull-requests/');
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains('/pull-requests'));
    });

    testWidgets('/settings redirects to /settings/appearance', (tester) async {
      final router = GoRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
        initialLocation: dashboardRoute,
        routes: [
          GoRoute(path: dashboardRoute, builder: (_, _) => const SizedBox()),
          GoRoute(
            path: settingsRoute,
            redirect: (_, _) => settingsAppearanceRoute,
          ),
          GoRoute(
            path: settingsAppearanceRoute,
            builder: (_, _) => const SizedBox(),
          ),
        ],
      );
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(settingsRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains(settingsAppearanceRoute));
    });
  });

  group('route configuration structure', () {
    testWidgets('router has all expected route paths accessible', (
      tester,
    ) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      final allRoutes = <String>[
        dashboardRoute,
        pullRequestsRoute,
        agentsRoute,
        workspaceListRoute,
        apiKeysRoute,
        settingsAppearanceRoute,
        settingsAdaptersRoute,
        settingsAgentsRoute,
        settingsReposRoute,
        settingsSkillsRoute,
        messagingRoute,
      ];

      for (final route in allRoutes) {
        router.go(route);
        await tester.pump();
        final location =
            router.routerDelegate.currentConfiguration.uri.toString();
        expect(
          location,
          contains(route),
          reason: 'Route $route should be reachable',
        );
      }
    });

    testWidgets('newsfeed route navigates correctly', (tester) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(newsfeedRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains(newsfeedRoute));
    });

    testWidgets('newsfeed settings route navigates correctly', (
      tester,
    ) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(newsfeedSettingsRoute);
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains(newsfeedSettingsRoute));
    });

    testWidgets('newsfeed article route navigates correctly', (
      tester,
    ) async {
      final router = buildRouter();
      addTearDown(router.dispose);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump();

      router.go(newsfeedArticleRoute('art-1'));
      await tester.pump();

      final location =
          router.routerDelegate.currentConfiguration.uri.toString();
      expect(location, contains('/newsfeed/article/art-1'));
    });
  });
}
