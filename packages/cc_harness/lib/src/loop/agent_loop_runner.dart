import 'dart:async';
import 'dart:collection';
import 'dart:convert';
import 'dart:math';
import 'package:cc_harness/src/cancellation_token.dart';
import 'package:cc_harness/src/context/harness_compaction.dart';
import 'package:cc_harness/src/context/harness_token_accounting.dart';
import 'package:cc_harness/src/context/provider_image_budget.dart';
import 'package:cc_harness/src/context/still_in_flight.dart';
import 'package:cc_harness/src/context/token_estimator.dart';
import 'package:cc_harness/src/context/tool_observation.dart';
import 'package:cc_harness/src/context/tool_output_truncation.dart';
import 'package:cc_harness/src/loop/advisor.dart';
import 'package:cc_harness/src/loop/agent_loop.dart';
import 'package:cc_harness/src/loop/agent_loop_hooks.dart';
import 'package:cc_harness/src/loop/checklist_supervisor.dart';
import 'package:cc_harness/src/loop/completion_contract.dart';
import 'package:cc_harness/src/loop/steering_message.dart';
import 'package:cc_harness/src/loop/steering_queue.dart';
import 'package:cc_harness/src/loop/stream_rules.dart';
import 'package:cc_harness/src/loop/transcript_store.dart';
import 'package:cc_harness/src/messages.dart';
import 'package:cc_harness/src/provider/llm_provider_port.dart';
import 'package:cc_harness/src/tools/background_commands.dart';
import 'package:cc_harness/src/tools/background_notify.dart';
import 'package:cc_harness/src/tools/tool.dart';
import 'package:cc_harness/src/tools/tool_reentry.dart';

part 'agent_loop_guards.dart';
part 'agent_loop_reentry.dart';
part 'agent_loop_run_end.dart';
part 'agent_loop_tool_catalog.dart';
part 'agent_loop_tool_gate.dart';
part 'agent_loop_tool_step.dart';
part 'agent_loop_turn_streamer.dart';

/// Below this many output tokens in one turn, the delivery-ratio check is not
/// meaningful — a short turn can legitimately spend tokens on a stop sequence or
/// a few reasoning tokens and deliver little text.
const int _minTokensForLossCheck = 256;

/// The floor for delivered characters per billed output token before a turn is
/// treated as provider output loss.
///
/// English averages ~4 characters per token and even dense JSON stays above
/// ~1.5, so 0.5 means at least ~87% of the generated text never reached us. It
/// is deliberately far below any plausible tokenizer ratio: this must fire on
/// real loss and never on a merely terse turn.
const double _minCharsPerOutputToken = 0.5;

/// How much of the streamed text tail stream rules are matched against.
///
/// Matching every rule against the WHOLE accumulated buffer on every delta is
/// quadratic in the turn's output. Rules trigger on phrases the model just
/// emitted, so a bounded tail carries the same signal at O(window) per delta.
/// 8 KB is far longer than any realistic course-correction pattern and still
/// small enough that the per-delta scan is free.
const int _streamRuleWindowChars = 8192;

/// How many context-overflow recoveries (forced compaction + re-issue) ONE
/// turn may attempt before the provider's rejection ends the run.
///
/// Per turn, not per run: a long run legitimately overflows many times over
/// its life, and a run-wide budget spent early left later turns with no
/// recovery at all.
const int _maxOverflowRecoveriesPerTurn = 2;

/// How many CONSECUTIVE `max_tokens`-truncated, tool-free turns are
/// auto-continued before the loop accepts the cut-off answer. Reset whenever a
/// turn makes progress (calls a tool) or a new user prompt arrives, so a long
/// run is not left with zero continuations after its first few.
const int _maxConsecutiveTruncations = 3;

/// The single implementation of [AgentLoop]: message → LLM → tools → loop.
///
/// Sends the conversation to the provider, streams its events, executes any
/// tool calls (gated by the approval callback for write/exec tools), appends
/// results and loops until the model stops calling tools, a budget/turn limit
/// is hit, the caller cancels, or an unrecoverable error occurs. Retryable
/// provider errors (rate-limit / overloaded) are retried with exponential
/// backoff.
///
/// The run itself lives in a per-call [_RunState]; this class is the stateless
/// entry point. Every terminal path goes through [_RunState.finish], which
/// saves the transcript and emits exactly one [LoopDone] (preceded by one
/// [LoopError] for a failure outcome) — including an exception escaping a
/// host-supplied extension point, which is caught here as a last resort.
class AgentLoopRunner implements AgentLoop {
  /// Creates an [AgentLoopRunner].
  const AgentLoopRunner();

  static int _nextLoopId = 0;

