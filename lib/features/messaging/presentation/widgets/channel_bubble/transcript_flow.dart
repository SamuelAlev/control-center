import 'package:cc_domain/core/domain/services/transcript_status.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/live_transcript_controller.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/transcript_segment_row.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/markdown_registries.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:control_center/shared/widgets/transcript/tool_presentation.dart';
import 'package:control_center/shared/widgets/transcript/widgets/shimmer_text.dart';
import 'package:flutter/material.dart';

/// Renders an agent turn as one **continuous, inline flow** — the reasoning,
/// tool calls, and answer text in the exact chronological order they were
/// emitted, rather than collapsing the "process" behind a single
/// "Thought for Ns · N tool calls" accordion and printing the answer separately
/// at the end.
///
/// This is the conductor.build reading model: prose, then the tool calls it
/// triggered shown inline where they happened, then more prose. Reasoning is
/// shown inline (dimmed, expanded by default) instead of hidden — it is part of
/// the story, not a footnote. Tool calls render as compact, expandable rows
/// (reusing [TranscriptSegmentRow]). The transcript's full ordered segment list
/// (text segments included) is persisted on the message, so this faithfully
/// reconstructs the turn both live and on reload.
///
/// ## Rebuild isolation
///
/// The parent rebuilds this widget only on **structural** changes (segment
/// open/close/finish — via `LiveTranscriptController.structure`). Within a
/// build:
///
///   * **closed** rows are memoized by value-equal segment: the identical
///     widget instance is returned across builds so `Element.update` skips
///     their whole subtree, and each sits under its own [RepaintBoundary];
///   * **open** rows (still streaming) sit under a `ValueListenableBuilder`
///     on [LiveTranscriptController.tail], re-reading just their own segment
///     per delta — a delta costs one small row rebuild, not a turn rebuild.
///
/// No master collapse/expand state and no auto-collapse timer — everything is
/// always visible, which is the whole point.
class TranscriptFlow extends StatefulWidget {
  /// Creates a [TranscriptFlow].
  const TranscriptFlow({
    super.key,
    required this.segments,
    required this.codeFont,
    this.isLive = false,
    this.live,
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

  @override
  State<TranscriptFlow> createState() => _TranscriptFlowState();
}

class _TranscriptFlowState extends State<TranscriptFlow> {
  /// Closed-row widget memo: index → (segment it was built from, row widget).
  /// Reusing the identical instance for a value-equal segment lets
  /// `Element.update` skip the row's subtree entirely.
  final Map<int, (TranscriptSegment, Widget)> _memo = {};
  String? _memoFont;

  @override
  Widget build(BuildContext context) {
    if (_memoFont != widget.codeFont) {
      _memo.clear();
      _memoFont = widget.codeFont;
    }
    final segments = widget.segments;
    // A revert/re-seed can shrink the list; drop stale trailing entries.
    _memo.removeWhere((i, _) => i >= segments.length);

    final children = <Widget>[];
    TranscriptSegment? prev;
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final rendered = _row(i, seg);
      if (rendered == null) {
        continue;
      }
      if (children.isNotEmpty) {
        children.add(SizedBox(height: _gapBefore(prev, seg)));
      }
      children.add(rendered);
      prev = seg;
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
        return _renderSegment(seg, open: true);
      }
      // The open row re-reads its own segment per delta pulse; the registry
      // materializes only that index, and Flutter coalesces pulses into one
      // rebuild per frame.
      return ValueListenableBuilder<int>(
        valueListenable: live.tail,
        builder: (context, _, _) {
          final current = live.segmentAt(index) ?? seg;
          return _renderSegment(current, open: true) ?? const SizedBox.shrink();
        },
      );
    }

    final memoed = _memo[index];
    if (memoed != null && memoed.$1 == seg) {
      return memoed.$2;
    }
    final rendered = _renderSegment(seg, open: false);
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

  Widget? _renderSegment(TranscriptSegment seg, {required bool open}) {
    switch (seg) {
      case TextSegment(:final text):
        if (open) {
          // Streaming answer prose: fence-safe prefix/tail split so a delta
          // never re-parses the whole accumulated text (see
          // `CcStreamingMarkdown`).
          return TurnProse(
            content: text,
            codeFont: widget.codeFont,
            streaming: true,
          );
        }
        if (text.trim().isEmpty) {
          return null;
        }
        return TurnProse(content: text, codeFont: widget.codeFont);
      case ReasoningSegment(:final text):
        if (!open && text.trim().isEmpty) {
          return null;
        }
        return _ReasoningBlock(
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

/// Visible answer text (a [TextSegment], or a whole message's content when it
/// carries no transcript) rendered as markdown. Identical to the old bubble
/// body minus the trailing timestamp — the turn shows a single timestamp on its
/// trailer line, not one after every prose block.
class TurnProse extends StatelessWidget {
  /// Creates a [TurnProse].
  const TurnProse({
    super.key,
    required this.content,
    required this.codeFont,
    this.streaming = false,
  });

  /// The markdown content.
  final String content;

  /// Font family for code blocks.
  final String codeFont;

  /// Whether [content] is still growing (a live answer). Renders through
  /// [CcStreamingMarkdown] so per-delta builds re-parse only the volatile
  /// tail block and never pollute the parse cache with intermediates.
  final bool streaming;

  @override
  Widget build(BuildContext context) {
    final style = appMarkdownStyle(context, codeFontFamily: codeFont);
    Widget codeBuilder(String code, String? language, {required bool cache}) =>
        buildSharedCodeBlock(
          context,
          code,
          language,
          codeFontFamily: codeFont,
          cache: cache,
        );
    if (streaming) {
      return CcStreamingMarkdown.value(
        data: content,
        selectable: true,
        style: style,
        plugins: chatMarkdownPlugins,
        options: chatMarkdownOptions,
        builders: chatMarkdownBuilders,
        codeBuilder: codeBuilder,
      );
    }
    return CcMarkdown(
      data: content,
      selectable: true,
      style: style,
      plugins: chatMarkdownPlugins,
      options: chatMarkdownOptions,
      builders: chatMarkdownBuilders,
      codeBuilder: codeBuilder,
    );
  }
}

/// An inline reasoning ("extended thinking") span: a quiet brain-iconed eyebrow
/// over dimmed markdown prose, set off by a faint left rail. Expanded by default
/// (reasoning is part of the flow, not hidden) with a collapse affordance for
/// long thoughts; force-expanded while the span is still streaming so the user
/// watches it think.
class _ReasoningBlock extends StatefulWidget {
  const _ReasoningBlock({
    required this.segment,
    required this.codeFont,
    required this.streaming,
  });

  final ReasoningSegment segment;
  final String codeFont;
  final bool streaming;

  @override
  State<_ReasoningBlock> createState() => _ReasoningBlockState();
}

class _ReasoningBlockState extends State<_ReasoningBlock> {
  bool? _userExpanded;

  bool get _expanded => widget.streaming || (_userExpanded ?? true);

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final l10n = AppLocalizations.of(context);
    final expanded = _expanded;

    final labelStyle = AppFonts.codeDynamic(
      widget.codeFont,
      textStyle: CcTypography.caption.copyWith(
        color: tokens.textTertiary,
        fontWeight: FontWeight.w500,
      ),
    );

    final durationMs = widget.segment.durationMs;
    final label = widget.streaming
        ? l10n.transcriptThinking
        : (durationMs != null && durationMs > 0
              ? l10n.transcriptThoughtFor(_formatDuration(durationMs))
              : l10n.transcriptThinking);

    // Reasoning is meaningful, readable content — keep it AAA-legible
    // (textSecondary ≈ muted), a touch lighter than the answer (textPrimary)
    // so it recedes, with the eyebrow + left rail carrying the distinction.
    final base = appMarkdownStyle(
      context,
      codeFontFamily: widget.codeFont,
      compact: true,
    );
    final muted = base.copyWith(
      paragraph: base.paragraph?.copyWith(color: tokens.textSecondary),
    );

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: tokens.borderSecondary, width: 2),
        ),
      ),
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // While streaming, the block is force-expanded and the eyebrow is a
          // static label (no collapse affordance that wouldn't do anything).
          if (widget.streaming)
            _eyebrow(
              labelStyle,
              label,
              tokens,
              showChevron: false,
              expanded: expanded,
            )
          else
            CcTappable(
              onPressed: () => setState(() => _userExpanded = !expanded),
              builder: (context, states) => _eyebrow(
                labelStyle,
                label,
                tokens,
                showChevron: true,
                expanded: expanded,
              ),
            ),
          if (expanded)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: widget.streaming
                  ? CcStreamingMarkdown.value(
                      data: widget.segment.text,
                      selectable: true,
                      style: muted,
                      plugins: chatMarkdownPlugins,
                      options: chatMarkdownOptions,
                      builders: chatMarkdownBuilders,
                      codeBuilder: (code, language, {required bool cache}) =>
                          buildSharedCodeBlock(
                            context,
                            code,
                            language,
                            cache: cache,
                          ),
                    )
                  : CcMarkdown(
                      data: widget.segment.text,
                      selectable: true,
                      style: muted,
                      plugins: chatMarkdownPlugins,
                      options: chatMarkdownOptions,
                      builders: chatMarkdownBuilders,
                      codeBuilder: (code, language, {required bool cache}) =>
                          buildSharedCodeBlock(
                            context,
                            code,
                            language,
                            cache: cache,
                          ),
                    ),
            ),
        ],
      ),
    );
  }

  /// The reasoning header: a brain icon, the "Thinking…" / "Thought for N"
  /// label, and (when interactive) a collapse chevron.
  Widget _eyebrow(
    TextStyle? labelStyle,
    String label,
    DesignSystemTokens tokens, {
    required bool showChevron,
    required bool expanded,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(AppIcons.brain, size: 13, color: tokens.textTertiary),
          const SizedBox(width: 6),
          Flexible(
            child: widget.streaming
                ? ShimmerText(label, style: labelStyle)
                : Text(
                    label,
                    style: labelStyle,
                    overflow: TextOverflow.ellipsis,
                  ),
          ),
          if (showChevron) ...[
            const SizedBox(width: 6),
            Icon(
              expanded ? AppIcons.chevronDown : AppIcons.chevronRight,
              size: 13,
              color: tokens.fgTertiary,
            ),
          ],
        ],
      ),
    );
  }
}

