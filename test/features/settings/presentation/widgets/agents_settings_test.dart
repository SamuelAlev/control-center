import 'dart:async';

import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/core/domain/value_objects/agent_skills.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/settings/domain/entities/adapter.dart';
import 'package:control_center/features/settings/presentation/widgets/agents_settings.dart';
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

List _agentContentOverrides(SharedPreferences prefs, List<Agent> agents, {String? workspaceId}) {
  return [
    agentsProvider.overrideWith((ref) => Stream.value(agents)),
    activeWorkspaceIdProvider.overrideWith(
      () => _TestActiveWorkspaceNotifier(workspaceId),
    ),
    detectedAdaptersProvider.overrideWith(
      () => _TestAdapterDetectionNotifier(const []),
    ),
    sharedPreferencesProvider.overrideWithValue(prefs),
  ];
}

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

AgentRunLog _testLog({
  String id = 'log-1',
  String agentId = 'agent-1',
  RunStatus status = RunStatus.completed,
  DateTime? startedAt,
  DateTime? completedAt,
  int? pid,
  String? adapter,
}) {
  final start = startedAt ?? DateTime(2025, 1, 1, 10, 0);
  return AgentRunLog(
    id: id,
    agentId: agentId,
    startedAt: start,
    completedAt: completedAt ?? start.add(const Duration(minutes: 5)),
    status: status,
    pid: pid,
    adapter: adapter,
  );
}

