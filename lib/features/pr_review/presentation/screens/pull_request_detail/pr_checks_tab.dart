import 'package:cc_domain/features/pr_review/domain/entities/check_run.dart';
import 'package:cc_domain/features/pr_review/domain/entities/workflow_graph.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pipelines/presentation/widgets/pipeline_run_formatting.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_checks_ui_notifier.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_files_tab.dart';
import 'package:control_center/features/pr_review/presentation/utils/relative_time.dart';
import 'package:control_center/features/pr_review/presentation/utils/review_status_palette.dart';
import 'package:control_center/features/pr_review/presentation/utils/workflow_matrix_names.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_sidebar.dart'
    show WorkflowStatusIcon, workflowStatusStyle;
import 'package:control_center/features/pr_review/presentation/widgets/workflow_graph_layout.dart';
import 'package:control_center/features/pr_review/presentation/widgets/workflow_job_detail.dart';
import 'package:control_center/features/pr_review/presentation/widgets/workflow_run_canvas.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:control_center/shared/widgets/app_timestamp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Actions tab — groups CI check runs by parent workflow, expandable to
/// show individual job statuses and a "View logs" link.
class ChecksTab extends ConsumerStatefulWidget {
  /// ChecksTab({.
  const ChecksTab({
    super.key,
    required this.checks,
    required this.isLoading,
    required this.error,
  });

  /// List of CI check runs to display.
  final List<CheckRun> checks;

  /// Whether data is still loading.
  final bool isLoading;

  /// Object?.
  final Object? error;

  @override
  ConsumerState<ChecksTab> createState() => _ChecksTabState();
}

class _ChecksTabState extends ConsumerState<ChecksTab> {
  final Map<String, GlobalKey> _workflowKeys = {};

  /// One-shot guard for the default-open seed.
  bool _didSeedExpansion = false;

