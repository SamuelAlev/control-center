/// Exact-once usage accounting at the provider-call boundary.
///
/// **Why the boundary and not the loop.** The loop only sees the `LlmUsage`
/// events of the calls it itself made. A compaction, an advisor review, a
/// handoff document and a `/btw` side request each go out on their own
/// `LlmProviderPort` and — before this file — each discarded its usage. A
/// measured probe showed a run that the provider billed 918 input tokens for
/// being accounted as 17, because the summarizer's request was invisible to the
/// loop. Optimization that moves work into an uncounted call is therefore not
/// an optimization at all, it is unmeasured spend.
///
/// **Why a decorator.** [ObservedLlmProvider] wraps any [LlmProviderPort], so
/// every provider — native Anthropic, OpenAI-compatible, Cursor, a fallback
/// chain, a test double — is measured by the same code with no per-provider
/// instrumentation and no change to the port. Wrapping at construction (the
/// factory/composition root) is what makes coverage complete rather than
/// opt-in: an auxiliary call site cannot forget to report, because reporting is
/// not its job.
///
/// **Exact once.** Exactly one [ProviderCallRecord] is emitted per `complete()`
/// invocation, when the stream terminates for ANY reason — `LlmDone`,
/// `LlmError`, a thrown error, or the consumer cancelling mid-stream. Usage is
/// reconciled PER COMPONENT between the `LlmUsage` events (which providers emit
/// even on partial and failed streams) and the final cumulative
/// `LlmDone.usage`, taking the larger of the two: a component only the events
/// reported survives, and one only the final report carried is not dropped just
/// because an event had already arrived. A cancelled or failed call still
/// records the tokens that were actually billed before it stopped.
library;

import 'dart:async';
import 'dart:collection';

import 'package:cc_harness/src/messages.dart';
import 'package:cc_harness/src/provider/llm_provider_port.dart';

/// How a call ended.
enum ProviderCallOutcome {
  /// The stream finished normally (`LlmDone`).
  success,

  /// The provider reported an `LlmError`, or the stream threw.
  failure,

  /// The consumer cancelled the stream before it finished. Usage accrued up to
  /// that point is still recorded — those tokens were billed.
  cancelled;

  /// The wire spelling used by the accounting layer.
  String get wire => name;
}

/// Where a call's cost figure came from.
///
/// Kept distinct because a subscription-billed call and an estimated API call
/// are not comparable, and silently presenting one as the other makes a cost
/// comparison meaningless.
enum ProviderCallCostBasis {
  /// Priced from a catalog (models.dev or a provider price list).
  estimated,

  /// The provider itself reported the exact cost.
  providerReported,

  /// Covered by a subscription, not billed per token.
  subscription,

  /// A mix of the above within one run.
  mixed;

  /// The wire spelling used by the accounting layer.
  String get wire => switch (this) {
    ProviderCallCostBasis.estimated => 'estimated',
    ProviderCallCostBasis.providerReported => 'provider_reported',
    ProviderCallCostBasis.subscription => 'subscription',
    ProviderCallCostBasis.mixed => 'mixed',
  };
}

/// One completed provider call.
///
/// Immutable: a ledger accumulates finished records rather than mutating a
/// running total, so a record handed to observability can never be changed
/// underneath it by a later call.
class ProviderCallRecord {
  /// Creates a call record.
  const ProviderCallRecord({
    required this.requestId,
    required this.purpose,
    required this.providerId,
    required this.model,
    this.requestedModel = '',
    required this.attempt,
    required this.outcome,
    required this.usage,
    this.usageReported = true,
    this.callId,
    this.runId,
    this.stopReason,
    this.errorCode,
    this.errorMessage,
    this.retryable = false,
    this.startedAtMs = 0,
    this.finishedAtMs = 0,
    this.requestSentMs,
    this.transportFirstByteMs,
    this.firstModelEventMs,
    this.costMicros,
    this.costBasis = ProviderCallCostBasis.estimated,
  });

  /// Identifier unique within the recorder, and the key observability dedupes
  /// on together with `runId` + [attempt].
  final String requestId;

  /// The logical request this call was an attempt at, when the caller supplied
  /// one.
  final String? callId;

