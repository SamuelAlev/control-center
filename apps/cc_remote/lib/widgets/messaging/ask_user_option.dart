part of 'ask_user_card.dart';

extension _AskUserOption on _AskUserCardState {
  Widget _option(DesignSystemTokens t, int index, AgentQuestionOption option) {
    final selected = _selected.contains(index);
    final subtitle = option.description;
    return CcTappable(
      onPressed: _interactive ? () => _activate(index) : null,
      semanticLabel: subtitle == null || subtitle.isEmpty
          ? option.label
          : '${option.label}. $subtitle',
      builder: (context, states) {
        return ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 44),
          child: ColoredBox(
            color: selected ? t.hoverStrong : const Color(0x00000000),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        children: [
                          TextSpan(
                            text: option.label,
                            style: CcTypography.body.copyWith(
                              color: t.textPrimary,
                              fontWeight: CcTypography.semiboldWeight,
                            ),
                          ),
                          if (subtitle != null && subtitle.isNotEmpty)
                            TextSpan(
                              text: ' $subtitle',
                              style: CcTypography.body.copyWith(
                                color: t.textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 28,
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: CcFonts.code(
                          textStyle: CcTypography.monoNum.copyWith(
                            color: selected ? t.textPrimary : t.textTertiary,
                            fontWeight: CcTypography.semiboldWeight,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
