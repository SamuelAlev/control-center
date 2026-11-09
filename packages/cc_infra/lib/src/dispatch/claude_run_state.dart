import 'dart:async';

import 'package:cc_infra/src/dispatch/backends/cli_backends.dart';
import 'package:cc_infra/src/dispatch/claude_subagent_runs.dart';
import 'package:cc_infra/src/sandboxing/claude_native_session.dart';
import 'package:cc_infra/src/sandboxing/claude_stream_json.dart';

/// What one dispatch's `claude -p` transport keeps between stream-json lines:
/// the parser, the open stdin and its steering, the MCP handshake, the
/// cumulative-accounting ledger, the native session coordinates and the
/// latency boundaries.
///
/// It is owned by exactly one `DispatchSession` and mutated only by its Claude
/// transport parts; it exists so that state reads as one unit rather than
/// thirty `_claude*` fields interleaved with every other transport's.
class ClaudeRunState {
  /// Active Claude stream-json parser, when the dispatch runs `claude`. Held so
  /// parsed stdout lines route to it from the shared sandbox-event forwarder.
  ClaudeStreamJsonParser? parser;

  /// Tool name per in-flight `tool_use` id: a `tool_result` block names only
  /// the id it answers, and a result with no tool name renders as `tool`.
  final Map<String, String> toolNames = {};

  /// Child runs for the subagents the active `claude -p` process spawned.
  ClaudeSubagentRuns? subagents;

  /// The running `claude -p` attempt's stdin, while it takes steering. Null
  /// outside a Claude run and once the turn's `result` closed it — what is
  /// queued after that converts to a follow-up message at run end.
  // ignore: close_sinks
  StreamController<String>? stdin;

  /// Steering this run already wrote to `claude`, in order. An account
  /// failover restarts the turn on a fresh process, which gets these again
  /// after the prompt: the cards are already marked injected.
  final List<String> steered = [];

  /// Limit crossings this run has already acted on; see `_onClaudeRateLimit`.
  final Set<String> limitCrossings = {};

  /// The first lines of a turn, held until the MCP servers are answered for.
  List<String>? heldLines;

  /// The `mcp_set_servers` request those lines wait on.
  String? mcpRequestId;

  /// Gives up on that answer when the CLI never sends it.
  Timer? mcpAnswerTimer;

  /// Control requests this run has sent, for unique request ids.
  int controlRequests = 0;

  /// Completes when stdin closes, for a stop waiting on the turn to end.
  Completer<void>? stdinClosed;

  /// The size of the latest main-thread call, for `ClaudeIdleCompactor`.
  int contextTokens = 0;

  /// How long the session's newest prompt cache entry lasts, when known.
  Duration? cacheTtl;

  /// Whether a microtask is already due to drain the steering queue into
  /// [stdin], so a burst of pushes is written in one pass.
  bool steeringPumpScheduled = false;

  /// Cumulative-accounting ledger for the active `claude -p` call.
  ///
  /// `claude` reports per-turn main-loop `usage` (additive) alongside a
  /// CUMULATIVE `total_cost_usd` and `modelUsage`; this delta's the cumulative
  /// halves so a queued follow-up turn — or a resumed session, whose totals
  /// include the prior spend — is never counted twice. Seeded from the
  /// persisted session record only when the CLI will restore those totals.
  ClaudeAccountingLedger? ledger;

  /// THIS dispatch's spend, summed from turn deltas.
  ///
  /// The run-level `runCumulative` event is built from this, never from the
  /// native session's cumulative counters: those include earlier dispatches
  /// (inflating the run) and restart at a reset or an account switch (losing
  /// the attempts already made).
  ClaudeDispatchTotals dispatchTotals = ClaudeDispatchTotals();

  /// The delta prompt this dispatch sends when it resumes, or null when it does
  /// not resume (the full prompt is sent then).
  String? deltaPrompt;

  /// The capabilities the resolved CLI advertised for this run, kept so the
  /// persistence decision (does this build restore session totals?) uses the
  /// same probe result that governed the argv.
  ClaudeCliCapabilities? capabilities;

  /// The native session this scope loaded, when the run resumed one. Held so
  /// the record is re-saved with the CLI's authoritative id after `init`.
  ClaudeNativeSessionRecord? resumeRecord;

  /// The native session id the CLI reports for the current call — `init`'s
  /// `session_id`, refreshed by any later result (a `/clear` mints a new one).
  /// This is what a later turn resumes.
  String? nativeSessionId;

  /// The native session id this run actually launched with (`--resume`), or
  /// null when it started fresh. Read by the tests and the diagnostics.
  String? resumeId;

  /// Storage key of the current run's scope, and the launch policy it was
  /// fingerprinted with. Together they are the record coordinates.
  String? scopeKey;

  /// See [scopeKey].
  String? policyKey;

  /// Startup metadata parsed from `system/init` (serving model, tool surface,
  /// MCP status/errors, capabilities), when the CLI reported it.
  ClaudeInitMetadata? init;

  /// When the active attempt's process was launched, for separating startup +
  /// MCP discovery time from model latency.
  DateTime? attemptStartedAt;

  /// Whether the attempt has seen its first structured stdout line yet, and
  /// whether it has produced a model delta / its first useful work (assistant
  /// text or a tool call) — the three observable latency boundaries this
  /// adapter can honestly report (it never invents a provider TTFB the CLI
  /// hides).
  bool sawFirstStdout = false;

  /// See [sawFirstStdout].
  bool sawFirstModelDelta = false;

  /// See [sawFirstStdout].
  bool sawFirstUseful = false;

  /// Whether this run was launched with an MCP config, so a session that came
  /// back without any `mcp__*` tool is a lost capability rather than the
  /// expected shape of a config-less run.
  bool mcpExpected = false;

  /// Set while the run is executing on a fallback account: the scope record
  /// names the FIRST account's config directory, so a session id learned on
  /// another account must not be written under it.
  bool persistDisabled = false;
}
