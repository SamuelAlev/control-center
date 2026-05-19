import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/value_objects/transcript_segment.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/transcript/tool_body.dart';
import 'package:control_center/shared/widgets/transcript/tool_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smooth_markdown/flutter_smooth_markdown.dart' as sm;
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// One row in the transcript process timeline: a reasoning span, tool call,
/// error, or sandbox violation. Collapsed by default; tools and long prose
/// expand to a rich body (code, diff, terminal, or JSON).
class TranscriptSegmentRow extends StatefulWidget {
  /// Creates a [TranscriptSegmentRow].
  const TranscriptSegmentRow({
    super.key,
    required this.segment,
    required this.codeFont,
    this.pending = false,
  });

  /// The segment to render.
  final TranscriptSegment segment;

  /// Mono font for rich code/diff bodies.
  final String codeFont;

  /// Whether this is the live, currently-running tail segment.
  final bool pending;

  @override
  State<TranscriptSegmentRow> createState() => _TranscriptSegmentRowState();
}

class _TranscriptSegmentRowState extends State<TranscriptSegmentRow> {
  bool? _userOpen;

  bool get _open => _userOpen ?? _defaultOpen;

  bool get _defaultOpen {
    final seg = widget.segment;
    if (seg is ErrorSegment || seg is ViolationSegment) {
      return true;
    }
    if (seg is ToolSegment && seg.status == ToolSegmentStatus.error) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final tokens = resolveTokens(context);
    final theme = Theme.of(context);
    final seg = widget.segment;
    final canExpand = _hasExpandable(seg);

    final summaryRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(_icon(seg), size: 14, color: _iconColor(seg, tokens)),
        const SizedBox(width: 6),
        Expanded(
          child: Text.rich(
            _summaryText(seg, tokens, theme),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        ..._trailing(seg, tokens, theme),
        const SizedBox(width: 4),
        _StatusDot(segment: seg, pending: widget.pending, tokens: tokens),
      ],
    );

    final header = canExpand
        ? CcTappable(
            onPressed: () => setState(() => _userOpen = !_open),
            builder: (context, states) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: summaryRow,
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: summaryRow,
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        header,
        if (_open && canExpand)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _detail(context, seg, tokens, theme),
          ),
      ],
    );
  }

  List<Widget> _trailing(
    TranscriptSegment seg,
    DesignSystemTokens tokens,
    ThemeData theme,
  ) {
    final out = <Widget>[];
    if (seg is ToolSegment) {
      final stats = toolDiffStats(seg);
      if (stats != null && (stats.adds > 0 || stats.dels > 0)) {
        out.add(Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text.rich(
            TextSpan(children: [
              TextSpan(
                text: '+${stats.adds}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: tokens.textSuccessPrimary, fontSize: 10),
              ),
              const TextSpan(text: ' '),
              TextSpan(
                text: '−${stats.dels}',
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: tokens.textErrorPrimary, fontSize: 10),
              ),
            ]),
          ),
        ));
      }
    }
    if (seg.durationMs != null) {
      out.add(Padding(
        padding: const EdgeInsets.only(left: 6),
        child: Text(
          _formatDuration(Duration(milliseconds: seg.durationMs!)),
          style: theme.textTheme.labelSmall
              ?.copyWith(color: tokens.textQuaternary, fontSize: 10),
        ),
      ));
    }
    return out;
  }

  TextSpan _summaryText(
    TranscriptSegment seg,
    DesignSystemTokens tokens,
    ThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context);
    final base = theme.textTheme.labelSmall?.copyWith(color: tokens.textTertiary);
    final mono = AppFonts.codeDynamic(
      widget.codeFont,
      textStyle:
          theme.textTheme.labelSmall?.copyWith(color: tokens.textPrimary),
    );
    switch (seg) {
      case ToolSegment():
        final p = resolveToolPresentation(seg);
        return TextSpan(children: [
          TextSpan(text: p.verb, style: mono.copyWith(fontWeight: FontWeight.w600)),
          if (p.subtitle != null) ...[
            const TextSpan(text: '  '),
            TextSpan(text: p.subtitle, style: base),
          ],
        ]);
      case ReasoningSegment(:final text):
        return TextSpan(text: _firstLine(text) ?? l10n.transcriptThinking, style: base);
      case ErrorSegment(:final message):
        return TextSpan(
          text: _firstLine(message) ?? l10n.transcriptErrorLabel,
          style: base?.copyWith(color: tokens.textErrorPrimary),
        );
      case ViolationSegment(:final message):
        return TextSpan(
          text: _firstLine(message) ?? l10n.transcriptSandboxBlocked,
          style: base?.copyWith(color: tokens.fgWarningPrimary),
        );
      case TextSegment(:final text):
        return TextSpan(text: _firstLine(text) ?? '', style: base);
    }
  }

  Widget _detail(
    BuildContext context,
    TranscriptSegment seg,
    DesignSystemTokens tokens,
    ThemeData theme,
  ) {
    if (seg is ToolSegment) {
      return buildToolBody(
        context,
        seg: seg,
        codeFont: widget.codeFont,
        tokens: tokens,
      );
    }
    final text = switch (seg) {
      ReasoningSegment(:final text) => text,
      ErrorSegment(:final message) => message,
      ViolationSegment(:final message) => message,
      TextSegment(:final text) => text,
      ToolSegment() => '',
    };
    return sm.SmoothMarkdown(
      data: text,
      selectable: true,
      styleSheet: _detailMdStyle(tokens, theme),
      plugins: chatPlugins,
      builderRegistry: chatBuilders,
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({
    required this.segment,
    required this.pending,
    required this.tokens,
  });

  final TranscriptSegment segment;
  final bool pending;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    final reduceMotion =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    final seg = segment;
    if (pending) {
      if (reduceMotion) {
        return Icon(LucideIcons.loaderCircle, size: 12, color: tokens.fgBrandPrimary);
      }
      return const SizedBox(
        width: 12,
        height: 12,
        child: CcSpinner(size: 12),
      );
    }
    if (seg is ToolSegment) {
      return switch (seg.status) {
        ToolSegmentStatus.running =>
          Icon(LucideIcons.minus, size: 12, color: tokens.textQuaternary),
        ToolSegmentStatus.ok =>
          Icon(LucideIcons.check, size: 12, color: tokens.fgSuccessPrimary),
        ToolSegmentStatus.error =>
          Icon(LucideIcons.circleX, size: 12, color: tokens.fgErrorPrimary),
        ToolSegmentStatus.interrupted =>
          Icon(LucideIcons.circleSlash, size: 12, color: tokens.fgWarningPrimary),
      };
    }
    if (seg is ErrorSegment) {
      return Icon(LucideIcons.circleX, size: 12, color: tokens.fgErrorPrimary);
    }
    if (seg is ViolationSegment) {
      return Icon(LucideIcons.shield, size: 12, color: tokens.fgWarningPrimary);
    }
    return const SizedBox(width: 12, height: 12);
  }
}

