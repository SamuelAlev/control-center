import 'dart:collection';

import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart'
    show canonicalHash;
import 'package:cc_harness/tools.dart' show ActionClass;

/// One tool call of a run, as its transcript recorded it: the tool's name,
/// its arguments and whether it succeeded.
class RunToolCall {
  /// Creates a call record.
  const RunToolCall({
    required this.name,
    required this.arguments,
    required this.ok,
  });

  /// The transcript's [ToolSegment] as a call record. A call still running
  /// or interrupted when the run ended did not succeed.
  factory RunToolCall.fromSegment(ToolSegment segment) => RunToolCall(
    name: segment.toolName,
    arguments: segment.inputs ?? const {},
    ok: segment.status == ToolSegmentStatus.ok,
  );

  /// The tool's name as the backend reported it (`write`, `Edit`,
  /// `mcp__control-center__create_ticket`).
  final String name;

  /// The call's arguments.
  final Map<String, dynamic> arguments;

  /// Whether the call succeeded.
  final bool ok;
}

/// What each run of the server called, kept from the moment its stream ends
/// until the goal supervisor reads it when the run settles: the top-level
/// run's transcript is owned by its message, not by its run, so this is
/// where a settled run's tool calls can be read by run id. In memory and
/// bounded ([capacity] runs, the oldest dropped first): a server restart
/// between a run's end and its settlement loses its record, and the
/// supervisor then judges progress from the worktree and the checklist.
class RunToolActivity {
  /// Creates an empty record.
  RunToolActivity({this.capacity = 256});

  /// The most runs remembered at once.
  final int capacity;

  /// The most calls kept for one run.
  static const int maxCallsPerRun = 5000;

  final LinkedHashMap<String, List<RunToolCall>> _runs = LinkedHashMap();

  /// Records [calls] for run [runId] of [workspaceId] (replacing what was
  /// recorded for it).
  void record({
    required String workspaceId,
    required String runId,
    required List<RunToolCall> calls,
  }) {
    final key = _key(workspaceId, runId);
    _runs.remove(key);
    _runs[key] = List.unmodifiable(
      calls.length > maxCallsPerRun ? calls.sublist(0, maxCallsPerRun) : calls,
    );
    while (_runs.length > capacity) {
      _runs.remove(_runs.keys.first);
    }
  }

  /// Records the tool segments of a finished run's transcript.
  void recordSegments({
    required String workspaceId,
    required String runId,
    required Iterable<TranscriptSegment> segments,
  }) => record(
    workspaceId: workspaceId,
    runId: runId,
    calls: [
      for (final segment in segments.whereType<ToolSegment>())
        RunToolCall.fromSegment(segment),
    ],
  );

  /// The calls of run [runId], removed from the record; null when nothing
  /// was recorded for it.
  List<RunToolCall>? take({
    required String workspaceId,
    required String runId,
  }) => _runs.remove(_key(workspaceId, runId));

  static String _key(String workspaceId, String runId) =>
      '$workspaceId\u0000$runId';
}

/// The action classes that change nothing: reading the network, reading a
/// secret. Every other class changes state.
const Set<ActionClass> readOnlyActionClasses = {
  ActionClass.networkEgress,
  ActionClass.secretAccess,
};

