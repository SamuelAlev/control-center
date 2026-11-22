import 'dart:convert';
import 'dart:io';

import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/environments/domain/ports/environment_port.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/capability_tier.dart';
import 'package:cc_domain/features/rigs/domain/ports/rig_port.dart';
import 'package:cc_harness/cancellation.dart';
import 'package:cc_harness/context.dart' show ToolOutputStore;
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/cc_infra.dart';
// ignore: implementation_imports
import 'package:cc_infra/src/evaluation/controlled_file_tools.dart';
// ignore: implementation_imports
import 'package:cc_infra/src/evaluation/goal_verification_session.dart';
import 'package:cc_mcp/cc_mcp.dart';
import 'package:cc_mcp_client/cc_mcp_client.dart'
    show BridgedMcpTool, McpRemoteTool;
import 'package:cc_natives/cc_natives.dart' show TreeSitterParser;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:test/test.dart';

import '../helpers/server_mcp_registry_fixture.dart';
import '../helpers/test_database.dart';
import 'script_callable_pin_test.dart'
    show harnessScriptCallable, mcpScriptCallable;

/// Where every tool a code mode script may call that runs what it may be
/// handed says what runs, pinned on both surfaces: a tool nobody decided
/// about fails here.
///
/// The set is the existing classification, not a list: every script-callable
/// tool ([harnessScriptCallable], [mcpScriptCallable]) of the exec tier
/// (`ToolApprovalTier.exec`, or an MCP tool's `CapabilityTier.exec` for no
/// arguments) or that declares [ActionClass.processSpawn] or
/// [ActionClass.hostExecution]. Each is built here, and each is in
/// [harnessRuns] or [mcpRuns] (the arguments of a call and what its
/// `executedContent` says that call runs, the audit's `<name>: <content>`)
/// or in [harnessRunsNothing] or [mcpRunsNothing] with the reason it runs
/// nothing it is handed. A wrapper answers what it wraps.
///
/// A tool of an external or workspace MCP server ([BridgedMcpTool]) is in the
/// set by rule (an `exec` tool) and states no content: [bridgedRunsNothing].
const harnessRuns = <String, List<(Map<String, Object?>, String?)>>{
  'bash': [
    ({'command': 'ls -la'}, 'ls -la'),
  ],
  'debug': [
    (
      {
        'op': 'launch',
        'program': 'main.py',
        'args': ['--fast', 'in "quotes"'],
      },
      '["main.py","--fast","in \\"quotes\\""]',
    ),
    ({'op': 'evaluate', 'expression': 'len(xs)'}, 'len(xs)'),
    ({'op': 'attach', 'port': 5678}, null),
    ({'op': 'stack'}, null),
  ],
};

/// See [harnessRuns].
const harnessRunsNothing = <String, String>{
  'bash_output':
      'reads a background command\'s state and output by its handle; '
      'nothing it is handed runs',
  'bash_kill':
      'stops a background command by its handle; nothing it is handed runs',
  'web_fetch': 'fetches the page at a URL; nothing it is handed runs',
  'web_search': 'sends a search query; nothing it is handed runs',
  'lsp':
      'asks the language server the run chose about a file and a position; '
      'nothing it is handed runs',
  'lsp_rename':
      'renames a symbol through that language server; it writes files and '
      'runs nothing it is handed',
};

