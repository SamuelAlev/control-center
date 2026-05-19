import 'package:cc_harness/src/cancellation_token.dart';
import 'package:cc_harness/src/messages.dart';
import 'package:cc_harness/src/provider/llm_provider_port.dart';
import 'package:cc_harness/src/tools/action_class.dart';

/// Approval sensitivity of a [HarnessTool], used to gate execution.
///
/// Maps onto Control Center's confirmation + command-policy stack:
/// * [read]  — never prompts (file reads, search, glob, list).
/// * [write] — prompts via the confirmation flow (file writes, data mutations).
/// * [exec]  — runs code / commands; the command policy decides allow / prompt /
///   deny per command, so an [exec] tool may self-guard (see
///   [HarnessTool.selfGuards]).
enum ToolApprovalTier {
  /// Read-only; safe to run without confirmation.
  read,

  /// Mutates state; requires confirmation.
  write,

  /// Executes commands / code; gated by the command policy.
  exec,
}

/// The outcome of running a [HarnessTool]. Tools never throw — they always
/// return a result so the loop has something to feed back to the model.
class HarnessToolResult {
  /// Creates a result.
  const HarnessToolResult({
    required this.content,
    this.isError = false,
    this.images = const [],
    this.activateTools = const {},
  });

  /// Successful result text, optionally with [images] the model should see.
  factory HarnessToolResult.success(
    String content, {
    List<HarnessImageBlock> images = const [],
    Set<String> activateTools = const {},
  }) => HarnessToolResult(
    content: content,
    images: images,
    activateTools: activateTools,
  );

  /// Error result text (surfaced to the model as an errored tool result).
  factory HarnessToolResult.error(String message) =>
      HarnessToolResult(content: message, isError: true);

  /// Result text shown to the model.
  final String content;

  /// Whether the call failed.
  final bool isError;

  /// Images returned alongside [content] — screenshots from an enclosure
  /// (rig), rendered output, visual diffs. Empty for nearly every tool.
  ///
  /// Text stays the primary channel: a tool that returns an image should also
  /// describe what it captured, so a text-only provider (or a compacted
  /// transcript, which drops images first) still carries the meaning.
  final List<HarnessImageBlock> images;

  /// Deferred tools whose schemas the loop should load for the rest of the run.
  ///
  /// This is how a tool-search tool makes its hits callable: it answers with the
  /// matches AND asks for their schemas, so the model can call one on its very
  /// next turn instead of spending a round trip asking for them. The loop
  /// ignores names that are not deferred (already resident, or not on this
  /// run's surface at all) — a tool cannot widen its own run's permissions by
  /// naming something the surface denied.
  final Set<String> activateTools;
}

/// Per-run context handed to every tool: where it runs and on whose behalf.
///
/// [workspaceId] is what keeps tools inside the workspace-isolation boundary —
/// every workspace-scoped tool (memory, tickets, messaging, …) scopes its
/// reads and writes to it.
class HarnessToolContext {
  /// Creates a tool context.
  const HarnessToolContext({
    required this.workingDirectory,
    this.sharedRoots = const [],
    this.agentId,
    this.workspaceId,
    this.conversationId,
    this.spaceId,
    this.cancel,
    this.toolCallId,
  });

  /// The current working directory for filesystem and command tools.
  final String workingDirectory;

  /// Extra directories that are part of the workspace boundary alongside
  /// [workingDirectory]. Filesystem tools accept paths inside any of them.
  ///
  /// Used for the per-conversation shared `repos/` worktrees dir: the overlay
  /// cwd reaches it only through a `repos → ../../repos` symlink, so its real
  /// path is outside the cwd and would otherwise be refused — even for reads.
  final List<String> sharedRoots;

  /// The agent running the loop, when known.
  final String? agentId;

  /// The workspace the run belongs to, when known.
  final String? workspaceId;

  /// The conversation the run belongs to, when known.
  final String? conversationId;

  /// The SPACE that conversation lives in, when known.
  ///
  /// Carried separately from [conversationId] on purpose: a conversation owns
  /// its own uuid, so it names no space. Space-scoped tool arguments
  /// (`todo_write` / `todo_read`, whose lists hang off the space's worktree)
  /// are filled from this, never from the conversation id.
  final String? spaceId;

