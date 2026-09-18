import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/ask_user/ask_user_free_text_row.dart';
import 'package:control_center/features/messaging/presentation/widgets/ask_user/ask_user_option_row.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const _digits = <LogicalKeyboardKey>[
  LogicalKeyboardKey.digit1,
  LogicalKeyboardKey.digit2,
  LogicalKeyboardKey.digit3,
  LogicalKeyboardKey.digit4,
  LogicalKeyboardKey.digit5,
  LogicalKeyboardKey.digit6,
  LogicalKeyboardKey.digit7,
  LogicalKeyboardKey.digit8,
  LogicalKeyboardKey.digit9,
];

const _numpads = <LogicalKeyboardKey>[
  LogicalKeyboardKey.numpad1,
  LogicalKeyboardKey.numpad2,
  LogicalKeyboardKey.numpad3,
  LogicalKeyboardKey.numpad4,
  LogicalKeyboardKey.numpad5,
  LogicalKeyboardKey.numpad6,
  LogicalKeyboardKey.numpad7,
  LogicalKeyboardKey.numpad8,
  LogicalKeyboardKey.numpad9,
];

/// Structured question card: numbered options, optional free text, skip, and
/// a continue chord for multi-select / typed answers.
///
/// Single-select submits on the option (hover replaces the trailing index with
/// an arrow). Multi-select toggles and waits for Continue. This is the visual
/// contract for both `ask_user` and in-conversation permission prompts.
class AskUserCard extends StatefulWidget {
  /// Creates an [AskUserCard].
  const AskUserCard({
    super.key,
    required this.question,
    this.contextText,
    this.options = const [],
    this.allowFreeText = false,
    this.multiSelect = false,
    this.allowSkip = true,
    this.questionIndex,
    this.questionCount,
    this.caption,
    this.extraBody,
    this.answered,
    this.submitting = false,
    this.onSubmit,
  });

  /// The question, as one sentence.
  final String question;

  /// Optional explanation of why this is being asked.
  final String? contextText;

  /// Predefined choices.
  final List<AgentQuestionOption> options;

  /// Whether a typed answer is accepted.
  final bool allowFreeText;

  /// Whether several options may be chosen.
  final bool multiSelect;

  /// Whether Skip is offered. Permission prompts pass false.
  final bool allowSkip;

  /// 1-based index in a batch, when known.
  final int? questionIndex;

  /// Batch size, when known.
  final int? questionCount;

  /// Overrides the default "Question for you" / progress caption.
  final String? caption;

  /// Extra content between the question and the options (a command block).
  final Widget? extraBody;

  /// When non-null the card is a read-only result.
  final AgentQuestionAnswer? answered;

  /// In-flight submit (disables the form).
  final bool submitting;

  /// Called with the chosen answer or a skip. Null on a read-only card.
  final ValueChanged<AgentQuestionAnswer>? onSubmit;

  @override
  State<AskUserCard> createState() => _AskUserCardState();
}

class _AskUserCardState extends State<AskUserCard> {
  final Set<int> _selected = {};
  final TextEditingController _freeText = TextEditingController();
  final FocusNode _textFocus = FocusNode();
  final FocusNode _cardFocus = FocusNode();

  bool get _interactive => widget.answered == null && !widget.submitting;

  bool get _freeTextAsOption =>
      widget.allowFreeText && widget.options.isNotEmpty;

  bool get _freeTextStandalone =>
      widget.allowFreeText && widget.options.isEmpty;

  bool get _needsContinue => widget.multiSelect || _freeTextStandalone;

  String get _typed => _freeText.text.trim();

  bool get _canSubmit {
    if (!_interactive) {
      return false;
    }
    if (_selected.isNotEmpty) {
      return true;
    }
    return widget.allowFreeText && _typed.isNotEmpty;
  }

  @override
  void initState() {
    super.initState();
    _hydrateAnswer(widget.answered);
    _freeText.addListener(_rebuild);
    _textFocus.addListener(_rebuild);
  }

