import 'package:cc_harness/src/cancellation_token.dart';
import 'package:cc_harness/src/context/harness_compaction.dart';
import 'package:cc_harness/src/loop/advisor.dart';
import 'package:cc_harness/src/loop/agent_loop_hooks.dart';
import 'package:cc_harness/src/loop/completion_contract.dart';
import 'package:cc_harness/src/loop/pause_gate.dart';
import 'package:cc_harness/src/loop/steering_queue.dart';
import 'package:cc_harness/src/loop/stream_rules.dart';
import 'package:cc_harness/src/loop/transcript_store.dart';
import 'package:cc_harness/src/messages.dart';
import 'package:cc_harness/src/provider/llm_provider_port.dart';
import 'package:cc_harness/src/provider/reasoning_effort.dart';
import 'package:cc_harness/src/tools/tool.dart';

/// Events emitted by the agent loop as it runs.
///
/// The loop is event-sourced: it emits typed events rather than raw text, so
/// the UI can render streaming text, thinking blocks and tool-call cards and
/// the dispatch layer can translate them into Control Center process events.
sealed class AgentLoopEvent {
  /// Const base constructor.
  const AgentLoopEvent();
}

/// Streamed assistant text.
class LoopTextDelta extends AgentLoopEvent {
  /// Creates a text delta event.
  const LoopTextDelta(this.text);

  /// The incremental text.
  final String text;
}

/// Streamed extended-thinking text.
class LoopThinkingDelta extends AgentLoopEvent {
  /// Creates a thinking delta event.
  const LoopThinkingDelta(this.thinking);

  /// The incremental reasoning text.
  final String thinking;
}

/// A tool is about to execute.
class LoopToolCallStart extends AgentLoopEvent {
  /// Creates a tool-call-start event.
  const LoopToolCallStart({
    required this.toolName,
    required this.toolUseId,
    required this.args,
  });

  /// Name of the tool being called.
  final String toolName;

  /// Tool-call id (pairs with [LoopToolCallResult.toolUseId]).
  final String toolUseId;

  /// Decoded arguments.
  final Map<String, dynamic> args;
}

/// A tool finished executing.
class LoopToolCallResult extends AgentLoopEvent {
  /// Creates a tool-call-result event.
  const LoopToolCallResult({
    required this.toolName,
    required this.toolUseId,
    required this.result,
  });

  /// Name of the tool that ran.
  final String toolName;

  /// Tool-call id (pairs with [LoopToolCallStart.toolUseId]).
  final String toolUseId;

  /// The tool result.
  final HarnessToolResult result;
}

/// A full assistant turn has been assembled and appended to history.
class LoopTurnComplete extends AgentLoopEvent {
  /// Creates a turn-complete event.
  const LoopTurnComplete(this.message);

  /// The assistant message that was appended.
  final HarnessMessage message;
}

/// Token usage for a turn.
class LoopUsage extends AgentLoopEvent {
  /// Creates a usage event.
  const LoopUsage(this.usage);

  /// The usage report.
  final LlmUsage usage;
}

/// An advisor (secondary model) injected a steering note before the next turn.
class LoopAdvisorNote extends AgentLoopEvent {
  /// Creates an advisor-note event.
  const LoopAdvisorNote(this.note, {this.severity = AdvisorSeverity.nit});

  /// The advisor's note text.
  final String note;

  /// How strongly the advisor weighed it.
  final AdvisorSeverity severity;
}

/// Deferred tools were loaded into the request for the rest of the run.
///
/// Emitted so the search → activate → call funnel is observable: a search that
/// activates nothing is a retrieval miss, and a miss is invisible otherwise —
/// the agent just does something adjacent and plausible instead.
class LoopToolsActivated extends AgentLoopEvent {
  /// Creates a tools-activated event.
  const LoopToolsActivated({required this.names, required this.trigger});

  /// Tool names whose schemas are now being sent, in activation order.
  final List<String> names;

  /// What caused the activation: `direct_call` (the model called a deferred
  /// tool by name) or the name of the tool that requested it (`search_tools`).
  final String trigger;
}

