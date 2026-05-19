import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
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
import 'package:forui/forui.dart';
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

    final state = ref.watch(agentLiveStateProvider(agent.id));
    final lastActive = ref.watch(agentLastActiveProvider(agent.id));
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
                      FButton.icon(
                        onPress: onClose,
                        variant: FButtonVariant.ghost,
                        child: const Icon(LucideIcons.arrowLeft, size: 18),
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
                  FButton(
                    onPress: onEdit,
                    variant: FButtonVariant.outline,
                    mainAxisSize: MainAxisSize.min,
                    prefix: const Icon(LucideIcons.pencil, size: 16),
                    child: Text(l10n.edit),
                  ),
                  const SizedBox(width: 8),
                  FButton(
                    onPress: () => _confirmDelete(context, ref, l10n),
                    variant: FButtonVariant.ghost,
                    mainAxisSize: MainAxisSize.min,
                    prefix: Icon(
                      LucideIcons.trash2,
                      size: 16,
                      color: tokens.textErrorPrimary,
                    ),
                    child: Text(
                      l10n.delete,
                      style: TextStyle(color: tokens.textErrorPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const FDivider(),
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
    final messenger = ScaffoldMessenger.maybeOf(context);
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(l10n.deleteAgent),
        body: Text(l10n.deleteAgentConfirm(agent.name)),
        actions: [
          FButton(
            onPress: () => Navigator.of(ctx).pop(false),
            variant: FButtonVariant.outline,
            mainAxisSize: MainAxisSize.min,
            child: Text(l10n.cancel),
          ),
          FButton(
            onPress: () => Navigator.of(ctx).pop(true),
            variant: FButtonVariant.destructive,
            mainAxisSize: MainAxisSize.min,
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
      messenger?.showSnackBar(
        SnackBar(content: Text(l10n.errorWithDetail(e.toString()))),
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

class _PathValue extends StatelessWidget {
  const _PathValue({required this.path});

  final String path;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final messenger = ScaffoldMessenger.maybeOf(context);
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
          child: FButton.icon(
            onPress: () {
              Clipboard.setData(ClipboardData(text: path));
              messenger?.showSnackBar(SnackBar(content: Text(l10n.pathCopied)));
            },
            variant: FButtonVariant.ghost,
            child: const Icon(LucideIcons.copy, size: 14),
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
