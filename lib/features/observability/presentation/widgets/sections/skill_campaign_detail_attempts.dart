part of 'skill_campaign_detail.dart';

class _CampaignAttempts extends StatelessWidget {
  const _CampaignAttempts({
    required this.attempts,
    required this.workspaceId,
    required this.campaignId,
    required this.attemptId,
    required this.refreshEpoch,
    required this.onSelectAttempt,
  });

  final AsyncValue<List<SkillAttemptView>> attempts;
  final String workspaceId, campaignId;
  final String? attemptId;
  final int refreshEpoch;
  final ValueChanged<String> onSelectAttempt;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l.skillEvalAttempts,
          style: CcTypography.label.copyWith(color: t.textPrimary),
        ),
        attempts.when(
          loading: () => const CcSpinner(),
          error: (error, _) => Text(skillCampaignError(l, error)),
          data: (list) => list.isEmpty
              ? Text(l.skillEvalNoAttempts)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: [
                        for (final a in list)
                          CcChip(
                            label: l.skillEvalAttempt(
                              a.taskId,
                              a.armId,
                              a.repetition + 1,
                            ),
                            selected: (attemptId ?? list.first.id) == a.id,
                            onPressed: () => onSelectAttempt(a.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SkillAttemptTimeline(
                      workspaceId: workspaceId,
                      campaignId: campaignId,
                      attemptId: list.any((a) => a.id == attemptId)
                          ? attemptId!
                          : list.first.id,
                      refreshEpoch: refreshEpoch,
                    ),
                  ],
                ),
        ),
      ],
    );
  }
}
