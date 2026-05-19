import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/services/step_label.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_canvas.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_formatting.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_history_menu.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_waterfall.dart';
import 'package:control_center/features/pipelines/presentation/widgets/trigger_labels.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// One pipeline run, full width: a meta strip (start, active duration, step
/// progress, retry / delete) over the timing waterfall and the run's graph.
///
/// Deliberately **not** a split with the runs list — the list is its own page
/// ([pipelinesRoute]), reached back through the breadcrumb. The run's name and
/// status live in that breadcrumb rather than in a page title, so the graph
/// starts at the top of the viewport instead of below a header that repeats what
/// the title bar already says.
class PipelineRunDetailScreen extends ConsumerStatefulWidget {
  /// Creates a [PipelineRunDetailScreen].
  const PipelineRunDetailScreen({super.key, required this.runId});

  /// The run to show.
  final String runId;

  @override
  ConsumerState<PipelineRunDetailScreen> createState() =>
      _PipelineRunDetailScreenState();
}

class _PipelineRunDetailScreenState
    extends ConsumerState<PipelineRunDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final runAsync = ref.watch(pipelineRunProvider(widget.runId));
    final run = runAsync.value;
    final templatesAsync = run == null
        ? const AsyncValue<List<PipelineDefinition>>.loading()
        : ref.watch(pipelineTemplatesProvider(run.workspaceId));
    final stepRuns =
        ref.watch(pipelineStepRunsForRunProvider(widget.runId)).value ??
        const <PipelineStepRun>[];
    ref.watch(pipelineClockProvider); // tick for live duration display

    final templates = templatesAsync.value;
    if (run == null || templates == null) {
      if (runAsync.isLoading || templatesAsync.isLoading) {
        return _RunDetailSkeleton(tokens: tokens);
      }
      return Center(
        child: Text(
          l10n.pipelinesNoSteps,
          style: TextStyle(color: tokens.textTertiary),
        ),
      );
    }

    final definition = templates
        .where((t) => t.templateId == run.templateId)
        .firstOrNull;
    if (definition == null) {
      return Center(
        child: Text(
          l10n.pipelinesNoSteps,
          style: TextStyle(color: tokens.textTertiary),
        ),
      );
    }

    final ordered = _orderedSteps(stepRuns, definition);
    final failed = ordered.firstWhereOrNull(
      (s) => s.status == PipelineStepStatus.failed,
    );
    // Land on the failed step (or the last one) so "what happened and why"
    // needs zero clicks; the operator can then pick any node on the canvas.
    final initialSelected =
        failed?.stepId ?? (ordered.isNotEmpty ? ordered.last.stepId : null);

    return Column(
      // Stretch so every section's edge-to-edge rule (meta strip bottom,
      // waterfall borders, canvas seam) spans the same full width.
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _RunMetaStrip(
          run: run,
          definition: definition,
          stepRuns: stepRuns,
          tokens: tokens,
          l10n: l10n,
          failedStepLabel: failed == null
              ? null
              : renderStepLabel(
                  definition.step(failed.stepId)?.config.label,
                  state: run.state,
                  trigger: run.triggerPayload,
                  fallback: failed.stepId,
                ),
          failedReason: failed?.errorMessage ?? run.errorMessage,
          onRetry: () => ref
              .read(pipelineEngineProvider)
              .retry(run.workspaceId, widget.runId),
          onDelete: () => _deleteRun(run),
        ),
        if (ordered.isNotEmpty)
          PipelineRunWaterfall(
            run: run,
            stepRuns: ordered,
            definition: definition,
            now: DateTime.now(),
            costByStepId:
                ref
                    .watch(
                      pipelineStepCostProvider((
                        workspaceId: run.workspaceId,
                        runId: widget.runId,
                      )),
                    )
                    .value ??
                const {},
          ),
        Expanded(
          child: PipelineCanvas(
            definition: definition,
            runId: widget.runId,
            initialSelectedStepId: initialSelected,
          ),
        ),
      ],
    );
  }

  /// Latest run per step, dropping the terminal sentinel, ordered by start.
  List<PipelineStepRun> _orderedSteps(
    List<PipelineStepRun> runs,
    PipelineDefinition def,
  ) {
    final latest = <String, PipelineStepRun>{};
    for (final sr in runs) {
      final prev = latest[sr.stepId];
      if (prev == null || sr.startedAt.isAfter(prev.startedAt)) {
        latest[sr.stepId] = sr;
      }
    }
    return latest.values
        .where((sr) => def.step(sr.stepId)?.kind != StepKind.terminal)
        .toList()
      ..sort((a, b) => a.startedAt.compareTo(b.startedAt));
  }

  Future<void> _deleteRun(PipelineRun run) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.deletePipelineRun,
        content: Text(l10n.deletePipelineRunConfirm(run.templateId)),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(ctx, false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(ctx, true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref
          .read(pipelineRunRepositoryProvider)
          .deleteRun(run.workspaceId, run.id);
      if (!mounted) {
        return;
      }
      // The run this page is about is gone — fall back to the queue rather than
      // sitting on a dead id.
      context.go(pipelinesRoute(run.workspaceId));
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      CcToastScope.of(context).show(
        l10n.errorDeletingPipelineRun('$e'),
        variant: CcToastVariant.danger,
      );
    }
  }
}

