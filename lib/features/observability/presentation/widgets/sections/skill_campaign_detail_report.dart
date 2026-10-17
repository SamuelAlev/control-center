part of 'skill_campaign_detail.dart';

class _CampaignReport extends StatelessWidget {
  const _CampaignReport({
    required this.report,
    required this.settledEvidence,
    required this.percent,
    required this.number,
    required this.money,
  });

  final Map<String, dynamic>? report;
  final bool settledEvidence;
  final NumberFormat percent, number, money;

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final report = this.report;
    final outcomes = _records(report?['taskOutcomes']);
    final regressions = _records(report?['regressions']);
    final verdicts = _records(report?['verdicts']);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (report == null)
          Text(
            l.skillEvalNoReport,
            style: CcTypography.bodySm.copyWith(color: t.textSecondary),
          )
        else ...[
          Text(
            l.skillEvalReport,
            style: CcTypography.label.copyWith(color: t.textPrimary),
          ),
          Text(
            settledEvidence ? l.skillEvalCoverageComplete : l.skillEvalPartial,
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
          if (verdicts.isEmpty)
            Text(
              '${l.skillEvalVerdict}: ${l.skillEvalUnknown}',
              style: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
          for (final v in verdicts) ...[
            Text(
              '${l.skillEvalVerdict}: ${settledEvidence ? _verdict(l, v['verdict']) : l.skillEvalInconclusive} · '
              '${l.skillEvalUncertainty}: ${_percent(percent, settledEvidence ? v['lowerBound'] : null, l.skillEvalUnknown)} – '
              '${_percent(percent, settledEvidence ? v['upperBound'] : null, l.skillEvalUnknown)} '
              '(${_count(number, v['pairs'], l.skillEvalUnknown)}/${_count(number, v['expectedPairs'], l.skillEvalUnknown)})',
              style: CcTypography.bodySm.copyWith(color: t.textPrimary),
            ),
            if (v['effectiveTaskCount'] is num)
              Text(
                l.skillEvalTaskClusters(
                  _count(number, v['effectiveTaskCount'], l.skillEvalUnknown),
                ),
                style: CcTypography.caption.copyWith(color: t.textSecondary),
              ),
          ],
          for (final unknown in (report['unknowns'] as List? ?? const []))
            Text(
              '${l.skillEvalUnknown}: $unknown',
              style: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
          for (final violation
              in (report['planViolations'] as List? ?? const []))
            Text(
              '${l.skillEvalPlanViolation}: $violation',
              style: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
          if (report['skillBehavior'] is Map)
            SkillBehaviorSummary(
              behavior: (report['skillBehavior'] as Map)
                  .cast<String, dynamic>(),
            ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l.skillEvalTasks,
            style: CcTypography.label.copyWith(color: t.textPrimary),
          ),
          if (outcomes.isEmpty) Text(l.skillEvalNoTasks),
          for (final taskId in {for (final task in outcomes) task['taskId']})
            _TaskGroup(
              taskId: '$taskId',
              outcomes: outcomes
                  .where((row) => row['taskId'] == taskId)
                  .toList(),
              regression: settledEvidence
                  ? regressions
                        .where((row) => row['taskId'] == taskId)
                        .firstOrNull
                  : null,
              percent: percent,
              money: money,
              number: number,
              settled: settledEvidence,
            ),
        ],
      ],
    );
  }
}

List<Map<String, dynamic>> _records(Object? value) => [
  for (final row in value is List ? value : const [])
    if (row is Map) row.cast<String, dynamic>(),
];

String _percent(NumberFormat format, Object? value, String unknown) =>
    value is num && value.isFinite ? format.format(value) : unknown;
String _count(NumberFormat format, Object? value, String unknown) =>
    value is num && value.isFinite ? format.format(value) : unknown;

String _comparison(AppLocalizations l, SkillCampaignComparison comparison) =>
    switch (comparison) {
      SkillCampaignComparison.absent => l.skillEvalAbsent,
      SkillCampaignComparison.previous => l.skillEvalPrevious,
      SkillCampaignComparison.forced => l.skillEvalForced,
      SkillCampaignComparison.composition => l.skillEvalComposition,
    };

String _campaignStatus(AppLocalizations l, SkillCampaignStatus status) =>
    switch (status) {
      SkillCampaignStatus.queued => l.skillEvalQueued,
      SkillCampaignStatus.running => l.skillEvalRunning,
      SkillCampaignStatus.cancelling => l.skillEvalCancelling,
      SkillCampaignStatus.cancelled => l.skillEvalCancelled,
      SkillCampaignStatus.completed => l.skillEvalCompleted,
      SkillCampaignStatus.failed => l.skillEvalFailed,
      SkillCampaignStatus.interrupted => l.skillEvalInterrupted,
    };

String _verdict(AppLocalizations l, Object? verdict) => switch (verdict) {
  'superior' => l.skillEvalImproved,
  'non_inferior' => l.skillEvalPreserved,
  'inferior' => l.skillEvalRegressed,
  _ => l.skillEvalInconclusive,
};

class _TaskGroup extends StatelessWidget {
  const _TaskGroup({
    required this.taskId,
    required this.outcomes,
    required this.regression,
    required this.percent,
    required this.money,
    required this.number,
    required this.settled,
  });
  final String taskId;
  final List<Map<String, dynamic>> outcomes;
  final Map<String, dynamic>? regression;
  final NumberFormat percent, money, number;
  final bool settled;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 320),
                child: Text(
                  taskId,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textDirection: ui.TextDirection.ltr,
                  style: CcTypography.label.copyWith(color: t.textPrimary),
                ),
              ),
              if (regression != null)
                CcStatusTag(
                  label: switch (regression!['kind']) {
                    'quality_loss' => l.skillEvalRegressed,
                    'cost_regression' => l.skillEvalCostRegression,
                    'harness_error' => l.skillEvalHarnessError,
                    _ => l.skillEvalUnknown,
                  },
                  tone: CcStatusTone.negative,
                  dot: false,
                ),
            ],
          ),
          for (final task in outcomes)
            _TaskLine(
              task: task,
              percent: percent,
              money: money,
              number: number,
              settled: settled,
            ),
        ],
      ),
    );
  }
}

class _TaskLine extends StatelessWidget {
  const _TaskLine({
    required this.task,
    required this.percent,
    required this.money,
    required this.number,
    required this.settled,
  });
  final Map<String, dynamic> task;
  final NumberFormat percent, money, number;
  final bool settled;
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final attempts = task['attempts'] as num?;
    final passes = task['verifiedSuccesses'] as num?;
    final rate = settled && attempts != null && attempts > 0 && passes != null
        ? _percent(percent, passes / attempts, l.skillEvalUnknown)
        : l.skillEvalUnknown;
    final cost = task['totalCostMicros'] is num
        ? money.format((task['totalCostMicros'] as num) / 1000000)
        : l.skillEvalUnknown;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Wrap(
        spacing: AppSpacing.sm,
        runSpacing: AppSpacing.xs,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 320),
            child: Text(
              '${task['armId'] ?? l.skillEvalUnknown}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textDirection: ui.TextDirection.ltr,
              style: CcTypography.bodySm.copyWith(color: t.textPrimary),
            ),
          ),
          Text(
            l.skillEvalTaskEvidence(
              rate,
              passes == null || attempts == null
                  ? l.skillEvalUnknown
                  : '${_count(number, passes, l.skillEvalUnknown)}/${_count(number, attempts, l.skillEvalUnknown)}',
              cost,
            ),
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
          Text(
            '${l.skillEvalUncertainty}: ${l.skillEvalUnknown}',
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
        ],
      ),
    );
  }
}
