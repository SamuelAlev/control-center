import 'dart:async';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/auth/domain/entities/github_cli_status.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_detection_result.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:riverpod/src/framework.dart' show Override;

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
  // There is NO step skipping: the onboarding gate alone decides whether
  // onboarding shows at all; once here, every run starts at step 1, even when
  // GitHub auth is already set up (`authenticated` only flips the gh probe /
  // derived auth flag, which enables step 1's Continue).
  // ---------------------------------------------------------------------------
  Future<void> pumpOnboarding(
    WidgetTester tester, {
    bool authenticated = false,
    // When true, neither the gh probe nor the forge connections are
    // overridden: the test supplies them via [extraOverrides] and the REAL
    // derivation answers hasAnyForgeConnectedProvider.
    bool deriveAuth = false,
    List<Override> extraOverrides = const [],
  }) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final githubCliStatus = authenticated
        ? const GitHubCliStatus(
            isInstalled: true,
            isAuthenticated: true,
            username: 'testuser',
          )
        : const GitHubCliStatus();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
          if (!deriveAuth) ...[
            githubCliStatusProvider.overrideWith(
              (ref) => Future.value(githubCliStatus),
            ),
            // The gate is "at least one forge connected", so the fixture is a
            // forge connection rather than a GitHub-specific flag. Overriding
            // the SOURCE keeps the real derivation
            // (connections → connectedForges → hasAnyForgeConnected) under test.
            forgeConnectionsProvider.overrideWith(
              (ref) async => authenticated
                  ? const [
                      ForgeConnection(
                        forge: ForgeHost.github,
                        authenticated: true,
                        username: 'testuser',
                        source: ForgeCredentialSource.cli,
                      ),
                    ]
                  : const <ForgeConnection>[],
            ),
          ],
          ...extraOverrides,
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: CcTheme(
            data: CcThemeData.light(),
            child: const Scaffold(body: OnboardingScreen()),
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

  testWidgets('renders step descriptions', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    expect(find.textContaining('Step 1'), findsOneWidget);
  });

  testWidgets('step 1 shows subtitle for connect step', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    expect(
      find.textContaining('Connect GitHub so Control Center can read'),
      findsOneWidget,
    );
  });

  testWidgets('step 1 shows step eyebrow', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    expect(find.text('Step 1 · Connect'), findsOneWidget);
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
  // No skipping — the gate decides onboarding, not individual steps
  // =========================================================================

  testWidgets('authenticated users start at step 1 too (no skipping)', (
    tester,
  ) async {
    // The screen used to skip step 1 when API access was already set up —
    // decided from async auth probes, so whether step 1 appeared depended on
    // probe timing. Now incomplete onboarding always starts from scratch.
    await pumpOnboarding(tester, authenticated: true);
    expect(find.text("Let's plug in your tools."), findsOneWidget);
    expect(find.text('Give your work a home.'), findsNothing);
  });

  testWidgets('step indicator shows 5 segments even when authenticated', (
    tester,
  ) async {
    await pumpOnboarding(tester, authenticated: true);
    expect(
      find.descendant(
        of: find.byKey(const Key('onboarding-step-indicator')),
        matching: find.byType(AnimatedContainer),
      ),
      findsNWidgets(5),
    );
  });

  testWidgets('gh auth settled before the first frame still shows step 1', (
    tester,
  ) async {
    // Same contract as "authenticated users start at step 1", exercised
    // through the REAL derivation (connections → hasAnyForgeConnected) rather
    // than an override of the derived flag.
    await pumpOnboarding(
      tester,
      deriveAuth: true,
      extraOverrides: [
        githubCliStatusProvider.overrideWith(
          (ref) => Future.value(
            const GitHubCliStatus(
              isInstalled: true,
              isAuthenticated: true,
              username: 'testuser',
            ),
          ),
        ),
        forgeConnectionsProvider.overrideWith(
          (ref) async => const [
            ForgeConnection(
              forge: ForgeHost.github,
              authenticated: true,
              username: 'testuser',
              source: ForgeCredentialSource.cli,
            ),
          ],
        ),
      ],
    );
    expect(find.text("Let's plug in your tools."), findsOneWidget);
    expect(find.text('Give your work a home.'), findsNothing);
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

  testWidgets('workspace step shows the Workspace eyebrow', (tester) async {
    await pumpOnboarding(tester, authenticated: true);
    await advanceToWorkspaceStep(tester);
    // Eyebrow numbering is 1-based over all five steps: workspace is step 2.
    expect(find.text('Step 2 · Workspace'), findsOneWidget);
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
    // The hint is l10n.egPlatform = 'e.g. macOS'.
    expect(find.text('e.g. macOS'), findsOneWidget);
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

  testWidgets('renders AnimatedSwitcher for step transitions', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    expect(find.byType(AnimatedSwitcher), findsOneWidget);
  });

  testWidgets('renders KeyedSubtree for step animation keys', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    // KeyedSubtree is used inside AnimatedSwitcher and possibly elsewhere.
    expect(find.byType(KeyedSubtree), findsWidgets);
  });

  testWidgets('renders SafeArea', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    expect(find.byType(SafeArea), findsOneWidget);
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

  testWidgets('icon container in step hero is 44x44', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    // The icon background container in _StepHero is 44×44.
    // It has constraints: BoxConstraints(w=44.0, h=44.0).
    final iconBgContainers = find.byWidgetPredicate(
      (w) =>
          w is Container &&
          w.constraints != null &&
          w.constraints!.minWidth == 44 &&
          w.constraints!.minHeight == 44,
    );
    // The _StepHero icon background is exactly one such Container.
    expect(iconBgContainers, findsOneWidget);
  });

  // =========================================================================
  // Theme toggle
  // =========================================================================

  testWidgets('renders theme toggle button', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    // Light theme → moon icon (AppIcons.moon). The toggle is an CcButton.icon
    // inside a Positioned widget. Verify at least one Icon widget exists.
    expect(find.byType(Icon), findsWidgets);
  });

  testWidgets('theme toggle is tappable without errors', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    // Find the theme toggle CcButton.icon near the top-right of the screen.
    // It's inside a Positioned widget. Tap the last CcButton.
    final toggleFinder = find.byType(CcIconButton).last;
    expect(toggleFinder, findsOneWidget);

    await tester.tap(toggleFinder);
    // Pump to let the tappable animation timers settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    // Tapping must not throw. Just verifying the screen is still present.
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
}

/// Returns a fresh id without touching the server — and, critically, without
/// navigating (the production notifier must not navigate either; the test
/// above pins the continuation of the onboarding flow that used to break).
class _FakeCreateWorkspaceNotifier extends CreateWorkspaceNotifier {
  @override
  Future<String?> create({required String name, String? logoPath}) async {
    state = const AsyncData<String?>('ws-new');
    return 'ws-new';
  }
}
