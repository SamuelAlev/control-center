import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:control_center/features/pr_review/domain/entities/check_run.dart';
import 'package:control_center/features/pr_review/presentation/notifiers/pr_checks_ui_notifier.dart';
import 'package:control_center/features/pr_review/presentation/screens/pull_request_detail/pr_files_tab.dart';
import 'package:control_center/features/pr_review/presentation/utils/relative_time.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_sidebar.dart'
    show WorkflowStatusIcon, workflowStatusStyle;
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:url_launcher/url_launcher.dart';

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

  GlobalKey _keyFor(String workflow) =>
      _workflowKeys.putIfAbsent(workflow, GlobalKey.new);

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading && widget.checks.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: FCircularProgress()),
      );
    }
    if (widget.error != null && widget.checks.isEmpty) {
      return SectionError(error: widget.error!);
    }

    final ui = ref.watch(prChecksUiProvider);
    final workflows = groupChecksByWorkflow(widget.checks);

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
      return Padding(
        padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
        child: FCard.raw(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Text(
                'No checks have run on this commit.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: context.theme.colors.mutedForeground,
                ),
              ),
            ),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 16, 0, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < workflows.length; i++) ...[
            _WorkflowCard(
              key: _keyFor(workflows[i].name),
              workflow: workflows[i],
              expanded: ui.expandedWorkflows.contains(workflows[i].name),
              onToggle: () => ref
                  .read(prChecksUiProvider.notifier)
                  .toggleExpanded(workflows[i].name),
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
    final theme = context.theme;
    final style = workflowStatusStyle(workflow.status, context);
    final isFailing = workflow.status == WorkflowStatus.failure;
    return Container(
      decoration: BoxDecoration(
        color: isFailing
            ? const Color(0xFFCF222E).withValues(alpha: 0.04)
            : theme.colors.background,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: isFailing
              ? const Color(0xFFCF222E).withValues(alpha: 0.25)
              : theme.colors.border,
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
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: theme.colors.foreground,
                              ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _summaryFor(workflow),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: style.color,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                    size: 16,
                    color: theme.colors.mutedForeground,
                  ),
                ],
              ),
            ),
          ),
          if (expanded) ...[
            const FDivider(),
            ...List.generate(workflow.jobs.length, (i) {
              final job = workflow.jobs[i];
              return _JobTile(
                job: job,
                isFirst: i == 0,
                isLast: i == workflow.jobs.length - 1,
              );
            }),
          ],
        ],
      ),
    );
  }

  String _summaryFor(WorkflowGroup w) {
    final total = w.jobs.length;
    final jobsLabel = '$total job${total == 1 ? '' : 's'}';
    switch (w.status) {
      case WorkflowStatus.running:
        return 'Running — $jobsLabel';
      case WorkflowStatus.success:
        return 'All checks passed — $jobsLabel';
      case WorkflowStatus.failure:
        return '${w.failingCount} of $total job${total == 1 ? '' : 's'} failed';
      case WorkflowStatus.neutral:
        return 'Completed — $jobsLabel';
    }
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

class _JobTileState extends ConsumerState<_JobTile> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final codeFont = ref.watch(codeFontFamilyProvider);
    final (icon, color, label) = _statusFor(widget.job, context);
    final l10n = AppLocalizations.of(context);
    final completedAt = widget.job.completedAt;
    final subtitle = widget.job.isFailing
        ? 'Failed${completedAt != null ? ' · ${formatRelative(completedAt)}' : ''}'
        : widget.job.isSuccess
        ? 'Passed${completedAt != null ? ' · ${formatRelative(completedAt)}' : ''}'
        : label;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        decoration: BoxDecoration(
          border: widget.isLast
              ? null
              : Border(bottom: BorderSide(color: theme.colors.border)),
        ),
        padding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        jobNameFor(widget.job),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: theme.colors.foreground,
                        ),
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(color: theme.colors.mutedForeground),
                        ),
                      ],
                    ],
                  ),
                ),
                if (widget.job.htmlUrl.isNotEmpty)
                  AnimatedOpacity(
                    opacity: _isHovered ? 1 : 0,
                    duration: const Duration(milliseconds: 150),
                    child: FButton(
                      variant: widget.job.isFailing
                          ? FButtonVariant.destructive
                          : FButtonVariant.ghost,
                      size: FButtonSizeVariant.sm,
                      prefix: const Icon(LucideIcons.externalLink, size: 12),
                      mainAxisSize: MainAxisSize.min,
                      onPress: () => launchUrl(Uri.parse(widget.job.htmlUrl)),
                      child: Text(l10n.viewLogs),
                    ),
                  ),
              ],
            ),
            if (widget.job.isFailing && widget.job.output.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: theme.colors.background,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: theme.colors.border),
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
            ],
          ],
        ),
      ),
    );
  }

  (IconData, Color, String) _statusFor(CheckRun c, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (!c.isComplete) {
      return (
        LucideIcons.loader,
        const Color(0xFF1F75FE),
        c.status == CheckRunStatus.queued ? l10n.queued : l10n.runningLabel,
      );
    }
    if (c.isSuccess) {
      return (
        LucideIcons.checkCircle2,
        const Color(0xFF2DA44E),
        l10n.successLabel,
      );
    }
    if (c.isFailing) {
      return (LucideIcons.xCircle, const Color(0xFFCF222E), l10n.failure);
    }
    return (
      LucideIcons.minusCircle,
      context.theme.colors.mutedForeground,
      l10n.neutral,
    );
  }
}