  GlobalKey _keyFor(String workflow) =>
      _workflowKeys.putIfAbsent(workflow, GlobalKey.new);

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.checks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: CcSpinner()),
      );
    }
    if (widget.error != null && widget.checks.isEmpty) {
      return SectionError(error: widget.error!);
    }

    final ui = ref.watch(prChecksUiProvider);
    final workflows = groupChecksByWorkflow(widget.checks);

    // Default-open: the first time checks arrive, every workflow card
    // expands. One-shot so a manual collapse survives refetches and a
    // late-arriving run doesn't force itself open.
    if (!_didSeedExpansion && workflows.isNotEmpty) {
      _didSeedExpansion = true;
      final keys = [for (final w in workflows) w.key];
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(prChecksUiProvider.notifier).expandAll(keys);
      });
    }

    // Consume any pending scroll request from the sidebar, deferred to the
    // next frame so the target tile is laid out by the time we scroll.
    final scrollTo = ui.scrollToWorkflow;
    if (scrollTo != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        final key = _workflowKeys[scrollTo];
        final ctx = key?.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            alignment: 0.1,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
          );
        }
        ref.read(prChecksUiProvider.notifier).consumeScrollRequest();
      });
    }

    if (workflows.isEmpty) {
      final tokens = context.designSystem ?? DesignSystemTokens.light();
      final l10n = AppLocalizations.of(context);
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
        child: CcCard(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                l10n.noChecksOnCommit,
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < workflows.length; i++) ...[
            _WorkflowCard(
              key: _keyFor(workflows[i].key),
              workflow: workflows[i],
              expanded: ui.expandedWorkflows.contains(workflows[i].key),
              onToggle: () => ref
                  .read(prChecksUiProvider.notifier)
                  .toggleExpanded(workflows[i].key),
            ),
            if (i != workflows.length - 1) const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _WorkflowCard extends StatelessWidget {
  const _WorkflowCard({
    super.key,
    required this.workflow,
    required this.expanded,
    required this.onToggle,
  });

  final WorkflowGroup workflow;
  final bool expanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final style = workflowStatusStyle(workflow.status, context);
    final isFailing = workflow.status == WorkflowStatus.failure;
    return Container(
      decoration: BoxDecoration(
        color: isFailing
            ? const Color(0xFFCF222E).withValues(alpha: 0.04)
            : tokens.bgPrimary,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isFailing
              ? const Color(0xFFCF222E).withValues(alpha: 0.25)
              : tokens.borderSecondary,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.vertical(
              top: const Radius.circular(4),
              bottom: expanded ? Radius.zero : const Radius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
              child: Row(
                children: [
                  WorkflowStatusIcon(status: workflow.status, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          workflow.name,
                          style: CcTypography.body
                              .copyWith(color: tokens.textTertiary)
                              .copyWith(
                                fontWeight: FontWeight.w600,
                                color: tokens.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: _summaryFor(context, workflow),
                                style: CcTypography.caption
                                    .copyWith(color: tokens.textTertiary)
                                    .copyWith(
                                      color: style.color,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                              if (_timeLabelFor(context, workflow)
                                  case final timeLabel?)
                                TextSpan(
                                  text: ' · $timeLabel',
                                  style: CcTypography.caption.copyWith(
                                    color: tokens.textTertiary,
                                  ),
                                ),
                            ],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
                    size: 16,
                    color: tokens.textTertiary,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const CcDivider(),
            _WorkflowRunBody(workflow: workflow),
          ],
        ],
      ),
    );
  }

  String _summaryFor(BuildContext context, WorkflowGroup w) {
    final l10n = AppLocalizations.of(context);
    final total = w.jobs.length;
    switch (w.status) {
      case WorkflowStatus.running:
        return l10n.checksSummaryRunning(total);
      case WorkflowStatus.success:
        return l10n.checksSummarySuccess(total);
      case WorkflowStatus.failure:
        return l10n.checksSummaryFailure(w.failingCount, total);
      case WorkflowStatus.neutral:
        return l10n.checksSummaryNeutral(total);
    }
  }

  /// The run's relative timing for the accordion header: `Started … ago`
  /// while in progress (earliest job start), `Completed … ago` once the run
  /// settles (latest job completion). Null when no job reported timing.
  String? _timeLabelFor(BuildContext context, WorkflowGroup w) {
    final l10n = AppLocalizations.of(context);
    if (w.status == WorkflowStatus.running) {
      DateTime? earliest;
      for (final j in w.jobs) {
        final s = j.startedAt;
        if (s != null && (earliest == null || s.isBefore(earliest))) {
          earliest = s;
        }
      }
      return earliest == null
          ? null
          : l10n.workflowRunStartedAgo(formatRelative(earliest));
    }
    DateTime? latest;
    for (final j in w.jobs) {
      final c = j.completedAt;
      if (c != null && (latest == null || c.isAfter(latest))) {
        latest = c;
      }
    }
    return latest == null
        ? null
        : l10n.workflowRunCompletedAgo(formatRelative(latest));
  }
}

class _JobTile extends ConsumerStatefulWidget {
  const _JobTile({
    required this.job,
    required this.isFirst,
    required this.isLast,
  });

  final CheckRun job;
  final bool isFirst;
  final bool isLast;

  @override
  ConsumerState<_JobTile> createState() => _JobTileState();
}

/// Expanded body of one workflow card: when the backing workflow run and its
/// YAML graph resolve, jobs render as a pannable left-to-right DAG with the
/// selected job's steps + logs below; otherwise (external checks, unreadable
/// workflow file) the classic flat job list renders instead.
class _WorkflowRunBody extends ConsumerStatefulWidget {
  const _WorkflowRunBody({required this.workflow});

  final WorkflowGroup workflow;

  @override
  ConsumerState<_WorkflowRunBody> createState() => _WorkflowRunBodyState();
}

class _WorkflowRunBodyState extends ConsumerState<_WorkflowRunBody> {
  String? _selectedNodeId;
  String? _selectedChildName;

  /// User-set graph height from the resize grip; null = content-aware auto.
  double? _graphHeightOverride;

  /// Smallest graph height (the resting size for shallow workflows).
  static const double _minGraphHeight = 280;

  /// Largest content-aware resting height; the grip extends beyond it.
  static const double _maxAutoGraphHeight = 560;

  /// Content-aware resting height: enough rows for the tallest column of the
  /// laid-out graph, clamped to [_minGraphHeight, _maxAutoGraphHeight]. Big
  /// workflows start bigger instead of forcing a pan; the resize grip below
  /// the canvas extends further.
  static double _autoGraphHeight(List<WorkflowJobNode> nodes) {
    final positions = WorkflowGraphLayout.compute(
      nodes,
      nodeWidth: WorkflowRunCanvas.nodeWidth,
      nodeHeight: WorkflowRunCanvas.nodeHeight,
    );
    const colPitch =
        WorkflowRunCanvas.nodeWidth + WorkflowGraphLayout.columnGap;
    const rowPitch = WorkflowRunCanvas.nodeHeight + WorkflowGraphLayout.rowGap;
    final perColumn = <int, int>{};
    for (final p in positions.values) {
      final col = (p.dx / colPitch).round();
      perColumn[col] = (perColumn[col] ?? 0) + 1;
    }
    var rows = 1;
    for (final count in perColumn.values) {
      if (count > rows) {
        rows = count;
      }
    }
    // 32px breathing room top and bottom, one pitch per row minus the gap
    // that only exists BETWEEN rows.
    final content = 64 + rows * rowPitch - WorkflowGraphLayout.rowGap;
    return content.clamp(_minGraphHeight, _maxAutoGraphHeight);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    // Groups are scoped by workflow run, so the run id is authoritative.
    final runId = widget.workflow.runId;
    if (runId == null) {
      return _flatJobList(widget.workflow.jobs);
    }

    final graphAsync = ref.watch(prWorkflowGraphProvider(runId));
    final graph = graphAsync.asData?.value;
    if (graphAsync.isLoading && graph == null) {
      return const SizedBox(
        height: 120,
        child: Center(child: CcSpinner(size: 18)),
      );
    }
    if (graph == null || graph.jobs.isEmpty) {
      // No YAML graph (moved file, GHES quirk, fetch error) — the fallback
      // IS the classic flat list; no error chrome.
      return _flatJobList(widget.workflow.jobs);
    }

    final join = matchCheckRunsToGraphNodes(graph.jobs, widget.workflow.jobs);
    _ensureSelection(graph.jobs, join.byNodeId);

    final graphHeight = _graphHeightOverride ?? _autoGraphHeight(graph.jobs);
    final selectedNodeId = _selectedNodeId;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          height: graphHeight,
          child: ClipRect(
            child: WorkflowRunCanvas(
              nodes: graph.jobs,
              checkRunsByNodeId: join.byNodeId,
              selectedNodeId: selectedNodeId,
              onSelect: (id) => setState(() {
                _selectedNodeId = id;
                _selectedChildName = null;
              }),
            ),
          ),
        ),
        _GraphResizeGrip(
          onDrag: (dy) => setState(() {
            _graphHeightOverride = ((_graphHeightOverride ?? graphHeight) + dy)
                .clamp(200.0, 1200.0);
          }),
          onReset: () => setState(() => _graphHeightOverride = null),
        ),
        const CcDivider(),
        if (selectedNodeId != null)
          _selectionDetail(
            selectedNodeId,
            graph.jobs,
            join.byNodeId,
            tokens,
            l10n,
          ),
        if (join.unmatched.isNotEmpty) ...[
          const CcDivider(),
          _flatJobList(join.unmatched),
        ],
      ],
    );
  }

  /// Keeps the selection valid as data arrives and refreshes: auto-selects
  /// the failing node (else running, else first) when nothing is selected or
  /// the selection vanished from a refreshed job list — never yanks a live
  /// selection. Mutated during build so the current frame uses the new
  /// selection immediately.
  void _ensureSelection(
    List<WorkflowJobNode> nodes,
    Map<String, List<CheckRun>> byNodeId,
  ) {
    var nodeSel = _selectedNodeId;
    if (nodeSel == null || !nodes.any((n) => n.id == nodeSel)) {
      nodeSel = nodes.first.id;
      for (final wanted in const [
        WorkflowStatus.failure,
        WorkflowStatus.running,
      ]) {
        var found = false;
        for (final n in nodes) {
          if (workflowNodeStatus(byNodeId[n.id] ?? const <CheckRun>[]) ==
              wanted) {
            nodeSel = n.id;
            found = true;
            break;
          }
        }
        if (found) {
          break;
        }
      }
    }
    _selectedNodeId = nodeSel;

    final children = byNodeId[nodeSel] ?? const <CheckRun>[];
    if (children.length > 1) {
      final childSel = _selectedChildName;
      if (childSel == null || !children.any((c) => c.name == childSel)) {
        _selectedChildName = _pickChild(children).name;
      }
    } else {
      _selectedChildName = null;
    }
  }

  /// Matrix child auto-selection: failing → running → first.
  CheckRun _pickChild(List<CheckRun> children) {
    for (final c in children) {
      if (c.isFailing) {
        return c;
      }
    }
    for (final c in children) {
      if (!c.isComplete) {
        return c;
      }
    }
    return children.first;
  }

  Widget _selectionDetail(
    String nodeId,
    List<WorkflowJobNode> nodes,
    Map<String, List<CheckRun>> byNodeId,
    DesignSystemTokens tokens,
    AppLocalizations l10n,
  ) {
    WorkflowJobNode? node;
    for (final n in nodes) {
      if (n.id == nodeId) {
        node = n;
        break;
      }
    }
    final children = byNodeId[nodeId] ?? const <CheckRun>[];
    if (node == null || children.isEmpty) {
      // The node never reported a check (skipped `if:`, unmatched name).
      return Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(
              AppIcons.minusCircle,
              size: 14,
              color: ReviewStatusColors.neutral,
            ),
            const SizedBox(width: 8),
            Text(
              l10n.neutral,
              style: CcTypography.caption.copyWith(color: tokens.textTertiary),
            ),
          ],
        ),
      );
    }
    if (children.length == 1) {
      // No chips row: give the lone detail air above and below so it doesn't
      // sit flush against the divider.
      return Padding(
        padding: const EdgeInsets.only(top: 6, bottom: 8),
        child: _childDetail(children.single),
      );
    }
    CheckRun selected = children.first;
    for (final c in children) {
      if (c.name == _selectedChildName) {
        selected = c;
        break;
      }
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final c in children)
                _childChip(node, c, c.name == selected.name, tokens),
            ],
          ),
        ),
        _childDetail(selected),
      ],
    );
  }

  /// One matrix child: the steps accordion for Actions jobs, the flat tile
  /// otherwise.
  Widget _childDetail(CheckRun c) {
    if (c.jobId != null) {
      return JobStepsAccordion(checkRun: c);
    }
    return _JobTile(job: c, isFirst: true, isLast: true);
  }

  Widget _childChip(
    WorkflowJobNode node,
    CheckRun c,
    bool selected,
    DesignSystemTokens tokens,
  ) {
    final label = matrixVariationLabel(node.name, c.name);
    final chip = CcTappable(
      onPressed: () => setState(() => _selectedChildName = c.name),
      builder: (context, states) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: selected ? tokens.bgSecondary : null,
          borderRadius: AppRadii.brSm,
          border: Border.all(color: tokens.borderSecondary),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _childGlyph(c),
            const SizedBox(width: 6),
            Text(
              label,
              style: CcTypography.caption.copyWith(
                fontWeight: FontWeight.w500,
                color: tokens.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
    // A chip shortened to its variation keeps the resolved job name reachable.
    if (label == c.name) {
      return chip;
    }
    return CcTooltip(message: c.name, child: chip);
  }

  Widget _childGlyph(CheckRun c) {
    if (c.status == CheckRunStatus.inProgress) {
      return const CcSpinner(size: 12, color: ReviewStatusColors.running);
    }
    if (c.isSuccess) {
      return const Icon(
        AppIcons.checkCircle2,
        size: 12,
        color: ReviewStatusColors.success,
      );
    }
    if (c.isFailing) {
      return const Icon(
        AppIcons.xCircle,
        size: 12,
        color: ReviewStatusColors.failure,
      );
    }
    return const Icon(
      AppIcons.minusCircle,
      size: 12,
      color: ReviewStatusColors.neutral,
    );
  }

  /// The classic flat job list — the whole body for external checks and the
  /// graph fallback, and the tail for check runs that matched no YAML node.
  Widget _flatJobList(List<CheckRun> jobs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < jobs.length; i++)
          _JobTile(job: jobs[i], isFirst: i == 0, isLast: i == jobs.length - 1),
      ],
    );
  }
}

