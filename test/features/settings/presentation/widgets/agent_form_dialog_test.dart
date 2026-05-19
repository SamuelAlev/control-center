import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/value_objects/agent_capabilities.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/sandboxing/providers/sandboxing_providers.dart';
import 'package:control_center/features/settings/domain/entities/adapter.dart';
import 'package:control_center/features/settings/presentation/widgets/agent_form_dialog.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:forui/forui.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _TestActiveWorkspaceNotifier extends ActiveWorkspaceIdNotifier {
  _TestActiveWorkspaceNotifier(this._id);
  final String? _id;
  @override
  String? build() => _id;
}

class _TestAdapterDetectionNotifier extends AdapterDetectionNotifier {
  _TestAdapterDetectionNotifier(this._adapters);
  final List<DetectedAdapter> _adapters;
  @override
  List<DetectedAdapter> build() => _adapters;
  @override
  Future<void> refresh() async {}
}

Agent _testAgent({
  String id = 'agent-1',
  String name = 'architect',
  String title = 'Software Architect',
  String? adapterId,
  String? modelId,
  String? systemPrompt,
  String? reportsTo,
  String? persona,
  bool strictMode = false,
  AgentEffort? effort,
  int? contextSize,
  List<String> skills = const [],
}) {
  return Agent(
    id: id,
    name: name,
    title: title,
    agentMdPath: '/tmp/$name.md',
    workspaceId: 'ws-1',
    skills: AgentSkills(skills),
    createdAt: DateTime(2025),
    adapterId: adapterId,
    modelId: modelId,
    systemPrompt: systemPrompt,
    reportsTo: reportsTo,
    persona: persona,
    strictMode: strictMode,
    effort: effort,
    contextSize: contextSize,
  );
}

DetectedAdapter _testDetectedAdapter(String name, String id, String path) {
  return DetectedAdapter(
    adapter: Adapter(
      id: id,
      name: name,
      description: 'Test adapter $name',
      cliName: name,
    ),
    path: path,
    status: DetectionStatus.found,
  );
}

Widget _wrapAgentForm({
  required Agent agent,
  List<String> availableSkills = const [],
  String? workspaceId,
  List<DetectedAdapter> adapters = const [],
}) {
  return ProviderScope(
    overrides: [
      activeWorkspaceIdProvider.overrideWith(
        () => _TestActiveWorkspaceNotifier(workspaceId),
      ),
      detectedAdaptersProvider.overrideWith(
        () => _TestAdapterDetectionNotifier(adapters),
      ),
      agentsProvider.overrideWith((ref) => Stream.value([])),
      defaultCapabilitiesProvider.overrideWith(
        (ref) => AgentCapabilities.safeDefault,
      ),
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: FTheme(
      data: FThemes.zinc.light.desktop,
      child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: AgentSettingsForm(
            agent: agent,
            availableSkills: availableSkills,
          ),
        ),
      ),
    ),
  );
}

