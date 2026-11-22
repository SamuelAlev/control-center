/// Code mode scripts in a transcript: which calls a script made, how each
/// ended, and how the script itself stands.
///
/// The phone folds a script's calls under the `repl` row the same way the
/// desktop does (the desktop's `nested_calls.dart` and
/// `script_status_line.dart`); the two apps share no presentation package, so
/// the rules are restated here. `test/script_calls_test.dart` round-trips the
/// server's status lines through them, as the desktop's test does.
library;

import 'package:cc_domain/core/domain/services/transcript_status.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';

/// Whether [toolName] is the code mode `repl` tool, under its own name or the
/// name an external adapter sees (`mcp__control-center__repl`).
bool isReplTool(String toolName) => normalizeToolName(toolName) == 'repl';

/// How one call a script made ended.
enum NestedCallState { running, ok, failed, denied, cancelled }

/// The [NestedCallState] of [seg]: its [ToolSegment.outcome] when that names
/// a refusal (`denied`), a cancellation or a timeout (both shown as
/// cancelled), otherwise its status. An error with no such outcome is a
/// failure; the result text is never parsed.
NestedCallState nestedCallStateOf(ToolSegment seg) => switch (seg.outcome) {
  'denied' => NestedCallState.denied,
  'cancelled' || 'timed_out' => NestedCallState.cancelled,
  _ => switch (seg.status) {
    ToolSegmentStatus.running => NestedCallState.running,
    ToolSegmentStatus.ok => NestedCallState.ok,
    ToolSegmentStatus.interrupted => NestedCallState.cancelled,
    ToolSegmentStatus.error => NestedCallState.failed,
  },
};

/// Counts of the calls a script made, by how each ended.
class NestedCallTally {
  NestedCallTally.of(Iterable<ToolSegment> calls) {
    for (final call in calls) {
      switch (nestedCallStateOf(call)) {
        case NestedCallState.running:
          running++;
        case NestedCallState.ok:
          ok++;
        case NestedCallState.failed:
          failed++;
        case NestedCallState.denied:
          denied++;
        case NestedCallState.cancelled:
          cancelled++;
      }
    }
  }

  int running = 0;
  int ok = 0;
  int failed = 0;
  int denied = 0;
  int cancelled = 0;

  int get total => running + ok + failed + denied + cancelled;
}

/// Whether [toolName] runs a script whose calls fold under its row: the code
/// mode `repl` tool, under either name.
bool isScriptTool(String toolName) => normalizeToolName(toolName) == 'repl';

/// For every segment that has nested calls, the indices of those calls in
/// [segments], in list order.
///
/// A call folds under the nearest segment before it whose call id is its
/// parent id, and only when that segment runs a script ([isScriptTool]). Ids
/// repeat (local models reuse `call_0`), so the nearest earlier match is the
/// script that made the call and two scripts sharing an id keep their own
/// calls. Any other call stays a row of its own, never hidden: a missing or
/// later parent, or a parent that is not a script.
Map<int, List<int>> foldNestedCalls(List<TranscriptSegment> segments) {
  final latestById = <String, int>{};
  final rootOf = <int, int>{};
  final out = <int, List<int>>{};
  for (var i = 0; i < segments.length; i++) {
    final seg = segments[i];
    if (seg is! ToolSegment) {
      continue;
    }
    final parentId = seg.parentToolCallId;
    if (parentId != null) {
      final parent = latestById[parentId];
      final script = parent == null ? null : segments[parent];
      if (parent != null &&
          script is ToolSegment &&
          isScriptTool(script.toolName)) {
        final root = rootOf[parent] ?? parent;
        rootOf[i] = root;
        (out[root] ??= <int>[]).add(i);
      }
    }
    if (seg.toolCallId.isNotEmpty) {
      latestById[seg.toolCallId] = i;
    }
  }
  return out;
}

/// How a `repl` script stands.
enum ScriptRunState {
  running,
  completed,
  failed,
  timedOut,
  cancelled,
  memoryExceeded,
  outputExceeded,
  sandboxError,
  refused,
}

/// The state of the `repl` call [seg], with the text after its first line
/// (`Script completed in 2.4 s · …`).
///
/// The state is the segment's [ToolSegment.outcome] (the execution status the
/// server recorded) when it carries one. Only a transcript without it, an
/// external adapter's, reads the state from that first line; a first line the
/// server does not write falls back to the segment status and keeps the whole
/// output.
({ScriptRunState state, String? detail, String rest}) readScriptStatus(
  ToolSegment seg,
) {
  final fallback = switch (seg.status) {
    ToolSegmentStatus.running => ScriptRunState.running,
    ToolSegmentStatus.ok => ScriptRunState.completed,
    ToolSegmentStatus.error => ScriptRunState.failed,
    ToolSegmentStatus.interrupted => ScriptRunState.cancelled,
  };
  final whole = (state: fallback, detail: null, rest: seg.outputs.trim());
  if (seg.status == ToolSegmentStatus.running) {
    return whole;
  }
  final line = _readStatusLine(seg.outputs);
  final recorded = switch (CodeExecutionStatus.tryParse(seg.outcome)) {
    final CodeExecutionStatus status => _scriptRunStateOf(status),
    null => null,
  };
  if (recorded != null) {
    return (
      state: recorded,
      detail: line?.detail,
      rest: line?.rest ?? whole.rest,
    );
  }
  return line ?? whole;
}

ScriptRunState _scriptRunStateOf(CodeExecutionStatus status) =>
    switch (status) {
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

/// The state the first line of [outputs] states, the refusal's reason as its
/// detail and the text after the line; null when the line is not one the
/// server writes.
({ScriptRunState state, String? detail, String rest})? _readStatusLine(
  String outputs,
) {
  final text = outputs.trimLeft();
  final end = text.indexOf('\n');
  final first = (end < 0 ? text : text.substring(0, end)).trim();
  final rest = end < 0 ? '' : text.substring(end + 1).trim();
  const refused = 'Script refused:';
  if (first.startsWith(refused)) {
    final detail = first.substring(refused.length).trim();
    return (
      state: ScriptRunState.refused,
      detail: detail.isEmpty ? null : detail,
      rest: rest,
    );
  }
  for (final (prefix, state) in _prefixes) {
    if (first.startsWith(prefix)) {
      return (state: state, detail: null, rest: rest);
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