/// A steering / status note the loop injects for the UI (e.g. budget pressure).
class LoopNotice extends AgentLoopEvent {
  /// Creates a notice event.
  const LoopNotice(this.message);

  /// The note text.
  final String message;
}

/// The conversation history was compacted (or pruned) to fit the context window.
class LoopCompaction extends AgentLoopEvent {
  /// Creates a compaction event.
  const LoopCompaction({
    required this.summarized,
    required this.messagesFolded,
    required this.tokensBefore,
    required this.tokensAfter,
  });

  /// True when an anchored summary was produced; false for a prune-only pass.
  final bool summarized;

  /// Number of messages folded into the summary.
  final int messagesFolded;

  /// Estimated live tokens before the pass.
  final int tokensBefore;

  /// Estimated live tokens after the pass.
  final int tokensAfter;
}

/// The loop finished.
class LoopDone extends AgentLoopEvent {
  /// Creates a done event.
  const LoopDone(this.reason, {this.unmetContractId});

  /// Why the loop ended.
  final LoopDoneReason reason;

  /// The [CompletionContract.id] the run failed to satisfy, or null when there
  /// was no contract or it was discharged.
  ///
  /// Carried alongside every terminal reason, not just
  /// [LoopDoneReason.contractUnmet]: "ran out of turns without delivering" and
  /// "ran out of turns after delivering" are different products and the
  /// primary cause should stay honest.
  final String? unmetContractId;
}

/// The loop hit an unrecoverable error.
class LoopError extends AgentLoopEvent {
  /// Creates an error event.
  const LoopError(this.message, {this.code});

  /// Human-readable message.
  final String message;

  /// Machine-readable classification, when available.
  final String? code;
}

/// Why the loop stopped.
enum LoopDoneReason {
  /// Model finished with no pending tool calls.
  completed,

  /// Hit the max-turns ceiling.
  maxTurns,

  /// The model stopped without ever satisfying the run's
  /// [CompletionContract] — it produced no deliverable. Distinct from
  /// [completed], which now means "finished AND delivered".
  contractUnmet,

  /// The goal budget was exhausted.
  budgetExhausted,

  /// Cancelled by the caller.
  cancelled,

  /// The provider billed output tokens for a turn but delivered almost none of
  /// them and cut the turn off at the output ceiling — the signature of a
  /// server-side tool-call parser discarding a buffer it never saw closed.
  ///
  /// Distinct from [error] because the remedy is a configuration or provider
  /// change, not a retry: re-issuing the same request at the same ceiling
  /// reproduces it exactly.
  providerOutputLost,

  /// Stopped due to an error.
  error,
}

/// Tool names the loop handles ITSELF (context control), rather than dispatching
/// to a tool's `execute` — they manipulate the loop's own history.
const Set<String> harnessControlToolNames = {'checkpoint', 'rewind'};

/// The outcome of gating a tool call, with the reason attached.
///
/// A bare bool destroyed information the model needed: the policy layer builds
/// a precise reason ("orchestrate mode denies vendorSyncWrite") and the model
/// used to receive only `Denied by user.` — so it could neither replan nor tell
/// a policy denial from a human one. Carrying the reason is the difference
/// between an agent that adapts and one that narrates giving up.
class ToolGateDecision {
  /// Allows the call.
  const ToolGateDecision.allow()
    : allowed = true,
      reason = '',
      remediation = null;

  /// Denies the call, optionally explaining why and what to do instead.
  const ToolGateDecision.deny({this.reason = '', this.remediation})
    : allowed = false;

  /// Whether the call may proceed.
  final bool allowed;

  /// Why the call was denied. Empty renders the legacy `Denied by user.`
  /// message, which keeps recorded sessions byte-compatible.
  final String reason;

  /// What the agent should do instead, when there is a sanctioned alternative.
  final String? remediation;

  /// The tool-result text surfaced to the model for a denial.
  String get deniedMessage {
    if (reason.isEmpty) {
      return 'Denied by user.';
    }
    final fix = remediation;
    return fix == null || fix.isEmpty
        ? 'Denied: $reason'
        : 'Denied: $reason $fix';
  }
}