class _JobTileState extends ConsumerState<_JobTile> {
  bool _isHovered = false;
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final codeFont = ref.watch(codeFontFamilyProvider);
    final (icon, color, label) = _statusFor(widget.job, context);
    final l10n = AppLocalizations.of(context);
    final completedAt = widget.job.completedAt;
    // Actions-backed jobs expand inline to their steps + logs; external
    // checks stay plain rows.
    final expandable = widget.job.jobId != null;
    // Duration over timestamps: `Passed · 4m 14s` beats `Passed · 5h ago`
    // for judging a job (the completion instant moves to the workflow
    // accordion header; it stays available as the hover tooltip).
    final duration = checkRunDuration(widget.job);
    final word = widget.job.isFailing
        ? l10n.failed
        : widget.job.isSuccess
        ? l10n.passed
        : label;
    final subtitle = duration != null
        ? '$word · ${formatPipelineDuration(duration)}'
        : word;

    Widget? subtitleWidget;
    if (subtitle.isNotEmpty) {
      subtitleWidget = Text(
        subtitle,
        style: CcTypography.caption.copyWith(color: tokens.textTertiary),
      );
      // The subtitle only carries a concrete instant when the job has
      // completed and reported a pass/fail; a queued/running label has none.
      if (completedAt != null &&
          (widget.job.isFailing || widget.job.isSuccess)) {
        subtitleWidget = AppTimestamp(
          dateTime: completedAt,
          child: subtitleWidget,
        );
      }
    }

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          border: widget.isLast
              ? null
              : Border(bottom: BorderSide(color: tokens.borderSecondary)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InkWell(
              onTap: expandable
                  ? () => setState(() => _expanded = !_expanded)
                  : null,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
                child: Row(
                  children: [
                    widget.job.status == CheckRunStatus.inProgress
                        ? const CcSpinner(
                            size: 16,
                            color: ReviewStatusColors.running,
                          )
                        : Icon(icon, size: 16, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            jobNameFor(widget.job),
                            style: CcTypography.caption.copyWith(
                              fontWeight: FontWeight.w500,
                              color: tokens.textPrimary,
                            ),
                          ),
                          if (subtitleWidget != null) ...[
                            const SizedBox(height: 2),
                            subtitleWidget,
                          ],
                        ],
                      ),
                    ),
                    if (widget.job.htmlUrl.isNotEmpty)
                      AnimatedOpacity(
                        opacity: _isHovered ? 1 : 0,
                        duration: const Duration(milliseconds: 150),
                        child: CcButton(
                          variant: widget.job.isFailing
                              ? CcButtonVariant.destructive
                              : CcButtonVariant.ghost,
                          size: CcButtonSize.sm,
                          icon: AppIcons.externalLink,
                          onPressed: () => openExternalUrl(widget.job.htmlUrl),
                          child: Text(l10n.viewLogs),
                        ),
                      ),
                    if (expandable) ...[
                      const SizedBox(width: 6),
                      Icon(
                        _expanded ? AppIcons.chevronUp : AppIcons.chevronDown,
                        size: 14,
                        color: tokens.textTertiary,
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_expanded && expandable)
              JobStepsAccordion(checkRun: widget.job),
            if (widget.job.isFailing && widget.job.output.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 12, 12),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: tokens.bgPrimary,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: tokens.borderSecondary),
                  ),
                  child: SelectableText(
                    widget.job.output,
                    style: AppFonts.codeStyleDynamic(
                      codeFont,
                      fontSize: 12,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  (IconData, Color, String) _statusFor(CheckRun c, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!c.isComplete) {
      return (
        AppIcons.loader,
        const Color(0xFF1F75FE),
        c.status == CheckRunStatus.queued ? l10n.queued : l10n.runningLabel,
      );
    }
    if (c.isSuccess) {
      return (
        AppIcons.checkCircle2,
        const Color(0xFF2DA44E),
        l10n.successLabel,
      );
    }
    if (c.isFailing) {
      return (AppIcons.xCircle, const Color(0xFFCF222E), l10n.failure);
    }
    return (
      AppIcons.minusCircle,
      (context.designSystem ?? DesignSystemTokens.light()).textTertiary,
      l10n.neutral,
    );
  }
}

/// Bottom grip that grows the workflow graph canvas vertically. Dragging
/// extends the height (clamped to 200-1200); a double-tap restores the
/// content-aware resting height.
class _GraphResizeGrip extends StatelessWidget {
  /// _GraphResizeGrip({.
  const _GraphResizeGrip({required this.onDrag, required this.onReset});

  /// Called with the vertical drag delta while the grip is dragged.
  final ValueChanged<double> onDrag;

  /// Called when the grip is double-tapped (reset to auto height).
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return Semantics(
      label: l10n.resizeGraph,
      child: MouseRegion(
        cursor: SystemMouseCursors.resizeUpDown,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onVerticalDragUpdate: (d) => onDrag(d.delta.dy),
          onDoubleTap: onReset,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: tokens.borderSecondary,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
