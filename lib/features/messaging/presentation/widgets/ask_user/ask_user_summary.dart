import 'package:cc_domain/core/domain/ports/agent_question_port.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// What a resolved `AskUserCard` collapses to in the conversation: the
/// question, then the choice and note the agent received — or that the
/// question was skipped or timed out.
class AskUserSummary extends StatelessWidget {
  /// Creates an [AskUserSummary].
  const AskUserSummary({
    super.key,
    required this.question,
    this.options = const [],
    this.answer,
    this.expired = false,
  });

  /// The question, as asked.
  final String question;

  /// The offered choices, so a stored value reads back as its label.
  final List<AgentQuestionOption> options;

  /// What the user submitted. Null with [expired] when nobody answered.
  final AgentQuestionAnswer? answer;

  /// Whether the asker stopped waiting before an answer arrived.
  final bool expired;

  List<String> get _chosen {
    final selected = answer?.selectedLabels ?? const <String>[];
    return [
      for (final value in selected)
        options
                .where((o) => o.effectiveValue == value || o.label == value)
                .firstOrNull
                ?.label ??
            value,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final answer = this.answer;
    final note = answer?.freeText?.trim() ?? '';
    final chosen = _chosen;

    final String? status = switch (answer) {
      _ when expired && answer == null => l10n.agentQuestionTimedOutLabel,
      AgentQuestionAnswer(skipped: true) => l10n.agentQuestionSkippedLabel,
      final a? when a.isEmpty => l10n.agentQuestionAnsweredLabel,
      _ => null,
    };

    return DecoratedBox(
      key: const ValueKey('ask-user-summary'),
      decoration: BoxDecoration(
        color: t.bgPrimary,
        border: Border.all(color: t.borderSecondary),
      ),
      child: Padding(
        padding: const EdgeInsetsDirectional.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsetsDirectional.only(top: 2),
              child: Icon(
                AppIcons.messageCircleQuestion,
                size: 14,
                color: t.textTertiary,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    question,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: CcTypography.bodySm.copyWith(color: t.textSecondary),
                  ),
                  const SizedBox(height: AppSpacing.xxs),
                  if (status != null)
                    Text(
                      status,
                      style: CcTypography.bodySm.copyWith(
                        color: t.textTertiary,
                      ),
                    ),
                  if (chosen.isNotEmpty)
                    Text(
                      chosen.join(', '),
                      style: CcTypography.body.copyWith(
                        color: t.textPrimary,
                        fontWeight: CcTypography.semiboldWeight,
                      ),
                    ),
                  if (note.isNotEmpty)
                    Text(
                      note,
                      style: CcTypography.body.copyWith(
                        color: chosen.isEmpty ? t.textPrimary : t.textSecondary,
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
}
