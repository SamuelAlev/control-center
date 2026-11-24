import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/sandbox_spec.dart';
import 'package:cc_domain/features/code_mode/domain/ports/code_execution_port.dart';
import 'package:cc_domain/features/code_mode/domain/services/repl_tool_description.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_mode_limits.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/mcp/domain/value_objects/mcp_call_scope.dart';
import 'package:cc_harness/context.dart' show ToolOutputStore;
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/code_mode/run_script_origins.dart';
import 'package:cc_infra/src/dap/debug_session.dart';
import 'package:cc_infra/src/edit/file_edit_service.dart';
import 'package:cc_infra/src/eval/eval_kernel.dart';
import 'package:cc_infra/src/harness/ask_user_tool.dart';
import 'package:cc_infra/src/harness/ast_tools.dart';
import 'package:cc_infra/src/harness/debug_tool.dart';
import 'package:cc_infra/src/harness/diagnostics_on_write.dart';
import 'package:cc_infra/src/harness/eval_tool.dart';
import 'package:cc_infra/src/harness/harness_command_runner.dart';
import 'package:cc_infra/src/harness/harness_tool_search_tool.dart';
import 'package:cc_infra/src/harness/lsp_rename_tool.dart';
import 'package:cc_infra/src/harness/lsp_tool.dart';
import 'package:cc_infra/src/harness/mcp_tool_bridge.dart';
import 'package:cc_infra/src/harness/repl_tool.dart';
import 'package:cc_infra/src/harness/tools/apply_patch_tool.dart';
import 'package:cc_infra/src/lsp/diagnostics_ledger.dart';
import 'package:cc_infra/src/lsp/lsp_supervisor.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
import 'package:cc_infra/src/sandboxing/tool_process_launcher.dart';
import 'package:cc_natives/cc_natives.dart';

