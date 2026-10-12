import 'package:cc_domain/core/domain/value_objects/llm_call_purpose.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';

/// How a single model call ended.
enum LlmCallOutcome {
  /// The call completed (with or without tool calls pending).
  success,

  /// The call failed; its partial usage is still billed and still recorded.
  failure,

  /// The call was abandoned before completion (shutdown, watchdog kill).
  cancelled;

  /// Stable wire/storage spelling.
  String get wire {
    switch (this) {
      case LlmCallOutcome.success:
        return 'success';
      case LlmCallOutcome.failure:
        return 'failure';
      case LlmCallOutcome.cancelled:
        return 'cancelled';
    }
  }

  /// Parses a wire/storage spelling, defaulting to [failure] for anything
  /// unrecognized: an unreadable outcome must not be reported as a success.
  static LlmCallOutcome fromWire(String? value) {
    switch (value) {
      case 'success':
        return LlmCallOutcome.success;
      case 'cancelled':
        return LlmCallOutcome.cancelled;
      case 'failure':
      default:
        return LlmCallOutcome.failure;
    }
  }
}

/// One model request's accounting, recorded AT THE PROVIDER BOUNDARY.
///
/// A request's tokens and cost are billed whether or not the loop ever saw the
/// result: a failed attempt, a retried attempt and an auxiliary call (a
/// summarizer, an advisor, a side request, a subagent) all spend real money.
/// The loop used to discard those (the harness summarizer consumed text and
/// dropped its `LlmUsage`), which made any optimization that MOVED work
/// off-thread look cheaper while spending exactly as much.
///
/// [id] is a deterministic dedup key, so a record delivered twice — replayed
/// from a transcript, re-read from a cumulative CLI ledger, re-emitted after a
/// retry — is counted exactly once.
class LlmCallRecord {
  /// Creates a call record.
  const LlmCallRecord({
    required this.requestId,
    required this.purpose,
    required this.provider,
    required this.modelId,
    required this.startedAt,
    required this.recordedAt,
    this.runId,
    this.workspaceId,
    this.conversationId,
    this.attempt = 1,
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.thoughtTokens = 0,
    this.cachedReadTokens = 0,
    this.cachedWriteTokens = 0,
    this.costMicros,
    this.costBasis = CostBasis.estimated,
    this.transportFirstByteMs,
    this.firstModelEventMs,
    this.durationMs,
    this.outcome = LlmCallOutcome.success,
    this.errorCode,
  }) : assert(requestId != '', 'LlmCallRecord requestId must not be empty'),
       assert(attempt >= 1, 'LlmCallRecord attempt is 1-based');

  /// Id the provider/loop assigned to this request (stable across retries).
  final String requestId;

  /// What the call was for.
  final LlmCallPurpose purpose;

  /// Provider id that served the call (e.g. `anthropic`, `claude-cli`).
  final String provider;

  /// The model that ACTUALLY served the call, not the requested alias.
  final String modelId;

  /// When the call started (wall clock, for ordering/display).
  final DateTime startedAt;

  /// When the record was captured.
  final DateTime recordedAt;

  /// Run this call belongs to, when known.
  final String? runId;

  /// Workspace the run belongs to, when known.
  final String? workspaceId;

  /// Conversation the run belongs to, when known.
  final String? conversationId;

  /// 1-based attempt number for calls sharing a [requestId].
  final int attempt;

  /// Non-cached input tokens.
  final int inputTokens;

  /// Output (completion) tokens, including reported reasoning tokens.
  final int outputTokens;

  /// Reasoning subset of [outputTokens], when separately reported.
  final int thoughtTokens;

  /// Cache-hit read tokens.
  final int cachedReadTokens;

  /// Cache-write tokens.
  final int cachedWriteTokens;

  /// Exact cost in micro-USD (`1e-6` USD), or null when the call is UNPRICED.
  ///
  /// Null and `0` mean different things — unpriced versus genuinely free — and
  /// collapsing them made an unpriced auxiliary call indistinguishable from a
  /// free one in a cost report.
  final int? costMicros;

