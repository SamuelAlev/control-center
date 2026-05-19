import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart' show UserDto;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/demo_providers.dart';
import 'package:control_center/features/auth/presentation/screens/api_keys_screen.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:control_center/features/auth/providers/onboarding_providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/inbox/presentation/inbox_screen.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail_screen.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_list_screen.dart';
import 'package:control_center/features/settings/presentation/screens/adapters_settings_screen.dart';
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

/// Reads [onboardingFinishedProvider] once `identity.me` has resolved.
///
/// The subscription is what makes this work: providers auto-dispose in Riverpod
/// 3, so a bare `read` tears the future down before it completes and the flag
/// never leaves "unknown".
Future<bool?> _settledFlag(ProviderContainer container) async {
  final sub = container.listen(onboardingFinishedProvider, (_, _) {});
  addTearDown(sub.close);
  await container.read(currentIdentityProvider.future);
  return container.read(onboardingFinishedProvider);
}

/// An `identity.me` payload whose user has (or has not) finished setup.
IdentityMe _me({DateTime? onboardingFinishedAt}) => IdentityMe(
  user: UserDto(
    id: 'u-1',
    handle: 'sam',
    displayName: 'Sam',
    onboardingFinishedAt: onboardingFinishedAt,
  ),
  deviceId: 'dev-1',
  isServerOwner: true,
  memberships: const [],
);

/// Hands a provider `Ref` out to a test, so the `Ref`-flavoured helpers can be
/// exercised the way a provider would call them.
final _refProvider = Provider<Ref>((ref) => ref);

const _connectedGitHub = ForgeConnection(
  forge: ForgeHost.github,
  authenticated: true,
  username: 'testuser',
  source: ForgeCredentialSource.oauth,
);

const _disconnectedGitHub = ForgeConnection(
  forge: ForgeHost.github,
  authenticated: false,
  username: '',
  source: ForgeCredentialSource.none,
);

