import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/shell/providers/command_palette_providers.dart';
import 'package:control_center/features/workspaces/presentation/widgets/add_workspace_form.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
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
          canCreateWorkspacesProvider.overrideWithValue(true),
          commandSourcesProvider.overrideWith(
            (ref) => [ref.watch(navigationCommandSourceProvider)],
          ),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: appLocalizationsDelegates,
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

  testWidgets('new workspace is offered only to someone who may create', (
    tester,
  ) async {
    Future<List<String>> idsFor({required bool canCreate}) async {
      late List<String> ids;
      final router = GoRouter(
        initialLocation: inboxRoute('w1'),
        routes: [
          GoRoute(
            path: '/workspaces/:workspaceId/:surface',
            builder: (_, _) => Consumer(
              builder: (context, ref, _) {
                ids = [
                  for (final item
                      in ref
                          .read(navigationCommandSourceProvider)
                          .buildItems(context, ref))
                    item.id,
                ];
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(AppPreferences.inMemory()),
            activeWorkspaceIdOverride('w1'),
            canCreateWorkspacesProvider.overrideWithValue(canCreate),
          ],
          child: MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: appLocalizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pump();
      return ids;
    }

    expect(await idsFor(canCreate: true), contains('new-workspace'));
    final withoutRight = await idsFor(canCreate: false);
    expect(withoutRight, isNot(contains('new-workspace')));
    // Switching workspaces stays available to everyone.
    expect(withoutRight, contains('workspaces'));
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

  testWidgets('navigation omits goals and improvements and puts schedules above calendar with clock icon', (
    tester,
  ) async {
    late List<CommandItem> items;
    final router = GoRouter(
      initialLocation: inboxRoute('w1'),
      routes: [
        GoRoute(
          path: '/workspaces/:workspaceId/:surface',
          builder: (_, _) => Consumer(
            builder: (context, ref, _) {
              items = ref
                  .read(navigationCommandSourceProvider)
                  .buildItems(context, ref);
              return const SizedBox.shrink();
            },
          ),
        ),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          appPreferencesProvider.overrideWithValue(AppPreferences.inMemory()),
          activeWorkspaceIdOverride('w1'),
          canCreateWorkspacesProvider.overrideWithValue(true),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: appLocalizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        ),
      ),
    );
    await tester.pump();

    final ids = items.map((e) => e.id).toList();
    expect(ids, isNot(contains('goals')));
    expect(ids, isNot(contains('improvements')));
    expect(ids.indexOf('schedules'), lessThan(ids.indexOf('calendar')));
    final schedules = items.firstWhere((e) => e.id == 'schedules');
    expect(schedules.icon, AppIcons.clock);
  });
}