  @override
  void didUpdateWidget(AskUserCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.answered == null && widget.answered != null) {
      _hydrateAnswer(widget.answered);
    }
  }

  void _hydrateAnswer(AgentQuestionAnswer? answered) {
    if (answered == null) {
      return;
    }
    _selected
      ..clear()
      ..addAll(_indicesFor(answered));
    final text = answered.freeText;
    if (text != null && text.isNotEmpty && _freeText.text != text) {
      _freeText.text = text;
    }
  }

  Iterable<int> _indicesFor(AgentQuestionAnswer answered) sync* {
    for (var i = 0; i < widget.options.length; i++) {
      final option = widget.options[i];
      if (answered.selectedLabels.contains(option.label) ||
          answered.selectedLabels.contains(option.effectiveValue)) {
        yield i;
      }
    }
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _freeText.removeListener(_rebuild);
    _textFocus.removeListener(_rebuild);
    _freeText.dispose();
    _textFocus.dispose();
    _cardFocus.dispose();
    super.dispose();
  }

  void _activateOption(int index) {
    if (!_interactive || index < 0 || index >= widget.options.length) {
      return;
    }
    if (widget.multiSelect) {
      setState(() {
        if (_selected.contains(index)) {
          _selected.remove(index);
        } else {
          _selected.add(index);
        }
      });
      return;
    }
    _emit(
      AgentQuestionAnswer(
        selectedLabels: [widget.options[index].effectiveValue],
        freeText: widget.allowFreeText && _typed.isNotEmpty ? _typed : null,
      ),
    );
  }

  void _activateIndex(int oneBased) {
    if (!_interactive) {
      return;
    }
    final i = oneBased - 1;
    if (i < widget.options.length) {
      _activateOption(i);
      return;
    }
    if (_freeTextAsOption && i == widget.options.length) {
      _textFocus.requestFocus();
    }
  }

  void _submitContinue() {
    if (!_canSubmit) {
      return;
    }
    final labels = [
      for (final i in _selected)
        if (i >= 0 && i < widget.options.length)
          widget.options[i].effectiveValue,
    ];
    _emit(
      AgentQuestionAnswer(
        selectedLabels: labels,
        freeText: widget.allowFreeText && _typed.isNotEmpty ? _typed : null,
      ),
    );
  }

  void _submitFreeText() {
    if (!_interactive || _typed.isEmpty) {
      return;
    }
    _emit(AgentQuestionAnswer(freeText: _typed));
  }

  void _skip() {
    if (!_interactive) {
      return;
    }
    _emit(const AgentQuestionAnswer(skipped: true));
  }

  void _emit(AgentQuestionAnswer answer) {
    widget.onSubmit?.call(answer);
  }

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

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final answered = widget.answered;

    return CallbackShortcuts(
      bindings: _bindings,
      child: Focus(
        focusNode: _cardFocus,
        autofocus: _interactive,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: t.bgPrimary,
            border: Border.all(color: t.borderPrimary),
          ),
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
                  _caption(l10n, answered),
                  style: CcTypography.caption.copyWith(color: t.textTertiary),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  widget.question,
                  style: CcTypography.title.copyWith(color: t.textPrimary),
                ),
                if ((widget.contextText ?? '').isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.contextText!,
                    style: CcTypography.body.copyWith(color: t.textSecondary),
                  ),
                ],
                if (widget.extraBody != null) ...[
                  const SizedBox(height: AppSpacing.md),
                  widget.extraBody!,
                ],
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
                    textStyle: CcTypography.body.copyWith(color: t.textPrimary),
                    onChanged: (_) => _rebuild(),
                    onSubmitted: _interactive && _typed.isNotEmpty
                        ? (_) => _submitContinue()
                        : null,
                  ),
                ],
                if (_showFooter(answered)) ...[
                  const SizedBox(height: AppSpacing.sm),
                  _footer(t, l10n),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _caption(AppLocalizations l10n, AgentQuestionAnswer? answered) {
    if (answered != null) {
      return answered.skipped
          ? l10n.agentQuestionSkippedLabel
          : l10n.agentQuestionAnsweredLabel;
    }
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

  bool _showFooter(AgentQuestionAnswer? answered) {
    if (answered != null) {
      return false;
    }
    return widget.allowSkip || _needsContinue;
  }

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