/// Called before a non-read tool runs. Wired by the dispatch layer to the
/// confirmation flow + action guard.
typedef ToolApprovalCallback =
    Future<ToolGateDecision> Function(
      HarnessTool tool,
      Map<String, dynamic> args,
    );

/// Optional token + wall-clock budget for goal-directed runs.
///
/// At [pressureFraction] of the budget the loop injects a steering notice
/// telling the model to wrap up; at 100% it either stops ([hardStop]) or keeps
/// steering until the model reaches a natural end-of-turn ([hardStop] false).
class HarnessBudget {
  /// Creates a budget.
  const HarnessBudget({
    this.tokenBudget,
    this.timeBudget,
    this.hardStop = true,
    this.pressureFraction = 0.8,
  });

  /// Max billable tokens (input + cache-write + output, excluding cache reads).
  final int? tokenBudget;

  /// Max wall-clock duration.
  final Duration? timeBudget;

  /// True = stop when the budget is hit; false = steer then continue to a
  /// natural end-of-turn.
  final bool hardStop;

  /// Fraction of the budget at which the wrap-up steering note fires.
  final double pressureFraction;

  /// Whether any limit is set.
  bool get isActive => tokenBudget != null || timeBudget != null;
}

/// Configuration for a single agent-loop run.
class AgentLoopConfig {
  /// Creates a loop config.
  const AgentLoopConfig({
    this.systemPrompt = _defaultSystemPrompt,
    this.maxTurns,
    this.maxTokens = defaultHarnessMaxTokens,
    this.model,
    this.temperature,
    this.topP,
    this.topK,
    this.effort,
    this.cacheEnabled = true,
    this.cacheKey,
    this.approvalCallback,
    this.autoApprove = true,
    this.budget = const HarnessBudget(),
    this.externalBudgetExceeded,
    this.externalBudgetPressure,
    this.maxProviderRetries = 3,
    this.maxParallelToolCalls = 4,
    this.toolTimeout,
    this.turnTimeout = const Duration(minutes: 30),
    this.contextWindow,
    this.compactor,
    this.selfAgentName = 'assistant',
    this.hooks,
    this.streamRules = const [],
    this.advisor,
    this.advisorEveryTurns = 3,
    this.checklistStaleAfterTurns = 4,
    this.steering,
    this.pauseGate,
    this.contract,
    this.transcriptStore,
    this.transcriptKey,
    this.initialCheckpoints = const {},
  });

  static const String _defaultSystemPrompt =
      'You are a capable coding assistant. Use the available tools to read, '
      'search, edit and run code to accomplish the task. Be concise.';

  /// The system prompt.
  final String systemPrompt;

  /// Max loop iterations before stopping with [LoopDoneReason.maxTurns].
  /// Null (the default) means NO turn ceiling: the loop runs until the model
  /// stops on its own, a budget bites, or the caller cancels. Long-running
  /// work is bounded by [budget] and [externalBudgetExceeded] plus the
  /// doom-loop repetition guard — a hard iteration count kills legitimate
  /// long tasks (migrations, fan-out cleanup) and saves nothing that the
  /// repetition guard doesn't catch earlier.
  final int? maxTurns;

  /// Max output tokens per provider turn.
  final int maxTokens;

  /// Model override (else the provider default is used).
  final String? model;

  /// Sampling temperature.
  final double? temperature;

  /// Nucleus-sampling cutoff. See [LlmCompleteConfig.topP] for why models that
  /// publish a required sampling recipe need this reachable.
  final double? topP;

  /// Top-k sampling cutoff. Only sent when the provider supports it.
  final int? topK;

  /// Reasoning-effort level, or null to disable extended thinking / reasoning.
  final ReasoningEffort? effort;

  /// Whether to request provider prompt caching (forwarded to the provider).
  final bool cacheEnabled;

  /// Stable per-run cache key (forwarded to providers with explicit keys).
  final String? cacheKey;

  /// Confirmation gate for write / exec tools.
  final ToolApprovalCallback? approvalCallback;

