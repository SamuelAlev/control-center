import 'dart:async';

import 'package:cc_domain/core/domain/events/agent_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_settings_repository.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_infra/cc_infra.dart'
    show
        BundledCodeRunner,
        CodeExecutionService,
        McpRunScriptPasts,
        ScriptHiddenSpaces,
        ScriptPastSources;
import 'package:cc_mcp/cc_mcp.dart' show ReplMcpTool;
import 'package:cc_persistence/cc_persistence.dart'
    show
        CrossWorkspaceQueries,
        DaoCodeExecutionRepository,
        DaoCodeModeStoreRepository,
        DaoTranscriptStore,
        WorkspaceDatabaseManager;
import 'package:cc_server_core/src/code_mode/code_mode_rpc_ops.dart';
import 'package:cc_server_core/src/code_mode/orphaned_execution_sweep.dart';
import 'package:cc_server_core/src/code_mode/server_code_mode.dart';
import 'package:path/path.dart' as p;

/// Code mode (`repl`) as the server boots it: one runner, one execution
/// service and one view of its settings for the whole server.
///
/// A bundle without the runner leaves [runner], [service] and [replTool]
/// null only until the native preflight refuses to boot; a runner that
/// cannot confine itself leaves code mode unavailable (no run gets `repl`)
/// and never runs a script with less isolation. A public demo runs no
/// script at all: it has no [service] and no [replTool], and code mode is
/// unavailable there with its own reason. The runner's self-test
/// starts at once and is awaited by [startupLine], after the preflight and
/// before any run. Availability is read live everywhere (the status op, the
/// composition snapshot, each new run's tools): a runner that stops
/// launching after boot and fails the self-test again turns code mode off,
/// and a later self-test that passes turns it back on
/// ([availabilityChanges]), each change logged once in the startup line's
/// words.
///
/// The service admits no script of a workspace before a sweep of that
/// workspace has finished the records a restart left running
/// ([OrphanedExecutionSweeps]), so the sweep can finish every running record
/// without finishing a live one. [sweepOrphans] starts the boot sweep of
/// every workspace; the server calls it once it holds its port: a second
/// server started on the same data directory and port fails to bind before
/// it sweeps. A script waits for the sweep within its wall clock and is
/// refused `server_busy` past that. Nothing stops a second server on
/// another port from sweeping the first one's live records; there is no
/// data-directory lock.
class ServerCodeMode {
  ServerCodeMode._({
    required this.runner,
    required this.service,
    required this.executions,
    required this.settings,
    required this.replTool,
    required this.scriptPast,
    required this.mcpPasts,
    required this._maxProcesses,
    required this._maxHeapBytes,
    required this._selfTest,
    required this._sweeps,
  });

  /// Finds the runner, starts its self-test, and builds the service over
  /// [workspaceDbs], unless this is a public [demo]. [embeddings] backs
  /// `models.*` in scripts. [hiddenSpaces] is the space rule a script's
  /// `history()` reads under (the server's `AgentSpaceVisibility.hiddenFor`).
  /// [events] is the server's bus: a run's MCP-lane port ([mcpPasts]) is
  /// dropped when the run settles ([AgentRunSettled]).
  factory ServerCodeMode.start({
    required String dataDir,
    required WorkspaceDatabaseManager workspaceDbs,
    required CrossWorkspaceQueries crossWorkspace,
    required EmbeddingPort? embeddings,
    required int maxProcesses,
    required int maxHeapBytes,
    required bool demo,
    required WorkspaceRepository workspaces,
    required WorkspaceSettingsRepository workspaceSettings,
    required ScriptHiddenSpaces hiddenSpaces,
    required DomainEventBus events,
  }) {
    final runner = CodeRunnerHost.locate(appSupportRoot: dataDir);
    final scriptPast = ScriptPastSources.over(
      DaoTranscriptStore(workspaceDbs),
      hiddenSpaces,
    );
    final mcpPasts = McpRunScriptPasts(scriptPast);
    events.on<AgentRunSettled>().listen((run) => mcpPasts.drop(run.runId));
    final executions = DaoCodeExecutionRepository(workspaceDbs);
    final sweeps = OrphanedExecutionSweeps(
      crossWorkspace: crossWorkspace,
      workspaceDbs: workspaceDbs,
    );
    final service = runner == null || demo
        ? null
        : CodeExecutionService(
            sandbox: runner.sandbox,
            executions: executions,
            store: DaoCodeModeStoreRepository(workspaceDbs),
            embeddings: embeddings,
            serverProcessCap: maxProcesses,
            maxHeapBytes: maxHeapBytes,
            admission: sweeps.admit,
          );
    if (runner != null && service != null) {
      // Availability is live: a runner that stops launching after boot and
      // then fails its self-test again turns code mode off, and a later
      // self-test that passes turns it back on. Each change is said once,
      // in the startup line's words.
      CodeRunnerHost.logChanges(
        runner.sandbox.changes,
        lineFor: (availability) => CodeRunnerHost.startupLineFor(
          availability,
          version: runner.version,
          maxProcesses: maxProcesses,
          maxParked: service.parkedCap,
          workspaceShare: service.workspaceShare,
          maxHeapBytes: maxHeapBytes,
        ),
      );
    }
    final settings = CodeModeSettings(
      availability: () => demo
          ? const CodeRunnerAvailability.unavailable(demoReason)
          : runner?.availability ??
                const CodeRunnerAvailability.unavailable(_missing),
      workspaces: workspaces,
      settings: workspaceSettings,
    );
    return ServerCodeMode._(
      runner: runner,
      service: service,
      executions: executions,
      settings: settings,
      replTool: service == null
          ? null
          : ReplMcpTool(
              executions: service,
              limitsFor: settings.limitsFor,
              records: executions,
              past: mcpPasts.forRun,
            ),
      scriptPast: scriptPast,
      mcpPasts: mcpPasts,
      maxProcesses: maxProcesses,
      maxHeapBytes: maxHeapBytes,
      selfTest: demo ? null : runner?.start(),
      sweeps: sweeps,
    );
  }