  /// Which attempt this was of [callId] (1-based; always 1 without a callId).
  final int attempt;

  /// What the call was for.
  final LlmCallPurpose purpose;

  /// The provider that served it (a fallback chain reports the target it
  /// actually consumed, not the one that was configured).
  final String providerId;

  /// The model that served it, preferring what the wire reported over what was
  /// requested.
  final String model;

  /// The model this call ASKED for (`config.model`, else the provider default),
  /// before any router or proxy substituted its own.
  ///
  /// Kept alongside [model] because the two answer different questions and must
  /// not be collapsed: prompt-token calibration is keyed by the model the run
  /// CONFIGURED (an alias like `claude-sonnet-4-5`), while usage/cost must be
  /// priced against the dated id that actually served. Folding them into one
  /// field is what leaves a run observing samples under a key nobody looks up,
  /// stuck at factor 1.0 however many samples it collects.
  ///
  /// Empty means "not recorded" (a caller built the record by hand); read it
  /// through [requestedModelOrServed].
  final String requestedModel;

  /// [requestedModel] when the caller recorded one, else [model].
  String get requestedModelOrServed =>
      requestedModel.isEmpty ? model : requestedModel;

  /// How the call ended.
  final ProviderCallOutcome outcome;

  /// Tokens the provider reported, exactly once.
  final LlmUsage usage;

  /// Whether the provider actually reported usage. Missing usage is unknown,
  /// not a known free request; failed streams often have no billing metadata.
  final bool usageReported;

  /// The run this call belongs to, when the recorder was given one.
  final String? runId;

  /// Why the model stopped, when the stream reported it.
  final LlmStopReason? stopReason;

  /// Machine-readable error classification, when the call failed.
  final String? errorCode;

  /// Human-readable error message, when the call failed.
  final String? errorMessage;

  /// Whether the failure was retryable (so the loop may try again — each retry
  /// is its own record, sharing [callId]).
  final bool retryable;

  /// Monotonic ms offset of the call's start, from the recorder's clock.
  ///
  /// Offsets from a monotonic clock, not wall-clock timestamps: these are
  /// durations, and a wall clock that steps (NTP, a laptop waking) would make a
  /// later call appear to start before an earlier one finished.
  final int startedAtMs;

  /// Monotonic ms offset of the call's end, from the recorder's clock.
  final int finishedAtMs;

  /// Ms from [startedAtMs] until the transport committed the HTTP request.
  /// Null when no transport boundary was observed.
  final int? requestSentMs;

  /// Ms from [startedAtMs] to the first response BODY byte, when the transport
  /// observed one. Null means unobserved — never inferred, and never back-filled
  /// from a nearby timestamp.
  ///
  /// A body-byte boundary, not a wire first-byte one: response headers arrive
  /// earlier and the first TCP/TLS byte is not observable from the client. Do
  /// not read the gap to [firstModelEventMs] as network latency.
  final int? transportFirstByteMs;

  /// Ms from [startedAtMs] to the first model-authored delta (text, thinking or
  /// tool use), when one arrived. Null when the stream produced none.
  final int? firstModelEventMs;

  /// Exact cost in micro-USD (10⁻⁶ USD), when a resolver priced the call.
  ///
  /// Micros rather than cents so a cheap auxiliary call is not rounded to zero
  /// — a compaction that costs $0.004 is real spend, and cents would erase it.
  final int? costMicros;

  /// Where [costMicros] came from.
  final ProviderCallCostBasis costBasis;

  /// Wall-clock duration of the call in ms.
  int get durationMs => finishedAtMs - startedAtMs;

  /// Whether the call produced a complete turn.
  bool get succeeded => outcome == ProviderCallOutcome.success;

  /// Tokens this call is accountable for in a budget: prompt (uncached and
  /// cache-write) plus output. Cache READS are excluded because the provider
  /// discounts them by an order of magnitude; counting them at full weight
  /// would overstate a well-cached run.
  int get billableTokens =>
      usage.inputTokens + usage.outputTokens + usage.cacheWriteTokens;

