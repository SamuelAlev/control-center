import 'package:cc_domain/core/domain/entities/llm_call_record.dart';
import 'package:cc_domain/core/domain/value_objects/llm_call_purpose.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:test/test.dart';

/// Builds a record with only the fields a test cares about overridden.
LlmCallRecord _record({
  String requestId = 'req-1',
  LlmCallPurpose purpose = LlmCallPurpose.main,
  String provider = 'anthropic',
  String modelId = 'claude-sonnet',
  DateTime? startedAt,
  DateTime? recordedAt,
  String? runId = 'run-1',
  String? workspaceId,
  String? conversationId,
  int attempt = 1,
  int inputTokens = 0,
  int outputTokens = 0,
  int thoughtTokens = 0,
  int cachedReadTokens = 0,
  int cachedWriteTokens = 0,
  int? costMicros,
  CostBasis costBasis = CostBasis.estimated,
  int? transportFirstByteMs,
  int? firstModelEventMs,
  int? durationMs,
  LlmCallOutcome outcome = LlmCallOutcome.success,
  String? errorCode,
}) {
  final start = startedAt ?? DateTime.utc(2026, 1, 1, 12);
  return LlmCallRecord(
    requestId: requestId,
    purpose: purpose,
    provider: provider,
    modelId: modelId,
    startedAt: start,
    recordedAt: recordedAt ?? start,
    runId: runId,
    workspaceId: workspaceId,
    conversationId: conversationId,
    attempt: attempt,
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    thoughtTokens: thoughtTokens,
    cachedReadTokens: cachedReadTokens,
    cachedWriteTokens: cachedWriteTokens,
    costMicros: costMicros,
    costBasis: costBasis,
    transportFirstByteMs: transportFirstByteMs,
    firstModelEventMs: firstModelEventMs,
    durationMs: durationMs,
    outcome: outcome,
    errorCode: errorCode,
  );
}

