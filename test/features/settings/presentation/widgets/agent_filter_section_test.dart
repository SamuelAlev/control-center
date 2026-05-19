import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/agent_filter_section.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
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

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });


  group('AgentSidebarItem', () {
    testWidgets('renders agent name and title', (tester) async {
      tester.view.physicalSize = const Size(300, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final agent = _testAgent('a1', 'architect', 'Software Architect');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AgentSidebarItem(
                  agent: agent,
                  isSelected: false,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('architect'), findsOneWidget);
      expect(find.text('Software Architect'), findsOneWidget);
    });

    testWidgets('shows selected styling', (tester) async {
      tester.view.physicalSize = const Size(300, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final agent = _testAgent('a1', 'architect', 'Software Architect');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AgentSidebarItem(
                  agent: agent,
                  isSelected: true,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('architect'), findsOneWidget);
    });

    testWidgets('shows running indicator when agent is running', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(300, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final agent = _testAgent('a1', 'architect', 'Software Architect');

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => true),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AgentSidebarItem(
                  agent: agent,
                  isSelected: false,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(CcSpinner), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      tester.view.physicalSize = const Size(300, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final agent = _testAgent('a1', 'architect', 'Software Architect');
      var tapped = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AgentSidebarItem(
                  agent: agent,
                  isSelected: false,
                  onTap: () => tapped = true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('architect'));
      expect(tapped, isTrue);
    });

    testWidgets('handles long agent names with ellipsis', (tester) async {
      tester.view.physicalSize = const Size(200, 100);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final agent = _testAgent(
        'a1',
        'very-long-agent-name-that-should-overflow',
        'A very long title that should also overflow the available space',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
            child: MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(
                body: AgentSidebarItem(
                  agent: agent,
                  isSelected: false,
                  onTap: () {},
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('very-long-agent-name'), findsOneWidget);
    });
  });
}
