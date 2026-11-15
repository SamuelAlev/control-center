import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/workspaces/presentation/widgets/workspace_read_only_banner.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_locales.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/router/routes.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:material_ui/material_ui.dart';

/// The shell's notice that the active workspace takes no writes, under a real
/// router so its link to Backups and its "hidden on Backups" rule run as in
/// the shell.
void main() {
  final now = DateTime.utc(2026, 11, 12);

  Workspace workspace(WorkspaceStorageState state) => Workspace(
    id: 'ws-1',
    name: 'Payments',
    createdAt: now,
    updatedAt: now,
    storageState: state,
  );

  Future<GoRouter> pump(
    WidgetTester tester, {
    required Workspace? active,
    bool owner = false,
    String initial = '/workspaces/ws-1/inbox',
    TextDirection textDirection = TextDirection.ltr,
  }) async {
    Widget page(GoRouterState state) => Directionality(
      textDirection: textDirection,
      child: Column(
        children: [
          const WorkspaceReadOnlyBanner(),
          Text(state.matchedLocation),
        ],
      ),
    );
    final router = GoRouter(
      initialLocation: initial,
      routes: [
        GoRoute(path: inboxRoute('ws-1'), builder: (_, s) => page(s)),
        GoRoute(path: settingsBackupRoute('ws-1'), builder: (_, s) => page(s)),
      ],
    );
    addTearDown(router.dispose);
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          activeWorkspaceProvider.overrideWith((ref) => active),
          isServerOwnerProvider.overrideWithValue(owner),
        ],
        child: MaterialApp.router(
          routerConfig: router,
          localizationsDelegates: const [
            appLocalizationsDelegate,
            ...GlobalMaterialLocalizations.delegates,
          ],
          supportedLocales: kSupportedAppLocales,
          locale: const Locale('en'),
          builder: (context, child) => CcTheme(
            data: CcThemeData.light(),
            child: child ?? const SizedBox.shrink(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets('a writable workspace shows nothing', (tester) async {
    await pump(tester, active: workspace(WorkspaceStorageState.ok));

    expect(find.text('This workspace is read-only'), findsNothing);
  });

  testWidgets('a member is told who can fix it, with no link', (tester) async {
    await pump(tester, active: workspace(WorkspaceStorageState.readOnly));

    expect(find.text('This workspace is read-only'), findsOneWidget);
    expect(
      find.textContaining('The server owner can restore it'),
      findsOneWidget,
    );
    expect(find.text('Open backups'), findsNothing);
  });

  testWidgets('the server owner is taken to Backups, where it hides', (
    tester,
  ) async {
    await pump(
      tester,
      active: workspace(WorkspaceStorageState.readOnly),
      owner: true,
    );

    expect(
      find.textContaining('Restore it from a backup to make it writable'),
      findsOneWidget,
    );
    await tester.tap(find.text('Open backups'));
    await tester.pumpAndSettle();

    expect(find.text(settingsBackupRoute('ws-1')), findsOneWidget);
    expect(find.text('This workspace is read-only'), findsNothing);
  });

  testWidgets('dismissing hides it for the session', (tester) async {
    await pump(tester, active: workspace(WorkspaceStorageState.readOnly));

    await tester.tap(find.byIcon(CcIcons.x));
    await tester.pumpAndSettle();

    expect(find.text('This workspace is read-only'), findsNothing);
  });

  testWidgets('mirrors under a right-to-left locale', (tester) async {
    await pump(
      tester,
      active: workspace(WorkspaceStorageState.readOnly),
      owner: true,
      textDirection: TextDirection.rtl,
    );

    final title = tester.getRect(find.text('This workspace is read-only'));
    final action = tester.getRect(find.text('Open backups'));
    expect(action.right, lessThan(title.left));
  });
}