  @override
  Stream<AgentLoopEvent> run({
    required List<HarnessMessage> history,
    required String userMessage,
    required List<HarnessTool> tools,
    required LlmProviderPort provider,
    List<HarnessTool> deferredTools = const [],
    List<HarnessTool> scriptTools = const [],
    HarnessToolContext? context,
    AgentLoopConfig config = const AgentLoopConfig(),
    CancellationToken? cancel,
    List<HarnessImageBlock> userImages = const [],
  }) async* {
    final state = _RunState(
      history: history,
      tools: tools,
      deferredTools: deferredTools,
      scriptTools: scriptTools,
      provider: provider,
      context: context,
      config: config,
      cancel: cancel ?? CancellationToken.none,
      callIdPrefix:
          '${config.guards.callLedger?.runId ?? config.cacheKey ?? 'loop'}'
          ':${++_nextLoopId}',
    );
    try {
      yield* state.run(userMessage, userImages);
    } on Object catch (e) {
      // A host-supplied callback (approval, observation store, compactor
      // commit) threw past every narrower guard. The exactly-one-terminal
      // contract still holds: report it as the run's error.
      yield* state.finish(
        LoopDoneReason.error,
        error: 'The agent loop failed: $e',
        errorCode: 'loop_exception',
      );
    } finally {
      // A background command never outlives its run: [finish] kills them, and
      // this covers a host that stopped listening to the stream instead.
      await state.closeBackground();
    }
  }
}

/// The mutable state of ONE [AgentLoopRunner.run] call, and its phases.
///
/// The run used to be a single 1,500-line generator over ~30 closure locals.
/// It is now: this orchestrator ([run]), the tool catalog ([_ToolCatalog]),
/// the provider-turn streamer ([_TurnStreamer]), tool execution
/// ([_ToolStep]) and the cross-turn guards ([_RunGuards]). Phases that can end
/// the run do so through [finish] and the orchestrator checks [finished] after
/// each one.
class _RunState {
  _RunState({
    required this.history,
    required List<HarnessTool> tools,
    required List<HarnessTool> deferredTools,
    required List<HarnessTool> scriptTools,
    required this.provider,
    required HarnessToolContext? context,
    required this.config,
    required this.cancel,
    required this.callIdPrefix,
  }) : catalog = _ToolCatalog(
         tools: tools,
         deferredTools: deferredTools,
         scriptTools: scriptTools,
         nativeDeferral:
             tools.isNotEmpty &&
             deferredTools.isNotEmpty &&
             provider.supportsDeferredTools(model: config.model),
       ),
       // Hand the run's cancellation token to tools so a cancelled run kills
       // work in flight (bash, web fetch) instead of only being noticed
       // between tools.
       // A host context may carry a reentry (a subagent's spawning call
       // hands its own context down): this run's calls get this run's
       // reentry, never one borrowed from another run.
       ctx = (context ?? const HarnessToolContext(workingDirectory: '.'))
           .withCancel(cancel)
           .withReentry(null),
       observationIngest =
           config.tools.observationIngest ?? ToolObservationIngest(),
       ledger = ContractLedger(config.guards.contract),
       checkpoints = <String, int>{...config.transcript.initialCheckpoints},
       snapshotSource = config.transcript.initialSnapshotSource {
    guards = _RunGuards(this);
    catalog
      ..rebuildNative(history)
      ..activate(collectActivatedToolNames(history));
    basePromptTokens = _overheadTokens(
      config.systemPrompt,
      catalog.residentSchemas,
    );
  }

  /// The caller-owned conversation, appended and rewritten in place.
  final List<HarnessMessage> history;
  final LlmProviderPort provider;
  final AgentLoopConfig config;
  final CancellationToken cancel;
  final String callIdPrefix;
  final _ToolCatalog catalog;
  final HarnessToolContext ctx;
  final ToolObservationIngest observationIngest;

  /// The run's deliverable, if it declared one. Tracks whether a required
  /// output verb has completed successfully so the loop can tell "finished
  /// and delivered" from "stopped talking".
  final ContractLedger ledger;

  /// Seeded from a restored run, so a `rewind` to a label the model set
  /// before a restart still lands where the label was set.
  final Map<String, int> checkpoints;

  /// The text behind a live snapshot page, carried across the run and written
  /// back with the transcript. Seeded from the resumed record: without it a
  /// restarted run cannot recover the conversation a page represents.
  String? snapshotSource;

  late final _RunGuards guards;

  /// The one gate every tool call passes, direct or nested.
  late final _ToolGate gate = _ToolGate(this);

  /// The lane every effectful, gated or person-waiting nested call takes, one
  /// at a time in call order across the whole run.
  final _Lane serialLane = _Lane(1);

  /// Builds the reentry for a model-issued call in a parallel batch.
  _LoopReentry reentryFor(
    String parentToolUseId,
    CancellationToken callToken,
    _PausableDeadline? deadline,
    void Function(AgentLoopEvent event) emit,
  ) => _LoopReentry(
    this,
    parentToolUseId: parentToolUseId,
    parentToken: callToken,
    parentDeadline: deadline,
    emit: emit,
  );

  final Stopwatch stopwatch = Stopwatch()..start();
  final Random rng = Random();

