import 'package:cc_domain/features/code_mode/domain/entities/code_execution.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';

/// One finished `repl` call, as the metrics see it.
///
/// Everything an operator aggregates over executions: failure rate by status,
/// durations, nested calls per execution, and how many bytes of tool results
/// a script kept out of the model's context against what it returned.
class CodeExecutionSample {
  /// Creates a sample.
  const CodeExecutionSample({
    required this.admitted,
    required this.surface,
    required this.status,
    required this.durationMs,
    required this.admissionWaitMs,
    required this.personWaitMs,
    required this.calls,
    required this.questionCount,
    required this.nestedResultBytes,
    required this.outputBytes,
    required this.returnedChars,
    required this.outputTruncated,
    this.errorKind,
  });

  /// Whether the script was admitted (and so recorded). A call refused
  /// before admission (`run_busy`, `server_busy`, an invalid id, code mode
  /// unavailable, an oversized source, a cancel while it waited for a slot)
  /// did nothing and has no record; this sample is all that counts it.
  final bool admitted;

  /// Which surface ran the script.
  final CodeExecutionSurface surface;

  /// How it ended.
  final CodeExecutionStatus status;

  /// Why a script that did not complete ended, from
  /// `CodeExecutionErrorKind.values`.
  final String? errorKind;

  /// Wall-clock milliseconds from the request to the result, waits included.
  final int durationMs;

  /// Milliseconds spent waiting for a free runner slot.
  final int admissionWaitMs;

  /// Milliseconds the script spent waiting on a person (not charged to its
  /// deadline).
  final int personWaitMs;

  /// Nested tool calls by outcome.
  final NestedCallCounts calls;

  /// Questions the script asked a person.
  final int questionCount;

  /// UTF-8 bytes of nested tool results handed to the script: what stayed
  /// out of the model's context.
  final int nestedResultBytes;

  /// UTF-8 bytes of output the script produced, before truncation.
  final int outputBytes;

  /// Characters of result text the model read.
  final int returnedChars;

  /// Whether the output was cut to its head and tail for the model.
  final bool outputTruncated;
}

/// Receives one [CodeExecutionSample] per finished `repl` call.
///
/// The execution service reports through this rather than through
/// `observability_metrics.dart`, which aggregates run logs after the fact
/// and has no counters to add to. The server wires an implementation that
/// feeds whatever metrics backend it uses. A listener must not throw; the
/// service ignores one that does.
abstract interface class CodeExecutionMetrics {
  /// Records [sample].
  void recordExecution(CodeExecutionSample sample);
}
