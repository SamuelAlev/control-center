import 'package:control_center/core/domain/entities/repo.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/shell/presentation/widgets/title_bar_workspace_chip.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/workspace_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';

late SharedPreferences prefs;

Widget _wrap(Widget child) {
  return ProviderScope(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
    child: FTheme(
      data: FThemes.zinc.light.desktop,
      child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, home: Scaffold(body: child)),
    ),
  );
}

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('WorkspaceAvatar', () {
    testWidgets('renders default icon when no logo path', (tester) async {
      await tester.pumpWidget(
        _wrap(const WorkspaceAvatar(logoPath: null, size: 32)),
      );
      await tester.pump();

      expect(find.byType(WorkspaceAvatar), findsOneWidget);
    });

    testWidgets('renders default icon for empty logo path', (tester) async {
      await tester.pumpWidget(
        _wrap(const WorkspaceAvatar(logoPath: '', size: 32)),
      );
      await tester.pump();

      expect(find.byType(WorkspaceAvatar), findsOneWidget);
    });
  });

  group('TitleBarWorkspaceChip', () {
    testWidgets('renders "No workspace" placeholder', (tester) async {
      tester.view.physicalSize = const Size(400, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider
                .overrideWith((ref) => Stream.value(const <Workspace>[])),
            activeWorkspaceProvider.overrideWith((ref) => null),
            reposForWorkspaceProvider
                .overrideWith((ref, id) => const Stream<List<Repo>>.empty()),
          ],
          child: _wrap(const TitleBarWorkspaceChip()),
        ),
      );
      await tester.pump();

      expect(find.text('No workspace'), findsOneWidget);
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
            sharedPreferencesProvider.overrideWithValue(prefs),
            workspacesProvider.overrideWith((ref) => Stream.value([workspace])),
            activeWorkspaceProvider.overrideWith((ref) => workspace),
            reposForWorkspaceProvider
                .overrideWith((ref, id) => const Stream<List<Repo>>.empty()),
          ],
          child: _wrap(const TitleBarWorkspaceChip()),
        ),
      );
      await tester.pump();

      expect(find.text('My Project'), findsOneWidget);
    });
  });

}
