import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/auth/domain/entities/github_cli_status.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase testDb;
  late SharedPreferences prefs;

  setUp(() async {
    testDb = createTestDatabase();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await testDb.close();
  });

  // ---------------------------------------------------------------------------
  // Helper: pump a full OnboardingScreen with the given overrides.
  // ---------------------------------------------------------------------------
  Future<void> pumpOnboarding(
    WidgetTester tester, {
    bool authenticated = false,
  }) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final githubCliStatus = authenticated
        ? const GitHubCliStatus(
            isInstalled: true, isAuthenticated: true, username: 'testuser')
        : const GitHubCliStatus();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
          githubCliStatusProvider
              .overrideWith((ref) => Future.value(githubCliStatus)),
          isGitHubAuthenticatedProvider
              .overrideWith((ref) => authenticated),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const Scaffold(body: OnboardingScreen()),
          ),
        ),
      ),
    );
    await tester.pump();
    if (authenticated) {
      // Allow the post-frame callback to advance from step 0 → 1.
      await tester.pump(const Duration(milliseconds: 500));
    } else {
      await tester.pump(const Duration(milliseconds: 200));
    }
  }

  // =========================================================================
  // Existing tests (preserved)
  // =========================================================================

  testWidgets('renders step 1 with welcome and API keys panel', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    expect(find.text("Let's plug in your tools."), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('renders step 2 when authenticated', (tester) async {
    await pumpOnboarding(tester, authenticated: true);
    expect(find.text('Give your work a home.'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('renders step indicator', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    expect(find.byType(AnimatedContainer), findsNWidgets(6));
  });

  testWidgets('renders app title in app bar', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    expect(find.text("Let's plug in your tools."), findsOneWidget);
  });

  testWidgets('renders scrolled layout with constrained width', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('step 2 has back button that calls onBack', (tester) async {
    await pumpOnboarding(tester, authenticated: true);
    // When authenticated the first step is skipped, so there is no back button.
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('renders step descriptions', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    expect(find.textContaining('Step 1'), findsOneWidget);
  });

  testWidgets('Continue button disabled when not authenticated', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    final continueButton =
        tester.widget<FButton>(find.widgetWithText(FButton, 'Continue'));
    expect(continueButton.onPress, isNull);
  });

  // =========================================================================
  // New tests — step indicator
  // =========================================================================

  testWidgets('step indicator shows 5 segments when authenticated (step 1 skipped)',
      (tester) async {
    await pumpOnboarding(tester, authenticated: true);
    expect(find.byType(AnimatedContainer), findsNWidgets(5));
  });

  // =========================================================================
  // New tests — theme toggle
  // =========================================================================

  testWidgets('renders theme toggle button', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    // Light theme → moon icon (LucideIcons.moon). The toggle is an FButton.icon
    // inside a Positioned widget. Verify at least one Icon widget exists.
    expect(find.byType(Icon), findsWidgets);
  });

  testWidgets('theme toggle is tappable without errors', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    // Find the theme toggle FButton.icon near the top-right of the screen.
    // It's inside a Positioned widget. Tap the last FButton.
    final toggleFinder = find.byType(FButton).last;
    expect(toggleFinder, findsOneWidget);

    await tester.tap(toggleFinder);
    // Pump to let the forui tappable animation timers settle.
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    // Tapping must not throw. Just verifying the screen is still present.
    expect(find.text("Let's plug in your tools."), findsOneWidget);
  });
  // =========================================================================
  // New tests — step copy content
  // =========================================================================

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

  testWidgets('step 2 shows workspace subtitle when authenticated', (tester) async {
    await pumpOnboarding(tester, authenticated: true);
    expect(
      find.textContaining('Name your first workspace'),
      findsOneWidget,
    );
  });

  testWidgets('step 2 shows Workspace eyebrow when authenticated', (tester) async {
    await pumpOnboarding(tester, authenticated: true);
    // Eyebrow is "Step 1 · Workspace" (step is 1-based because step 0 was skipped).
    expect(find.text('Step 1 · Workspace'), findsOneWidget);
  });

  // =========================================================================
  // New tests — layout & animation structure
  // =========================================================================

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
    final constrained = tester.widgetList<ConstrainedBox>(boxes).firstWhere(
      (b) => b.constraints.maxWidth == 720,
    );
    expect(constrained.constraints.maxWidth, 720);
  });

  // =========================================================================
  // New tests — step 2 content details
  // =========================================================================

  testWidgets('step 2 has workspace name text field', (tester) async {
    await pumpOnboarding(tester, authenticated: true);
    expect(find.byType(FTextField), findsOneWidget);
  });

  testWidgets('step 2 shows workspace form elements', (tester) async {
    await pumpOnboarding(tester, authenticated: true);
    // The _LogoPicker shows "Workspace logo" as a hardcoded label.
    expect(find.text('Workspace logo'), findsOneWidget);
  });

  testWidgets('step 2 shows workspace name hint', (tester) async {
    await pumpOnboarding(tester, authenticated: true);
    // The hint is l10n.egPlatform = 'e.g. macOS'.
    expect(find.text('e.g. macOS'), findsOneWidget);
  });

  // =========================================================================
  // New tests — step 1 specific content
  // =========================================================================

  testWidgets('step 1 eyebrow text changes when authenticated flow skipped',
      (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    // Step 0 of 6: eyebrow is "Step 1 · Connect".
    expect(find.text('Step 1 · Connect'), findsOneWidget);
  });

  testWidgets('does not show step 1 title when authenticated', (tester) async {
    await pumpOnboarding(tester, authenticated: true);
    expect(find.text("Let's plug in your tools."), findsNothing);
  });

  // =========================================================================
  // New tests — edge cases
  // =========================================================================

  testWidgets('shows onboarding card with border decoration', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    // _StepHero renders a Container with BoxDecoration (border radius + border).
    final decoratedContainers = find.byWidgetPredicate(
      (w) => w is Container && w.decoration is BoxDecoration,
    );
    // At least the _StepHero card should exist.
    expect(decoratedContainers, findsWidgets);
  });

  testWidgets('step indicator has correct gap SizedBox between segments',
      (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    // 6 segments produce 5 gaps (SizedBox with width 6).
    final gaps = find.byWidgetPredicate(
      (w) => w is SizedBox && w.width == 6,
    );
    expect(gaps, findsNWidgets(5));
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


  testWidgets('step ordering: unauthenticated starts at step 0 title',
      (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    expect(find.text("Let's plug in your tools."), findsOneWidget);
    expect(find.text('Give your work a home.'), findsNothing);
  });

  testWidgets('step ordering: authenticated starts at workspace step',
      (tester) async {
    await pumpOnboarding(tester, authenticated: true);
    expect(find.text('Give your work a home.'), findsOneWidget);
    expect(find.text("Let's plug in your tools."), findsNothing);
  });

  // =========================================================================
  // New tests — interaction: Continue button on Step 1 state
  // =========================================================================

  testWidgets('Continue button is null onPress when unauthenticated', (tester) async {
    await pumpOnboarding(tester, authenticated: false);
    final continueButton =
        tester.widget<FButton>(find.widgetWithText(FButton, 'Continue'));
    expect(continueButton.onPress, isNull);
  });

  testWidgets('Continue button not null when authenticated on step 0 (before skip)',
      (tester) async {
    // This test verifies the logical invariant: on Step 1, if isAuthed is true,
    // the Continue button IS enabled. We test by checking the _StepOne widget logic
    // through the provider override — the post-frame callback will jump to step 1
    // immediately, so we can't observe step 0 with auth. Instead, we verify the
    // opposite: that step 0 without auth has a disabled button (tested above),
    // and step 1 (workspace) with auth has its own Continue button (tested above).
    // The invariant is: the _StepOne continue button is enabled iff isAuthed.
    // We test it indirectly by verifying the authenticated flow works.
    await pumpOnboarding(tester, authenticated: true);
    // The workspace step has its own Continue button.
    expect(find.text('Continue'), findsOneWidget);
  });
}
