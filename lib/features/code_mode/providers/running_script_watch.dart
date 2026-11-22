import 'dart:async';

import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:control_center/features/agents/providers/run_activity_providers.dart';
import 'package:control_center/shared/widgets/transcript/util/nested_calls.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How far a running script has got, as its run's live transcript shows it:
/// whether its row has finished, and how many of its calls have settled.
typedef ScriptProgress = ({bool finished, int settledCalls});

/// The progress of the newest `repl` row whose call id is [toolCallId] in
/// [segments], or null when no such row is there.
///
/// The newest, because ids repeat across turns and a run runs one script at
/// a time, so the script still running is the latest row with its id. Its
/// calls are the ones the transcript folds under that row.
ScriptProgress? scriptProgressOf(
  List<TranscriptSegment> segments,
  String toolCallId,
) {
  final row = segments.lastIndexWhere(
    (s) =>
        s is ToolSegment &&
        s.toolCallId == toolCallId &&
        isReplTool(s.toolName),
  );
  if (row < 0) {
    return null;
  }
  final script = segments[row] as ToolSegment;
  final calls = foldNestedCalls(segments)[row] ?? const <int>[];
  var settled = 0;
  for (final i in calls) {
    if (segments[i] case final ToolSegment call
        when call.status != ToolSegmentStatus.running) {
      settled++;
    }
  }
  return (
    finished: script.status != ToolSegmentStatus.running,
    settledCalls: settled,
  );
}

/// The shortest gap between two refreshes a running script's page asks for.
const Duration runningScriptRefreshGap = Duration(seconds: 2);

/// Calls [onProgress] when the running script [toolCallId] of [runId] moves
/// on: a call of it settles, or it finishes.
///
/// A record has no live feed of its own; its run's transcript does (the same
/// relay a run's activity page watches), so the page follows that and reads
/// the record again only when the script's row changes, never on a timer
/// while nothing happens. Changes that arrive together are read once, at most
/// every [runningScriptRefreshGap]. A row already finished when the watch
/// starts counts as a change, since the record was read before it ended.
///
/// The watch lives as long as [ref]; the caller drops it by rebuilding once
/// the record is no longer running.
void watchRunningScript(
  Ref ref, {
  required String workspaceId,
  required String runId,
  required String toolCallId,
  required void Function() onProgress,
}) {
  ScriptProgress? seen;
  var first = true;
  Timer? pending;
  ref.onDispose(() => pending?.cancel());
  ref.listen(runTranscriptProvider((workspaceId: workspaceId, runId: runId)), (
    _,
    next,
  ) {
    final segments = next.value;
    if (segments == null) {
      return;
    }
    final progress = scriptProgressOf(segments, toolCallId);
    final changed = first
        ? progress?.finished ?? false
        : progress != null && progress != seen;
    first = false;
    seen = progress;
    if (!changed || pending != null) {
      return;
    }
    pending = Timer(runningScriptRefreshGap, () {
      pending = null;
      onProgress();
    });
  }, fireImmediately: true);
}
