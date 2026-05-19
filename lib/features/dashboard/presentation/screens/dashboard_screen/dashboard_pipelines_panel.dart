import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:control_center/core/theme/app_spacing.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/dashboard/presentation/screens/dashboard_screen/dashboard_shared.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/utils/relative_time.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// The "Pipelines" section — the last five runs in the workspace as a compact
/// list. Each row reveals a retry action on hover. Renders nothing when the
/// workspace has no runs.
class DashboardPipelinesPanel extends ConsumerWidget {
  /// Creates a [DashboardPipelinesPanel].
  const DashboardPipelinesPanel({super.key, required this.codeFont});

  /// User-selected code font.
  final String codeFont;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final runs =
        ref.watch(workspacePipelineRunsProvider(workspaceId)).asData?.value ??
        const <PipelineRun>[];
    if (runs.isEmpty) {
      return const SizedBox.shrink();
    }

    final sorted = [...runs]..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    final latest = sorted.take(5).toList();

    final templates =
        ref.watch(pipelineTemplatesProvider(workspaceId)).asData?.value ??
        const <PipelineDefinition>[];
    String nameFor(String templateId) {
      for (final t in templates) {
        if (t.templateId == templateId) {
          return t.name;
        }
      }
      return templateId;
    }

    final l10n = AppLocalizations.of(context);
    final failedCount =
        runs.where((r) => r.status == PipelineRunStatus.failed).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        DashboardSectionHeader(
          title: l10n.pipelinesSectionTitle,
          count: failedCount > 0 ? '$failedCount' : null,
          codeFont: codeFont,
          trailing: DashboardLinkArrow(
            label: l10n.allRuns,
            onTap: () => GoRouter.of(context).go(pipelinesRoute(workspaceId)),
          ),
        ),
        DashboardPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < latest.length; i++)
                _RunRow(
                  run: latest[i],
                  name: nameFor(latest[i].templateId),
                  last: i == latest.length - 1,
                  codeFont: codeFont,
                  l10n: l10n,
                ),
            ],
          ),
        ),
      ],
    );
  }
}

Color _runColor(PipelineRunStatus status, DesignSystemTokens ds) =>
    switch (status) {
      PipelineRunStatus.completed => ds.success,
      PipelineRunStatus.failed => ds.danger,
      PipelineRunStatus.running => ds.accent,
      PipelineRunStatus.pending ||
      PipelineRunStatus.suspended ||
      PipelineRunStatus.cancelled =>
        ds.muted,
    };

String _runStatusLabel(PipelineRunStatus status, AppLocalizations l10n) =>
    switch (status) {
      PipelineRunStatus.completed => l10n.pipelineStatusCompleted,
      PipelineRunStatus.failed => l10n.pipelineStatusFailed,
      PipelineRunStatus.running => l10n.pipelineStatusRunning,
      PipelineRunStatus.pending => l10n.pipelineStatusPending,
      PipelineRunStatus.suspended => l10n.pipelineStatusSuspended,
      PipelineRunStatus.cancelled => l10n.pipelineStatusCancelled,
    };

class _RunRow extends StatefulWidget {
  const _RunRow({
    required this.run,
    required this.name,
    required this.last,
    required this.codeFont,
    required this.l10n,
  });

  final PipelineRun run;
  final String name;
  final bool last;
  final String codeFont;
  final AppLocalizations l10n;

  @override
  State<_RunRow> createState() => _RunRowState();
}

class _RunRowState extends State<_RunRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final ds = dashTokens(context);
    final run = widget.run;
    final l10n = widget.l10n;
    final color = _runColor(run.status, ds);
    final time = formatRelativeTime(context, run.finishedAt ?? run.startedAt);
    final automatic = run.triggerEventType != null &&
        !run.triggerEventType!.toLowerCase().contains('manual');
    final trigger =
        automatic ? l10n.pipelineRunTriggerAuto : l10n.pipelineRunTriggerManual;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => GoRouter.of(context)
            .go(pipelineRunRoute(context.currentWorkspaceId!, run.id)),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: _hover ? ds.hover : null,
            border: widget.last
                ? null
                : Border(bottom: BorderSide(color: ds.borderPrimary)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: ds.fg,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      '${_runStatusLabel(run.status, l10n)} · $time · $trigger',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: dashMono(widget.codeFont, size: 11, color: ds.muted),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              // Retry — pinned far right, revealed on row hover.
              IgnorePointer(
                ignoring: !_hover,
                child: AnimatedOpacity(
                  opacity: _hover ? 1 : 0,
                  duration: const Duration(milliseconds: 120),
                  child: DashboardButton(
                    label: l10n.retry,
                    style: DashButtonStyle.cream,
                    small: true,
                    onTap: () => GoRouter.of(context)
                        .go(pipelineRunRoute(context.currentWorkspaceId!, run.id)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