  /// How [costMicros] was obtained.
  final CostBasis costBasis;

  /// Milliseconds from request start to the first response byte on the
  /// transport, or null when no transport byte was observable (e.g. a CLI that
  /// hides its socket).
  final int? transportFirstByteMs;

  /// Milliseconds from request start to the first model delta, or null when
  /// unobserved.
  final int? firstModelEventMs;

  /// Total call duration in milliseconds, when measured.
  final int? durationMs;

  /// How the call ended. Failures keep their partial usage.
  final LlmCallOutcome outcome;

  /// Structured error code when [outcome] is not [LlmCallOutcome.success].
  final String? errorCode;

  /// Deterministic exact-once key: `runId/requestId/attempt`.
  String get id => '${runId ?? '-'}/$requestId/$attempt';

  /// True when the call completed.
  bool get succeeded => outcome == LlmCallOutcome.success;

  /// Tokens the provider processed and charged for.
  int get billableTokens =>
      inputTokens + outputTokens + cachedReadTokens + cachedWriteTokens;

  /// This record's usage as a [RunUsage], carrying the exact cost basis.
  RunUsage toUsage() => RunUsage(
    inputTokens: inputTokens,
    outputTokens: outputTokens,
    thoughtTokens: thoughtTokens,
    cachedReadTokens: cachedReadTokens,
    cachedWriteTokens: cachedWriteTokens,
    estimatedCostCents: costMicros == null ? 0 : (costMicros! / 10000).round(),
    costMicros: costMicros ?? 0,
    costBasis: costBasis,
  );

  /// JSON-safe map for the wire and durable storage.
  Map<String, dynamic> toJson() => {
    'id': id,
    'requestId': requestId,
    'runId': ?runId,
    'workspaceId': ?workspaceId,
    'conversationId': ?conversationId,
    'purpose': purpose.wire,
    'provider': provider,
    'modelId': modelId,
    'attempt': attempt,
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'thoughtTokens': thoughtTokens,
    'cachedReadTokens': cachedReadTokens,
    'cachedWriteTokens': cachedWriteTokens,
    'costMicros': ?costMicros,
    'costBasis': costBasis.name,
    'transportFirstByteMs': ?transportFirstByteMs,
    'firstModelEventMs': ?firstModelEventMs,
    'durationMs': ?durationMs,
    'outcome': outcome.wire,
    'errorCode': ?errorCode,
    'startedAt': startedAt.toIso8601String(),
    'recordedAt': recordedAt.toIso8601String(),
  };

  /// Rebuilds a record from [toJson] output; null when the payload is
  /// unusable (a record that cannot name its request is not a record).
  static LlmCallRecord? fromJson(Object? raw) {
    if (raw is! Map) {
      return null;
    }
    final requestId = raw['requestId'];
    final startedAt = raw['startedAt'];
    if (requestId is! String || requestId.isEmpty || startedAt is! String) {
      return null;
    }
    int intOf(Object? v) => v is num ? v.toInt() : 0;
    int? nullableInt(Object? v) => v is num ? v.toInt() : null;
    return LlmCallRecord(
      requestId: requestId,
      purpose: LlmCallPurpose.fromWire(raw['purpose'] as String?),
      provider: raw['provider'] as String? ?? '',
      modelId: raw['modelId'] as String? ?? '',
      startedAt: DateTime.parse(startedAt),
      recordedAt:
          DateTime.tryParse(raw['recordedAt'] as String? ?? '') ??
          DateTime.parse(startedAt),
      runId: raw['runId'] as String?,
      workspaceId: raw['workspaceId'] as String?,
      conversationId: raw['conversationId'] as String?,
      attempt: nullableInt(raw['attempt']) ?? 1,
      inputTokens: intOf(raw['inputTokens']),
      outputTokens: intOf(raw['outputTokens']),
      thoughtTokens: intOf(raw['thoughtTokens']),
      cachedReadTokens: intOf(raw['cachedReadTokens']),
      cachedWriteTokens: intOf(raw['cachedWriteTokens']),
      costMicros: nullableInt(raw['costMicros']),
      costBasis: CostBasis.fromWire(raw['costBasis'] as String?),
      transportFirstByteMs: nullableInt(raw['transportFirstByteMs']),
      firstModelEventMs: nullableInt(raw['firstModelEventMs']),
      durationMs: nullableInt(raw['durationMs']),
      outcome: LlmCallOutcome.fromWire(raw['outcome'] as String?),
      errorCode: raw['errorCode'] as String?,
    );
  }

