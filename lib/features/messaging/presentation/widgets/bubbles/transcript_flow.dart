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
import 'package:control_center/features/messaging/presentation/widgets/bubbles/transcript_segment_row.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/markdown_image.dart';
import 'package:control_center/shared/widgets/markdown/markdown_registries.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:flutter/widgets.dart';

part 'transcript_flow_prose.dart';
part 'transcript_flow_reasoning.dart';
part 'transcript_flow_status.dart';

/// Agent turn as chronological inline flow (reasoning, tools, answer).
///
/// Persisted ordered segments; tools as [TranscriptSegmentRow]. Parent rebuilds
/// only on structure changes: closed rows memoized + [RepaintBoundary]; open
/// rows listen to [LiveTranscriptController.tail] only. No master collapse.
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
  /// Closed-row widget memo: index → (segment it was built from, row widget).
  /// Reusing the identical instance for a value-equal segment lets
  /// `Element.update` skip the row's subtree entirely.
  final Map<int, (TranscriptSegment, Widget)> _memo = {};
  String? _memoFont;

  /// Per-index keys for the prose and reasoning rows. A row that closes moves
  /// from under its delta listener to the plain closed slot; the key carries
  /// its element (and the streaming renderer's sealed-block memo) along, so
  /// closing finalizes the text in place instead of re-parsing and relaying
  /// out the whole answer in one frame. Separate maps per row type: a key is
  /// only ever attached to one widget type. Only allocated once this flow has
  /// been live: a persisted transcript never closes a row.
  final Map<int, GlobalKey> _proseKeys = {};
  final Map<int, GlobalKey> _reasoningKeys = {};
  bool _everLive = false;

  @override
  Widget build(BuildContext context) {
    if (_memoFont != widget.codeFont) {
      _memo.clear();
      _memoFont = widget.codeFont;
    }
    _everLive = _everLive || widget.isLive;
    final segments = widget.segments;
    // A revert/re-seed can shrink the list; drop stale trailing entries.
    _memo.removeWhere((i, _) => i >= segments.length);
    _proseKeys.removeWhere((i, _) => i >= segments.length);
    _reasoningKeys.removeWhere((i, _) => i >= segments.length);

    final children = <Widget>[];
    TranscriptSegment? prev;
    final inlineMessages = widget.inlineMessages;
    var nextInline = 0;
    void insertMessage(Message message) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: AppSpacing.md));
      }
      children.add(
        message.isUserQuestion
            ? QuestionBubble(key: ValueKey(message.id), message: message)
            : SteeringBubble(
                key: ValueKey(message.id),
                message: message,
                codeFont: widget.codeFont,
              ),
      );
      prev = null;
    }

    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      while (nextInline < inlineMessages.length &&
          (inlineMessages[nextInline].steerInjectedAt ??
                  inlineMessages[nextInline]
                      .createdAt
                      .millisecondsSinceEpoch) <=
              seg.startedAt.millisecondsSinceEpoch) {
        insertMessage(inlineMessages[nextInline++]);
      }
      final rendered = _row(i, seg);
      if (rendered == null) {
        continue;
      }
      if (children.isNotEmpty) {
        children.add(
          SizedBox(
            height: prev == null ? AppSpacing.md : _gapBefore(prev, seg),
          ),
        );
      }
      children.add(rendered);
      prev = seg;
    }
    while (nextInline < inlineMessages.length) {
      insertMessage(inlineMessages[nextInline++]);
    }

    if (widget.isLive && _showTail(segments)) {
      if (children.isNotEmpty) {
        children.add(const SizedBox(height: AppSpacing.sm));
      }
      children.add(_LiveStatusLine(segments: segments));
    }

    if (children.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: children,
    );
  }

  /// One transcript row: memoized when closed, delta-live when open.
  Widget? _row(int index, TranscriptSegment seg) {
    final live = widget.live;
    if (widget.isLive && _isOpen(seg)) {
      _memo.remove(index);
      if (live == null) {
        return _renderSegment(index, seg, open: true);
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
            return _renderSegment(index, current, open: true) ??
                const SizedBox.shrink();
          },
        ),
      );
    }

    final memoed = _memo[index];
    if (memoed != null && memoed.$1 == seg) {
      return memoed.$2;
    }
    final rendered = _renderSegment(index, seg, open: false);
    if (rendered == null) {
      _memo.remove(index);
      return null;
    }
    final row = RepaintBoundary(child: rendered);
    _memo[index] = (seg, row);
    return row;
  }

  /// Whether a segment is still receiving content while the turn is live.
  static bool _isOpen(TranscriptSegment seg) => switch (seg) {
    TextSegment(:final durationMs) => durationMs == null,
    ReasoningSegment(:final durationMs) => durationMs == null,
    ToolSegment(:final status) => status == ToolSegmentStatus.running,
    ErrorSegment() || ViolationSegment() => false,
  };

  Widget? _renderSegment(
    int index,
    TranscriptSegment seg, {
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
            codeFont: widget.codeFont,
            streaming: true,
          );
        }
        if (text.trim().isEmpty) {
          return null;
        }
        return TurnProse(key: key, content: text, codeFont: widget.codeFont);
      case ReasoningSegment(:final text):
        if (!open && text.trim().isEmpty) {
          return null;
        }
        return _ReasoningBlock(
          key: _everLive
              ? _reasoningKeys.putIfAbsent(index, GlobalKey.new)
              : null,
          segment: seg,
          codeFont: widget.codeFont,
          streaming: open,
        );
      case ToolSegment():
      case ErrorSegment():
      case ViolationSegment():
        return TranscriptSegmentRow(
          segment: seg,
          codeFont: widget.codeFont,
          pending:
              open &&
              seg is ToolSegment &&
              seg.status == ToolSegmentStatus.running,
        );
    }
  }

  /// Vertical rhythm: prose breathes, consecutive tool rows stack tightly.
  static double _gapBefore(TranscriptSegment? prev, TranscriptSegment cur) {
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
  static bool _showTail(List<TranscriptSegment> segments) {
    if (segments.isEmpty) {
      return true;
    }
    return switch (segments.last) {
      TextSegment(:final durationMs) => durationMs != null,
      ReasoningSegment(:final durationMs) => durationMs != null,
      _ => true,
    };
  }
}
