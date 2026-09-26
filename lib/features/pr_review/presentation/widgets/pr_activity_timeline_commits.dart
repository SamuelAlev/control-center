part of 'pr_activity_timeline.dart';

/// Leading space plus the commit subject, with backtick runs as inline code.
List<InlineSpan> _commitTitleSpans(
  BuildContext context,
  String title,
  TextStyle style,
) {
  return [
    TextSpan(text: ' ', style: style),
    // The subject wraps with the sentence and does not ellipsize, so code
    // runs stay chips. An ellipsizing title has to degrade to text runs
    // (see [PrTitleText]).
    ...buildInlineCodeSpans(context, title, baseStyle: style),
  ];
}

/// Hash + title of a commit. With [onOpen], both are one button that opens
/// that commit's diff; otherwise they stay plain text so the sentence wraps
/// the same way.
List<InlineSpan> _commitIdentitySpans(
  BuildContext context, {
  required PrCommit commit,
  required String codeFont,
  required TextStyle base,
  required ValueChanged<String>? onOpen,
  bool leadingSpace = false,
}) {
  final t = context.designSystem ?? DesignSystemTokens.light();
  final shaStyle = base.copyWith(fontFamily: codeFont, color: t.textSecondary);
  final titleStyle = base.copyWith(color: t.textTertiary);
  if (onOpen == null) {
    return [
      TextSpan(
        text: leadingSpace ? ' ${commit.shortSha}' : commit.shortSha,
        style: shaStyle,
      ),
      if (commit.title.isNotEmpty)
        ..._commitTitleSpans(context, commit.title, titleStyle),
    ];
  }
  return [
    if (leadingSpace) const TextSpan(text: ' '),
    WidgetSpan(
      alignment: PlaceholderAlignment.baseline,
      baseline: TextBaseline.alphabetic,
      child: _CommitChangesLink(
        commit: commit,
        codeFont: codeFont,
        onOpen: onOpen,
      ),
    ),
  ];
}

/// The tappable hash and title. Inline so a tap reaches the button inside the
/// overview's selection region; a long title takes the next line instead of
/// overflowing the sentence.
class _CommitChangesLink extends StatelessWidget {
  const _CommitChangesLink({
    required this.commit,
    required this.codeFont,
    required this.onOpen,
  });

  final PrCommit commit;
  final String codeFont;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final base = CcTypography.caption.copyWith(height: 1.5);
    return CcTooltip(
      message: l10n.viewInDiff,
      child: CcTappable(
        onPressed: () => onOpen(commit.sha),
        semanticLabel: '${l10n.viewInDiff} ${commit.shortSha}',
        borderRadius: AppRadii.brSm,
        builder: (context, states) {
          final hot =
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused) ||
              states.contains(WidgetState.pressed);
          final shaColor = hot ? t.textPrimary : t.textSecondary;
          final titleColor = hot ? t.textSecondary : t.textTertiary;
          final decoration = hot
              ? TextDecoration.underline
              : TextDecoration.none;
          return Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: commit.shortSha,
                  style: base.copyWith(
                    fontFamily: codeFont,
                    color: shaColor,
                    decoration: decoration,
                    decorationColor: shaColor,
                  ),
                ),
                if (commit.title.isNotEmpty)
                  ..._commitTitleSpans(
                    context,
                    commit.title,
                    base.copyWith(
                      color: titleColor,
                      decoration: decoration,
                      decorationColor: titleColor,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
