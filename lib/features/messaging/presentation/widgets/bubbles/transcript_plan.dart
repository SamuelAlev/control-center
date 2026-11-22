import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/transcript/util/nested_calls.dart';

/// One row of an agent turn's transcript, in display order.
///
/// The plan is what a transcript renders, decided once: which segments draw a
/// row, where steering and answered questions slot in, the vertical gap above
/// each row and whether the turn-level "still working" line closes it. Both
/// renderers consume it — `TranscriptFlow` stacks the rows in a column, and the
/// conversation feed gives each row its own list slot so a long turn is laid
/// out only as far as the screen reaches.
sealed class TranscriptRowPlan {
  const TranscriptRowPlan({required this.gapBefore});

  /// Vertical space above the row (0 for the first row).
  final double gapBefore;

  /// Stable identity of the row inside its turn.
  String get id;
}

/// A transcript segment's row.
final class SegmentRowPlan extends TranscriptRowPlan {
  /// Creates the row for the segment at [index].
  const SegmentRowPlan({
    required this.index,
    required this.segment,
    required this.open,
    required super.gapBefore,
    this.children = const [],
  });

  /// Index of the segment in the transcript.
  final int index;

  /// Indices of the calls a script made from this call, in the order it made
  /// them. They render inside this row, never as rows of their own.
  final List<int> children;

  /// The segment as of the plan (a live open row re-reads fresher state).
  final TranscriptSegment segment;

  /// Whether the segment is still receiving content in a live turn.
  final bool open;

  @override
  String get id => 's$index';
}

/// A steering message or answered question, at its point in the run.
final class InlineMessageRowPlan extends TranscriptRowPlan {
  /// Creates the row for [message].
  const InlineMessageRowPlan({required this.message, required super.gapBefore});

  /// The steering message or answered question.
  final Message message;

  @override
  String get id => 'q${message.id}';
}

/// The live turn's "still working" status line.
final class LiveStatusRowPlan extends TranscriptRowPlan {
  /// Creates the status-line row.
  const LiveStatusRowPlan({required super.gapBefore});

  @override
  String get id => 'live';
}

/// Plans the rows of a transcript: [segments] in order with [inlineMessages]
/// interleaved by time, empty closed prose dropped, and the live status line
/// appended while [isLive] and no prose is streaming.
///
/// A call a script made folds into the row of the call that ran the script
/// (see [foldNestedCalls]); one whose parent is not in [segments] keeps a row
/// of its own.
List<TranscriptRowPlan> planTranscriptRows({
  required List<TranscriptSegment> segments,
  required List<Message> inlineMessages,
  required bool isLive,
}) {
  final nested = foldNestedCalls(segments);
  final folded = {for (final children in nested.values) ...children};
  final out = <TranscriptRowPlan>[];
  TranscriptSegment? prev;
  var afterInline = false;
  var nextInline = 0;

  void addInline(Message message) {
    out.add(
      InlineMessageRowPlan(
        message: message,
        gapBefore: out.isEmpty ? 0 : AppSpacing.md,
      ),
    );
    prev = null;
    afterInline = true;
  }

  for (var i = 0; i < segments.length; i++) {
    if (folded.contains(i)) {
      continue;
    }
    final seg = segments[i];
    while (nextInline < inlineMessages.length &&
        _inlineAt(inlineMessages[nextInline]) <=
            seg.startedAt.millisecondsSinceEpoch) {
      addInline(inlineMessages[nextInline++]);
    }
    final open = isLive && isSegmentOpen(seg);
    if (!open && !_rendersClosed(seg)) {
      continue;
    }
    final double gap;
    if (out.isEmpty) {
      gap = 0;
    } else if (afterInline || prev == null) {
      gap = AppSpacing.md;
    } else {
      gap = transcriptGapBefore(prev!, seg);
    }
    out.add(
      SegmentRowPlan(
        index: i,
        segment: seg,
        open: open,
        gapBefore: gap,
        children: nested[i] ?? const [],
      ),
    );
    prev = seg;
    afterInline = false;
  }
  while (nextInline < inlineMessages.length) {
    addInline(inlineMessages[nextInline++]);
  }
  if (isLive && _showLiveTail(segments)) {
    out.add(LiveStatusRowPlan(gapBefore: out.isEmpty ? 0 : AppSpacing.sm));
  }
  return out;
}

int _inlineAt(Message message) =>
    message.steerInjectedAt ?? message.createdAt.millisecondsSinceEpoch;

/// Whether a closed segment draws anything: blank prose and blank reasoning
/// do not.
bool _rendersClosed(TranscriptSegment seg) => switch (seg) {
  TextSegment(:final text) => text.trim().isNotEmpty,
  ReasoningSegment(:final text) => text.trim().isNotEmpty,
  ToolSegment() || ErrorSegment() || ViolationSegment() => true,
};

/// Whether a segment is still receiving content while the turn is live.
bool isSegmentOpen(TranscriptSegment seg) => switch (seg) {
  TextSegment(:final durationMs) => durationMs == null,
  ReasoningSegment(:final durationMs) => durationMs == null,
  ToolSegment(:final status) => status == ToolSegmentStatus.running,
  ErrorSegment() || ViolationSegment() => false,
};

/// Vertical rhythm: prose breathes, consecutive tool rows stack tightly.
double transcriptGapBefore(TranscriptSegment prev, TranscriptSegment cur) {
  if (prev is TextSegment || cur is TextSegment) {
    return AppSpacing.md;
  }
  if (prev is ReasoningSegment || cur is ReasoningSegment) {
    return AppSpacing.sm;
  }
  return AppSpacing.xs;
}

/// The tail is the turn-level "still working" pulse. Suppress it only while
/// the answer or a thought is itself streaming — a status line under
/// live-rendering prose would just echo what the user already sees. Show it
/// while a tool runs (the tail names the activity class, the row names the
/// target) and between steps (where it reports the thinking gap).
bool _showLiveTail(List<TranscriptSegment> segments) {
  if (segments.isEmpty) {
    return true;
  }
  return switch (segments.last) {
    TextSegment(:final durationMs) => durationMs != null,
    ReasoningSegment(:final durationMs) => durationMs != null,
    _ => true,
  };
}
