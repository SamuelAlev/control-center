part of 'agent_loop_runner.dart';

/// What one successful provider attempt produced.
class _TurnOutput {
  // StringBuffers, not `text += delta`: Dart strings do not rope, so
  // concatenating per delta copies the whole prefix every time — a 32 KB
  // answer arriving in ~4-char deltas costs ~130 MB of copying per turn on the
  // hosting isolate (cc_server), which must also answer RPCs.
  final StringBuffer _text = StringBuffer();
  final StringBuffer _thinking = StringBuffer();
  String? thinkingSignature;
  final List<_PendingTool> pending = <_PendingTool>[];
  final Set<String> _pendingIds = <String>{};

  /// Results of read-only tools the overlap lane already ran mid-stream.
  final Map<String, HarnessToolResult> earlyResults = {};
  LlmStopReason stopReason = LlmStopReason.unknown;

  /// Output tokens the provider billed for THIS turn. Compared against what
  /// the turn delivered to catch a provider that generates tokens and then
  /// hands us none of them.
  int outputTokens = 0;

  String get text => _text.toString();
  String get thinking => _thinking.toString();
  bool get hasStreamedContent => _text.isNotEmpty || _thinking.isNotEmpty;

  void reset() {
    _text.clear();
    _thinking.clear();
    thinkingSignature = null;
    pending.clear();
    _pendingIds.clear();
    earlyResults.clear();
    stopReason = LlmStopReason.unknown;
    outputTokens = 0;
  }

  HarnessMessage toAssistantMessage() {
    final blocks = <HarnessContentBlock>[];
    if (_thinking.isNotEmpty || thinkingSignature != null) {
      blocks.add(
        HarnessThinkingBlock(
          _thinking.toString(),
          signature: thinkingSignature,
        ),
      );
    }
    if (_text.isNotEmpty) {
      blocks.add(HarnessTextBlock(_text.toString()));
    }
    for (final t in pending) {
      blocks.add(HarnessToolUseBlock(id: t.id, name: t.name, input: t.args));
    }
    return HarnessMessage(
      role: HarnessRole.assistant,
      content: blocks.isEmpty ? const [HarnessTextBlock('')] : blocks,
    );
  }
}

/// Runs ONE turn's provider call: streams the attempt, retries retryable
/// failures with backoff, recovers from a context overflow by forced
/// compaction, and leaves the successful attempt in [output].
///
/// Ends the run (through [_RunState.finish]) on cancellation, a hard budget,
/// the per-turn wall clock, or an unrecoverable provider error.
class _TurnStreamer {
  _TurnStreamer(this.s) : callId = '${s.callIdPrefix}:turn-${s.turn}';

  final _RunState s;
  final String callId;
  final _TurnOutput output = _TurnOutput();

  /// Forced-compaction recoveries spent on THIS turn.
  int _overflowRecoveries = 0;
  int _attempt = 0;

  AgentLoopConfig get config => s.config;