  /// Policy when a write/exec tool needs approval but [approvalCallback] is
  /// null. When true (the low-level default) the tool runs ungated; when false
  /// it is denied — a fail-closed posture the product layer opts into so a
  /// missing approver can never silently ungate privileged tools.
  final bool autoApprove;

  /// Optional goal budget.
  final HarnessBudget budget;

  /// External budget check, polled at every turn boundary: when it returns
  /// true the loop stops with [LoopDoneReason.budgetExhausted]. Lets the host
  /// impose a budget in units the harness knows nothing about (a priced cost
  /// cap in cents lives at the dispatch layer, which alone can price usage).
  final bool Function()? externalBudgetExceeded;

  /// Soft variant of [externalBudgetExceeded], also polled at every turn
  /// boundary: the first true poll injects a one-shot "approaching the budget
  /// — wrap up NOW" steer so the model consolidates (persists notes, writes
  /// its handoff) before the hard check ends the run mid-task. With no turn
  /// ceiling this restores what the ceiling's pre-end warning turns did.
  final bool Function()? externalBudgetPressure;

  /// Max retries on retryable provider errors (rate-limit / overloaded).
  final int maxProviderRetries;

  /// How many parallel-safe tool calls from one turn run at a time. A wave of
  /// cheap reads is happy to be wide; a wave of `task` calls is not — each
  /// subagent is a full nested agent loop with its own provider traffic, so an
  /// unbounded fan-out is how one turn trips a rate limit or saturates a local
  /// endpoint. Excess calls run in the next wave, still concurrently and
  /// results are always paired back in the model's original order. Values < 1
  /// are treated as 1 (fully sequential).
  final int maxParallelToolCalls;

  /// Wall-clock ceiling on ONE tool call, or null for no kernel-level bound.
  ///
  /// Correctness used to rest entirely on each tool self-limiting: the runner
  /// caught throws but never raced a deadline OR the cancellation token, so a
  /// hung tool blocked the turn indefinitely — and a token-ignoring one kept
  /// running after the caller cancelled (the runtime's own `bash` clamps a
  /// model-supplied timeout at ONE HOUR, so a single approved command could
  /// legally hold a cancelled turn that long).
  ///
  /// The timeout does not kill the tool's own work — the kernel cannot, it has
  /// no handle on it — it stops WAITING and returns an error result the model
  /// can act on. Tools that own a process should still self-limit; this is the
  /// floor under the ones that don't.
  final Duration? toolTimeout;

  /// Wall-clock ceiling on a SINGLE provider turn. Null disables it.
  ///
  /// Budgets and stop conditions are otherwise only evaluated at turn
  /// boundaries, and the only in-turn bound is the transport's IDLE timeout —
  /// which resets on every chunk. A provider stream dripping one byte every
  /// 100 seconds therefore never trips anything and holds the run open
  /// indefinitely, spending nothing the token budget can see. This is the
  /// wall-clock backstop for exactly that shape.
  ///
  /// Generous by default: a long extended-thinking turn with several large
  /// tool results legitimately takes minutes. It is a runaway bound, not a
  /// latency target — a turn that hits it was not going to finish.
  final Duration? turnTimeout;

  /// The model's context window in tokens. Null disables compaction.
  final int? contextWindow;

  /// Compacts the history when it approaches [contextWindow]. Null disables
  /// compaction (history grows unbounded — the pre-compaction behavior).
  final HarnessCompactor? compactor;

  /// Display name used to label the agent's turns in compaction summaries.
  final String selfAgentName;

  /// Optional lifecycle hooks (start/end + pre/post-tool gate). Null = none.
  final AgentLoopHooks? hooks;

  /// Course-correction rules matched against streamed output. Empty = none.
  final List<StreamRule> streamRules;

  /// Optional secondary reviewer that can inject a note after each turn.
  final Advisor? advisor;

  /// How often (in tool-bearing turns) the [advisor] is prompted to review.
  /// Higher = cheaper and less naggy; each review still sees every turn since
  /// the last one as an accumulated delta. Ignored when [advisor] is null.
  final int advisorEveryTurns;

