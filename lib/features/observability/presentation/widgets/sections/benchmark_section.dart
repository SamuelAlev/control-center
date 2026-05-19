import 'package:cc_domain/features/observability/domain/benchmark.dart';
import 'package:cc_markdown/cc_markdown.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/features/observability/providers/benchmark_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Scored eval / benchmark section (PRD #13): CC's own agent-run history as a
/// scored benchmark — pass/fail, reward, and spend-per-task — with a copyable
/// markdown report. Non-scrolling; the parent tab owns the scroll view.
class BenchmarkSection extends ConsumerWidget {
  /// Creates a [BenchmarkSection].
  const BenchmarkSection({super.key});

  /// Cap the rendered trial list so a long run history stays cheap to lay out.
  static const _maxTrials = 50;

  /// How many leading lines of the markdown report to preview inline.
  static const _reportPreviewLines = 12;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final run = ref.watch(workspaceBenchmarkRunProvider);
    final scorer = ref.watch(benchmarkScorerProvider);

    final costPerTaskCents = run.done > 0
        ? (run.totalCostCents / run.done).round()
        : 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.obsBenchmarkCaption,
          style: CcTypography.caption.copyWith(color: t.textTertiary),
        ),
        const SizedBox(height: AppSpacing.lg),
        Wrap(
          spacing: AppSpacing.xl,
          runSpacing: AppSpacing.lg,
          children: [
            ObsStatTile(
              label: l10n.obsBenchmarkPassAt1,
              value: fmtPercent(scorer.passAtK(run)),
              tone: ObsTone.success,
              icon: AppIcons.trophy,
            ),
            ObsStatTile(
              label: l10n.obsBenchmarkSuccessPct,
              value: '${run.successPct.toStringAsFixed(0)}%',
              icon: AppIcons.chartColumn,
            ),
            ObsStatTile(
              label: l10n.obsBenchmarkPassed,
              value: fmtCount(run.passCount),
              tone: ObsTone.success,
              icon: AppIcons.circleCheck,
            ),
            ObsStatTile(
              label: l10n.obsBenchmarkFailed,
              value: fmtCount(run.failCount),
              tone: ObsTone.danger,
              icon: AppIcons.circleX,
            ),
            ObsStatTile(
              label: l10n.obsBenchmarkErrors,
              value: fmtCount(run.errorCount),
              tone: ObsTone.warning,
              icon: AppIcons.circleAlert,
            ),
            ObsStatTile(
              label: l10n.obsBenchmarkSpend,
              value: fmtCents(run.totalCostCents),
            ),
            ObsStatTile(
              label: l10n.obsBenchmarkCostPerTask,
              value: fmtCents(costPerTaskCents),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        ObsSection(
          title: l10n.obsBenchmarkTrials,
          icon: AppIcons.scrollText,
          child: _TrialList(run: run),
        ),
        const SizedBox(height: AppSpacing.lg),
        _ReportSection(run: run, scorer: scorer),
      ],
    );
  }
}

/// Maps a [TrialStatus] to its semantic tone.
ObsTone _trialTone(TrialStatus status) => switch (status) {
  TrialStatus.pass => ObsTone.success,
  TrialStatus.fail => ObsTone.danger,
  TrialStatus.error => ObsTone.warning,
  TrialStatus.running => ObsTone.neutral,
};

/// A short, human label for a [TrialStatus] (status is never color-only).
String _trialLabel(AppLocalizations l10n, TrialStatus status) =>
    switch (status) {
      TrialStatus.pass => l10n.obsBenchmarkTrialPass,
      TrialStatus.fail => l10n.obsBenchmarkTrialFail,
      TrialStatus.error => l10n.obsBenchmarkTrialError,
      TrialStatus.running => l10n.obsBenchmarkTrialRunning,
    };

/// The capped list of scored trials inside the 'Trials' section.
class _TrialList extends StatelessWidget {
  const _TrialList({required this.run});

