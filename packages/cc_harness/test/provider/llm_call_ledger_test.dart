import 'dart:async';

import 'package:cc_harness/messages.dart';
import 'package:cc_harness/provider.dart';
import 'package:test/test.dart';

/// A provider that replays a scripted event list and can report the transport /
/// serving-model boundaries through the trace, the way a real provider does.
class _ScriptedProvider implements LlmProviderPort {
  _ScriptedProvider(
    this.events, {
    this.displayName = 'Scripted',
    this.reportsTrace = false,
    this.throwAfterEvents = false,
    this.boundaryDelayMs = 0,
  }) : defaultModel = 'scripted-1';

  final List<LlmEvent> events;
  final bool reportsTrace;

  /// When true the stream errors after replaying, standing in for a transport
  /// failure inside a provider that does not map it to [LlmError].
  final bool throwAfterEvents;

  /// When > 0 the provider reports a SECOND transport boundary this long after
  /// the first, standing in for a re-authorizing retry's response body.
  final int boundaryDelayMs;

  /// The provider's own offset for the SECOND boundary report (ms), so a test
  /// can prove the recorder kept the first.
  int? secondBoundaryOffsetMs;

  @override
  final String displayName;

  @override
  final String defaultModel;

  @override
  Stream<LlmEvent> complete({
    required List<HarnessMessage> messages,
    List<LlmToolSchema> tools = const [],
    LlmCompleteConfig config = const LlmCompleteConfig(),
  }) async* {
    if (reportsTrace) {
      final stopwatch = Stopwatch()..start();
      config.trace?.transportFirstByte();
      if (boundaryDelayMs > 0) {
        await Future<void>.delayed(Duration(milliseconds: boundaryDelayMs));
        config.trace?.transportFirstByte();
        secondBoundaryOffsetMs = stopwatch.elapsedMilliseconds;
      }
      config.trace?.servedModel('served-by-wire');
    }
    for (final event in events) {
      yield event;
    }
    if (throwAfterEvents) {
      throw StateError('socket closed');
    }
  }

  @override
  Future<List<ProviderModel>> listModels() async => const [];
}

class _Collector implements ProviderCallObserver {
  final List<ProviderCallRecord> records = [];

  @override
  void onProviderCall(ProviderCallRecord record) => records.add(record);
}

ObservedLlmProvider _observed(
  LlmProviderPort delegate,
  _Collector collector, {
  String? runId,
  ProviderCallCostResolver? costResolver,
}) => ObservedLlmProvider(
  delegate,
  observer: collector,
  runId: runId,
  costResolver: costResolver,
);

