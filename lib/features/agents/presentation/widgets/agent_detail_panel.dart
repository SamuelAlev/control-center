import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/agent_run_log.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_activity_heatmap.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_status.dart';
import 'package:control_center/features/agents/presentation/widgets/skill_chip.dart';
import 'package:control_center/features/agents/providers/agent_management_providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// The right-hand detail surface of the agents master-detail view.
///
/// Replaces the old read-only modal: it keeps the roster visible, reports the
/// agent's live state, resolves the reporting line to a name, and carries the
/// real edit / delete actions plus the activity heatmap.
class AgentDetailPanel extends ConsumerWidget {
  /// Creates an [AgentDetailPanel].
  const AgentDetailPanel({
    super.key,
    required this.agent,
    required this.onEdit,
    required this.onDeleted,
    this.onClose,
  });

  /// The agent being inspected.
  final Agent agent;

  /// Invoked when the operator chooses to edit the agent.
  final VoidCallback onEdit;

  /// Invoked after the agent has been deleted, so the host can clear selection.
  final VoidCallback onDeleted;

  /// Optional close handler — shown as a back affordance in narrow layouts.
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem!;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final runsKey = (workspaceId: agent.workspaceId, agentId: agent.id);
    final state = ref.watch(agentLiveStateProvider(runsKey));
    final lastActive = ref.watch(agentLastActiveProvider(runsKey));
    final siblings =
        ref.watch(workspaceAgentsProvider(agent.workspaceId)).asData?.value ??
        const <Agent>[];
    final managerName = agent.reportsTo == null
        ? null
        : siblings
              .where((a) => a.id == agent.reportsTo)
              .map((a) => a.name)
              .firstOrNull;

    final skills = agent.skills.toList();

    final heatmap = AgentActivityHeatmap(agentId: agent.id);

    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          agent.name,
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: tokens.textPrimary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          agent.title,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: tokens.textTertiary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            AgentStatusBadge(state: state),
            if (lastActive != null) ...[
              const SizedBox(width: 10),
              Text(
                l10n.lastActiveAgo(_relativeTime(lastActive)),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ],
    );

    return Container(
      color: tokens.bgPrimary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Above this width the activity heatmap rides inline at the top-right
          // of the header — mirroring the GitHub user profile page. Below it,
          // the panel is too narrow, so the heatmap falls back to a stacked
          // section at the bottom.
          final heatmapInline = constraints.maxWidth >= 620;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: tokens.bgSecondary,
                  border: Border.all(color: tokens.borderSecondary),
                  borderRadius: AppRadii.brLg,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (onClose != null) ...[
                      CcIconButton(
                        icon: LucideIcons.arrowLeft,
                        onPressed: onClose,
                      ),
                      const SizedBox(width: 8),
                    ],
                    AgentAvatar(
                      agentId: agent.id,
                      name: agent.name,
                      size: 56,
                      showHoverCard: false,
                    ),
                    const SizedBox(width: 16),
                    Expanded(child: infoColumn),
                    if (heatmapInline) ...[const SizedBox(width: 20), heatmap],
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  CcButton(
                    onPressed: onEdit,
                    variant: CcButtonVariant.secondary,
                    icon: LucideIcons.pencil,
                    child: Text(l10n.edit),
                  ),
                  const SizedBox(width: 8),
                  CcButton(
                    onPressed: () => _confirmDelete(context, ref, l10n),
                    variant: CcButtonVariant.ghost,
                    icon: LucideIcons.trash2,
                    child: Text(
                      l10n.delete,
                      style: TextStyle(color: tokens.textErrorPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const CcDivider(),
              const SizedBox(height: 16),
              _DetailRow(
                label: l10n.reportsTo,
                child: managerName != null
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AgentAvatar(
                            agentId: agent.reportsTo!,
                            name: managerName,
                            size: 18,
                            showHoverCard: false,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            managerName,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: tokens.textSecondary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        l10n.reportsToNobody,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: tokens.textQuaternary,
                        ),
                      ),
              ),
              if (agent.role != null)
                _DetailRow(
                  label: l10n.roleLabel,
                  child: Text(
                    agent.role!.label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                    ),
                  ),
                ),
              if (agent.agentMdPath.isNotEmpty)
                _DetailRow(
                  label: l10n.pathLabel,
                  child: _PathValue(path: agent.agentMdPath),
                ),
              if (skills.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  l10n.skillsColon,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [for (final s in skills) SkillChip(label: s)],
                ),
              ],
              if (agent.hasPersona) ...[
                const SizedBox(height: 16),
                Text(
                  l10n.personaColon,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: tokens.bgSecondary,
                    borderRadius: AppRadii.brSm,
                    border: Border.all(color: tokens.borderSecondary),
                  ),
                  child: Text(
                    agent.persona!,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: tokens.textSecondary,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 20),
              Text(
                l10n.recentRuns,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: tokens.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              _RecentRuns(runsKey: runsKey),
              if (!heatmapInline) ...[
                const SizedBox(height: 20),
                Text(
                  l10n.activity,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: tokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                heatmap,
              ],
            ],
          );
        },
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    AppLocalizations l10n,
  ) async {
    final toaster = CcToastScope.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.deleteAgent,
        content: Text(l10n.deleteAgentConfirm(agent.name)),
        actions: [
          CcButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    try {
      await ref
          .read(deleteAgentUseCaseProvider)
          .execute(agentId: agent.id, workspaceId: agent.workspaceId);
      onDeleted();
    } catch (e) {
      toaster.show(
        l10n.errorWithDetail(e.toString()),
        variant: CcToastVariant.danger,
      );
    }
  }

  /// Compact relative-time token (e.g. "2m", "3h", "5d", "2w"). The
  /// surrounding sentence ("Active … ago") is localized; these short units
  /// are deliberately kept terse and language-neutral.
  String _relativeTime(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) {
      return 'now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h';
    }
    if (diff.inDays < 7) {
      return '${diff.inDays}d';
    }
    return '${(diff.inDays / 7).floor()}w';
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: tokens.textTertiary),
            ),
          ),
          Expanded(child: child),
        ],
      ),
    );
  }
}

