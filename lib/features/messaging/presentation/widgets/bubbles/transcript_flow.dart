import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/services/tool_display_name.dart';
import 'package:cc_domain/core/domain/services/transcript_status.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/live_transcript_controller.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/question_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/steering_bubble.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/transcript_plan.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/transcript_segment_row.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/turn_auth_failure_notice.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/turn_sandbox_unavailable_notice.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/markdown_image.dart';
import 'package:control_center/shared/widgets/markdown/markdown_links.dart';
import 'package:control_center/shared/widgets/markdown/markdown_registries.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/widgets.dart';

part 'transcript_flow_prose.dart';
part 'transcript_flow_reasoning.dart';
part 'transcript_flow_status.dart';

/// Agent turn as chronological inline flow (reasoning, tools, answer).
///
/// Persisted ordered segments; tools as [TranscriptSegmentRow]. The rows come
/// from [planTranscriptRows] and are built by a [TranscriptRowRenderer], the
/// same pair the conversation feed uses when it gives each row its own list
/// slot. Parent rebuilds only on structure changes: closed rows memoized +
/// [RepaintBoundary]; open rows listen to [LiveTranscriptController.tail]
/// only. No master collapse.
class TranscriptFlow extends StatefulWidget {
  /// Creates a [TranscriptFlow].
  const TranscriptFlow({
    super.key,
    required this.segments,
    required this.codeFont,
    this.isLive = false,
    this.live,
    this.inlineMessages = const [],
  });

  /// The full transcript in chronological order (text segments included).
  ///
  /// While live this is the registry snapshot at the last structural change;
  /// open rows re-read their fresher state through [live].
  final List<TranscriptSegment> segments;

  /// Mono font for rich code/diff/terminal bodies.
  final String codeFont;

  /// Whether the agent is still emitting segments.
  final bool isLive;

  /// Delta-cadence pulse + segment reader for open rows. Null on persisted
  /// (non-live) transcripts.
  final LiveTranscriptController? live;

  /// Steering and resolved questions in chronological transcript order.
  final List<Message> inlineMessages;

  @override
  State<TranscriptFlow> createState() => _TranscriptFlowState();
}

class _TranscriptFlowState extends State<TranscriptFlow> {
  final TranscriptRowRenderer _rows = TranscriptRowRenderer();

