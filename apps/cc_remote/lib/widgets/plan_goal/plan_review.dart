import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/phone_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

String planStatusLabel(AppLocalizations l10n, PlanDocumentStatus status) =>
    switch (status) {
      PlanDocumentStatus.draft => l10n.mobilePlanDraft,
      PlanDocumentStatus.proposed => l10n.mobilePlanProposed,
      PlanDocumentStatus.approved => l10n.mobilePlanApproved,
      PlanDocumentStatus.rejected => l10n.mobilePlanRejected,
      PlanDocumentStatus.superseded => l10n.mobilePlanSuperseded,
    };

String planMoney(BuildContext context, int cents) =>
    NumberFormat.simpleCurrency(
      locale: Localizations.localeOf(context).toLanguageTag(),
      name: 'USD',
    ).format(cents / 100);

/// Selectable node in a linear reading order (not a miniature graph editor).
class PhonePlanStep extends StatelessWidget {
  const PhonePlanStep({
    super.key,
    required this.node,
    required this.graph,
    required this.position,
    required this.selected,
    this.approved = false,
    required this.canSelect,
    required this.onToggle,
  });

  final PlanNode node;
  final PlanGraph graph;
  final int position;
  final bool selected;
  final bool approved;
  final bool canSelect;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final estimate = node.estimate;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CcCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  NumberFormat.decimalPattern(
                    Localizations.localeOf(context).toLanguageTag(),
                  ).format(position),
                  style: TextStyle(fontSize: 13, color: t.textSecondary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    node.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                ),
              ],
            ),
            if (approved)
              Align(
                alignment: AlignmentDirectional.centerStart,
                child: CcBadge(
                  label: l10n.mobilePlanApproved,
                  variant: CcBadgeVariant.success,
                ),
              ),
            if (canSelect) ...[
              const SizedBox(height: 8),
              CcButton(
                size: CcButtonSize.lg,
                fullWidth: true,
                variant: CcButtonVariant.secondary,
                onPressed: onToggle,
                child: Text(
                  selected ? l10n.mobilePlanSelected : l10n.mobilePlanSelect,
                ),
              ),
            ],
            if (node.description.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              PhoneMarkdown(data: node.description),
            ],
            if (node.dependsOn.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                l10n.mobilePlanDependsOn(
                  node.dependsOn
                      .map((key) => graph.node(key)?.title ?? key)
                      .join(', '),
                ),
                style: TextStyle(fontSize: 12, color: t.textSecondary),
              ),
            ],
            if (estimate?.costCentsHigh != null) ...[
              const SizedBox(height: 8),
              Text(
                l10n.mobilePlanStepCost(
                  planMoney(context, estimate!.costCentsHigh!),
                ),
                style: TextStyle(fontSize: 12, color: t.textSecondary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Reviewable document and the assumptions that led to it.
class PhonePlanDocumentBody extends StatelessWidget {
  const PhonePlanDocumentBody({
    super.key,
    required this.plan,
    required this.selected,
    required this.canSelect,
    this.approvedNodeKeys,
    required this.onToggle,
  });

  final PlanDocument plan;
  final Set<String> selected;
  final bool canSelect;
  final Set<String>? approvedNodeKeys;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          plan.goal,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            CcBadge(
              label: planStatusLabel(l10n, plan.status),
              variant: plan.status == PlanDocumentStatus.proposed
                  ? CcBadgeVariant.warning
                  : CcBadgeVariant.neutral,
            ),
            Text(
              l10n.mobilePlanRevision(
                NumberFormat.decimalPattern(
                  Localizations.localeOf(context).toLanguageTag(),
                ).format(plan.revision),
              ),
              style: TextStyle(fontSize: 12, color: t.textSecondary),
            ),
            Text(
              shortDate(context, plan.updatedAt),
              style: TextStyle(fontSize: 12, color: t.textSecondary),
            ),
          ],
        ),
        if (plan.clarifications.isNotEmpty) ...[
          const SizedBox(height: 24),
          Text(
            l10n.mobilePlanAssumptions,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
          for (final clarification in plan.clarifications) ...[
            const SizedBox(height: 12),
            Text(
              clarification.question,
              style: TextStyle(fontSize: 14, color: t.textPrimary),
            ),
            PhoneMarkdown(data: clarification.answer),
          ],
        ],
        const SizedBox(height: 24),
        Text(
          l10n.mobilePlanSteps,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: t.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        if (plan.graph.nodes.isEmpty)
          Text(l10n.mobilePlanNoSteps, style: TextStyle(color: t.textSecondary))
        else
          for (var i = 0; i < plan.graph.nodes.length; i++)
            PhonePlanStep(
              key: ValueKey(plan.graph.nodes[i].key),
              node: plan.graph.nodes[i],
              graph: plan.graph,
              position: i + 1,
              selected: selected.contains(plan.graph.nodes[i].key),
              approved:
                  approvedNodeKeys?.contains(plan.graph.nodes[i].key) ?? false,
              canSelect:
                  canSelect &&
                  plan.graph.nodes[i].isWork &&
                  (approvedNodeKeys?.contains(plan.graph.nodes[i].key) != true),
              onToggle: () => onToggle(plan.graph.nodes[i].key),
            ),
      ],
    );
  }
}

/// A whole-cent budget typed into [raw], or null when it is not a positive
/// amount. Accepts the locale's digits and decimal mark plus ASCII digits for
/// hardware keyboards; rejects grouping and never rounds a third cent.
int? parsePlanBudgetCents(BuildContext context, String raw) {
  final locale = Localizations.localeOf(context).toLanguageTag();
  final format = NumberFormat.decimalPattern(locale);
  var text = raw.trim();
  for (var digit = 0; digit < 10; digit++) {
    text = text.replaceAll(format.format(digit), '$digit');
  }
  final separator = format.symbols.DECIMAL_SEP;
  if (separator != '.') text = text.replaceAll(separator, '.');
  if (!RegExp(r'^\d{1,7}(?:\.\d{1,2})?$').hasMatch(text)) return null;
  final pieces = text.split('.');
  final dollars = int.parse(pieces.first);
  final cents = pieces.length == 1
      ? 0
      : int.parse(pieces.last.padRight(2, '0'));
  final total = dollars * 100 + cents;
  return total > 0 ? total : null;
}
