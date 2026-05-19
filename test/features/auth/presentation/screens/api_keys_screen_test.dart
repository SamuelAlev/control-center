import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/auth/presentation/screens/api_keys_screen.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/ticketing/providers/ticketing_connection_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppPreferences prefs;

  setUp(() {
    prefs = AppPreferences.inMemory();
  });

  Widget wrap(Widget child) => ProviderScope(
    overrides: [
      appPreferencesProvider.overrideWithValue(prefs),
      forgeConnectionsProvider.overrideWith(
        (ref) async => const <ForgeConnection>[],
      ),
      signInProvidersProvider.overrideWith(
        (ref) async => const <String, SignInProvider>{},
      ),
      ticketingConnectionsProvider.overrideWith(
        (ref) async => const <TicketProvider, TicketingConnection>{},
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: CcTheme(data: CcThemeData.light(), child: child),
    ),
  );

  group('ApiKeysScreen', () {
    testWidgets('renders its title', (tester) async {
      await tester.pumpWidget(wrap(const ApiKeysScreen()));
      await tester.pumpAndSettle();

      expect(find.text('API keys'), findsOneWidget);
    });

    testWidgets('renders the same connection cards onboarding does', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(const ApiKeysScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Ticketing provider'), findsOneWidget);
      expect(find.text('GitHub'), findsOneWidget);
    });
  });
}
