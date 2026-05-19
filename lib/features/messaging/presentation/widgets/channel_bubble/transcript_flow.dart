import 'package:cc_domain/core/domain/services/transcript_status.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/transcript_segment_row.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:control_center/shared/widgets/transcript/tool_presentation.dart';
import 'package:control_center/shared/widgets/transcript/widgets/shimmer_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart' as sm;

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
/// Pure render over [segments]; the parent rebuilds it on each live update by
/// re-reading the active-stream snapshot, so this widget needs no stream
/// subscription of its own. No master collapse/expand state and no auto-collapse
/// timer — everything is always visible, which is the whole point.
class TranscriptFlow extends StatelessWidget {
  /// Creates a [TranscriptFlow].
  const TranscriptFlow({
    super.key,
    required this.segments,
    required this.codeFont,
    this.isLive = false,
  });

  /// The full transcript in chronological order (text segments included).
  final List<TranscriptSegment> segments;

  /// Mono font for rich code/diff/terminal bodies.
  final String codeFont;

  /// Whether the agent is still emitting segments.
  final bool isLive;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    TranscriptSegment? prev;
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final rendered = _renderSegment(seg, i);
      if (rendered == null) {
        continue;
      }
      if (children.isNotEmpty) {
        children.add(SizedBox(height: _gapBefore(prev, seg)));
      }
      children.add(rendered);
      prev = seg;
    }

    if (isLive && _showTail(segments)) {
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

  Widget? _renderSegment(TranscriptSegment seg, int index) {
    switch (seg) {
      case TextSegment(:final text):
        if (text.trim().isEmpty) {
          return null;
        }
        return TurnProse(content: text, codeFont: codeFont);
      case ReasoningSegment(:final text):
        if (text.trim().isEmpty) {
          return null;
        }
        return _ReasoningBlock(
          segment: seg,
          codeFont: codeFont,
          streaming: isLive &&
              index == segments.length - 1 &&
              seg.durationMs == null,
        );
      case ToolSegment():
      case ErrorSegment():
      case ViolationSegment():
        return TranscriptSegmentRow(
          segment: seg,
          codeFont: codeFont,
          pending: isLive &&
              index == segments.length - 1 &&
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
  const TurnProse({super.key, required this.content, required this.codeFont});

  /// The markdown content.
  final String content;

  /// Font family for code blocks.
  final String codeFont;

  @override
  Widget build(BuildContext context) {
    return sm.SmoothMarkdown(
      data: content,
      selectable: true,
      styleSheet: smMarkdownStyleSheet(context, codeFontFamily: codeFont),
      codeBuilder: (code, language) => buildSharedCodeBlock(
        context,
        code,
        language,
        codeFontFamily: codeFont,
      ),
      plugins: chatPlugins,
      builderRegistry: chatBuilders,
      useEnhancedComponents: true,
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
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final expanded = _expanded;

    final labelStyle = AppFonts.codeDynamic(
      widget.codeFont,
      textStyle: theme.textTheme.labelSmall?.copyWith(
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
    final base = smMarkdownStyleSheet(
      context,
      codeFontFamily: widget.codeFont,
      compact: true,
    );
    final muted = base.copyWith(
      textStyle: base.textStyle?.copyWith(color: tokens.textSecondary),
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
            _eyebrow(labelStyle, label, tokens, showChevron: false, expanded: expanded)
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
              child: sm.SmoothMarkdown(
                data: widget.segment.text,
                selectable: true,
                styleSheet: muted,
                codeBuilder: (code, language) =>
                    buildSharedCodeBlock(context, code, language),
                plugins: chatPlugins,
                builderRegistry: chatBuilders,
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
                : Text(label, style: labelStyle, overflow: TextOverflow.ellipsis),
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
class _LiveStatusLine extends StatelessWidget {
  const _LiveStatusLine({required this.segments});

  final List<TranscriptSegment> segments;

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final style = theme.textTheme.labelSmall?.copyWith(
      color: tokens.textTertiary,
      fontWeight: FontWeight.w500,
    );
    return Row(
      children: [
        Flexible(child: ShimmerText(liveStatusLabel(segments, l10n), style: style)),
      ],
    );
  }
}

/// Maps the derived in-flight [TranscriptStatus] to a localized status line.
/// Shared between the live tail indicator and any other "what is the agent
/// doing" surface.
String liveStatusLabel(List<TranscriptSegment> segments, AppLocalizations l10n) {
  final status = statusLineFor(segments);
  if (status == null) {
    return l10n.transcriptThinking;
  }
  return switch (status.kind) {
    TranscriptStatusKind.thinking => l10n.transcriptThinking,
    TranscriptStatusKind.readingFiles => l10n.transcriptStatusReadingFiles,
    TranscriptStatusKind.makingEdits => l10n.transcriptStatusMakingEdits,
    TranscriptStatusKind.runningCommands => l10n.transcriptStatusRunningCommands,
    TranscriptStatusKind.searching => l10n.transcriptStatusSearching,
    TranscriptStatusKind.responding => l10n.transcriptStatusResponding,
    TranscriptStatusKind.runningTool =>
      l10n.transcriptStatusRunningTool(humanizeToolName(status.toolName ?? '')),
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
