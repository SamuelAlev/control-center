import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/agent_list_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';

Agent _testAgent(String id, String name, String title) {
  return Agent(
    id: id,
    name: name,
    title: title,
    agentMdPath: '/tmp/$name.md',
    workspaceId: 'ws-1',
    skills: AgentSkills([]),
    createdAt: DateTime(2025),
  );
}

late SharedPreferences prefs;

void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('AgentListSection', () {
    testWidgets('renders new agent button', (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        FTheme(
          data: FThemes.zinc.light.desktop,
          child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AgentListSection(
                agents: const [],
                selectedAgentId: null,
                filterController: TextEditingController(),
                onAgentSelected: (_) {},
                onCreateAgent: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('New agent'), findsOneWidget);
    });

    testWidgets('renders filter text field', (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        FTheme(
          data: FThemes.zinc.light.desktop,
          child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AgentListSection(
                agents: const [],
                selectedAgentId: null,
                filterController: TextEditingController(),
                onAgentSelected: (_) {},
                onCreateAgent: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(FTextField), findsOneWidget);
    });

    testWidgets('renders agent list items', (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final agents = [
        _testAgent('a1', 'architect', 'Software Architect'),
        _testAgent('a2', 'reviewer', 'Code Reviewer'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentIsRunningProvider('a1').overrideWith((ref) => false),
            agentIsRunningProvider('a2').overrideWith((ref) => false),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AgentListSection(
                  agents: agents,
                  selectedAgentId: null,
                  filterController: TextEditingController(),
                  onAgentSelected: (_) {},
                  onCreateAgent: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('architect'), findsOneWidget);
      expect(find.text('reviewer'), findsOneWidget);
    });

    testWidgets('calls onAgentSelected when agent tapped', (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final agents = [
        _testAgent('a1', 'architect', 'Software Architect'),
      ];
      String? selectedId;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentIsRunningProvider('a1').overrideWith((ref) => false),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AgentListSection(
                  agents: agents,
                  selectedAgentId: null,
                  filterController: TextEditingController(),
                  onAgentSelected: (id) => selectedId = id,
                  onCreateAgent: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('architect'));
      expect(selectedId, 'a1');
    });

    testWidgets('calls onCreateAgent when new agent button pressed', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      var created = false;

      await tester.pumpWidget(
        FTheme(
          data: FThemes.zinc.light.desktop,
          child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(
              body: AgentListSection(
                agents: const [],
                selectedAgentId: null,
                filterController: TextEditingController(),
                onAgentSelected: (_) {},
                onCreateAgent: () => created = true,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('New agent'));
      expect(created, isTrue);
    });

    testWidgets('highlights selected agent', (tester) async {
      tester.view.physicalSize = const Size(400, 600);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final agents = [
        _testAgent('a1', 'architect', 'Software Architect'),
        _testAgent('a2', 'reviewer', 'Code Reviewer'),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentIsRunningProvider('a1').overrideWith((ref) => false),
            agentIsRunningProvider('a2').overrideWith((ref) => false),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AgentListSection(
                  agents: agents,
                  selectedAgentId: 'a1',
                  filterController: TextEditingController(),
                  onAgentSelected: (_) {},
                  onCreateAgent: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('architect'), findsOneWidget);
      expect(find.text('reviewer'), findsOneWidget);
    });
  });
}
