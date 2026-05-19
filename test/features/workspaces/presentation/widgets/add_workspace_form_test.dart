import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/workspaces/presentation/widgets/add_workspace_form.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../helpers/test_database.dart';

void main() {
  late AppDatabase testDb;
  late SharedPreferences prefs;

  setUp(() async {
    testDb = createTestDatabase();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  tearDown(() async {
    await testDb.close();
  });

  testWidgets('renders workspace name field and submit button', (tester) async {
    const bool created = false;
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData.light(),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: AddWorkspaceForm(onCreated: _noop),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Workspace name'), findsOneWidget);
    expect(find.text('Add workspace'), findsOneWidget);
    expect(created, false);
  });

  testWidgets('renders cancel button when onCancel provided', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData.light(),
            child: Scaffold(
              body: SingleChildScrollView(
                child: AddWorkspaceForm(
                  onCreated: _noop,
                  onCancel: () {},
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Cancel'), findsOneWidget);
  });

  testWidgets('submit button is enabled before any form interaction',
      (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData.light(),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: AddWorkspaceForm(onCreated: _noop),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    final buttons = find.byType(CcButton);
    expect(buttons, findsAtLeastNWidgets(1));
  });

  testWidgets('renders custom submit label', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData.light(),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: AddWorkspaceForm(
                  onCreated: _noop,
                  submitLabel: 'Create',
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Create'), findsOneWidget);
  });

  testWidgets('does not render cancel when onCancel is null', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData.light(),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: AddWorkspaceForm(onCreated: _noop),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Cancel'), findsNothing);
  });

  testWidgets('workspace name field always visible', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          databaseProvider.overrideWithValue(testDb),
        ],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: CcTheme(
            data: CcThemeData.light(),
            child: const Scaffold(
              body: SingleChildScrollView(
                child: AddWorkspaceForm(onCreated: _noop),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    expect(find.text('Workspace name'), findsOneWidget);
  });
}

void _noop(String _) {}