  static const String _missing =
      'the code mode runner is missing from this bundle';

  /// Why a public demo runs no script.
  static const String demoReason = 'a public demo runs no scripts';

  /// The runner, or null when the bundle has none.
  final CodeRunnerHost? runner;

  /// Runs every script on this server; null without a runner.
  final CodeExecutionService? service;

  /// The execution records.
  final DaoCodeExecutionRepository executions;

  /// Whether this server runs scripts, and each workspace's limits.
  final CodeModeSettings settings;

  /// The MCP `repl` tool; null without a runner.
  final ReplMcpTool? replTool;

  /// What every run's scripts read of its past and keep (`history`,
  /// `outputs`, `loadOutput`, `keep`): the dispatch adapter binds it per
  /// run, the MCP `repl` tool per attested scope.
  final ScriptPastSources scriptPast;

  /// The MCP `repl` tool's ports, one per run until it settles.
  final McpRunScriptPasts mcpPasts;

  final int _maxProcesses;
  final int _maxHeapBytes;
  final Future<void>? _selfTest;
  final OrphanedExecutionSweeps _sweeps;

  /// Finishes the code executions a restart left running, in every
  /// workspace, then lets scripts in; a workspace whose sweep failed admits
  /// none until a later sweep of it succeeds. Runs once; later calls do
  /// nothing. [announce] gets one line when records were closed.
  void sweepOrphans({required void Function(String line) announce}) =>
      unawaited(_sweeps.sweepAll(announce: announce));

  /// The directories no agent sandbox may change: the runner is run
  /// unconfined by the host (it confines itself), so neither it nor where it
  /// is found may be replaced. The data directory's `codemode/` is hidden
  /// with the data directory.
  List<String> get hostExecutableDirs => [
    ...BundledCodeRunner.installDirectories(),
    if (runner case final runner?) p.dirname(runner.executable),
  ];

  /// Fires once per change of [CodeModeSettings.availability] after boot,
  /// with the new answer. The MCP endpoint lists `repl` and the script-only
  /// tools by availability, so its clients are told the list changed.
  Stream<CodeRunnerAvailability> get availabilityChanges =>
      runner?.sandbox.changes ?? const Stream.empty();

  /// Calls [relist] on every change of [availabilityChanges], for the
  /// lifetime of the server.
  void relistOnChange(void Function() relist) =>
      availabilityChanges.listen((_) => relist());

  /// Whether this server runs scripts, with the public reason (no host path)
  /// when it does not: what a client may be shown.
  CodeRunnerAvailability get publicAvailability =>
      switch (settings.availability) {
        CodeRunnerAvailable() => const CodeRunnerAvailability.available(),
        CodeRunnerUnavailable() => CodeRunnerAvailability.unavailable(
          hostFacts.publicReason() ?? _missing,
        ),
      };

  /// What the `codeMode.*` ops report about this host.
  CodeModeHostFacts get hostFacts => CodeModeHostFacts(
    availability: () => settings.availability,
    publicReason: () => switch (settings.availability) {
      CodeRunnerAvailable() => null,
      CodeRunnerUnavailable(:final reason) when service == null => reason,
      CodeRunnerUnavailable() => runner?.publicReason ?? _missing,
    },
    runnerVersion: () => runner?.version,
    maxProcesses: _maxProcesses,
    maxParkedProcesses: service?.parkedCap ?? 0,
    maxWorkspaceProcesses: service?.workspaceShare ?? 0,
    maxHeapBytes: _maxHeapBytes,
  );

  /// Waits for the runner's self-test, then gives the one startup line about
  /// code mode: `code_mode=available (…)` or
  /// `code_mode=unavailable (<reason>)`. Null without a runner (the preflight has refused to boot
  /// by then).
  Future<String?> startupLine() async {
    await _selfTest;
    final runner = this.runner;
    if (runner == null) {
      return null;
    }
    final service = this.service;
    if (service == null) {
      return CodeRunnerHost.startupLineFor(
        settings.availability,
        version: null,
        maxProcesses: _maxProcesses,
        maxParked: 0,
        workspaceShare: 0,
        maxHeapBytes: _maxHeapBytes,
      );
    }
    return runner.startupLine(
      maxProcesses: _maxProcesses,
      maxParked: service.parkedCap,
      workspaceShare: service.workspaceShare,
      maxHeapBytes: _maxHeapBytes,
    );
  }
}
