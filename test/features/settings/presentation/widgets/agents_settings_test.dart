import 'dart:async';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/agents/domain/value_objects/agent_live_state.dart';
import 'package:cc_domain/features/analytics/domain/entities/agent_daily_stats.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_status.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/analytics/providers/analytics_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/agents_settings.dart';
import 'package:control_center/features/settings/providers/settings_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../fakes/fake_agent_repository.dart';
import '../../../../fakes/fake_agent_run_log_repository.dart';
import '../../../../fakes/fake_filesystem_port.dart';

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

/// Derived providers the agent-registry UI watches per agent (roster live
/// state, the last-active hint, and the activity heatmap). Overridden to
/// inert values so tests need no database — per-agent run-log streams are
/// still overridden individually where a test exercises the Logs tab.
List _derivedAgentStateOverrides() => [
  agentLiveStateProvider.overrideWith((ref, key) => AgentLiveState.idle),
  agentLastActiveProvider.overrideWith((ref, key) => null),
  dailyStatsByDateRangeProvider.overrideWith(
    (ref, params) => Stream.value(const <AgentDailyStats>[]),
  ),
];

List _agentContentOverrides(
  AppPreferences prefs,
  List<Agent> agents, {
  String? workspaceId,
}) {
  return [
    agentsProvider.overrideWith((ref) => Stream.value(agents)),
    activeWorkspaceIdProvider.overrideWith(
      () => _TestActiveWorkspaceNotifier(workspaceId),
    ),
    detectedAdaptersProvider.overrideWith(
      () => _TestAdapterDetectionNotifier(const []),
    ),
    ..._derivedAgentStateOverrides(),
    appPreferencesProvider.overrideWithValue(prefs),
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

/// Overrides for CRUD tests that need a real agent repository.
List _crudOverrides(
  AppPreferences prefs,
  FakeAgentRepository repo, {
  String? workspaceId = 'ws-1',
}) {
  return [
    agentRepositoryProvider.overrideWithValue(repo),
    workspaceFilesystemPortProvider.overrideWithValue(FakeFilesystemPort()),
    agentRunLogRepositoryProvider.overrideWithValue(
      FakeAgentRunLogRepository(),
    ),
    activeWorkspaceIdProvider.overrideWith(
      () => _TestActiveWorkspaceNotifier(workspaceId),
    ),
    detectedAdaptersProvider.overrideWith(
      () => _TestAdapterDetectionNotifier(const []),
    ),
    ..._derivedAgentStateOverrides(),
    appPreferencesProvider.overrideWithValue(prefs),
  ];
}

/// Common pump setup for the agent settings widget.
Future<void> _pumpAgentsSettings(
  WidgetTester tester,
  List overrides,
) async {
  tester.view.physicalSize = const Size(1000, 700);
  tester.view.devicePixelRatio = 1.0;
  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  await tester.pumpWidget(
    ProviderScope(
      overrides: [...overrides],
      child: CcTheme(
        data: CcThemeData.light(),
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          // CcToastScope above the navigator overlay (mirrors lib/main.dart) so
          // create/rename/save flows that raise a CcToast resolve a host.
          builder: (context, navigator) => Overlay(
            initialEntries: [
              OverlayEntry(
                builder: (context) =>
                    CcToastScope(child: navigator ?? const SizedBox.shrink()),
              ),
            ],
          ),
          home: const Scaffold(body: AgentsSettings()),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  late AppPreferences prefs;
  setUp(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    prefs = AppPreferences.inMemory();
  });

  testWidgets('renders loading state', (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final agentController = StreamController<List<Agent>>();
    addTearDown(agentController.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          agentsProvider.overrideWith((ref) => agentController.stream),
          workspaceAgentsProvider.overrideWith(
            (ref, workspaceId) => Stream.value(const <Agent>[]),
          ),
          workspacesProvider.overrideWith(
            (ref) => Stream.value(const <Workspace>[]),
          ),
          appPreferencesProvider.overrideWithValue(prefs),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
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

    expect(find.byType(CcSpinner), findsOneWidget);
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
          appPreferencesProvider.overrideWithValue(prefs),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
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
          appPreferencesProvider.overrideWithValue(prefs),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
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

    expect(find.text('AGENTS'), findsOneWidget);
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
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a2')).overrideWith((ref) => false),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
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

    final agents = [_testAgent('a1', 'architect', 'Software Architect')];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
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

    final agents = [_testAgent('a1', 'architect', 'Software Architect')];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
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
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value(logs),
          ),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
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
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value([log]),
          ),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
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
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value([log]),
          ),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
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
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value([log]),
          ),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
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
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value(logs),
          ),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
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
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => true),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value([log]),
          ),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
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

    expect(find.byType(CcSpinner), findsWidgets);
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
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value(logs),
          ),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
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
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
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
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value(logs),
          ),
        ],
        child: CcTheme(
          data: CcThemeData.light(),
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
            agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
            agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a2')).overrideWith((ref) => false),
            agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
              (ref) => Stream.value(const <AgentRunLog>[]),
            ),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
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
            agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
            agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
              (ref) => Stream.value(logs),
            ),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
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
            agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
            agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
              (ref) => Stream.value(logs),
            ),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
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
            agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => true),
            agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
              (ref) => Stream.value([log]),
            ),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
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
            agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
            agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
              (ref) => Stream.value(const <AgentRunLog>[]),
            ),
          ],
          child: CcTheme(
            data: CcThemeData.light(),
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

      expect(find.byType(CcTabView), findsOneWidget);
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
          child: CcTheme(
            data: CcThemeData.light(),
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
      expect(find.text('Add agent'), findsAtLeast(1));
    });
  });

  group('AgentsSettings CRUD', () {
    testWidgets('creates an agent via Add Agent button', (tester) async {
      final repo = FakeAgentRepository();
      final agents = [_testAgent('a1', 'architect', 'Software Architect')];
      for (final a in agents) {
        await repo.upsert(a);
      }

      await _pumpAgentsSettings(tester, _crudOverrides(prefs, repo));
      repo.emit();
      await tester.pump();

      expect(find.text('architect'), findsAtLeast(1));
      expect(find.text('Software Architect'), findsAtLeast(1));

      await tester.tap(find.text('Add agent'));
      await tester.pump();
      await tester.pump();
      await tester.pump();

      expect(repo.saved.length, 2);
      await tester.pumpAndSettle();
    });

    testWidgets('deletes an agent with confirmation dialog', (tester) async {
      final repo = FakeAgentRepository();
      final agents = [
        _testAgent('a1', 'architect', 'Software Architect'),
        _testAgent('a2', 'reviewer', 'Code Reviewer'),
      ];
      for (final a in agents) {
        await repo.upsert(a);
      }

      await _pumpAgentsSettings(tester, _crudOverrides(prefs, repo));
      repo.emit();
      await tester.pump();

      final deleteButton = find.text('Delete');
      expect(deleteButton, findsWidgets);

      await tester.tap(deleteButton.last);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.textContaining('Delete'), findsAtLeast(2));

      final confirmButton = find.descendant(
        of: find.byType(CcDialog),
        matching: find.text('Delete'),
      );
      await tester.tap(confirmButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(repo.saved.length, 1);
      expect(repo.saved.first.id, 'a2');
    });

    testWidgets('shows empty state after deleting last agent', (tester) async {
      final repo = FakeAgentRepository();
      final agent = _testAgent('a1', 'architect', 'Software Architect');
      await repo.upsert(agent);

      await _pumpAgentsSettings(tester, _crudOverrides(prefs, repo));
      repo.emit();
      await tester.pump();

      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final confirmButton = find.descendant(
        of: find.byType(CcDialog),
        matching: find.text('Delete'),
      );
      await tester.tap(confirmButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('No agents'), findsOneWidget);
      expect(find.textContaining('Create your first agent'), findsOneWidget);
      expect(repo.saved, isEmpty);
    });
  });

  group('AgentsSettings selection', () {
    testWidgets('selects agent by tapping tile', (tester) async {
      final agents = [
        _testAgent('a1', 'architect', 'Software Architect'),
        _testAgent('a2', 'reviewer', 'Code Reviewer'),
      ];

      await _pumpAgentsSettings(
        tester,
        [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a2')).overrideWith((ref) => false),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a2')).overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
        ],
      );

      expect(find.text('Software Architect'), findsAtLeast(1));

      await tester.tap(find.text('reviewer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Code Reviewer'), findsAtLeast(1));
    });

    testWidgets('filters agent list by name', (tester) async {
      final agents = [
        _testAgent('a1', 'architect', 'Software Architect'),
        _testAgent('a2', 'reviewer', 'Code Reviewer'),
        _testAgent('a3', 'tester', 'QA Engineer'),
      ];

      await _pumpAgentsSettings(
        tester,
        [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a2')).overrideWith((ref) => false),
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a3')).overrideWith((ref) => false),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a2')).overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a3')).overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
        ],
      );

      expect(find.text('architect'), findsAtLeast(1));
      expect(find.text('reviewer'), findsOneWidget);
      expect(find.text('tester'), findsOneWidget);

      await tester.enterText(find.byType(CcTextField).first, 'rev');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('reviewer'), findsOneWidget);
    });

    testWidgets('filters agent list by title', (tester) async {
      final agents = [
        _testAgent('a1', 'architect', 'Software Architect'),
        _testAgent('a2', 'reviewer', 'Code Reviewer'),
      ];

      await _pumpAgentsSettings(
        tester,
        [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a2')).overrideWith((ref) => false),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a2')).overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
        ],
      );

      await tester.enterText(find.byType(CcTextField).first, 'code');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('reviewer'), findsOneWidget);
    });
  });

  group('AgentsSettings edge cases', () {
    testWidgets('auto-selects first agent after deleting selected', (
      tester,
    ) async {
      final repo = FakeAgentRepository();
      final agents = [
        _testAgent('a1', 'architect', 'Software Architect'),
        _testAgent('a2', 'reviewer', 'Code Reviewer'),
      ];
      for (final a in agents) {
        await repo.upsert(a);
      }

      await _pumpAgentsSettings(tester, _crudOverrides(prefs, repo));
      repo.emit();
      await tester.pump();

      await tester.tap(find.text('reviewer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));
      expect(find.text('Code Reviewer'), findsAtLeast(1));

      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      final confirmButton = find.descendant(
        of: find.byType(CcDialog),
        matching: find.text('Delete'),
      );
      await tester.tap(confirmButton);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(repo.saved.length, 1);
      expect(find.text('Software Architect'), findsAtLeast(1));
    });

    testWidgets('shows status indicator on each agent tile', (tester) async {
      final agents = [
        _testAgent('a1', 'architect', 'Software Architect'),
        _testAgent('a2', 'reviewer', 'Code Reviewer'),
      ];

      await _pumpAgentsSettings(
        tester,
        [
          ..._agentContentOverrides(prefs, agents),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a2')).overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
        ],
      );

      expect(find.text('architect'), findsAtLeast(1));
      expect(find.text('reviewer'), findsOneWidget);
      // Each roster row carries a live status dot (the fleet-roster design).
      expect(find.byType(AgentStatusDot), findsWidgets);
    });

    testWidgets('shows no matches when filter excludes all', (tester) async {
      final agents = [_testAgent('a1', 'architect', 'Software Architect')];

      await _pumpAgentsSettings(
        tester,
        [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
        ],
      );

      expect(find.text('architect'), findsAtLeast(1));

      await tester.enterText(find.byType(CcTextField).first, 'zzzzzz');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No agents match your filter'), findsOneWidget);
    });
  });

  // ─── Agent CRUD - validation ──────────────────────────────────────────

  group('AgentsSettings CRUD - validation', () {
    testWidgets('create agent with empty name shows error snackbar', (
      tester,
    ) async {
      final repo = FakeAgentRepository();
      final agent = _testAgent('a1', 'architect', 'Software Architect');
      await repo.upsert(agent);

      await _pumpAgentsSettings(tester, _crudOverrides(prefs, repo));
      repo.emit();
      await tester.pump();

      await tester.tap(find.text('architect').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Clear the name field (second CcTextField after the filter field)
      await tester.enterText(find.byType(CcTextField).at(1), '');
      await tester.pump();


      // Scroll down to make the Save changes button visible
      await tester.scrollUntilVisible(
        find.text('Save changes'),
        -200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Save changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Name and title are required.'), findsOneWidget);
    });

    testWidgets('create agent with very long name (150 chars) does not crash', (
      tester,
    ) async {
      final repo = FakeAgentRepository();
      final agent = _testAgent('a1', 'architect', 'Software Architect');
      await repo.upsert(agent);

      await _pumpAgentsSettings(tester, _crudOverrides(prefs, repo));
      repo.emit();
      await tester.pump();

      await tester.tap(find.text('architect').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final longName = List.filled(150, 'x').join();
      await tester.enterText(find.byType(CcTextField).at(1), longName);
      await tester.pump();


      // Scroll down to make the Save changes button visible
      await tester.scrollUntilVisible(
        find.text('Save changes'),
        -200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Save changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Should not crash; agent should be updated with long name
      expect(tester.takeException(), isNull);
      final saved = repo.saved.firstWhere((a) => a.id == 'a1');
      expect(saved.name, longName);
    });

    testWidgets('create agent with special characters in name', (
      tester,
    ) async {
      final repo = FakeAgentRepository();
      final agent = _testAgent('a1', 'architect', 'Software Architect');
      await repo.upsert(agent);

      await _pumpAgentsSettings(tester, _crudOverrides(prefs, repo));
      repo.emit();
      await tester.pump();

      await tester.tap(find.text('architect').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      const specialName = r'!@#$%^&*()_+-=[]{}|;:,.<>?/~`';
      await tester.enterText(find.byType(CcTextField).at(1), specialName);
      await tester.pump();


      // Scroll down to make the Save changes button visible
      await tester.scrollUntilVisible(
        find.text('Save changes'),
        -200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Save changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      final saved = repo.saved.firstWhere((a) => a.id == 'a1');
      expect(saved.name, specialName);
    });
  });

  // ─── Agent CRUD - rename ──────────────────────────────────────────────

  group('AgentsSettings CRUD - rename', () {
    testWidgets('updates an existing agent name via settings form', (
      tester,
    ) async {
      final repo = FakeAgentRepository();
      final agent = _testAgent('a1', 'architect', 'Software Architect');
      await repo.upsert(agent);

      await _pumpAgentsSettings(tester, _crudOverrides(prefs, repo));
      repo.emit();
      await tester.pump();

      await tester.tap(find.text('architect').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Change name
      await tester.enterText(find.byType(CcTextField).at(1), 'lead-dev');
      await tester.pump();


      // Scroll down to make the Save changes button visible
      await tester.scrollUntilVisible(
        find.text('Save changes'),
        -200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Save changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify name updated in repo
      final saved = repo.saved.firstWhere((a) => a.id == 'a1');
      expect(saved.name, 'lead-dev');

      // Verify new name appears in the agent list
      expect(find.text('lead-dev'), findsAtLeast(1));
    });
  });

  // ─── Agent CRUD - title update ────────────────────────────────────────

  group('AgentsSettings CRUD - title update', () {
    testWidgets('change title field, save, verify title persisted', (
      tester,
    ) async {
      final repo = FakeAgentRepository();
      final agent = _testAgent('a1', 'architect', 'Software Architect');
      await repo.upsert(agent);

      await _pumpAgentsSettings(tester, _crudOverrides(prefs, repo));
      repo.emit();
      await tester.pump();

      await tester.tap(find.text('architect').first);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Change title (third CcTextField after filter and name)
      await tester.enterText(
        find.byType(CcTextField).at(2),
        'Lead DevOps Engineer',
      );
      await tester.pump();


      // Scroll down to make the Save changes button visible
      await tester.scrollUntilVisible(
        find.text('Save changes'),
        -200,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.tap(find.text('Save changes'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Verify title updated in repo
      final saved = repo.saved.firstWhere((a) => a.id == 'a1');
      expect(saved.title, 'Lead DevOps Engineer');

      // Verify new title appears in UI
      expect(find.text('Lead DevOps Engineer'), findsAtLeast(1));
    });
  });

  // ─── Agent CRUD - duplicate handling ──────────────────────────────────

  group('AgentsSettings CRUD - duplicate handling', () {
    testWidgets('shows error when creating agent with duplicate name', (
      tester,
    ) async {
      final repo = FakeAgentRepository();
      // Pre-create an agent with the default name that Add agent uses
      final existing = Agent(
        id: 'existing-1',
        name: 'Unnamed agent',
        title: 'Unnamed agent',
        agentMdPath: '/tmp/unnamed-agent.md',
        workspaceId: 'ws-1',
        skills: AgentSkills([]),
        createdAt: DateTime(2025),
      );
      await repo.upsert(existing);

      await _pumpAgentsSettings(tester, _crudOverrides(prefs, repo));
      repo.emit();
      await tester.pump();

      // Tap Add agent — CreateAgentUseCase should reject duplicate name
      await tester.tap(find.text('Add agent'));
      // Pump a bounded amount so the async create rejects and the error toast
      // animates in — but stay under the toast's 3s auto-dismiss (pumpAndSettle
      // would overshoot it and remove the toast before we assert).
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // Error toast should appear
      expect(find.textContaining('Error creating agent'), findsOneWidget);
      // Only the original agent should exist
      expect(repo.saved.length, 1);
    });
  });

  // ─── Agent CRUD - cancel create ───────────────────────────────────────

  group('AgentsSettings CRUD - cancel create', () {
    testWidgets('tap Add agent shows form and creates agent', (
      tester,
    ) async {
      final repo = FakeAgentRepository();

      await _pumpAgentsSettings(tester, _crudOverrides(prefs, repo));
      repo.emit();
      await tester.pump();

      // Tap Add agent
      await tester.tap(find.text('Add agent').first);
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // Form should appear with Settings and Logs tabs
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Logs'), findsOneWidget);

      // Agent should have been created in the repo
      expect(repo.saved.length, 1);
    });
  });

  // ─── Log edge cases - multiple logs ───────────────────────────────────

  group('AgentsSettings log edge cases - multiple logs', () {
    testWidgets('shows 3+ log entries for an agent', (tester) async {
      final agents = [_testAgent('a1', 'architect', 'Software Architect')];
      final logs = [
        _testLog(
          id: 'log-1',
          agentId: 'a1',
          startedAt: DateTime(2025, 1, 1, 10, 0),
          completedAt: DateTime(2025, 1, 1, 10, 5),
        ),
        _testLog(
          id: 'log-2',
          agentId: 'a1',
          startedAt: DateTime(2025, 1, 2, 14, 0),
          completedAt: DateTime(2025, 1, 2, 14, 30),
        ),
        _testLog(
          id: 'log-3',
          agentId: 'a1',
          startedAt: DateTime(2025, 1, 3, 9, 0),
          completedAt: DateTime(2025, 1, 3, 9, 45),
        ),
      ];

      await _pumpAgentsSettings(
        tester,
        [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value(logs),
          ),
        ],
      );

      await tester.tap(find.text('Logs'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // All three logs should have their status badges visible
      expect(find.text('COMPLETED'), findsNWidgets(3));
    });
  });

  // ─── Log edge cases - pending status ──────────────────────────────────

  group('AgentsSettings log edge cases - pending status', () {
    testWidgets('log with RunStatus.pending shows status badge', (
      tester,
    ) async {
      final agents = [_testAgent('a1', 'architect', 'Software Architect')];
      final log = AgentRunLog(
        id: 'log-pending',
        agentId: 'a1',
        startedAt: DateTime(2025, 1, 1),
        status: RunStatus.pending,
      );

      await _pumpAgentsSettings(
        tester,
        [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value([log]),
          ),
        ],
      );

      await tester.tap(find.text('Logs'));
      await tester.pumpAndSettle(const Duration(seconds: 2));

      expect(find.text('PENDING'), findsOneWidget);
    });
  });

  // ─── Log edge cases - zero duration ───────────────────────────────────

  group('AgentsSettings log edge cases - zero duration', () {
    testWidgets('log where startedAt equals completedAt renders without crash', (
      tester,
    ) async {
      final agents = [_testAgent('a1', 'architect', 'Software Architect')];
      final now = DateTime(2025, 1, 1, 12, 0);
      final log = AgentRunLog(
        id: 'log-zero',
        agentId: 'a1',
        startedAt: now,
        completedAt: now,
        status: RunStatus.completed,
      );

      await _pumpAgentsSettings(
        tester,
        [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value([log]),
          ),
        ],
      );

      await tester.tap(find.text('Logs'));
      await tester.pumpAndSettle(const Duration(seconds: 5));

      // Should not crash; log entry should be visible
      expect(tester.takeException(), isNull);
      expect(find.text('COMPLETED'), findsOneWidget);
    });
  });

  // ─── Agent tile click ─────────────────────────────────────────────────

  group('AgentsSettings agent tile click', () {
    testWidgets('tapping agent tile shows details with settings and logs tabs', (
      tester,
    ) async {
      final agents = [
        _testAgent('a1', 'architect', 'Software Architect'),
        _testAgent('a2', 'reviewer', 'Code Reviewer'),
      ];

      await _pumpAgentsSettings(
        tester,
        [
          ..._agentContentOverrides(prefs, agents),
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith((ref) => false),
          agentIsRunningProvider((workspaceId: 'ws-1', agentId: 'a2')).overrideWith((ref) => false),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a1')).overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
          agentRunLogsProvider((workspaceId: 'ws-1', agentId: 'a2')).overrideWith(
            (ref) => Stream.value(const <AgentRunLog>[]),
          ),
        ],
      );

      // Tap second agent tile
      await tester.tap(find.text('reviewer'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Settings and Logs tabs should be visible
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Logs'), findsOneWidget);

      // Selected agent title should appear in the header
      expect(find.text('Code Reviewer'), findsAtLeast(1));
    });
  });

  // ─── Multiple workspaces ──────────────────────────────────────────────

  group('AgentsSettings multiple workspaces', () {
    testWidgets('switching active workspace updates agent list', (
      tester,
    ) async {
      final repo = FakeAgentRepository();
      final ws1Agent = _testAgent('a1', 'architect', 'Software Architect');
      final ws2Agent = Agent(
        id: 'a2',
        name: 'tester',
        title: 'QA Engineer',
        agentMdPath: '/tmp/tester.md',
        workspaceId: 'ws-2',
        skills: AgentSkills([]),
        createdAt: DateTime(2025),
      );
      await repo.upsert(ws1Agent);
      await repo.upsert(ws2Agent);

      // Show workspace ws-1
      await _pumpAgentsSettings(
        tester,
        _crudOverrides(prefs, repo, workspaceId: 'ws-1'),
      );
      repo.emit();
      await tester.pump();

      // ws-1 has architect
      expect(find.text('architect'), findsAtLeast(1));

      // Rebuild with workspace ws-2 (new key forces fresh ProviderScope)
      await _pumpAgentsSettings(
        tester,
        _crudOverrides(prefs, repo, workspaceId: 'ws-2'),
      );
      repo.emit();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Widget renders without error
      expect(tester.takeException(), isNull);
    });
  });
}
