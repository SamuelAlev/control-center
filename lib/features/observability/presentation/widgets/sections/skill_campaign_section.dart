import 'package:cc_data/cc_data.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/features/observability/presentation/widgets/sections/skill_campaign_detail.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_error.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

/// Workspace-wide full snapshots; independent from the legacy suite list.
class SkillCampaignSection extends ConsumerWidget {
  /// Lists campaigns for the active workspace and follows campaign deep links.
  const SkillCampaignSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l = AppLocalizations.of(context);
    final workspace = ref.watch(activeWorkspaceIdProvider);
    if (workspace == null) {
      return Text(l.skillEvalNoWorkspace);
    }
    final scope = (workspaceId: workspace, skillKey: null as String?);
    final campaigns = ref.watch(skillCampaignsProvider(scope));
    final t = context.designSystem ?? DesignSystemTokens.light();
    final linkedId = GoRouterState.of(context).uri.queryParameters['campaign'];
    return ObsSection(
      title: l.skillEvalTitle,
      icon: AppIcons.scanSearch,
      subtitle: l.skillEvalQualityIntro,
      trailing: CcButton(
        size: CcButtonSize.sm,
        variant: CcButtonVariant.secondary,
        onPressed: () => ref.invalidate(skillCampaignsProvider(scope)),
        child: Text(l.skillEvalRefresh),
      ),
      child: campaigns.when(
        loading: () => const CcSpinner(),
        error: (error, _) => Text(skillCampaignError(l, error)),
        data: (items) => items.isEmpty
            ? Text(
                l.skillEvalNotEvaluated,
                style: CcTypography.bodySm.copyWith(color: t.textSecondary),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item
                      in (items.toList()..sort(
                        (a, b) => b.createdAt.compareTo(a.createdAt),
                      ))) ...[
                    _CampaignRow(
                      key: ValueKey(item.id),
                      campaign: item,
                      linked: linkedId == item.id,
                    ),
                    const CcDivider(),
                  ],
                ],
              ),
      ),
    );
  }
}

class _CampaignRow extends StatefulWidget {
  const _CampaignRow({required this.campaign, required this.linked, super.key});
  final SkillCampaignView campaign;
  final bool linked;
  @override
  State<_CampaignRow> createState() => _CampaignRowState();
}

class _CampaignRowState extends State<_CampaignRow> {
  bool? _expanded;
  @override
  Widget build(BuildContext context) {
    final c = widget.campaign;
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final expanded = _expanded ?? widget.linked;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        CcButton(
          variant: CcButtonVariant.ghost,
          onPressed: () => setState(() => _expanded = !expanded),
          child: Align(
            alignment: AlignmentDirectional.centerStart,
            child: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(
                  c.skillSlug,
                  style: CcTypography.label.copyWith(color: t.textPrimary),
                ),
                CcStatusTag(
                  label: skillCampaignStatusLabel(l, c.status),
                  tone: skillCampaignStatusTone(c.status),
                  dot: false,
                ),
                Text(
                  '${c.completedAttempts}/${c.plannedAttempts} · ${c.modelId}',
                  style: CcTypography.caption.copyWith(color: t.textSecondary),
                ),
                Text(
                  DateFormat.yMd(
                    Localizations.localeOf(context).toString(),
                  ).add_Hm().format(c.createdAt.toLocal()),
                  style: CcTypography.caption.copyWith(color: t.textSecondary),
                ),
                if (c.staleReason != null)
                  CcStatusTag(
                    label: l.skillEvalStale,
                    tone: CcStatusTone.caution,
                    dot: false,
                  ),
              ],
            ),
          ),
        ),
        if (expanded)
          Padding(
            padding: const EdgeInsetsDirectional.only(
              start: AppSpacing.sm,
              bottom: AppSpacing.md,
            ),
            child: SkillCampaignDetail(
              workspaceId: c.workspaceId,
              campaignId: c.id,
              initial: c,
            ),
          ),
      ],
    );
  }
}

/// Localized lifecycle label, independent of the campaign's evidence verdict.
String skillCampaignStatusLabel(
  AppLocalizations l,
  SkillCampaignStatus status,
) => switch (status) {
  SkillCampaignStatus.queued => l.skillEvalQueued,
  SkillCampaignStatus.running => l.skillEvalRunning,
  SkillCampaignStatus.cancelling => l.skillEvalCancelling,
  SkillCampaignStatus.cancelled => l.skillEvalCancelled,
  SkillCampaignStatus.completed => l.skillEvalCompleted,
  SkillCampaignStatus.failed => l.skillEvalFailed,
  SkillCampaignStatus.interrupted => l.skillEvalInterrupted,
};

/// Visual tone for a run's lifecycle rather than its evaluation quality.
CcStatusTone skillCampaignStatusTone(SkillCampaignStatus status) =>
    switch (status) {
      SkillCampaignStatus.queued ||
      SkillCampaignStatus.cancelling => CcStatusTone.neutral,
      SkillCampaignStatus.running => CcStatusTone.info,
      SkillCampaignStatus.completed => CcStatusTone.positive,
      SkillCampaignStatus.failed ||
      SkillCampaignStatus.interrupted => CcStatusTone.negative,
      SkillCampaignStatus.cancelled => CcStatusTone.caution,
    };
