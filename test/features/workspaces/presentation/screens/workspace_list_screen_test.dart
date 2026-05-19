import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/workspaces/presentation/screens/workspace_list_screen.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late AppDatabase testDb;
  late SharedPreferences prefs;

  setUp(() async {
    testDb = AppDatabase.forTesting(NativeDatabase.memory());
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await testDb.close();
  });

  testWidgets('renders empty state when no workspaces', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const Scaffold(body: WorkspaceListScreen()),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Workspaces'), findsOneWidget);
    expect(find.text('No workspaces yet'), findsOneWidget);
    expect(find.text('Add Workspace'), findsWidgets);

    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('renders workspace list with data', (tester) async {
    await testDb.workspaceDao.upsertWorkspace(
      WorkspacesTableCompanion.insert(
        id: 'ws-1',
        name: 'Frontend App',
      ),
    );
    await testDb.workspaceDao.upsertWorkspace(
      WorkspacesTableCompanion.insert(
        id: 'ws-2',
        name: 'Backend API',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const Scaffold(body: WorkspaceListScreen()),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Frontend App'), findsOneWidget);
    expect(find.text('Backend API'), findsOneWidget);
    expect(find.text('myorg/frontend'), findsOneWidget);
    expect(find.text('myorg/backend'), findsOneWidget);
    expect(find.text('Active'), findsNothing);
    expect(find.text('Idle'), findsNothing);

    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 50));
  });

  testWidgets('renders workspace with error status', (tester) async {
    await testDb.workspaceDao.upsertWorkspace(
      WorkspacesTableCompanion.insert(
        id: 'ws-err',
        name: 'Broken Repo',
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(testDb),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const Scaffold(body: WorkspaceListScreen()),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Broken Repo'), findsOneWidget);
    expect(find.text('Open'), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pump(const Duration(milliseconds: 50));
  });
}
