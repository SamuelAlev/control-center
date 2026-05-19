import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_canvas.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_card.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_formatting.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_waterfall.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_status_badge.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Screen listing pipeline runs alongside the selected run's graph.
///
/// When [initialRunId] is provided (via the `/pipelines/:runId` route), the
/// matching run is pre-selected so the user can jump straight from "Ask AI"
/// onto the focused run inside the standard sidebar layout.
class PipelinesScreen extends ConsumerStatefulWidget {
  /// Creates a [PipelinesScreen].
  const PipelinesScreen({super.key, this.initialRunId});

  /// Run to focus when the screen first builds. Optional.
  final String? initialRunId;

  @override
  ConsumerState<PipelinesScreen> createState() => _PipelinesScreenState();
}

/// Status filter for the runs rail. Keeps the operator's most common triage —
/// "what's running" / "what broke" — one click away without leaving the page.
enum _RunStatusFilter {
  /// Every run in the workspace.
  all,

  /// Runs currently executing.
  running,

  /// Runs that ended in failure.
  failed,
}

class _PipelinesScreenState extends ConsumerState<PipelinesScreen> {
  String? _selectedRunId;
  _RunStatusFilter _filter = _RunStatusFilter.all;

  @override
  void initState() {
    super.initState();
    _selectedRunId = widget.initialRunId;
  }

  /// Runs matching the active [_filter], preserving the source order.
  List<PipelineRun> _applyFilter(List<PipelineRun> runs) {
    return switch (_filter) {
      _RunStatusFilter.all => runs,
      _RunStatusFilter.running =>
        runs.where((r) => r.status == PipelineRunStatus.running).toList(),
      _RunStatusFilter.failed =>
        runs.where((r) => r.status == PipelineRunStatus.failed).toList(),
    };
  }

  /// Moves the run selection [delta] rows within [visible], so the up/down
  /// arrows walk the rail without a mouse.
  void _moveSelection(List<PipelineRun> visible, int delta) {
    if (visible.isEmpty) {
      return;
    }
    final current = visible.indexWhere((r) => r.id == _selectedRunId);
    final next = (current < 0 ? 0 : current + delta).clamp(
      0,
      visible.length - 1,
    );
    setState(() => _selectedRunId = visible[next].id);
  }

  @override
  void didUpdateWidget(covariant PipelinesScreen old) {
    super.didUpdateWidget(old);
    if (widget.initialRunId != null &&
        widget.initialRunId != old.initialRunId) {
      _selectedRunId = widget.initialRunId;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return PageWrapper(
        title: l10n.pipelinesScreenTitle,
        subtitle: l10n.pipelinesScreenSubtitle,
        child: Center(child: Text(l10n.pipelinesNoActiveWorkspace)),
      );
    }
    final runsAsync = ref.watch(workspacePipelineRunsProvider(workspaceId));
    // Friendly names for the run cards: templateId → human-readable name.
    final templateNames = {
      for (final t
          in ref.watch(pipelineTemplatesProvider(workspaceId)).value ??
              const <PipelineDefinition>[])
        t.templateId: t.name,
    };
    ref.watch(pipelineClockProvider); // tick for live duration display

    return PageWrapper(
      title: l10n.pipelinesScreenTitle,
      subtitle: l10n.pipelinesScreenSubtitle,
      actions: [
        CcButton(
          onPressed: () => context.go(runPipelineRoute(workspaceId)),
          icon: AppIcons.play,
          size: CcButtonSize.sm,
          variant: CcButtonVariant.primary,
          child: Text(l10n.pipelinesRunPipeline),
        ),
      ],
      child: runsAsync.when(
        loading: () => _RunsLoadingSkeleton(tokens: tokens),
        error: (e, _) =>
            Center(child: Text(l10n.pipelinesLoadError(e.toString()))),
        data: (runs) {
          if (runs.isEmpty) {
            return _EmptyState(l10n: l10n, tokens: tokens);
          }
          final visible = _applyFilter(runs);
          final runningCount = runs
              .where((r) => r.status == PipelineRunStatus.running)
              .length;
          final failedCount = runs
              .where((r) => r.status == PipelineRunStatus.failed)
              .length;
          return Row(
            children: [
              SizedBox(
                width: 360,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _RunFilterBar(
                      filter: _filter,
                      allCount: runs.length,
                      runningCount: runningCount,
                      failedCount: failedCount,
                      onChanged: (f) => setState(() => _filter = f),
                      tokens: tokens,
                      l10n: l10n,
                    ),
                    Expanded(
                      child: visible.isEmpty
                          ? _EmptyFilterState(l10n: l10n, tokens: tokens)
                          : CallbackShortcuts(
                              bindings: {
                                const SingleActivator(
                                  LogicalKeyboardKey.arrowDown,
                                ): () =>
                                    _moveSelection(visible, 1),
                                const SingleActivator(
                                  LogicalKeyboardKey.arrowUp,
                                ): () =>
                                    _moveSelection(visible, -1),
                                const SingleActivator(
                                  LogicalKeyboardKey.keyJ,
                                ): () =>
                                    _moveSelection(visible, 1),
                                const SingleActivator(
                                  LogicalKeyboardKey.keyK,
                                ): () =>
                                    _moveSelection(visible, -1),
                              },
                              child: ListView.separated(
                                padding: const EdgeInsets.all(AppSpacing.lg),
                                itemCount: visible.length,
                                separatorBuilder: (_, _) =>
                                    const SizedBox(height: AppSpacing.md),
                                itemBuilder: (context, index) {
                                  final run = visible[index];
                                  return PipelineRunCard(
                                    run: run,
                                    now: DateTime.now(),
                                    title: templateNames[run.templateId],
                                    selected: run.id == _selectedRunId,
                                    onTap: () =>
                                        setState(() => _selectedRunId = run.id),
                                  );
                                },
                              ),
                            ),
                    ),
                  ],
                ),
              ),
              VerticalDivider(
                width: 1,
                thickness: 1,
                color: tokens.borderSecondary,
              ),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(color: tokens.borderSecondary),
                    ),
                  ),
                  child: _selectedRunId != null
                      ? _RunDetail(
                          runId: _selectedRunId!,
                          workspaceId: workspaceId,
                          onDelete: _deleteRun,
                        )
                      : _SelectRunPlaceholder(l10n: l10n, tokens: tokens),
                ),
              ),
            ],
          );
        },
      ),
    );
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
      setState(() {
        if (_selectedRunId == run.id) {
          _selectedRunId = null;
        }
      });
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

