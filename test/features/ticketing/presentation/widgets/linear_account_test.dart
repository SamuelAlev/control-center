import 'package:cc_connect_core/cc_connect_core.dart' show ConnectOAuthLane;
import 'package:cc_data/cc_data.dart'
    show ProviderConnection, SignInLaneInfo, SignInLaneMode, SignInSlot;
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart'
    show ForgeConnectionStatus;
import 'package:cc_domain/features/ticketing/domain/entities/ticket_provider.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/auth/providers/oauth_providers.dart';
import 'package:control_center/features/settings/providers/workspace_settings_providers.dart';
import 'package:control_center/features/ticketing/presentation/widgets/linear_account_card.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:control_center/shared/widgets/your_account_line.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

import '../../../../helpers/active_workspace.dart';
import '../../../../helpers/settings_contribution.dart';

const _linearOwn = {
  ConnectOAuthLane.linear: SignInLaneInfo(
    lane: ConnectOAuthLane.linear,
    mode: SignInLaneMode.own,
  ),
};

ProviderConnection _linear(
  ForgeConnectionStatus status, {
  String account = '',
  SignInSlot slot = SignInSlot.global,
}) => ProviderConnection(
  lane: ConnectOAuthLane.linear,
  status: status,
  account: account,
  slot: slot,
);

void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });

  // Not `testWrap`: its own scope pins the active workspace to none, and the
  // card names the workspace.
  Future<void> pump(
    WidgetTester tester,
    Widget child, {
    TicketProvider vendor = TicketProvider.linear,
    ProviderConnection? linear,
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceIdOverride(),
          activeWorkspaceProvider.overrideWithValue(
            Workspace(
              id: kTestWorkspaceId,
              name: 'Acme',
              createdAt: DateTime(2026),
              updatedAt: DateTime(2026),
            ),
          ),
          workspaceSettingsProvider.overrideWith(
            (ref) => Stream.value({
              ticketingProviderSettingKey: vendor.toStorageString(),
            }),
          ),
          oauthLanesProvider.overrideWith(
            (ref, workspaceId) async => _linearOwn,
          ),
          oauthConnectionsProvider.overrideWith(
            (ref, workspaceId) async => {
              ConnectOAuthLane.linear:
                  linear ?? _linear(ForgeConnectionStatus.notConnected),
            },
          ),
        ],
        child: MaterialApp(
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Directionality(
            textDirection: textDirection,
            child: CcTheme(
              data: CcThemeData.light(),
              child: CcToastScope(child: Scaffold(body: child)),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  group('LinearAccountCard', () {
    testWidgets('offers the person\'s own sign-in, used everywhere', (
      tester,
    ) async {
      await pump(tester, const LinearAccountCard());
      expect(find.text(l10n.ticketing.toUpperCase()), findsOneWidget);
      expect(find.text(l10n.accountReachServer), findsOneWidget);
      expect(find.text(l10n.signInToProvider('Linear')), findsOneWidget);
      // The automation actor is the workspace's, not the person's.
      expect(find.text(l10n.linearAutomationTitle), findsNothing);
    });

    testWidgets('a workspace on its own Linear app keeps its own grant', (
      tester,
    ) async {
      await pump(
        tester,
        const LinearAccountCard(),
        linear: _linear(
          ForgeConnectionStatus.connected,
          account: 'sam@acme.dev',
          slot: SignInSlot.workspace,
        ),
      );
      expect(find.text(l10n.accountReachWorkspace('Acme')), findsOneWidget);
      expect(find.text(l10n.signedInAs('sam@acme.dev')), findsOneWidget);
      expect(find.text(l10n.disconnect), findsOneWidget);
    });

    testWidgets('local tickets with no Linear grant show nothing', (
      tester,
    ) async {
      await pump(
        tester,
        const LinearAccountCard(),
        vendor: TicketProvider.local,
      );
      expect(find.byType(SectionCard), findsNothing);
    });

    testWidgets('a grant stays visible, and disconnectable, under local '
        'tickets', (tester) async {
      await pump(
        tester,
        const LinearAccountCard(),
        vendor: TicketProvider.local,
        linear: _linear(ForgeConnectionStatus.connected, account: 'sam'),
      );
      expect(find.text(l10n.signedInAs('sam')), findsOneWidget);
      expect(find.text(l10n.disconnect), findsOneWidget);
    });

    testWidgets('renders right to left', (tester) async {
      await pump(
        tester,
        const LinearAccountCard(),
        textDirection: TextDirection.rtl,
      );
      expect(tester.takeException(), isNull);
      expect(find.text(l10n.accountReachServer), findsOneWidget);
    });
  });

  group('LinearAccountStatusLine', () {
    testWidgets('names the reader\'s Linear account', (tester) async {
      await pump(
        tester,
        const ContributedSection('ticketing.account-status'),
        linear: _linear(ForgeConnectionStatus.connected, account: 'sam'),
      );
      final line = tester.widget<YourAccountLine>(find.byType(YourAccountLine));
      expect(line.status, l10n.yourAccountEntry('Linear', 'sam'));
      expect(line.attention, isFalse);
    });

    testWidgets('says when the reader has not signed in', (tester) async {
      await pump(tester, const ContributedSection('ticketing.account-status'));
      final line = tester.widget<YourAccountLine>(find.byType(YourAccountLine));
      expect(line.status, l10n.yourAccountNotConnected('Linear'));
      expect(line.attention, isTrue);
    });

    testWidgets('is absent while tickets are local', (tester) async {
      await pump(
        tester,
        const ContributedSection('ticketing.account-status'),
        vendor: TicketProvider.local,
        linear: _linear(ForgeConnectionStatus.connected, account: 'sam'),
      );
      expect(find.byType(YourAccountLine), findsNothing);
    });
  });
}
