import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/settings/providers/settings_command_source.dart';
import 'package:control_center/features/shell/providers/command_palette_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

import '../../../helpers/active_workspace.dart';

GoRouter _router({bool includeGlobalDestinations = false}) => GoRouter(
  initialLocation: '/home',
  routes: [
    GoRoute(
      path: '/home',
      builder: (_, _) => Scaffold(
        body: _opener(includeGlobalDestinations: includeGlobalDestinations),
      ),
    ),
    GoRoute(
      path: settingsMeetingsRoute(workspaceIdParam),
      builder: (_, _) => const Scaffold(body: Text('Meeting settings page')),
    ),
    GoRoute(
      path: settingsNewsfeedRoute(workspaceIdParam),
      builder: (_, _) => const Scaffold(body: Text('Feed settings page')),
    ),
  ],
);

Widget _app(
  GoRouter router, {
  String? workspaceId = 'ws-1',
  bool isOwner = false,
  bool failOwnerRead = false,
}) => ProviderScope(
  overrides: [
    appPreferencesProvider.overrideWithValue(AppPreferences.inMemory()),
    codeFontFamilyProvider.overrideWithValue('Fira Code'),
    activeWorkspaceIdOverride(workspaceId),
    isServerOwnerProvider.overrideWith((ref) {
      if (failOwnerRead) {
        throw StateError('Owner must not be read without a workspace');
      }
      return isOwner;
    }),
  ],
  child: MaterialApp.router(
    routerConfig: router,
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    builder: (context, child) =>
        CcTheme(data: CcThemeData.light(), child: child!),
  ),
);

Widget _opener({bool includeGlobalDestinations = false}) => Consumer(
  builder: (context, ref, _) => CcButton(
    onPressed: () => showCommandPalette(context, (dialogContext, dialogRef) {
      final settings = dialogRef
          .watch(settingsCommandSourceProvider)
          .buildItems(dialogContext, dialogRef);
      return [
        if (includeGlobalDestinations)
          ...dialogRef
              .watch(navigationCommandSourceProvider)
              .buildItems(dialogContext, dialogRef),
        ...settings,
      ];
    }),
    child: const Text('Open palette'),
  ),
);

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('Open palette'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('search and Enter open a workspace settings destination', (
    tester,
  ) async {
    final router = _router(includeGlobalDestinations: true);
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));
    await _open(tester);

    await tester.enterText(find.byType(EditableText), 'Meetings Workspace');
    await tester.pump();
    expect(find.text('Meetings'), findsOneWidget);
    expect(find.text('Workspace'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();

    expect(
      router.routeInformationProvider.value.uri.path,
      settingsMeetingsRoute('ws-1'),
    );
    expect(find.text('Meeting settings page'), findsOneWidget);
    expect(find.byType(EditableText), findsNothing);
  });

  testWidgets('owner-only SSO and MCP are absent for a non-owner', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));
    await _open(tester);

    for (final label in ['Single sign-on', 'MCP servers']) {
      await tester.enterText(find.byType(EditableText), label);
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data ?? widget.textSpan?.toPlainText()) == label,
        ),
        findsNothing,
      );
    }
    await tester.enterText(
      find.byType(EditableText),
      'Connection & status Server',
    );
    await tester.pump();
    expect(find.text('Connection & status'), findsOneWidget);
  });

  testWidgets('owner can search SSO and MCP destinations', (tester) async {
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router, isOwner: true));
    await _open(tester);

    for (final label in ['Single sign-on', 'MCP servers']) {
      await tester.enterText(find.byType(EditableText), label);
      await tester.pump();
      expect(
        find.byWidgetPredicate(
          (widget) =>
              widget is Text &&
              (widget.data ?? widget.textSpan?.toPlainText()) == label,
        ),
        findsOneWidget,
      );
      expect(find.text('Server'), findsOneWidget);
    }
  });

  testWidgets('scope distinguishes feed settings from global feed', (
    tester,
  ) async {
    final router = _router(includeGlobalDestinations: true);
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(router));
    await _open(tester);

    await tester.enterText(find.byType(EditableText), 'Newsfeed You');
    await tester.pump();
    expect(find.text('Newsfeed'), findsOneWidget);
    expect(find.text('You'), findsOneWidget);
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(
      router.routeInformationProvider.value.uri.path,
      settingsNewsfeedRoute('ws-1'),
    );
    expect(find.text('Feed settings page'), findsOneWidget);
  });

  testWidgets('without a workspace no settings are offered or owner read', (
    tester,
  ) async {
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(
      _app(router, workspaceId: null, failOwnerRead: true),
    );
    await _open(tester);
    await tester.enterText(find.byType(EditableText), 'Meetings');
    await tester.pump();
    expect(find.text('No commands match'), findsOneWidget);
  });
}