/// See [harnessRuns].
const mcpRuns = <String, List<(Map<String, Object?>, String?)>>{
  'environment_exec': [
    (
      {
        'service': 'api',
        'command': ['npm', 'test'],
      },
      '["npm","test"]',
    ),
  ],
  'environment_run_task': [
    (
      {
        'task_id': 'test',
        'arguments': ['--watch'],
      },
      '["test","--watch"]',
    ),
    ({'task_id': 'lint'}, '["lint"]'),
  ],
  'mobile_use': [
    (
      {
        'action': 'shell',
        'argv': ['logcat', '-d'],
      },
      '["logcat","-d"]',
    ),
    (
      {
        'action': 'tap',
        'coordinate': [1, 2],
      },
      null,
    ),
    ({'action': 'shell', 'argv': 'not a list'}, null),
    (
      {
        'action': 'shell',
        'argv': <Object?>[1, null],
      },
      null,
    ),
  ],
  'ios_use': [
    (
      {
        'action': 'spawn',
        'argv': ['log', 'show'],
      },
      '["log","show"]',
    ),
    ({'action': 'screenshot'}, null),
    // Malformed calls answer null, never throw: the gate asks first.
    ({'action': 'spawn', 'argv': 'not a list'}, null),
    ({'action': 'tap', 'coordinate': 7}, null),
  ],
};

/// See [harnessRuns].
const mcpRunsNothing = <String, String>{
  'environment_up':
      "runs the commands of the space's own environment definition; the "
      'call names none',
  'environment_down': 'stops what the definition started; the call names none',
  'environment_reset':
      'resets the stack by its definition; the call names no command',
  'environment_destroy':
      'tears the stack down by its definition; the call names no command',
  'environment_restart':
      'restarts a service by its definition; the call names no command',
  'environment_launch_app':
      'builds and starts a component the definition names; the call names '
      'no command',
  'environment_stop_app': 'stops a component the definition names',
  'computer_use':
      "drives the rig's screen with the pointer and keys; typed text is "
      'input to whatever has focus, not a command the tool runs',
  'app_use':
      "drives one app window on the rig's screen; typed text is input, not "
      'a command the tool runs',
  'browser_use':
      "drives a page in the rig's browser; no action evaluates a script",
};

/// Why a tool of an external or workspace MCP server states no content: its
/// arguments mean whatever that server makes of them, and nothing here can
/// tell which of them, if any, it runs.
const bridgedRunsNothing =
    'an external server decides what its arguments mean; nothing here can '
    'tell which of them it runs';

const _execClasses = {ActionClass.processSpawn, ActionClass.hostExecution};

/// Whether [tool] is in the set: script-callable, and of the exec tier or
/// spawning a process or running on the host.
bool runsWhatItIsHanded(HarnessTool tool) =>
    tool.scriptCallable &&
    (tool.approvalTier == ToolApprovalTier.exec ||
        tool.actionClasses.any(_execClasses.contains));

/// See [runsWhatItIsHanded].
bool mcpRunsWhatItIsHanded(McpTool tool) =>
    tool.scriptCallable &&
    (tool.toolApproval(const {}).tier == CapabilityTier.exec ||
        tool.actionClasses.any(_execClasses.contains));

/// The names of the tool classes under [roots] whose source, or the source
/// of a class they extend, declares a process spawn, host execution or the
/// exec tier.
Set<String> execToolNamesInSource(List<String> roots) {
  final sources = [
    for (final root in roots)
      for (final file in Directory(
        root,
      ).listSync(recursive: true).whereType<File>())
        if (file.path.endsWith('.dart') && !file.path.endsWith('.g.dart'))
          file.readAsStringSync(),
  ];
  final declaration = RegExp(
    r'^(?:abstract |final |base )*class (\w+)(?:<[^>{]*>)?\s+extends\s+(\w+)',
    multiLine: true,
  );
  final topLevel = RegExp(
    r'^(?:abstract |final |base |sealed |mixin )*(?:class|mixin|enum) ',
    multiLine: true,
  );
  final marker = RegExp(
    r'ActionClass\.(?:processSpawn|hostExecution)|'
    r'(?:ToolApproval|CapabilityTier|ToolApprovalTier)\.exec\b',
  );
  final literalName = RegExp(r"String get name =>\s*'(\w+)'");
  final classes = <String, ({String parent, String body})>{};
  for (final source in sources) {
    final starts = [for (final m in topLevel.allMatches(source)) m.start];
    for (final m in declaration.allMatches(source)) {
      final end = starts.firstWhere(
        (s) => s > m.start,
        orElse: () => source.length,
      );
      classes[m.group(1)!] = (
        parent: m.group(2)!,
        body: source.substring(m.start, end),
      );
    }
  }
  bool exec(String cls, [int depth = 0]) {
    final c = classes[cls];
    return c != null &&
        depth < 8 &&
        (marker.hasMatch(c.body) || exec(c.parent, depth + 1));
  }

  return {
    for (final MapEntry(key: cls, value: c) in classes.entries)
      if (exec(cls))
        if (literalName.firstMatch(c.body) case final m?) m.group(1)!,
  };
}