  /// Prompt overhead of the system prompt + RESIDENT tool schemas, constant
  /// across the run. Activated schemas are added by [overheadTokensNow].
  late final int basePromptTokens;

  /// Where the last SUCCESSFUL request placed its message-tail cache
  /// breakpoint, so the next one can anchor its read there. -1 until the first
  /// request and after any history rewrite (the old anchor then points into a
  /// conversation that no longer exists).
  int cacheAnchorIndex = -1;

  /// Billable tokens counted from streamed usage — the fallback for a run with
  /// no [LoopGuardConfig.callLedger]. With a ledger, the ledger is the single
  /// source of truth ([billableTokensNow]).
  int streamedBillableTokens = 0;

  /// The turn being run (0-based).
  int turn = 0;

  /// How many turns the persisted transcript claims.
  int persistedTurns = 0;

  /// History length at the start of the current turn — the clean boundary a
  /// `checkpoint` marks and a `rewind` truncates to.
  int preTurnLength = 0;

  /// CONSECUTIVE truncated, tool-free turns auto-continued so far.
  int consecutiveTruncations = 0;

  /// Set once [finish] has emitted the terminal event.
  bool finished = false;

  /// The run's background commands, carried by its `bash` family of tools
  /// ([BackgroundCommandTool]); null when none carries them.
  late final BackgroundCommandRegistry? background = backgroundCommandsOf(
    catalog.admitted.values,
  );

  /// The run's own aside lane for background-command notices. Not the host's
  /// queue: that one may be a nested view that delivers into the parent's
  /// lanes, is capped for people's messages, and has persistence listeners.
  /// Drained with the host's aside lane, at the same point, as system
  /// messages.
  final SteeringQueue noticeLane = SteeringQueue();

  /// The focus of a `compact` call made this turn: set when the model asks
  /// for a compaction, consumed by the next turn boundary.
  String? pendingCompactFocus;

  /// Whether `compact` was called and the compaction has not run yet.
  bool compactRequested = false;

  /// The highest context-use level (70, 80, 90 percent) already announced;
  /// re-armed when a compaction brings the use back under it.
  int contextLineLevel = 0;

  AgentLoopHooks? get hooks => config.steering.hooks;

  /// Whether independent calls may run concurrently: not while a hook
  /// intercepts tools, whose veto and observation must run in call order.
  bool get batchingAllowed {
    final hooks = this.hooks;
    return hooks == null || !hooks.interceptsTools;
  }

  HarnessCompactor? get compactor => config.compaction.compactor;

  int billableTokensNow() =>
      config.guards.callLedger?.billableTokens ?? streamedBillableTokens;

  /// Tools activated mid-run are real request bytes: left out of the budget,
  /// a run that pulls in a dozen schemas would compact too late and hit the
  /// provider's context ceiling instead of its own.
  int overheadTokensNow() => basePromptTokens + catalog.activatedOverheadTokens;

  late final LlmCompleteConfig completeConfig = LlmCompleteConfig(
    model: config.model,
    systemPrompt: config.systemPrompt,
    maxTokens: config.maxTokens,
    temperature: config.temperature,
    topP: config.topP,
    topK: config.topK,
    effort: config.effort,
    cacheEnabled: config.cacheEnabled,
    cacheKey: config.cacheKey,
    purpose: config.purpose,
  );

  // ---------------------------------------------------------------------------
  // Orchestration
  // ---------------------------------------------------------------------------

