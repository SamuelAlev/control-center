import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_domain/core/domain/ports/confirmation_port.dart';
import 'package:cc_domain/core/domain/value_objects/agent_capabilities.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/features/guardrails/domain/services/action_guard_service.dart';
import 'package:cc_domain/features/mcp/domain/services/mcp_tool_registry.dart';
import 'package:cc_domain/features/sandboxing/domain/services/sandbox_exec_grant_service.dart';
import 'package:cc_harness/tools.dart';
import 'package:cc_harness_runtime/cc_harness_runtime.dart';
import 'package:cc_infra/src/dap/debug_session.dart';
import 'package:cc_infra/src/edit/file_edit_service.dart';
import 'package:cc_infra/src/eval/eval_kernel.dart';
import 'package:cc_infra/src/harness/ask_user_tool.dart';
import 'package:cc_infra/src/harness/ast_tools.dart';
import 'package:cc_infra/src/harness/debug_tool.dart';
import 'package:cc_infra/src/harness/diagnostics_on_write.dart';
import 'package:cc_infra/src/harness/eval_tool.dart';
import 'package:cc_infra/src/harness/harness_command_runner.dart';
import 'package:cc_infra/src/harness/lsp_rename_tool.dart';
import 'package:cc_infra/src/harness/lsp_tool.dart';
import 'package:cc_infra/src/harness/mcp_tool_bridge.dart';
import 'package:cc_infra/src/harness/tools/apply_patch_tool.dart';
import 'package:cc_infra/src/lsp/diagnostics_ledger.dart';
import 'package:cc_infra/src/lsp/lsp_supervisor.dart';
import 'package:cc_infra/src/sandboxing/sandbox_manager.dart';
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
/// The caller adds the `task` tool afterwards when the run may spawn
/// subagents — nesting depth is a per-run property, so it is deliberately not
/// baked in here.
HarnessToolRegistry buildHarnessToolRegistry({
  required Mode mode,
  required AgentCapabilities caps,
  required Map<String, String> env,
  String? workspaceId,
  String? agentId,
  String? conversationId,
  SandboxManager? sandboxManager,
  ConfirmationPort? confirmationPort,
  SandboxExecGrantService? execGrantService,
  ActionGuardService? actionGuard,
  required FileSearchPort fileSearch,
  McpToolRegistry? mcpRegistry,
  Future<List<String>> Function()? protectedPaths,
  AgentQuestionPort? agentQuestionPort,
  String? spaceId,
  String? agentDisplayName,
  LspSupervisor? lspSupervisor,
  DiagnosticsLedger? diagnosticsLedger,
  String? lspWorkingDirectory,
  TreeSitterParser? treeSitterParser,
  StagedEditStore? stagedEditStore,
  DebugSessionSupervisor? debugSupervisor,
  EvalKernel Function(KernelLanguage language)? evalKernelFor,
}) {
  final commandRunner = SandboxedHarnessCommandRunner(
    mode: mode,
    capabilities: caps,
    sandboxManager: sandboxManager,
    confirmationPort: confirmationPort,
    execGrantService: execGrantService,
    actionGuard: actionGuard,
    workspaceId: workspaceId,
    agentId: agentId,
    conversationId: conversationId,
    baseEnv: env,
    protectedPaths: protectedPaths,
  );
  // Shared hashline edit service: `read` snapshots content into it and
  // `apply_patch` recovers against those snapshots (drift-tolerant edits).
  final fileEditService = FileEditService();
  // Staged changes live for the run, shared by whatever stages and whatever
  // commits. One store, so a change staged by `ast_edit` is resolvable by the
  // same `resolve` a future staging tool would use.
  final stagedEdits = stagedEditStore ?? StagedEditStore();
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
      // Web tools honor the agent's network capability and block SSRF targets.
      WebFetchTool(allowNetwork: caps.canAccessNetwork),
      WebSearchTool(allowNetwork: caps.canAccessNetwork),
      CheckpointTool(),
      RewindTool(),
      BashTool(commandRunner),
    ]);
  // `ask_user` needs somewhere to render the form and someone to answer it, so
  // it is offered ONLY when both a port and a target space exist. Registering
  // it without them would advertise a tool whose every call ends in a timeout.
  if (agentQuestionPort != null &&
      workspaceId != null &&
      workspaceId.isNotEmpty &&
      spaceId != null &&
      spaceId.isNotEmpty) {
    registry.register(
      AskUserTool(
        port: agentQuestionPort,
        workspaceId: workspaceId,
        spaceId: spaceId,
        askedByAgentId: agentId,
        askedByName: agentDisplayName,
      ),
    );
  }
  // Structural search and rewrite. Registered only with a parser AND a
  // working directory: a pattern is parsed by the grammar of the language it
  // searches, and there is nothing to search without a root.
  final astParser = treeSitterParser;
  if (astParser != null && lspWorkingDirectory != null &&
      lspWorkingDirectory.isNotEmpty) {
    registry
      ..register(
        AstGrepTool(
          parser: astParser,
          workingDirectory: lspWorkingDirectory,
        ),
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
  if (kernelFor != null) {
    registry.register(EvalTool(kernelFor: kernelFor));
  }
  // Debugger. Registered only with a supervisor AND a working directory: a
  // debug adapter is chosen by what the checkout contains, so there is nothing
  // to detect without a project root. Exec tier, so read-only surfaces (plan
  // mode, an explore subagent) never see it.
  if (debugSupervisor != null &&
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
        environment: env,
      ),
    );
  }
  // Language-server surface. Registered only when a supervisor is wired AND
  // the run has a working directory to resolve a project root from — without
  // both there is nothing to ask and no project to ask about.
  final lspRoot = lspWorkingDirectory;
  if (lspSupervisor != null && lspRoot != null && lspRoot.isNotEmpty) {
    final ledger = diagnosticsLedger ?? DiagnosticsLedger();
    registry
      ..register(
        LspTool(
          supervisor: lspSupervisor,
          ledger: ledger,
          workingDirectory: lspRoot,
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
            ),
          );
      }
    }
  }
  if (mcpRegistry != null) {
    // Arguments the bridge fills from the run's context are hidden from the
    // model-facing schema — but only the ones this run can actually supply.
    // `agent_id` is deliberately NOT hidden: on some tools it names the CALLER
    // ("your own agent id") and on others a TARGET ("agent to assign"), so the
    // model must stay able to choose it.
    final hiddenScopeParams = <String>{
      if (workspaceId != null && workspaceId.isNotEmpty) 'workspace_id',
      if (conversationId != null && conversationId.isNotEmpty)
        'conversation_id',
      if (spaceId != null && spaceId.isNotEmpty) 'space_id',
    };
    for (final toolName in mcpRegistry.toolNames) {
      final mcpTool = mcpRegistry.lookup(toolName);
      if (mcpTool != null) {
        registry.register(
          McpToolBridge(mcpTool, hiddenScopeParams: hiddenScopeParams),
        );
      }
    }
  }
  return registry;
}
