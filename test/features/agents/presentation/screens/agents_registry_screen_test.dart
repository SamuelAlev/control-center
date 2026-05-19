import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/agents/presentation/screens/agents_registry_screen.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:drift/drift.dart' as drift;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';

void main() {
  late AppDatabase testDb;

  setUp(() {
    testDb = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await testDb.close();
  });

  Widget host() => ProviderScope(
        overrides: [databaseProvider.overrideWithValue(testDb)],
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: ThemeData(extensions: [DesignSystemTokens.light()]),
          home: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const Scaffold(body: AgentsRegistryScreen()),
          ),
        ),
      );

  Future<void> seed(
    String id,
    String name,
    String title, {
    String? reportsTo,
    String skills = 'testing',
  }) {
    return testDb.agentDao.upsert(
      AgentsTableCompanion.insert(
        id: id,
        name: name,
        title: title,
        agentMdPath: '.kilo/agent/$name.md',
        skills: skills,
        reportsTo: reportsTo == null
            ? const drift.Value.absent()
            : drift.Value(reportsTo),
        persona: const drift.Value.absent(),
        workspaceId: 'ws-test',
      ),
    );
  }

  testWidgets('renders empty state with both actions', (tester) async {
    await tester.pumpWidget(host());
    await tester.pump();

    expect(find.text('No agents discovered'), findsOneWidget);
    expect(find.text('Discover agents'), findsWidgets);
    expect(find.text('Agents'), findsAtLeast(1));

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('renders roster with count, names, titles and skill chips',
      (tester) async {
    await seed('agent-1', 'architect', 'Software Architect',
        skills: 'architecture, design');
    await seed('agent-2', 'reviewer', 'Code Reviewer', skills: 'review');

    await tester.pumpWidget(host());
    await tester.pump();

    expect(find.text('2 agents'), findsOneWidget);
    expect(find.text('architect'), findsAtLeast(1));
    expect(find.text('reviewer'), findsOneWidget);
    expect(find.text('Software Architect'), findsOneWidget);
    // Quiet skill chips render the skill names.
    expect(find.text('architecture'), findsOneWidget);
    expect(find.text('design'), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('filtering narrows the roster', (tester) async {
    await seed('agent-1', 'architect', 'Software Architect');
    await seed('agent-2', 'reviewer', 'Code Reviewer');

    await tester.pumpWidget(host());
    await tester.pump();

    await tester.enterText(find.byType(TextField).first, 'review');
    await tester.pump();

    expect(find.text('reviewer'), findsOneWidget);
    expect(find.text('architect'), findsNothing);

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('selecting an agent opens the detail panel with resolved manager',
      (tester) async {
    await seed('senior', 'senior-dev', 'Senior Developer');
    await seed('agent-report', 'junior', 'Junior Developer',
        reportsTo: 'senior');

    await tester.pumpWidget(host());
    await tester.pump();

    await tester.tap(find.text('junior'));
    await tester.pump();

    // Detail panel shows the reports-to row, resolved to the manager's name.
    expect(find.text('Reports to'), findsOneWidget);
    expect(find.text('senior-dev'), findsAtLeast(1));
    // The edit / delete actions are present in the panel.
    expect(find.text('Edit'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });

  testWidgets('renders action buttons', (tester) async {
    await seed('agent-btn', 'tester', 'QA Engineer');

    await tester.pumpWidget(host());
    await tester.pump();

    expect(find.text('Discover'), findsOneWidget);
    expect(find.text('Add agent'), findsAtLeast(1));

    await tester.pumpWidget(Container());
    await tester.pumpAndSettle();
  });
}