/// A container for the gate with all three of its inputs settled: the
/// workspaces, the forge connections and whether this user has ever finished
/// setup.
///
/// The finished flag is overridden as a VALUE rather than through the server
/// prefs stream it normally derives from: these tests are about which gate the
/// three inputs produce, and threading a stream through would make them assert
/// on delivery timing instead. How the flag itself merges the local and server
/// lanes has its own group below.
ProviderContainer _gateContainer({
  required List<Workspace> workspaces,
  required List<ForgeConnection> connections,
  required bool? onboardingFinished,
  AppPreferences? prefs,
  Future<void> Function()? push,
}) => ProviderContainer(
  overrides: [
    appPreferencesProvider.overrideWithValue(
      prefs ?? AppPreferences.inMemory(),
    ),
    workspacesProvider.overrideWithValue(AsyncValue.data(workspaces)),
    forgeConnectionsProvider.overrideWith((ref) async => connections),
    onboardingFinishedProvider.overrideWithValue(onboardingFinished),
    onboardingFinishedPushProvider.overrideWithValue(push ?? () async {}),
  ],
);

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
      // A bare `/workspaces/:workspaceId` enters the workspace inbox.
      GoRoute(
        path: workspaceRoot(workspaceIdParam),
        redirect: (context, state) =>
            inboxRoute(state.pathParameters['workspaceId']!),
      ),
      ShellRoute(
        builder: (context, state, child) => ControlCenterLayout(child: child),
        routes: [
          GoRoute(
            path: inboxRoute(workspaceIdParam),
            pageBuilder: (context, state) => NoTransitionPage(
              key: state.pageKey,
              child: const InboxScreen(),
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
                      workspaceId: state.pathParameters['workspaceId']!,
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
    test('inboxRoute', () => expect(inboxRoute('w1'), '/workspaces/w1/inbox'));
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
          _stateWithLocation('/inbox'),
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
      // navigates to the inbox itself once the final step is completed.
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

    testWidgets('returns null when complete and on inbox', (tester) async {
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
          _stateWithLocation('/inbox'),
          notifier,
          () => 'ws-1',
        ),
        onboardingRoute,
      );

      notifier.value = OnboardingGate.complete;

      expect(
        onboardingGuard(
          context,
          _stateWithLocation('/inbox'),
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
          _stateWithLocation('/inbox'),
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

    testWidgets('leaves splash for inbox once gate resolves complete', (
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
        inboxRoute('ws-1'),
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

    // -------------------------------------------------------------------------
    // signedOut: a completed setup whose forge credential lapsed
    // -------------------------------------------------------------------------
    group('signedOut', () {
      testWidgets('redirects to the re-auth screen, NOT onboarding', (
        tester,
      ) async {
        // The whole point of the state: an operator with workspaces, a sandbox
        // and a model already configured must not be walked through a five-step
        // first-run flow to replace one expired token.
        await tester.pumpWidget(const SizedBox());
        final context = tester.element(find.byType(SizedBox));
        final notifier = ValueNotifier<OnboardingGate>(OnboardingGate.signedOut);

        for (final route in <String>[
          '/inbox',
          '/pull-requests',
          '/workspaces/abc',
          '/settings',
        ]) {
          expect(
            onboardingGuard(
              context,
              _stateWithLocation(route),
              notifier,
              () => 'ws-1',
            ),
            signedOutRoute,
            reason: 'Expected the signed-out redirect for $route',
          );
        }

        notifier.dispose();
      });

      testWidgets('leaves splash for the re-auth screen', (tester) async {
        await tester.pumpWidget(const SizedBox());
        final context = tester.element(find.byType(SizedBox));
        final notifier = ValueNotifier<OnboardingGate>(OnboardingGate.signedOut);

        expect(
          onboardingGuard(
            context,
            _stateWithLocation(splashRoute),
            notifier,
            () => 'ws-1',
          ),
          signedOutRoute,
        );

        notifier.dispose();
      });

      testWidgets('stays put while still signed out', (tester) async {
        await tester.pumpWidget(const SizedBox());
        final context = tester.element(find.byType(SizedBox));
        final notifier = ValueNotifier<OnboardingGate>(OnboardingGate.signedOut);

        expect(
          onboardingGuard(
            context,
            _stateWithLocation(signedOutRoute),
            notifier,
            () => 'ws-1',
          ),
          isNull,
        );

        notifier.dispose();
      });

      testWidgets('returns to the inbox the moment the credential lands', (
        tester,
      ) async {
        // Unlike onboarding, this screen IS left automatically: signing back in
        // is one action with nothing after it, so staying on it would read as a
        // sign-in that silently failed.
        await tester.pumpWidget(const SizedBox());
        final context = tester.element(find.byType(SizedBox));
        final notifier = ValueNotifier<OnboardingGate>(OnboardingGate.signedOut);

        expect(
          onboardingGuard(
            context,
            _stateWithLocation(signedOutRoute),
            notifier,
            () => 'ws-1',
          ),
          isNull,
        );

        notifier.value = OnboardingGate.complete;

        expect(
          onboardingGuard(
            context,
            _stateWithLocation(signedOutRoute),
            notifier,
            () => 'ws-1',
          ),
          inboxRoute('ws-1'),
        );

        notifier.dispose();
      });

      testWidgets('falls back to the picker when no workspace resolves', (
        tester,
      ) async {
        await tester.pumpWidget(const SizedBox());
        final context = tester.element(find.byType(SizedBox));
        final notifier = ValueNotifier<OnboardingGate>(OnboardingGate.complete);

        expect(
          onboardingGuard(
            context,
            _stateWithLocation(signedOutRoute),
            notifier,
            () => null,
          ),
          workspaceListRoute,
        );

        notifier.dispose();
      });

      testWidgets('does NOT eject a user who is mid-onboarding', (tester) async {
        // A token that expires between the workspace step and the model step
        // would otherwise throw the operator into the re-auth screen and strand
        // the steps after it — and step 1 already carries the same forge card.
        await tester.pumpWidget(const SizedBox());
        final context = tester.element(find.byType(SizedBox));
        final notifier = ValueNotifier<OnboardingGate>(OnboardingGate.signedOut);

        expect(
          onboardingGuard(
            context,
            _stateWithLocation(onboardingRoute),
            notifier,
            () => 'ws-1',
          ),
          isNull,
        );

        notifier.dispose();
      });

      testWidgets('a never-onboarded user still gets onboarding', (
        tester,
      ) async {
        await tester.pumpWidget(const SizedBox());
        final context = tester.element(find.byType(SizedBox));
        final notifier = ValueNotifier<OnboardingGate>(
          OnboardingGate.incomplete,
        );

        expect(
          onboardingGuard(
            context,
            _stateWithLocation(signedOutRoute),
            notifier,
            () => 'ws-1',
          ),
          onboardingRoute,
        );

        notifier.dispose();
      });
    });
  });

  // ---------------------------------------------------------------------------
  // onboardingGateProvider
  // ---------------------------------------------------------------------------
  //
  // The gate provider stitches together credentials, gh-CLI status and
  // workspaces. The key invariant we care about (and that fixes the
  // onboarding flash) is that the gate is `loading` until every input
  // resolves, then transitions to complete/incomplete. The router-level
  // guard tests above cover the user-visible behavior of that transition.
  group('onboardingGateProvider', () {
    test('a demo server is complete, whatever the forge says', () {
      // The demo regression: a visitor redeems into a furnished workspace, but
      // `oauth.*` and `credentials.*` are absent from a demo server's op
      // registry, so no forge can ever be connected. Running the normal gate
      // resolved to `signedOut` and offered a sign-in for a credential that
      // cannot exist, in front of a workspace that was already set up.
      final container = ProviderContainer(
        overrides: [
          isDemoServerProvider.overrideWithValue(true),
          // Deliberately the WORST case for the normal gate: no forge, no
          // workspaces, nothing resolved. A demo is complete regardless.
          workspacesProvider.overrideWithValue(
            const AsyncValue<List<Workspace>>.loading(),
          ),
          forgeConnectionsProvider.overrideWith(
            (ref) async => const <ForgeConnection>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(onboardingGateProvider), OnboardingGate.complete);
    });

    test('a real server still runs the full gate', () {
      // The other half of the guard: the bypass must be keyed on the demo flag
      // and nothing else, or it would hide a genuinely incomplete setup.
      final container = ProviderContainer(
        overrides: [
          isDemoServerProvider.overrideWithValue(false),
          workspacesProvider.overrideWithValue(
            const AsyncValue<List<Workspace>>.loading(),
          ),
          forgeConnectionsProvider.overrideWith(
            (ref) async => const <ForgeConnection>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(onboardingGateProvider), OnboardingGate.loading);
    });

    test('is loading until the forge connections resolve', () {
      final container = ProviderContainer(
        overrides: [
          workspacesProvider.overrideWithValue(
            const AsyncValue<List<Workspace>>.loading(),
          ),
          forgeConnectionsProvider.overrideWith(
            (ref) async => const <ForgeConnection>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(onboardingGateProvider), OnboardingGate.loading);
    });

    test('is loading until the workspaces stream emits', () {
      final container = ProviderContainer(
        overrides: [
          workspacesProvider.overrideWithValue(
            const AsyncValue<List<Workspace>>.loading(),
          ),
          forgeConnectionsProvider.overrideWith(
            (ref) async => const [
              ForgeConnection(
                forge: ForgeHost.github,
                authenticated: true,
                username: 'testuser',
                source: ForgeCredentialSource.oauth,
              ),
            ],
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(onboardingGateProvider), OnboardingGate.loading);
    });

    test('resolves to complete when authed with a workspace', () async {
      final container = _gateContainer(
        workspaces: [_workspaceRow()],
        connections: const [_connectedGitHub],
        onboardingFinished: true,
      );
      addTearDown(container.dispose);

      container.read(onboardingGateProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(onboardingGateProvider), OnboardingGate.complete);
    });

    test('resolves to signedOut when a FINISHED setup lost its forge', () async {
      // The credential is the only missing piece, so this is a re-auth, not a
      // setup. It must not resolve to `incomplete` — that would re-ask for a
      // workspace they already have and read as if the install was reset.
      final container = _gateContainer(
        workspaces: [_workspaceRow()],
        connections: const [_disconnectedGitHub],
        onboardingFinished: true,
      );
      addTearDown(container.dispose);

      container.read(onboardingGateProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(onboardingGateProvider), OnboardingGate.signedOut);
    });

    test('an INVITED member with no forge onboards, not re-auths', () async {
      // The case that killed the old "workspaces prove you were signed in
      // once" inference: an invited member has a workspace they never created
      // and has never onboarded. Sending them to the re-auth screen would skip
      // the sandbox, model and dictation setup they still need.
      final container = _gateContainer(
        workspaces: [_workspaceRow()],
        connections: const [_disconnectedGitHub],
        onboardingFinished: false,
      );
      addTearDown(container.dispose);

      container.read(onboardingGateProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(onboardingGateProvider), OnboardingGate.incomplete);
    });

    test('holds the splash while the finished flag is unknown', () async {
      // Guessing costs a screen the guard will not let us take back: the guard
      // never redirects away from onboarding, so a wrong guess here strands a
      // returning operator in the flow.
      final container = _gateContainer(
        workspaces: [_workspaceRow()],
        connections: const [_disconnectedGitHub],
        onboardingFinished: null,
      );
      addTearDown(container.dispose);

      container.read(onboardingGateProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(onboardingGateProvider), OnboardingGate.loading);
    });

    test('a complete setup records that onboarding is finished', () async {
      // Self-healing for installs that predate the flag and for a workspace
      // that arrived by invite: without this, the FIRST credential lapse after
      // upgrading would run the first-run flow instead of asking for a sign-in.
      // It lands on the USER server-side — nothing is written to this device.
      var pushes = 0;
      final container = _gateContainer(
        workspaces: [_workspaceRow()],
        connections: const [_connectedGitHub],
        onboardingFinished: false,
        push: () async => pushes++,
      );
      addTearDown(container.dispose);

      container.read(onboardingGateProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(onboardingGateProvider), OnboardingGate.complete);
      expect(pushes, 1);
    });

    test('an already-finished user is not re-recorded', () async {
      // The write refreshes `identity.me`, which recomputes the gate. Firing it
      // unconditionally on every complete recomputation would be a round-trip
      // loop, so the gate reads the flag before deciding to record it.
      var pushes = 0;
      final container = _gateContainer(
        workspaces: [_workspaceRow()],
        connections: const [_connectedGitHub],
        onboardingFinished: true,
        push: () async => pushes++,
      );
      addTearDown(container.dispose);

      container.read(onboardingGateProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(onboardingGateProvider), OnboardingGate.complete);
      expect(pushes, 0);
    });

    test('resolves to incomplete when authed without a workspace', () async {
      final container = _gateContainer(
        workspaces: const [],
        connections: const [_connectedGitHub],
        onboardingFinished: false,
      );
      addTearDown(container.dispose);

      container.read(onboardingGateProvider);
      await Future<void>.delayed(Duration.zero);
      expect(container.read(onboardingGateProvider), OnboardingGate.incomplete);
    });

    test('a cached INCOMPLETE verdict is not trusted before the live '
        'checks settle', () {
      // The guard never redirects away from /onboarding once the gate flips to
      // complete (so a half-finished flow is not cut short). A stale cached
      // `false` therefore strands a fully set-up operator inside onboarding on
      // every launch, and walking the flow again creates another workspace. So
      // only a cached COMPLETE short-circuits the splash.
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(
            AppPreferences.inMemory(const {'onboarding_complete': false}),
          ),
          workspacesProvider.overrideWithValue(
            const AsyncValue<List<Workspace>>.loading(),
          ),
          forgeConnectionsProvider.overrideWith(
            (ref) async => const <ForgeConnection>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(onboardingGateProvider), OnboardingGate.loading);
    });

    test('a cached COMPLETE verdict still routes without the splash', () {
      final container = ProviderContainer(
        overrides: [
          appPreferencesProvider.overrideWithValue(
            AppPreferences.inMemory(const {'onboarding_complete': true}),
          ),
          workspacesProvider.overrideWithValue(
            const AsyncValue<List<Workspace>>.loading(),
          ),
          forgeConnectionsProvider.overrideWith(
            (ref) async => const <ForgeConnection>[],
          ),
        ],
      );
      addTearDown(container.dispose);

      expect(container.read(onboardingGateProvider), OnboardingGate.complete);
    });
  });

  // ---------------------------------------------------------------------------
  // onboardingFinishedProvider — the "has this PERSON been set up" flag
  // ---------------------------------------------------------------------------
  group('onboardingFinishedProvider', () {
    ProviderContainer containerWith({
      Future<IdentityMe> Function()? identity,
      Future<void> Function()? push,
      AppPreferences? prefs,
    }) => ProviderContainer(
      overrides: [
        appPreferencesProvider.overrideWithValue(
          prefs ?? AppPreferences.inMemory(),
        ),
        currentIdentityProvider.overrideWith(
          (ref) => identity == null ? Completer<IdentityMe>().future : identity(),
        ),
        onboardingFinishedPushProvider.overrideWithValue(push ?? () async {}),
      ],
    );

    test('is null while identity has not resolved', () {
      // Null is NOT "no". The gate parks on the splash rather than guessing,
      // because the guard will not redirect back out of onboarding.
      final container = containerWith();
      addTearDown(container.dispose);

      expect(container.read(onboardingFinishedProvider), isNull);
    });

    test('reads the timestamp off the caller own user', () async {
      // The flag follows the ACCOUNT: someone who set up on their desktop and
      // then signs in on the phone has onboarded, and the phone learns it from
      // `identity.me` rather than from anything stored on the phone.
      final container = containerWith(
        identity: () async => _me(onboardingFinishedAt: DateTime(2025)),
      );
      addTearDown(container.dispose);

      expect(await _settledFlag(container), isTrue);
    });

    test('is false once identity answers with no timestamp', () async {
      final container = containerWith(identity: () async => _me());
      addTearDown(container.dispose);

      expect(await _settledFlag(container), isFalse);
    });

    test('no device-local value can make it true', () async {
      // The regression this whole lane exists for. `onboarding_finished` used
      // to be a synced preference read local-copy-first, and the preference
      // sync's promotion pass pushes a device's local values onto whichever
      // account first signs in there. A machine that had onboarded once marked
      // a brand-new user as already set up, and the gate offered them the
      // re-auth screen instead of the setup they had never done.
      final container = containerWith(
        identity: () async => _me(),
        prefs: AppPreferences.inMemory(const {'onboarding_finished': true}),
      );
      addTearDown(container.dispose);

      expect(await _settledFlag(container), isFalse);
    });

    test('markOnboardingFinished pushes once and coalesces a race', () async {
      var pushes = 0;
      final gate = Completer<void>();
      final container = containerWith(
        identity: () async => _me(),
        push: () async {
          pushes++;
          await gate.future;
        },
      );
      addTearDown(container.dispose);

      // Both callers land while the first round-trip is still in flight — the
      // gate fires on every recomputation, so this is the normal case, not an
      // edge one.
      final first = markOnboardingFinished(container.read(_refProvider));
      final second = markOnboardingFinished(container.read(_refProvider));
      gate.complete();
      await Future.wait([first, second]);

      expect(pushes, 1);
    });

    test('a failed push is swallowed and does not latch the writer shut', () async {
      // The gate fires this from a provider body and the flow awaits it before
      // navigating, so a server that is down must not throw into either — but
      // it must also leave the writer able to try again.
      var pushes = 0;
      final container = containerWith(
        identity: () async => _me(),
        push: () async {
          pushes++;
          throw StateError('offline');
        },
      );
      addTearDown(container.dispose);

      await markOnboardingFinished(container.read(_refProvider));
      await markOnboardingFinished(container.read(_refProvider));
      expect(pushes, 2);
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
      expect(shellPaths, contains(inboxRoute(workspaceIdParam)));
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
      // The list route no longer lives inside the shell and there is no
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

    test('settingsNewsfeedRoute is scoped to you', () {
      expect(
        settingsNewsfeedRoute('w1'),
        '/workspaces/w1/settings/you/newsfeed',
      );
    });

    // Settings paths are namespaced by SCOPE, so the URL states who a change
    // affects rather than only the sidebar grouping doing so.
    test('settingsAppearanceRoute is scoped to you', () {
      expect(
        settingsAppearanceRoute('w1'),
        '/workspaces/w1/settings/you/appearance',
      );
    });

    test('settingsAdaptersRoute is scoped to the server', () {
      expect(
        settingsAdaptersRoute('w1'),
        '/workspaces/w1/settings/server/providers',
      );
    });

    test('settingsAgentsRoute is scoped to the workspace', () {
      expect(
        settingsAgentsRoute('w1'),
        '/workspaces/w1/settings/workspace/agents',
      );
    });

    test('settingsReposRoute is scoped to the workspace', () {
      expect(
        settingsReposRoute('w1'),
        '/workspaces/w1/settings/workspace/repositories',
      );
    });

    test('settingsSkillsRoute is scoped to the workspace', () {
      expect(
        settingsSkillsRoute('w1'),
        '/workspaces/w1/settings/workspace/skills',
      );
    });

    test('spacesRoute is /workspaces/w1/spaces', () {
      expect(spacesRoute('w1'), '/workspaces/w1/spaces');
    });

    test('spaceRoute is /workspaces/w1/spaces/c1', () {
      expect(spaceRoute('w1', 'c1'), '/workspaces/w1/spaces/c1');
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