/// The tools of [tools] in the set that no pin decides.
List<String> undecided(Iterable<HarnessTool> tools, Set<String> decided) => [
  for (final t in tools)
    if (runsWhatItIsHanded(t) && !decided.contains(t.name)) t.name,
];

void main() {
  final scratch = Directory.systemTemp.createTempSync('cc_exec_pin_');
  tearDownAll(() => scratch.deleteSync(recursive: true));

  List<HarnessTool> harnessTools() {
    final registry = buildHarnessToolRegistry(
      mode: Mode.chat,
      networkEnabled: true,
      env: const {},
      workspaceId: 'ws-1',
      agentId: 'agent-1',
      conversationId: 'conv-1',
      spaceId: 'space-1',
      fileSearch: _NoFileSearch(),
      mcpRegistry: McpToolRegistry(const []),
      agentQuestionPort: _NoQuestions(),
      toolOutputStore: _NoOutputs(),
      treeSitterParser: _NoParser(),
      lspWorkingDirectory: scratch.path,
      lspSupervisor: LspSupervisor(),
      // Unconfined: a tool's worst case decides whether it is in the set.
      lspProcesses: const HostToolProcessLauncher(),
      debugSupervisor: DebugSessionSupervisor(),
      debugProcesses: const HostToolProcessLauncher(),
      evalKernelFor: (_) => throw StateError('no kernel in this test'),
      toolProcesses: const HostToolProcessLauncher(),
      replSlot: true,
    )..register(TaskTool(_NeverSpawns()));
    final controlled = ControlledEvaluationProcess(
      root: scratch.path,
      home: scratch.path,
    );
    return [
      ...registry.tools,
      ...buildVibeTools(roster: VibeRoster(), runner: _NeverRuns()),
      HarnessToolSearchTool(
        catalog: registry.tools,
        residency: const ToolResidencySpec(),
      ),
      ReplTool(
        executor: _NoScripts(),
        run: ReplRunIdentity(
        workspaceId: 'ws-1',
        runId: 'run-1',
        readOnly: false,
        past: null,
      ),
        callableTools: registry.tools,
        limits: CodeModeLimits.defaults,
      ),
      // Wrappers answer what they wrap.
      ControlledEvaluationBashTool(controlled),
      ...controlledFileTools(controlled),
      // Evaluation-only copies of two MCP tools (a goal attempt's claim and
      // its review's answer): classified here like every built tool.
      EvaluationCompleteGoalTool((_) => throw StateError('no claim here')),
      EvaluationSubmitOutputTool(),
    ];
  }

  void expectDecided(
    String name,
    String? Function(Map<String, dynamic>) content,
    Map<String, List<(Map<String, Object?>, String?)>> runs,
    Map<String, String> nothing,
  ) {
    final samples = runs[name];
    if (samples != null) {
      for (final (args, expected) in samples) {
        expect(content(args), expected, reason: '$name $args');
      }
      return;
    }
    expect(nothing.keys, contains(name), reason: '$name is undecided');
    for (final args in <Map<String, dynamic>>[
      const {},
      const {
        'command': 'ls',
        'code': 'x',
        'argv': ['a'],
      },
    ]) {
      expect(content(args), isNull, reason: '$name says it runs nothing');
    }
  }

  test('every harness tool that runs what it may be handed is decided, '
      'with what each call runs, and every pin names one', () {
    final tools = harnessTools();
    final names = {for (final t in tools) t.name};
    // Every tool a script may call is built here and classified.
    expect(
      names,
      containsAll([
        for (final MapEntry(key: n, value: callable)
            in harnessScriptCallable.entries)
          if (callable) n,
      ]),
    );
    final decided = {...harnessRuns.keys, ...harnessRunsNothing.keys};
    expect(undecided(tools, decided), isEmpty);
    final inSet = {
      for (final t in tools)
        if (runsWhatItIsHanded(t)) t.name,
    };
    expect(decided, inSet, reason: 'a pin names a tool outside the set');
    for (final t in tools.where(runsWhatItIsHanded)) {
      expectDecided(t.name, t.executedContent, harnessRuns, harnessRunsNothing);
    }
    // Decided on purpose: the evaluation's `complete_goal` records a claim
    // and its `submit_output` keeps an answer; neither runs what it is
    // handed, and neither is of the exec tier or spawns a process.
    for (final name in ['complete_goal', 'submit_output']) {
      final tool = tools.singleWhere((t) => t.name == name);
      expect(runsWhatItIsHanded(tool), isFalse, reason: name);
      expect(tool.executedContent(const {'command': 'ls'}), isNull);
    }
    // Non-vacuity: the bash wrapper of a controlled evaluation is in the
    // set and answered for the tool it wraps.
    expect(
      tools.whereType<ControlledEvaluationBashTool>().single.executedContent(
        const {'command': 'ls -la'},
      ),
      'ls -la',
    );
  });

  test('a tool of the exec tier that states nothing fails the pin', () {
    final decided = {...harnessRuns.keys, ...harnessRunsNothing.keys};
    expect(undecided([...harnessTools(), _Unpinned()], decided), ['unpinned']);
  });

  group('the MCP lane', () {
    late GlobalDatabase global;
    late WorkspaceDatabaseManager dbs;

    setUp(() {
      global = createTestGlobalDatabase();
      dbs = createTestWorkspaceDatabases(global: global);
    });
    tearDown(() async {
      await dbs.closeAll();
      await global.close();
    });

    List<McpTool> mcpTools() {
      final registry = buildTestServerMcpRegistry(global: global, dbs: dbs);
      final environments = _NoEnvironments();
      final rigs = _NoRigs();
      return [
        for (final name in registry.toolNames(view: McpToolView.shared))
          registry.lookup(name, view: McpToolView.shared)!,
        // The tools that need live services, which the registry above
        // leaves out.
        EnvironmentUpTool(environments: environments),
        EnvironmentDownTool(environments: environments),
        EnvironmentResetTool(environments: environments),
        EnvironmentDestroyTool(environments: environments),
        EnvironmentRestartTool(environments: environments),
        EnvironmentExecTool(environments: environments),
        EnvironmentRunTaskTool(environments: environments),
        EnvironmentLaunchAppTool(environments: environments),
        EnvironmentStopAppTool(environments: environments),
        EnvironmentStatusTool(environments: environments),
        EnvironmentLogsTool(environments: environments),
        ComputerUseTool(rigs: rigs),
        AppUseTool(rigs: rigs),
        BrowserUseTool(rigs: rigs),
        MobileUseTool(rigs: rigs),
        IosUseTool(rigs: rigs),
        RigListTool(rigs: rigs),
        RigCloseTool(rigs: rigs),
      ];
    }

    test('every MCP tool that runs what it may be handed is decided, with '
        'what each call runs, on both surfaces, and every pin names one', () {
      final tools = mcpTools();
      final names = {for (final t in tools) t.name};
      // The registry above leaves out tools that need live services. Every
      // script-callable tool whose class (or a class it extends) declares a
      // process spawn, host execution or the exec tier is built here, so
      // none of them goes unclassified.
      final declared = execToolNamesInSource(const [
        '../cc_mcp/lib',
        '../cc_mcp_client/lib',
        '../cc_infra/lib',
        '../cc_server_core/lib',
      ]);
      expect(declared, containsAll(['environment_exec', 'mobile_use']));
      final missing = [
        for (final n in declared)
          if ((mcpScriptCallable[n] ?? false) && !names.contains(n)) n,
      ];
      expect(missing, isEmpty, reason: 'not built, so not classified');
      final decided = {...mcpRuns.keys, ...mcpRunsNothing.keys};
      final inSet = {
        for (final t in tools)
          if (mcpRunsWhatItIsHanded(t)) t.name,
      };
      expect(inSet.difference(decided), isEmpty, reason: 'undecided');
      expect(decided.difference(inSet), isEmpty, reason: 'outside the set');
      for (final t in tools.where(mcpRunsWhatItIsHanded)) {
        expectDecided(t.name, t.executedContent, mcpRuns, mcpRunsNothing);
        // The harness bridges it with the same answer.
        final bridged = McpToolBridge(t);
        expect(runsWhatItIsHanded(bridged), isTrue, reason: t.name);
        expectDecided(t.name, bridged.executedContent, mcpRuns, mcpRunsNothing);
      }
    });

    test('an external or workspace server\'s tool is in the set and states '
        'no content: $bridgedRunsNothing', () {
      final tool = BridgedMcpTool(
        serverName: 'shell',
        remoteTool: const McpRemoteTool(
          name: 'run',
          description: 'Runs a command.',
          inputSchema: {'type': 'object'},
        ),
        invoker: (_, _, _) async => const {},
      );
      expect(mcpRunsWhatItIsHanded(tool), isTrue);
      expect(tool.executedContent(const {'command': 'rm -rf /'}), isNull);
      expect(McpToolBridge(tool).executedContent(const {'cmd': 'x'}), isNull);
    });
  });

  test('an argv is its JSON list, so no two argvs read the same', () {
    final tool = EnvironmentExecTool(environments: _NoEnvironments());
    String? of(List<String> argv) =>
        tool.executedContent({'service': 'api', 'command': argv});
    expect(of(['echo', 'a b']), isNot(of(['echo', 'a', 'b'])));
    expect(jsonDecode(of(['a"b', r'c\d'])!), ['a"b', r'c\d']);
  });
}