/// Covers [LlmCallRecord]: the deterministic dedup [LlmCallRecord.id], JSON
/// round-tripping (including the unpriced-vs-free distinction), rejection of
/// unusable payloads, `billableTokens` and the outcome/purpose wire parsing.
void main() {
  // ---------------------------------------------------------------------------
  // id
  // ---------------------------------------------------------------------------
  group('LlmCallRecord.id', () {
    // Protects: the dedup key is exactly `runId/requestId/attempt`, so the
    // same call re-delivered from a transcript or a CLI ledger collapses.
    test('formats a run-scoped record', () {
      expect(
        _record(runId: 'run-1', requestId: 'req-9', attempt: 2).id,
        'run-1/req-9/2',
      );
    });

    // Protects: a run-less call still gets a stable key rather than a null
    // string, so it is still deduped.
    test('formats a run-less record with a dash placeholder', () {
      expect(_record(runId: null, requestId: 'req-9').id, '-/req-9/1');
    });
  });

  // ---------------------------------------------------------------------------
  // dedup identity
  // ---------------------------------------------------------------------------
  group('LlmCallRecord identity', () {
    // Protects: two calls with different requestIds are different records even
    // when everything else matches — dedup must not merge unrelated calls.
    test('a different requestId is a different record', () {
      final a = _record(requestId: 'req-a');
      final b = _record(requestId: 'req-b');
      expect(a.id, isNot(b.id));
      expect(a == b, isFalse);
    });

    // Protects: a retry of the same request is a distinct billable call.
    test('a different attempt is a different record', () {
      final first = _record(requestId: 'req-a');
      final retry = _record(requestId: 'req-a', attempt: 2);
      expect(retry.id, isNot(first.id));
      expect(retry == first, isFalse);
    });
  });

  // ---------------------------------------------------------------------------
  // JSON round-trip
  // ---------------------------------------------------------------------------
  group('LlmCallRecord JSON round-trip', () {
    // Protects: every recorded field survives storage and replay — provenance
    // (purpose, basis, provider), timing and error all come back intact.
    test('round-trips every field', () {
      final record = _record(
        requestId: 'req-9',
        purpose: LlmCallPurpose.sideRequest,
        provider: 'openai',
        modelId: 'gpt-5',
        startedAt: DateTime.utc(2026, 2, 3, 4, 5, 6),
        recordedAt: DateTime.utc(2026, 2, 3, 4, 5, 7),
        runId: 'run-7',
        workspaceId: 'ws-1',
        conversationId: 'conv-2',
        attempt: 2,
        inputTokens: 1,
        outputTokens: 2,
        thoughtTokens: 3,
        cachedReadTokens: 4,
        cachedWriteTokens: 5,
        costMicros: 123456,
        costBasis: CostBasis.providerReported,
        transportFirstByteMs: 11,
        firstModelEventMs: 22,
        durationMs: 33,
        outcome: LlmCallOutcome.failure,
        errorCode: 'rate_limit_error',
      );

      final restored = LlmCallRecord.fromJson(record.toJson());
      expect(restored, isNotNull);
      expect(restored, record);
      expect(restored!.id, record.id);
      expect(restored.purpose, LlmCallPurpose.sideRequest);
      expect(restored.costBasis, CostBasis.providerReported);
      expect(restored.outcome, LlmCallOutcome.failure);
      expect(restored.errorCode, 'rate_limit_error');
      expect(restored.startedAt, DateTime.utc(2026, 2, 3, 4, 5, 6));
    });

    // Protects: unpriced (null) and genuinely free (0) survive storage as
    // DISTINCT states — collapsing them would misreport an unknown as zero.
    test('keeps null costMicros distinct from zero', () {
      final unpriced = _record(requestId: 'unpriced', inputTokens: 12);
      final free = _record(requestId: 'free', inputTokens: 12, costMicros: 0);

      expect(unpriced.toJson().containsKey('costMicros'), isFalse);
      expect(free.toJson()['costMicros'], 0);

      final restoredUnpriced = LlmCallRecord.fromJson(unpriced.toJson())!;
      final restoredFree = LlmCallRecord.fromJson(free.toJson())!;
      expect(restoredUnpriced.costMicros, isNull);
      expect(restoredFree.costMicros, 0);
      expect(restoredUnpriced, unpriced);
      expect(restoredFree, free);
      expect(restoredUnpriced == restoredFree, isFalse);
    });

    // Protects: a record missing its timing fallback is still orderable — the
    // record time falls back to the start time rather than null.
    test('falls back to startedAt when recordedAt is absent', () {
      final parsed = LlmCallRecord.fromJson(<String, dynamic>{
        'requestId': 'req-1',
        'startedAt': DateTime.utc(2026, 3, 3).toIso8601String(),
      });
      expect(parsed, isNotNull);
      expect(parsed!.recordedAt, DateTime.utc(2026, 3, 3));
      expect(parsed.provider, '');
      expect(parsed.purpose, LlmCallPurpose.main);
    });
  });

  // ---------------------------------------------------------------------------
  // fromJson rejection
  // ---------------------------------------------------------------------------
  group('LlmCallRecord.fromJson rejects unusable payloads', () {
    // Protects: a payload that cannot name its request or its start is not a
    // record, and must not be silently reconstructed with blanks.
    test('returns null when requestId or startedAt is missing', () {
      final json = _record().toJson();

      expect(LlmCallRecord.fromJson(null), isNull);
      expect(LlmCallRecord.fromJson('not a map'), isNull);
      expect(
        LlmCallRecord.fromJson(
          Map<String, dynamic>.of(json)..remove('requestId'),
        ),
        isNull,
      );
      expect(
        LlmCallRecord.fromJson(
          Map<String, dynamic>.of(json)..['requestId'] = '',
        ),
        isNull,
      );
      expect(
        LlmCallRecord.fromJson(
          Map<String, dynamic>.of(json)..remove('startedAt'),
        ),
        isNull,
      );
      expect(
        LlmCallRecord.fromJson(
          Map<String, dynamic>.of(json)..['startedAt'] = 42,
        ),
        isNull,
      );
    });
  });

  // ---------------------------------------------------------------------------
  // billableTokens
  // ---------------------------------------------------------------------------
  test('does not rebill reasoning already included in output', () {
    final record = _record(
      inputTokens: 10,
      outputTokens: 20,
      thoughtTokens: 15,
      cachedReadTokens: 40,
      cachedWriteTokens: 50,
    );
    // The 15 reasoning tokens are part of the 20 output tokens, not a
    // separately chargeable axis. Both independent cache axes still count.
    expect(record.billableTokens, 120);
  });

  // ---------------------------------------------------------------------------
  // wire parsing
  // ---------------------------------------------------------------------------
  group('LlmCallRecord wire parsing', () {
    // Protects: an unreadable outcome is never reported as a success.
    test('LlmCallOutcome.fromWire defaults to failure', () {
      expect(LlmCallOutcome.fromWire('nonsense'), LlmCallOutcome.failure);
      expect(LlmCallOutcome.fromWire(null), LlmCallOutcome.failure);
      expect(LlmCallOutcome.fromWire('failure'), LlmCallOutcome.failure);
      expect(LlmCallOutcome.fromWire('success'), LlmCallOutcome.success);
      expect(LlmCallOutcome.fromWire('cancelled'), LlmCallOutcome.cancelled);
      expect(LlmCallOutcome.cancelled.wire, 'cancelled');
    });

    // Protects: `succeeded` reflects only a completed call; failures and
    // cancellations both count as not-succeeded.
    test('succeeded is true only for success', () {
      expect(_record(outcome: LlmCallOutcome.success).succeeded, isTrue);
      expect(_record(outcome: LlmCallOutcome.failure).succeeded, isFalse);
      expect(_record(outcome: LlmCallOutcome.cancelled).succeeded, isFalse);
    });

    // Protects: the snake_case wire spelling round-trips, and an unknown
    // purpose falls back to the implicit pre-attribution purpose.
    test('LlmCallPurpose.fromWire reads side_request and defaults to main', () {
      expect(
        LlmCallPurpose.fromWire('side_request'),
        LlmCallPurpose.sideRequest,
      );
      expect(LlmCallPurpose.sideRequest.wire, 'side_request');
      expect(LlmCallPurpose.fromWire('nonsense'), LlmCallPurpose.main);
      expect(LlmCallPurpose.fromWire(null), LlmCallPurpose.main);
      expect(LlmCallPurpose.fromWire('advisor'), LlmCallPurpose.advisor);
    });
  });
}