  Stream<AgentLoopEvent> stream() async* {
    final hasStreamRules = config.steering.streamRules.isNotEmpty;
    final hooks = s.hooks;
    while (true) {
      // Compaction and failed attempts are real spend. Do not begin another
      // main call after an auxiliary request or retry exhausted the budget.
      if (s.guards.hardBudgetExhausted()) {
        yield* s.finish(LoopDoneReason.budgetExhausted);
        return;
      }
      output.reset();
      var requestUsage = const LlmUsage();
      LlmUsage? finalUsage;
      LlmError? lastError;
      var retry = false;
      var ruleRestart = false;
      // Bounded tail of the streamed text that stream rules are matched
      // against (see [_streamRuleWindowChars]).
      var ruleWindow = '';

      // Wall-clock ceiling for THIS turn. The transport's timeout is an IDLE
      // timeout and resets on every chunk, so a stream dripping one byte every
      // 100 seconds trips nothing. Checked per event because that is the shape
      // being bounded.
      final turnClock = Stopwatch()..start();
      final turnLimit = config.guards.turnTimeout;

      // Provider-side image ceiling, applied per REQUEST: the oldest frames
      // are dropped ON THE WIRE only — `history` keeps every image.
      final wireMessages = clampProviderContextImages(
        s.history,
        providerImageLimitFor(s.provider.displayName),
      );
      // The tools breakpoint sits at the end of the RESIDENT block so
      // activation appends behind it; the message anchor points at where the
      // last SUCCESSFUL request wrote. It is advanced only once this attempt
      // succeeds: a failed attempt wrote nothing anyone can read, so a retry
      // that anchored on the failed attempt's tail lost the read breakpoint
      // exactly when the provider was flaky.
      final requestConfig = s.completeConfig.copyWith(
        toolCacheBreakpointIndex: s.catalog.residentSchemas.length - 1,
        cacheAnchorIndex: s.cacheAnchorIndex,
        callId: callId,
      );
      final writtenAnchor = wireMessages.length - 1;
      final recordStart = config.guards.callLedger?.records.length ?? 0;
      final estimatedPromptTokens = config.compaction.tokenCalibration == null
          ? 0
          : estimateHarnessHistory(wireMessages) + s.overheadTokensNow();
      final modelEvents = s.provider.complete(
        messages: wireMessages,
        tools: s.catalog.schemas,
        config: requestConfig,
      );
      final Stream<Object> turnEvents =
          config.tools.overlapReadOnlyTools &&
              (hooks == null || !hooks.interceptsTools)
          ? _overlapReadOnlyTools(
              modelEvents,
              s.catalog.byName,
              s.ctx,
              limit: max(1, config.tools.maxParallelToolCalls),
              timeout: config.tools.toolTimeout,
            )
          : modelEvents.untilCancelled(s.cancel);
      await for (final event in turnEvents) {
        if (s.cancel.isCancelled) {
          yield* s.finish(LoopDoneReason.cancelled);
          return;
        }
        if (turnLimit != null && turnClock.elapsed > turnLimit) {
          // A failure, not a clean stop: the host derives its exit status from
          // the error, and a turn timeout used to exit 0.
          yield* s.finish(
            LoopDoneReason.error,
            error:
                'Turn exceeded its ${turnLimit.inMinutes}-minute wall-clock '
                'limit and was abandoned. The provider stream was still open.',
            errorCode: 'turn_timeout',
          );
          return;
        }
        if (event is LoopToolCallStart) {
          yield event;
          continue;
        }
        if (event is LoopToolCallResult) {
          output.earlyResults[event.toolUseId] = event.result;
          yield event;
          continue;
        }
        final modelEvent = event as LlmEvent;
        switch (modelEvent) {
          case LlmTextDelta(:final text):
            output._text.write(text);
            yield LoopTextDelta(text);
            if (hasStreamRules) {
              final probe = ruleWindow + text;
              ruleWindow = probe.length > _streamRuleWindowChars
                  ? probe.substring(probe.length - _streamRuleWindowChars)
                  : probe;
              final rule = s.guards.firstUnfiredRule(probe);
              if (rule != null) {
                s.guards.firedRules.add(rule);
                s.history.add(HarnessMessage.system(rule.reminder));
                yield LoopNotice('Course-correction: ${rule.reminder}');
                ruleRestart = true;
              }
            }
          case LlmThinkingDelta(:final thinking, :final signature):
            if (signature != null) {
              output.thinkingSignature = signature;
            }
            if (thinking.isNotEmpty) {
              output._thinking.write(thinking);
              yield LoopThinkingDelta(thinking);
            }
          case LlmToolUseDelta(:final id, :final name, :final argumentsJson):
            if (output._pendingIds.add(id)) {
              output.pending.add(
                _PendingTool.fromStream(id, name, argumentsJson),
              );
            } else {
              lastError = LlmError(
                // A protocol error is not safe to replay as a transient one.
                'The provider emitted duplicate tool-call id "$id".',
                code: 'duplicate_tool_call_id',
                kind: LlmErrorKind.protocol,
              );
              retry = false;
            }
          case LlmUsage():
            final previous = requestUsage;
            requestUsage = previous.reconcile(modelEvent);
            if (!identical(previous, requestUsage)) {
              final delta = _usageTotal(previous) == 0
                  ? requestUsage
                  : _usageDelta(requestUsage, previous);
              _countStreamed(delta);
              yield LoopUsage(delta);
            }
          case LlmError():
            // Protocol-invalid duplicate IDs must never become retryable
            // merely because another event reported a transient failure.
            if (lastError?.code != 'duplicate_tool_call_id') {
              lastError = modelEvent;
              retry =
                  modelEvent.retryable && _attempt < config.guards.maxProviderRetries;
            }
          case LlmDone(stopReason: final reason, :final usage):
            output.stopReason = reason;
            finalUsage = usage;
        }
        // A stream rule fired: abandon this turn's stream and restart with the
        // reminder now in history.
        if (ruleRestart) {
          break;
        }
      }

      if (s.cancel.isCancelled) {
        yield* s.finish(LoopDoneReason.cancelled);
        return;
      }

      final reconciled = requestUsage.reconcile(finalUsage);
      output.outputTokens = reconciled.outputTokens;
      if (!identical(reconciled, requestUsage)) {
        final missing = _usageDelta(reconciled, requestUsage);
        _countStreamed(missing);
        yield LoopUsage(missing);
      }
      if (!ruleRestart) {
        _calibrate(recordStart, estimatedPromptTokens, reconciled, lastError);
      }

      if (ruleRestart) {
        yield* _discardAttempt('stream_rule');
        continue;
      }
      // Empty-stream guard: no text/thinking/tools/error/stop reason means a
      // transport or buffering parser failure, not a finished turn. Synthesize
      // a retryable error so backoff handles it (else the loop banks silence
      // as the model's answer).
      if (lastError == null &&
          output.pending.isEmpty &&
          !output.hasStreamedContent &&
          output.stopReason == LlmStopReason.unknown) {
        lastError = const LlmError(
          'Provider returned an empty response: no content, no tool call, '
          'and no stop reason. That is a transport or server-side parser '
          'failure, not a finished turn.',
          code: 'empty_response',
          retryable: true,
          kind: LlmErrorKind.protocol,
        );
        if (_attempt < config.guards.maxProviderRetries) {
          retry = true;
        }
      }
      if (retry) {
        _attempt++;
        yield* _discardAttempt(lastError?.code ?? 'retry');
        // Honor a server Retry-After hint when present; otherwise exponential
        // backoff. Cap at 30s and apply full jitter (sleep in [50%, 100%] of
        // the target) to avoid synchronized retry storms.
        final retryAfterMs = lastError?.retryAfterMs;
        final baseMs = retryAfterMs ?? (500 * (1 << (_attempt - 1)));
        final cappedMs = baseMs > 30000 ? 30000 : baseMs;
        final delayMs = (cappedMs * (0.5 + s.rng.nextDouble() * 0.5)).round();
        yield LoopNotice(
          'Provider error (${lastError?.code ?? 'unknown'}); '
          'retrying in ${delayMs}ms (attempt $_attempt).',
        );
        // Cancellable sleep: a 30s backoff that ignores the token kept a
        // cancelled run alive for up to 30s per attempt.
        await Future.any<void>([
          Future<void>.delayed(Duration(milliseconds: delayMs)),
          s.cancel.whenCancelled,
        ]);
        if (s.cancel.isCancelled) {
          yield* s.finish(LoopDoneReason.cancelled);
          return;
        }
        continue;
      }
      if (lastError != null) {
        // Reactive context-overflow recovery: the provider rejected the request
        // as too large. Force a compaction pass and re-issue the same turn
        // instead of failing the run. The typed kind decides — a rate limit
        // that talks about "tokens per minute exceeded" is NOT an overflow.
        if (lastError.kind == LlmErrorKind.contextOverflow &&
            _overflowRecoveries < _maxOverflowRecoveriesPerTurn) {
          _overflowRecoveries++;
          final recovery = await s.recoverFromOverflow();
          if (recovery.failure case final failure?) {
            yield LoopNotice(failure);
          }
          if (s.cancel.isCancelled) {
            yield* s.finish(LoopDoneReason.cancelled);
            return;
          }
          if (recovery.event case final event?) {
            yield* _discardAttempt('context_overflow');
            yield event;
            yield const LoopNotice(
              'Context window exceeded; compacted history and retrying.',
            );
            continue;
          }
        }
        yield* s.finish(
          LoopDoneReason.error,
          error: lastError.message,
          errorCode: lastError.code,
        );
        return;
      }
      // Success: this request's tail is now the anchor the next one reads.
      // (A rewrite during the attempt already reset it to -1 and must win.)
      if (s.cacheAnchorIndex == requestConfig.cacheAnchorIndex) {
        s.cacheAnchorIndex = writtenAnchor;
      }
      return;
    }
  }