  @override
  Widget build(BuildContext context) {
    final segments = widget.segments;
    _rows.prepare(
      codeFont: widget.codeFont,
      isLive: widget.isLive,
      segmentCount: segments.length,
    );
    final plan = planTranscriptRows(
      segments: segments,
      inlineMessages: widget.inlineMessages,
      isLive: widget.isLive,
    );
    if (plan.isEmpty) {
      return const SizedBox.shrink();
    }
    final children = <Widget>[];
    for (final row in plan) {
      if (children.isNotEmpty) {
        children.add(SizedBox(height: row.gapBefore));
      }
      children.add(
        _rows.build(
          row,
          segments: segments,
          codeFont: widget.codeFont,
          live: widget.live,
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }
}

/// Builds the rows of one transcript, keeping the per-row state that makes a
/// long or live transcript cheap to rebuild.
///
/// * Closed rows are memoized by index: a value-equal segment hands back the
///   identical widget, so `Element.update` skips its subtree.
/// * Open rows listen to [LiveTranscriptController.tail] and re-read only their
///   own segment per delta.
/// * Prose and reasoning rows carry a [GlobalKey] per index once the turn has
///   been live, so a row that closes keeps its element (and the streaming
///   renderer's sealed-block memo) instead of re-parsing the whole answer in
///   one frame.
///
/// One instance per transcript, owned by whatever renders it: a
/// [TranscriptFlow], or the conversation feed for a turn it lays out row by
/// row.
class TranscriptRowRenderer {
  final Map<int, (TranscriptSegment, Widget)> _memo = {};
  String? _memoFont;
  final Map<int, GlobalKey> _proseKeys = {};
  final Map<int, GlobalKey> _reasoningKeys = {};
  bool _everLive = false;

  /// Call before building the rows of a pass: drops memo entries a font
  /// change or a shrunk transcript (revert/re-seed) made stale.
  void prepare({
    required String codeFont,
    required bool isLive,
    required int segmentCount,
  }) {
    if (_memoFont != codeFont) {
      _memo.clear();
      _memoFont = codeFont;
    }
    _everLive = _everLive || isLive;
    _memo.removeWhere((i, _) => i >= segmentCount);
    _proseKeys.removeWhere((i, _) => i >= segmentCount);
    _reasoningKeys.removeWhere((i, _) => i >= segmentCount);
  }

  /// The widget for [row]. [segments] is the transcript the plan was made
  /// from (the live status line reads it).
  Widget build(
    TranscriptRowPlan row, {
    required List<TranscriptSegment> segments,
    required String codeFont,
    LiveTranscriptController? live,
  }) => switch (row) {
    SegmentRowPlan() =>
      _segmentRow(row, codeFont: codeFont, live: live) ??
          const SizedBox.shrink(),
    InlineMessageRowPlan(:final message) =>
      message.isUserQuestion
          ? QuestionBubble(key: ValueKey(message.id), message: message)
          : SteeringBubble(
              key: ValueKey(message.id),
              message: message,
              codeFont: codeFont,
            ),
    LiveStatusRowPlan() => _LiveStatusLine(segments: segments),
  };

  /// One transcript row: memoized when closed, delta-live when open.
  Widget? _segmentRow(
    SegmentRowPlan plan, {
    required String codeFont,
    LiveTranscriptController? live,
  }) {
    final index = plan.index;
    final seg = plan.segment;
    if (plan.open) {
      _memo.remove(index);
      if (live == null) {
        return _renderSegment(index, seg, codeFont: codeFont, open: true);
      }
      // The open row re-reads its own segment per delta pulse; the registry
      // materializes only that index and Flutter coalesces pulses into one
      // rebuild per frame.
      // The OPEN row is the one row that repaints per delta, and it was the
      // one row without a boundary — so each delta re-rasterized the nearest
      // ancestor one, i.e. the whole viewport including every closed row that
      // is memoized precisely so it does not have to rebuild.
      return RepaintBoundary(
        child: ValueListenableBuilder<int>(
          valueListenable: live.tail,
          builder: (context, _, _) {
            final current = live.segmentAt(index) ?? seg;
            return _renderSegment(
                  index,
                  current,
                  codeFont: codeFont,
                  open: true,
                ) ??
                const SizedBox.shrink();
          },
        ),
      );
    }

    final memoed = _memo[index];
    if (memoed != null && memoed.$1 == seg) {
      return memoed.$2;
    }
    final rendered = _renderSegment(
      index,
      seg,
      codeFont: codeFont,
      open: false,
    );
    if (rendered == null) {
      _memo.remove(index);
      return null;
    }
    final row = RepaintBoundary(child: rendered);
    _memo[index] = (seg, row);
    return row;
  }

  Widget? _renderSegment(
    int index,
    TranscriptSegment seg, {
    required String codeFont,
    required bool open,
  }) {
    switch (seg) {
      case TextSegment(:final text):
        final key = _everLive
            ? _proseKeys.putIfAbsent(index, GlobalKey.new)
            : null;
        if (open) {
          // Streaming answer prose: fence-safe prefix/tail split so a delta
          // never re-parses the whole accumulated text (see
          // `CcStreamingMarkdown`).
          return TurnProse(
            key: key,
            content: text,
            codeFont: codeFont,
            streaming: true,
          );
        }
        if (text.trim().isEmpty) {
          return null;
        }
        return TurnProse(key: key, content: text, codeFont: codeFont);
      case ReasoningSegment(:final text):
        if (!open && text.trim().isEmpty) {
          return null;
        }
        return _ReasoningBlock(
          key: _everLive
              ? _reasoningKeys.putIfAbsent(index, GlobalKey.new)
              : null,
          segment: seg,
          codeFont: codeFont,
          streaming: open,
        );
      case ErrorSegment(isAuthentication: true):
        return TurnAuthFailureNotice(segment: seg);
      case ErrorSegment(isSandboxUnavailable: true):
        return const TurnSandboxUnavailableNotice();
      case ToolSegment():
      case ErrorSegment():
      case ViolationSegment():
        return TranscriptSegmentRow(
          segment: seg,
          codeFont: codeFont,
          pending:
              open &&
              seg is ToolSegment &&
              seg.status == ToolSegmentStatus.running,
        );
    }
  }
}
