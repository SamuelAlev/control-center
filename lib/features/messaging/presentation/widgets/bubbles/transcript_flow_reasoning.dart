part of 'transcript_flow.dart';

/// An inline reasoning ("extended thinking") span: a quiet brain-iconed eyebrow
/// over dimmed markdown prose, set off by a faint left rail. Expanded by default
/// (reasoning is part of the flow, not hidden) with a collapse affordance for
/// long thoughts; force-expanded while the span is still streaming so the user
/// watches it think.
class _ReasoningBlock extends StatefulWidget {
  const _ReasoningBlock({
    super.key,
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

  /// The muted prose style and the base it was derived from. Re-derived only
  /// when the base changes: a fresh `copyWith` per build is value-equal but a
  /// new instance, and the markdown memo below is keyed on it.
  CcMarkdownStyle? _mutedBase;
  Color? _mutedColor;
  CcMarkdownStyle? _muted;

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
    if (!identical(_mutedBase, base) || _mutedColor != tokens.textSecondary) {
      _mutedBase = base;
      _mutedColor = tokens.textSecondary;
      _muted = base.copyWith(
        paragraph: base.paragraph?.copyWith(color: tokens.textSecondary),
      );
    }
    final muted = _muted!;

    return Container(
      decoration: BoxDecoration(
        border: BorderDirectional(
          start: BorderSide(color: tokens.borderSecondary, width: 2),
        ),
      ),
      padding: const EdgeInsetsDirectional.only(start: 10),
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
          CcCollapsible(
            expanded: expanded,
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: _ChatProseMarkdown(
                data: widget.segment.text,
                style: muted,
                codeBuilder: sharedCodeBuilder(),
                streaming: widget.streaming,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// The reasoning header: a brain icon, the "Thinking…" / "Thought for N"
  /// label and (when interactive) a collapse chevron.
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
                ? CcShimmerText(label, style: labelStyle)
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