  /// How many tool-bearing turns of other work may pass with open
  /// task-checklist items before the loop injects one steer to bring the list
  /// up to date. 0 (or negative) disables the check.
  ///
  /// Unlike [advisor] this costs nothing — staleness is a turn count, so no
  /// second model is involved. It exists because the checklist tool's own
  /// result can only correct an agent that is still calling it; the common
  /// failure is an agent that appends items once and then never touches the
  /// list again.
  final int checklistStaleAfterTurns;

  /// Optional mid-run steering inbox. When set, the loop drains queued user
  /// messages at safe turn boundaries: the steering + aside lanes are injected
  /// at the top of each turn (so a message typed while the agent is working
  /// reaches it without a new dispatch) and the follow-up lane is consumed when
  /// the model would otherwise stop (so queued work continues the same run).
  final SteeringQueue? steering;

  /// Pauses the loop at the next clean turn boundary (take-over, PRD 16 §8).
  /// Null = never pauses.
  final PauseGate? pauseGate;

  /// The deliverable this run owes. Null (the default) keeps the historical
  /// behavior exactly: "no tool calls" ends the run as
  /// [LoopDoneReason.completed].
  ///
  /// When set, the loop nudges once at the point it would otherwise complete
  /// and, if still unmet, ends with [LoopDoneReason.contractUnmet] instead of
  /// silently reporting success.
  final CompletionContract? contract;

  /// Where the loop persists its history at each turn boundary, so a later
  /// run can continue this conversation for real rather than from a summary.
  ///
  /// Null (the default) keeps the historical behaviour exactly: nothing is
  /// written and every run starts fresh.
  final HarnessTranscriptStore? transcriptStore;

  /// The key [transcriptStore] saves under — a conversation id, typically.
  ///
  /// Required alongside the store: without it the loop would have to invent a
  /// key, and two runs inventing different keys for one conversation is the
  /// same as not persisting at all.
  final String? transcriptKey;

  /// Checkpoint labels restored from a previous run, as indices into the
  /// caller-seeded [AgentLoop.run] history.
  ///
  /// Passed in rather than loaded here because [AgentLoop.run]'s history is
  /// CALLER-OWNED: only the caller knows how much of a stored transcript it
  /// chose to seed, and a label indexing a list it does not index points at a
  /// different message — a rewind that discards work while reporting success.
  final Map<String, int> initialCheckpoints;
}

/// The built-in agent loop: send messages → call the model → execute tools →
/// loop until a stop condition.
abstract interface class AgentLoop {
  /// Runs the loop for [userMessage] against [provider] with [tools].
  ///
  /// [history] is owned by the caller and appended to in place as the loop
  /// runs (the user turn, each assistant turn and tool-result turns). The
  /// returned stream emits granular [AgentLoopEvent]s and finishes with exactly
  /// one [LoopDone] (or a [LoopError] followed by [LoopDone]).
  ///
  /// [userImages] are attached to the user turn — a screenshot the human
  /// pasted into the composer. Kept separate from [userMessage] rather than
  /// folded into it because the text is what every other surface (the run log,
  /// the title generator, the repetition guard) reads, and none of them wants
  /// a base64 blob in the middle of it.
  ///
  /// [deferredTools] are callable but their schemas are withheld from the
  /// request until first use — see `ToolResidencySpec`. They are activated
  /// (appended to the schemas sent, permanently for the run) when the model
  /// calls one by name or when a tool result asks for them
  /// ([HarnessToolResult.activateTools]). Activation only ever APPENDS, so the
  /// resident prefix the provider cached stays byte-identical.
  Stream<AgentLoopEvent> run({
    required List<HarnessMessage> history,
    required String userMessage,
    required List<HarnessTool> tools,
    required LlmProviderPort provider,
    List<HarnessTool> deferredTools,
    HarnessToolContext? context,
    AgentLoopConfig config = const AgentLoopConfig(),
    CancellationToken? cancel,
    List<HarnessImageBlock> userImages = const [],
  });
}
