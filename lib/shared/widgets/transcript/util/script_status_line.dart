import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';

/// How a `repl` script stands, as its row reports it.
enum ScriptRunState {
  /// No result yet.
  running,

  /// Ran to the end.
  completed,

  /// Threw, or its result could not be used.
  failed,

  /// Hit its wall-clock or CPU limit.
  timedOut,

  /// Stopped by the person or the run ending.
  cancelled,

  /// Hit its memory limit.
  memoryExceeded,

  /// Wrote more output than it may.
  outputExceeded,

  /// The sandbox it runs in failed.
  sandboxError,

  /// Never ran.
  refused,
}

/// The first line of a `repl` result, read back into a state, and the text
/// that follows it.
///
/// The server writes that line in English for the model to read
/// (`Script completed in 2.4 s · 7 tool calls (6 ok, 1 failed)`, see
/// `ScriptResultFormatter.firstLine`). The row shows the state as a status
/// and the duration from the segment itself, so the person never has to parse
/// the sentence.
class ScriptStatusLine {
  /// Creates a status line.
  const ScriptStatusLine({
    required this.state,
    required this.rest,
    this.detail,
  });

  /// The state the line reports.
  final ScriptRunState state;

  /// Why a refused script never ran, when the line says.
  final String? detail;

  /// Everything after the first line: the script's output, its error and the
  /// calls it made before it stopped.
  final String rest;
}

/// Reads the state of the `repl` call [seg].
///
/// A running call has no result to read. A finished call whose first line is
/// not one the server writes still gets a state from its segment status, and
/// its whole output is kept as [ScriptStatusLine.rest].
ScriptStatusLine readScriptStatus(ToolSegment seg) {
  final fallback = switch (seg.status) {
    ToolSegmentStatus.running => ScriptRunState.running,
    ToolSegmentStatus.ok => ScriptRunState.completed,
    ToolSegmentStatus.error => ScriptRunState.failed,
    ToolSegmentStatus.interrupted => ScriptRunState.cancelled,
  };
  final text = seg.outputs;
  if (seg.status == ToolSegmentStatus.running) {
    return ScriptStatusLine(state: fallback, rest: text.trim());
  }
  final trimmed = text.trimLeft();
  final end = trimmed.indexOf('\n');
  final first = (end < 0 ? trimmed : trimmed.substring(0, end)).trim();
  final rest = end < 0 ? '' : trimmed.substring(end + 1).trim();
  final parsed = parseScriptStatusLine(first);
  // The server records how the script ended on the segment itself when it
  // ran the script; that outranks the sentence. An external adapter's own
  // transcript carries no such field, so its row is read from the line.
  final recorded = switch (CodeExecutionStatus.tryParse(seg.outcome)) {
    final CodeExecutionStatus status => _stateOf(status),
    null => null,
  };
  if (recorded != null) {
    return ScriptStatusLine(
      state: recorded,
      detail: parsed?.detail,
      rest: parsed == null ? text.trim() : rest,
    );
  }
  if (parsed == null) {
    return ScriptStatusLine(state: fallback, rest: text.trim());
  }
  return ScriptStatusLine(
    state: parsed.state,
    detail: parsed.detail,
    rest: rest,
  );
}

ScriptRunState _stateOf(CodeExecutionStatus status) => switch (status) {
  CodeExecutionStatus.running => ScriptRunState.running,
  CodeExecutionStatus.completed => ScriptRunState.completed,
  CodeExecutionStatus.failed => ScriptRunState.failed,
  CodeExecutionStatus.timedOut => ScriptRunState.timedOut,
  CodeExecutionStatus.cancelled => ScriptRunState.cancelled,
  CodeExecutionStatus.memoryExceeded => ScriptRunState.memoryExceeded,
  CodeExecutionStatus.outputExceeded => ScriptRunState.outputExceeded,
  CodeExecutionStatus.sandboxError => ScriptRunState.sandboxError,
  CodeExecutionStatus.refused => ScriptRunState.refused,
};

/// The state [line] reports, or null when it is not a `repl` status line.
({ScriptRunState state, String? detail})? parseScriptStatusLine(String line) {
  const refused = 'Script refused:';
  if (line.startsWith(refused)) {
    final detail = line.substring(refused.length).trim();
    return (
      state: ScriptRunState.refused,
      detail: detail.isEmpty ? null : detail,
    );
  }
  for (final (prefix, state) in _prefixes) {
    if (line.startsWith(prefix)) {
      return (state: state, detail: null);
    }
  }
  return null;
}

const List<(String, ScriptRunState)> _prefixes = [
  ('Script completed in ', ScriptRunState.completed),
  ('Script failed after ', ScriptRunState.failed),
  ('Script timed out after ', ScriptRunState.timedOut),
  ('Script cancelled after ', ScriptRunState.cancelled),
  ('Script ran out of memory after ', ScriptRunState.memoryExceeded),
  ('Script stopped after ', ScriptRunState.outputExceeded),
  ('Script sandbox failed after ', ScriptRunState.sandboxError),
];