  final BenchmarkRun run;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    if (run.trials.isEmpty) {
      return Text(
        l10n.obsBenchmarkNoTrials,
        style: CcTypography.bodySm.copyWith(color: t.textTertiary),
      );
    }

    final shown = run.trials.length > BenchmarkSection._maxTrials
        ? run.trials.sublist(0, BenchmarkSection._maxTrials)
        : run.trials;
    final overflow = run.trials.length - shown.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < shown.length; i++) ...[
          if (i > 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppSpacing.xxs),
              child: CcDivider(),
            ),
          _TrialRow(trial: shown[i]),
        ],
        if (overflow > 0)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              l10n.obsBenchmarkAndMore(overflow),
              style: CcTypography.caption.copyWith(color: t.textTertiary),
            ),
          ),
      ],
    );
  }
}

/// One trial row: status dot + label, name, reward, cost, duration, detail.
class _TrialRow extends StatelessWidget {
  const _TrialRow({required this.trial});

  final BenchmarkTrial trial;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final tone = _trialTone(trial.status);
    final reward = trial.reward != null
        ? trial.reward!.toStringAsFixed(2)
        : '—';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 3),
            child: ObsStatusDot(tone: tone),
          ),
          const SizedBox(width: AppSpacing.sm),
          SizedBox(
            width: 56,
            child: Text(
              _trialLabel(l10n, trial.status),
              style: CcTypography.caption.copyWith(
                color: obsToneColor(t, tone),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trial.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                ),
                if (trial.detail.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xxs),
                    child: Text(
                      trial.detail,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: CcTypography.caption.copyWith(
                        color: trial.status == TrialStatus.error
                            ? t.textErrorPrimary
                            : t.textTertiary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          _TrialMetric(label: l10n.obsBenchmarkReward, value: reward, t: t),
          const SizedBox(width: AppSpacing.lg),
          _TrialMetric(
            label: l10n.obsColCost,
            value: fmtCents(trial.costCents),
            t: t,
          ),
          const SizedBox(width: AppSpacing.lg),
          _TrialMetric(
            label: l10n.obsColTime,
            value: fmtDuration(trial.durationMs),
            t: t,
          ),
        ],
      ),
    );
  }
}

/// A compact right-aligned label-over-value metric cell for a trial row.
class _TrialMetric extends StatelessWidget {
  const _TrialMetric({
    required this.label,
    required this.value,
    required this.t,
  });

  final String label;
  final String value;
  final DesignSystemTokens t;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          label,
          style: CcTypography.caption.copyWith(color: t.textQuaternary),
        ),
        Text(value, style: CcTypography.monoNum.copyWith(color: t.textPrimary)),
      ],
    );
  }
}

/// The 'Report' section: a copy-to-clipboard action plus an inline preview of
/// the first lines of the markdown report.
class _ReportSection extends StatelessWidget {
  const _ReportSection({required this.run, required this.scorer});

  final BenchmarkRun run;
  final BenchmarkScorer scorer;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final markdown = scorer.markdownReport(run);
    final previewLines = markdown
        .trimRight()
        .split('\n')
        .take(BenchmarkSection._reportPreviewLines)
        .join('\n');

    return ObsSection(
      title: l10n.obsBenchmarkReport,
      icon: AppIcons.fileText,
      trailing: CcButton(
        variant: CcButtonVariant.secondary,
        size: CcButtonSize.sm,
        icon: AppIcons.copy,
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: markdown));
          if (context.mounted) {
            CcToastScope.maybeOf(
              context,
            )?.show(l10n.obsBenchmarkCopied, variant: CcToastVariant.success);
          }
        },
        child: Text(l10n.obsBenchmarkCopyMarkdown),
      ),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: t.bgTertiary,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: t.borderPrimary),
        ),
        child: CcSelectionRegion(
          child: Text(
            previewLines,
            style: CcTypography.monoNum.copyWith(color: t.textSecondary),
          ),
        ),
      ),
    );
  }
}
