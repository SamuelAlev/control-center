import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/ports/agent_question_port.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Renders an agent's `user_question` message as an interactive form: the
/// question, optional context, single/multi-select choices, and an optional
/// free-text field. On submit the answer is handed back to the blocked agent
/// via [AgentQuestionPort]. Once answered, it collapses to a read-only result.
class QuestionBubble extends ConsumerStatefulWidget {
  /// Creates a [QuestionBubble].
  const QuestionBubble({super.key, required this.message});

  /// The `user_question` channel message.
  final ChannelMessage message;

  @override
  ConsumerState<QuestionBubble> createState() => _QuestionBubbleState();
}

class _QuestionBubbleState extends ConsumerState<QuestionBubble> {
  final Set<int> _selected = {};
  final TextEditingController _freeText = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _freeText.dispose();
    super.dispose();
  }

  Map<String, dynamic> get _meta => widget.message.metadata ?? const {};

  String get _question =>
      (_meta['question'] as String?) ?? widget.message.content;

  List<AgentQuestionOption> get _options {
    final raw = _meta['options'];
    if (raw is! List) {
      return const [];
    }
    return [
      for (final o in raw)
        if (o is Map) AgentQuestionOption.fromJson(o.cast<String, dynamic>()),
    ];
  }

  bool get _allowFreeText => _meta['allowFreeText'] == true;
  bool get _multiSelect => _meta['multiSelect'] == true;

  bool get _canSubmit {
    if (_submitting) {
      return false;
    }
    if (_selected.isNotEmpty) {
      return true;
    }
    return _allowFreeText && _freeText.text.trim().isNotEmpty;
  }

  Future<void> _submit() async {
    final options = _options;
    final labels = _selected
        .map((i) => i >= 0 && i < options.length ? options[i].label : null)
        .whereType<String>()
        .toList();
    final text = _freeText.text.trim();
    final answer = AgentQuestionAnswer(
      selectedLabels: labels,
      freeText: _allowFreeText && text.isNotEmpty ? text : null,
    );
    setState(() => _submitting = true);
    try {
      await ref
          .read(agentQuestionServiceProvider)
          .submitAnswer(widget.message, answer);
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tokens = resolveTokens(context);
    final l10n = AppLocalizations.of(context);
    final answered = widget.message.isQuestionAnswered;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: tokens.bgPrimary,
          borderRadius: BorderRadius.circular(bubbleRadius),
          border: Border.all(color: tokens.borderSecondary),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(bubbleRadius),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              _header(theme, tokens, l10n, answered: answered),
              Padding(
                padding: bubblePadding,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _question,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: tokens.textPrimary,
                        fontWeight: FontWeight.w600,
                        height: bodyLineHeight,
                      ),
                    ),
                    if ((_meta['context'] as String?)?.isNotEmpty ?? false) ...[
                      const SizedBox(height: 4),
                      Text(
                        _meta['context'] as String,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.textTertiary,
                          height: bodyLineHeight,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    if (answered)
                      _answeredView(theme, tokens, l10n)
                    else
                      _form(theme, tokens, l10n),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(
    ThemeData theme,
    DesignSystemTokens tokens,
    AppLocalizations l10n, {
    required bool answered,
  }) {
    final accent = tokens.textBrandPrimary;
    final bg = tokens.accentSoft;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: tokens.borderSecondary)),
      ),
      child: Row(
        children: [
          Icon(
            answered ? LucideIcons.circleCheck : LucideIcons.messageCircleQuestion,
            size: 14,
            color: accent,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              answered ? l10n.agentQuestionAnsweredLabel : l10n.agentQuestionHeader,
              style: theme.textTheme.labelSmall?.copyWith(
                color: accent,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.6,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _form(
    ThemeData theme,
    DesignSystemTokens tokens,
    AppLocalizations l10n,
  ) {
    final options = _options;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < options.length; i++)
          _optionTile(theme, tokens, options[i], i),
        if (_allowFreeText) ...[
          const SizedBox(height: 8),
          TextField(
            controller: _freeText,
            enabled: !_submitting,
            minLines: 1,
            maxLines: 4,
            onChanged: (_) => setState(() {}),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: tokens.textPrimary,
            ),
            decoration: InputDecoration(
              isDense: true,
              hintText: l10n.agentQuestionFreeformHint,
              border: const OutlineInputBorder(
                borderRadius: AppRadii.brSm,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _canSubmit ? _submit : null,
            icon: _submitting
                ? const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 1.5),
                  )
                : const Icon(LucideIcons.send, size: 16),
            label: Text(l10n.agentQuestionSubmit),
          ),
        ),
      ],
    );
  }

  Widget _optionTile(
    ThemeData theme,
    DesignSystemTokens tokens,
    AgentQuestionOption option,
    int index,
  ) {
    final selected = _selected.contains(index);
    final subtitle = option.description;
    void toggle() {
      if (_submitting) {
        return;
      }
      setState(() {
        if (_multiSelect) {
          if (selected) {
            _selected.remove(index);
          } else {
            _selected.add(index);
          }
        } else {
          _selected
            ..clear()
            ..add(index);
        }
      });
    }

    return InkWell(
      onTap: toggle,
      borderRadius: AppRadii.brSm,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              _multiSelect
                  ? (selected
                      ? LucideIcons.squareCheck
                      : LucideIcons.square)
                  : (selected
                      ? LucideIcons.circleDot
                      : LucideIcons.circle),
              size: 18,
              color: selected ? tokens.textBrandPrimary : tokens.textQuaternary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: tokens.textPrimary,
                    ),
                  ),
                  if (subtitle != null && subtitle.isNotEmpty)
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: tokens.textTertiary,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _answeredView(
    ThemeData theme,
    DesignSystemTokens tokens,
    AppLocalizations l10n,
  ) {
    final raw = _meta['answer'];
    final answer = raw is Map
        ? AgentQuestionAnswer.fromJson(raw.cast<String, dynamic>())
        : const AgentQuestionAnswer();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: AppRadii.brSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n.agentQuestionAnswerLabel,
            style: theme.textTheme.labelSmall?.copyWith(
              color: tokens.textQuaternary,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.4,
            ),
          ),
          const SizedBox(height: 4),
          if (answer.selectedLabels.isNotEmpty)
            Text(
              answer.selectedLabels.join(', '),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          if ((answer.freeText ?? '').isNotEmpty) ...[
            if (answer.selectedLabels.isNotEmpty) const SizedBox(height: 4),
            Text(
              answer.freeText!,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: tokens.textPrimary,
                height: bodyLineHeight,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
