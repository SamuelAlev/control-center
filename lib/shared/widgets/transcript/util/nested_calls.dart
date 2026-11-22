import 'package:cc_domain/core/domain/services/transcript_status.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';

/// Whether [toolName] is the code mode `repl` tool, under its own name or the
/// name an external adapter sees (`mcp__control-center__repl`).
bool isReplTool(String toolName) => normalizeToolName(toolName) == 'repl';

/// How one call a script made ended, as the transcript shows it.
///
/// [ToolSegmentStatus] has no "denied": a call the gate refused is an error
/// result whose [ToolSegment.outcome] says `denied` (the harness gate and the
/// MCP dispatcher both set it), so it is told apart here rather than reading
/// as a tool that ran and failed. The result text is never parsed.
enum NestedCallState {
  /// Still running.
  running,

  /// Completed.
  ok,

  /// Ran and failed.
  failed,

  /// Refused before it ran: by a person, a policy or a hook.
  denied,

  /// Stopped before it produced a result: cancelled, or abandoned at its
  /// time limit.
  cancelled,
}

/// The [NestedCallState] of [seg]: its [ToolSegment.outcome] when that names
/// a refusal, a cancellation or a timeout, otherwise its status. An error
/// with no such outcome is a failure.
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
  /// Counts [calls].
  factory NestedCallTally.of(Iterable<ToolSegment> calls) {
    var running = 0;
    var ok = 0;
    var failed = 0;
    var denied = 0;
    var cancelled = 0;
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
    return NestedCallTally._(
      running: running,
      ok: ok,
      failed: failed,
      denied: denied,
      cancelled: cancelled,
    );
  }

  const NestedCallTally._({
    required this.running,
    required this.ok,
    required this.failed,
    required this.denied,
    required this.cancelled,
  });

  /// Calls still running.
  final int running;

  /// Calls that completed.
  final int ok;

  /// Calls that ran and failed.
  final int failed;

  /// Calls refused before they ran.
  final int denied;

  /// Calls stopped before they produced a result.
  final int cancelled;

  /// Every call.
  int get total => running + ok + failed + denied + cancelled;
}

/// Whether [toolName] runs a script whose calls fold under its row: the code
/// mode `repl` tool, under either name.
bool isScriptTool(String toolName) => normalizeToolName(toolName) == 'repl';

/// Folds the calls scripts made under the call that ran each script.
///
/// Returns, for every segment that has nested calls, the indices of those
/// calls in [segments], in list order (the server appends them in the order
/// the script made them).
///
/// A nested call folds under the nearest segment *before* it whose call id is
/// its [ToolSegment.parentToolCallId], and only when that segment runs a
/// script ([isScriptTool]). Tool call ids repeat (local models reuse
/// `call_0` on every turn), so the nearest earlier match is the script that
/// made the call, and two scripts that share an id each keep their own calls.
/// Any other case leaves the call as a row of its own, never hidden: a parent
/// that is not in [segments] (pruned, or not loaded yet), a parent that comes
/// after the call, and a parent that is not a script (a call cannot borrow
/// another tool's row). Should the script row itself be folded, its calls go
/// with it to the same row, so the transcript stays one level deep.
///
/// Matching is on [ToolSegment.parentToolCallId] alone; the shape of the ids
/// (`<parent>/<n>`) is a server detail the client does not rely on.
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

/// The calls at [children] in [segments], in order.
///
/// While a turn streams, [fresh] reads a call's current state: only a call
/// that was still running needs it, because a finished call never changes.
List<ToolSegment> nestedCallsAt(
  List<int> children,
  List<TranscriptSegment> segments, {
  TranscriptSegment? Function(int index)? fresh,
}) => [
  for (final i in children)
    if (i < segments.length)
      if (segments[i] case final ToolSegment call)
        if (fresh != null && call.status == ToolSegmentStatus.running)
          switch (fresh(i)) {
            final ToolSegment current => current,
            _ => call,
          }
        else
          call,
];
