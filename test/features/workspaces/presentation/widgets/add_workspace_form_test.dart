import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/workspaces/presentation/widgets/add_workspace_form.dart';
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

  testWidgets('renders primary pick folder button', (tester) async {
    bool created = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs), databaseProvider.overrideWithValue(testDb)],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: Scaffold(
              body: SingleChildScrollView(
                child: AddWorkspaceForm(onCreated: (_) => created = true),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Choose repository folder'), findsOneWidget);
    expect(find.text('Add Workspace'), findsOneWidget);
    expect(created, false);
  });

  testWidgets('renders cancel button when onCancel provided', (tester) async {
    bool cancelled = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs), databaseProvider.overrideWithValue(testDb)],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: Scaffold(
              body: SingleChildScrollView(
                child: AddWorkspaceForm(
                  onCreated: (_) {},
                  onCancel: () => cancelled = true,
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Cancel'), findsOneWidget);

    await tester.tap(find.text('Cancel'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(cancelled, true);
  });

  testWidgets('submit button is disabled before folder picked', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs), databaseProvider.overrideWithValue(testDb)],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: Scaffold(
              body: SingleChildScrollView(
                child: AddWorkspaceForm(onCreated: (_) {}),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    final addButton = find.widgetWithText(FButton, 'Add Workspace');
    final button = tester.widget<FButton>(addButton);
    expect(button.onPress, isNull);
  });

  testWidgets('renders custom submit label', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs), databaseProvider.overrideWithValue(testDb)],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: Scaffold(
              body: SingleChildScrollView(
                child: AddWorkspaceForm(
                  onCreated: (_) {},
                  submitLabel: 'Finish setup',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Finish setup'), findsOneWidget);
  });

  testWidgets('does not render cancel when onCancel is null', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs), databaseProvider.overrideWithValue(testDb)],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: Scaffold(
              body: SingleChildScrollView(
                child: AddWorkspaceForm(onCreated: (_) {}),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('repo summary and name field hidden before folder picked', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [sharedPreferencesProvider.overrideWithValue(prefs), databaseProvider.overrideWithValue(testDb)],
        child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: Scaffold(
              body: SingleChildScrollView(
                child: AddWorkspaceForm(onCreated: (_) {}),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Workspace name'), findsNothing);
  });
}