  Stream<AgentLoopEvent> run(
    String userMessage,
    List<HarnessImageBlock> userImages,
  ) async* {
    // The user turn carries any pasted screenshots alongside its text. Built
    // as one message rather than two so the provider sees the picture and the
    // question as a single turn — a bare image message reads to most models as
    // context with no ask attached.
    history.add(
      userImages.isEmpty
          ? HarnessMessage.user(
              userMessage,
              origin: config.steering.requestOrigin,
            )
          : HarnessMessage(
              role: HarnessRole.user,
              content: [HarnessTextBlock(userMessage), ...userImages],
              origin: config.steering.requestOrigin,
            ),
    );

    openBackground();

    final hooks = this.hooks;
    if (hooks != null) {
      // Guarded, like every other extension-point call below. These are
      // THIRD-PARTY implementations: an exception escaping the `async*`
      // generator becomes a stream error with NO LoopDone, breaking the
      // documented "exactly one terminal event" contract and leaving the
      // caller-owned `history` half-mutated with nothing to tell it so.
      final failure = await _guardExtension(
        'onSessionStart',
        hooks.onSessionStart,
      );
      if (failure != null) {
        yield* finish(LoopDoneReason.error, error: failure);
        return;
      }
    }

    final maxTurns = config.maxTurns;
    for (turn = 0; maxTurns == null || turn < maxTurns; turn++) {
      yield* _pauseAtBoundary();
      if (finished) {
        return;
      }
      if (cancel.isCancelled) {
        yield* finish(LoopDoneReason.cancelled);
        return;
      }
      if (guards.hardBudgetExhausted()) {
        yield* finish(LoopDoneReason.budgetExhausted);
        return;
      }

      yield* _compactNearWindow();
      if (cancel.isCancelled) {
        yield* finish(LoopDoneReason.cancelled);
        return;
      }
      yield* _drainSteering();
      yield* contextUseLine();
      yield* guards.turnPressure();

      // The clean boundary at the start of this turn (end of a complete prior
      // turn) — where a `checkpoint` marks and a `rewind` truncates to, and
      // the only point at which the history is safe to persist.
      preTurnLength = history.length;
      persistedTurns = turn;
      await persistTranscript();

      final streamer = _TurnStreamer(this);
      yield* streamer.stream();
      if (finished) {
        return;
      }
      final output = streamer.output;

      // ---- Assemble + append the assistant turn. ----
      final assistantMsg = output.toAssistantMessage();
      history.add(assistantMsg);
      yield LoopTurnComplete(assistantMsg);

      if (output.pending.isEmpty) {
        yield* _onToolFreeTurn(output);
        if (finished) {
          return;
        }
        continue;
      }
      // A tool-bearing turn is progress: the truncation streak is over.
      consecutiveTruncations = 0;

      // ---- Rewind: prune the exploration back to a checkpoint (or the
      //      original task), keeping a digest. ----
      final rewind = await _tryRewind(output.pending);
      if (rewind is _Rewound) {
        yield LoopNotice(rewind.notice);
        continue;
      }

      final step = _ToolStep(
        this,
        output,
        rewindRejection: rewind is _RewindRejected ? rewind.message : null,
      );
      yield* step.execute();
      if (finished) {
        return;
      }

      yield* guards.afterToolTurn(output.pending, step.observedCalls);

      // Reclaim uneventful older tool results — but only once there is enough
      // to reclaim to be worth the cached prefix it rewrites. Batched, it is a
      // rare deep rewrite instead of a permanent cache leak. Full compaction
      // remains the heavier fallback at the loop top.
      final elided = compactor?.pruneToolResults(history) ?? 0;
      if (elided > 0) {
        onHistoryRewritten(reindexed: false);
      }

      yield* guards.advise();
      if (finished) {
        return;
      }
      yield* guards.budgetAfterTurn();
      if (finished) {
        return;
      }
    }

    yield* _turnCeilingHandoff();
    // Turn ceiling reached (only reachable when a ceiling is configured — an
    // uncapped loop never exits the turn loop normally). The primary cause
    // stays `maxTurns`; an unmet contract rides along.
    yield* finish(LoopDoneReason.maxTurns);
  }

  /// The ONE terminal path. Saves the transcript (at its last clean boundary)
  /// and emits exactly one [LoopDone] — preceded by exactly one [LoopError]
  /// when [error] is given or [reason] is [LoopDoneReason.error], so a host
  /// that derives its exit status from the error stream never sees a failed
  /// run as a clean exit.
  ///
  /// Every reason flushes the final turn: a budget stop, a cancel, the turn
  /// ceiling or an error used to skip the save, leaving the resumed run one
  /// turn stale with the last turn's work unsaved.
  Stream<AgentLoopEvent> finish(
    LoopDoneReason reason, {
    String? error,
    String? errorCode,
  }) async* {
    if (finished) {
      return;
    }
    finished = true;
    await closeBackground();
    await persistTranscript();
    if (error != null) {
      yield LoopError(error, code: errorCode);
    } else if (reason == LoopDoneReason.error) {
      yield LoopError(
        'The run stopped on an unrecoverable error.',
        code: errorCode ?? 'loop_error',
      );
    }
    final carriesContract = switch (reason) {
      LoopDoneReason.budgetExhausted ||
      LoopDoneReason.maxTurns ||
      LoopDoneReason.contractUnmet => true,
      _ => false,
    };
    yield LoopDone(
      reason,
      unmetContractId: carriesContract && ledger.isActive && !ledger.satisfied
          ? ledger.contract!.id
          : null,
    );
  }

  // ---------------------------------------------------------------------------
  // Persistence + history rewrites
  // ---------------------------------------------------------------------------

  /// Whether [history] ends on a boundary a provider will accept back: never
  /// between an assistant `tool_use` and its `tool_result`.
  bool get _atCleanBoundary {
    if (history.isEmpty) {
      return true;
    }
    final last = history.last;
    return !(last.role == HarnessRole.assistant &&
        last.content.any((b) => b is HarnessToolUseBlock));
  }

