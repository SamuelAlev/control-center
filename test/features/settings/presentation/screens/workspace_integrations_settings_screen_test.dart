import 'package:control_center/di/settings_registry.dart';
import 'package:control_center/features/settings/presentation/screens/workspace_integrations_settings_screen.dart';
import 'package:control_center/features/settings/settings_extensions.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/test_wrap.dart';

/// The page is pure composition: it owns no card and renders whatever the
/// features contributed to its slot, in their order bands. The shipped
/// contributions keep their ids, slots and orders here, but each renders as
/// a label, so the page is tested without every provider behind every card.
void main() {
  late AppLocalizations l10n;
  late SettingsRegistry shipped;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
    final container = ProviderContainer();
    shipped = container.read(settingsRegistryProvider);
    container.dispose();
  });

  SettingsRegistry stubbed() => SettingsRegistry(
    sections: [
      for (final s in shipped.sections)
        SettingsSectionContribution(
          id: s.id,
          slot: s.slot,
          order: s.order,
          builder: (_) => SizedBox(
            height: 40,
            child: Align(
              alignment: AlignmentDirectional.centerStart,
              child: Text(s.id),
            ),
          ),
        ),
    ],
  );

  Future<void> pump(
    WidgetTester tester, {
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    tester.view
      ..physicalSize = const Size(1200, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final router = GoRouter(
      initialLocation: settingsWorkspaceIntegrationsRoute('ws-1'),
      routes: [
        GoRoute(
          path: settingsWorkspaceIntegrationsRoute(':workspaceId'),
          builder: (_, _) => Directionality(
            textDirection: textDirection,
            child: const WorkspaceIntegrationsSettingsScreen(),
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [settingsRegistryProvider.overrideWithValue(stubbed())],
        child: testRouterWrap(router),
      ),
    );
    await tester.pumpAndSettle();
  }

  const expectedOrder = [
    'connect.workspace',
    'forge.account-status',
    'forge.github-app',
    'ticketing.account-status',
    'ticketing.connection',
    'settings.workspace-app.linear',
    'settings.sync-health',
    'settings.workspace-app.google',
    'chat_bridges.account-status',
    'chat_bridges.workspace-setup',
    'settings.gifs',
  ];

  testWidgets('stacks every provider contribution, grouped by provider', (
    tester,
  ) async {
    await pump(tester);

    expect(find.text(l10n.settingsWorkspaceIntegrations), findsOneWidget);
    expect(
      find.text(l10n.settingsWorkspaceIntegrationsDescription),
      findsOneWidget,
    );
    final tops = [
      for (final id in expectedOrder) tester.getTopLeft(find.text(id)).dy,
    ];
    expect(tops, [...tops]..sort(), reason: 'cards render in band order');
    // The server's sign-in cards stay on Server → Single sign-on.
    expect(find.text('connect.connect'), findsNothing);
    expect(find.text('settings.provider-apps'), findsNothing);
    // The person's own sign-ins are on You → Profile.
    expect(find.text('forge.connections'), findsNothing);
    expect(find.text('ticketing.account'), findsNothing);
    expect(find.text('calendar.accounts'), findsNothing);
    expect(find.text('chat_bridges.my-account-link'), findsNothing);
    expect(find.text('chat_bridges.ticket-drafts'), findsNothing);
  });

  testWidgets('right to left keeps the order and mirrors the cards', (
    tester,
  ) async {
    await pump(tester, textDirection: TextDirection.rtl);
    expect(tester.takeException(), isNull);
    final tops = [
      for (final id in expectedOrder) tester.getTopLeft(find.text(id)).dy,
    ];
    expect(tops, [...tops]..sort());
    // Labels start on the reading side: flush right in RTL.
    final label = find.text('connect.workspace');
    final page = find.byType(WorkspaceIntegrationsSettingsScreen);
    expect(
      tester.getTopRight(label).dx,
      greaterThan(tester.getCenter(page).dx),
    );
  });
}