/// The agent's most recent runs: status, when, duration, cost, and an error
/// family chip on failures. Each row opens a small menu with run links (copy
/// run id, copy log path) so a run can be correlated and its NDJSON revealed.
class _RecentRuns extends ConsumerWidget {
  const _RecentRuns({required this.runsKey});

  final AgentRunsKey runsKey;

  static const int _max = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem!;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final logsAsync = ref.watch(agentRunLogsProvider(runsKey));

    return logsAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Center(child: CcSpinner()),
      ),
      error: (e, _) => Text(
        l10n.failedToLoadLogs('$e'),
        style: theme.textTheme.bodySmall?.copyWith(color: tokens.textTertiary),
      ),
      data: (logs) {
        if (logs.isEmpty) {
          return Text(
            l10n.noRunsYet,
            style:
                theme.textTheme.bodySmall?.copyWith(color: tokens.textQuaternary),
          );
        }
        final shown = logs.take(_max).toList();
        return Container(
          decoration: BoxDecoration(
            color: tokens.bgSecondary,
            border: Border.all(color: tokens.borderSecondary),
            borderRadius: AppRadii.brLg,
          ),
          child: Column(
            children: [
              for (var i = 0; i < shown.length; i++)
                _RunRow(
                  log: shown[i],
                  isLast: i == shown.length - 1,
                  tokens: tokens,
                  theme: theme,
                  l10n: l10n,
                ),
            ],
          ),
        );
      },
    );
  }
}

class _RunRow extends StatelessWidget {
  const _RunRow({
    required this.log,
    required this.isLast,
    required this.tokens,
    required this.theme,
    required this.l10n,
  });

  final AgentRunLog log;
  final bool isLast;
  final DesignSystemTokens tokens;
  final ThemeData theme;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = switch (log.status) {
      RunStatus.completed => (LucideIcons.circleCheck, tokens.fgSuccessPrimary),
      RunStatus.error => (LucideIcons.circleX, tokens.fgErrorPrimary),
      RunStatus.running => (LucideIcons.loaderCircle, tokens.fgBrandPrimary),
      RunStatus.pending => (LucideIcons.clock, tokens.textQuaternary),
    };
    final durationLabel = log.completedAt == null
        ? null
        : _fmtDuration(log.completedAt!.difference(log.startedAt));
    final costCents = log.cost.estimatedCostCents;
    final family = log.errorFamily;
    final showFamily = log.status == RunStatus.error &&
        family != null &&
        family != RunErrorFamily.unknown;