/// An exec-tier tool nobody pinned.
class _Unpinned extends HarnessTool {
  @override
  String get name => 'unpinned';
  @override
  String get description => 'Runs a thing.';
  @override
  Map<String, dynamic> get inputSchema => const {'type': 'object'};
  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.exec;
  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.success('ran');
}

class _NoEnvironments implements EnvironmentPort {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('no environments in this test');
}

class _NoRigs implements RigPort {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('no rigs in this test');
}

class _NoQuestions implements AgentQuestionPort {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('no questions in this test');
}

class _NoOutputs implements ToolOutputStore {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('no outputs in this test');
}

class _NoParser implements TreeSitterParser {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('no parser in this test');
}

class _NeverSpawns implements SubagentSpawner {
  @override
  Future<SubagentResult> spawn(SubagentSpawnRequest request) =>
      throw StateError('not spawned in this test');
}

class _NeverRuns implements VibeWorkerRunner {
  @override
  Future<SubagentResult> run({
    required VibeWorker worker,
    required String brief,
    required HarnessToolContext context,
    required SubagentType type,
    String? modelOverride,
  }) => throw StateError('not run in this test');
}

class _NoScripts implements CodeExecutionPort {
  @override
  CodeRunnerAvailability get availability =>
      const CodeRunnerAvailability.unavailable('test');

  @override
  Future<CodeExecutionResult> execute(
    CodeExecutionRequest request, {
    required ScriptNestedCall callNested,
    CancellationToken cancel = CancellationToken.none,
  }) => throw StateError('no scripts in this test');
}

class _NoFileSearch implements FileSearchPort {
  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw StateError('no file search in this test');
}
