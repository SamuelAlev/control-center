import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/calendar/presentation/widgets/sections/calendar_section.dart';
import 'package:control_center/features/calendar/providers/google_auth_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' show MaterialApp, Scaffold;

import '../../../helpers/active_workspace.dart';

/// The Google Calendar card on You → Profile. The accounts are
/// the person's but kept per workspace, so the card names the workspace.
void main() {
  late AppLocalizations l10n;

  setUpAll(() async {
    l10n = await AppLocalizations.delegate.load(const Locale('en'));
  });

  Future<void> pump(
    WidgetTester tester, {
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
          googleAccountsProvider.overrideWith((ref) => Stream.value(const [])),
        ],
        // Not `testWrap`: its own scope pins the active workspace to none.
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          locale: const Locale('en'),
          home: Directionality(
            textDirection: textDirection,
            child: CcTheme(
              data: CcThemeData.light(),
              child: const Scaffold(body: CalendarSection()),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('says it applies to this workspace only, by name', (
    tester,
  ) async {
    await pump(tester);
    expect(find.text(l10n.accountReachWorkspace('Acme')), findsOneWidget);
    expect(find.text(l10n.calendarConnectGoogle), findsOneWidget);
  });

  testWidgets('renders right to left', (tester) async {
    await pump(tester, textDirection: TextDirection.rtl);
    expect(tester.takeException(), isNull);
    expect(find.text(l10n.accountReachWorkspace('Acme')), findsOneWidget);
  });
}
