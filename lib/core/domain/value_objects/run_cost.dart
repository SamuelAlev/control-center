import 'package:control_center/core/domain/entities/agent_run_log.dart' show AgentRunLog;

/// Per-run token usage and cost breakdown.
class RunCost {
  const RunCost({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.thoughtTokens = 0,
    this.cachedReadTokens = 0,
    this.cachedWriteTokens = 0,
    this.estimatedCostCents = 0,
    this.durationMs,
    this.timeToFirstTokenMs,
  });

  final int inputTokens;
  final int outputTokens;

  /// Tokens used for thinking / reasoning output.
  final int thoughtTokens;

  /// Cache-hit read tokens (discounted by the model provider).
  final int cachedReadTokens;

  /// Cache-hit write tokens (discounted by the model provider).
  final int cachedWriteTokens;

  final int estimatedCostCents;

  /// Total wall-clock duration in milliseconds, if measured.
  final int? durationMs;

  /// Time from run start to first output token in milliseconds, if measured.
  final int? timeToFirstTokenMs;

  int get totalTokens =>
      inputTokens + outputTokens + thoughtTokens + cachedReadTokens + cachedWriteTokens;

  RunCost operator +(RunCost other) => RunCost(
        inputTokens: inputTokens + other.inputTokens,
        outputTokens: outputTokens + other.outputTokens,
        thoughtTokens: thoughtTokens + other.thoughtTokens,
        cachedReadTokens: cachedReadTokens + other.cachedReadTokens,
        cachedWriteTokens: cachedWriteTokens + other.cachedWriteTokens,
        estimatedCostCents:
            estimatedCostCents + other.estimatedCostCents,
        durationMs: durationMs != null && other.durationMs != null
            ? durationMs! + other.durationMs!
            : (durationMs ?? other.durationMs),
        timeToFirstTokenMs: timeToFirstTokenMs ?? other.timeToFirstTokenMs,
      );

  static const zero = RunCost();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunCost &&
          inputTokens == other.inputTokens &&
          outputTokens == other.outputTokens &&
          thoughtTokens == other.thoughtTokens &&
          cachedReadTokens == other.cachedReadTokens &&
          cachedWriteTokens == other.cachedWriteTokens &&
          estimatedCostCents == other.estimatedCostCents &&
          durationMs == other.durationMs &&
          timeToFirstTokenMs == other.timeToFirstTokenMs;

  @override
  int get hashCode => Object.hash(
        inputTokens,
        outputTokens,
        thoughtTokens,
        cachedReadTokens,
        cachedWriteTokens,
        estimatedCostCents,
        durationMs,
        timeToFirstTokenMs,
      );
}

/// Structured usage report from an adapter, aggregated into [RunCost]
/// for persistence on [AgentRunLog].
class RunUsage {
  const RunUsage({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.thoughtTokens = 0,
    this.cachedReadTokens = 0,
    this.cachedWriteTokens = 0,
    this.estimatedCostCents = 0,
  });

  final int inputTokens;
  final int outputTokens;
  final int thoughtTokens;
  final int cachedReadTokens;
  final int cachedWriteTokens;
  final int estimatedCostCents;

  int get totalTokens =>
      inputTokens + outputTokens + thoughtTokens + cachedReadTokens + cachedWriteTokens;

  /// Converts to [RunCost] for persistence on [AgentRunLog].
  RunCost toCost({int? durationMs, int? timeToFirstTokenMs}) => RunCost(
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        thoughtTokens: thoughtTokens,
        cachedReadTokens: cachedReadTokens,
        cachedWriteTokens: cachedWriteTokens,
        estimatedCostCents: estimatedCostCents,
        durationMs: durationMs,
        timeToFirstTokenMs: timeToFirstTokenMs,
      );

  static const zero = RunUsage();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RunUsage &&
          inputTokens == other.inputTokens &&
          outputTokens == other.outputTokens &&
          thoughtTokens == other.thoughtTokens &&
          cachedReadTokens == other.cachedReadTokens &&
          cachedWriteTokens == other.cachedWriteTokens &&
          estimatedCostCents == other.estimatedCostCents;

  @override
  int get hashCode => Object.hash(
        inputTokens,
        outputTokens,
        thoughtTokens,
        cachedReadTokens,
        cachedWriteTokens,
        estimatedCostCents,
      );
}
