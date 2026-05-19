import 'package:cc_domain/features/auth/domain/entities/github_cli_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/auth/presentation/widgets/api_keys_panel.dart';
import 'package:control_center/features/auth/providers/auth_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppPreferences prefs;

  setUp(() async {
    prefs = AppPreferences.inMemory();
  });

  Widget wrap(Widget child) {
    return ProviderScope(
      overrides: [
        appPreferencesProvider.overrideWithValue(prefs),
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

    testWidgets('renders a card per credential this panel owns', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const ApiKeysPanel()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // GitHub CLI, GitHub PAT, ticketing provider, ticketing API key. The
      // former fifth card (z.ai) moved to the harness provider panel, where
      // per-provider credentials now live (`providers.saveApiKey`).
      expect(find.byType(SectionCard), findsNWidgets(4));
      // Asserted by title too, so a card being swapped rather than removed
      // cannot keep the count passing.
      expect(find.text('GitHub CLI integration'), findsOneWidget);
      expect(find.text('Ticketing provider'), findsOneWidget);
      expect(find.text('Ticketing API key'), findsOneWidget);
    });

    testWidgets('shows Linear API Key section', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysPanel()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.text('Ticketing API key'), findsOneWidget);
    });

    testWidgets('renders one Update key button, for the ticketing key', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const ApiKeysPanel()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Only the ticketing API key remains here; the z.ai key (the former
      // second button) moved to the harness provider panel.
      expect(find.text('Update key'), findsOneWidget);
    });

    testWidgets('renders GitHub PAT card subtitle', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysPanel()));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(
        find.textContaining('Required if gh CLI is not available'),
        findsOneWidget,
      );
    });
  });
}