  /// Announces that the attempt's already-streamed deltas are void, so a host
  /// that recorded them can drop them. Silent when nothing was streamed.
  Stream<AgentLoopEvent> _discardAttempt(String reason) async* {
    if (!output.hasStreamedContent) {
      return;
    }
    yield LoopTurnDiscarded(
      text: output.text,
      thinking: output.thinking,
      reason: reason,
    );
  }

  void _countStreamed(LlmUsage delta) {
    if (config.guards.callLedger == null) {
      s.streamedBillableTokens +=
          delta.inputTokens + delta.outputTokens + delta.cacheWriteTokens;
    }
  }

  void _calibrate(
    int recordStart,
    int estimatedPromptTokens,
    LlmUsage reconciled,
    LlmError? lastError,
  ) {
    final calibration = config.compaction.tokenCalibration;
    if (calibration == null) {
      return;
    }
    final records = config.guards.callLedger?.records;
    if (records != null) {
      for (var i = recordStart; i < records.length; i++) {
        final record = records[i];
        if (record.callId == callId && record.succeeded) {
          final usage = record.usage;
          calibration.observe(
            providerId: record.providerId,
            // The REQUESTED identity, not the serving one: the compactor looks
            // the factor up by the model it was configured with, so keying
            // observations by a served id leaves every sample under a key
            // nobody queries.
            modelId: record.requestedModelOrServed,
            purpose: config.purpose,
            estimatedTokens: estimatedPromptTokens,
            observedPromptTokens:
                usage.inputTokens +
                usage.cacheReadTokens +
                usage.cacheWriteTokens,
          );
        }
      }
    } else if (lastError == null) {
      calibration.observe(
        providerId: s.provider.displayName,
        modelId: config.model ?? s.provider.defaultModel,
        purpose: config.purpose,
        estimatedTokens: estimatedPromptTokens,
        observedPromptTokens:
            reconciled.inputTokens +
            reconciled.cacheReadTokens +
            reconciled.cacheWriteTokens,
      );
    }
  }

  static int _usageTotal(LlmUsage u) =>
      u.inputTokens +
      u.outputTokens +
      u.cacheReadTokens +
      u.cacheWriteTokens +
      u.thoughtTokens;

  static LlmUsage _usageDelta(LlmUsage now, LlmUsage before) => LlmUsage(
    inputTokens: now.inputTokens - before.inputTokens,
    outputTokens: now.outputTokens - before.outputTokens,
    cacheReadTokens: now.cacheReadTokens - before.cacheReadTokens,
    cacheWriteTokens: now.cacheWriteTokens - before.cacheWriteTokens,
    thoughtTokens: now.thoughtTokens - before.thoughtTokens,
  );
}