  /// Writes the history as it stands — only at a clean boundary: a history
  /// captured between a `tool_use` and its `tool_result` is one no provider
  /// will accept, so a crash at that instant must restore the turn BEFORE
  /// rather than a half-turn that cannot be replayed.
  Future<void> persistTranscript() async {
    final store = config.transcript.store;
    final key = config.transcript.key;
    if (store == null || key == null || !_atCleanBoundary) {
      return;
    }
    try {
      await store.save(
        key,
        HarnessTranscript(
          messages: List<HarnessMessage>.unmodifiable(history),
          checkpoints: Map<String, int>.unmodifiable(checkpoints),
          turns: persistedTurns,
          retainedSnapshotSource: snapshotSource,
          // A copy, so the persisted record is a snapshot of the host's
          // bookkeeping rather than a live view of a map the host may keep
          // mutating.
          metadata: Map<String, Object?>.of(config.transcript.metadata),
        ),
      );
    } on Object {
      // Continuity is worth less than the run in progress.
    }
  }

  /// The single "history was rewritten" sequence, shared by compaction,
  /// overflow recovery, rewind and pruning. It used to be hand-copied at each
  /// site with drifting subsets (rewind never remapped its checkpoints).
  ///
  /// * [fold]: the compaction result whose span collapsed — checkpoints are
  ///   remapped across it, the snapshot source absorbed, and pruning is
  ///   forced to ride the rewrite that was already paid for (ARCH: compaction
  ///   forces pruning).
  /// * [reindexed]: message POSITIONS changed (fold, rewind), so the advisor's
  ///   cursor and the checklist cadence must re-prime. An in-place prune keeps
  ///   positions and leaves them alone.
  ///
  /// Always: the cache anchor is invalidated (it names a position no request
  /// wrote at any more) and the native tool catalog is rebuilt for whatever
  /// activation carriers the history still holds.
  void onHistoryRewritten({
    HarnessCompactionResult? fold,
    required bool reindexed,
  }) {
    if (fold != null) {
      _remapCheckpoints(checkpoints, fold);
      _absorbSnapshotSource(fold);
      compactor?.pruneToolResults(history, force: true);
    }
    if (reindexed) {
      config.steering.advisor?.reset();
      guards.checklist?.resetCadence();
    }
    cacheAnchorIndex = -1;
    catalog.rebuildNative(history);
  }

  /// Folds a compaction result's snapshot bookkeeping into [snapshotSource].
  ///
  /// Only a pass that CHANGED anything can say something about the carrier: a
  /// reported source is a page that is (still) on the wire; otherwise the
  /// source is spent — but only if the carrier is actually gone. The carrier's
  /// IDENTITY decides (the `isSnapshotCarrier` marker), not how many images
  /// happen to be left: a fold can drop the page while an unrelated screenshot
  /// stays.
  void _absorbSnapshotSource(HarnessCompactionResult result) {
    if (!result.changed) {
      return;
    }
    final source = result.retainedSnapshotSource;
    if (source != null) {
      snapshotSource = source;
      // The folded span collapsed into ONE replacement message AT
      // `foldedFromIndex`, so that message is the page the source describes.
      final index = result.foldedFromIndex;
      if (index >= 0 &&
          index < history.length &&
          !history[index].isSnapshotCarrier) {
        history[index] = history[index].copyWith(isSnapshotCarrier: true);
      }
      return;
    }
    if (!history.any((m) => m.isSnapshotCarrier)) {
      snapshotSource = null;
    }
  }

  // ---------------------------------------------------------------------------
  // Turn-boundary phases
  // ---------------------------------------------------------------------------

  /// Take-over pause: hold at the clean turn boundary until resumed (PRD 16
  /// §8). The hand-back summary arrives as steering and is drained right after.
  Stream<AgentLoopEvent> _pauseAtBoundary() async* {
    final pauseGate = config.steering.pauseGate;
    if (pauseGate == null || !pauseGate.isPaused) {
      return;
    }
    yield const LoopNotice('Paused at turn boundary (take-over).');
    // Race the resume against cancellation: awaiting the gate alone meant a
    // cancel while paused woke nothing and the run leaked.
    await Future.any<void>([pauseGate.waitWhilePaused(), cancel.whenCancelled]);
    if (cancel.isCancelled) {
      yield* finish(LoopDoneReason.cancelled);
      return;
    }
    yield const LoopNotice('Resumed by hand-back.');
  }

