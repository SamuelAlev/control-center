import 'package:control_center/features/settings/presentation/widgets/sections/integrations/workspace_provider_apps_card.dart';
import 'package:control_center/features/settings/providers/provider_apps_providers.dart';
import 'package:control_center/features/settings/providers/workspace_provider_apps_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../../helpers/test_wrap.dart';

/// The workspace's own Google, Linear and Klipy apps: one row each, a
/// half-configured own app named as an error, and nothing for anyone the
/// list resolves empty for.
void main() {
  late AppLocalizations l10n;
  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  const apps = [
    WorkspaceProviderAppView(
      provider: 'google',
      mode: WorkspaceAppMode.own,
      clientId: 'ws.apps.googleusercontent.com',
      state: ProviderAppState.partial,
      redirectUris: ['https://cc.example/oauth/google/callback'],
    ),
    WorkspaceProviderAppView(provider: 'linear'),
    WorkspaceProviderAppView(provider: 'klipy'),
  ];

  Future<void> pump(
    WidgetTester tester,
    List<WorkspaceProviderAppView> list, {
    TextDirection? textDirection,
  }) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          workspaceProviderAppsProvider.overrideWith((ref) async => list),
        ],
        child: testWrap(
          const SingleChildScrollView(child: WorkspaceProviderAppsCard()),
          textDirection: textDirection,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders nothing when the list is empty', (tester) async {
    await pump(tester, const []);
    expect(find.text(l10n.workspaceProviderApps), findsNothing);
  });

  testWidgets('one row per provider, the partial own app as an error', (
    tester,
  ) async {
    await pump(tester, apps);
    expect(find.text(l10n.workspaceProviderAppsDescription), findsOneWidget);
    expect(find.text('Google Calendar'), findsOneWidget);
    expect(find.text('Linear'), findsOneWidget);
    expect(find.text('Klipy'), findsOneWidget);
    expect(find.text(l10n.settingsStateFailed), findsOneWidget);
    expect(find.text(l10n.workspaceProviderAppStatusInherit), findsNWidgets(2));
  });

  for (final direction in TextDirection.values) {
    testWidgets('expanding names what is missing (${direction.name})', (
      tester,
    ) async {
      await pump(tester, apps, textDirection: direction);
      await tester.tap(find.text('Google Calendar'));
      await tester.pumpAndSettle();
      expect(
        find.text(
          l10n.workspaceProviderAppMissingFields(l10n.providerClientSecret),
        ),
        findsOneWidget,
      );
      expect(
        find.text('https://cc.example/oauth/google/callback'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