/// The effect classes of the built-in harness tools and of Claude Code's own
/// tools, for a run whose tool names are all a transcript keeps. The harness
/// rows follow each tool's declared `actionClasses` (pinned by
/// `test/core/action_class_coverage_test.dart`), with one exception: `repl`
/// declares none because its nested calls are gated one by one, but a
/// script is how the harness edits and runs things, so it counts as a
/// change. A tool not named here and not known to the MCP registry changes
/// nothing (the worktree fingerprint still sees what it did).
const Map<String, Set<ActionClass>> builtinToolEffects = {
  // The built-in harness.
  'write': {ActionClass.fileWriteOutsideWorktree},
  'edit': {ActionClass.fileWriteOutsideWorktree},
  'apply_patch': {ActionClass.fileWriteOutsideWorktree, ActionClass.fileDelete},
  'ast_edit': {ActionClass.fileWriteOutsideWorktree},
  'lsp_rename': {ActionClass.fileWriteOutsideWorktree},
  'resolve': {ActionClass.fileWriteOutsideWorktree},
  'bash': {ActionClass.processSpawn},
  'bash_kill': {ActionClass.processSpawn},
  'repl': {ActionClass.processSpawn},
  'web_fetch': {ActionClass.networkEgress},
  'web_search': {ActionClass.networkEgress},
  // Claude Code's own tools.
  'Write': {ActionClass.fileWriteOutsideWorktree},
  'Edit': {ActionClass.fileWriteOutsideWorktree},
  'MultiEdit': {ActionClass.fileWriteOutsideWorktree},
  'NotebookEdit': {ActionClass.fileWriteOutsideWorktree},
  'Bash': {ActionClass.processSpawn},
  'KillShell': {ActionClass.processSpawn},
  'WebFetch': {ActionClass.networkEgress},
  'WebSearch': {ActionClass.networkEgress},
};

/// [name] without the `mcp__<server>__` prefix Claude Code and ACP agents
/// put in front of an MCP tool's name.
String bareToolName(String name) {
  if (!name.startsWith('mcp__')) {
    return name;
  }
  final rest = name.substring('mcp__'.length);
  final cut = rest.indexOf('__');
  return cut < 0 ? name : rest.substring(cut + 2);
}

/// Whether a call to [name] can change state: its classes, from
/// [builtinToolEffects] or else [mcpClassesOf] (the MCP registry's
/// declaration; null when it does not know the tool), include one that is
/// not read-only.
bool toolChangesState(
  String name, {
  required Set<ActionClass>? Function(String bareName) mcpClassesOf,
}) {
  final classes = builtinToolEffects[name] ?? mcpClassesOf(bareToolName(name));
  if (classes == null) {
    return false;
  }
  return classes.any((c) => !readOnlyActionClasses.contains(c));
}

/// What a segment's tool calls say about progress (plan section 8, as
/// amended by A2).
class SegmentActivity {
  /// Creates the summary.
  const SegmentActivity({
    required this.anyCall,
    required this.anySucceededChange,
    required this.digest,
  });

  /// Reads [calls]: [anyCall] when there was at least one, [digest] over the
  /// state-changing ones, [anySucceededChange] when one of those succeeded.
  factory SegmentActivity.of(
    List<RunToolCall> calls, {
    required Set<ActionClass>? Function(String bareName) mcpClassesOf,
  }) {
    final changing = [
      for (final call in calls)
        if (toolChangesState(call.name, mcpClassesOf: mcpClassesOf)) call,
    ];
    return SegmentActivity(
      anyCall: calls.isNotEmpty,
      anySucceededChange: changing.any((call) => call.ok),
      digest: changing.isEmpty ? null : activityDigest(changing),
    );
  }

  /// The segment made at least one tool call of any kind.
  final bool anyCall;

  /// At least one state-changing call succeeded.
  final bool anySucceededChange;

  /// [activityDigest] of the state-changing calls; null when there were none.
  final String? digest;

  /// Whether the calls are progress against [previousDigest] (the last
  /// segment's `lastActivityDigest`): a state-changing call succeeded and
  /// the set of such calls is not the one the last segment made.
  bool progressAgainst(String? previousDigest) =>
      anySucceededChange && digest != null && digest != previousDigest;
}

/// SHA-256 (hex) over the ordered list of (tool name, canonical JSON of its
/// arguments, success) of [calls]: two segments that make the same calls
/// with the same results have the same digest.
String activityDigest(List<RunToolCall> calls) => canonicalHash([
  for (final call in calls) [call.name, call.arguments, call.ok],
]);
