import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/auth/domain/entities/github_cli_status.dart';
import 'package:control_center/features/auth/presentation/widgets/api_keys_panel.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
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
        home: CcTheme(
          data: CcThemeData.light(),
          child: Scaffold(body: SingleChildScrollView(child: child)),
        ),
      ),
    );
  }

  group('ApiKeysPanel', () {
    testWidgets('renders without crashing', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysPanel()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(ApiKeysPanel), findsOneWidget);
    });

    testWidgets('renders GitHub CLI card', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysPanel()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('GitHub CLI integration'), findsOneWidget);
    });

    testWidgets('shows Add Token button', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysPanel()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Add token'), findsOneWidget);
    });

    testWidgets('shows Not configured for Linear', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysPanel()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Not configured.'), findsOneWidget);
    });

    testWidgets('shows Refresh button', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysPanel()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Refresh'), findsOneWidget);
    });

    testWidgets('renders four SectionCard widgets', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysPanel()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.byType(SectionCard), findsNWidgets(4));
    });

    testWidgets('shows Linear API Key section', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysPanel()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Ticketing API key'), findsOneWidget);
    });

    testWidgets('renders Update Key button for Linear', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysPanel()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Update key'), findsOneWidget);
    });

    testWidgets('renders GitHub PAT card subtitle', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysPanel()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.textContaining('Required if gh CLI is not available'), findsOneWidget);
    });
  });
}
