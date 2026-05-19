import 'package:cc_domain/core/domain/value_objects/agent_lifecycle_status.dart';
import 'package:cc_domain/features/governance/domain/value_objects/agent_presence.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_node.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders the agent org chart for a workspace as an indented reporting tree:
/// the CEO / top-level agents at the root, specialists nested under their
/// manager via `reportsTo`. Each row surfaces the agent's title, role, and
/// governance lifecycle status (status is never conveyed by colour alone — it
/// carries an explicit label).
class OrgChartView extends ConsumerWidget {
  /// Creates an [OrgChartView] for [workspaceId].
  const OrgChartView({super.key, required this.workspaceId});

  /// The workspace whose org chart is rendered.
  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    final roots = ref.watch(orgChartProvider(workspaceId));
    // Computed presence (availability × workload) per agent, read over RPC.
    // Empty while loading or if the read fails — the chart still renders.
    final presence =
        ref.watch(workspacePresenceProvider(workspaceId)).asData?.value ??
        const <String, AgentPresence>{};

    if (roots.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Text(
          l10n.orgChartEmpty,
          style: CcTypography.bodySm.copyWith(color: tokens.textTertiary),
        ),
      );
    }

    final rows = <Widget>[];
    for (final root in roots) {
      _collect(root, 0, rows, presence);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: rows,
    );
  }

  void _collect(
    OrgNode node,
    int depth,
    List<Widget> out,
    Map<String, AgentPresence> presence,
  ) {
    out.add(
      _OrgRow(node: node, depth: depth, presence: presence[node.agent.id]),
    );
    for (final child in node.reports) {
      _collect(child, depth + 1, out, presence);
    }
  }
}

class _OrgRow extends StatelessWidget {
  const _OrgRow({required this.node, required this.depth, this.presence});

  final OrgNode node;
  final int depth;
  final AgentPresence? presence;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    final agent = node.agent;
    final isPaused = agent.lifecycleStatus == AgentLifecycleStatus.paused;
    final isArchived = agent.lifecycleStatus == AgentLifecycleStatus.archived;
    final presence = this.presence;

    return Padding(
      padding: EdgeInsets.only(
        left: depth * AppSpacing.lg,
        top: AppSpacing.xxs,
        bottom: AppSpacing.xxs,
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: tokens.panel,
          borderRadius: AppRadii.brMd,
          border: Border.all(color: tokens.borderSecondary),
        ),
        child: Row(
          children: [
            AgentAvatar(
              agentId: agent.id,
              name: agent.name,
              size: 24,
              showHoverCard: false,
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    agent.title,
                    style: CcTypography.bodySm.copyWith(
                      color: tokens.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    agent.role?.label ?? agent.name,
                    style: CcTypography.caption.copyWith(
                      color: tokens.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Live presence (availability × workload), e.g.
                  // "online + working (2/3)" — never colour-only; the label is
                  // explicit text. Omitted until the RPC presence read resolves.
                  if (presence != null)
                    Text(
                      presence.summary,
                      style: CcTypography.caption.copyWith(
                        color: presence.hasFreeSlot
                            ? tokens.textTertiary
                            : tokens.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            if (isPaused || isArchived) ...[
              const SizedBox(width: AppSpacing.sm),
              CcBadge(
                label: agent.lifecycleStatus.label,
                variant: isPaused
                    ? CcBadgeVariant.warning
                    : CcBadgeVariant.neutral,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