/// The run's meta strip: when it started, how long it was active, step progress,
/// and the run-level actions. The name and status are the breadcrumb's job.
class _RunMetaStrip extends StatelessWidget {
  const _RunMetaStrip({
    required this.run,
    required this.definition,
    required this.stepRuns,
    required this.tokens,
    required this.l10n,
    required this.failedStepLabel,
    required this.failedReason,
    required this.onRetry,
    required this.onDelete,
  });

  final PipelineRun run;
  final PipelineDefinition definition;
  final List<PipelineStepRun> stepRuns;
  final DesignSystemTokens tokens;
  final AppLocalizations l10n;
  final String? failedStepLabel;
  final String? failedReason;
  final VoidCallback onRetry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    // PRD 25 §6: active run time, excluding idle stop→restart gaps.
    final duration = run.activeDurationAt(now);

    // Progress over the action steps (excluding the trigger and any terminal).
    final stepIds = definition.steps
        .where((s) => s.kind != StepKind.terminal && s.kind != StepKind.trigger)
        .map((s) => s.id)
        .toSet();
    final latest = <String, PipelineStepRun>{};
    for (final sr in stepRuns) {
      final prev = latest[sr.stepId];
      if (prev == null || sr.startedAt.isAfter(prev.startedAt)) {
        latest[sr.stepId] = sr;
      }
    }
    final total = stepIds.length;
    final completed = stepIds
        .where((id) => latest[id]?.status == PipelineStepStatus.completed)
        .length;

    // "12 min ago" answers "is this recent?" without arithmetic; the exact
    // instant stays one hover (or tap-to-copy) away via AppTimestamp. This is
    // the run's one authoritative timestamp — the rows in the queue deliberately
    // carry no copy gesture, since their tap opens the run.
    //
    // It names the CURRENT attempt: after a rerun (a retry, or a crash-resume
    // that re-fired the run's steps) the original instant answers a question
    // nobody asked, while the work being watched started minutes ago. The
    // original start is not lost — it is the last segment of the meta line
    // below, and it is where the waterfall's timeline still begins.
    final attemptStart = run.currentAttemptStartedAt;
    final relative = formatPipelineRelative(attemptStart, now, l10n);
    final startedLabel = run.wasRestarted
        ? l10n.pipelineRunRerunAgo(relative)
        : relative;
    // The trigger belongs in the meta line, not only in the row's tooltip: this
    // is the page an operator opens to ask why a run happened, and until now it
    // answered every question about the run except that one.
    final triggerReason = runTriggerReason(l10n, run);
    final meta = <String>[
      // A queued run has not started, so it has no duration to report and the
      // coarse formatter would floor its zero to `<1s` — a run that has done
      // nothing reading as one that finished instantly. The status badge
      // beside this already says it is waiting.
      if (run.status != PipelineRunStatus.queued)
        formatPipelineDurationCoarse(duration),
      if (total > 0) l10n.pipelineRunStepProgress(completed, total),
      runTriggerLabel(l10n, run),
      ?triggerReason,
      if (run.attemptCount > 1) l10n.pipelineRunAttempt(run.attemptCount),
      if (run.wasRestarted)
        l10n.pipelineRunFirstStarted(
          formatPipelineRelative(run.startedAt, now, l10n),
        ),
    ].join(' · ');

