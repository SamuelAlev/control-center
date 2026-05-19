import 'dart:async';

import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/ports/sandbox_port.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_backend.dart';
import 'package:cc_domain/features/sandboxing/domain/sandbox_detection_result.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_screen.dart';
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
  // Every run starts at step 1, even when a forge is already connected
  // (`authenticated` only flips the connection fixture, which enables step 1's
  // Continue). The ONE conditional step is the workspace step, which is
  // dropped for someone who already belongs to a workspace — see the "invited
  // member" group. That choice is snapshotted when the flow starts, so it can
  // never change underneath the person walking it.
  // ---------------------------------------------------------------------------
  Future<void> pumpOnboarding(
    WidgetTester tester, {
    bool authenticated = false,
    // When true, the forge connections are NOT overridden: the test supplies
    // them via [extraOverrides] and the REAL derivation answers
    // hasAnyForgeConnectedProvider.
    bool deriveAuth = false,
    List<Override> extraOverrides = const [],
  }) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(prefs),
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
                        authenticated: true,
                        username: 'testuser',
                        source: ForgeCredentialSource.oauth,
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

  testWidgets(
    'a connection settled before the first frame still shows step 1',
    (tester) async {
      // Same contract as "authenticated users start at step 1", exercised
      // through the REAL derivation (connections → hasAnyForgeConnected) rather
      // than an override of the derived flag.
      await pumpOnboarding(
        tester,
        deriveAuth: true,
        extraOverrides: [
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
      expect(find.text("Let's plug in your tools."), findsOneWidget);
      expect(find.text('Give your work a home.'), findsNothing);
    },
  );

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

    testWidgets('drops the workspace step', (tester) async {
      // Being invited IS how they got a workspace. Asking them to name their
      // first one both misdescribes what happened and leaves a stray second
      // workspace behind.
      await pumpOnboarding(
        tester,
        authenticated: true,
        extraOverrides: [withWorkspace()],
      );

      expect(find.text('Workspace'), findsNothing);
      for (final label in const ['Connect', 'Sandbox', 'Adapter', 'Voice']) {
        expect(find.text(label), findsOneWidget, reason: 'missing $label');
      }
    });

    testWidgets('continue from step 1 lands on sandbox, not workspace', (
      tester,
    ) async {
      await pumpOnboarding(
        tester,
        authenticated: true,
        extraOverrides: [withWorkspace()],
      );

      final continueButton = find.widgetWithText(CcButton, 'Continue');
      await tester.ensureVisible(continueButton);
      await tester.pump();
      await tester.tap(continueButton);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Isolate agent execution.'), findsOneWidget);
      expect(find.text('Give your work a home.'), findsNothing);
    });

    testWidgets('still gets the rest of the setup', (tester) async {
      // The point of onboarding them at all: signing in, sandboxing, the model
      // and dictation are per-person and none of them came with the invite.
      await pumpOnboarding(
        tester,
        authenticated: true,
        extraOverrides: [withWorkspace()],
      );

      expect(
        find.byKey(const Key('onboarding-step-indicator')),
        findsOneWidget,
      );
      expect(find.text("Let's plug in your tools."), findsOneWidget);
    });
  });

  // =========================================================================
  // Solo first run — no workspace yet
  // =========================================================================
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
  Future<String?> create({required String name, String? logoPath}) async {
    state = const AsyncData<String?>('ws-new');
    return 'ws-new';
  }
}
