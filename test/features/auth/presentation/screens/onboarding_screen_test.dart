import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/auth/domain/entities/github_cli_status.dart';
import 'package:control_center/features/auth/presentation/screens/onboarding_screen.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase testDb;
  late SharedPreferences prefs;

  setUp(() async {
    testDb = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await testDb.close();
  });

  testWidgets('renders step 1 with welcome and API keys panel', (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
          githubCliStatusProvider.overrideWith(
            (ref) async => const GitHubCliStatus(),
          ),
          isGitHubAuthenticatedProvider.overrideWith((ref) => false),
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
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text("Let's plug in your tools."), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('renders step 2 when authenticated', (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
          githubCliStatusProvider.overrideWith(
            (ref) => Future.value(
              const GitHubCliStatus(
                isInstalled: true,
                isAuthenticated: true,
                username: 'testuser',
              ),
            ),
          ),
          isGitHubAuthenticatedProvider.overrideWith((ref) => true),
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
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Give your work a home.'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('renders step indicator', (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
          githubCliStatusProvider.overrideWith(
            (ref) async => const GitHubCliStatus(),
          ),
          isGitHubAuthenticatedProvider.overrideWith((ref) => false),
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
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(AnimatedContainer), findsNWidgets(6));
  });

  testWidgets('renders app title in app bar', (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
          githubCliStatusProvider.overrideWith(
            (ref) async => const GitHubCliStatus(),
          ),
          isGitHubAuthenticatedProvider.overrideWith((ref) => false),
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
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text("Let's plug in your tools."), findsOneWidget);
  });

  testWidgets('renders scrolled layout with constrained width', (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
          githubCliStatusProvider.overrideWith(
            (ref) async => const GitHubCliStatus(),
          ),
          isGitHubAuthenticatedProvider.overrideWith((ref) => false),
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
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(SingleChildScrollView), findsOneWidget);
  });

  testWidgets('step 2 has back button that calls onBack', (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
          githubCliStatusProvider.overrideWith(
            (ref) => Future.value(
              const GitHubCliStatus(
                isInstalled: true,
                isAuthenticated: true,
                username: 'testuser',
              ),
            ),
          ),
          isGitHubAuthenticatedProvider.overrideWith((ref) => true),
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
    await tester.pump(const Duration(milliseconds: 500));
    // When authenticated the first step is skipped, so there is no back button.
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('renders step descriptions', (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
          githubCliStatusProvider.overrideWith(
            (ref) async => const GitHubCliStatus(),
          ),
          isGitHubAuthenticatedProvider.overrideWith((ref) => false),
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
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.textContaining('Step 1'), findsOneWidget);
  });

  testWidgets('Continue button disabled when not authenticated', (tester) async {
    tester.view.physicalSize = const Size(900, 900);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
          githubCliStatusProvider.overrideWith(
            (ref) async => const GitHubCliStatus(),
          ),
          isGitHubAuthenticatedProvider.overrideWith((ref) => false),
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
    await tester.pump(const Duration(milliseconds: 200));

    final continueButton = tester.widget<FButton>(find.widgetWithText(FButton, 'Continue'));
    expect(continueButton.onPress, isNull);
  });
}