  /// The run's cancellation signal, when known. Long-running tools (bash, web
  /// fetch) observe it so a cancelled run kills work in flight instead of
  /// waiting for the tool's own timeout.
  final CancellationToken? cancel;

  /// Id of the tool call currently executing, when known.
  ///
  /// Set by the loop per invocation. The `task` tool passes it down so a spawned
  /// subagent run can record which tool row spawned it, letting that row in the
  /// parent's transcript open the child's own activity.
  final String? toolCallId;

  /// Returns a copy of this context with [cancel] set — used by the loop to
  /// hand its cancellation token to tools without the caller having to thread it.
  HarnessToolContext withCancel(CancellationToken? cancel) =>
      HarnessToolContext(
        workingDirectory: workingDirectory,
        sharedRoots: sharedRoots,
        agentId: agentId,
        workspaceId: workspaceId,
        conversationId: conversationId,
        spaceId: spaceId,
        cancel: cancel,
        toolCallId: toolCallId,
      );

  /// Returns a copy of this context scoped to the tool call [toolCallId].
  HarnessToolContext withToolCallId(String? toolCallId) => HarnessToolContext(
    workingDirectory: workingDirectory,
    sharedRoots: sharedRoots,
    agentId: agentId,
    workspaceId: workspaceId,
    conversationId: conversationId,
    spaceId: spaceId,
    cancel: cancel,
    toolCallId: toolCallId,
  );
}

/// A tool the agent loop can call.
///
/// Built-in tools (read / write / edit / bash / search / find) and bridged
/// Control Center MCP tools both implement this interface, so the loop treats
/// every tool uniformly.
abstract class HarnessTool {
  /// Stable tool name the model calls (e.g. `read`, `bash`, `recall_facts`).
  String get name;

  /// Description shown to the model.
  String get description;

  /// JSON Schema for the tool's arguments.
  Map<String, dynamic> get inputSchema;

  /// Approval tier governing confirmation.
  ToolApprovalTier get approvalTier;

  /// When true the tool enforces its own policy / confirmation internally and
  /// the loop must NOT also fire the approval callback (avoids double prompts).
  /// The sandboxed `bash` tool sets this because the command policy already
  /// decides allow / prompt / deny per command at a finer granularity.
  bool get selfGuards => false;

  /// Whether sibling calls to this tool inside one turn may run concurrently.
  ///
  /// Defaults to read-tier tools that do not guard themselves: those have no
  /// side effects and never prompt, so ordering among them is irrelevant. A
  /// self-guarding read tool overrides this to opt back in — the `task` tool
  /// does, because its gating happens on the *child's* tools, leaving the loop
  /// with nothing to serialize. Without the override a model that emits N
  /// `task` calls in one turn gets them run strictly one at a time, which
  /// defeats the point of asking for parallel subagents.
  bool get parallelSafe => approvalTier == ToolApprovalTier.read && !selfGuards;

  /// The unified-guardrail effect classes this tool can produce (PRD 24 §1).
  /// Every tool DECLARES its worst-case classes; a ratchet test holds the line.
  /// The default is derived conservatively from [approvalTier] (exec ⇒ process
  /// spawn, write ⇒ file writes); tools with more specific effects (delete, PR
  /// create, network, secrets) override this.
  Set<ActionClass> get actionClasses {
    switch (approvalTier) {
      case ToolApprovalTier.exec:
        return const {ActionClass.processSpawn};
      case ToolApprovalTier.write:
        return const {ActionClass.fileWriteOutsideWorktree};
      case ToolApprovalTier.read:
        return const {};
    }
  }

  /// Runs the tool. Must not throw — return [HarnessToolResult.error] instead.
  Future<HarnessToolResult> execute(
    Map<String, dynamic> args,
    HarnessToolContext context,
  );

  /// Converts to the provider-facing schema.
  LlmToolSchema toSchema() => LlmToolSchema(
    name: name,
    description: description,
    inputSchema: inputSchema,
  );
}