late SharedPreferences prefs;
void main() {
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  group('AgentSettingsForm rendering', () {
    testWidgets('renders name field', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrapAgentForm(agent: _testAgent()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Name'), findsOneWidget);
    });

    testWidgets('renders title field', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrapAgentForm(agent: _testAgent()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Title'), findsOneWidget);
    });

    testWidgets('renders name pre-filled from agent', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrapAgentForm(
          agent: _testAgent(name: 'reviewer', title: 'Code Reviewer'),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
    });

    testWidgets('renders system prompt field', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrapAgentForm(agent: _testAgent()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('System prompt'), findsOneWidget);
    });

    testWidgets('renders adapter field with options', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final adapters = [
        _testDetectedAdapter('opencode', 'adapter-1', '/usr/local/bin'),
      ];

      await tester.pumpWidget(
        _wrapAgentForm(agent: _testAgent(), adapters: adapters),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Adapter'), findsOneWidget);
    });

    testWidgets('renders detecting adapters placeholder when empty', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrapAgentForm(agent: _testAgent()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Detecting adapters…'), findsOneWidget);
    });

    testWidgets('renders model field placeholder when no adapter', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrapAgentForm(agent: _testAgent()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Model'), findsOneWidget);
      expect(find.text('Select an adapter first'), findsOneWidget);
    });

    testWidgets('renders skills section', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrapAgentForm(agent: _testAgent()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Skills'), findsOneWidget);
    });

    testWidgets('renders skills with empty skills message', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrapAgentForm(agent: _testAgent()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.textContaining('No skills available'), findsOneWidget);
    });

    testWidgets('renders available skills as chips', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const skills = ['code-review', 'architecture', 'testing'];

      await tester.pumpWidget(
        _wrapAgentForm(agent: _testAgent(), availableSkills: skills),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('code-review'), findsOneWidget);
      expect(find.text('architecture'), findsOneWidget);
      expect(find.text('testing'), findsOneWidget);
    });

    testWidgets('renders reportsTo field', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrapAgentForm(agent: _testAgent()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Reports to'), findsOneWidget);
    });

    testWidgets('renders persona field', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrapAgentForm(agent: _testAgent()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Persona'), findsOneWidget);
    });

    testWidgets('renders strict identity check switch', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrapAgentForm(agent: _testAgent()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Strict identity check'), findsOneWidget);
    });

    testWidgets('renders reasoning effort field', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrapAgentForm(agent: _testAgent()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Reasoning effort'), findsOneWidget);
    });

    testWidgets('renders context window size field', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrapAgentForm(agent: _testAgent()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Context window size'), findsOneWidget);
    });

    testWidgets('renders save button', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrapAgentForm(agent: _testAgent()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Save changes'), findsOneWidget);
    });

    testWidgets('renders pre-filled reportsTo from agent', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrapAgentForm(agent: _testAgent(reportsTo: 'ceo-agent')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Reports to'), findsOneWidget);
    });

    testWidgets('renders pre-filled persona from agent', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrapAgentForm(agent: _testAgent(persona: 'I am a helpful assistant')),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Persona'), findsOneWidget);
    });

    testWidgets('renders context size presets', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrapAgentForm(agent: _testAgent()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('200k'), findsOneWidget);
      expect(find.text('500k'), findsOneWidget);
      expect(find.text('1000k'), findsOneWidget);
    });
  });

  group('AgentSettingsForm updates on agent change', () {
    testWidgets('updates fields when agent changes', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final agent1 = _testAgent(id: 'a1', name: 'architect', title: 'Architect');
      const skills = ['code-review'];

      await tester.pumpWidget(
        _wrapAgentForm(agent: agent1, availableSkills: skills),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Name'), findsOneWidget);

      final agent2 = _testAgent(
        id: 'a2',
        name: 'reviewer',
        title: 'Code Reviewer',
      );

      await tester.pumpWidget(
        _wrapAgentForm(agent: agent2, availableSkills: skills),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Name'), findsOneWidget);
    });
  });

  group('AgentSettingsForm with skills context', () {
    testWidgets('renders with pre-selected skills chips', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const skills = ['code-review', 'architecture'];

      await tester.pumpWidget(
        _wrapAgentForm(
          agent: _testAgent(skills: ['code-review']),
          availableSkills: skills,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('code-review'), findsOneWidget);
      expect(find.text('architecture'), findsOneWidget);
    });

    testWidgets('renders with strict mode on', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrapAgentForm(agent: _testAgent(strictMode: true)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Strict identity check'), findsOneWidget);
    });

    testWidgets('renders with effort pre-selected', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrapAgentForm(agent: _testAgent(effort: AgentEffort.high)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Reasoning effort'), findsOneWidget);
    });

    testWidgets('renders with context size pre-set', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrapAgentForm(agent: _testAgent(contextSize: 128000)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Context window size'), findsOneWidget);
    });
  });

  group('AgentSettingsForm error state on model loading', () {
    testWidgets('shows model field with adapter selected', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final adapters = [
        _testDetectedAdapter('opencode', 'adapter-1', '/usr/local/bin'),
      ];

      await tester.pumpWidget(
        _wrapAgentForm(
          agent: _testAgent(adapterId: 'adapter-1'),
          adapters: adapters,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Model'), findsOneWidget);
    });
  });

  group('AgentSettingsForm adapter selection behavior', () {
    testWidgets('shows adapter name in select when adapter assigned', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final adapters = [
        _testDetectedAdapter('OpenCode', 'adapter-1', '/usr/local/bin'),
      ];

      await tester.pumpWidget(
        _wrapAgentForm(
          agent: _testAgent(adapterId: 'adapter-1'),
          adapters: adapters,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Adapter'), findsOneWidget);
    });

    testWidgets('model field shows loading when adapter selected without models', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final adapters = [
        _testDetectedAdapter('OpenCode', 'adapter-2', '/usr/local/bin'),
      ];

      await tester.pumpWidget(
        _wrapAgentForm(
          agent: _testAgent(adapterId: 'adapter-2'),
          adapters: adapters,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Model'), findsOneWidget);
    });
  });

  group('AgentSettingsForm with skills pre-selected', () {
    testWidgets('shows skills as already selected chips', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      const skills = ['code-review', 'architecture'];

      await tester.pumpWidget(
        _wrapAgentForm(
          agent: _testAgent(skills: ['code-review', 'architecture']),
          availableSkills: skills,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('code-review'), findsOneWidget);
      expect(find.text('architecture'), findsOneWidget);
    });
  });

  group('AgentSettingsForm field labels', () {
    testWidgets('all field labels render correctly', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrapAgentForm(agent: _testAgent()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Name'), findsOneWidget);
      expect(find.text('Title'), findsOneWidget);
      expect(find.text('System prompt'), findsOneWidget);
      expect(find.text('Adapter'), findsOneWidget);
      expect(find.text('Model'), findsOneWidget);
      expect(find.text('Skills'), findsOneWidget);
      expect(find.text('Reports to'), findsOneWidget);
      expect(find.text('Persona'), findsOneWidget);
      expect(find.text('Strict identity check'), findsOneWidget);
      expect(find.text('Reasoning effort'), findsOneWidget);
      expect(find.text('Context window size'), findsOneWidget);
    });
  });

  group('AgentSettingsForm strict mode', () {
    testWidgets('toggle renders in off state by default', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrapAgentForm(agent: _testAgent()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(FSwitch), findsNWidgets(2));
    });

    testWidgets('toggle renders in on state when agent has strict mode', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        _wrapAgentForm(agent: _testAgent(strictMode: true)),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(FSwitch), findsNWidgets(2));
    });
  });

  group('AgentSettingsForm reasoning effort', () {
    testWidgets('renders reasoning effort select with options', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrapAgentForm(agent: _testAgent(effort: AgentEffort.medium)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Reasoning effort'), findsOneWidget);
    });
  });

  group('AgentSettingsForm context size presets', () {
    testWidgets('context size field has input field', (tester) async {
      tester.view.physicalSize = const Size(800, 900);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(_wrapAgentForm(agent: _testAgent(contextSize: 64000)));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Context window size'), findsOneWidget);
      expect(find.text('200k'), findsOneWidget);
      expect(find.text('500k'), findsOneWidget);
      expect(find.text('1000k'), findsOneWidget);
    });
  });
}
