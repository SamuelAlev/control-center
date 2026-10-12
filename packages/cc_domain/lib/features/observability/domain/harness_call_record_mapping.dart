import 'package:cc_domain/core/domain/entities/llm_call_record.dart' as domain;
import 'package:cc_domain/core/domain/value_objects/llm_call_purpose.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_harness/provider.dart' as harness;

/// Maps the provider layer's call record (`cc_harness`, which cannot depend on
/// `cc_domain`) onto the domain ledger entity.
///
/// This is the ONLY place the two types meet: the provider boundary records
/// what it measured, the domain owns the dedup key, the exact cost basis and
/// the durable/observable shape. Keeping the conversion here means a rename on
/// either side breaks exactly one file instead of silently dropping fields.
extension HarnessLlmCallRecordMapping on harness.ProviderCallRecord {
  /// Converts this provider-boundary record into a domain [domain.LlmCallRecord].
  ///
  /// [runStartedAt] anchors the record's MONOTONIC `startedAtMs` offset to a
  /// wall-clock instant — the provider layer measures elapsed time from its own
  /// injected stopwatch and never pretends to know the run's wall clock, so the
  /// caller (which does) supplies the anchor. [runId], [workspaceId] and
  /// [conversationId] default to whatever the provider record already carries.
  domain.LlmCallRecord toDomainLlmCallRecord({
    required DateTime runStartedAt,
    String? runId,
    String? workspaceId,
    String? conversationId,
  }) {
    final startedAt = runStartedAt.add(Duration(milliseconds: startedAtMs));
    return domain.LlmCallRecord(
      requestId: requestId,
      purpose: LlmCallPurpose.fromWire(purpose.wire),
      provider: providerId,
      modelId: model,
      startedAt: startedAt,
      recordedAt: runStartedAt.add(Duration(milliseconds: finishedAtMs)),
      runId: runId ?? this.runId,
      workspaceId: workspaceId,
      conversationId: conversationId,
      attempt: attempt,
      inputTokens: usage.inputTokens,
      outputTokens: usage.outputTokens,
      thoughtTokens: usage.thoughtTokens,
      cachedReadTokens: usage.cacheReadTokens,
      cachedWriteTokens: usage.cacheWriteTokens,
      costMicros: costMicros,
      costBasis: CostBasis.fromWire(costBasis.wire),
      transportFirstByteMs: transportFirstByteMs,
      firstModelEventMs: firstModelEventMs,
      durationMs: durationMs,
      outcome: domain.LlmCallOutcome.fromWire(outcome.wire),
      errorCode: errorCode,
    );
  }
}

/// Converts every provider-boundary record to a domain record, preserving
/// order.
List<domain.LlmCallRecord> toDomainLlmCallRecords(
  Iterable<harness.ProviderCallRecord> records, {
  required DateTime runStartedAt,
  String? runId,
  String? workspaceId,
  String? conversationId,
}) => [
  for (final record in records)
    record.toDomainLlmCallRecord(
      runStartedAt: runStartedAt,
      runId: runId,
      workspaceId: workspaceId,
      conversationId: conversationId,
    ),
];