void main() {
  late SharedPreferences prefs;
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('renders loading state', (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentsProvider.overrideWith(
            (ref) => const Stream<List<Agent>>.empty(),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AgentsSettings()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.byType(FCircularProgress), findsOneWidget);
  });

  testWidgets('renders error state on stream error', (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentsProvider.overrideWith(
            (ref) => Stream<List<Agent>>.error(
              Exception('Connection refused'),
            ),
          ),
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier(null),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AgentsSettings()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 2));

    expect(find.textContaining('Failed to load agents'), findsOneWidget);
  });

  testWidgets('renders empty state with no agents', (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentsProvider.overrideWith(
            (ref) => Stream.value(const <Agent>[]),
          ),
          activeWorkspaceIdProvider.overrideWith(
            () => _TestActiveWorkspaceNotifier(null),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AgentsSettings()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Agents'), findsOneWidget);
    expect(find.text('No agents'), findsOneWidget);
    expect(find.textContaining('Create your first agent'), findsOneWidget);
  });

  testWidgets('renders agent list with agents', (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
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
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider('a1').overrideWith((ref) => false),
          agentIsRunningProvider('a2').overrideWith((ref) => false),
          agentRunLogsProvider('a1').overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
        ],
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AgentsSettings()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('architect'), findsAtLeast(1));
    expect(find.text('reviewer'), findsOneWidget);
  });

  testWidgets('shows agent settings form tabs', (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final agents = [
      _testAgent('a1', 'architect', 'Software Architect'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider('a1').overrideWith((ref) => false),
          agentRunLogsProvider('a1').overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
        ],
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AgentsSettings()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Settings'), findsOneWidget);
    expect(find.text('Logs'), findsOneWidget);
  });

  testWidgets('shows agent logs tab empty state', (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final agents = [
      _testAgent('a1', 'architect', 'Software Architect'),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider('a1').overrideWith((ref) => false),
          agentRunLogsProvider('a1').overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
        ],
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AgentsSettings()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.textContaining('No execution logs'), findsOneWidget);
  });

  testWidgets('shows agent logs with entries', (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final agents = [_testAgent('a1', 'architect', 'Software Architect')];
    final logs = [_testLog(id: 'log-1', agentId: 'a1')];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider('a1').overrideWith((ref) => false),
          agentRunLogsProvider('a1').overrideWith(
            (ref) => Stream.value(logs),
          ),
        ],
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AgentsSettings()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('COMPLETED'), findsOneWidget);
  });

  testWidgets('shows log with pid field', (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final agents = [_testAgent('a1', 'architect', 'Software Architect')];
    final log = AgentRunLog(
      id: 'log-pid',
      agentId: 'a1',
      startedAt: DateTime(2025, 1, 1),
      completedAt: DateTime(2025, 1, 1, 10, 5),
      status: RunStatus.completed,
      pid: 12345,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider('a1').overrideWith((ref) => false),
          agentRunLogsProvider('a1').overrideWith(
            (ref) => Stream.value([log]),
          ),
        ],
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AgentsSettings()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.textContaining('12345'), findsOneWidget);
  });

  testWidgets('completed log shows pid and adapter', (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final agents = [_testAgent('a1', 'architect', 'Software Architect')];
    final log = AgentRunLog(
      id: 'log-complete',
      agentId: 'a1',
      startedAt: DateTime(2025, 1, 1),
      completedAt: DateTime(2025, 1, 1, 10, 5),
      status: RunStatus.completed,
      pid: 99999,
      adapter: 'opencode',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider('a1').overrideWith((ref) => false),
          agentRunLogsProvider('a1').overrideWith(
            (ref) => Stream.value([log]),
          ),
        ],
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AgentsSettings()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.textContaining('99999'), findsOneWidget);
    expect(find.textContaining('opencode'), findsOneWidget);
  });

  testWidgets('shows error log entry', (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final agents = [_testAgent('a1', 'architect', 'Software Architect')];
    final log = AgentRunLog(
      id: 'log-error',
      agentId: 'a1',
      startedAt: DateTime(2025, 1, 1),
      completedAt: DateTime(2025, 1, 1, 10, 5),
      status: RunStatus.error,
      adapter: 'claude',
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider('a1').overrideWith((ref) => false),
          agentRunLogsProvider('a1').overrideWith(
            (ref) => Stream.value([log]),
          ),
        ],
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AgentsSettings()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.text('ERROR'), findsOneWidget);
    expect(find.textContaining('claude'), findsOneWidget);
  });

  testWidgets('log entry shows duration text', (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final agents = [_testAgent('a1', 'architect', 'Software Architect')];
    final logs = [
      _testLog(
        id: 'log-1',
        agentId: 'a1',
        startedAt: DateTime(2025, 1, 1, 10, 0),
        completedAt: DateTime(2025, 1, 1, 10, 5),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider('a1').overrideWith((ref) => false),
          agentRunLogsProvider('a1').overrideWith(
            (ref) => Stream.value(logs),
          ),
        ],
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AgentsSettings()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.textContaining('5m'), findsOneWidget);
  });

  testWidgets('running log has duration running indicator', (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final agents = [_testAgent('a1', 'architect', 'Software Architect')];
    final log = AgentRunLog(
      id: 'log-running',
      agentId: 'a1',
      startedAt: DateTime(2025, 1, 1),
      status: RunStatus.running,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider('a1').overrideWith((ref) => true),
          agentRunLogsProvider('a1').overrideWith(
            (ref) => Stream.value([log]),
          ),
        ],
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AgentsSettings()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Logs'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(FCircularProgress), findsWidgets);
  });

  testWidgets('log entry shows hours in duration', (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final agents = [_testAgent('a1', 'architect', 'Software Architect')];
    final logs = [
      _testLog(
        id: 'log-long',
        agentId: 'a1',
        startedAt: DateTime(2025, 1, 1, 10, 0),
        completedAt: DateTime(2025, 1, 1, 12, 30),
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider('a1').overrideWith((ref) => false),
          agentRunLogsProvider('a1').overrideWith(
            (ref) => Stream.value(logs),
          ),
        ],
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AgentsSettings()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.textContaining('2h'), findsOneWidget);
  });

  testWidgets('AgentsSettings header shows agent info', (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final agents = [_testAgent('a1', 'architect', 'Software Architect')];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider('a1').overrideWith((ref) => false),
          agentRunLogsProvider('a1').overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
        ],
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AgentsSettings()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.textContaining('Software Architect'), findsAtLeast(1));
  });

  testWidgets('AgentsSettings widget accepts key', (tester) async {
    const widget = AgentsSettings(key: ValueKey('agents'));
    expect(widget.key, const ValueKey('agents'));
  });

  testWidgets('log entry shows started date', (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final agents = [_testAgent('a1', 'architect', 'Software Architect')];
    final logs = [_testLog(id: 'log-1', agentId: 'a1')];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider('a1').overrideWith((ref) => false),
          agentRunLogsProvider('a1').overrideWith(
            (ref) => Stream.value(logs),
          ),
        ],
        child: FTheme(
          data: FThemes.zinc.light.desktop,
          child: const MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
            home: Scaffold(body: AgentsSettings()),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Logs'));
    await tester.pumpAndSettle(const Duration(seconds: 5));

    expect(find.textContaining('Started:'), findsOneWidget);
    expect(find.textContaining('Completed:'), findsOneWidget);
  });

  group('AgentsSettings filter section', () {
    testWidgets('filter section renders with agents', (tester) async {
      tester.view.physicalSize = const Size(1000, 700);
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
            ..._agentContentOverrides(prefs, agents),
            agentIsRunningProvider('a1').overrideWith((ref) => false),
            agentIsRunningProvider('a2').overrideWith((ref) => false),
            agentRunLogsProvider('a1').overrideWith(
              (ref) => Stream.value(const <AgentRunLog>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: AgentsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('architect'), findsAtLeast(1));
      expect(find.text('reviewer'), findsOneWidget);
    });
  });

  group('AgentsSettings log edge cases', () {
    testWidgets('log with seconds duration shows seconds', (tester) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final agents = [_testAgent('a1', 'architect', 'Software Architect')];
      final logs = [
        _testLog(
          id: 'log-secs',
          agentId: 'a1',
          startedAt: DateTime(2025, 1, 1, 10, 0, 0),
          completedAt: DateTime(2025, 1, 1, 10, 0, 45),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._agentContentOverrides(prefs, agents),
            agentIsRunningProvider('a1').overrideWith((ref) => false),
            agentRunLogsProvider('a1').overrideWith(
              (ref) => Stream.value(logs),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: AgentsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Logs'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.textContaining('45s'), findsOneWidget);
    });

    testWidgets('log with hours and minutes shows correctly', (tester) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final agents = [_testAgent('a1', 'architect', 'Software Architect')];
      final logs = [
        _testLog(
          id: 'log-hm',
          agentId: 'a1',
          startedAt: DateTime(2025, 1, 1, 9, 0, 0),
          completedAt: DateTime(2025, 1, 1, 12, 30, 0),
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._agentContentOverrides(prefs, agents),
            agentIsRunningProvider('a1').overrideWith((ref) => false),
            agentRunLogsProvider('a1').overrideWith(
              (ref) => Stream.value(logs),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: AgentsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Logs'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(find.textContaining('3h'), findsOneWidget);
    });

    testWidgets('log status badge shows RUNNING', (tester) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final agents = [_testAgent('a1', 'architect', 'Software Architect')];
      final log = AgentRunLog(
        id: 'log-running-status',
        agentId: 'a1',
        startedAt: DateTime(2025, 1, 1),
        status: RunStatus.running,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._agentContentOverrides(prefs, agents),
            agentIsRunningProvider('a1').overrideWith((ref) => true),
            agentRunLogsProvider('a1').overrideWith(
              (ref) => Stream.value([log]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: AgentsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      await tester.tap(find.text('Logs'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('RUNNING'), findsOneWidget);
    });

    testWidgets('agent content renders Tabs correctly', (tester) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final agents = [_testAgent('a1', 'architect', 'Software Architect')];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ..._agentContentOverrides(prefs, agents),
            agentIsRunningProvider('a1').overrideWith((ref) => false),
            agentRunLogsProvider('a1').overrideWith(
              (ref) => Stream.value(const <AgentRunLog>[]),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: AgentsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Logs'), findsOneWidget);
    });

    testWidgets('empty agents renders empty content', (tester) async {
      tester.view.physicalSize = const Size(1000, 700);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            agentsProvider.overrideWith(
              (ref) => Stream.value(const <Agent>[]),
            ),
            activeWorkspaceIdProvider.overrideWith(
              () => _TestActiveWorkspaceNotifier(null),
            ),
          ],
          child: FTheme(
            data: FThemes.zinc.light.desktop,
            child: const MaterialApp(
                localizationsDelegates: AppLocalizations.localizationsDelegates,
                supportedLocales: AppLocalizations.supportedLocales,
              home: Scaffold(body: AgentsSettings()),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('No agents'), findsOneWidget);
    expect(find.text('Add agent'), findsOneWidget);
    });
  });
}
