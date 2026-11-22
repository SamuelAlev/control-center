import 'package:cc_harness/src/cancellation_token.dart';
import 'package:cc_harness/src/messages.dart';
import 'package:cc_harness/src/provider/llm_provider_port.dart';
import 'package:cc_harness/src/tools/action_class.dart';
import 'package:cc_harness/src/tools/tool_reentry.dart';

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
    this.refusal,
    this.structured,
    this.outcome,
    this.guardVerdict,
    this.withdrawsScripts = false,
  });

  /// Successful result text, optionally with [images] the model should see
  /// and a [structured] value a script receives instead of the text.
  factory HarnessToolResult.success(
    String content, {
    List<HarnessImageBlock> images = const [],
    Set<String> activateTools = const {},
    Object? structured,
  }) => HarnessToolResult(
    content: content,
    images: images,
    activateTools: activateTools,
    structured: structured,
  );

  /// Error result text (surfaced to the model as an errored tool result).
  factory HarnessToolResult.error(String message) =>
      HarnessToolResult(content: message, isError: true);

  /// A refusal the host has a name for: an error result carrying [refusal]
  /// (see [ReadOnlyRoot.refusal]).
  factory HarnessToolResult.refused(
    String message,
    Map<String, Object?> refusal,
  ) => HarnessToolResult(content: message, isError: true, refusal: refusal);

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

  /// Why the call was refused, in the host's own terms (for Control Center,
  /// `{kind, level}` error data), when it was refused for a reason the host
  /// named; null otherwise.
  final Map<String, Object?>? refusal;

  /// The result as a JSON-serialisable value (maps, lists, strings, numbers,
  /// booleans and null only), shaped by [HarnessTool.outputSchema], or null
  /// when the tool has none.
  ///
  /// The model never sees it: [content] stays what the model reads. A script
  /// calling the tool through a [ToolReentry] gets this value instead, so it
  /// can filter the fields it needs rather than parsing the text the tool
  /// formatted for a model.
  final Object? structured;

  /// How the call ended when that is finer than ok or error, as a short
  /// lower-snake word ([ToolOutcome] names the gate's own): `denied` for a
  /// refusal the gate produced, `cancelled` or `timed_out` where the loop
  /// ended the call that way, or a tool's own status (a script's execution
  /// status). Null when there is nothing finer to say.
  ///
  /// It is what a transcript records and a client reads to tell a refusal
  /// from a failure, instead of parsing [content].
  final String? outcome;

  /// What the tool's own guard decided, for a tool that guards itself
  /// ([HarnessTool.selfGuards]) and asked a person or refused the call:
  /// [ToolGateVerdict.approved] when a person approved every card raised for
  /// the call (its own, or one the host raised for something the call did),
  /// [ToolGateVerdict.denied] when its guard refused the call or a person
  /// declined one of those cards, with the reason in [content]. Null when
  /// it asked nobody and let the call through. The loop's gate records this
  /// as the call's decision when its own was a plain allow, so a script's
  /// record says what actually let the tool act or stopped it.
  final ToolGateVerdict? guardVerdict;

  /// Whether the run's scripts can no longer run: set by the run's script
  /// tool when the host refused a script for a reason no other script would
  /// have escaped (the server is busy, cannot record it, runs no scripts).
  /// The loop then makes the run's script-only tools callable directly, as
  /// deferred tools that load on first use, for the rest of the run. It
  /// widens nothing: those tools were admitted to the run, and a direct call
  /// passes the same gate a script's call does.
  final bool withdrawsScripts;

  /// This result with [outcome] set, every other field kept.
  HarnessToolResult withOutcome(String? outcome) => HarnessToolResult(
    content: content,
    isError: isError,
    images: images,
    activateTools: activateTools,
    refusal: refusal,
    structured: structured,
    outcome: outcome,
    guardVerdict: guardVerdict,
    withdrawsScripts: withdrawsScripts,
  );
}

/// The [HarnessToolResult.outcome] words the loop's gate sets.
// ignore: avoid_classes_with_only_static_members
abstract final class ToolOutcome {
  /// The gate refused the call: a policy hook, an approver, no approver, or
  /// a person declining.
  static const String denied = 'denied';

  /// The loop ended the call because the run or its caller stopped waiting.
  static const String cancelled = 'cancelled';