/// The quiet, shimmering "still working" line shown at the tail of a live turn
/// between steps. Mirrors the status the old accordion header used to show, now
/// as a footer in the continuous flow.
///
/// Quiet, not faint: while a turn is in flight this line is the only thing on
/// screen reporting what the agent is doing, so it takes a body-grade text token
/// (`textSecondary`) rather than the annotation-grade tertiary. [ShimmerText]
/// sweeps *up* from this colour, so it is also the line's contrast floor.
class _LiveStatusLine extends StatelessWidget {
  const _LiveStatusLine({required this.segments});

  final List<TranscriptSegment> segments;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final l10n = AppLocalizations.of(context);
    final style = CcTypography.caption.copyWith(
      color: tokens.textSecondary,
      fontWeight: FontWeight.w500,
    );
    return Row(
      children: [
        Flexible(
          child: ShimmerText(liveStatusLabel(segments, l10n), style: style),
        ),
      ],
    );
  }
}

/// Maps the derived in-flight [TranscriptStatus] to a localized status line.
/// Shared between the live tail indicator and any other "what is the agent
/// doing" surface.
String liveStatusLabel(
  List<TranscriptSegment> segments,
  AppLocalizations l10n,
) {
  final status = statusLineFor(segments);
  if (status == null) {
    return l10n.transcriptThinking;
  }
  return switch (status.kind) {
    TranscriptStatusKind.thinking => l10n.transcriptThinking,
    TranscriptStatusKind.readingFiles => l10n.transcriptStatusReadingFiles,
    TranscriptStatusKind.makingEdits => l10n.transcriptStatusMakingEdits,
    TranscriptStatusKind.runningCommands =>
      l10n.transcriptStatusRunningCommands,
    TranscriptStatusKind.searching => l10n.transcriptStatusSearching,
    TranscriptStatusKind.responding => l10n.transcriptStatusResponding,
    TranscriptStatusKind.runningTool => l10n.transcriptStatusRunningTool(
      humanizeToolName(status.toolName ?? ''),
    ),
  };
}

String _formatDuration(int ms) {
  if (ms < 1000) {
    return '<1s';
  }
  final s = ms ~/ 1000;
  if (s < 60) {
    return '${s}s';
  }
  final m = s ~/ 60;
  final rem = s % 60;
  return rem == 0 ? '${m}m' : '${m}m ${rem}s';
}
