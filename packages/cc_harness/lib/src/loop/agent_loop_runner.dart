import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cc_harness/src/cancellation_token.dart';
import 'package:cc_harness/src/context/harness_compaction.dart';
import 'package:cc_harness/src/context/provider_image_budget.dart';
import 'package:cc_harness/src/context/token_estimator.dart';
import 'package:cc_harness/src/context/tool_output_truncation.dart';
import 'package:cc_harness/src/loop/advisor.dart';
import 'package:cc_harness/src/loop/agent_loop.dart';
import 'package:cc_harness/src/loop/agent_loop_hooks.dart';
import 'package:cc_harness/src/loop/checklist_supervisor.dart';
import 'package:cc_harness/src/loop/completion_contract.dart';
import 'package:cc_harness/src/loop/stream_rules.dart';
import 'package:cc_harness/src/loop/transcript_store.dart';
import 'package:cc_harness/src/messages.dart';
import 'package:cc_harness/src/provider/llm_provider_port.dart';
import 'package:cc_harness/src/tools/tool.dart';

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

/// The single implementation of [AgentLoop]: message → LLM → tools → loop.
///
/// Sends the conversation to the provider, streams its events, executes any
/// tool calls (gated by the approval callback for write/exec tools), appends
/// results and loops until the model stops calling tools, a budget/turn limit
/// is hit, the caller cancels, or an unrecoverable error occurs. Retryable
/// provider errors (rate-limit / overloaded) are retried with exponential
/// backoff.
class AgentLoopRunner implements AgentLoop {
  /// Creates an [AgentLoopRunner].
  const AgentLoopRunner();

