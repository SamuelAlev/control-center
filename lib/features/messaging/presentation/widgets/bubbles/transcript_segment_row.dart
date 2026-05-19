import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/features/messaging/presentation/widgets/bubbles/bubble_shared.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/markdown_image.dart';
import 'package:control_center/shared/widgets/markdown/markdown_registries.dart';
import 'package:control_center/shared/widgets/markdown/markdown_style.dart';
import 'package:control_center/shared/widgets/transcript/tool_body.dart';
import 'package:control_center/shared/widgets/transcript/tool_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One row in the transcript process timeline: a reasoning span, tool call,
/// error, or sandbox violation. Collapsed by default; tools and long prose
/// expand to a rich body (code, diff, terminal, or JSON).
class TranscriptSegmentRow extends ConsumerStatefulWidget {
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
  ConsumerState<TranscriptSegmentRow> createState() =>
      _TranscriptSegmentRowState();
}

class _TranscriptSegmentRowState extends ConsumerState<TranscriptSegmentRow> {
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
    // File changes open expanded: for an edit or a write, the body *is* the
    // information ("Edit foo.dart" alone says nothing), so the diff shows
    // inline where the change happened instead of one click away.
    if (seg is ToolSegment && toolBodyOpensByDefault(seg)) {
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

    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(color: _categoryAccent(seg, tokens), width: 2),
        ),
      ),
      padding: const EdgeInsets.only(left: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          header,
          if (_open && canExpand)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _detail(context, seg, tokens, theme),
            ),
        ],
      ),
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
        out.add(
          Padding(
            padding: const EdgeInsets.only(left: 6),
            child: Text.rich(
              // A base style on the root span matters: an unstyled child
              // (e.g. a bare ' ' spacer) would inherit the ambient
              // DefaultTextStyle, inflate the line box and lift the stats
              // off the shared baseline with the duration beside it.
              TextSpan(
                style: CcTypography.caption.copyWith(fontSize: 10),
                children: [
                  TextSpan(
                    text: '+${stats.adds}',
                    style: CcTypography.caption.copyWith(
                      color: tokens.textSuccessPrimary,
                      fontSize: 10,
                    ),
                  ),
                  const TextSpan(text: ' '),
                  TextSpan(
                    text: '−${stats.dels}',
                    style: CcTypography.caption.copyWith(
                      color: tokens.textErrorPrimary,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    }
    if (seg.durationMs != null) {
      out.add(
        Padding(
          padding: const EdgeInsets.only(left: 6),
          child: Text(
            _formatDuration(Duration(milliseconds: seg.durationMs!)),
            style: CcTypography.caption.copyWith(
              color: tokens.textQuaternary,
              fontSize: 10,
            ),
          ),
        ),
      );
    }
    return out;
  }

  TextSpan _summaryText(
    TranscriptSegment seg,
    DesignSystemTokens tokens,
    ThemeData theme,
  ) {
    final l10n = AppLocalizations.of(context);
    final base = AppFonts.codeDynamic(
      widget.codeFont,
      textStyle: CcTypography.caption.copyWith(color: tokens.textTertiary),
    );
    final mono = AppFonts.codeDynamic(
      widget.codeFont,
      textStyle: CcTypography.caption.copyWith(color: tokens.textPrimary),
    );
    switch (seg) {
      case ToolSegment():
        final p = resolveToolPresentation(seg);
        return TextSpan(
          // Base style on the root so the unstyled '  ' spacer below shares
          // the summary's metrics instead of the ambient DefaultTextStyle.
          style: base,
          children: [
            TextSpan(
              text: p.verb,
              style: mono.copyWith(fontWeight: FontWeight.w600),
            ),
            if (p.subtitle != null) ...[
              const TextSpan(text: '  '),
              TextSpan(text: p.subtitle, style: base),
            ],
          ],
        );
      case ReasoningSegment(:final text):
        return TextSpan(
          text: _firstLine(text) ?? l10n.transcriptThinking,
          style: base,
        );
      case ErrorSegment(:final message):
        return TextSpan(
          text: _firstLine(message) ?? l10n.transcriptErrorLabel,
          style: base.copyWith(color: tokens.textErrorPrimary),
        );
      case ViolationSegment(:final message):
        return TextSpan(
          text: _firstLine(message) ?? l10n.transcriptSandboxBlocked,
          style: base.copyWith(color: tokens.fgWarningPrimary),
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
      // The blob URL is signed per workspace, and `shared/` may not reach into
      // a feature to find out which one — so it is read here and passed down.
      return buildToolBody(
        context,
        seg: seg,
        codeFont: widget.codeFont,
        tokens: tokens,
        workspaceId: ref.watch(activeWorkspaceIdProvider),
      );
    }
    final text = switch (seg) {
      ReasoningSegment(:final text) => text,
      ErrorSegment(:final message) => message,
      ViolationSegment(:final message) => message,
      TextSegment(:final text) => text,
      ToolSegment() => '',
    };
    return CcMarkdown(
      data: text,
      selectable: true,
      style: appMarkdownStyle(context, compact: true),
      codeBuilder: (code, language, {required bool cache}) =>
          buildSharedCodeBlock(context, code, language, cache: cache),
      plugins: chatMarkdownPlugins,
      options: chatMarkdownOptions,
      builders: chatMarkdownBuilders,
      imageBuilder: appMarkdownImageBuilder,
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
        return Icon(
          AppIcons.loaderCircle,
          size: 12,
          color: tokens.fgBrandPrimary,
        );
      }
      return const SizedBox(width: 12, height: 12, child: CcSpinner(size: 12));
    }
    if (seg is ToolSegment) {
      return switch (seg.status) {
        ToolSegmentStatus.running => Icon(
          AppIcons.minus,
          size: 12,
          color: tokens.textQuaternary,
        ),
        ToolSegmentStatus.ok => Icon(
          AppIcons.check,
          size: 12,
          color: tokens.fgSuccessPrimary,
        ),
        ToolSegmentStatus.error => Icon(
          AppIcons.circleX,
          size: 12,
          color: tokens.fgErrorPrimary,
        ),
        ToolSegmentStatus.interrupted => Icon(
          AppIcons.circleSlash,
          size: 12,
          color: tokens.fgWarningPrimary,
        ),
      };
    }
    if (seg is ErrorSegment) {
      return Icon(AppIcons.circleX, size: 12, color: tokens.fgErrorPrimary);
    }
    if (seg is ViolationSegment) {
      return Icon(AppIcons.shield, size: 12, color: tokens.fgWarningPrimary);
    }
    return const SizedBox(width: 12, height: 12);
  }
}

IconData _icon(TranscriptSegment seg) => switch (seg) {
  ReasoningSegment() => AppIcons.brain,
  ToolSegment() => resolveToolPresentation(seg).icon,
  ErrorSegment() => AppIcons.triangleAlert,
  ViolationSegment() => AppIcons.shield,
  TextSegment() => AppIcons.messageSquare,
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

/// Left-rail accent color for a transcript row: tool categories get a distinct
/// token hue (explore/edit/run/delegate/fetch/other); error and violation rows
/// get their status hue; everything else a faint rail. Color is an additional
/// scannability cue only — the icon, verb and status dot always carry the
/// primary signal.
Color _categoryAccent(TranscriptSegment seg, DesignSystemTokens tokens) {
  if (seg is ToolSegment) {
    return switch (resolveToolPresentation(seg).category) {
      ToolCategory.explore => tokens.textTertiary,
      ToolCategory.edit => tokens.fgWarningPrimary,
      ToolCategory.run => tokens.accent,
      ToolCategory.delegate => tokens.fgBrandSecondary,
      ToolCategory.fetch => tokens.textSuccessPrimary,
      ToolCategory.other => tokens.borderSecondary,
    };
  }
  if (seg is ErrorSegment) {
    return tokens.fgErrorPrimary;
  }
  if (seg is ViolationSegment) {
    return tokens.fgWarningPrimary;
  }
  return tokens.borderSecondary;
}

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