  /// Compacts the history when it nears the context window. Runs BEFORE the
  /// pre-turn boundary is captured so checkpoint/rewind indices refer to the
  /// post-compaction list.
  Stream<AgentLoopEvent> _compactNearWindow() async* {
    final compactor = this.compactor;
    if (compactor == null || config.compaction.contextWindow == null) {
      return;
    }
    // A THROWING compactor must not take the run down: compaction is an
    // optimization, and the turn is still runnable without it (the provider's
    // own overflow error is the backstop). Report and continue.
    // A `compact` call forces the pass and carries its focus; the owner's
    // `preCompact` hook adds to the focus of any pass that summarizes.
    final requested = compactRequested;
    final toolFocus = pendingCompactFocus;
    compactRequested = false;
    pendingCompactFocus = null;
    HarnessCompactionResult? result;
    Object? error;
    yield* _announcedPass(
      (focus) => raceCancellation(
        compactor.maybeCompact(
          history,
          contextWindow: config.compaction.contextWindow,
          overheadTokens: overheadTokensNow(),
          reservedOutputTokens: config.maxTokens,
          selfAgentName: config.compaction.selfAgentName,
          force: requested,
          cancel: cancel,
          focus: focus,
        ),
        cancel,
      ),
      () => compactionFocus(toolFocus),
      (r, e) => (result, error) = (r, e),
    );
    if (error != null) {
      yield LoopNotice('Compaction failed and was skipped: $error');
      result = null;
    }
    if (result case final folded? when folded.changed) {
      onHistoryRewritten(fold: folded, reindexed: true);
      await writeStillInFlight();
      yield _compactionEvent(folded);
    } else if (requested) {
      yield const LoopNotice(
        'Compaction was requested but there was nothing old enough to fold.',
      );
    }
  }

  /// Runs one compactor [pass], handing it [focus] wrapped so the moment the
  /// compactor asks for it (only when a summary is about to be written) is
  /// announced: [LoopCompacting] started, then ended when the pass returns.
  /// [done] receives the result, or the error the pass threw.
  Stream<AgentLoopEvent> _announcedPass(
    Future<HarnessCompactionResult?> Function(
      Future<String?> Function() focus,
    )
    pass,
    Future<String?> Function() focus,
    void Function(HarnessCompactionResult? result, Object? error) done,
  ) async* {
    final began = Completer<void>();
    final running = pass(() {
      if (!began.isCompleted) {
        began.complete();
      }
      return focus();
    });
    await Future.any<void>([
      began.future,
      running.then<void>((_) {}, onError: (Object _) {}),
    ]);
    final announced = began.isCompleted;
    if (announced) {
      yield const LoopCompacting(started: true);
    }
    HarnessCompactionResult? result;
    Object? error;
    try {
      result = await running;
    } on Object catch (e) {
      error = e;
    }
    if (announced) {
      yield const LoopCompacting(started: false);
    }
    done(result, error);
  }

  /// Forced compaction after the provider rejected the request as too large.
  ///
  /// Hands [done] the compaction event when the history changed (the turn
  /// should be re-issued), or a failure message when the compactor THREW —
  /// guarded so a throw cannot escape the generator without a terminal
  /// event; the original overflow error then ends the run through [finish].
  /// Yields [LoopCompacting] around a pass that summarizes.
  Stream<AgentLoopEvent> recoverFromOverflow(
    void Function(({LoopCompaction? event, String? failure}) recovery) done,
  ) async* {
    final compactor = this.compactor;
    if (compactor == null || config.compaction.contextWindow == null) {
      done((event: null, failure: null));
      return;
    }
    HarnessCompactionResult? result;
    Object? error;
    yield* _announcedPass(
      (focus) => raceCancellation(
        compactor.maybeCompact(
          history,
          contextWindow: config.compaction.contextWindow,
          overheadTokens: overheadTokensNow(),
          reservedOutputTokens: config.maxTokens,
          selfAgentName: config.compaction.selfAgentName,
          force: true,
          cancel: cancel,
          focus: focus,
        ),
        cancel,
      ),
      () => compactionFocus(null),
      (r, e) => (result, error) = (r, e),
    );
    if (error != null) {
      done((event: null, failure: 'Overflow compaction failed: $error'));
      return;
    }
    final folded = result;
    if (folded == null || !folded.changed) {
      done((event: null, failure: null));
      return;
    }
    try {
      onHistoryRewritten(fold: folded, reindexed: true);
      await writeStillInFlight();
      done((event: _compactionEvent(folded), failure: null));
    } on Object catch (e) {
      done((event: null, failure: 'Overflow compaction failed: $e'));
    }
  }

  static LoopCompaction _compactionEvent(HarnessCompactionResult result) =>
      LoopCompaction(
        summarized: result.summarized,
        messagesFolded: result.messagesFolded,
        tokensBefore: result.tokensBefore,
        tokensAfter: result.tokensAfter,
      );

  /// Mid-run steering: drain messages queued while the agent was working and
  /// inject them before this turn's provider call.
  Stream<AgentLoopEvent> _drainSteering() async* {
    // Background-command notices: system framing, never the person's words.
    // Their untrusted part (the output) is inside the data envelope. Tagged
    // as notices: an observation a compaction summarises or drops, never
    // pins (the state block is the live record of what is in flight).
    collectNotify();
    for (final msg in noticeLane.drainAside()) {
      if (msg.content.trim().isNotEmpty) {
        history.add(
          HarnessMessage.system(
            msg.content.trim(),
            origin: HarnessMessageOrigin.notice,
          ),
        );
      }
      if (msg.source case final source?
          when source.startsWith(backgroundNoticeSource)) {
        background?.markNoticeDelivered(
          source.substring(backgroundNoticeSource.length),
        );
      }
    }
    final steering = config.steering.queue;
    if (steering == null) {
      return;
    }
    for (final msg in steering.drainSteering()) {
      if (msg.content.trim().isNotEmpty) {
        history.add(
          HarnessMessage.user(
            msg.content.trim(),
            origin: laneMessageOrigin(msg),
          ),
        );
        yield const LoopNotice('Steering message injected.');
      }
    }
    for (final msg in steering.drainAside()) {
      if (msg.content.trim().isNotEmpty) {
        history.add(
          HarnessMessage.system(
            msg.content.trim(),
            origin: laneMessageOrigin(msg),
          ),
        );
      }
    }
  }

