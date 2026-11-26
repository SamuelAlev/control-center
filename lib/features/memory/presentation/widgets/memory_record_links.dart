import 'package:cc_domain/core/domain/entities/memory_fact.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/improvement_proposal_view.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_actions.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_fact_row.dart';
import 'package:control_center/features/messaging/presentation/widgets/work/work_text.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// Other facts this record leads to, each one a way into it.
class MemoryFactLinks extends StatelessWidget {
  /// Creates a [MemoryFactLinks].
  const MemoryFactLinks({super.key, required this.label, required this.facts});

  /// How they relate to this record.
  final String label;

  /// The facts.
  final List<MemoryFact> facts;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      label: label,
      count: facts.length,
      padding: EdgeInsets.zero,
      headerPadding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        14,
        AppSpacing.lg,
        0,
      ),
      child: SettingsGroup(
        separator: SettingsGroupSeparator.rule,
        children: [
          for (final fact in facts) MemoryFactRow(fact: fact, deletable: false),
        ],
      ),
    );
  }
}

/// Says a fact has been replaced, and by what when that fact still exists.
class MemoryReplacedNotice extends StatelessWidget {
  /// Creates a [MemoryReplacedNotice].
  const MemoryReplacedNotice({super.key, required this.replacement});

  /// The newer fact.
  final MemoryFact? replacement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final newer = replacement;
    return CcAlert(
      variant: CcAlertVariant.warning,
      title: l10n.supersededTooltip,
      action: newer == null
          ? null
          : CcButton(
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              onPressed: () => openMemoryFact(context, newer),
              child: Text(l10n.openLabel),
            ),
    );
  }
}

/// Accepted improvement proposals that authored or updated a fact or policy,
/// each opening its proposal page under Memory settings.
class MemoryImprovementLinks extends StatelessWidget {
  /// Creates a [MemoryImprovementLinks].
  const MemoryImprovementLinks({
    super.key,
    required this.label,
    required this.proposals,
  });

  /// How they relate to this record.
  final String label;

  /// The proposals.
  final List<ImprovementProposalView> proposals;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final caption = CcTypography.caption.copyWith(color: t.textTertiary);
    return SectionCard(
      label: label,
      count: proposals.length,
      padding: EdgeInsets.zero,
      headerPadding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.lg,
        14,
        AppSpacing.lg,
        0,
      ),
      child: SettingsGroup(
        separator: SettingsGroupSeparator.rule,
        children: [
          for (final ImprovementProposalView(proposal: p) in proposals)
            SettingsEntityRow(
              icon: AppIcons.lightbulb,
              title: inertText(p.change, singleLine: true),
              meta: [
                AppTimestamp.relative(p.decidedAt ?? p.createdAt, style: caption),
              ],
              onPressed: () =>
                  GoRouter.of(context).go(memoryImprovementRoute(p.workspaceId, p.id)),
            ),
        ],
      ),
    );
  }
}