  /// Returns a copy attributed to the target that actually served the call.
  ProviderCallRecord withServedIdentity({
    required String providerId,
    required String model,
  }) => ProviderCallRecord(
    requestId: requestId,
    callId: callId,
    attempt: attempt,
    purpose: purpose,
    providerId: providerId.isEmpty ? this.providerId : providerId,
    model: model.isEmpty ? this.model : model,
    // The requested identity is NOT part of the serving identity: a failover
    // target changes who served, never what the run asked for.
    requestedModel: requestedModel,
    outcome: outcome,
    usage: usage,
    usageReported: usageReported,
    runId: runId,
    stopReason: stopReason,
    errorCode: errorCode,
    errorMessage: errorMessage,
    retryable: retryable,
    startedAtMs: startedAtMs,
    finishedAtMs: finishedAtMs,
    requestSentMs: requestSentMs,
    transportFirstByteMs: transportFirstByteMs,
    firstModelEventMs: firstModelEventMs,
    costMicros: costMicros,
    costBasis: costBasis,
  );

  /// Returns a copy carrying [cost] as the exact cost, when it was priced.
  ProviderCallRecord withCost(ProviderCallCost? cost) => cost == null
      ? this
      : ProviderCallRecord(
          requestId: requestId,
          callId: callId,
          attempt: attempt,
          purpose: purpose,
          providerId: providerId,
          model: model,
          requestedModel: requestedModel,
          outcome: outcome,
          usage: usage,
          usageReported: usageReported,
          runId: runId,
          stopReason: stopReason,
          errorCode: errorCode,
          errorMessage: errorMessage,
          retryable: retryable,
          startedAtMs: startedAtMs,
          finishedAtMs: finishedAtMs,
          requestSentMs: requestSentMs,
          transportFirstByteMs: transportFirstByteMs,
          firstModelEventMs: firstModelEventMs,
          costMicros: cost.micros,
          costBasis: cost.basis,
        );

  @override
  String toString() =>
      'ProviderCallRecord($requestId ${purpose.wire} ${outcome.wire} '
      '${providerId}/${requestedModelOrServed == model ? model : '$requestedModelOrServed→$model'} '
      'in=${usage.inputTokens} '
      'out=${usage.outputTokens} cacheR=${usage.cacheReadTokens} '
      'cacheW=${usage.cacheWriteTokens} ${durationMs}ms)';
}

/// An exact cost figure plus where it came from.
///
/// The basis travels WITH the number: a $0.42 estimate and a $0.42 bill are the
/// same digits and different facts, and a consumer that cannot tell them apart
/// will compare a subscription run against a metered one and conclude the wrong
/// thing.
class ProviderCallCost {
  /// Creates a cost figure.
  const ProviderCallCost(
    this.micros, {
    this.basis = ProviderCallCostBasis.estimated,
  });

  /// Exact cost in micro-USD (10⁻⁶ USD).
  final int micros;

  /// Where the figure came from.
  final ProviderCallCostBasis basis;
}

/// Prices a completed call, or returns null when the model is unpriced.
///
/// The whole record is passed rather than a bare token count so a resolver can
/// use the serving model, the purpose and the outcome (a failed attempt may be
/// discounted or free).
typedef ProviderCallCostResolver =
    ProviderCallCost? Function(ProviderCallRecord record);

/// Receives exactly one [ProviderCallRecord] per completed provider call.
abstract interface class ProviderCallObserver {
  /// Called once per completed, failed or cancelled call.
  void onProviderCall(ProviderCallRecord record);
}

/// Allocates the identity of each physical provider call.
///
/// **Must be shared.** A run wraps several providers (each fallback entry, the
/// summarizer, the advisor, subagents) and they all report into one ledger. If
/// each wrapper numbered its own calls, two wrappers would both emit `call-1` /
/// `turn-7#1` for DIFFERENT physical requests — and the second would be dropped
/// as a duplicate of the first, silently losing its tokens. One allocator per
/// run, handed to every wrapper (and to the ledger so duplicates can be
/// recognized), is what makes the ids unique and the dedupe meaningful.
class ProviderCallIdentityAllocator {
  /// Creates an allocator with fresh counters.
  ProviderCallIdentityAllocator();

  final Map<String, int> _attemptsByCallId = {};
  var _sequence = 0;

