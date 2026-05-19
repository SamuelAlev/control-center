import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/workspaces/presentation/screens/workspace_detail_screen.dart';
import 'package:control_center/features/workspaces/providers/workspace_panel_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/workspace_panel.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase testDb;
  late SharedPreferences prefs;

  const testWorkspaceId = 'ws-detail-1';

  final testPanel2 = WorkspacePanel(
    label: 'Memory',
    icon: LucideIcons.brain,
    builder: (_) => const Center(child: Text('Memory Panel')),
  );

  setUp(() async {
    testDb = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await testDb.close();
  });

  testWidgets('renders workspace not found state', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
          memoryWorkspacePanelProvider.overrideWithValue(testPanel2),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const Scaffold(
              body: WorkspaceDetailScreen(workspaceId: 'nonexistent'),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Workspace not found'), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('renders workspace header and breadcrumb', (tester) async {
    await testDb.workspaceDao.upsertWorkspace(
      WorkspacesTableCompanion.insert(id: testWorkspaceId, name: 'Detail Test'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
          memoryWorkspacePanelProvider.overrideWithValue(testPanel2),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const Scaffold(
              body: WorkspaceDetailScreen(workspaceId: testWorkspaceId),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Workspace: Detail Test'), findsOneWidget);
    expect(find.text('Workspaces'), findsOneWidget);
    expect(find.text('feature/test'), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('renders tab bar with panel labels', (tester) async {
    await testDb.workspaceDao.upsertWorkspace(
      WorkspacesTableCompanion.insert(id: testWorkspaceId, name: 'Tab Test'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
          memoryWorkspacePanelProvider.overrideWithValue(testPanel2),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const Scaffold(
              body: WorkspaceDetailScreen(workspaceId: testWorkspaceId),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Tasks Panel'), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('renders action buttons in header', (tester) async {
    await testDb.workspaceDao.upsertWorkspace(
      WorkspacesTableCompanion.insert(id: testWorkspaceId, name: 'Action Test'),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
          memoryWorkspacePanelProvider.overrideWithValue(testPanel2),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const Scaffold(
              body: WorkspaceDetailScreen(workspaceId: testWorkspaceId),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Live Sync'), findsOneWidget);
    expect(find.text('Live Diff'), findsOneWidget);
    expect(find.text('Forks'), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
