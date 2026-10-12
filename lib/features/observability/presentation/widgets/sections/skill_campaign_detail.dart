import 'dart:ui' as ui;

import 'package:cc_data/cc_data.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/widgets/sections/skill_attempt_timeline.dart';
import 'package:control_center/features/observability/presentation/widgets/sections/skill_behavior_summary.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_providers.dart';
import 'package:control_center/shared/skill_evaluation/skill_campaign_error.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

/// Live campaign evidence; partial and stale runs are never presented as verdicts.
class SkillCampaignDetail extends ConsumerStatefulWidget {
  const SkillCampaignDetail({
    required this.workspaceId,
    required this.campaignId,
    required this.initial,
    super.key,
  });
  final String workspaceId, campaignId;
  final SkillCampaignView initial;
  @override
  ConsumerState<SkillCampaignDetail> createState() =>
      _SkillCampaignDetailState();
}

class _SkillCampaignDetailState extends ConsumerState<SkillCampaignDetail> {
  bool _busy = false;
  Object? _error;
  String? _attemptId;
  int _refreshEpoch = 0;

  Future<void> _cancel() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref
          .read(skillCampaignClientProvider)
          .cancelCampaign(widget.workspaceId, widget.campaignId);
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _export() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final bundle = await ref
          .read(skillCampaignClientProvider)
          .exportCampaign(widget.workspaceId, widget.campaignId);
      await Clipboard.setData(ClipboardData(text: bundle.content));
      if (mounted)
        CcToastScope.maybeOf(context)?.show(
          AppLocalizations.of(context).skillEvalExportCopied(bundle.filename),
          variant: CcToastVariant.success,
        );
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final snapshotScope = (
      workspaceId: widget.workspaceId,
      campaignId: widget.campaignId,
    );
    final snapshot = ref.watch(skillCampaignProvider(snapshotScope));
    if (isSkillCampaignDenied(snapshot.error)) {
      return Text(skillCampaignError(l, snapshot.error!));
    }
    if (snapshot.asData != null && snapshot.asData!.value == null) {
      return Text(l.skillEvalUnavailable(l.skillEvalUnknown));
    }
    final c = snapshot.asData?.value ?? widget.initial;
    final report = c.report;
    final settledEvidence =
        c.status == SkillCampaignStatus.completed &&
        c.staleReason == null &&
        report?['coverageComplete'] == true;
    final percent = NumberFormat.percentPattern(
      Localizations.localeOf(context).toString(),
    );
    final number = NumberFormat.decimalPattern(
      Localizations.localeOf(context).toString(),
    );
    final money = NumberFormat.currency(
      locale: Localizations.localeOf(context).toString(),
      symbol: r'$',
      decimalDigits: 4,
    );
    final outcomes = _records(report?['taskOutcomes']);
    final regressions = _records(report?['regressions']);
    final verdicts = _records(report?['verdicts']);
    final attempts = ref.watch(skillAttemptsProvider(snapshotScope));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          '${c.skillSlug} · ${_comparison(l, c.comparison)} · '
          '${c.adapter == 'claude-cli' ? l.guardrailAdapterClaudeCli : l.guardrailAdapterHarness} · ${c.modelId}',
          style: CcTypography.bodySm.copyWith(color: t.textPrimary),
        ),
        Text(
          c.staleReason != null
              ? l.skillEvalStale
              : c.status == SkillCampaignStatus.completed && !settledEvidence
              ? l.skillEvalPartial
              : _campaignStatus(l, c.status),
          style: CcTypography.caption.copyWith(color: t.textSecondary),
        ),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            Text(
              l.skillEvalCurrentHash(''),
              style: CcTypography.caption.copyWith(color: t.textSecondary),
            ),
            // RTL carve-out: package hashes are code-like identifiers.
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Text(
                c.skillHash,
                textDirection: ui.TextDirection.ltr,
                softWrap: true,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: CcTypography.caption.copyWith(color: t.textSecondary),
              ),
            ),
          ],
        ),
        Text(
          l.skillEvalProgress(c.completedAttempts, c.plannedAttempts),
          style: CcTypography.caption.copyWith(color: t.textSecondary),
        ),
        Text(
          l.skillEvalSpend(
            c.spentMicros == null
                ? l.skillEvalUnknown
                : money.format(c.spentMicros! / 1000000),
            money.format(c.budgetMicros / 1000000),
          ),
          style: CcTypography.caption.copyWith(color: t.textSecondary),
        ),
        if (c.adapter == 'claude-cli' ||
            (c.configuration['modelPin'] as Map?)?['budgetEnforcement'] ==
                'stop_after_call')
          Text(
            l.skillEvalUsageBudgetNote,
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
        if (c.staleReason != null) Text(l.skillEvalStaleReason(c.staleReason!)),
        if (c.error != null) Text(l.skillEvalUnavailable(c.error!)),
        if (snapshot.hasError) Text(skillCampaignError(l, snapshot.error!)),
        if (snapshot.asData?.value == null && snapshot.isLoading)
          Text(l.skillEvalReconnecting),
        if (_error != null) Text(skillCampaignError(l, _error!)),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            if (!c.isTerminal)
              CcButton(
                size: CcButtonSize.sm,
                variant: CcButtonVariant.destructive,
                onPressed: _busy ? null : _cancel,
                child: Text(l.skillEvalCancel),
              ),
            CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.secondary,
              onPressed: _busy ? null : _export,
              child: Text(l.skillEvalExport),
            ),
            CcButton(
              size: CcButtonSize.sm,
              variant: CcButtonVariant.ghost,
              onPressed: () {
                ref.invalidate(skillCampaignProvider(snapshotScope));
                ref.invalidate(skillAttemptsProvider(snapshotScope));
                setState(() => _refreshEpoch++);
              },
              child: Text(l.skillEvalRefresh),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
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
        const SizedBox(height: AppSpacing.md),
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
                            selected: (_attemptId ?? list.first.id) == a.id,
                            onPressed: () => setState(() => _attemptId = a.id),
                          ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    SkillAttemptTimeline(
                      workspaceId: widget.workspaceId,
                      campaignId: widget.campaignId,
                      attemptId: list.any((a) => a.id == _attemptId)
                          ? _attemptId!
                          : list.first.id,
                      refreshEpoch: _refreshEpoch,
                    ),
                  ],
                ),
        ),
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