  /// The attempt index for [callId], advancing its counter.
  ///
  /// 1-based; always 1 without a callId (an uncorrelated call cannot be known to
  /// be a retry of anything).
  int nextAttempt(String? callId) => callId == null
      ? 1
      : (_attemptsByCallId[callId] = (_attemptsByCallId[callId] ?? 0) + 1);

  /// A request id unique within this allocator's scope.
  ///
  /// A correlated call keys off its logical id (`turn-7#2`), so observability
  /// can regroup attempts of one request; an uncorrelated one gets a
  /// run-scoped sequence number.
  String nextRequestId({required int attempt, String? callId, String? runId}) {
    if (callId != null) {
      return '$callId#$attempt';
    }
    final scope = (runId == null || runId.isEmpty) ? '' : '$runId:';
    return '${scope}call-${++_sequence}';
  }
}

/// Fans one record out to several observers.
///
/// An observer that throws cannot be allowed to break the run it is measuring
/// (accounting is a side channel), so each is isolated; one broken sink cannot
/// silently disable the others.
class ProviderCallObserverFanout implements ProviderCallObserver {
  /// Creates a fan-out over [observers].
  ProviderCallObserverFanout(Iterable<ProviderCallObserver> observers)
    : _observers = List.unmodifiable(observers);

  final List<ProviderCallObserver> _observers;

  @override
  void onProviderCall(ProviderCallRecord record) {
    for (final observer in _observers) {
      try {
        observer.onProviderCall(record);
      } on Object {
        // Accounting must never fail a run; a broken sink is dropped for this
        // record and the others still see it.
      }
    }
  }
}

/// Accumulates [ProviderCallRecord]s for one run and reports the totals a budget
/// needs.
///
/// Implements [ProviderCallObserver], so it is passed straight to
/// [ObservedLlmProvider].
class ProviderCallLedger implements ProviderCallObserver {
  /// Creates an empty ledger.
  ProviderCallLedger({this.runId});

  /// The run these records belong to, when known.
  final String? runId;

  /// The identity allocator to hand to every wrapper that reports here.
  ///
  /// Sharing it is what keeps request ids unique across a run's several
  /// wrappers; a wrapper left with its own allocator would collide with this
  /// one and its records would be dropped as duplicates.
  final ProviderCallIdentityAllocator identity =
      ProviderCallIdentityAllocator();

  final List<ProviderCallRecord> _records = [];
  late final List<ProviderCallRecord> _recordView = UnmodifiableListView(
    _records,
  );
  final Map<LlmCallPurpose, LlmUsage> _totals = {};
  final Set<String> _seen = {};
  var _billableTokens = 0;
  var _failedCalls = 0;
  var _duplicatesIgnored = 0;

  /// Live, read-only completed calls, in completion order.
  List<ProviderCallRecord> get records => _recordView;

  /// Every call's usage summed.
  LlmUsage get total {
    var sum = const LlmUsage();
    for (final usage in _totals.values) {
      sum = sum + usage;
    }
    return sum;
  }

  /// Usage summed per purpose.
  LlmUsage totalFor(LlmCallPurpose purpose) =>
      _totals[purpose] ?? const LlmUsage();

  /// Tokens accountable to a budget: every call's [ProviderCallRecord.billableTokens]
  /// summed, including auxiliary and failed attempts.
  int get billableTokens => _billableTokens;

  /// How many calls failed (including retried attempts).
  int get failedCalls => _failedCalls;

  /// How many records were dropped as duplicates of an already-recorded call.
  int get duplicatesIgnored => _duplicatesIgnored;

  /// Whether anything has been recorded.
  bool get isEmpty => _records.isEmpty;

  /// Adds [record]; returns false when an identical call was already recorded.
  ///
  /// Identity is `runId/requestId/attempt` — the run is part of the key because
  /// two runs on one ledger (a conversation's successive dispatches) legitimately
  /// number their first call the same way, and collapsing those would hide the
  /// second run's entire spend.
  bool add(ProviderCallRecord record) {
    final key = '${record.runId ?? ''}/${record.requestId}/${record.attempt}';
    if (!_seen.add(key)) {
      _duplicatesIgnored++;
      return false;
    }
    _records.add(record);
    _totals.update(
      record.purpose,
      (value) => value + record.usage,
      ifAbsent: () => record.usage,
    );
    _billableTokens += record.billableTokens;
    if (!record.succeeded) {
      _failedCalls++;
    }
    return true;
  }