  /// The model answered with no tool calls: finish, or continue the run
  /// (truncation continuation, queued follow-up, contract nudge).
  Stream<AgentLoopEvent> _onToolFreeTurn(_TurnOutput output) async* {
    // Output-loss guard: billed tokens with almost no delivered content
    // (buffering tool-call parsers drop the buffer when max_tokens cuts
    // mid-`<tool_call>`). Do not auto-continue — same ceiling loses again.
    final deliveredChars = output.text.length + output.thinking.length;
    if (output.stopReason == LlmStopReason.maxTokens &&
        output.outputTokens >= _minTokensForLossCheck &&
        deliveredChars < output.outputTokens * _minCharsPerOutputToken) {
      yield* finish(
        LoopDoneReason.providerOutputLost,
        error:
            'The provider billed ${output.outputTokens} output tokens for '
            'this turn but delivered only $deliveredChars characters and cut '
            'the turn off at the output ceiling. The response was almost '
            'certainly discarded by a server-side tool-call parser that never '
            'saw its closing tag. Raise the output ceiling or use a provider '
            'that does not drop a partial tool call.',
        errorCode: 'provider_output_lost',
      );
      return;
    }
    // A `max_tokens`-truncated answer is NOT a clean completion — the model
    // was cut off mid-response. Auto-continue (bounded by a consecutive
    // streak) so the answer finishes instead of silently ending truncated.
    if (output.stopReason == LlmStopReason.maxTokens &&
        consecutiveTruncations < _maxConsecutiveTruncations) {
      consecutiveTruncations++;
      history.add(
        HarnessMessage.system(
          'Your previous response was cut off at the output-token limit. '
          'Continue exactly where you left off; do not repeat what you '
          'already wrote.',
        ),
      );
      yield const LoopNotice(
        'Response truncated at the output limit; continuing.',
      );
      return;
    }
    yield* wouldStop(output.text);
  }

  /// Handles a `rewind` call in [pending]: prunes the history back to the
  /// named checkpoint (or the original task), keeping a digest, and drops
  /// checkpoints that pointed into the discarded span.
  ///
  /// An UNKNOWN label is a failure the model must see, not a silent rewind to
  /// the start of the task that reports success: the turn's tools then run
  /// normally and the rewind call gets an error result naming the labels that
  /// exist.
  Future<_RewindOutcome?> _tryRewind(List<_PendingTool> pending) async {
    final call = pending.where((t) => t.name == 'rewind').firstOrNull;
    if (call == null || call.argsError != null) {
      return null;
    }
    final rawLabel = (call.args['checkpoint'] as String?)?.trim();
    final label = (rawLabel == null || rawLabel.isEmpty) ? null : rawLabel;
    final int raw;
    if (label == null) {
      raw = _firstTaskIndex(history);
    } else {
      final at = checkpoints[label];
      if (at == null) {
        final known = checkpoints.keys.toList()..sort();
        final listed = known.isEmpty
            ? 'No checkpoints are set in this run.'
            : 'Set checkpoints: ${known.map((k) => '"$k"').join(', ')}.';
        return _RewindRejected(
          'Unknown checkpoint "$label" — nothing was rewound. $listed '
          'Omit `checkpoint` to rewind to the original task.',
        );
      }
      raw = at;
    }
    final target = raw.clamp(0, history.length);
    final dropped = history.sublist(target);
    // Deferred tools the dropped span had activated are still callable, so
    // the replacement message must carry their names.
    final carriedThroughRewind = <String>{
      for (final message in dropped) ...message.activatedToolNames,
    };
    // A rewind can drop the snapshot page itself. The source goes with the
    // PAGE, identified by its marker.
    if (snapshotSource != null && dropped.any((m) => m.isSnapshotCarrier)) {
      snapshotSource = null;
    }
    final digest = dropped.isEmpty
        ? ''
        : const StructuralHarnessSummarizer().digest(
            HarnessCompactionInput(
              messages: dropped,
              selfAgentName: config.compaction.selfAgentName,
            ),
          );
    history
      ..removeRange(target, history.length)
      ..add(
        HarnessMessage(
          role: HarnessRole.user,
          content: [
            HarnessTextBlock(
              '[Rewound${label != null ? ' to "$label"' : ''}. '
              'Dropped ${dropped.length} exploratory message(s).'
              '${digest.isEmpty ? '' : '\n\n$digest'}\n\nContinue.',
            ),
          ],
          activatedToolNames: carriedThroughRewind.toList(growable: false),
          // What the person said in the dropped span stays theirs: a later
          // compaction pins it.
          carriedPersonTexts: [
            for (final m in dropped) ...[
              ...m.carriedPersonTexts,
              if (m.origin == HarnessMessageOrigin.person &&
                  m.textContent.trim().isNotEmpty)
                m.textContent.trim(),
            ],
          ],
        ),
      );
    // Labels set inside the discarded span now point past (or at a different
    // message than) what they marked; a later rewind to one would clamp and
    // silently drop the wrong span. A label AT the target is still exact.
    checkpoints.removeWhere((_, index) => index > target);
    onHistoryRewritten(reindexed: true);
    return _Rewound(
      'Rewound context${label != null ? ' to "$label"' : ''} '
      '(${dropped.length} messages dropped).',
    );
  }