  /// The loop abandoned the call at its time limit.
  static const String timedOut = 'timed_out';
}

/// A directory inside the workspace the run may read but not change, and what
/// a tool tells the model when it refuses a change there.
///
/// The host decides which directories these are; the file-changing tools
/// refuse any path under one, symlinks resolved.
class ReadOnlyRoot {
  /// Creates a [ReadOnlyRoot].
  const ReadOnlyRoot({
    required this.path,
    required this.reason,
    this.refusal = const {},
  });

  /// The directory.
  final String path;

  /// Shown to the model with the refused path.
  final String reason;

  /// Carried on the refusal as [HarnessToolResult.refusal].
  final Map<String, Object?> refusal;
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
    this.readOnlyRoots = const [],
    this.agentId,
    this.workspaceId,
    this.conversationId,
    this.spaceId,
    this.cancel,
    this.toolCallId,
    this.parentToolCallId,
    this.reentry,
    this.personWait,
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

  /// Directories inside the workspace the file-changing tools refuse to
  /// change. Reading them is unaffected.
  final List<ReadOnlyRoot> readOnlyRoots;

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

  /// Id of the call that made this one through its [ToolReentry], or null for
  /// a call the model issued itself. Lets a tool tell that a script called it
  /// and which call ran that script; the same value as
  /// `ToolCallOrigin.parentToolUseId`.
  final String? parentToolCallId;

  /// The gate through which this call may call the run's other tools, or null
  /// when it may not.
  ///
  /// The loop sets it for each call the model makes and leaves it null for a
  /// call made through a reentry, so a script cannot start a script and a tool
  /// called from a script cannot bridge any further: the call tree stays two
  /// levels deep and every nested call passed the gate a direct call passes.
  final ToolReentry? reentry;

  /// Tells the loop when this call starts (`true`) and stops (`false`) waiting
  /// on a person, or null when nothing is listening.
  ///
  /// A tool that asks a person inside its own execution (a command runner's
  /// confirmation, say) reports the wait here, itself or through whatever it
  /// delegates to. While it waits, the call's own deadline is paused, and for
  /// a call made through a reentry so are the calling tool's deadline and the
  /// caller's clock: a person deciding is not a tool running late. Waits
  /// nest; the loop ends any wait still open when the call settles, and
  /// ignores reports that arrive after it.
  final PersonWaitListener? personWait;

  /// Returns a copy of this context with [cancel] set — used by the loop to
  /// hand its cancellation token to tools without the caller having to thread it.
  HarnessToolContext withCancel(CancellationToken? cancel) =>
      HarnessToolContext(
        workingDirectory: workingDirectory,
        sharedRoots: sharedRoots,
        readOnlyRoots: readOnlyRoots,
        agentId: agentId,
        workspaceId: workspaceId,
        conversationId: conversationId,
        spaceId: spaceId,
        cancel: cancel,
        toolCallId: toolCallId,
        parentToolCallId: parentToolCallId,
        reentry: reentry,
        personWait: personWait,
      );

  /// Returns a copy of this context scoped to the tool call [toolCallId].
  HarnessToolContext withToolCallId(String? toolCallId) => HarnessToolContext(
    workingDirectory: workingDirectory,
    sharedRoots: sharedRoots,
    readOnlyRoots: readOnlyRoots,
    agentId: agentId,
    workspaceId: workspaceId,
    conversationId: conversationId,
    spaceId: spaceId,
    cancel: cancel,
    toolCallId: toolCallId,
    parentToolCallId: parentToolCallId,
    reentry: reentry,
    personWait: personWait,
  );

  /// Returns a copy of this context whose [reentry] is exactly [reentry]; null
  /// removes it.
  HarnessToolContext withReentry(ToolReentry? reentry) => HarnessToolContext(
    workingDirectory: workingDirectory,
    sharedRoots: sharedRoots,
    readOnlyRoots: readOnlyRoots,
    agentId: agentId,
    workspaceId: workspaceId,
    conversationId: conversationId,
    spaceId: spaceId,
    cancel: cancel,
    toolCallId: toolCallId,
    parentToolCallId: parentToolCallId,
    reentry: reentry,
    personWait: personWait,
  );