  @override
  Stream<AgentLoopEvent> run({
    required List<HarnessMessage> history,
    required String userMessage,
    required List<HarnessTool> tools,
    required LlmProviderPort provider,
    List<HarnessTool> deferredTools = const [],
    HarnessToolContext? context,
    AgentLoopConfig config = const AgentLoopConfig(),
    CancellationToken? cancel,
    List<HarnessImageBlock> userImages = const [],
  }) async* {
    final cancelToken = cancel ?? CancellationToken.none;
    final rng = Random();
    // Deferred tools are CALLABLE from the first turn — only their schemas are
    // withheld. Keeping them in `toolsByName` is what makes a direct call to a
    // name the model saw in the prompt index work in one step instead of
    // costing an "unknown tool" round trip.
    final toolsByName = {
      for (final t in tools) t.name: t,
      for (final t in deferredTools) t.name: t,
    };
    final deferredByName = {for (final t in deferredTools) t.name: t};
    final residentSchemas = tools.map((t) => t.toSchema()).toList();
    // Activation is APPEND-ONLY and never reordered: the resident block is the
    // head of the provider's cache prefix, so appending after it leaves that
    // prefix byte-identical and costs only the new schemas. Removing or
    // reordering would invalidate the whole tools+system prefix on every turn,
    // which is strictly worse than never having deferred at all.
    final activatedNames = <String>[];
    var toolSchemas = residentSchemas;
    var activatedOverheadTokens = 0;
    List<String> activateDeferred(Iterable<String> names) {
      final fresh = [
        for (final n in names)
          if (deferredByName.containsKey(n) && !activatedNames.contains(n)) n,
      ];
      if (fresh.isEmpty) {
        return const [];
      }
      activatedNames.addAll(fresh);
      final added = [for (final n in fresh) deferredByName[n]!.toSchema()];
      for (final s in added) {
        activatedOverheadTokens += _schemaTokens(s);
      }
      toolSchemas = [...toolSchemas, ...added];
      return fresh;
    }

    // Hand the run's cancellation token to tools so a cancelled run kills work
    // in flight (bash, web fetch) instead of only being noticed between tools.
    final ctx = (context ?? const HarnessToolContext(workingDirectory: '.'))
        .withCancel(cancelToken);
    final stopwatch = Stopwatch()..start();

    // The user turn carries any pasted screenshots alongside its text. Built
    // as one message rather than two so the provider sees the picture and the
    // question as a single turn — a bare image message reads to most models as
    // context with no ask attached.
    history.add(
      userImages.isEmpty
          ? HarnessMessage.user(userMessage)
          : HarnessMessage(
              role: HarnessRole.user,
              content: [HarnessTextBlock(userMessage), ...userImages],
            ),
    );

    final completeConfig = LlmCompleteConfig(
      model: config.model,
      systemPrompt: config.systemPrompt,
      maxTokens: config.maxTokens,
      temperature: config.temperature,
      topP: config.topP,
      topK: config.topK,
      effort: config.effort,
      cacheEnabled: config.cacheEnabled,
      cacheKey: config.cacheKey,
    );

    // Where the previous request placed its message-tail cache breakpoint, so
    // this one can anchor its read there. -1 until the first request; reset by
    // compaction, which rewrites history and makes any earlier anchor a
    // pointer into a conversation that no longer exists.
    var cacheAnchorIndex = -1;
    var billableTokens = 0;
    var pressureNotified = false;
    // One-shot latch for the host-priced soft budget steer (section 5b).
    var externalPressureSteered = false;
    // Bounds how many times a mid-run "context too long" rejection triggers a
    // forced compaction + retry before the run gives up (mirrors goose's ×2).
    var overflowRecoveries = 0;
    const maxOverflowRecoveries = 2;
    // Bounds how many times a `max_tokens`-truncated answer (no tool calls) is
    // auto-continued before the loop gives up, so a model that keeps hitting the
    // output ceiling can't spin forever.
    var truncationContinuations = 0;
    const maxTruncationContinuations = 3;
    // The run's deliverable, if it declared one. Tracks whether a required
    // output verb has completed successfully so the loop can tell "finished
    // and delivered" from "stopped talking".
    final ledger = ContractLedger(config.contract);

    // Context management: the system prompt and the RESIDENT tool schemas are
    // constant across the run, so estimate them once for the compaction budget.
    final compactor = config.compactor;
    // Reserve the per-request overhead (system + tool schemas) AND the output
    // budget (max_tokens) so compaction fires before the input+output exceeds
    // the window, not just the input.
    final baseOverheadTokens = compactor == null
        ? 0
        : _overheadTokens(config.systemPrompt, residentSchemas) +
              config.maxTokens;
    // Tools activated mid-run are real request bytes: left out of the budget,
    // a run that pulls in a dozen schemas would compact too late and hit the
    // provider's context ceiling instead of its own.
    int overheadTokensNow() =>
        compactor == null ? 0 : baseOverheadTokens + activatedOverheadTokens;

    final hooks = config.hooks;
    final advisor = config.advisor;
    // Advisor cadence: prompt the reviewer at most once per this many
    // tool-bearing turns. Each review still sees every intervening turn as an
    // accumulated delta and dedupe/noise-suppression live inside the advisor,
    // so the loop just injects whatever survives. Seeded so the first eligible
    // turn reviews, then it throttles.
    final advisorEveryTurns = config.advisorEveryTurns < 1
        ? 1
        : config.advisorEveryTurns;
    var turnsSinceAdvice = advisorEveryTurns - 1;
    // Doom-loop detection: when the model issues the identical set of tool calls
    // (same names + arguments) several turns in a row, inject a corrective
    // reminder so it breaks out. With no turn ceiling (the default) this guard
    // is the primary bound on a spinning run, so it catches both period-1
    // (A-A-A) and period-2 (A-B-A-B ping-pong) cycles.
    const repetitionLimit = 3;
    // Returns-to-two-back before the alternation guard fires: 4 = A-B-A-B-A-B
    // (the ping-pong has cycled three times).
    const alternationLimit = 4;
    // How many turns before the ceiling the wrap-up warning fires (section
    // 0c). Skipped entirely for ceilings at or below this — a tiny budget
    // needs every turn for work, not warnings.
    const turnPressureLead = 5;
    final maxTurns = config.maxTurns;
    String? lastTurnSignature;
    String? prevTurnSignature;
    var repeatedTurns = 0;
    var alternatingTurns = 0;
    // Checklist staleness: an agent that opens a task list, appends to it and
    // then never transitions anything leaves the user watching a list of
    // `pending` items that says nothing about where the run is. Deterministic
    // (a turn count, not a second model) and cheap enough to always run; the
    // host disables it with `checklistStaleAfterTurns: 0`.
    final checklist = config.checklistStaleAfterTurns > 0
        ? ChecklistSupervisor(staleAfterTurns: config.checklistStaleAfterTurns)
        : null;
    final firedRules = <StreamRule>{};
    // Seeded from a restored run, so a `rewind` to a label the model set
    // before a restart still lands where the label was set.
    final checkpoints = <String, int>{...config.initialCheckpoints};
    final transcriptStore = config.transcriptStore;
    final transcriptKey = config.transcriptKey;
    var persistedTurns = 0;

    /// Writes the history as it stands. Called ONLY at a turn boundary: a
    /// history captured between a `tool_use` and its `tool_result` is one no
    /// provider will accept, so a crash at that instant must restore the turn
    /// BEFORE rather than a half-turn that cannot be replayed.
    Future<void> persistTranscript() async {
      if (transcriptStore == null || transcriptKey == null) {
        return;
      }
      try {
        await transcriptStore.save(
          transcriptKey,
          HarnessTranscript(
            messages: List<HarnessMessage>.unmodifiable(history),
            checkpoints: Map<String, int>.unmodifiable(checkpoints),
            turns: persistedTurns,
          ),
        );
      } on Object {
        // Continuity is worth less than the run in progress.
      }
    }

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
        yield LoopError(failure);
        yield const LoopDone(LoopDoneReason.error);
        return;
      }
    }

    for (var turn = 0; maxTurns == null || turn < maxTurns; turn++) {
      // ---- 0a'. Take-over pause: hold at the clean turn boundary until
      //      resumed (PRD 16 §8). The prior turn fully completed, so a human
      //      can safely take the worktree; the hand-back summary arrives as
      //      steering and is drained right below on resume.
      final pauseGate = config.pauseGate;
      if (pauseGate != null && pauseGate.isPaused) {
        yield const LoopNotice('Paused at turn boundary (take-over).');
        // Race the resume against cancellation. Awaiting the gate alone meant
        // a cancel while paused woke NOTHING: the run() stream stayed open,
        // no terminal event was ever emitted, and the run leaked until someone
        // happened to call resume().
        await Future.any<void>([
          pauseGate.waitWhilePaused(),
          cancelToken.whenCancelled,
        ]);
        if (cancelToken.isCancelled) {
          yield const LoopDone(LoopDoneReason.cancelled);
          return;
        }
        yield const LoopNotice('Resumed by hand-back.');
      }

      if (cancelToken.isCancelled) {
        yield const LoopDone(LoopDoneReason.cancelled);
        return;
      }

      // ---- 0. Compact the history when it nears the context window. ----
      // Runs BEFORE the pre-turn boundary is captured so checkpoint/rewind
      // indices refer to the post-compaction list; existing checkpoints are
      // remapped across the fold so they never point into folded messages.
      if (compactor != null && config.contextWindow != null) {
        // A THROWING compactor must not take the run down: compaction is an
        // optimization, and the turn is still runnable without it (the
        // provider's own overflow error is the backstop). Report and continue.
        HarnessCompactionResult? result;
        try {
          result = await compactor.maybeCompact(
            history,
            contextWindow: config.contextWindow,
            overheadTokens: overheadTokensNow(),
            selfAgentName: config.selfAgentName,
          );
        } on Object catch (e) {
          yield LoopNotice('Compaction failed and was skipped: $e');
          result = null;
        }
        if (result != null && result.changed) {
          _remapCheckpoints(checkpoints, result.messagesFolded);
          // The history was rewritten under the advisor's cursor — re-prime it
          // so it re-reads the compacted transcript instead of slicing past
          // its end and can re-raise issues that were folded away.
          advisor?.reset();
          checklist?.resetCadence();
          // Compaction rewrote the messages, so no earlier position can still
          // be a cache hit and the old anchor now points into a conversation
          // that no longer exists. The next request re-anchors from its own
          // tail. (The tools and system prefixes are untouched — a message
          // rewrite costs the message tier only.)
          cacheAnchorIndex = -1;
          yield LoopCompaction(
            summarized: result.summarized,
            messagesFolded: result.messagesFolded,
            tokensBefore: result.tokensBefore,
            tokensAfter: result.tokensAfter,
          );
        }
      }

      // ---- 0b. Mid-run steering: drain any messages queued while the agent
      //      was working and inject them before this turn's provider call, so a
      //      user can nudge a running run without starting a new dispatch.
      final steering = config.steering;
      if (steering != null) {
        for (final msg in steering.drainSteering()) {
          if (msg.content.trim().isNotEmpty) {
            history.add(HarnessMessage.user(msg.content.trim()));
            yield const LoopNotice('Steering message injected.');
          }
        }
        for (final msg in steering.drainAside()) {
          if (msg.content.trim().isNotEmpty) {
            history.add(HarnessMessage.system(msg.content.trim()));
          }
        }
      }

      // ---- 0c. Turn-pressure steering: with only a few turns left, warn the
      //      model while it can still ACT — mirrors the goal-budget pressure
      //      note. The ceiling otherwise stops the run mid-task with every
      //      finding still in volatile history: notes unsaved, memory
      //      unwritten and no real final answer for the next run's context.
      if (maxTurns != null &&
          maxTurns > turnPressureLead &&
          turn == maxTurns - turnPressureLead) {
        const steer =
            'You are nearing this run\'s turn limit — only a few turns left. '
            'Wrap up NOW: save durable findings to your notes or memory tools, '
            'and make your final answer a handoff — what you learned, the '
            'current state and the exact next steps. Anything not written '
            'down is lost when the run stops.';
        history.add(HarnessMessage.system(steer));
        yield const LoopNotice(steer);
      }

      // The clean boundary at the start of this turn (end of a complete prior
      // turn) — where a `checkpoint` marks and a `rewind` truncates to, and
      // the only point at which the history is safe to persist.
      final preTurnLength = history.length;
      persistedTurns = turn;
      await persistTranscript();

      // ---- 1. Provider call (with retry on retryable errors). ----
      // A StringBuffer, not `text += delta`: Dart strings do not rope, so
      // concatenating per delta copies the whole prefix every time — a 32 KB
      // answer arriving in ~4-char deltas costs ~130 MB of copying per turn on
      // the hosting isolate (cc_server), which must also answer RPCs.
      final textBuffer = StringBuffer();
      final thinkingBuffer = StringBuffer();
      String? thinkingSignature;
      final pending = <_PendingTool>[];
      LlmError? lastError;
      var stopReason = LlmStopReason.unknown;
      var attempt = 0;
      var completed = false;
      // Output tokens the provider billed for THIS turn. Compared against what
      // the turn actually delivered to catch a provider that generates tokens
      // and then hands us none of them (see the delivery-ratio guard below).
      var turnOutputTokens = 0;

      // Bounded tail of the streamed text that stream rules are matched
      // against. Matching the WHOLE accumulated buffer per delta is a second
      // O(n²) per turn; a fixed overlap window keeps it O(window) per delta.
      var ruleWindow = '';
      final hasStreamRules = config.streamRules.isNotEmpty;

      while (!completed) {
        textBuffer.clear();
        ruleWindow = '';
        thinkingBuffer.clear();
        thinkingSignature = null;
        pending.clear();
        lastError = null;
        stopReason = LlmStopReason.unknown;
        turnOutputTokens = 0;
        var retry = false;
        var ruleRestart = false;

        // Wall-clock ceiling for THIS turn. The transport's timeout is an IDLE
        // timeout and resets on every chunk, so a stream dripping one byte
        // every 100 seconds trips nothing: the turn never ends, the
        // turn-boundary budget checks never run, and the run holds resources
        // open forever having spent almost no tokens. Checked per event
        // because that is the shape being bounded — a stream that stops
        // producing entirely is already the transport's problem.
        final turnClock = Stopwatch()..start();
        final turnLimit = config.turnTimeout;

        // Provider-side image ceiling, applied per REQUEST rather than per
        // tool call. A browser-driving run adds a frame every turn and each
        // one survives compaction (summarization shrinks text, never a
        // screenshot), so the accumulated count climbs until the provider
        // rejects the request outright. Dropping the oldest frames keeps the
        // turn alive; the newest one is what the agent is reasoning about.
        // Note this shapes only what goes ON THE WIRE — `history` keeps every
        // image, so a later compaction still sees the real conversation.
        final wireMessages = clampProviderContextImages(
          history,
          providerImageLimitFor(provider.displayName),
        );
        // The cache breakpoints this request should carry. The tools
        // breakpoint sits at the end of the RESIDENT block so activation
        // appends behind it; the message anchor points at where the previous
        // request wrote, which is what makes the read a certainty rather than
        // a bet on the provider's bounded backward search.
        final requestConfig = completeConfig.copyWith(
          toolCacheBreakpointIndex: residentSchemas.length - 1,
          cacheAnchorIndex: cacheAnchorIndex,
        );
        // Recorded BEFORE the call: this is the tail this request writes at,
        // and therefore the anchor the next one must read from.
        cacheAnchorIndex = wireMessages.length - 1;
        await for (final event in provider.complete(
          messages: wireMessages,
          tools: toolSchemas,
          config: requestConfig,
        )) {
          if (cancelToken.isCancelled) {
            yield const LoopDone(LoopDoneReason.cancelled);
            return;
          }
          if (turnLimit != null && turnClock.elapsed > turnLimit) {
            yield LoopNotice(
              'Turn exceeded its ${turnLimit.inMinutes}-minute wall-clock '
              'limit and was abandoned. The provider stream was still open.',
            );
            yield const LoopDone(LoopDoneReason.error);
            return;
          }
          switch (event) {
            case LlmTextDelta(:final text):
              textBuffer.write(text);
              yield LoopTextDelta(text);
              if (hasStreamRules) {
                final probe = ruleWindow + text;
                ruleWindow = probe.length > _streamRuleWindowChars
                    ? probe.substring(probe.length - _streamRuleWindowChars)
                    : probe;
                final rule = _firstUnfiredRule(
                  config.streamRules,
                  firedRules,
                  probe,
                );
                if (rule != null) {
                  firedRules.add(rule);
                  history.add(HarnessMessage.system(rule.reminder));
                  yield LoopNotice('Course-correction: ${rule.reminder}');
                  ruleRestart = true;
                }
              }
            case LlmThinkingDelta(:final thinking, :final signature):
              if (signature != null) {
                thinkingSignature = signature;
              }
              if (thinking.isNotEmpty) {
                thinkingBuffer.write(thinking);
                yield LoopThinkingDelta(thinking);
              }
            case LlmToolUseDelta(:final id, :final name, :final argumentsJson):
              pending.add(_PendingTool.fromStream(id, name, argumentsJson));
            case LlmUsage(
              :final inputTokens,
              :final outputTokens,
              :final cacheWriteTokens,
            ):
              billableTokens += inputTokens + outputTokens + cacheWriteTokens;
              turnOutputTokens += outputTokens;
              yield LoopUsage(event);
            case LlmError():
              lastError = event;
              if (event.retryable && attempt < config.maxProviderRetries) {
                retry = true;
              }
            case LlmDone(stopReason: final reason):
              stopReason = reason;
              break;
          }
          // A stream rule fired: abandon this turn's stream and restart with
          // the reminder now in history.
          if (ruleRestart) {
            break;
          }
        }

        if (ruleRestart) {
          continue;
        }
        // ---- 1b. Empty-stream guard. ----
        // A stream that delivered NOTHING — no text, no thinking, no tool call,
        // no error and no recognized stop reason — is a transport or
        // server-side parser failure wearing the shape of a finished turn.
        // Observed on an OpenAI-compatible local server whose tool-call parser
        // buffers from `<tool_call>` to the closing tag and returns an empty
        // body when generation is cut off before the closer arrives.
        //
        // Without this, the loop banked that as an assistant turn with no tool
        // calls and reported the provider's failure as the model's answer —
        // the single worst reading available. Synthesize a retryable error so
        // the existing backoff handles it and an exhausted retry budget fails
        // the run out loud.
        if (lastError == null &&
            pending.isEmpty &&
            textBuffer.isEmpty &&
            thinkingBuffer.isEmpty &&
            stopReason == LlmStopReason.unknown) {
          lastError = const LlmError(
            'Provider returned an empty response: no content, no tool call, '
            'and no stop reason. That is a transport or server-side parser '
            'failure, not a finished turn.',
            code: 'empty_response',
            retryable: true,
          );
          if (attempt < config.maxProviderRetries) {
            retry = true;
          }
        }
        if (retry) {
          attempt++;
          // Honor a server Retry-After hint when present; otherwise exponential
          // backoff. Cap at 30s and apply full jitter (sleep in [50%, 100%] of
          // the target) to avoid synchronized retry storms.
          final retryAfterMs = lastError?.retryAfterMs;
          final baseMs = retryAfterMs ?? (500 * (1 << (attempt - 1)));
          final cappedMs = baseMs > 30000 ? 30000 : baseMs;
          final delayMs = (cappedMs * (0.5 + rng.nextDouble() * 0.5)).round();
          yield LoopNotice(
            'Provider error (${lastError?.code ?? 'unknown'}); '
            'retrying in ${delayMs}ms (attempt $attempt).',
          );
          // Cancellable sleep: a 30s backoff that ignores the token kept a
          // cancelled run alive for up to 30s per attempt.
          await Future.any<void>([
            Future<void>.delayed(Duration(milliseconds: delayMs)),
            cancelToken.whenCancelled,
          ]);
          if (cancelToken.isCancelled) {
            yield const LoopDone(LoopDoneReason.cancelled);
            return;
          }
          continue;
        }
        if (lastError != null) {
          // Reactive context-overflow recovery: the provider rejected the
          // request as too large. Force a compaction pass and re-issue the same
          // turn instead of failing the run.
          if (compactor != null &&
              config.contextWindow != null &&
              overflowRecoveries < maxOverflowRecoveries &&
              _isContextOverflow(lastError)) {
            overflowRecoveries++;
            final result = await compactor.maybeCompact(
              history,
              contextWindow: config.contextWindow,
              overheadTokens: overheadTokensNow(),
              selfAgentName: config.selfAgentName,
              force: true,
            );
            if (result.changed) {
              _remapCheckpoints(checkpoints, result.messagesFolded);
              // Same rewrite hazard as the loop-top compaction: re-prime the
              // advisor so its cursor doesn't slice into the rewritten history.
              advisor?.reset();
              checklist?.resetCadence();
              yield LoopCompaction(
                summarized: result.summarized,
                messagesFolded: result.messagesFolded,
                tokensBefore: result.tokensBefore,
                tokensAfter: result.tokensAfter,
              );
              yield const LoopNotice(
                'Context window exceeded; compacted history and retrying.',
              );
              continue;
            }
          }
          yield LoopError(lastError.message, code: lastError.code);
          yield const LoopDone(LoopDoneReason.error);
          return;
        }
        completed = true;
      }

      // ---- 2. Assemble + append the assistant turn. ----
      final blocks = <HarnessContentBlock>[];
      if (thinkingBuffer.isNotEmpty || thinkingSignature != null) {
        blocks.add(
          HarnessThinkingBlock(
            thinkingBuffer.toString(),
            signature: thinkingSignature,
          ),
        );
      }
      if (textBuffer.isNotEmpty) {
        blocks.add(HarnessTextBlock(textBuffer.toString()));
      }
      for (final t in pending) {
        blocks.add(HarnessToolUseBlock(id: t.id, name: t.name, input: t.args));
      }
      final assistantMsg = HarnessMessage(
        role: HarnessRole.assistant,
        content: blocks.isEmpty ? const [HarnessTextBlock('')] : blocks,
      );
      history.add(assistantMsg);
      yield LoopTurnComplete(assistantMsg);

      // ---- 3. Stop when the model is done (no tool calls). ----
      if (pending.isEmpty) {
        // ---- 3a'. Output-loss guard: billed for tokens we never received.
        // A buffering tool-call parser (vLLM `qwen3_xml`, SGLang `qwen3_coder`
        // and friends) swallows everything from `<tool_call>` until the closing
        // tag. When generation is cut off at `max_tokens` the closer never
        // arrives, the buffer is discarded and the turn reports thousands of
        // output tokens while delivering almost nothing.
        //
        // Auto-continuing is worse than useless here: the retry re-rolls the
        // SAME ceiling and loses the buffer again. That is how one run burned
        // four turns × 8192 tokens to produce two newlines. Detect it by
        // delivery ratio and stop, because the remedy (a larger ceiling, or a
        // server whose parser does not drop its buffer) is not something more
        // turns can reach.
        final deliveredChars = textBuffer.length + thinkingBuffer.length;
        if (stopReason == LlmStopReason.maxTokens &&
            turnOutputTokens >= _minTokensForLossCheck &&
            deliveredChars < turnOutputTokens * _minCharsPerOutputToken) {
          yield LoopError(
            'The provider billed $turnOutputTokens output tokens for this turn '
            'but delivered only $deliveredChars characters and cut the turn '
            'off at the output ceiling. The response was almost certainly '
            'discarded by a server-side tool-call parser that never saw its '
            'closing tag. Raise the output ceiling or use a provider that does '
            'not drop a partial tool call.',
            code: 'provider_output_lost',
          );
          yield const LoopDone(LoopDoneReason.providerOutputLost);
          return;
        }
        // A `max_tokens`-truncated answer is NOT a clean completion — the model
        // was cut off mid-response. Auto-continue (bounded) so the answer
        // finishes instead of silently ending truncated.
        if (stopReason == LlmStopReason.maxTokens &&
            truncationContinuations < maxTruncationContinuations) {
          truncationContinuations++;
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
          continue;
        }
        // Follow-up lane: queued messages meant to run once the agent finishes.
        // Consume them here so the work continues in the same run instead of
        // ending and requiring a new dispatch.
        final followUps = steering?.drainFollowUp() ?? const [];
        if (followUps.isNotEmpty) {
          for (final msg in followUps) {
            if (msg.content.trim().isNotEmpty) {
              history.add(HarnessMessage.user(msg.content.trim()));
            }
          }
          yield const LoopNotice('Follow-up message injected; continuing.');
          continue;
        }
        // ---- 3c. Completion contract: the model is about to stop. If the run
        //      owes a deliverable and none was produced, nudge once (bounded)
        //      before accepting the stop; if it still has not delivered, end
        //      with `contractUnmet` so "researched and produced nothing" can
        //      never be reported as success.
        //
        //      Ordered AFTER the follow-up drain deliberately: real user
        //      steering outranks the reminder and `maxNudges` bounds the delay
        //      so a follow-up is never starved.
        if (ledger.isActive && !await ledger.resolveSatisfied()) {
          if (ledger.canNudge) {
            history.add(HarnessMessage.system(ledger.takeNudge()));
            yield LoopNotice(
              'Completion contract "${ledger.contract!.id}" unmet — '
              'steering the agent to deliver.',
            );
            continue;
          }
          yield LoopDone(
            LoopDoneReason.contractUnmet,
            unmetContractId: ledger.contract!.id,
          );
          return;
        }
        yield const LoopDone(LoopDoneReason.completed);
        return;
      }

      // ---- 3b. Rewind: if the model asked to rewind, prune the exploration
      //      back to a checkpoint (or the original task), keeping a digest and
      //      start the next turn from there. Drops this turn's assistant
      //      message (incl. the rewind call) so no tool_use is orphaned.
      final rewindCall = pending.where((t) => t.name == 'rewind').firstOrNull;
      if (rewindCall != null) {
        final label = rewindCall.args['checkpoint'] as String?;
        final raw =
            (label != null ? checkpoints[label] : null) ??
            _firstTaskIndex(history);
        final target = raw.clamp(0, history.length);
        final dropped = history.sublist(target);
        final digest = dropped.isEmpty
            ? ''
            : await const StructuralHarnessSummarizer().summarize(
                HarnessCompactionInput(
                  messages: dropped,
                  selfAgentName: config.selfAgentName,
                ),
              );
        history.removeRange(target, history.length);
        history.add(
          HarnessMessage(
            role: HarnessRole.user,
            content: [
              HarnessTextBlock(
                '[Rewound${label != null ? ' to "$label"' : ''}. '
                'Dropped ${dropped.length} exploratory message(s).'
                '${digest.isEmpty ? '' : '\n\n$digest'}\n\nContinue.',
              ),
            ],
          ),
        );
        // History was rewritten under the advisor's cursor (same hazard as the
        // two compaction sites) — re-prime it so it re-reads the rewound
        // transcript instead of slicing past its end.
        advisor?.reset();
        checklist?.resetCadence();
        yield LoopNotice(
          'Rewound context${label != null ? ' to "$label"' : ''} '
          '(${dropped.length} messages dropped).',
        );
        continue;
      }

      // ---- 4. Execute tool calls, append results. ----
      // Read-only tools carry no side effects and no approval, so a run of them
      // executes concurrently;
      // write/exec/control tools stay strictly sequential ("exclusive"). Only
      // batched when no hook INTERCEPTS TOOLS, since a per-tool veto or
      // observation must run in the model's original order — a hook that only
      // handles session start observes nothing per tool and so must not cost
      // the run its batching. Result blocks are always appended in the model's
      // original tool-call order so pairing is unambiguous.
      // A deferred tool called by name loads its schema and then runs in the
      // SAME step. The model saw the name in the prompt's tool index, so
      // answering "unknown tool, go search for it" would be a round trip spent
      // telling it something it already knew. From here on the schema rides
      // every request, so follow-up calls are ordinary calls.
      final activatedByCall = activateDeferred(pending.map((t) => t.name));
      if (activatedByCall.isNotEmpty) {
        yield LoopToolsActivated(
          names: activatedByCall,
          trigger: 'direct_call',
        );
      }
      final batchingAllowed = hooks == null || !hooks.interceptsTools;
      final resultBlocks = <HarnessToolResultBlock>[];
      // Deferred tools a RESULT asked for (a tool search loading its hits), so
      // the model can call one on its next turn rather than spending a round
      // trip asking for the schema it just read a description of.
      final requestedActivations = <String>[];
      var pi = 0;
      while (pi < pending.length) {
        if (cancelToken.isCancelled) {
          yield const LoopDone(LoopDoneReason.cancelled);
          return;
        }
        if (batchingAllowed &&
            pending[pi].argsError == null &&
            _isParallelSafe(toolsByName[pending[pi].name])) {
          // Gather a run of consecutive parallel-safe tools, capped at the
          // per-wave concurrency limit; anything left over runs in the next
          // wave (still concurrently and still cancellable in between).
          final waveLimit = config.maxParallelToolCalls < 1
              ? 1
              : config.maxParallelToolCalls;
          final batch = <_PendingTool>[];
          while (pi < pending.length &&
              batch.length < waveLimit &&
              pending[pi].argsError == null &&
              _isParallelSafe(toolsByName[pending[pi].name])) {
            batch.add(pending[pi]);
            pi++;
          }
          for (final b in batch) {
            yield LoopToolCallStart(
              toolName: b.name,
              toolUseId: b.id,
              args: b.args,
            );
          }
          final results = await Future.wait([
            for (final b in batch)
              _safeExecute(
                toolsByName[b.name]!,
                b.args,
                ctx,
                toolCallId: b.id,
                timeout: config.toolTimeout,
              ),
          ]);
          for (var k = 0; k < batch.length; k++) {
            ledger.recordToolResult(batch[k].name, isError: results[k].isError);
            requestedActivations.addAll(results[k].activateTools);
            yield LoopToolCallResult(
              toolName: batch[k].name,
              toolUseId: batch[k].id,
              result: results[k],
            );
            resultBlocks.add(
              HarnessToolResultBlock(
                toolUseId: batch[k].id,
                content: _budgetedContent(batch[k].name, results[k]),
                isError: results[k].isError,
                images: _budgetedImages(batch[k].name, results[k]),
              ),
            );
          }
          continue;
        }
        final t = pending[pi];
        pi++;
        yield LoopToolCallStart(
          toolName: t.name,
          toolUseId: t.id,
          args: t.args,
        );
        final tool = toolsByName[t.name];
        HarnessToolResult result;
        final argsError = t.argsError;
        if (argsError != null) {
          // Refused before dispatch: running a tool with arguments we know are
          // wrong produces a failure that blames the tool.
          result = HarnessToolResult.error(argsError);
        } else if (t.name == 'checkpoint') {
          // Loop-handled: mark the clean boundary at the start of this turn.
          final label = (t.args['label'] as String?)?.trim();
          final key = (label == null || label.isEmpty) ? 'default' : label;
          checkpoints[key] = preTurnLength;
          result = HarnessToolResult.success('Checkpoint "$key" set.');
        } else if (tool == null) {
          // Deliberately does NOT enumerate the catalogue: with a deferred
          // surface that list is ~130 names, and reprinting it into a tool
          // result every time the model fat-fingers one is the context cost
          // deferral was meant to remove. Point at the search instead.
          result = HarnessToolResult.error(
            deferredByName.isEmpty
                ? 'Unknown tool: ${t.name}. '
                      'Available tools: ${toolsByName.keys.join(', ')}.'
                : 'Unknown tool: ${t.name}. Call `search_tools` to find the '
                      'right tool for what you are trying to do, or '
                      '`list_my_tools` to browse everything available.',
          );
        } else if (hooks != null &&
            !await _preToolUseAllows(hooks, t.name, t.args)) {
          result = HarnessToolResult.error('Denied by policy hook.');
        } else if (_requiresApproval(tool)) {
          if (config.approvalCallback != null) {
            final decision = await config.approvalCallback!(tool, t.args);
            result = decision.allowed
                ? await _safeExecute(
                    tool,
                    t.args,
                    ctx,
                    toolCallId: t.id,
                    timeout: config.toolTimeout,
                  )
                // Carries the policy's own reason + remediation so the model can
                // replan instead of guessing who denied it and why.
                : HarnessToolResult.error(decision.deniedMessage);
          } else if (config.autoApprove) {
            result = await _safeExecute(
              tool,
              t.args,
              ctx,
              toolCallId: t.id,
              timeout: config.toolTimeout,
            );
          } else {
            // Fail closed: a privileged tool must never run without an approver.
            result = HarnessToolResult.error(
              'Denied: "${tool.name}" requires approval but no approver is '
              'configured for this run.',
            );
          }
        } else {
          result = await _safeExecute(
            tool,
            t.args,
            ctx,
            toolCallId: t.id,
            timeout: config.toolTimeout,
          );
        }
        if (hooks != null) {
          // Report-only: the tool has ALREADY run, so a throwing observer must
          // not turn a completed call into a dead run.
          final failure = await _guardExtension(
            'postToolUse hook',
            () => hooks.postToolUse(
              t.name,
              result.content,
              isError: result.isError,
            ),
          );
          if (failure != null) {
            yield LoopNotice(failure);
          }
        }
        ledger.recordToolResult(t.name, isError: result.isError);
        requestedActivations.addAll(result.activateTools);
        yield LoopToolCallResult(
          toolName: t.name,
          toolUseId: t.id,
          result: result,
        );
        resultBlocks.add(
          HarnessToolResultBlock(
            toolUseId: t.id,
            content: _budgetedContent(t.name, result),
            isError: result.isError,
            images: _budgetedImages(t.name, result),
          ),
        );
      }
      history.add(HarnessMessage.toolResults(resultBlocks));
      final activatedByRequest = activateDeferred(requestedActivations);
      if (activatedByRequest.isNotEmpty) {
        yield LoopToolsActivated(
          names: activatedByRequest,
          // Attributed to the tool that asked, so a search that activates
          // nothing is visibly a retrieval miss rather than silent noise.
          trigger: pending.map((t) => t.name).toSet().join(','),
        );
      }

      // Doom-loop guard: detect cycles in the per-turn tool-call signature.
      // Period-1 (A-A-A): this turn's calls are byte-identical to the previous
      // turn's. Period-2 (A-B-A-B): the model ping-pongs between two call
      // sets — the classic "edit, revert, edit, revert" loop a period-1 check
      // never sees. Past the limit, nudge the model to change approach (fires
      // once per breach, then re-arms).
      final turnSignature = [
        for (final t in pending) '${t.name}:${jsonEncode(t.args)}',
      ].join('|');
      if (turnSignature == lastTurnSignature) {
        repeatedTurns++;
        alternatingTurns = 0;
      } else if (turnSignature == prevTurnSignature &&
          turnSignature != lastTurnSignature) {
        alternatingTurns++;
        repeatedTurns = 1;
      } else {
        repeatedTurns = 1;
        alternatingTurns = 0;
      }
      prevTurnSignature = lastTurnSignature;
      lastTurnSignature = turnSignature;
      if (repeatedTurns >= repetitionLimit ||
          alternatingTurns >= alternationLimit) {
        final alternating = alternatingTurns >= alternationLimit;
        repeatedTurns = 0;
        alternatingTurns = 0;
        history.add(
          HarnessMessage.system(
            alternating
                ? 'You are alternating between the same two tool call sets '
                      'and getting nowhere — a ping-pong loop. Stop cycling: '
                      'pick a different approach, or explain what is blocking '
                      'you and ask for guidance.'
                : 'You have repeated the same tool call(s) with identical '
                      'arguments $repetitionLimit turns in a row and are '
                      'getting the same result. Stop repeating — change your '
                      'approach, or explain what is blocking you and ask for '
                      'guidance.',
          ),
        );
        yield const LoopNotice(
          'Repetition detected; steering the agent to change approach.',
        );
      }

      // ---- 4a2. Checklist supervision: nudge once when the task list has open
      //      items the agent has stopped maintaining. Free (no model call) and
      //      silent on any turn that did write the list.
      if (checklist != null) {
        final steer = checklist.observeTurn([
          for (final t in pending) (name: t.name, args: t.args),
        ]);
        if (steer != null) {
          history.add(HarnessMessage.system(steer));
          yield const LoopNotice(
            'Task checklist is stale; steering the agent to update it.',
          );
        }
      }

      // Reclaim uneventful older tool results — but only once there is enough
      // to reclaim to be worth the cached prefix it rewrites. This used to run
      // unconditionally every tool-bearing turn, which meant editing the
      // middle of history continuously and paying full price for the whole
      // conversation to save a few dozen tokens. Batched, it is a rare deep
      // rewrite instead of a permanent cache leak. Full compaction remains the
      // heavier fallback at the loop top.
      final elided = compactor?.pruneToolResults(history) ?? 0;
      if (elided > 0) {
        // The rewrite invalidated everything from the earliest edit onward, so
        // the anchor no longer names a position any request wrote at.
        cacheAnchorIndex = -1;
      }

      // ---- 4b. Advisor: a second model reviews the turn and may inject a
      //      steering note before the next turn. Rate-limited to at most once
      //      per `advisorImmuneTurns` tool-turns and deduped, so it neither
      //      doubles the model spend nor nags with the same note repeatedly.
      turnsSinceAdvice++;
      if (advisor != null && turnsSinceAdvice >= advisorEveryTurns) {
        turnsSinceAdvice = 0;
        AdvisorNote? note;
        try {
          note = await advisor.review(history);
        } on Object catch (e) {
          // Advice is optional by construction; a failing reviewer costs the
          // note, not the run.
          yield LoopNotice('Advisor review failed and was skipped: $e');
          note = null;
        }
        if (note != null) {
          history.add(HarnessMessage.system(_formatAdvisory(note)));
          yield LoopAdvisorNote(note.note, severity: note.severity);
        }
      }

      // ---- 5. Budget enforcement (goal mode). Time and tokens are handled
      //      symmetrically: a hard budget stops the run; a soft budget steers
      //      once at the pressure threshold and again when exhausted, then lets
      //      the model finish naturally.
      final budget = config.budget;
      if (budget.isActive) {
        final timeBudget = budget.timeBudget;
        final tokenBudget = budget.tokenBudget;
        final timeExhausted =
            timeBudget != null && stopwatch.elapsed >= timeBudget;
        final tokenExhausted =
            tokenBudget != null && billableTokens >= tokenBudget;
        if (timeExhausted || tokenExhausted) {
          if (budget.hardStop) {
            yield LoopNotice(
              tokenExhausted
                  ? 'Token budget exhausted.'
                  : 'Time budget '
                        'exhausted.',
            );
            yield LoopDone(
              LoopDoneReason.budgetExhausted,
              unmetContractId: ledger.isActive && !ledger.satisfied
                  ? ledger.contract!.id
                  : null,
            );
            return;
          }
          if (!pressureNotified) {
            pressureNotified = true;
            const steer =
                'Your budget is exhausted. Wrap up and deliver your '
                'result now.';
            history.add(HarnessMessage.system(steer));
            yield const LoopNotice(steer);
          }
        } else if (!pressureNotified) {
          final timePressure =
              timeBudget != null &&
              stopwatch.elapsed >= timeBudget * budget.pressureFraction;
          final tokenPressure =
              tokenBudget != null &&
              billableTokens >= tokenBudget * budget.pressureFraction;
          if (timePressure || tokenPressure) {
            pressureNotified = true;
            const steer =
                'You are approaching your budget. Wrap up your '
                'work and deliver your result now.';
            history.add(HarnessMessage.system(steer));
            yield const LoopNotice(steer);
          }
        }
      }
      // ---- 5b. External budget (host-priced): the dispatch layer alone can
      //      price usage, so it hands the loop a poll instead of a number.
      //      Soft pressure steers once (wrap up + leave a clean handoff)
      //      before the hard stop ends the run mid-task; the host's own
      //      messaging carries the why.
      if (!externalPressureSteered &&
          (config.externalBudgetPressure?.call() ?? false)) {
        externalPressureSteered = true;
        const steer =
            'You are approaching this run\u2019s cost budget. Wrap up '
            'your work NOW: persist important notes, leave the worktree in a '
            'coherent state and deliver your result \u2014 a follow-up run '
            'continues from what you leave behind.';
        history.add(HarnessMessage.system(steer));
        yield const LoopNotice(steer);
      }
      if (config.externalBudgetExceeded?.call() ?? false) {
        yield const LoopNotice('External budget exhausted.');
        yield LoopDone(
          LoopDoneReason.budgetExhausted,
          unmetContractId: ledger.isActive && !ledger.satisfied
              ? ledger.contract!.id
              : null,
        );
        return;
      }
    }

    // ---- 6. Turn-ceiling handoff (only reached when a ceiling exists). ----
    // Hitting the ceiling mid-task used to discard everything the run learned:
    // the history died with the loop and only the last prose fragment reached
    // the space, so a follow-up "continue" started from nothing. Give the
    // model one final, tool-free turn to consolidate. The text streams like
    // any answer, so it lands in the persisted message the next run's
    // conversation context rebuilds from — and the human sees what happened.
    // Best-effort: a provider error here must never mask the ceiling stop.
    if (!cancelToken.isCancelled) {
      const handoff =
          'You reached this run\'s turn limit and it is stopping now. Do NOT '
          'call any tool. Write a concise handoff for whoever continues this '
          'work: (1) the task, (2) what you learned — key files, symbols, '
          'decisions, with specifics — (3) what remains, as ordered next '
          'steps.';
      history.add(HarnessMessage.system(handoff));
      final handoffBuffer = StringBuffer();
      await for (final event in provider.complete(
        messages: history,
        tools: const [],
        config: completeConfig,
      )) {
        if (cancelToken.isCancelled) {
          break;
        }
        switch (event) {
          case LlmTextDelta(:final text):
            handoffBuffer.write(text);
            yield LoopTextDelta(text);
          case LlmUsage():
            yield LoopUsage(event);
          default:
            // Thinking, tool deltas, errors: ignored — this turn is
            // prose-only and best-effort.
            break;
        }
      }
      final handoffText = handoffBuffer.toString().trim();
      if (handoffText.isNotEmpty) {
        history.add(HarnessMessage.assistant(handoffText));
      }
    }

    // Turn ceiling reached (only reachable when a ceiling is configured —
    // an uncapped loop never exits the turn loop normally). The primary cause
    // stays `maxTurns`, but an unmet contract rides along: "ran out of turns
    // without delivering" and "ran out of turns after delivering" are
    // different products.
    yield LoopDone(
      LoopDoneReason.maxTurns,
      unmetContractId: ledger.isActive && !ledger.satisfied
          ? ledger.contract!.id
          : null,
    );
  }

  /// Whether [tool] must clear the approval gate before running. A tool is
  /// gated when it is above read-tier OR declares any PRD 24 effect class (so a
  /// bridged MCP tool that is mis-tiered `read` but really performs a
  /// prPublish/fileDelete effect is still gated — its declared classes, not its
  /// tier, are authoritative). Self-guarding tools (sandboxed `bash`) stay
  /// exempt: they enforce their own finer-grained command policy in the runner.
  bool _requiresApproval(HarnessTool tool) =>
      (tool.approvalTier != ToolApprovalTier.read ||
          tool.actionClasses.isNotEmpty) &&
      !tool.selfGuards;

  /// Whether [tool] is safe to run concurrently with sibling calls in the same
  /// turn: a known tool that declares itself [HarnessTool.parallelSafe], needs
  /// no approval from the loop and is not one the loop handles itself
  /// (checkpoint/rewind). Ordering among these is irrelevant.
  ///
  /// The [_requiresApproval] clause matters: the batch path calls the tool
  /// directly, so anything that would otherwise be gated must not be batched.
  /// That keeps a read-tiered-but-effectful bridged MCP tool (non-empty
  /// [HarnessTool.actionClasses]) on the sequential path where its approval
  /// still fires, instead of slipping through ungated.
  bool _isParallelSafe(HarnessTool? tool) =>
      tool != null &&
      tool.parallelSafe &&
      !_requiresApproval(tool) &&
      !harnessControlToolNames.contains(tool.name);

  /// The images from [result] capped to the per-tool budget.
  ///
  /// Applied by the loop rather than by each tool: a tool that captures three
  /// frames should not have to know the transcript's image economics, and a
  /// bridged MCP tool could not know them at all. Images cost ~1200 tokens
  /// each and survive compaction (which shrinks text but cannot shrink a
  /// screenshot), so an unbudgeted tool would quietly eat the window.
  List<HarnessImageBlock> _budgetedImages(
    String toolName,
    HarnessToolResult result,
  ) {
    if (result.images.isEmpty) {
      return const [];
    }
    return capToolImages(
      result.images,
      ToolOutputLimitTable.defaults.forTool(toolName),
    );
  }

  /// [result]'s text capped to the per-tool budget, with an explicit omission
  /// marker where content was dropped.
  ///
  /// Applied HERE and not in each tool, for the same reason the image budget
  /// is: a tool that dumps a DOM should not have to know the transcript's
  /// economics, and a bridged MCP tool could not know them at all. The limits
  /// table existed and was documented long before anything called it — a
  /// single 400k-character output would blow the window in one turn, and the
  /// only symptom was a compaction that fired immediately and lost the turn's
  /// context.
  ///
  /// The full, untruncated text still reaches the UI through
  /// [LoopToolCallResult]; only the model's copy is bounded. A human looking
  /// at a run wants what actually happened.
  String _budgetedContent(String toolName, HarnessToolResult result) {
    if (result.content.isEmpty) {
      return result.content;
    }
    return truncateToolOutput(
      result.content,
      ToolOutputLimitTable.defaults.forTool(toolName),
    ).content;
  }

  /// Whether the pre-tool gate allows the call. A THROWING gate denies.
  ///
  /// Fail-closed matches the rest of the approval machinery: a hook that
  /// cannot answer is not permission, and the previous behaviour (the
  /// exception escaping the loop's `async*` generator) both skipped the
  /// terminal event AND left the caller unable to tell allow from error.
  static Future<bool> _preToolUseAllows(
    AgentLoopHooks hooks,
    String name,
    Map<String, dynamic> args,
  ) async {
    try {
      return await hooks.preToolUse(name, args);
    } on Object {
      return false;
    }
  }

  /// Runs a third-party extension point, returning a message when it THREW.
  ///
  /// Extension points (hooks, compactor, advisor) are host-supplied: the
  /// shipped batteries are safe by construction, but the kernel's
  /// exactly-one-terminal-event contract must not depend on that.
  static Future<String?> _guardExtension(
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

  Future<HarnessToolResult> _safeExecute(
    HarnessTool tool,
    Map<String, dynamic> args,
    HarnessToolContext context, {
    String? toolCallId,
    Duration? timeout,
  }) async {
    try {
      final execution = tool.execute(args, context.withToolCallId(toolCallId));
      final cancel = context.cancel;
      if (timeout == null && cancel == null) {
        return await execution;
      }
      // Race the tool against its deadline AND the cancellation token. The
      // kernel cannot kill the tool's work (it holds no handle on it), but it
      // can stop WAITING — which is the difference between a turn that ends
      // and a turn that is stuck forever behind one tool.
      final guard = Completer<HarnessToolResult>();
      unawaited(
        execution.then(
          (r) => guard.isCompleted ? null : guard.complete(r),
          onError: (Object e) => guard.isCompleted
              ? null
              : guard.complete(
                  HarnessToolResult.error('Tool "${tool.name}" failed: $e'),
                ),
        ),
      );
      if (timeout != null) {
        unawaited(
          Future<void>.delayed(timeout).then((_) {
            if (!guard.isCompleted) {
              guard.complete(
                HarnessToolResult.error(
                  'Tool "${tool.name}" exceeded its ${timeout.inSeconds}s '
                  'time limit and was abandoned. Its work may still be '
                  'running; do not assume it finished.',
                ),
              );
            }
          }),
        );
      }
      if (cancel != null) {
        unawaited(
          cancel.whenCancelled.then((_) {
            if (!guard.isCompleted) {
              guard.complete(
                HarnessToolResult.error('Tool "${tool.name}" was cancelled.'),
              );
            }
          }),
        );
      }
      return await guard.future;
    } on Object catch (e) {
      return HarnessToolResult.error('Tool "${tool.name}" failed: $e');
    }
  }

  /// Remaps checkpoint indices across a compaction that folded [foldedCount]
  /// leading messages into a single summary message. Indices inside the folded
  /// region collapse to the tail start (1, just after the summary); indices in
  /// the kept tail shift left by `foldedCount - 1`.
  static void _remapCheckpoints(Map<String, int> checkpoints, int foldedCount) {
    if (foldedCount <= 0 || checkpoints.isEmpty) {
      return;
    }
    checkpoints.updateAll(
      (_, index) => index >= foldedCount ? index - foldedCount + 1 : 1,
    );
  }

  /// Frames an advisor note as the agent-facing `<advisory>` block, severity as
  /// an attribute. Injected as a `HarnessRole.system` message (rendered as a
  /// cache-safe `<system-reminder>` user block by the provider). The `guidance`
  /// attribute is the model's only cue for how to treat it: advice to weigh,
  /// not an order to obey.
  static String _formatAdvisory(AdvisorNote note) =>
      '<advisory severity="${note.severity.name}" '
      'guidance="weigh, do not blindly obey">\n'
      '${note.note}\n'
      '</advisory>';

  /// Whether a provider error signals the request exceeded the model's context
  /// window (as opposed to a rate-limit / auth / transient failure). Matches the
  /// error codes and message phrasings used by Anthropic, OpenAI-compatible and
  /// local providers.
  static bool _isContextOverflow(LlmError error) {
    final code = error.code?.toLowerCase() ?? '';
    if (code.contains('context_length') ||
        code.contains('context_window') ||
        code == 'context_length_exceeded') {
      return true;
    }
    final msg = error.message.toLowerCase();
    return msg.contains('context length') ||
        msg.contains('context window') ||
        msg.contains('maximum context') ||
        msg.contains('context_length_exceeded') ||
        msg.contains('prompt is too long') ||
        msg.contains('too many tokens') ||
        (msg.contains('token') && msg.contains('exceed'));
  }

  /// The index just after the original task's opening user message — the
  /// default rewind target (keeps the task, drops the exploration).
  static int _firstTaskIndex(List<HarnessMessage> history) {
    for (var i = 0; i < history.length; i++) {
      if (history[i].role == HarnessRole.user) {
        return i + 1;
      }
    }
    return 0;
  }

  /// The first stream rule that matches [text] and has not yet fired, or null.
  static StreamRule? _firstUnfiredRule(
    List<StreamRule> rules,
    Set<StreamRule> fired,
    String text,
  ) {
    for (final rule in rules) {
      if (!fired.contains(rule) && rule.matches(text)) {
        return rule;
      }
    }
    return null;
  }

  /// Estimated tokens for the per-request overhead (system prompt + the tool
  /// schemas sent up front) so compaction budgets against real request size.
  ///
  /// Only the RESIDENT schemas are constant across a run; tools activated
  /// mid-run add to this, which is why the loop tracks their cost separately
  /// and adds it in rather than treating the whole overhead as fixed.
  static int _overheadTokens(String? systemPrompt, List<LlmToolSchema> tools) {
    const est = TokenEstimator.instance;
    var total = est.estimate(systemPrompt ?? '');
    for (final t in tools) {
      total += _schemaTokens(t);
    }
    return total;
  }

  /// Estimated tokens one tool definition occupies on the wire.
  static int _schemaTokens(LlmToolSchema t) => TokenEstimator.instance.estimate(
    '${t.name} ${t.description} ${jsonEncode(t.inputSchema)}',
  );
}

