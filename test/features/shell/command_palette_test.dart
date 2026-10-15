import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/shell/providers/command_palette_providers.dart';
import 'package:control_center/features/workspaces/presentation/widgets/add_workspace_form.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/active_workspace.dart';

void main() {
  Future<GoRouter> openPalette(
    WidgetTester tester, {
    String? workspaceId = 'w1',
  }) async {
    final router = GoRouter(
      navigatorKey: rootNavigatorKey,
      initialLocation: workspaceId == null
          ? workspaceListRoute
          : inboxRoute(workspaceId),
      routes: [
        GoRoute(
          path: workspaceListRoute,
          builder: (_, _) => const Text('Workspace picker'),
        ),
        GoRoute(
          path: '/workspaces/:workspaceId/:surface',
          builder: (_, _) => const Text('Workspace surface'),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(AppPreferences.inMemory()),
          codeFontFamilyProvider.overrideWithValue('Fira Code'),
          activeWorkspaceIdOverride(workspaceId),
          commandSourcesProvider.overrideWith(
            (ref) => [ref.watch(navigationCommandSourceProvider)],
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          builder: (context, child) =>
              CcTheme(data: CcThemeData.light(), child: child!),
        ),
      ),
    );
    await tester.pumpAndSettle();
    showCommandPalette(rootNavigatorKey.currentContext!, buildGlobalCommands);
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('new workspace opens the creation form instead of the picker', (
    tester,
  ) async {
    final router = await openPalette(tester);
    await tester.enterText(find.byType(EditableText), 'New workspace');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.byType(AddWorkspaceForm), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, inboxRoute('w1'));
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();
    expect(find.byType(AddWorkspaceForm), findsNothing);
  });

  testWidgets('spaces without a workspace returns to the workspace picker', (
    tester,
  ) async {
    final router = await openPalette(tester, workspaceId: null);
    await tester.enterText(find.byType(EditableText), 'Spaces');
    await tester.pump();
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(find.text('Workspace picker'), findsOneWidget);
    expect(router.routeInformationProvider.value.uri.path, workspaceListRoute);
    expect(find.byType(EditableText), findsNothing);
  });
}
