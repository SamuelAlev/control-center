import 'dart:async';

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
///
/// The card is only ever a live form: once a question is resolved its caller
/// swaps it for an `AskUserSummary`. When the asker stops waiting at
/// [expiresAt], a bar along the top edge drains over [timeout] and
/// [onExpired] fires as it empties.
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
    this.submitting = false,
    this.onSubmit,
    this.expiresAt,
    this.timeout,
    this.onExpired,
    this.now = DateTime.now,
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

  /// In-flight submit (disables the form).
  final bool submitting;

  /// Called with the chosen answer or a skip.
  final ValueChanged<AgentQuestionAnswer>? onSubmit;

  /// When the asker stops waiting. Null hides the countdown.
  final DateTime? expiresAt;

  /// The full wait ending at [expiresAt]; the countdown's 100% mark.
  final Duration? timeout;

  /// Called once when [expiresAt] passes while the card is mounted.
  final VoidCallback? onExpired;

  /// The countdown's clock. Tests pass one they can advance.
  final DateTime Function() now;

  @override
  State<AskUserCard> createState() => _AskUserCardState();
}

class _AskUserCardState extends State<AskUserCard> {
  final Set<int> _selected = {};
  final TextEditingController _freeText = TextEditingController();
  final FocusNode _textFocus = FocusNode();
  final FocusNode _cardFocus = FocusNode();

  Timer? _countdown;

  bool get _interactive => !widget.submitting;

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
    _freeText.addListener(_rebuild);
    _textFocus.addListener(_rebuild);
    _syncCountdown();
  }

  @override
  void didUpdateWidget(AskUserCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expiresAt != widget.expiresAt) {
      _syncCountdown();
    }
  }

  /// Whole seconds are plenty: the bar eases between ticks, and a long wait
  /// moves well under a pixel per second.
  void _syncCountdown() {
    _countdown?.cancel();
    _countdown = null;
    if (widget.expiresAt == null) {
      return;
    }
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    final expiresAt = widget.expiresAt;
    if (!mounted || expiresAt == null) {
      return;
    }
    if (!widget.now().isBefore(expiresAt)) {
      _countdown?.cancel();
      _countdown = null;
      widget.onExpired?.call();
    }
    setState(() {});
  }

  /// Share of the wait still left, or null when there is no countdown.
  double? get _remainingFraction {
    final expiresAt = widget.expiresAt;
    final total = widget.timeout;
    if (expiresAt == null || total == null || total <= Duration.zero) {
      return null;
    }
    final left = expiresAt.difference(widget.now());
    return (left.inMilliseconds / total.inMilliseconds).clamp(0.0, 1.0);
  }

  void _rebuild() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _countdown?.cancel();
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
    final remaining = _remainingFraction;

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
              Padding(
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
                    Text(
                      widget.question,
                      style: CcTypography.title.copyWith(color: t.textPrimary),
                    ),
                    if ((widget.contextText ?? '').isNotEmpty) ...[
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
            ],
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