/// Placeholder shown in the detail pane when no run is selected.
class _SelectRunPlaceholder extends StatelessWidget {
  const _SelectRunPlaceholder({required this.l10n, required this.tokens});

  final AppLocalizations l10n;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.workflow, size: 28, color: tokens.fgQuaternary),
          const SizedBox(height: AppSpacing.md),
          Text(
            l10n.pipelinesSelectRun,
            style: TextStyle(color: tokens.textTertiary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

/// Empty state when no pipeline runs exist.
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.l10n, required this.tokens});

  final AppLocalizations l10n;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(AppIcons.gitBranch, size: 40, color: tokens.fgQuaternary),
          const SizedBox(height: AppSpacing.lg),
          Text(
            l10n.pipelinesEmpty,
            style: TextStyle(
              color: tokens.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            l10n.pipelinesEmptyHint,
            style: TextStyle(color: tokens.textTertiary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

/// Compact segmented control above the runs rail: all / running / failed, each
/// with a live count, so the operator can narrow to "what's running" or "what
/// broke" in one click.
class _RunFilterBar extends StatelessWidget {
  const _RunFilterBar({
    required this.filter,
    required this.allCount,
    required this.runningCount,
    required this.failedCount,
    required this.onChanged,
    required this.tokens,
    required this.l10n,
  });

  final _RunStatusFilter filter;
  final int allCount;
  final int runningCount;
  final int failedCount;
  final ValueChanged<_RunStatusFilter> onChanged;
  final DesignSystemTokens tokens;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.lg,
        AppSpacing.sm,
      ),
      child: Container(
        padding: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: tokens.bgSecondary,
          borderRadius: AppRadii.brMd,
          border: Border.all(color: tokens.borderSecondary),
        ),
        child: Row(
          children: [
            _segment(_RunStatusFilter.all, l10n.pipelineRunFilterAll, allCount),
            _segment(
              _RunStatusFilter.running,
              l10n.pipelineStatusRunning,
              runningCount,
            ),
            _segment(
              _RunStatusFilter.failed,
              l10n.pipelineStatusFailed,
              failedCount,
            ),
          ],
        ),
      ),
    );
  }

  Widget _segment(_RunStatusFilter value, String label, int count) {
    final selected = value == filter;
    final fg = selected ? tokens.textPrimary : tokens.textTertiary;
    return Expanded(
      child: Semantics(
        button: true,
        selected: selected,
        child: CcTappable(
          onPressed: () => onChanged(value),
          builder: (context, states) => Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
            decoration: BoxDecoration(
              color: selected ? tokens.bgPrimary : Colors.transparent,
              borderRadius: AppRadii.brSm,
              border: Border.all(
                color: selected ? tokens.borderSecondary : Colors.transparent,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: fg,
                      fontSize: 12,
                      height: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 5),
                Text(
                  '$count',
                  style: TextStyle(
                    color: selected
                        ? tokens.textTertiary
                        : tokens.textQuaternary,
                    fontSize: 12,
                    height: 1.2,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shown in the rail when the active filter matches no runs.
class _EmptyFilterState extends StatelessWidget {
  const _EmptyFilterState({required this.l10n, required this.tokens});

  final AppLocalizations l10n;
  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          l10n.pipelineRunFilterEmpty,
          textAlign: TextAlign.center,
          style: TextStyle(color: tokens.textTertiary, fontSize: 13),
        ),
      ),
    );
  }
}

/// Renders the selected run: a header summary above either a scannable step
/// timeline (default) or the node graph, with the detail of the selected step
/// alongside the timeline.
class _RunDetail extends ConsumerStatefulWidget {
  const _RunDetail({
    required this.runId,
    required this.workspaceId,
    required this.onDelete,
  });

  final String runId;
  final String workspaceId;

  /// Deletes the given run (with confirmation) from the detail header.
  final ValueChanged<PipelineRun> onDelete;

  @override
  ConsumerState<_RunDetail> createState() => _RunDetailState();
}

class _RunDetailState extends ConsumerState<_RunDetail> {
  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final runAsync = ref.watch(pipelineRunProvider(widget.runId));
    final templatesAsync = ref.watch(
      pipelineTemplatesProvider(widget.workspaceId),
    );
    final stepRuns =
        ref.watch(pipelineStepRunsForRunProvider(widget.runId)).value ??
        const <PipelineStepRun>[];
    ref.watch(pipelineClockProvider); // tick for live duration display

    final run = runAsync.value;
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
      children: [
        _RunHeader(
          run: run,
          definition: definition,
          stepRuns: stepRuns,
          tokens: tokens,
          l10n: l10n,
          failedStepLabel: failed == null
              ? null
              : (definition.step(failed.stepId)?.config.label ?? failed.stepId),
          failedReason: failed?.errorMessage ?? run.errorMessage,
          onRetry: () => ref.read(pipelineEngineProvider).retry(widget.runId),
          onDelete: () => widget.onDelete(run),
        ),
        if (ordered.isNotEmpty)
          PipelineRunWaterfall(
            stepRuns: ordered,
            definition: definition,
            now: DateTime.now(),
            costByStepId: ref
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
}

/// Summary header above the canvas: name, status, timing/progress, a failure
/// summary when the run failed, and Retry.
class _RunHeader extends StatelessWidget {
  const _RunHeader({
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
    final duration = (run.finishedAt ?? DateTime.now()).difference(
      run.startedAt,
    );

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

    final meta = <String>[
      formatPipelineTime(run.startedAt),
      formatPipelineDurationCoarse(duration),
      if (total > 0) l10n.pipelineRunStepProgress(completed, total),
    ].join(' · ');

    final isFailed = run.status == PipelineRunStatus.failed;
    final canRetry = isFailed || run.status == PipelineRunStatus.completed;

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            definition.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: tokens.textPrimary,
                              fontSize: 16,
                              height: 1.3,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        AppSpacing.hGapSm,
                        PipelineStatusBadge.forRun(status: run.status),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      meta,
                      style: TextStyle(
                        color: tokens.textTertiary,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ],
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
              Tooltip(
                message: l10n.deletePipelineRun,
                child: CcIconButton(
                  icon: AppIcons.trash2,
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
          Icon(
            AppIcons.circleAlert,
            size: 14,
            color: tokens.textErrorPrimary,
          ),
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

/// Loading placeholder for the whole pane: a few skeleton rows in the rail.
class _RunsLoadingSkeleton extends StatelessWidget {
  const _RunsLoadingSkeleton({required this.tokens});

  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SizedBox(
          width: 360,
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: 5,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (_, _) => _SkeletonBar(tokens: tokens, height: 56),
          ),
        ),
        VerticalDivider(width: 1, thickness: 1, color: tokens.borderSecondary),
        Expanded(child: _RunDetailSkeleton(tokens: tokens)),
      ],
    );
  }
}

/// Loading placeholder for the detail pane.
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
          _SkeletonBar(tokens: tokens, height: 20, width: 220),
          const SizedBox(height: AppSpacing.md),
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