/// A tool call accumulated from the provider stream, awaiting execution.
class _PendingTool {
  _PendingTool(this.id, this.name, this.args, {this.argsError});

  /// Parses [argumentsJson] as a tool's argument map.
  ///
  /// A model can emit truncated or malformed JSON — mid-stream cutoff, a
  /// stray token, a top-level array where an object was expected. Decoding
  /// used to swallow that into `{}`, so the call still RAN and each argument
  /// surfaced as its own "missing argument" error inside the tool. The model
  /// then saw a plausible-looking tool failure and had no way to learn that
  /// its JSON was the problem, so it re-emitted the same broken call.
  /// [argsError] carries the real reason instead.
  factory _PendingTool.fromStream(
    String id,
    String name,
    String argumentsJson,
  ) {
    final raw = argumentsJson.trim();
    if (raw.isEmpty) {
      // Genuinely no arguments — the common shape for a zero-arg tool.
      return _PendingTool(id, name, <String, dynamic>{});
    }
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return _PendingTool(id, name, decoded);
      }
      return _PendingTool(
        id,
        name,
        <String, dynamic>{},
        argsError:
            'Tool arguments must be a JSON object, got '
            '${decoded.runtimeType}: ${_excerpt(raw)}',
      );
    } on FormatException catch (e) {
      return _PendingTool(
        id,
        name,
        <String, dynamic>{},
        argsError:
            'Tool arguments were not valid JSON (${e.message}): '
            '${_excerpt(raw)}',
      );
    }
  }

  /// Enough of the payload to see the break, bounded so a runaway argument
  /// blob cannot itself become the context problem.
  static String _excerpt(String raw) =>
      raw.length <= 200 ? raw : '${raw.substring(0, 200)}…';

  final String id;
  final String name;
  final Map<String, dynamic> args;

  /// Non-null when [args] could not be parsed; the call must not run.
  final String? argsError;
}