    final isFailed = run.status == PipelineRunStatus.failed;
    // Exactly what `PipelineEngine.retry` accepts. Offering it on a COMPLETED
    // run, as this did, is a button that does nothing.
    final canRetry = isFailed || run.status == PipelineRunStatus.cancelled;

    return Container(
      decoration: BoxDecoration(
        color: tokens.bgPrimary,
        border: Border(bottom: BorderSide(color: tokens.borderSecondary)),
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xl,
        vertical: AppSpacing.md,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: DefaultTextStyle.merge(
                  style: TextStyle(
                    color: tokens.textTertiary,
                    fontSize: 12,
                    height: 1.4,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AppTimestamp(
                        dateTime: attemptStart,
                        child: Text(startedLabel),
                      ),
                      Flexible(
                        child: Text(
                          ' · $meta',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (canRetry) ...[
                AppSpacing.hGapSm,
                CcButton(
                  onPressed: onRetry,
                  icon: AppIcons.refreshCw,
                  size: CcButtonSize.sm,
                  variant: CcButtonVariant.secondary,
                  child: Text(l10n.retry),
                ),
              ],
              AppSpacing.hGapSm,
              // Beside the run's own actions, because "how did the last one
              // go" is a question about THIS run, not a place to navigate to.
              PipelineRunHistoryMenu(run: run),
              AppSpacing.hGapSm,
              CcTooltip(
                message: l10n.deletePipelineRun,
                child: CcIconButton(
                  icon: AppIcons.trash2,
                  semanticLabel: l10n.deletePipelineRun,
                  onPressed: onDelete,
                ),
              ),
            ],
          ),
          if (isFailed && failedStepLabel != null) ...[
            const SizedBox(height: AppSpacing.sm),
            _FailureSummary(
              stepLabel: failedStepLabel!,
              reason: failedReason,
              tokens: tokens,
              l10n: l10n,
            ),
          ],
        ],
      ),
    );
  }
}

/// Error-toned banner naming the step a failed run died on, with its reason,
/// so the operator never has to hunt the graph to learn why a run failed.
class _FailureSummary extends StatelessWidget {
  const _FailureSummary({
    required this.stepLabel,
    required this.reason,
    required this.tokens,
    required this.l10n,
  });

  final String stepLabel;
  final String? reason;
  final DesignSystemTokens tokens;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final trimmed = reason?.trim();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: tokens.bgErrorPrimary,
        border: Border.all(color: tokens.borderErrorSubtle),
        borderRadius: AppRadii.brSm,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(AppIcons.circleAlert, size: 14, color: tokens.textErrorPrimary),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.pipelineRunFailedAtStep(stepLabel),
                  style: TextStyle(
                    color: tokens.textErrorPrimary,
                    fontSize: 12,
                    height: 1.3,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (trimmed != null && trimmed.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    trimmed,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: tokens.textErrorPrimary,
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Loading placeholder for the run page.
class _RunDetailSkeleton extends StatelessWidget {
  const _RunDetailSkeleton({required this.tokens});

  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SkeletonBar(tokens: tokens, height: 12, width: 320),
          const SizedBox(height: AppSpacing.xl),
          for (var i = 0; i < 3; i++) ...[
            _SkeletonBar(tokens: tokens, height: 40),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

/// A single rounded skeleton placeholder block.
class _SkeletonBar extends StatelessWidget {
  const _SkeletonBar({
    required this.tokens,
    required this.height,
    this.width = double.infinity,
  });

  final DesignSystemTokens tokens;
  final double height;
  final double width;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: width,
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: AppRadii.brSm,
      ),
    );
  }
}