void main() {
  test('records exactly one call per completion', () async {
    final collector = _Collector();
    final provider = _observed(
      _ScriptedProvider([
        const LlmTextDelta('hi'),
        const LlmUsage(inputTokens: 5, outputTokens: 2),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ]),
      collector,
      runId: 'run-1',
    );

    await provider.complete(messages: [HarnessMessage.user('q')]).toList();

    expect(collector.records, hasLength(1));
    final record = collector.records.single;
    expect(record.runId, 'run-1');
    expect(record.providerId, 'Scripted');
    expect(record.model, 'scripted-1');
    expect(record.purpose, LlmCallPurpose.main);
    expect(record.outcome, ProviderCallOutcome.success);
    expect(record.stopReason, LlmStopReason.endTurn);
    expect(record.usage.inputTokens, 5);
    expect(record.usage.outputTokens, 2);
    expect(record.succeeded, isTrue);
  });

  test('does not double count a cumulative usage reported twice', () async {
    // Anthropic emits a cumulative LlmUsage event AND repeats the totals on
    // LlmDone; the call must be billed once.
    final collector = _Collector();
    final provider = _observed(
      _ScriptedProvider([
        const LlmUsage(
          inputTokens: 900,
          outputTokens: 40,
          cacheReadTokens: 100,
          cacheWriteTokens: 20,
        ),
        const LlmUsage(
          inputTokens: 900,
          outputTokens: 40,
          cacheReadTokens: 100,
          cacheWriteTokens: 20,
        ),
        const LlmDone(
          stopReason: LlmStopReason.endTurn,
          usage: LlmUsage(inputTokens: 900, outputTokens: 40),
        ),
      ]),
      collector,
    );

    await provider.complete(messages: const []).toList();

    final usage = collector.records.single.usage;
    expect(usage.inputTokens, 900);
    expect(usage.outputTokens, 40);
    expect(usage.cacheReadTokens, 100);
    expect(usage.cacheWriteTokens, 20);
    // The ledger's total is the record's, not a re-summed stream.
    expect(
      collector.records.single.billableTokens,
      900 + 40 + 20,
      reason: 'cache READS are discounted and excluded from the billable sum',
    );
  });

  test('reconciles a component only the final cumulative reported', () async {
    // A provider whose event carries input/output while the cache counters
    // arrive only on the final report must not lose them (nor the reverse).
    final collector = _Collector();
    final provider = _observed(
      _ScriptedProvider([
        const LlmUsage(inputTokens: 10, outputTokens: 3),
        const LlmDone(
          stopReason: LlmStopReason.endTurn,
          usage: LlmUsage(
            inputTokens: 10,
            outputTokens: 3,
            cacheReadTokens: 700,
            cacheWriteTokens: 12,
          ),
        ),
      ]),
      collector,
    );

    await provider.complete(messages: const []).toList();

    final usage = collector.records.single.usage;
    expect(usage.inputTokens, 10);
    expect(usage.outputTokens, 3);
    expect(usage.cacheReadTokens, 700);
    expect(usage.cacheWriteTokens, 12);
  });

  test('records partial usage from a failed attempt', () async {
    final collector = _Collector();
    final provider = _observed(
      _ScriptedProvider([
        const LlmUsage(inputTokens: 400, outputTokens: 7),
        const LlmError('overloaded', code: 'overloaded_error', retryable: true),
        const LlmDone(stopReason: LlmStopReason.unknown),
      ]),
      collector,
    );

    await provider.complete(messages: const []).toList();

    final record = collector.records.single;
    expect(record.outcome, ProviderCallOutcome.failure);
    expect(record.errorCode, 'overloaded_error');
    expect(record.retryable, isTrue);
    expect(
      record.usage.inputTokens,
      400,
      reason: 'tokens the provider billed before failing are still spend',
    );
  });

  test('records one record when the consumer cancels mid-stream', () async {
    final collector = _Collector();
    final provider = _observed(
      _ScriptedProvider([
        const LlmTextDelta('a'),
        const LlmUsage(inputTokens: 30, outputTokens: 1),
        const LlmTextDelta('b'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ]),
      collector,
    );

    // Cancel once the usage has arrived: the record must still be emitted, with
    // the tokens billed before the stream was torn down.
    final cancelled = Completer<void>();
    late final StreamSubscription<LlmEvent> subscription;
    subscription = provider.complete(messages: const []).listen((event) {
      if (event is LlmUsage) {
        unawaited(subscription.cancel().then((_) => cancelled.complete()));
      }
    });
    await cancelled.future;

    expect(collector.records, hasLength(1));
    final record = collector.records.single;
    expect(record.outcome, ProviderCallOutcome.cancelled);
    expect(record.usage.inputTokens, 30);
  });

  test('records a thrown stream failure without losing the call', () async {
    final collector = _Collector();
    final provider = _observed(
      _ScriptedProvider([
        const LlmUsage(inputTokens: 11, outputTokens: 2),
      ], throwAfterEvents: true),
      collector,
    );

    await expectLater(
      provider.complete(messages: const []).toList(),
      throwsA(isA<StateError>()),
      reason: 'the decoration must not swallow a provider failure',
    );

    final record = collector.records.single;
    expect(record.outcome, ProviderCallOutcome.failure);
    expect(record.usage.inputTokens, 11);
    expect(record.errorMessage, contains('socket closed'));
  });

  test('numbers attempts that share a callId', () async {
    final collector = _Collector();
    final provider = _observed(
      _ScriptedProvider([const LlmDone(stopReason: LlmStopReason.endTurn)]),
      collector,
    );

    for (var i = 0; i < 3; i++) {
      await provider
          .complete(
            messages: const [],
            config: const LlmCompleteConfig(callId: 'turn-7'),
          )
          .toList();
    }
    await provider.complete(messages: const []).toList();

    expect(collector.records.map((r) => r.attempt), [
      1,
      2,
      3,
      1,
    ], reason: 'a retry is a separate billed attempt of the same request');
    expect(collector.records.first.requestId, 'turn-7#1');
    // An uncorrelated call is numbered within the allocator's own sequence, so
    // it can never collide with a correlated id.
    expect(collector.records.last.requestId, 'call-1');
  });

  test('two wrappers sharing one ledger and allocator never collide', () async {
    // This is the shape of a failover: one logical call consumes two physical
    // targets. Each target has its own wrapper, and a per-wrapper counter would
    // emit `turn-1#1` twice — the ledger would drop the second record and lose
    // that target's spend entirely.
    final ledger = ProviderCallLedger(runId: 'run-1');
    final primary = _ScriptedProvider([
      const LlmError('bad key', code: 'authentication_error'),
      const LlmDone(stopReason: LlmStopReason.unknown),
    ], displayName: 'primary');
    final secondary = _ScriptedProvider([
      const LlmTextDelta('ok'),
      const LlmUsage(inputTokens: 40, outputTokens: 5),
      const LlmDone(stopReason: LlmStopReason.endTurn),
    ], displayName: 'secondary');
    final a = ObservedLlmProvider(
      primary,
      observer: ledger,
      identity: ledger.identity,
      runId: 'run-1',
    );
    final b = ObservedLlmProvider(
      secondary,
      observer: ledger,
      identity: ledger.identity,
      runId: 'run-1',
    );

    const logical = LlmCompleteConfig(
      callId: 'turn-1',
      model: 'primary-model',
      purpose: LlmCallPurpose.subagent,
    );
    await a.complete(messages: const [], config: logical).toList();
    await b
        .complete(
          messages: const [],
          config: logical.copyWith(model: 'secondary-model'),
        )
        .toList();

    expect(
      ledger.records,
      hasLength(2),
      reason: 'the failover target\'s call is not a duplicate of the first',
    );
    expect(ledger.duplicatesIgnored, 0);
    expect(ledger.records.map((r) => r.requestId), ['turn-1#1', 'turn-1#2']);
    expect(ledger.records.map((r) => r.providerId), ['primary', 'secondary']);
    expect(ledger.records.map((r) => r.model), [
      'primary-model',
      'secondary-model',
    ]);
    expect(ledger.records.first.outcome, ProviderCallOutcome.failure);
    expect(ledger.records.last.outcome, ProviderCallOutcome.success);
    expect(ledger.records.first.errorCode, 'authentication_error');
    expect(
      ledger.total.inputTokens,
      40,
      reason: 'the failed target billed nothing, the serving one billed 40',
    );
    expect(ledger.billableTokens, 45);
  });

  test('a distinct run on the same ledger is a distinct call', () {
    final ledger = ProviderCallLedger();
    const first = ProviderCallRecord(
      requestId: 'turn-1#1',
      attempt: 1,
      runId: 'run-a',
      purpose: LlmCallPurpose.main,
      providerId: 'Anthropic',
      model: 'm',
      outcome: ProviderCallOutcome.success,
      usage: LlmUsage(inputTokens: 10),
    );
    const second = ProviderCallRecord(
      requestId: 'turn-1#1',
      attempt: 1,
      runId: 'run-b',
      purpose: LlmCallPurpose.main,
      providerId: 'Anthropic',
      model: 'm',
      outcome: ProviderCallOutcome.success,
      usage: LlmUsage(inputTokens: 20),
    );

    expect(
      ledger.add(first),
      isTrue,
      reason: 'two runs legitimately number their first call the same way',
    );
    expect(ledger.add(second), isTrue);
    expect(ledger.total.inputTokens, 30);
    expect(ledger.add(first), isFalse, reason: 'the same run and call again');
    expect(ledger.duplicatesIgnored, 1);
    expect(ledger.total.inputTokens, 30);
  });

  test('carries the purpose from the call site', () async {
    final collector = _Collector();
    final provider = _observed(
      _ScriptedProvider([const LlmDone(stopReason: LlmStopReason.endTurn)]),
      collector,
    );

    await provider
        .complete(
          messages: const [],
          config: const LlmCompleteConfig(purpose: LlmCallPurpose.compaction),
        )
        .toList();

    expect(collector.records.single.purpose, LlmCallPurpose.compaction);
    expect(LlmCallPurpose.sideRequest.wire, 'side_request');
    expect(LlmCallPurpose.fromWire('advisor'), LlmCallPurpose.advisor);
    expect(LlmCallPurpose.fromWire('nonsense'), LlmCallPurpose.main);
  });

  test('reports transport and model timings only when observed', () async {
    final traced = _Collector();
    await _observed(
      _ScriptedProvider([
        const LlmTextDelta('x'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ], reportsTrace: true),
      traced,
    ).complete(messages: const []).toList();

    final withTrace = traced.records.single;
    expect(withTrace.transportFirstByteMs, isNotNull);
    expect(withTrace.firstModelEventMs, isNotNull);
    expect(withTrace.model, 'served-by-wire');
    expect(withTrace.durationMs, greaterThanOrEqualTo(0));

    final untraced = _Collector();
    await _observed(
      _ScriptedProvider([
        const LlmTextDelta('x'),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ]),
      untraced,
    ).complete(messages: const []).toList();

    expect(
      untraced.records.single.transportFirstByteMs,
      isNull,
      reason: 'an unobserved boundary must never be invented',
    );

    final silent = _Collector();
    await _observed(
      _ScriptedProvider([const LlmDone(stopReason: LlmStopReason.endTurn)]),
      silent,
    ).complete(messages: const []).toList();

    expect(
      silent.records.single.firstModelEventMs,
      isNull,
      reason: 'a stream with no model delta has no first model event',
    );
  });

  test('prices the call through the injected resolver', () async {
    final collector = _Collector();
    final provider = _observed(
      _ScriptedProvider([
        const LlmUsage(inputTokens: 100, outputTokens: 50),
        const LlmDone(stopReason: LlmStopReason.endTurn),
      ]),
      collector,
      costResolver: (record) => ProviderCallCost(
        record.billableTokens * 3,
        basis: ProviderCallCostBasis.estimated,
      ),
    );

    await provider.complete(messages: const []).toList();

    expect(collector.records.single.costMicros, 450);
    expect(collector.records.single.costBasis, ProviderCallCostBasis.estimated);
  });

  test(
    'a throwing resolver leaves the call unpriced instead of failing it',
    () async {
      final collector = _Collector();
      final provider = _observed(
        _ScriptedProvider([const LlmDone(stopReason: LlmStopReason.endTurn)]),
        collector,
        costResolver: (_) => throw StateError('catalog unreachable'),
      );

      await provider.complete(messages: const []).toList();

      expect(collector.records.single.costMicros, isNull);
    },
  );

  test('the allocator numbers calls deterministically', () {
    final allocator = ProviderCallIdentityAllocator();
    expect(allocator.nextAttempt('turn-1'), 1);
    expect(allocator.nextAttempt('turn-1'), 2);
    expect(allocator.nextAttempt(null), 1);
    expect(
      allocator.nextRequestId(attempt: 2, callId: 'turn-1'),
      'turn-1#2',
      reason: 'attempts of one logical request regroup by that id',
    );
    expect(
      allocator.nextRequestId(attempt: 1, runId: 'run-9'),
      'run-9:call-1',
      reason: 'an uncorrelated id is run-scoped, never bare `call-1`',
    );
    expect(allocator.nextRequestId(attempt: 1), 'call-2');
  });

  test('the ledger totals every purpose and ignores duplicates', () {
    final ledger = ProviderCallLedger(runId: 'run-2');
    const main = ProviderCallRecord(
      requestId: 'call-1',
      purpose: LlmCallPurpose.main,
      providerId: 'Anthropic',
      model: 'claude-opus-4-8',
      attempt: 1,
      outcome: ProviderCallOutcome.success,
      usage: LlmUsage(inputTokens: 1000, outputTokens: 100),
    );
    const compaction = ProviderCallRecord(
      requestId: 'call-2',
      purpose: LlmCallPurpose.compaction,
      providerId: 'Anthropic',
      model: 'claude-opus-4-8',
      attempt: 1,
      outcome: ProviderCallOutcome.success,
      usage: LlmUsage(inputTokens: 800, outputTokens: 200),
    );
    const failed = ProviderCallRecord(
      requestId: 'call-3',
      purpose: LlmCallPurpose.advisor,
      providerId: 'Anthropic',
      model: 'claude-haiku-4-5',
      attempt: 1,
      outcome: ProviderCallOutcome.failure,
      usage: LlmUsage(inputTokens: 50),
      errorCode: 'overloaded_error',
      retryable: true,
    );

    expect(ledger.add(main), isTrue);
    expect(ledger.add(compaction), isTrue);
    expect(ledger.add(failed), isTrue);
    expect(ledger.add(main), isFalse, reason: 'the same call twice');

    expect(ledger.records, hasLength(3));
    expect(ledger.duplicatesIgnored, 1);
    expect(ledger.failedCalls, 1);
    expect(ledger.total.inputTokens, 1850);
    expect(ledger.total.outputTokens, 300);
    expect(ledger.totalFor(LlmCallPurpose.compaction).inputTokens, 800);
    expect(ledger.totalFor(LlmCallPurpose.subagent).inputTokens, 0);
    expect(
      ledger.billableTokens,
      1850 + 300,
      reason: 'every purpose, including the failed advisor call',
    );

    ledger.clear();
    expect(ledger.isEmpty, isTrue);
    expect(ledger.billableTokens, 0);
  });

  test('a fanout isolates a broken observer', () {
    final good = _Collector();
    final fanout = ProviderCallObserverFanout([_ThrowingObserver(), good]);
    fanout.onProviderCall(
      const ProviderCallRecord(
        requestId: 'call-1',
        purpose: LlmCallPurpose.main,
        providerId: 'p',
        model: 'm',
        attempt: 1,
        outcome: ProviderCallOutcome.success,
        usage: LlmUsage(inputTokens: 1),
      ),
    );
    expect(good.records, hasLength(1));
  });

  test('delegates deferred-tool capability honestly', () {
    final plain = _observed(_ScriptedProvider(const []), _Collector());
    expect(plain.supportsDeferredTools(), isFalse);
    expect(providerSupportsDeferredTools(plain, model: 'x'), isFalse);

    final supporting = _observed(_TraceCapableProvider(), _Collector());
    expect(supporting.supportsDeferredTools(model: 'supported'), isTrue);
    expect(
      providerSupportsDeferredTools(supporting, model: 'other'),
      isFalse,
      reason: 'the capability must come from the delegate, not the wrapper',
    );
  });

  test('a double wrap does not double count the call', () async {
    final inner = _Collector();
    final outer = _Collector();
    final raw = _ScriptedProvider([
      const LlmUsage(inputTokens: 70, outputTokens: 9),
      const LlmDone(stopReason: LlmStopReason.endTurn),
    ]);
    final innerProvider = ObservedLlmProvider(raw, observer: inner);
    final outerProvider = ObservedLlmProvider(innerProvider, observer: outer);

    await outerProvider.complete(messages: const []).toList();

    expect(inner.records, isEmpty, reason: 'the outer recorder owns the call');
    expect(outer.records, hasLength(1));
    expect(outer.records.single.usage.inputTokens, 70);
  });

  test('adopts the ledger run id when the wrapper names none', () async {
    final ledger = ProviderCallLedger(runId: 'run-42');
    final provider = ObservedLlmProvider(
      _ScriptedProvider([const LlmDone(stopReason: LlmStopReason.endTurn)]),
      observer: ledger,
      identity: ledger.identity,
    );

    await provider.complete(messages: const []).toList();

    final record = ledger.records.single;
    expect(record.runId, 'run-42');
    expect(
      record.requestId,
      'run-42:call-1',
      reason: 'an uncorrelated id is run-scoped so two runs cannot collide',
    );
  });

  test('keeps the FIRST transport boundary across a retry', () async {
    // A re-authorizing retry produces a second response body. Its byte arrival
    // must not overwrite the boundary already observed for the call — the
    // metric is "when the first response byte arrived", and the retry is later
    // by construction.
    final collector = _Collector();
    final raw = _ScriptedProvider(
      [const LlmDone(stopReason: LlmStopReason.endTurn)],
      reportsTrace: true,
      boundaryDelayMs: 150,
    );

    await _observed(raw, collector).complete(messages: const []).toList();

    final record = collector.records.single;
    expect(record.transportFirstByteMs, isNotNull);
    expect(
      record.transportFirstByteMs!,
      lessThan(raw.secondBoundaryOffsetMs!),
      reason:
          'the recorded boundary must be the first report, not the '
          'second response body',
    );
  });

  test('keeps the requested model separate from the served one', () async {
    // A configured alias can be served by a dated snapshot id. Pricing needs
    // the served id; prompt calibration is keyed by what the run asked for.
    final collector = _Collector();
    final raw = _ScriptedProvider([
      const LlmDone(stopReason: LlmStopReason.endTurn),
    ], reportsTrace: true);

    await _observed(raw, collector)
        .complete(
          messages: const [],
          config: const LlmCompleteConfig(model: 'claude-sonnet-4-5'),
        )
        .toList();

    final record = collector.records.single;
    expect(record.model, 'served-by-wire');
    expect(record.requestedModel, 'claude-sonnet-4-5');
    expect(record.requestedModelOrServed, 'claude-sonnet-4-5');

    // A serving-identity override moves WHO served, never what was asked for.
    final identified = record.withServedIdentity(
      providerId: 'rotated',
      model: 'other-model',
    );
    expect(identified.model, 'other-model');
    expect(identified.providerId, 'rotated');
    expect(identified.requestedModel, 'claude-sonnet-4-5');

    final priced = record.withCost(const ProviderCallCost(7));
    expect(priced.costMicros, 7);
    expect(priced.requestedModel, 'claude-sonnet-4-5');
  });

  test('a hand-built record falls back to the served model', () {
    const record = ProviderCallRecord(
      requestId: 'call-1',
      purpose: LlmCallPurpose.main,
      providerId: 'p',
      model: 'served',
      attempt: 1,
      outcome: ProviderCallOutcome.success,
      usage: LlmUsage(inputTokens: 1),
    );
    expect(record.requestedModel, isEmpty);
    expect(record.requestedModelOrServed, 'served');
  });

  test('attributes a fallback chain to the target that served it', () async {
    final collector = _Collector();
    final provider = _observed(_ServedIdentityProvider(), collector);

    await provider.complete(messages: const []).toList();

    expect(collector.records.single.providerId, 'rotated-key');
    expect(collector.records.single.model, 'rotated-model');
  });
}

class _ThrowingObserver implements ProviderCallObserver {
  @override
  void onProviderCall(ProviderCallRecord record) => throw StateError('boom');
}

class _TraceCapableProvider extends _ScriptedProvider
    implements LlmDeferredToolSupport {
  _TraceCapableProvider() : super(const []);

  @override
  bool supportsDeferredTools({String? model}) => model == 'supported';
}

class _ServedIdentityProvider extends _ScriptedProvider
    implements LlmServedIdentity {
  _ServedIdentityProvider()
    : super(const [LlmDone(stopReason: LlmStopReason.endTurn)]);

  @override
  String get lastServedProviderId => 'rotated-key';

  @override
  String get lastServedModel => 'rotated-model';
}