  /// Turn-ceiling handoff (only reached when a ceiling exists): one final,
  /// tool-free turn to consolidate, so a follow-up "continue" starts from a
  /// handoff instead of nothing. Best-effort: a provider error here must never
  /// mask the ceiling stop.
  Stream<AgentLoopEvent> _turnCeilingHandoff() async* {
    if (cancel.isCancelled || guards.hardBudgetExhausted()) {
      return;
    }
    const handoff =
        'You reached this run\'s turn limit and it is stopping now. Do NOT '
        'call any tool. Write a concise handoff for whoever continues this '
        'work: (1) the task, (2) what you learned — key files, symbols, '
        'decisions, with specifics — (3) what remains, as ordered next '
        'steps.';
    history.add(HarnessMessage.system(handoff));
    final buffer = StringBuffer();
    try {
      await for (final event
          in provider
              .complete(
                messages: history,
                tools: const [],
                config: completeConfig.copyWith(
                  purpose: LlmCallPurpose.sideRequest,
                  callId: '$callIdPrefix:handoff',
                ),
              )
              .untilCancelled(cancel)) {
        switch (event) {
          case LlmTextDelta(:final text):
            buffer.write(text);
            yield LoopTextDelta(text);
          case LlmUsage():
            yield LoopUsage(event);
          default:
            // Thinking, tool deltas, errors: ignored — prose-only and
            // best-effort.
            break;
        }
      }
    } on Object catch (e) {
      yield LoopNotice('Turn-limit handoff failed: $e');
    }
    final text = buffer.toString().trim();
    if (text.isNotEmpty) {
      history.add(HarnessMessage.assistant(text));
    }
  }
}

/// What [_RunState._tryRewind] decided.
sealed class _RewindOutcome {
  const _RewindOutcome();
}

/// The history was rewound; the turn's other calls are dropped with it.
class _Rewound extends _RewindOutcome {
  const _Rewound(this.notice);
  final String notice;
}

/// The rewind was refused (unknown label); the turn's tools run normally.
class _RewindRejected extends _RewindOutcome {
  const _RewindRejected(this.message);
  final String message;
}

/// Runs a third-party extension point, returning a message when it THREW.
///
/// Extension points (hooks, compactor, advisor) are host-supplied: the shipped
/// batteries are safe by construction, but the kernel's exactly-one-terminal
/// event contract must not depend on that.
Future<String?> _guardExtension(
  String label,
  Future<void> Function() action,
) async {
  try {
    await action();
    return null;
  } on Object catch (e) {
    return '$label failed: $e';
  }
}

/// Remaps checkpoint indices across the fold a compaction result performed,
/// using the result's REAL span (a snapshot keeps a verbatim head and folds a
/// region after it).
void _remapCheckpoints(
  Map<String, int> checkpoints,
  HarnessCompactionResult result,
) {
  remapCheckpointsAcrossFold(
    checkpoints,
    foldedFromIndex: result.foldedFromIndex,
    messagesFolded: result.messagesFolded,
  );
}

/// The index just after the original task's opening user message — the
/// default rewind target (keeps the task, drops the exploration).
int _firstTaskIndex(List<HarnessMessage> history) {
  for (var i = 0; i < history.length; i++) {
    if (history[i].role == HarnessRole.user) {
      return i + 1;
    }
  }
  return 0;
}

/// Estimated tokens for the per-request overhead (system prompt + the RESIDENT
/// tool schemas) so compaction budgets against real request size.
int _overheadTokens(String? systemPrompt, List<LlmToolSchema> tools) {
  const est = TokenEstimator.instance;
  var total = est.estimate(systemPrompt ?? '');
  for (final t in tools) {
    total += _schemaTokens(t);
  }
  return total;
}

/// Estimated tokens one tool definition occupies on the wire.
int _schemaTokens(LlmToolSchema t) => TokenEstimator.instance.estimate(
  '${t.name} ${t.description} ${jsonEncode(t.inputSchema)}',
);