    return Container(
      decoration: BoxDecoration(
        border: isLast
            ? null
            : Border(bottom: BorderSide(color: tokens.borderSecondary)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _fmtWhen(log.startedAt),
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: tokens.textSecondary),
              ),
            ),
            if (showFamily) ...[
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: tokens.bgPrimary,
                  borderRadius: AppRadii.brSm,
                  border: Border.all(color: tokens.borderSecondary),
                ),
                child: Text(
                  family.name,
                  style: theme.textTheme.labelSmall
                      ?.copyWith(color: tokens.textErrorPrimary),
                ),
              ),
              const SizedBox(width: 8),
            ],
            if (durationLabel != null) ...[
              Text(
                durationLabel,
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: tokens.textQuaternary),
              ),
              const SizedBox(width: 8),
            ],
            if (costCents > 0)
              Text(
                _fmtCost(costCents),
                style: theme.textTheme.labelSmall
                    ?.copyWith(color: tokens.textTertiary),
              ),
            MenuAnchor(
              menuChildren: [
                MenuItemButton(
                  leadingIcon: const Icon(LucideIcons.copy, size: 14),
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: log.id));
                    CcToastScope.of(context).show(
                      l10n.runIdCopied,
                      variant: CcToastVariant.success,
                    );
                  },
                  child: Text(l10n.copyRunId),
                ),
                if (log.logPath != null)
                  MenuItemButton(
                    leadingIcon: const Icon(LucideIcons.fileText, size: 14),
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: log.logPath!));
                      CcToastScope.of(context).show(
                        l10n.pathCopied,
                        variant: CcToastVariant.success,
                      );
                    },
                    child: Text(l10n.copyLogPath),
                  ),
              ],
              builder: (context, controller, _) => IconButton(
                icon: Icon(
                  LucideIcons.ellipsis,
                  size: 14,
                  color: tokens.textQuaternary,
                ),
                padding: EdgeInsets.zero,
                constraints:
                    const BoxConstraints(minWidth: 24, minHeight: 24),
                onPressed: () => controller.isOpen
                    ? controller.close()
                    : controller.open(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmtWhen(DateTime when) {
    final diff = DateTime.now().difference(when);
    if (diff.inMinutes < 1) {
      return l10n.justNow;
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    return '${diff.inDays}d ago';
  }

  String _fmtDuration(Duration d) {
    if (d.inSeconds < 60) {
      return '${d.inSeconds}s';
    }
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return s == 0 ? '${m}m' : '${m}m ${s}s';
  }

  String _fmtCost(int cents) {
    final dollars = cents / 100;
    if (dollars < 0.01) {
      return '<\$0.01';
    }
    return '\$${dollars.toStringAsFixed(2)}';
  }
}

class _PathValue extends StatelessWidget {
  const _PathValue({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            _abbreviate(path),
            style: const TextStyle(
              fontFamily: 'JetBrains Mono',
              fontFamilyFallback: ['monospace'],
              fontSize: 12,
              height: 1.4,
            ).copyWith(color: tokens.textTertiary),
          ),
        ),
        const SizedBox(width: 8),
        Tooltip(
          message: l10n.copyPath,
          child: CcIconButton(
            icon: LucideIcons.copy,
            onPressed: () {
              Clipboard.setData(ClipboardData(text: path));
              CcToastScope.of(context)
                  .show(l10n.pathCopied, variant: CcToastVariant.success);
            },
          ),
        ),
      ],
    );
  }

  /// Collapses the user's home directory to `~` so the path reads cleanly
  /// instead of dumping the full Application Support location. Done with pure
  /// string matching — presentation has no `dart:io` access.
  String _abbreviate(String full) {
    return full
        .replaceFirst(RegExp(r'^/Users/[^/]+/'), '~/')
        .replaceFirst(RegExp(r'^/home/[^/]+/'), '~/')
        .replaceFirst(RegExp(r'^C:\\Users\\[^\\]+\\'), r'~\');
  }
}
