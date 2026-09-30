import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/repos/presentation/settings/repo_link_settings_view.dart';
import 'package:control_center/features/repos/providers/repo_link_workspace_choices.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

final _epoch = DateTime.utc(2026);

Widget _wrap(
  AppPreferences preferences, {
  TextDirection textDirection = TextDirection.ltr,
}) => ProviderScope(
  overrides: [
    appPreferencesProvider.overrideWithValue(preferences),
    workspacesProvider.overrideWith(
      (ref) => Stream.value([
        Workspace(
          id: 'ws-cc',
          name: 'Control Center',
          createdAt: _epoch,
          updatedAt: _epoch,
        ),
      ]),
    ),
  ],
  child: CcTheme(
    data: CcThemeData.light(),
    child: MaterialApp(
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: Directionality(
        textDirection: textDirection,
        child: const Scaffold(body: RepoLinkSettingsView()),
      ),
    ),
  ),
);

void main() {
  late AppPreferences preferences;

  setUp(() {
    preferences = AppPreferences.inMemory({
      repoLinkWorkspaceChoicesKey: const RepoLinkWorkspaceChoices()
          .remember('SamuelAlev/control-center', 'ws-cc')
          .remember('acme/widgets', 'ws-deleted')
          .encode(),
    });
  });

  testWidgets('lists each remembered repository with its workspace', (
    tester,
  ) async {
    await tester.pumpWidget(_wrap(preferences));
    await tester.pumpAndSettle();

    expect(find.text('SamuelAlev/control-center'), findsOneWidget);
    expect(find.text('Control Center'), findsOneWidget);
    // A choice for a workspace that no longer exists stays listed so it can
    // still be forgotten.
    expect(find.text('acme/widgets'), findsOneWidget);
    expect(find.text('Workspace no longer available'), findsOneWidget);
  });

  testWidgets('forgetting a choice removes it everywhere', (tester) async {
    await tester.pumpWidget(_wrap(preferences));
    await tester.pumpAndSettle();

    final row = find.ancestor(
      of: find.text('SamuelAlev/control-center'),
      matching: find.byType(CcTile),
    );
    await tester.tap(find.descendant(of: row, matching: find.text('Forget')));
    await tester.pumpAndSettle();

    expect(find.text('SamuelAlev/control-center'), findsNothing);
    expect(
      RepoLinkWorkspaceChoices.decode(
        preferences.getString(repoLinkWorkspaceChoicesKey),
      ).byRepo,
      {'acme/widgets': 'ws-deleted'},
    );
  });

  testWidgets('says so when nothing is remembered', (tester) async {
    await tester.pumpWidget(_wrap(AppPreferences.inMemory()));
    await tester.pumpAndSettle();

    expect(find.text('No remembered choices yet.'), findsOneWidget);
    expect(find.text('Forget'), findsNothing);
  });

  testWidgets('puts the Forget action at the end edge under RTL', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(preferences, textDirection: TextDirection.rtl),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final forget = tester.getCenter(find.text('Forget').first);
    final repo = tester.getCenter(find.text('acme/widgets'));
    expect(forget.dx, lessThan(repo.dx));
  });
}
