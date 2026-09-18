import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Phone-sized structured question: numbered options, optional free text,
/// skip, and Continue for multi-select / typed answers.
///
/// Single-select submits on tap (there is no hover on a phone). Matches the
/// desktop [AskUserCard] contract so a question answered here unblocks the
/// same agent.
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

  /// Overrides the default "Question for you" caption.
  final String? caption;

  /// Extra content between the question and the options (a command block).
  final Widget? extraBody;

  /// When non-null the card is a read-only result.
  final AgentQuestionAnswer? answered;

  /// In-flight submit.
  final bool submitting;

  /// Called with the chosen answer or a skip.
  final ValueChanged<AgentQuestionAnswer>? onSubmit;

  @override
  State<AskUserCard> createState() => _AskUserCardState();
}

class _AskUserCardState extends State<AskUserCard> {
  final Set<int> _selected = {};
  final TextEditingController _freeText = TextEditingController();

  bool get _interactive => widget.answered == null && !widget.submitting;

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
    final answered = widget.answered;
    if (answered != null) {
      for (var i = 0; i < widget.options.length; i++) {
        final option = widget.options[i];
        if (answered.selectedLabels.contains(option.label) ||
            answered.selectedLabels.contains(option.effectiveValue)) {
          _selected.add(i);
        }
      }
      if ((answered.freeText ?? '').isNotEmpty) {
        _freeText.text = answered.freeText!;
      }
    }
  }

  @override
  void dispose() {
    _freeText.dispose();
    super.dispose();
  }

  void _activate(int index) {
    if (!_interactive) {
      return;
    }
    if (widget.multiSelect) {
      setState(() {
        if (!_selected.add(index)) {
          _selected.remove(index);
        }
      });
      return;
    }
    widget.onSubmit?.call(
      AgentQuestionAnswer(
        selectedLabels: [widget.options[index].effectiveValue],
        freeText: widget.allowFreeText && _typed.isNotEmpty ? _typed : null,
      ),
    );
  }

  void _continue() {
    if (!_canSubmit) {
      return;
    }
    widget.onSubmit?.call(
      AgentQuestionAnswer(
        selectedLabels: [
          for (final i in _selected)
            if (i >= 0 && i < widget.options.length)
              widget.options[i].effectiveValue,
        ],
        freeText: widget.allowFreeText && _typed.isNotEmpty ? _typed : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final answered = widget.answered;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bgPrimary,
        border: Border.all(color: t.borderPrimary),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _caption(l10n, answered),
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
            const SizedBox(height: 8),
            Text(
              widget.question,
              style: CcTypography.title.copyWith(color: t.textPrimary),
            ),
            if ((widget.contextText ?? '').isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                widget.contextText!,
                style: CcTypography.body.copyWith(color: t.textSecondary),
              ),
            ],
            if (widget.extraBody != null) ...[
              const SizedBox(height: 12),
              widget.extraBody!,
            ],
            const SizedBox(height: 12),
            for (var i = 0; i < widget.options.length; i++)
              _option(t, i, widget.options[i]),
            if (widget.allowFreeText) ...[
              const SizedBox(height: 8),
              CcTextField(
                controller: _freeText,
                enabled: _interactive,
                hintText: l10n.agentQuestionFreeformHint,
                onChanged: (_) => setState(() {}),
                onSubmitted: _interactive && _typed.isNotEmpty
                    ? (_) => widget.multiSelect
                          ? _continue()
                          : widget.onSubmit?.call(
                              AgentQuestionAnswer(freeText: _typed),
                            )
                    : null,
              ),
            ],
            if (answered == null && (widget.allowSkip || _needsContinue)) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (widget.allowSkip)
                    CcButton(
                      variant: CcButtonVariant.ghost,
                      size: CcButtonSize.sm,
                      onPressed: _interactive
                          ? () => widget.onSubmit?.call(
                              const AgentQuestionAnswer(skipped: true),
                            )
                          : null,
                      trailing: const Icon(AppIcons.arrowRight, size: 14),
                      child: Text(l10n.agentQuestionSkip),
                    ),
                  if (_needsContinue) ...[
                    const SizedBox(width: 8),
                    CcButton(
                      variant: _canSubmit
                          ? CcButtonVariant.primary
                          : CcButtonVariant.secondary,
                      size: CcButtonSize.sm,
                      loading: widget.submitting,
                      onPressed: _canSubmit ? _continue : null,
                      child: Text(l10n.continueLabel),
                    ),
                  ],
                ],
              ),
            ],
          ],
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
    return widget.caption ?? l10n.agentQuestionHeader;
  }

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
