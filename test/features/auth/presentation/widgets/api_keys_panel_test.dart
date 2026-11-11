import 'package:cc_connect_core/cc_connect_core.dart'
    show ConnectOAuthLane, SignInUnavailableReason;
import 'package:cc_data/cc_data.dart'
    show ProviderConnection, SignInLaneInfo, SignInLaneMode;
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/auth/presentation/widgets/api_keys_panel.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/settings/providers/workspace_settings_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

const _githubOwn = SignInLaneInfo(
  lane: ConnectOAuthLane.github,
  mode: SignInLaneMode.own,
);

void main() {
  late AppPreferences prefs;

  setUp(() {
    prefs = AppPreferences.inMemory();
  });

  Widget wrap({
    List<ForgeConnection> connections = const [],
    Map<ConnectOAuthLane, SignInLaneInfo> lanes = const {},
    Map<ConnectOAuthLane, ProviderConnection> grants = const {},
    TicketProvider vendor = TicketProvider.local,
  }) => ProviderScope(
    overrides: [
      appPreferencesProvider.overrideWithValue(prefs),
      forgeConnectionsProvider.overrideWith((ref) async => connections),
      oauthLanesProvider.overrideWith((ref, workspaceId) async => lanes),
      oauthConnectionsProvider.overrideWith((ref, workspaceId) async => grants),
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

  CcButton button(WidgetTester tester, String label) =>
      tester.widget<CcButton>(find.widgetWithText(CcButton, label));

  group('structure', () {
    testWidgets('is two cards: code hosting and ticketing', (tester) async {
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

    testWidgets('the action sits to the end of the row it belongs to', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(lanes: const {ConnectOAuthLane.github: _githubOwn}),
      );
      await tester.pumpAndSettle();

      final title = tester.getTopRight(find.text('GitHub'));
      final action = tester.getTopLeft(
        find.widgetWithText(CcButton, 'Sign in to GitHub'),
      );
      expect(action.dx, greaterThan(title.dx));
    });

    testWidgets('with Linear, the person\'s own sign-in is its own card', (
      tester,
    ) async {
      // The vendor is the workspace's choice; the sign-in is the person's,
      // the same card You → Profile shows.
      await tester.pumpWidget(wrap(vendor: TicketProvider.linear));
      await tester.pumpAndSettle();

      expect(find.byType(SectionCard), findsNWidgets(3));
      final vendorCard = find.ancestor(
        of: find.text('Ticketing provider'),
        matching: find.byType(SectionCard),
      );
      expect(
        find.descendant(
          of: vendorCard,
          matching: find.widgetWithText(CcButton, 'Sign in to Linear'),
        ),
        findsNothing,
      );
      expect(find.widgetWithText(CcButton, 'Sign in to Linear'), findsOneWidget);
    });

    testWidgets('local tickets show no credential row', (tester) async {
      // Local tickets live in this server's own database; there is nothing to
      // authenticate to.
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(find.widgetWithText(CcButton, 'Sign in to Linear'), findsNothing);
    });
  });

  group('the GitHub affordance', () {
    testWidgets('is a sign-in, never a token paste', (tester) async {
      await tester.pumpWidget(
        wrap(lanes: const {ConnectOAuthLane.github: _githubOwn}),
      );
      await tester.pumpAndSettle();

      expect(button(tester, 'Sign in to GitHub').onPressed, isNotNull);
      // GitLab and Bitbucket keep their pasted token; GitHub never takes one.
      expect(
        find.widgetWithText(CcButton, 'Add token'),
        findsNWidgets(ForgeHost.supported.length - 1),
      );
    });

    testWidgets('is disabled, with the reason, when the lane is unavailable', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          lanes: const {
            ConnectOAuthLane.github: SignInLaneInfo(
              lane: ConnectOAuthLane.github,
              mode: SignInLaneMode.unavailable,
              unavailableReason: SignInUnavailableReason.notConfigured,
            ),
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(button(tester, 'Sign in to GitHub').onPressed, isNull);
      expect(
        find.text("GitHub sign-in isn't set up for this workspace."),
        findsOneWidget,
      );
    });

    testWidgets('is disabled while the server has not answered', (
      tester,
    ) async {
      await tester.pumpWidget(wrap());
      await tester.pumpAndSettle();

      expect(button(tester, 'Sign in to GitHub').onPressed, isNull);
    });
  });

  group('connection state', () {
    testWidgets('names the account, and offers to disconnect', (tester) async {
      await tester.pumpWidget(
        wrap(
          lanes: const {ConnectOAuthLane.github: _githubOwn},
          connections: const [
            ForgeConnection(
              forge: ForgeHost.github,
              status: ForgeConnectionStatus.connected,
              username: 'octocat',
              source: ForgeCredentialSource.oauth,
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Signed in as octocat.'), findsOneWidget);
      expect(find.widgetWithText(CcButton, 'Disconnect'), findsOneWidget);
      expect(find.widgetWithText(CcButton, 'Sign in again'), findsOneWidget);
    });

    testWidgets('surfaces a rejected credential as its own reason', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          connections: const [
            ForgeConnection(
              forge: ForgeHost.github,
              status: ForgeConnectionStatus.notConnected,
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