IconData _icon(TranscriptSegment seg) => switch (seg) {
      ReasoningSegment() => LucideIcons.brain,
      ToolSegment() => resolveToolPresentation(seg).icon,
      ErrorSegment() => LucideIcons.triangleAlert,
      ViolationSegment() => LucideIcons.shield,
      TextSegment() => LucideIcons.messageSquare,
    };

Color _iconColor(TranscriptSegment seg, DesignSystemTokens tokens) =>
    switch (seg) {
      ErrorSegment() => tokens.fgErrorPrimary,
      ViolationSegment() => tokens.fgWarningPrimary,
      ToolSegment(:final status) when status == ToolSegmentStatus.error =>
        tokens.fgErrorPrimary,
      ToolSegment() => tokens.textPrimary,
      _ => tokens.textTertiary,
    };

bool _hasExpandable(TranscriptSegment seg) => switch (seg) {
      ToolSegment(:final inputs, :final outputs) =>
        (inputs != null && inputs.isNotEmpty) || outputs.isNotEmpty,
      ReasoningSegment(:final text) => text.length > 80,
      ErrorSegment(:final message) => message.length > 80,
      ViolationSegment(:final message) => message.length > 80,
      TextSegment(:final text) => text.length > 80,
    };

String? _firstLine(String content) {
  if (content.isEmpty) {
    return null;
  }
  final i = content.indexOf('\n');
  final line = (i == -1 ? content : content.substring(0, i)).trim();
  return line.isEmpty ? null : line;
}

String _formatDuration(Duration d) {
  if (d.inMilliseconds < 1000) {
    return '<1s';
  }
  if (d.inSeconds < 60) {
    return '${d.inSeconds}s';
  }
  final m = d.inMinutes;
  final s = d.inSeconds % 60;
  return s == 0 ? '${m}m' : '${m}m ${s}s';
}

sm.MarkdownStyleSheet _detailMdStyle(DesignSystemTokens tokens, ThemeData theme) {
  final bodyStyle = theme.textTheme.bodySmall?.copyWith(
    color: tokens.textQuaternary,
    height: bodyLineHeight,
  );
  return sm.MarkdownStyleSheet.fromTheme(theme).copyWith(
    textStyle: bodyStyle,
    codeBlockStyle: AppFonts.codeDynamic(
      theme.textTheme.bodySmall?.fontFamily ?? 'JetBrains Mono',
      textStyle: theme.textTheme.bodySmall?.copyWith(
        color: tokens.textQuaternary,
        height: bodyLineHeight,
      ),
    ),
    linkStyle: theme.textTheme.bodySmall?.copyWith(
      color: tokens.textBrandTertiary,
      decoration: TextDecoration.underline,
      height: bodyLineHeight,
    ),
  );
}