  @override
  void onProviderCall(ProviderCallRecord record) => add(record);

  /// Forgets every record and total (a new run reusing the ledger).
  void clear() {
    _records.clear();
    _totals.clear();
    _seen.clear();
    _billableTokens = 0;
    _failedCalls = 0;
    _duplicatesIgnored = 0;
  }
}

/// Wraps an [LlmProviderPort] so every completion produces exactly one
/// [ProviderCallRecord].
///
/// Wrap once per run, at construction, and pass the provider this decorator
/// returns to every call site that spends tokens — the loop, the compactor's
/// summarizer, the advisor, side requests, subagents and the handoff writer.
/// Attribution then comes from each call's `LlmCompleteConfig.purpose`, which
/// is why no call site needs to know the ledger exists.
///
/// **One wrapper per physical provider, one allocator for all of them.** The
/// ledger is fed by several wrappers in a single run, so they must share an
/// [identity] allocator (`ledger.identity`); otherwise two wrappers would
/// produce the same request id for different requests and the ledger would drop
/// the second as a duplicate. Wrapping a FALLBACK CHAIN as a whole is not
/// equivalent: the chain can consume two targets for one logical call, and one
/// outer record would collapse the failed target's spend into the serving one.
/// Wrap each entry's provider instead.
class ObservedLlmProvider implements LlmProviderPort, LlmDeferredToolSupport {
  /// Creates a recording decorator over [delegate].
  ///
  /// [observer] receives the records; [identity] allocates request ids (share
  /// the ledger's allocator across every wrapper of one run); [runId] stamps
  /// them; [costResolver] prices them (left unset, costs are simply not recorded
  /// — never guessed); [clock] is the monotonic source for timings (a
  /// stopped-then-restarted external stopwatch is adopted as-is, so offsets stay
  /// comparable across several decorators sharing one run clock).
  ObservedLlmProvider(
    this.delegate, {
    required this.observer,
    ProviderCallIdentityAllocator? identity,
    this.runId,
    this.providerId,
    this.costResolver,
    Stopwatch? clock,
  }) : identity = identity ?? ProviderCallIdentityAllocator(),
       _clock = clock ?? (Stopwatch()..start());

  /// The wrapped provider.
  final LlmProviderPort delegate;

  /// Where completed calls are reported.
  final ProviderCallObserver observer;

  /// Allocates this wrapper's request ids.
  final ProviderCallIdentityAllocator identity;

  /// The run stamped on every record, when known.
  final String? runId;

  /// Stable catalog/provider id supplied by the host, rather than a display
  /// label. Unset for standalone callers that only have the provider port.
  final String? providerId;

  /// Prices a completed call, when pricing is available.
  final ProviderCallCostResolver? costResolver;

  final Stopwatch _clock;

  @override
  String get displayName => delegate.displayName;

  @override
  String get defaultModel => delegate.defaultModel;

  @override
  Future<List<ProviderModel>> listModels() => delegate.listModels();

  @override
  bool supportsDeferredTools({String? model}) =>
      providerSupportsDeferredTools(delegate, model: model);

  /// The run stamped on every record.
  ///
  /// Falls back to the ledger's own run id when the caller did not set one: the
  /// run id is part of the dedupe key, so a wrapper that left it null while its
  /// ledger named the run would let two runs' first calls collide and be
  /// counted once.
  String? get _runId =>
      runId ??
      switch (observer) {
        ProviderCallLedger(:final runId) => runId,
        _ => null,
      };

