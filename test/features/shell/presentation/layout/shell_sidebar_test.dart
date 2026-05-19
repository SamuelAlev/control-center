import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/shell/presentation/widgets/title_bar_workspace_chip.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/workspace_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

late AppPreferences prefs;

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [appPreferencesProvider.overrideWithValue(prefs)],
    child: CcTheme(
      data: CcThemeData.light(),
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      ),
    ),
  );
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    prefs = AppPreferences.inMemory();
  });

  group('WorkspaceAvatar', () {
    testWidgets('renders default icon when no logo path', (tester) async {
      await tester.pumpWidget(_wrap(const WorkspaceAvatar(size: 32)));
      await tester.pump();

      expect(find.byType(WorkspaceAvatar), findsOneWidget);
    });

    testWidgets('renders default icon for empty logo path', (tester) async {
      await tester.pumpWidget(
        _wrap(const WorkspaceAvatar(hasLogo: false, size: 32)),
      );
      await tester.pump();

      expect(find.byType(WorkspaceAvatar), findsOneWidget);
    });
  });

  group('TitleBarWorkspaceChip', () {
    testWidgets('renders "Select a workspace" placeholder', (tester) async {
      tester.view.physicalSize = const Size(400, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith(
              (ref) => Stream.value(const <Workspace>[]),
            ),
            activeWorkspaceProvider.overrideWith((ref) => null),
            reposForWorkspaceProvider.overrideWith(
              (ref, id) => const Stream<List<Repo>>.empty(),
            ),
          ],
          child: _wrap(const TitleBarWorkspaceChip()),
        ),
      );
      await tester.pump();

      expect(find.text('Select a workspace'), findsOneWidget);
    });

    testWidgets('renders active workspace name', (tester) async {
      tester.view.physicalSize = const Size(400, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final workspace = Workspace(
        id: 'ws-1',
        name: 'My Project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value([workspace])),
            activeWorkspaceProvider.overrideWith((ref) => workspace),
            reposForWorkspaceProvider.overrideWith(
              (ref, id) => const Stream<List<Repo>>.empty(),
            ),
          ],
          child: _wrap(const TitleBarWorkspaceChip()),
        ),
      );
      await tester.pump();

      expect(find.text('My Project'), findsOneWidget);
    });

    testWidgets('active tile is a neutral wash and rows sit flush', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final tokens = DesignSystemTokens.light();
      final workspace = Workspace(
        id: 'ws-1',
        name: 'My Project',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value([workspace])),
            activeWorkspaceProvider.overrideWith((ref) => workspace),
            reposForWorkspaceProvider.overrideWith(
              (ref, id) => const Stream<List<Repo>>.empty(),
            ),
          ],
          child: _wrap(const TitleBarWorkspaceChip()),
        ),
      );
      await tester.pump();

      // Open the switcher popover.
      await tester.tap(find.text('My Project'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      final tileFinder = find.byKey(const ValueKey('ws-1'));
      expect(tileFinder, findsOneWidget);

      // The active workspace reads as the neutral hover wash (Carbon's
      // layer-selected)…
      expect(
        find.ancestor(
          of: tileFinder,
          matching: find.byWidgetPredicate(
            (w) =>
                w is Container &&
                w.decoration is BoxDecoration &&
                (w.decoration! as BoxDecoration).color == tokens.hover,
          ),
        ),
        findsOneWidget,
      );
      // …and nothing in the popover carries the accent selection tint.
      expect(
        find.byWidgetPredicate(
          (w) =>
              w is Container &&
              w.decoration is BoxDecoration &&
              (w.decoration! as BoxDecoration).color == tokens.accentSoft,
        ),
        findsNothing,
      );

      // Carbon-style menu: rows sit flush against the panel — no top or
      // bottom gap between the panel edge and the first/last row.
      final panelFinder = find.byWidgetPredicate(
        (w) => w is ClipRRect && w.borderRadius == AppRadii.brLg,
      );
      expect(panelFinder, findsOneWidget);
      expect(
        tester.getTopLeft(tileFinder).dy,
        tester.getTopLeft(panelFinder).dy,
      );
      expect(
        tester.getBottomLeft(find.text('Manage workspaces')).dy,
        lessThanOrEqualTo(tester.getBottomLeft(panelFinder).dy),
      );
    });
  });
}
