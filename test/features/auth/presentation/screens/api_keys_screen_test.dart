import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/auth/domain/entities/github_cli_status.dart';
import 'package:control_center/features/auth/presentation/screens/api_keys_screen.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        githubCliStatusProvider.overrideWith(
          (ref) => const GitHubCliStatus(isInstalled: true),
        ),
      ],
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('en'),
        home: CcTheme(data: CcThemeData.light(), child: child),
      ),
    );
  }

  group('ApiKeysScreen', () {
    testWidgets('renders AppBar with title', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('API keys'), findsOneWidget);
    });

    testWidgets('renders GitHub CLI card', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('GitHub CLI integration'), findsOneWidget);
    });

    testWidgets('renders PAT card', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Personal access token (optional)'), findsOneWidget);
    });

    testWidgets('renders Linear API Key card', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Ticketing API key'), findsOneWidget);
    });

    testWidgets('renders Add Token button', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Add token'), findsOneWidget);
    });

    testWidgets('renders Update Key button', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Update key'), findsOneWidget);
    });

    testWidgets('renders within ScrollView', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(SingleChildScrollView), findsOneWidget);
    });

    testWidgets('renders Scaffold with AppBar', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('ApiKeysScreen is present', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(ApiKeysScreen), findsOneWidget);
    });

    testWidgets('has 24px padding around body', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysScreen()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      final scrollView = tester.widget<SingleChildScrollView>(
        find.byType(SingleChildScrollView),
      );
      expect(scrollView.padding, const EdgeInsets.all(24));
    });
  });
}