  /// Streams a completion while recording exactly one call.
  ///
  /// A controller rather than an `async*` generator so CANCELLATION has a
  /// defined ordering: `onCancel` banks the record synchronously, and only then
  /// awaits the delegate's own cleanup. With the generator's `finally`, the
  /// record could only be emitted after the upstream finished tearing down (a
  /// socket close, a worker drain), and the loop's terminal event and the
  /// host's flush — which follow the cancellation — could reach the UI before
  /// the call was ever accounted for. A cancelled call's partial usage is real
  /// spend; it must not be able to land after the run is reported finished.
  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) {
    if (config.trace != null) {
      // Already instrumented upstream. A second wrap around an already-wrapped
      // provider would emit a second record for the SAME physical call and
      // double every token in the totals, so the inner decorator forwards the
      // call (and the trace, so transport/model timings still reach the one
      // recorder) instead of recording it again.
      return delegate.complete(
        messages: messages,
        tools: tools,
        config: config,
      );
    }

    late _InFlightCall inFlight;
    StreamSubscription<LlmEvent>? subscription;
    // Set as soon as the call ends so no event is forwarded after it, whichever
    // way it ended.
    var ended = false;

    late StreamController<LlmEvent> controller;
    void fail(Object error, StackTrace stack) {
      if (ended) {
        return;
      }
      ended = true;
      inFlight.fail(error);
      _emit(inFlight);
      controller.addError(error, stack);
      unawaited(controller.close());
    }

    controller = StreamController<LlmEvent>(
      onListen: () {
        // Allocated on listen, not on call: a stream nobody subscribes never
        // happened, and must not consume an attempt number.
        final callId = config.callId;
        final attempt = identity.nextAttempt(callId);
        inFlight = _InFlightCall(
          requestId: identity.nextRequestId(
            attempt: attempt,
            callId: callId,
            runId: _runId,
          ),
          attempt: attempt,
          callId: callId,
          purpose: config.purpose,
          startedAtMs: _clock.elapsedMilliseconds,
          requestedModel: config.model ?? delegate.defaultModel,
          providerId: providerId ?? delegate.displayName,
        );
        final trace = _RecorderTrace(inFlight, _clock);
        // The delegate must receive the trace, or a provider that CAN report
        // the transport/model boundaries has no way to reach this recorder.
        final effective = config.copyWith(trace: trace);
        try {
          subscription = delegate
              .complete(messages: messages, tools: tools, config: effective)
              .listen(
                (event) {
                  if (ended) {
                    return;
                  }
                  inFlight.observe(event, _clock.elapsedMilliseconds);
                  controller.add(event);
                },
                onError: fail,
                onDone: () {
                  if (ended) {
                    return;
                  }
                  ended = true;
                  _emit(inFlight);
                  unawaited(controller.close());
                },
              );
        } on Object catch (error, stack) {
          fail(error, stack);
        }
      },
      onPause: () => subscription?.pause(),
      onResume: () => subscription?.resume(),
      onCancel: () async {
        if (!ended) {
          ended = true;
          // Bank usage before upstream cleanup or a downstream terminal event.
          _emit(inFlight);
        }
        // An error closes the output too, but does not necessarily close the
        // upstream source. Cleanup is required even after accounting finished.
        await subscription?.cancel();
        subscription = null;
      },
    );
    return controller.stream;
  }

  /// Emits one record, filling in the serving identity and the cost.
  void _emit(_InFlightCall call) {
    if (call.emitted) {
      return;
    }
    call.emitted = true;
    var record = call.finish(_clock.elapsedMilliseconds, runId: _runId);
    // A fallback/rotation chain serves from a different target than the one
    // that was configured; attribute the spend to the target that consumed it.
    if (delegate case final LlmServedIdentity served) {
      record = record.withServedIdentity(
        providerId: served.lastServedProviderId,
        model: served.lastServedModel,
      );
    }
    final resolve = costResolver;
    if (resolve != null) {
      // A resolver must not be able to break the run it is merely measuring.
      try {
        record = record.withCost(resolve(record));
      } on Object {
        // Unpriced: leave costMicros null rather than guess a number.
      }
    }
    observer.onProviderCall(record);
  }
}

/// Forwards transport / serving-model observations into an in-flight call.
class _RecorderTrace extends LlmCallTrace {
  _RecorderTrace(this._call, this._clock);

  final _InFlightCall _call;
  final Stopwatch _clock;

  @override
  void requestSent() =>
      _call.requestSentMs ??= _clock.elapsedMilliseconds - _call.startedAtMs;

