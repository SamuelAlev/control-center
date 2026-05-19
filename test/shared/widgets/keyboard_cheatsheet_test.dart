import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/keyboard_cheatsheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// Regression coverage for the keyboard cheat sheet (`?`).
///
/// The sheet is opened by a *global* shortcut whose only context is the root
/// navigator — ABOVE every `RouteBase.builder` subtree. `GoRouterState.of`
/// throws a GoError there ("no GoRouterState above the current context"), so
/// the sheet resolves the current location from the router itself
/// (`GoRouter.maybeOf`). This never surfaced before because the `?` binding
/// could not match on macOS at all (Shift+/ reports `question`, not `slash`) —
/// the crash was unmasked the moment the shortcut started firing.
void main() {
  // The sheet is a 640×560 desktop dialog; give it a desktop-sized viewport.
  void useDesktopViewport(WidgetTester tester) {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);
  }

  Widget scoped(Widget child) {
    return ProviderScope(
      overrides: [
        appPreferencesProvider.overrideWithValue(AppPreferences.inMemory()),
        codeFontFamilyProvider.overrideWithValue('Fira Code'),
      ],
      child: child,
    );
  }

  testWidgets(
    'opens from the root-navigator context (the global ? handler path)',
    (tester) async {
      useDesktopViewport(tester);
      // Mirror production: the app router owns the shared rootNavigatorKey and
      // every destination is workspace-prefixed.
      final router = GoRouter(
        navigatorKey: rootNavigatorKey,
        initialLocation: '/workspaces/ws-1/pull-requests',
        routes: [
          GoRoute(
            path: '/workspaces/:workspaceId/pull-requests',
            builder: (_, _) => const SizedBox.shrink(),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        scoped(
          MaterialApp.router(
            routerConfig: router,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The global `?` shortcut opens the sheet with the ROOT navigator context,
      // which sits above every RouteBase.builder subtree.
      showKeyboardCheatSheet(rootNavigatorKey.currentContext!);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(tester.takeException(), isNull);
      // Matches both the dialog title and the `?` binding's own row label.
      expect(find.text('Keyboard shortcuts'), findsWidgets);
      // The workspace prefix is stripped, so the /pull-requests-scoped bindings
      // (pr.list-refresh — "Refresh") appear below the global ones. The list
      // is lazy, so scroll the section into view.
      await tester.scrollUntilVisible(
        find.text('Refresh'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      expect(find.text('Refresh'), findsOneWidget);
    },
  );

  testWidgets('degrades to global shortcuts with no router in the tree', (
    tester,
  ) async {
    useDesktopViewport(tester);
    // A context with a Navigator but no GoRouter (rootNavigatorKey unattached,
    // GoRouter.maybeOf returns null) must still open the sheet.
    await tester.pumpWidget(
      scoped(
        const MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: SizedBox.shrink()),
        ),
      ),
    );

    showKeyboardCheatSheet(tester.element(find.byType(SizedBox)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(tester.takeException(), isNull);
    // Matches both the dialog title and the `?` binding's own row label.
    expect(find.text('Keyboard shortcuts'), findsWidgets);
  });
}