/// Builds the harness tool registry for one run: built-in tools first (so they
/// win on name collisions), then every Control Center MCP tool bridged in.
///
/// Extracted from `DispatchSession` so the SAME tool surface can be
/// materialized without a live run — the context-inspection path rebuilds it
/// headlessly to report (and show) exactly what the next dispatch would
/// advertise. There must be one builder only: a second, inspection-specific
/// assembly would drift from the surface a run actually gets.
///
/// The run always gets the MCP servers configured for its own [workspaceId]
/// (the registry's workspace layer). [personalMcpUserId] also hands it that
/// member's own servers in the workspace. Only a run that member started may
/// have those; absent, the run gets none of them, not even their names.
///
/// The caller adds the `task` tool afterwards when the run may spawn
/// subagents — nesting depth is a per-run property, so it is deliberately not
/// baked in here.
///
/// [networkEnabled] is the run's network posture, resolved from the "network
/// egress" policy rule when the run starts: a deny takes the network away from
/// the sandbox and the web tools alike.
///
/// [toolProcesses] is the `eval` kernel's launcher, [debugProcesses] the debug
/// adapter's and [lspProcesses] starts language servers and the project
/// checker. Without one, the tools that need it are not registered: they never
/// start a process any other way. [harnessSandboxSessionId] is the sandbox
/// session `bash` runs in, the one [toolProcesses] uses; with no
/// [sandboxManager], `bash` starts through [toolProcesses] or not at all.
///
/// [runLogId] and [onBehalfOfUserId] name the run and the person it acts for
/// on every guard row `bash` writes, as the harness gate names them.
///
/// [scriptOrigins] names the execution a code mode script's question or
/// command comes from; [callWaits] is the run's agent run gateway lease, where
/// `bash` registers each command so a push the gateway holds for a person
/// stops the calling tool's clocks.
///
/// [replSlot] registers the run's `repl` (code mode's script tool) as a
/// [ReplSlot]: it makes the surface admit a script tool, and [bindReplTool]
/// replaces it with the run's [ReplTool] once the surface says which tools a
/// script may call. Pass it only when the host can run scripts. The Control
/// Center MCP `repl` (the external adapters' script tool) is never bridged
/// in: a harness run's scripts run under the loop's own gate.
HarnessToolRegistry buildHarnessToolRegistry({
  required Mode mode,
  required bool networkEnabled,
  List<int> loopbackPorts = const [],
  String? environmentScope,
  required Map<String, String> env,
  String? workspaceId,
  String? agentId,
  String? conversationId,
  SandboxManager? sandboxManager,
  ConfirmationPort? confirmationPort,
  Future<List<String>> Function()? execGrantRootsResolver,
  Future<SandboxSpec> Function(String sessionId)? sandboxSpec,
  ActionGuardService? actionGuard,
  required FileSearchPort fileSearch,
  McpToolRegistry? mcpRegistry,
  String? personalMcpUserId,
  Future<List<String>> Function()? protectedPaths,
  AgentQuestionPort? agentQuestionPort,
  String? spaceId,
  String? runLogId,
  String? onBehalfOfUserId,
  String? agentDisplayName,
  LspSupervisor? lspSupervisor,
  DiagnosticsLedger? diagnosticsLedger,
  String? lspWorkingDirectory,
  TreeSitterParser? treeSitterParser,
  StagedEditStore? stagedEditStore,
  DebugSessionSupervisor? debugSupervisor,
  EvalKernel Function(KernelLanguage language)? evalKernelFor,
  ToolProcessLauncher? toolProcesses,
  ToolProcessLauncher? debugProcesses,
  ToolProcessLauncher? lspProcesses,
  String? harnessSandboxSessionId,
  ToolOutputStore? toolOutputStore,
  RunScriptOrigins? scriptOrigins,
  CommandWaitRelay? callWaits,
  bool replSlot = false,
}) {
  final commandRunner = SandboxedHarnessCommandRunner(
    sandboxSessionId: harnessSandboxSessionId,
    mode: mode,
    networkEnabled: networkEnabled,
    loopbackPorts: loopbackPorts,
    environmentScope: environmentScope,
    sandboxManager: sandboxManager,
    hostProcesses: toolProcesses,
    confirmationPort: confirmationPort,
    execGrantRootsResolver: execGrantRootsResolver,
    sandboxSpec: sandboxSpec,
    actionGuard: actionGuard,
    workspaceId: workspaceId,
    agentId: agentId,
    conversationId: conversationId,
    spaceId: spaceId,
    runId: runLogId,
    onBehalfOfUserId: onBehalfOfUserId,
    baseEnv: env,
    protectedPaths: protectedPaths,
    scriptOrigins: scriptOrigins,
    callWaits: callWaits,
  );
  // Shared hashline edit service: `read` snapshots content into it and
  // `apply_patch` recovers against those snapshots (drift-tolerant edits).
  final fileEditService = FileEditService();
  // Staged changes live for the run, shared by whatever stages and whatever
  // commits. One store, so a change staged by `ast_edit` is resolvable by the
  // same `resolve` a future staging tool would use.
  final stagedEdits = stagedEditStore ?? StagedEditStore();
  // The run's background commands: one registry per built surface, so each
  // run (a subagent's included) owns its commands and its loop kills them
  // when it ends. `bash` starts them, `bash_output`/`bash_kill` follow them
  // and `read_output` pages their output while they run.
  final backgroundCommands = BackgroundCommandRegistry(
    store: toolOutputStore,
  );
  final registry = HarnessToolRegistry()
    ..registerAll([
      ReadTool(
        onRead: fileEditService.recordSnapshot,
        hashOf: fileEditService.computeHashFor,
        // fff-backed: a read of a missing path answers with the closest
        // fuzzy matches instead of a bare not-found.
        fileSearch: fileSearch,
      ),
      WriteTool(),
      EditTool(),
      ApplyPatchTool(fileEditService),
      SearchTool(),
      FindTool(),
      FileSearchTool(fileSearch: fileSearch),
      // `todo_write` comes from the bridged MCP `TodoWriteTool` (persisted,
      // per-conversation); the bridge injects `conversation_id`.
      // Web tools honor the run's network posture and block SSRF targets.
      WebFetchTool(allowNetwork: networkEnabled),
      WebSearchTool(allowNetwork: networkEnabled),
      CheckpointTool(),
      RewindTool(),
      CompactTool(),
      BashTool(commandRunner, backgroundCommands: backgroundCommands),
      BashOutputTool(backgroundCommands),
      BashKillTool(backgroundCommands),
    ]);
  if (toolOutputStore != null) {
    registry.register(
      ToolOutputReadTool(
        toolOutputStore,
        backgroundCommands: backgroundCommands,
      ),
    );
  }
  // `ask_user` needs a port and the run's exact conversation to render the
  // form. Without all three scope ids it cannot offer a question safely.
  if (agentQuestionPort != null &&
      workspaceId != null &&
      workspaceId.isNotEmpty &&
      spaceId != null &&
      spaceId.isNotEmpty &&
      conversationId != null &&
      conversationId.isNotEmpty) {
    registry.register(
      AskUserTool(
        port: agentQuestionPort,
        workspaceId: workspaceId,
        spaceId: spaceId,
        askedByAgentId: agentId,
        conversationId: conversationId,
        askedByName: agentDisplayName,
        runId: runLogId,
        scriptOrigins: scriptOrigins,
      ),
    );
  }
  // Structural search and rewrite. Registered only with a parser AND a
  // working directory: a pattern is parsed by the grammar of the language it
  // searches, and there is nothing to search without a root.
  final astParser = treeSitterParser;
  if (astParser != null &&
      lspWorkingDirectory != null &&
      lspWorkingDirectory.isNotEmpty) {
    registry
      ..register(
        AstGrepTool(parser: astParser, workingDirectory: lspWorkingDirectory),
      )
      // Separate WRITE-tier tool for the same reason `lsp_rename` is separate
      // from `lsp`: the tier decides which surfaces SEE a tool, so a
      // read-only explorer keeps structural search without gaining a
      // repo-wide rewrite.
      ..register(
        AstEditTool(
          parser: astParser,
          workingDirectory: lspWorkingDirectory,
          store: stagedEdits,
        ),
      )
      // `resolve` is what makes staging more than a delay: it is the call the
      // approval prompt and the transcript's Accept/Discard card attach to.
      ..register(ResolveTool(stagedEdits));
  }
  // Persistent interpreters. Registered only when the host supplied a kernel
  // factory, which is where the decision of WHERE a kernel runs lives (the
  // conversation's enclosure when it has one, the host otherwise).
  final kernelFor = evalKernelFor;
  if (kernelFor != null && toolProcesses != null) {
    registry.register(
      EvalTool(kernelFor: kernelFor, hostConfined: toolProcesses.confined),
    );
  }
  // Debugger. Registered only with a supervisor AND a working directory: a
  // debug adapter is chosen by what the checkout contains, so there is nothing
  // to detect without a project root. Exec tier, so read-only surfaces (plan
  // mode, an explore subagent) never see it.
  if (debugSupervisor != null &&
      debugProcesses != null &&
      lspWorkingDirectory != null &&
      lspWorkingDirectory.isNotEmpty &&
      conversationId != null &&
      conversationId.isNotEmpty) {
    registry.register(
      DebugTool(
        supervisor: debugSupervisor,
        workingDirectory: lspWorkingDirectory,
        // One session per conversation: an agent that launches a second
        // without terminating the first has almost certainly lost track of
        // the first, and two stopped debuggees is two held ports.
        sessionKey: conversationId,
        launcher: debugProcesses,
        // `attach` reaches only what the run's sandbox may reach.
        attachablePorts: loopbackPorts,
        environment: env,
      ),
    );
  }
  // Language-server surface. Registered only when a supervisor is wired AND
  // the run has a working directory to resolve a project root from — without
  // both there is nothing to ask and no project to ask about.
  final lspRoot = lspWorkingDirectory;
  if (lspSupervisor != null &&
      lspProcesses != null &&
      lspRoot != null &&
      lspRoot.isNotEmpty) {
    final ledger = diagnosticsLedger ?? DiagnosticsLedger();
    registry
      ..register(
        LspTool(
          supervisor: lspSupervisor,
          ledger: ledger,
          workingDirectory: lspRoot,
          launcher: lspProcesses,
        ),
      )
      // Rename is a separate, WRITE-tier tool: the tier decides which
      // surfaces see a tool, so plan mode and read-only subagents get
      // navigation without the ability to rewrite the repo.
      ..register(
        LspRenameTool(
          supervisor: lspSupervisor,
          ledger: ledger,
          workingDirectory: lspRoot,
          launcher: lspProcesses,
        ),
      );
    // The real payoff is not the tool — it is that an edit answers with the
    // compiler's opinion without the agent having to remember to ask. Wrapping
    // rather than modifying the write tools keeps `cc_harness_runtime` free of
    // any LSP knowledge.
    for (final toolName in const ['write', 'edit', 'apply_patch']) {
      final inner = registry.findByName(toolName);
      if (inner != null) {
        // `register` is putIfAbsent (first-wins), and the wrapper reports the
        // SAME name as the tool it wraps — so registering it over an existing
        // entry silently did nothing and no write ever came back with the
        // compiler's opinion. Drop the inner registration first.
        registry
          ..unregister(toolName)
          ..register(
            DiagnosticsOnWriteTool(
              inner: inner,
              supervisor: lspSupervisor,
              ledger: ledger,
              workingDirectory: lspRoot,
              launcher: lspProcesses,
            ),
          );
      }
    }
  }
  if (mcpRegistry != null) {
    // Arguments the bridge fills from the run's context are hidden from the
    // model-facing schema — but only the ones this run can actually supply.
    // `agent_id` is hidden only for tools that FORCE it to the caller: other
    // tools use it as a target the model must remain able to choose.
    final hiddenScopeParams = <String>{
      if (workspaceId != null && workspaceId.isNotEmpty) 'workspace_id',
      if (conversationId != null && conversationId.isNotEmpty) ...{
        'conversation_id',
        McpCallScope.callerConversationKey,
      },
      if (spaceId != null && spaceId.isNotEmpty) 'space_id',
      if (agentId != null && agentId.isNotEmpty)
        ...McpCallScope.callerIdentityKeys,
    };
    // The run's own workspace's configured servers, and the own servers of
    // the member who started it.
    final view = McpToolView(
      workspaceId: workspaceId,
      personalUserId: personalMcpUserId,
    );
    for (final toolName in mcpRegistry.toolNames(view: view)) {
      if (toolName == ReplToolDescription.toolName) {
        continue;
      }
      final mcpTool = mcpRegistry.lookup(toolName, view: view);
      if (mcpTool != null) {
        registry.register(
          McpToolBridge(
            mcpTool,
            hiddenScopeParams:
                agentId != null &&
                    agentId.isNotEmpty &&
                    mcpTool.forcedScopeKeys.contains('agent_id')
                ? {...hiddenScopeParams, 'agent_id'}
                : hiddenScopeParams,
            runLogId: runLogId,
          ),
        );
      }
    }
  }
  if (replSlot) {
    registry.register(ReplSlot());
  }
  return registry;
}

