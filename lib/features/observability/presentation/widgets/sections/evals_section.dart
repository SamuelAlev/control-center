import 'package:cc_data/cc_data.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/observability/presentation/obs_format.dart';
import 'package:control_center/features/observability/presentation/widgets/obs_widgets.dart';
import 'package:control_center/features/observability/providers/evals_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The evals surface (PRD 21 §5): one card per eval suite, each showing its
/// recent batch runs (pass-rate, size, status, cost, trigger, age) and a "Run"
/// action. A thin client surface — runs are dispatched to `cc_server` over the
/// `evals.*` RPC ops via [RpcEvalsClient]. Non-scrolling; the parent tab owns
/// the scroll view.
class EvalsSection extends ConsumerWidget {
  /// Creates an [EvalsSection].
  const EvalsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final suites = ref.watch(evalSuitesProvider);
    return suites.when(
      data: (list) {
        if (list.isEmpty) {
          return _EmptyState(text: l10n.evalsNoSuites);
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (var i = 0; i < list.length; i++) ...[
              if (i > 0) const SizedBox(height: AppSpacing.lg),
              _SuiteCard(suite: list[i]),
            ],
          ],
        );
      },
      loading: () => const Center(child: CcSpinner()),
      error: (_, _) => _EmptyState(text: l10n.evalsError),
    );
  }
}

/// A single eval suite with its recent runs and a run action.
class _SuiteCard extends ConsumerWidget {
  const _SuiteCard({required this.suite});

  final EvalSuiteView suite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final runs = ref.watch(evalRunsProvider(suite.id));
    return ObsSection(
      title: suite.name,
      subtitle: suite.description.isNotEmpty ? suite.description : null,
      icon: AppIcons.scanSearch,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (suite.isStarter) ...[
            CcStatusTag(
              label: l10n.evalsStarterBadge,
              tone: CcStatusTone.info,
              dot: false,
            ),
            const SizedBox(width: AppSpacing.sm),
          ],
          _RunButton(suiteId: suite.id),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            l10n.evalsDefaultBatch(suite.defaultBatchSize),
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.evalsRecentRuns,
            style: CcTypography.label.copyWith(color: t.textTertiary),
          ),
          const SizedBox(height: AppSpacing.xs),
          runs.when(
            data: (list) => list.isEmpty
                ? _EmptyLine(text: l10n.evalsNoRuns)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (var i = 0; i < list.length; i++) ...[
                        if (i > 0) const CcDivider(),
                        _RunRow(run: list[i]),
                      ],
                    ],
                  ),
            loading: () => const _LoadingLine(),
            error: (_, _) => _EmptyLine(text: l10n.evalsError),
          ),
        ],
      ),
    );
  }
}

/// A single eval run: a pass-rate meter plus a compact metadata line.
class _RunRow extends StatelessWidget {
  const _RunRow({required this.run});

  final EvalRunView run;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ObsBar(
            label: l10n.evalsPassRate,
            fraction: run.passRate,
            valueLabel: fmtPercent(run.passRate),
            tone: _passRateTone(run.passRate),
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              CcStatusTag(
                label: _runStatusLabel(l10n, run.status),
                tone: _runStatusTone(run.status),
              ),
              Text(
                l10n.evalsBatchTimes(run.batchSize),
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
              Text(
                fmtCents(run.costCents),
                style: CcTypography.monoNum.copyWith(color: t.textSecondary),
              ),
              Text(
                l10n.evalsTriggeredBy(run.triggeredBy),
                style: CcTypography.caption.copyWith(color: t.textTertiary),
              ),
              if (run.createdAt != null)
                AppTimestamp.relative(
                  run.createdAt!,
                  style: CcTypography.caption.copyWith(color: t.textQuaternary),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The per-suite "Run" button; shows an inline spinner while the batch runs and
/// surfaces the resulting pass-rate in a toast.
class _RunButton extends ConsumerStatefulWidget {
  const _RunButton({required this.suiteId});

  final String suiteId;

  @override
  ConsumerState<_RunButton> createState() => _RunButtonState();
}

class _RunButtonState extends ConsumerState<_RunButton> {
  bool _running = false;

  Future<void> _run() async {
    final l10n = AppLocalizations.of(context);
    setState(() => _running = true);
    try {
      final scorecard = await ref
          .read(rpcEvalsClientProvider)
          .runSuite(widget.suiteId);
      final rate = (scorecard['passRate'] as num?)?.toDouble();
      if (mounted && rate != null) {
        CcToastScope.maybeOf(context)?.show(
          l10n.evalsRunFinished(fmtPercent(rate)),
          variant: CcToastVariant.success,
        );
      }
    } on Object {
      if (mounted) {
        CcToastScope.maybeOf(
          context,
        )?.show(l10n.evalsRunFailed, variant: CcToastVariant.danger);
      }
    } finally {
      if (mounted) {
        setState(() => _running = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcButton(
      size: CcButtonSize.sm,
      variant: CcButtonVariant.accent,
      icon: AppIcons.play,
      loading: _running,
      onPressed: _running ? null : _run,
      child: Text(l10n.evalsRun),
    );
  }
}

/// A muted, centered spinner used while a suite's runs resolve.
class _LoadingLine extends StatelessWidget {
  const _LoadingLine();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Center(child: CcSpinner()),
    );
  }
}

/// A muted single-line hint used for empty / error run lists.
class _EmptyLine extends StatelessWidget {
  const _EmptyLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Text(
      text,
      style: CcTypography.bodySm.copyWith(color: t.textTertiary),
    );
  }
}

/// A full-surface empty / error state, centered.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: CcTypography.body.copyWith(color: t.textTertiary),
        ),
      ),
    );
  }
}

ObsTone _passRateTone(double rate) {
  if (rate >= 0.9) {
    return ObsTone.success;
  }
  if (rate >= 0.7) {
    return ObsTone.warning;
  }
  return ObsTone.danger;
}

CcStatusTone _runStatusTone(String status) => switch (status) {
  'running' => CcStatusTone.info,
  'passed' || 'succeeded' || 'completed' => CcStatusTone.positive,
  'failed' => CcStatusTone.negative,
  _ => CcStatusTone.neutral,
};

String _runStatusLabel(AppLocalizations l10n, String status) =>
    switch (status) {
      'queued' => l10n.evalsStatusQueued,
      'running' => l10n.evalsStatusRunning,
      'passed' || 'succeeded' || 'completed' => l10n.evalsStatusPassed,
      'failed' => l10n.evalsStatusFailed,
      _ => status,
    };
