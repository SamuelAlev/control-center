part of 'ask_user_card.dart';

extension _AskUserCardPresentation on _AskUserCardState {
  Map<ShortcutActivator, VoidCallback> get _bindings {
    if (!_interactive) {
      return const {};
    }
    final n = widget.options.length + (_freeTextAsOption ? 1 : 0);
    final map = <ShortcutActivator, VoidCallback>{};
    for (var i = 0; i < n && i < _digits.length; i++) {
      final oneBased = i + 1;
      map[SingleActivator(_digits[i])] = () => _activateIndex(oneBased);
      map[SingleActivator(_numpads[i])] = () => _activateIndex(oneBased);
    }
    if (_needsContinue) {
      map[const SingleActivator(LogicalKeyboardKey.enter, meta: true)] =
          _submitContinue;
      map[const SingleActivator(LogicalKeyboardKey.enter, control: true)] =
          _submitContinue;
    }
    return map;
  }

  Widget _buildCard(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final remaining = _remainingFraction;

    return DefaultTextStyle(
      style: CcFonts.ui(
        textStyle: CcTypography.body.copyWith(
          color: t.textPrimary,
          decoration: TextDecoration.none,
        ),
      ),
      child: CallbackShortcuts(
        bindings: _bindings,
        child: Focus(
          focusNode: _cardFocus,
          autofocus: _interactive,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: t.bgPrimary,
              border: Border.all(color: t.borderPrimary),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (remaining != null)
                  _CountdownBar(
                    remaining: remaining,
                    color: t.accent,
                    semanticLabel: l10n.agentQuestionTimeLeft,
                  ),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.lg,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _caption(l10n),
                          style: CcTypography.caption.copyWith(
                            color: t.textTertiary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Flexible(
                          child: CcScrollbar(
                            thumbVisibility: true,
                            child: SingleChildScrollView(
                              padding: const EdgeInsetsDirectional.only(
                                end: AppSpacing.sm,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    widget.question,
                                    style: CcTypography.title.copyWith(
                                      color: t.textPrimary,
                                    ),
                                  ),
                                  if ((widget.contextText ?? '')
                                      .isNotEmpty) ...[
                                    const SizedBox(height: AppSpacing.xs),
                                    Text(
                                      widget.contextText!,
                                      style: CcTypography.body.copyWith(
                                        color: t.textSecondary,
                                      ),
                                    ),
                                  ],
                                  if (widget.extraBody != null) ...[
                                    const SizedBox(height: AppSpacing.md),
                                    widget.extraBody!,
                                  ],
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        ..._optionRows(),
                        if (_freeTextAsOption)
                          AskUserFreeTextRow(
                            key: const ValueKey('ask-user-free-text'),
                            index: widget.options.length + 1,
                            controller: _freeText,
                            focusNode: _textFocus,
                            hintText: l10n.agentQuestionFreeformOptionHint,
                            enabled: _interactive,
                            hasText: _typed.isNotEmpty,
                            showSubmitArrow: !widget.multiSelect,
                            onChanged: (_) => _rebuild(),
                            onSubmit: _submitFreeText,
                          )
                        else if (_freeTextStandalone) ...[
                          CcTextField(
                            key: const ValueKey('ask-user-free-text'),
                            controller: _freeText,
                            focusNode: _textFocus,
                            enabled: _interactive,
                            autofocus: _interactive,
                            hintText: l10n.agentQuestionFreeformHint,
                            textStyle: CcTypography.body.copyWith(
                              color: t.textPrimary,
                            ),
                            onChanged: (_) => _rebuild(),
                            onSubmitted: _interactive && _typed.isNotEmpty
                                ? (_) => _submitContinue()
                                : null,
                          ),
                        ],
                        if (_showFooter) ...[
                          const SizedBox(height: AppSpacing.sm),
                          _footer(t, l10n),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _caption(AppLocalizations l10n) {
    if (widget.caption != null) {
      return widget.caption!;
    }
    final index = widget.questionIndex;
    final count = widget.questionCount;
    if (index != null && count != null && count > 0) {
      return l10n.agentQuestionProgress(index, count);
    }
    return l10n.agentQuestionHeader;
  }

  List<Widget> _optionRows() {
    return [
      for (var i = 0; i < widget.options.length; i++)
        AskUserOptionRow(
          key: ValueKey('ask-user-option-$i'),
          index: i + 1,
          label: widget.options[i].label,
          description: widget.options[i].description,
          selected: _selected.contains(i),
          multiSelect: widget.multiSelect,
          enabled: _interactive,
          onPressed: () => _activateOption(i),
        ),
    ];
  }

  bool get _showFooter => widget.allowSkip || _needsContinue;

  Widget _footer(DesignSystemTokens t, AppLocalizations l10n) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (widget.allowSkip)
          CcTappable(
            key: const ValueKey('ask-user-skip'),
            onPressed: _interactive ? _skip : null,
            semanticLabel: l10n.agentQuestionSkip,
            builder: (context, states) {
              final hovered = states.contains(WidgetState.hovered);
              final color = hovered ? t.textPrimary : t.textTertiary;
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.sm,
                  vertical: AppSpacing.sm,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n.agentQuestionSkip,
                      style: CcTypography.body.copyWith(color: color),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Icon(AppIcons.arrowRight, size: 14, color: color),
                  ],
                ),
              );
            },
          ),
        if (widget.allowSkip && _needsContinue)
          const SizedBox(width: AppSpacing.sm),
        if (_needsContinue)
          CcButton(
            key: const ValueKey('ask-user-continue'),
            variant: _canSubmit
                ? CcButtonVariant.primary
                : CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            loading: widget.submitting,
            onPressed: _canSubmit ? _submitContinue : null,
            trailing: CcKbdGroup(
              keys: [CcKeys.cmdOrCtrl, CcKeys.enter],
              fontSize: 10,
            ),
            child: Text(l10n.continueLabel),
          ),
      ],
    );
  }
}

/// Thin bar along the card's top edge showing how much of the asker's wait is
/// left. It eases between the card's one-second ticks so it drains smoothly.
class _CountdownBar extends StatelessWidget {
  const _CountdownBar({
    required this.remaining,
    required this.color,
    required this.semanticLabel,
  });

  final double remaining;
  final Color color;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: remaining),
      duration: CcMotion.reduced(context)
          ? Duration.zero
          : const Duration(seconds: 1),
      builder: (context, value, _) => CcProgressBar(
        key: const ValueKey('ask-user-countdown'),
        value: value,
        height: 2,
        color: color,
        trackColor: const Color(0x00000000),
        semanticLabel: semanticLabel,
      ),
    );
  }
}