/// A run's `repl` before the run's tool surface is known.
///
/// A [ReplTool] is built for the tools a script may call, and
/// that set is the run's admitted surface, which exists only after the
/// mode's filter has run over a registry that already holds the script tool
/// (the surface admits code mode only for a registry with a `repl`). So the
/// registry holds this slot, with the same name, tier and effects as the
/// real tool, and [bindReplTool] swaps in the run's [ReplTool] afterwards.
/// A slot that reaches a loop unbound refuses every call.
class ReplSlot extends HarnessTool {
  /// Creates the slot.
  ReplSlot();

  @override
  String get name => ReplToolDescription.toolName;

  @override
  String get description =>
      "Runs a script. Not available: this run's script tool was not set up.";

  @override
  Map<String, dynamic> get inputSchema => ReplToolDescription.inputSchema();

  @override
  ToolApprovalTier get approvalTier => ToolApprovalTier.read;

  @override
  bool get selfGuards => true;

  @override
  Set<ActionClass> get actionClasses => const {};

  @override
  bool get parallelSafe => false;

  @override
  bool get scriptCallable => false;

  @override
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  ) async => HarnessToolResult.error(
    'repl is not available in this run: its script tool was not set up.',
  );
}

/// What a run needs to turn its [ReplSlot] into a [ReplTool].
class ReplBinding {
  /// Creates a binding.
  const ReplBinding({
    required this.executions,
    required this.run,
    required this.limits,
    this.fullOutputSink,
  });