  /// FIRST boundary only (`??=`).
  ///
  /// A transport that re-sends the request after a rejected credential produces
  /// a second response body, and its byte arrival must not overwrite the
  /// boundary already observed for this call: the metric is "when the first
  /// response byte of this call arrived", and a retry is later by construction.
  /// The call's `durationMs` still covers the whole call, including the retry.
  @override
  void transportFirstByte() => _call.transportFirstByteMs ??=
      _clock.elapsedMilliseconds - _call.startedAtMs;

  @override
  void servedModel(String model) {
    if (model.isNotEmpty) {
      _call.model = model;
    }
  }
}

/// Mutable accumulation for one call, frozen into a record when it ends.
class _InFlightCall {
  _InFlightCall({
    required this.requestId,
    required this.attempt,
    required this.callId,
    required this.purpose,
    required this.startedAtMs,
    required this.requestedModel,
    required this.providerId,
  }) : model = requestedModel;

  final String requestId;
  final int attempt;
  final String? callId;
  final LlmCallPurpose purpose;
  final int startedAtMs;
  final String requestedModel;
  final String providerId;

  /// The serving model — the wire-reported one once a provider tells us.
  String model;

  int? requestSentMs;
  int? transportFirstByteMs;
  int? firstModelEventMs;
  LlmStopReason? stopReason;
  LlmError? error;
  LlmUsage? doneUsage;
  LlmUsage reportedUsage = const LlmUsage();
  var usageReported = false;
  var emitted = false;

  void markFirstModelEvent(int nowMs) =>
      firstModelEventMs ??= nowMs - startedAtMs;

  void observe(LlmEvent event, int nowMs) {
    switch (event) {
      case LlmTextDelta():
      case LlmThinkingDelta():
      case LlmToolUseDelta():
        markFirstModelEvent(nowMs);
      case LlmUsage():
        usageReported = true;
        // Partial component reports and repeated cumulative snapshots overlap;
        // adding them would charge a request twice.
        reportedUsage = reportedUsage.reconcile(event);
      case LlmError():
        error = event;
      case LlmDone(:final stopReason, :final usage):
        this.stopReason = stopReason;
        doneUsage = usage;
        usageReported = usageReported || usage != null;
    }
  }

  void fail(Object error) {
    this.error = error is LlmError
        ? error
        : LlmError(
            '$error',
            // Providers map their own failures to LlmError; this is the path
            // for a transport or protocol exception escaping one, where the
            // only honest classification is that the stream failed.
            code: 'stream_error',
          );
  }

  /// The usage to bill, reconciling the streamed events with the final total.
  ///
  /// `LlmDone.usage` is cumulative for the request, and a provider may report
  /// only part of the breakdown on the events (Anthropic's `LlmDone` carries
  /// input+output while the cache counters arrive on the `LlmUsage` event, and
  /// a failed stream can report only the components it had reached). Taking the
  /// per-component MAX therefore loses nothing in either direction: a component
  /// that only the events reported is kept, and one that only the final total
  /// reported is added rather than dropped because "a usage event already
  /// arrived". Components are reconciled independently for exactly that reason.
  LlmUsage _reconciledUsage() => reportedUsage.reconcile(doneUsage);

  ProviderCallRecord finish(int finishedAtMs, {String? runId}) {
    final failed = error != null;
    // A stream that ended with neither a stop reason nor an error was torn
    // down (consumer cancel, or a provider that closed silently); calling that
    // a success would bank silence as an answer.
    final outcome = failed
        ? ProviderCallOutcome.failure
        : (stopReason == null
              ? ProviderCallOutcome.cancelled
              : ProviderCallOutcome.success);
    return ProviderCallRecord(
      requestId: requestId,
      callId: callId,
      attempt: attempt,
      purpose: purpose,
      providerId: providerId,
      model: model,
      requestedModel: requestedModel,
      outcome: outcome,
      usage: _reconciledUsage(),
      usageReported: usageReported,
      runId: runId,
      stopReason: stopReason,
      errorCode: error?.code,
      errorMessage: error?.message,
      retryable: error?.retryable ?? false,
      startedAtMs: startedAtMs,
      finishedAtMs: finishedAtMs,
      requestSentMs: requestSentMs,
      transportFirstByteMs: transportFirstByteMs,
      firstModelEventMs: firstModelEventMs,
    );
  }
}