  /// Returns a copy with the given overrides. Null-removal is not needed here:
  /// a record is written once at the boundary and never patched.
  LlmCallRecord copyWith({
    String? requestId,
    LlmCallPurpose? purpose,
    String? provider,
    String? modelId,
    DateTime? startedAt,
    DateTime? recordedAt,
    String? runId,
    String? workspaceId,
    String? conversationId,
    int? attempt,
    int? inputTokens,
    int? outputTokens,
    int? thoughtTokens,
    int? cachedReadTokens,
    int? cachedWriteTokens,
    int? costMicros,
    CostBasis? costBasis,
    int? transportFirstByteMs,
    int? firstModelEventMs,
    int? durationMs,
    LlmCallOutcome? outcome,
    String? errorCode,
  }) => LlmCallRecord(
    requestId: requestId ?? this.requestId,
    purpose: purpose ?? this.purpose,
    provider: provider ?? this.provider,
    modelId: modelId ?? this.modelId,
    startedAt: startedAt ?? this.startedAt,
    recordedAt: recordedAt ?? this.recordedAt,
    runId: runId ?? this.runId,
    workspaceId: workspaceId ?? this.workspaceId,
    conversationId: conversationId ?? this.conversationId,
    attempt: attempt ?? this.attempt,
    inputTokens: inputTokens ?? this.inputTokens,
    outputTokens: outputTokens ?? this.outputTokens,
    thoughtTokens: thoughtTokens ?? this.thoughtTokens,
    cachedReadTokens: cachedReadTokens ?? this.cachedReadTokens,
    cachedWriteTokens: cachedWriteTokens ?? this.cachedWriteTokens,
    costMicros: costMicros ?? this.costMicros,
    costBasis: costBasis ?? this.costBasis,
    transportFirstByteMs: transportFirstByteMs ?? this.transportFirstByteMs,
    firstModelEventMs: firstModelEventMs ?? this.firstModelEventMs,
    durationMs: durationMs ?? this.durationMs,
    outcome: outcome ?? this.outcome,
    errorCode: errorCode ?? this.errorCode,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LlmCallRecord &&
          requestId == other.requestId &&
          purpose == other.purpose &&
          provider == other.provider &&
          modelId == other.modelId &&
          startedAt == other.startedAt &&
          recordedAt == other.recordedAt &&
          runId == other.runId &&
          workspaceId == other.workspaceId &&
          conversationId == other.conversationId &&
          attempt == other.attempt &&
          inputTokens == other.inputTokens &&
          outputTokens == other.outputTokens &&
          thoughtTokens == other.thoughtTokens &&
          cachedReadTokens == other.cachedReadTokens &&
          cachedWriteTokens == other.cachedWriteTokens &&
          costMicros == other.costMicros &&
          costBasis == other.costBasis &&
          transportFirstByteMs == other.transportFirstByteMs &&
          firstModelEventMs == other.firstModelEventMs &&
          durationMs == other.durationMs &&
          outcome == other.outcome &&
          errorCode == other.errorCode;

  @override
  int get hashCode => Object.hashAll([
    requestId,
    purpose,
    provider,
    modelId,
    startedAt,
    recordedAt,
    runId,
    workspaceId,
    conversationId,
    attempt,
    inputTokens,
    outputTokens,
    thoughtTokens,
    cachedReadTokens,
    cachedWriteTokens,
    costMicros,
    costBasis,
    transportFirstByteMs,
    firstModelEventMs,
    durationMs,
    outcome,
    errorCode,
  ]);
}