  /// Returns a copy of this context whose [parentToolCallId] is exactly
  /// [parentToolCallId]; null marks a call the model issued itself.
  HarnessToolContext withParentToolCallId(String? parentToolCallId) =>
      HarnessToolContext(
        workingDirectory: workingDirectory,
        sharedRoots: sharedRoots,
        readOnlyRoots: readOnlyRoots,
        agentId: agentId,
        workspaceId: workspaceId,
        conversationId: conversationId,
        spaceId: spaceId,
        cancel: cancel,
        toolCallId: toolCallId,
        parentToolCallId: parentToolCallId,
        reentry: reentry,
        personWait: personWait,
      );

  /// Returns a copy of this context whose [personWait] is exactly
  /// [personWait]; null removes it.
  HarnessToolContext withPersonWait(PersonWaitListener? personWait) =>
      HarnessToolContext(
        workingDirectory: workingDirectory,
        sharedRoots: sharedRoots,
        readOnlyRoots: readOnlyRoots,
        agentId: agentId,
        workspaceId: workspaceId,
        conversationId: conversationId,
        spaceId: spaceId,
        cancel: cancel,
        toolCallId: toolCallId,
        parentToolCallId: parentToolCallId,
        reentry: reentry,
        personWait: personWait,
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

  /// Explicit opt-in for execution after a complete tool-use block arrives,
  /// while the provider is still generating the rest of its response.
  ///
  /// Only bounded, read-only operations with no external side effects may
  /// opt in. The loop still requires read tier, no effect classes, no
  /// self-guard, parallel safety and an uninterrupted prefix of safe calls.
  /// Merely being parallel-safe (for example a subagent) is not sufficient.
  bool get speculativeReadSafe => false;

  /// Whether a script may call this tool through a [ToolReentry].
  ///
  /// True for nearly every tool: a nested call passes the same gate a direct
  /// call passes, so allowing it widens nothing. False for a tool that only
  /// means something as the model's own move (`checkpoint` and `rewind` mark
  /// and cut the model's history), which a script would call with no effect
  /// the model could see.
  bool get scriptCallable => true;

  /// Why a script may not make this call with [args], or null when it may.
  ///
  /// For a tool a script may call ([scriptCallable]) that takes an argument
  /// a script may not use: one that assigns work to another agent run,
  /// starts or messages one. The gate asks it before the approval step, for
  /// a script's call only (never a direct call), so a
  /// refused call raises no card; the refusal is what the script reads, and
  /// it says to make the call directly instead. A bridged MCP tool answers
  /// with the MCP tool's own rule.
  String? scriptArgumentRefusal(Map<String, dynamic> args) => null;

  /// What this call runs that the caller handed it, or null when it runs
  /// nothing of the caller's: the shell command, the code cell, the program
  /// and its arguments (an argv as its JSON list), the expression.
  ///
  /// The gate audits the call as `<name>: <content>` and digests the content,
  /// and refuses a script's call whose summary is over the 16 KiB the audit
  /// stores whole, before policy or a card. A script-callable tool of the
  /// [ToolApprovalTier.exec] tier, or one that spawns a process or runs on
  /// the host, states it, or states that it runs nothing it is handed, in
  /// `script_executed_content_pin_test.dart`; a wrapper answers what it
  /// wraps.
  String? executedContent(Map<String, dynamic> args) => null;

  /// JSON Schema of [HarnessToolResult.structured], or null when the tool
  /// returns no structured value.
  ///
  /// Shown to a script author as the declaration of what a call resolves to.
  Map<String, dynamic>? get outputSchema => null;

  /// What a script receives from a completed call, in one or two sentences a
  /// script author can code against: parsed JSON (its keys and their types)
  /// or text (its line format, and where an error or an exit code shows), or
  /// null when the tool states none.
  ///
  /// `repl`'s description shows it for each direct tool a script may also
  /// call, and `describeTool` returns it. Required for every such tool by
  /// `result_note_pin_test.dart`, and each note is held to what the tool
  /// returns by a test that calls it. A wrapper answers what it wraps.
  String? get resultNote => null;

  /// Whether running this tool itself waits for a person, as a question to
  /// the user does.
  ///
  /// A nested call to such a tool takes the serial lane, so a person never
  /// faces two forms from one script at once, and the time it takes is not
  /// charged to the calling tool's deadline.
  bool get waitsOnPerson => false;

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
