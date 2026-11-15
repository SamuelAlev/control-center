import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/forge/providers/forge_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/settings_sidebar_nav.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

/// The settings sidebar's one attention dot: a person with no code host
/// connected is pointed at their profile, where their accounts are.
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await appLocalizationsDelegate.load(const Locale('en'));
  });

  Future<void> pump(WidgetTester tester, {required bool forgeConnected}) async {
    tester.view
      ..physicalSize = const Size(400, 2400)
      ..devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isServerOwnerProvider.overrideWithValue(false),
          isWorkspaceAdminAnywhereProvider.overrideWithValue(false),
          hasAnyForgeConnectedProvider.overrideWithValue(forgeConnected),
        ],
        child: testWrap(
          SingleChildScrollView(
            child: SettingsSidebarNav(
              location: settingsAppearanceRoute('ws-1'),
              workspaceId: 'ws-1',
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Finder row(String label) => find.byWidgetPredicate(
    (widget) => widget is CcSidebarItem && widget.label == label,
  );

  /// The dot, by the words its tooltip gives it.
  Finder dot() => find.byWidgetPredicate(
    (widget) => widget is CcTooltip && widget.message == l10n.needsSetupLabel,
  );

  testWidgets('the profile leads the list and there is no accounts page', (
    tester,
  ) async {
    await pump(tester, forgeConnected: true);
    final rows = tester.widgetList<CcSidebarItem>(find.byType(CcSidebarItem));
    expect(rows.first.label, l10n.accountProfileTitle);
    expect(row(l10n.linkedAccountsTitle), findsNothing);
    expect(dot(), findsNothing);
  });

  testWidgets('with no code host connected, the profile row is dotted', (
    tester,
  ) async {
    await pump(tester, forgeConnected: false);
    expect(dot(), findsOneWidget);
    expect(
      find.descendant(of: row(l10n.accountProfileTitle), matching: dot()),
      findsOneWidget,
    );
  });
}
