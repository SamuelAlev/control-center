part of 'skill_evaluation_panel.dart';

/// Open Quality beside the primary action, in the editor header's order.
class _EvaluationActions extends StatelessWidget {
  const _EvaluationActions({
    required this.readOnly,
    required this.onOpenQuality,
    required this.onStart,
  });

  final bool readOnly;
  final VoidCallback onOpenQuality;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final start = CcButton(
      size: CcButtonSize.sm,
      onPressed: onStart,
      child: Text(l.skillEvalStart),
    );
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        CcButton(
          size: CcButtonSize.sm,
          variant: CcButtonVariant.secondary,
          onPressed: onOpenQuality,
          child: Text(l.skillEvalOpenQuality),
        ),
        if (readOnly)
          CcTooltip(message: l.demoReadOnlySave, child: start)
        else
          start,
      ],
    );
  }
}

/// What the server knows about the installed revision's behavior.
class _EvidenceSummary extends StatelessWidget {
  const _EvidenceSummary({required this.latest});

  /// The newest campaign for the installed revision. Null when every campaign
  /// evaluated an older revision, so the evidence no longer applies.
  final SkillCampaignView? latest;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final campaign = latest;
    if (campaign == null) {
      return SettingsSummary(
        facts: [
          SettingsFact(
            label: l.statusLabel,
            value: l.skillEvalStale,
            tone: CcStatusTone.caution,
            mono: false,
          ),
        ],
      );
    }
    return SettingsSummary(
      facts: [
        SettingsFact(
          label: l.statusLabel,
          value: _evidenceStatus(l, campaign),
          tone: _evidenceTone(campaign),
          mono: false,
        ),
        SettingsFact(
          label: l.skillEvalProgressLabel,
          value: l.skillEvalProgress(
            campaign.completedAttempts,
            campaign.plannedAttempts,
          ),
        ),
        SettingsFact(label: l.modelLabel, value: campaign.modelId),
        SettingsFact(
          label: l.skillEvalCorpus,
          value: l.skillEvalCoverage(campaign.corpusId, campaign.repetitions),
          mono: false,
        ),
      ],
    );
  }
}

/// Why the policy switch cannot turn on yet.
class _PolicyHint extends StatelessWidget {
  const _PolicyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Text(
      text,
      style: CcTypography.caption.copyWith(color: t.textSecondary),
    );
  }
}

/// The latest campaigns across revisions; each row opens its Quality report.
class _RevisionHistory extends StatelessWidget {
  const _RevisionHistory({required this.campaigns, required this.onOpen});

  static const _maxRows = 8;
  static const _shortHashLength = 12;

  final List<SkillCampaignView> campaigns;
  final ValueChanged<String> onOpen;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    return SettingsGroup(
      showRule: true,
      title: l.skillEvalHistory,
      separator: SettingsGroupSeparator.rule,
      children: [
        for (final c in campaigns.take(_maxRows))
          SettingsEntityRow(
            key: ValueKey(c.id),
            title: c.modelId,
            tone: _evidenceTone(c),
            // The full partial-evidence sentence is too long for a row's tag.
            statusLabel: c.staleReason == null && _isPartial(c)
                ? l.skillEvalIncomplete
                : _evidenceStatus(l, c),
            subtitleWidget: Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xxs,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SettingsMetaFact(
                  value: c.skillHash.length > _shortHashLength
                      ? c.skillHash.substring(0, _shortHashLength)
                      : c.skillHash,
                ),
                AppTimestamp.relative(c.createdAt),
              ],
            ),
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
            onPressed: () => onOpen(c.id),
          ),
      ],
    );
  }
}
