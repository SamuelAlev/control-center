import 'dart:async';
import 'dart:typed_data';

import 'package:cc_data/cc_data.dart' show ConnectModeSetting, IdentityMe;
import 'package:cc_domain/cc_domain.dart' show UserDto;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_detection_result.dart';
import 'package:cc_domain/features/settings/domain/model_control.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_model_control.dart';
import 'package:control_center/core/infrastructure/speech/voice_model_control.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_chrome.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:control_center/features/auth/presentation/widgets/onboarding_you_step.dart';
import 'package:control_center/features/auth/providers/onboarding_providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/identity/providers/account_profile_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/features/workspaces/presentation/widgets/no_workspace_state.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/server_activity_panel.dart';
import 'package:control_center/shared/widgets/server_connect/pre_app_settings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';
import 'package:riverpod/src/framework.dart' show Override;

import '../../../../helpers/fake_rpc_client.dart';

void main() {
  late AppPreferences prefs;

  setUp(() async {
    prefs = AppPreferences.inMemory();
  });

  /// Detection fixture: macOS host with the native sandbox ready, so the
  /// sandbox step renders its data state instead of a spinner.
  const macNativeDetection = SandboxDetectionResult(
    platform: 'macos',
    recommendation: SandboxBackend.native,
    capabilities: {
      SandboxBackend.native: SandboxBackendCapabilities(
        backend: SandboxBackend.native,
        available: true,
      ),
    },
  );

  // ---------------------------------------------------------------------------
  // Helper: pump a full OnboardingScreen with the given overrides.
  //
  // The flow shows only the steps a person is missing, snapshotted when it
  // starts so a step can never vanish underneath them. `authenticated` flips
  // the connection fixture, which answers AFTER the flow planned (an async
  // override), so the connect step still shows and its Continue is enabled;
  // a connection settled before the start drops the step (see "missing
  // steps").
  // ---------------------------------------------------------------------------
  Future<void> pumpOnboarding(
    WidgetTester tester, {
    bool authenticated = false,
    // When true, the forge connections are NOT overridden: the test supplies
    // them via [extraOverrides] and the REAL derivation answers
    // hasAnyForgeConnectedProvider.
    bool deriveAuth = false,
    bool serverOwner = false,
    // Whether this person finished onboarding before. Most cases here are
    // about the steps after "You", which only someone who never finished
    // walks; the "You" group below covers that step.
    bool finished = true,
    // Whether this person may create workspaces (`identity.me`).
    bool canCreate = true,
    List<Override> extraOverrides = const [],
    void Function(String op, Map<String, dynamic> args)? onCall,
    // Mounts the flow under a router whose workspace picker is the real
    // no-workspace state, so finishing the flow can be followed to where it
    // lands.
    bool routed = false,
  }) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final rpc =
        (FakeRpcHost()
              ..onCall = (op, args) {
                onCall?.call(op, args);
                return {'status': 'installed'};
              })
            .client();
    addTearDown(rpc.close);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          rpcClientProvider.overrideWithValue(rpc),
          isServerOwnerProvider.overrideWithValue(serverOwner),
          canCreateWorkspacesProvider.overrideWithValue(canCreate),
          onboardingFinishedProvider.overrideWithValue(finished),
          accountProfileProvider.overrideWith(_Profile.new),
          voiceModelCatalogProvider.overrideWith((ref) async => null),
          if (!deriveAuth) ...[
            // The gate is "at least one forge connected", so the fixture is a
            // forge connection rather than a GitHub-specific flag. Overriding
            // the SOURCE keeps the real derivation
            // (connections → connectedForges → hasAnyForgeConnected) under test.
            forgeConnectionsProvider.overrideWith(
              (ref) async => authenticated
                  ? const [
                      ForgeConnection(
                        forge: ForgeHost.github,
                        status: ForgeConnectionStatus.connected,
                        username: 'testuser',
                        source: ForgeCredentialSource.oauth,
                      ),
                    ]
                  : const <ForgeConnection>[],
            ),
          ],
          ...extraOverrides,
        ],
        child: routed
            ? MaterialApp.router(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('en'),
                routerConfig: GoRouter(
                  initialLocation: onboardingRoute,
                  routes: [
                    GoRoute(
                      path: onboardingRoute,
                      builder: (context, state) => CcTheme(
                        data: CcThemeData.light(),
                        child: const OnboardingScreen(),
                      ),
                    ),
                    GoRoute(
                      path: workspaceListRoute,
                      builder: (context, state) => CcTheme(
                        data: CcThemeData.light(),
                        child: NoWorkspaceState(onAdd: () {}),
                      ),
                    ),
                  ],
                ),
              )
            : MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
                locale: const Locale('en'),
                home: CcTheme(
                  data: CcThemeData.light(),
                  child: const OnboardingScreen(),
                ),
              ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
  }

  /// Step 1 → step 2 (workspace). Requires [pumpOnboarding] with
  /// `authenticated: true` so step 1's Continue is enabled.
  Future<void> advanceToWorkspaceStep(WidgetTester tester) async {
    final continueButton = find.widgetWithText(CcButton, 'Continue');
    await tester.ensureVisible(continueButton);
    await tester.pump();
    await tester.tap(continueButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Give your work a home.'), findsOneWidget);
  }

  // =========================================================================
  // Step 1 — always the entry point
  // =========================================================================

  testWidgets('renders step 1 with welcome and API keys panel', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    expect(find.text("Let's plug in your tools."), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('background failure keeps narrow onboarding actions reachable', (
    tester,
  ) async {
    await pumpOnboarding(
      tester,
      authenticated: true,
      extraOverrides: [
        embeddingModelStatusSnapshotProvider.overrideWith(
          (ref) => Stream.value(
            const ModelStatusSnapshot(
              status: ModelLifecycleStatus.error,
              error: 'No space left on device',
            ),
          ),
        ),
      ],
    );
    tester.view.physicalSize = const Size(390, 640);
    await tester.pump();
    final next = find.widgetWithText(CcButton, 'Continue');
    final activity = find.byType(ServerActivityPanel);
    expect(
      tester.getRect(next).bottom,
      lessThanOrEqualTo(tester.getRect(activity).top),
    );
    await tester.tap(next);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Give your work a home.'), findsOneWidget);
    expect(tester.takeException(), isNull);
    final name = find.byType(CcTextField);
    await tester.ensureVisible(name);
    await tester.enterText(name, 'My workspace');
    tester.view.viewInsets = const FakeViewPadding(bottom: 280);
    addTearDown(tester.view.resetViewInsets);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(
      tester.getRect(next).bottom,
      lessThanOrEqualTo(tester.getRect(activity).top),
    );
    expect(tester.getRect(activity).bottom, lessThanOrEqualTo(360));
    expect(next.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  group('the server owner', () {
    testWidgets('starts by choosing how people sign in', (tester) async {
      await pumpOnboarding(tester, serverOwner: true);
      expect(find.text('Choose how people sign in'), findsOneWidget);
      expect(find.text("Let's plug in your tools."), findsNothing);
    });

    testWidgets('nothing is preselected, so Continue waits for a choice', (
      tester,
    ) async {
      await pumpOnboarding(tester, serverOwner: true);
      final next = tester.widget<CcButton>(
        find.widgetWithText(CcButton, 'Continue'),
      );
      expect(next.onPressed, isNull);
      for (final radio in tester.widgetList<CcRadio<ConnectModeSetting>>(
        find.byType(CcRadio<ConnectModeSetting>),
      )) {
        expect(radio.groupValue, isNull);
      }
    });

    testWidgets('saves the choice, then moves on to the tools step', (
      tester,
    ) async {
      final configured = <Map<String, dynamic>>[];
      await pumpOnboarding(
        tester,
        serverOwner: true,
        onCall: (op, args) {
          if (op == 'connect.configure') {
            configured.add(args);
          }
        },
      );
      await tester.tap(find.text("Use Control Center's apps"));
      await tester.pump();
      final next = find.widgetWithText(CcButton, 'Continue');
      await tester.ensureVisible(next);
      await tester.tap(next);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(configured, [
        {'mode': 'hosted'},
      ]);
      expect(find.text("Let's plug in your tools."), findsOneWidget);
    });
  });

  testWidgets('a member who does not own the server never sees the choice', (
    tester,
  ) async {
    await pumpOnboarding(tester);
    expect(find.text('Choose how people sign in'), findsNothing);
  });

  testWidgets('renders app title in app bar', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    expect(find.text("Let's plug in your tools."), findsOneWidget);
  });

  testWidgets('renders scrolled layout with constrained width', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('scrolling the step body leaves the header pinned', (
    tester,
  ) async {
    await pumpOnboarding(tester, authenticated: false);

    // Shrink the viewport so the step body must scroll.
    tester.view.physicalSize = const Size(900, 520);
    await tester.pump();

    final indicator = find.byKey(const Key('onboarding-step-indicator'));
    final title = find.text("Let's plug in your tools.");
    expect(indicator, findsOneWidget);
    expect(title, findsOneWidget);
    final indicatorTop = tester.getTopLeft(indicator);
    final titleTop = tester.getTopLeft(title);

    // The only scrollable is the step body — neither the step indicator nor
    // the title/subtitle header sits inside it. (Regression: one page-wide
    // SingleChildScrollView used to scroll the whole header away and draw
    // the scrollbar at the window edge.)
    expect(
      find.ancestor(
        of: indicator,
        matching: find.byType(SingleChildScrollView),
      ),
      findsNothing,
    );
    expect(
      find.ancestor(of: title, matching: find.byType(SingleChildScrollView)),
      findsNothing,
    );

    await tester.drag(
      find.byType(SingleChildScrollView),
      const Offset(0, -200),
    );
    await tester.pump();

    // The drag really scrolled the body…
    final scrollableState = tester.state<ScrollableState>(
      find.descendant(
        of: find.byType(SingleChildScrollView),
        matching: find.byType(Scrollable),
      ),
    );
    expect(scrollableState.position.pixels, greaterThan(0));
    // …while the pinned chrome never moved.
    expect(tester.getTopLeft(indicator), indicatorTop);
    expect(tester.getTopLeft(title), titleTop);
  });

  testWidgets('renders the step title', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    expect(find.text("Let's plug in your tools."), findsOneWidget);
  });

  testWidgets('step 1 says where credentials are kept', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    expect(
      find.textContaining('Credentials are held by your server'),
      findsOneWidget,
    );
  });

  testWidgets('step 1 is the current step on the progress bar', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    expect(
      find.descendant(
        of: find.byKey(const Key('onboarding-step-indicator')),
        matching: find.text('Connect'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('Continue button disabled when not authenticated', (
    tester,
  ) async {
    await pumpOnboarding(tester, authenticated: false);
    final continueButton = tester.widget<CcButton>(
      find.widgetWithText(CcButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNull);
  });

  testWidgets('Continue button is enabled on step 1 when authenticated', (
    tester,
  ) async {
    await pumpOnboarding(tester, authenticated: true);
    final continueButton = tester.widget<CcButton>(
      find.widgetWithText(CcButton, 'Continue'),
    );
    expect(continueButton.onPressed, isNotNull);
  });

  // =========================================================================
  // Missing steps only: a connection settled at the start drops the step
  // =========================================================================

  /// A forge connection that has settled before the flow plans.
  Override settledConnection() => forgeConnectionsProvider.overrideWithValue(
    const AsyncValue.data([
      ForgeConnection(
        forge: ForgeHost.github,
        status: ForgeConnectionStatus.connected,
        username: 'testuser',
        source: ForgeCredentialSource.oauth,
      ),
    ]),
  );

  testWidgets('a forge connected before the flow starts skips connecting', (
    tester,
  ) async {
    await pumpOnboarding(
      tester,
      deriveAuth: true,
      serverOwner: true,
      extraOverrides: [settledConnection()],
    );
    expect(find.text('Give your work a home.'), findsOneWidget);
    expect(find.text("Let's plug in your tools."), findsNothing);
    expect(find.text('Choose how people sign in'), findsNothing);
  });

  testWidgets('a connection still loading at the start counts as missing', (
    tester,
  ) async {
    // The gate holds an incomplete verdict until the connections answer, so
    // this is a flow opened some other way; showing the step costs one
    // Continue, hiding it could skip a sign-in the person needs.
    await pumpOnboarding(tester, authenticated: true);
    expect(find.text("Let's plug in your tools."), findsOneWidget);
    expect(find.text('Give your work a home.'), findsNothing);
  });

  testWidgets('a first run shows five steps', (tester) async {
    await pumpOnboarding(tester);
    expect(
      find.descendant(
        of: find.byKey(const Key('onboarding-step-indicator')),
        matching: find.byType(AnimatedContainer),
      ),
      findsNWidgets(5),
    );
  });

  // =========================================================================
  // Step 2 — workspace
  // =========================================================================

  testWidgets('step 1 Continue advances to the workspace step', (tester) async {
    await pumpOnboarding(tester, authenticated: true);
    await advanceToWorkspaceStep(tester);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('workspace step shows the workspace subtitle', (tester) async {
    await pumpOnboarding(tester, authenticated: true);
    await advanceToWorkspaceStep(tester);
    expect(find.textContaining('Name your first workspace'), findsOneWidget);
  });

  testWidgets('workspace step fills the second progress segment', (
    tester,
  ) async {
    await pumpOnboarding(tester, authenticated: true);
    await advanceToWorkspaceStep(tester);
    await tester.pump(const Duration(milliseconds: 300));
    final bars = tester
        .widgetList<AnimatedContainer>(
          find.descendant(
            of: find.byKey(const Key('onboarding-step-indicator')),
            matching: find.byType(AnimatedContainer),
          ),
        )
        .toList();
    final accent = Theme.of(
      tester.element(find.byKey(const Key('onboarding-step-indicator'))),
    ).colorScheme.primary;
    Color? fillOf(int i) => (bars[i].decoration! as BoxDecoration).color;
    expect(fillOf(0), accent);
    expect(fillOf(1), accent);
    expect(fillOf(2), isNot(accent));
  });

  testWidgets('workspace step has workspace name text field', (tester) async {
    await pumpOnboarding(tester, authenticated: true);
    await advanceToWorkspaceStep(tester);
    expect(find.byType(CcTextField), findsOneWidget);
  });

  testWidgets('workspace step shows workspace form elements', (tester) async {
    await pumpOnboarding(tester, authenticated: true);
    await advanceToWorkspaceStep(tester);
    // The _LogoPicker shows "Workspace logo" as a hardcoded label.
    expect(find.text('Workspace logo'), findsOneWidget);
  });

  testWidgets('workspace step shows workspace name hint', (tester) async {
    await pumpOnboarding(tester, authenticated: true);
    await advanceToWorkspaceStep(tester);
    expect(find.text('e.g. Platform'), findsOneWidget);
  });

  testWidgets('workspace step Cancel returns to step 1', (tester) async {
    await pumpOnboarding(tester, authenticated: true);
    await advanceToWorkspaceStep(tester);
    // With no skipping, the workspace step always offers a way back.
    final cancelButton = find.text('Cancel');
    await tester.ensureVisible(cancelButton);
    await tester.pump();
    expect(cancelButton, findsOneWidget);

    await tester.tap(cancelButton);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text("Let's plug in your tools."), findsOneWidget);
    expect(find.text('Give your work a home.'), findsNothing);
  });

  // =========================================================================
  // Step indicator & layout structure
  // =========================================================================

  testWidgets('renders step indicator', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    expect(
      find.descendant(
        of: find.byKey(const Key('onboarding-step-indicator')),
        matching: find.byType(AnimatedContainer),
      ),
      findsNWidgets(5),
    );
  });

  testWidgets('ConstrainedBox max width is 720', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    final boxes = find.byType(ConstrainedBox);
    // The main layout ConstrainedBox has the 720 max width.
    final constrained = tester
        .widgetList<ConstrainedBox>(boxes)
        .firstWhere((b) => b.constraints.maxWidth == 720);
    expect(constrained.constraints.maxWidth, 720);
  });

  testWidgets('shows onboarding card with border decoration', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    // _StepHero renders a Container with BoxDecoration (border radius + border).
    final decoratedContainers = find.byWidgetPredicate(
      (w) => w is Container && w.decoration is BoxDecoration,
    );
    // At least the _StepHero card should exist.
    expect(decoratedContainers, findsWidgets);
  });

  testWidgets('step indicator has correct gap SizedBox between segments', (
    tester,
  ) async {
    await pumpOnboarding(tester, authenticated: false);
    // 5 segments produce 4 gaps (SizedBox with width 6).
    final gaps = find.byWidgetPredicate((w) => w is SizedBox && w.width == 6);
    expect(gaps, findsNWidgets(4));
  });

  testWidgets('every step is named above the progress bar', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    final indicator = find.byKey(const Key('onboarding-step-indicator'));
    for (final label in const [
      'Connect',
      'Workspace',
      'Sandbox',
      'Adapter',
      'Voice',
    ]) {
      expect(
        find.descendant(of: indicator, matching: find.text(label)),
        findsOneWidget,
        reason: 'missing step label: $label',
      );
    }
  });

  testWidgets('the current step label takes the accent color', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    final indicator = find.byKey(const Key('onboarding-step-indicator'));
    // Ancestors come nearest-first: the label's own style wrapper is [0].
    Color? colorOf(String label) => tester
        .widgetList<AnimatedDefaultTextStyle>(
          find.ancestor(
            of: find.descendant(of: indicator, matching: find.text(label)),
            matching: find.byType(AnimatedDefaultTextStyle),
          ),
        )
        .first
        .style
        .color;

    final accent = Theme.of(tester.element(indicator)).colorScheme.primary;
    expect(colorOf('Connect'), accent);
    // Steps still ahead read as plain text, not accented.
    expect(colorOf('Workspace'), isNot(accent));
  });

  // =========================================================================
  // Settings
  // =========================================================================

  testWidgets('the corner opens language and theme, and back returns', (
    tester,
  ) async {
    await pumpOnboarding(tester, authenticated: false);
    await tester.tap(find.byType(OnboardingSettingsButton));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PreAppSettingsPage), findsOneWidget);

    await tester.tap(find.text('Back'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.byType(PreAppSettingsPage), findsNothing);
    expect(find.text("Let's plug in your tools."), findsOneWidget);
  });

  // =========================================================================
  // Regression — creating the workspace must NOT leave onboarding
  // =========================================================================

  testWidgets(
    'creating the workspace advances to the sandbox step instead of navigating away',
    (tester) async {
      await pumpOnboarding(
        tester,
        authenticated: true,
        extraOverrides: [
          createWorkspaceProvider.overrideWith(
            _FakeCreateWorkspaceNotifier.new,
          ),
          workspacesProvider.overrideWith(
            (ref) => Stream.value(const <Workspace>[]),
          ),
          sandboxDetectionProvider.overrideWith(
            (ref) => Future.value(macNativeDetection),
          ),
        ],
      );
      await advanceToWorkspaceStep(tester);

      await tester.enterText(find.byType(CcTextField), 'Acme');
      await tester.pump();
      final submit = find.widgetWithText(CcButton, 'Continue');
      await tester.ensureVisible(submit);
      await tester.pump();
      await tester.tap(submit);
      await tester.pump();
      // Let the fake create resolve, the step transition animate and the
      // sandbox detection future land.
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Regression: the create provider used to `go(inboxRoute(id))` the moment
      // the insert landed, unmounting onboarding mid-flow — the sandbox,
      // adapter and voice steps never rendered. The flow must
      // continue: step 3 is the sandbox step.
      expect(find.text('Isolate agent execution.'), findsOneWidget);
      expect(find.text('Give your work a home.'), findsNothing);
    },
  );

  // =========================================================================
  // Invited member — belongs to a workspace they did not create
  // =========================================================================
  group('invited member', () {
    Override withWorkspace() => workspacesProvider.overrideWithValue(
      AsyncValue.data([
        Workspace(
          id: 'ws-invited',
          name: 'Acme',
          createdAt: DateTime(2025),
          updatedAt: DateTime(2025),
        ),
      ]),
    );

    testWidgets('of a ready workspace sees just "You"', (tester) async {
      // Being invited IS how they got a workspace, and its agents already have
      // a sandbox and a runner. Asking them to name a workspace leaves a stray
      // second one behind.
      await pumpOnboarding(
        tester,
        finished: false,
        deriveAuth: true,
        extraOverrides: [withWorkspace(), settledConnection()],
      );

      expect(find.byType(OnboardingYouStep), findsOneWidget);
      final indicator = find.byKey(const Key('onboarding-step-indicator'));
      expect(
        find.descendant(of: indicator, matching: find.text('You')),
        findsOneWidget,
      );
      for (final label in const [
        'Connect',
        'Workspace',
        'Sandbox',
        'Adapter',
        'Voice',
      ]) {
        expect(
          find.descendant(of: indicator, matching: find.text(label)),
          findsNothing,
          reason: 'unexpected $label',
        );
      }
    });

    testWidgets('without a forge sign-in still connects one', (tester) async {
      await pumpOnboarding(
        tester,
        finished: false,
        extraOverrides: [withWorkspace()],
      );

      final indicator = find.byKey(const Key('onboarding-step-indicator'));
      for (final label in const ['You', 'Connect']) {
        expect(
          find.descendant(of: indicator, matching: find.text(label)),
          findsOneWidget,
          reason: 'missing $label',
        );
      }
      expect(
        find.descendant(of: indicator, matching: find.text('Sandbox')),
        findsNothing,
      );
    });
  });

  // =========================================================================
  // No workspace and no right to create one: nothing to set up but themselves
  // =========================================================================
  group('someone who may not create workspaces', () {
    Override noWorkspace() => workspacesProvider.overrideWithValue(
      const AsyncValue<List<Workspace>>.data([]),
    );

    testWidgets('is never asked to create one', (tester) async {
      await pumpOnboarding(
        tester,
        finished: false,
        canCreate: false,
        deriveAuth: true,
        extraOverrides: [noWorkspace(), settledConnection()],
      );

      expect(find.byType(OnboardingYouStep), findsOneWidget);
      final indicator = find.byKey(const Key('onboarding-step-indicator'));
      for (final label in const ['Workspace', 'Sandbox', 'Adapter', 'Voice']) {
        expect(
          find.descendant(of: indicator, matching: find.text(label)),
          findsNothing,
          reason: 'unexpected $label',
        );
      }
    });

    testWidgets('finishing lands on "You are not in a workspace yet"', (
      tester,
    ) async {
      var marked = 0;
      await pumpOnboarding(
        tester,
        finished: false,
        canCreate: false,
        deriveAuth: true,
        routed: true,
        onCall: (op, _) {
          if (op == 'users.markOnboardingFinished') {
            marked++;
          }
        },
        extraOverrides: [
          noWorkspace(),
          settledConnection(),
          currentIdentityProvider.overrideWith(
            (ref) => Completer<IdentityMe>().future,
          ),
        ],
      );

      // "You" is the whole flow: its Continue finishes it.
      final indicator = find.byKey(const Key('onboarding-step-indicator'));
      expect(
        find.descendant(of: indicator, matching: find.text('Workspace')),
        findsNothing,
      );
      final continueButton = find.widgetWithText(CcButton, 'Continue');
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(marked, 1);
      // The route change animates the flow out.
      await tester.pump(const Duration(seconds: 1));
      expect(find.byType(OnboardingScreen), findsNothing);
      expect(find.text('You are not in a workspace yet'), findsOneWidget);
      expect(find.text('Add workspace'), findsNothing);
    });

    testWidgets('still connects a forge when none is connected', (
      tester,
    ) async {
      await pumpOnboarding(
        tester,
        finished: false,
        canCreate: false,
        extraOverrides: [noWorkspace()],
      );

      final indicator = find.byKey(const Key('onboarding-step-indicator'));
      for (final label in const ['You', 'Connect']) {
        expect(
          find.descendant(of: indicator, matching: find.text(label)),
          findsOneWidget,
          reason: 'missing $label',
        );
      }
      expect(
        find.descendant(of: indicator, matching: find.text('Workspace')),
        findsNothing,
      );
    });
  });

  // =========================================================================
  // Solo first run — no workspace yet
  // =========================================================================
  group('the "You" step', () {
    testWidgets('comes first for someone who never finished onboarding', (
      tester,
    ) async {
      await pumpOnboarding(tester, finished: false, serverOwner: true);
      expect(find.byType(OnboardingYouStep), findsOneWidget);
      expect(find.text('Choose your username'), findsOneWidget);
      final indicator = find.byKey(const Key('onboarding-step-indicator'));
      expect(
        find.descendant(of: indicator, matching: find.text('You')),
        findsOneWidget,
      );
      // Prefilled with what the server derived.
      expect(find.text('sam'), findsOneWidget);
    });

    testWidgets('an unchanged name continues to the next step', (tester) async {
      await pumpOnboarding(tester, finished: false, authenticated: true);
      final continueButton = find.widgetWithText(CcButton, 'Continue');
      await tester.ensureVisible(continueButton);
      await tester.tap(continueButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(OnboardingYouStep), findsNothing);
    });

    testWidgets('is skipped for someone already onboarded', (tester) async {
      await pumpOnboarding(tester);
      expect(find.byType(OnboardingYouStep), findsNothing);
      final indicator = find.byKey(const Key('onboarding-step-indicator'));
      expect(
        find.descendant(of: indicator, matching: find.text('You')),
        findsNothing,
      );
    });
  });

  testWidgets('a first-ever run keeps the workspace step', (tester) async {
    await pumpOnboarding(
      tester,
      authenticated: true,
      extraOverrides: [
        workspacesProvider.overrideWithValue(
          const AsyncValue<List<Workspace>>.data([]),
        ),
      ],
    );

    expect(find.text('Workspace'), findsOneWidget);
  });
}

/// Returns a fresh id without touching the server — and, critically, without
/// navigating (the production notifier must not navigate either; the test
/// above pins the continuation of the onboarding flow that used to break).
class _FakeCreateWorkspaceNotifier extends CreateWorkspaceNotifier {
  @override
  Future<String?> create({
    required String name,
    Uint8List? logoBytes,
    String logoExtension = '',
  }) async {
    state = const AsyncData<String?>('ws-new');
    return 'ws-new';
  }
}

/// The account row the server derived for a brand-new person.
class _Profile extends AccountProfileNotifier {
  @override
  Future<UserDto> build() async =>
      UserDto(id: 'u-1', handle: 'sam', displayName: 'Sam');
}