  /// The execution service, as the run sees it.
  final CodeExecutionPort executions;

  /// Whose scripts these are, and where their records go.
  final ReplRunIdentity run;

  /// The workspace's script limits.
  final CodeModeLimits limits;

  /// Stores a result's full output so `read_output` can page through it.
  final ReplFullOutputSink? fullOutputSink;
}

/// [resident] without its `repl`, with [scriptOnly] made resident so the
/// run keeps every tool: for a run whose scripts could not be recorded (it
/// has no run-log row), which therefore runs none. Its `search_tools`, if it
/// has one, then finds those tools as loaded rather than pointing at a
/// script the run cannot write.
List<HarnessTool> withoutReplTool({
  required List<HarnessTool> resident,
  List<HarnessTool> scriptOnly = const [],
}) => List.unmodifiable([
  for (final tool in resident)
    if (tool is HarnessToolSearchTool)
      tool.withScriptOnlyResident(scriptOnly)
    else if (tool.name != ReplToolDescription.toolName)
      tool,
  ...scriptOnly,
]);

/// [resident] with its `repl` (a [ReplSlot], or a [ReplTool] bound for
/// another surface) replaced by a [ReplTool] for [binding]'s run, or
/// [resident] unchanged when it has no `repl` (the server runs no scripts).
///
/// The tool's callable tools are exactly what the loop admits for a nested
/// call: [resident] and [scriptOnly] ([ReplTool] drops the tools no script
/// may call). The [resident] tools are the direct tools: the description
/// gives each one's result note, not its schema, which is in the request. Bind after the last
/// change to the lists the loop gets (the `/vibe` orchestrator narrows
/// them), so the script catalog never names a tool the gate refuses. The
/// run's `search_tools`, if it has one, is rebound to the same [scriptOnly]
/// for the same reason.
List<HarnessTool> bindReplTool({
  required List<HarnessTool> resident,
  List<HarnessTool> scriptOnly = const [],
  required ReplBinding binding,
}) {
  final at = resident.indexWhere(
    (tool) => tool.name == ReplToolDescription.toolName,
  );
  if (at < 0) {
    return resident;
  }
  final others = [
    for (final tool in resident)
      if (tool.name != ReplToolDescription.toolName) tool,
  ];
  // The run's script state, shared by its `repl` and its `search_tools`.
  final lane = ReplLane(
    hasSearch: resident.any((tool) => tool is HarnessToolSearchTool),
  );
  final repl = ReplTool(
    executor: binding.executions,
    run: binding.run,
    callableTools: [...others, ...scriptOnly],
    limits: binding.limits,
    directToolNames: {for (final tool in others) tool.name},
    fullOutputSink: binding.fullOutputSink,
    lane: lane,
  );
  return List.unmodifiable([
    for (var i = 0; i < resident.length; i++)
      switch (resident[i]) {
        _ when i == at => repl,
        final HarnessToolSearchTool search => search.withScriptOnly(
          scriptOnly,
          lane: lane,
        ),
        final tool => tool,
      },
  ]);
}
