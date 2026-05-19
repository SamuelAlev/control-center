import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/auth/presentation/widgets/api_keys_panel.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/settings/providers/workspace_settings_providers.dart';
import 'package:control_center/features/ticketing/providers/ticketing_connection_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppPreferences prefs;

  setUp(() {
    prefs = AppPreferences.inMemory();
  });

  Widget wrap({
    List<ForgeConnection> connections = const [],
    Map<String, SignInProvider> signIn = const {},
    Map<TicketProvider, TicketingConnection> ticketing = const {},
    TicketProvider vendor = TicketProvider.local,
  }) => ProviderScope(
    overrides: [
      appPreferencesProvider.overrideWithValue(prefs),
      forgeConnectionsProvider.overrideWith((ref) async => connections),
      signInProvidersProvider.overrideWith((ref) async => signIn),
      ticketingConnectionsProvider.overrideWith((ref) async => ticketing),
      // The vendor is a WORKSPACE setting, so the fixture is the settings map
      // rather than a local preference.
      workspaceSettingsProvider.overrideWith(
        (ref) => Stream.value({
          ticketingProviderSettingKey: vendor.toStorageString(),
        }),
      ),
    ],
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      locale: const Locale('en'),
      home: CcTheme(
        data: CcThemeData.light(),
        child: const Scaffold(
          body: SingleChildScrollView(child: ApiKeysPanel()),
        ),
      ),
    ),
  );

  group('structure', () {
    testWidgets('is two cards: code hosting and ticketing', (tester) async {
      // It used to be four — a `gh` CLI card, a PAT card, a ticketing
      // provider card and a ticketing key card — which split each decision
      // across two places.
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.byType(SectionCard), findsNWidgets(2));
    });

    testWidgets('names every supported forge, connected or not', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      for (final forge in ForgeHost.supported) {
        expect(
          find.text(forge.displayName),
          findsOneWidget,
          reason: 'missing row for ${forge.name}',
        );
      }
    });

    testWidgets('the action sits to the RIGHT of the row it belongs to', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      final title = tester.getTopRight(find.text('GitHub'));
      final action = tester.getTopLeft(
        find.widgetWithText(CcButton, 'Add token').first,
      );
      expect(action.dx, greaterThan(title.dx));
    });

    testWidgets('the ticketing provider and its credential live in ONE card', (
      tester,
    ) async {
      await tester.pumpWidget(wrap(vendor: TicketProvider.linear));
      await tester.pumpAndSettle();

      final card = find.ancestor(
        of: find.text('Ticketing provider'),
        matching: find.byType(SectionCard),
      );
      expect(
        find.descendant(of: card, matching: find.text('Linear')),
        findsWidgets,
      );
    });

    testWidgets('local tickets show no credential row', (tester) async {
      // Local tickets live in this server's own database; there is nothing to
      // authenticate to.
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(CcButton, 'Add key'), findsNothing);
    });
  });

  group('the sign-in affordance', () {
    testWidgets('is a token paste when the server has no app', (tester) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.textContaining('Sign in with'), findsNothing);
      expect(find.widgetWithText(CcButton, 'Add token'), findsWidgets);
    });

    testWidgets('is a sign-in when the server has one', (tester) async {
      await tester.pumpWidget(
        wrap(
          signIn: const {
            'github': SignInProvider(id: 'github', flow: SignInFlow.device),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.widgetWithText(CcButton, 'Sign in with GitHub'),
        findsOneWidget,
      );
      // The paste path stays available — it is the only way in for someone
      // whose account the app is not installed for.
      expect(find.widgetWithText(CcButton, 'Add token'), findsWidgets);
    });

    testWidgets('only for the forges the server advertises', (tester) async {
      await tester.pumpWidget(
        wrap(
          signIn: const {
            'github': SignInProvider(id: 'github', flow: SignInFlow.device),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Sign in with GitLab'), findsNothing);
    });
  });

  group('connection state', () {
    testWidgets('names the account, and offers to disconnect', (tester) async {
      await tester.pumpWidget(
        wrap(
          connections: const [
            ForgeConnection(
              forge: ForgeHost.github,
              authenticated: true,
              username: 'octocat',
              source: ForgeCredentialSource.oauth,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Signed in as octocat.'), findsOneWidget);
      expect(find.widgetWithText(CcButton, 'Disconnect'), findsOneWidget);
    });

    testWidgets('says WHICH credential is answering when it is not yours', (
      tester,
    ) async {
      // An operator seeing the wrong account needs to know the server's own
      // app is what is answering, not a token they pasted.
      await tester.pumpWidget(
        wrap(
          connections: const [
            ForgeConnection(
              forge: ForgeHost.github,
              authenticated: true,
              username: 'octocat',
              source: ForgeCredentialSource.app,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining("via this server's app"), findsOneWidget);
    });

    testWidgets('surfaces a rejected credential as its own reason', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          connections: const [
            ForgeConnection(
              forge: ForgeHost.github,
              authenticated: false,
              error: 'GitHub rejected the stored credential.',
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('GitHub rejected the stored credential.'),
        findsOneWidget,
      );
    });
  });
}
