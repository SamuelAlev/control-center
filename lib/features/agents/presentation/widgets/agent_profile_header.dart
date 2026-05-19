import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_activity_heatmap.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_status.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The agent identity header: avatar, name, title, live status badge, and
/// last-active timestamp, with an optional 6-month activity heatmap.
///
/// Extracted from `AgentDetailPanel` so the fleet-roster header and the
/// settings agent-registry header read identically. In [compact] mode (used
/// by the config-dense settings page) the heatmap is omitted and the spacing
/// tightens so the form/logs/memory tabs keep their vertical room; the full
/// mode (global Agents page) keeps the heatmap, which rides inline at
/// ≥[_heatmapInlineBreakpoint] px and stacks beneath the identity row below.
class AgentProfileHeader extends ConsumerWidget {
  /// Creates an [AgentProfileHeader].
  const AgentProfileHeader({
    super.key,
    required this.agent,
    this.leading,
    this.compact = false,
  });

  /// The agent whose identity is shown.
  final Agent agent;

  /// Optional widget rendered before the avatar — e.g. a back affordance in
  /// narrow master-detail layouts.
  final Widget? leading;

  /// Tightens spacing and drops the activity heatmap. For surfaces where the
  /// header sits above scrolling config content (the agent registry).
  final bool compact;

  /// Above this width the activity heatmap rides inline at the header's
  /// top-right; below it the heatmap stacks beneath the identity row.
  static const _heatmapInlineBreakpoint = 620.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem!;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    final runsKey = (workspaceId: agent.workspaceId, agentId: agent.id);
    final state = ref.watch(agentLiveStateProvider(runsKey));
    final lastActive = ref.watch(agentLastActiveProvider(runsKey));

    final avatarSize = compact ? 44.0 : 56.0;
    final nameStyle = (compact
            ? theme.textTheme.titleMedium
            : theme.textTheme.titleLarge)
        ?.copyWith(fontWeight: FontWeight.w700, color: tokens.textPrimary);

    final infoColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          agent.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: nameStyle,
        ),
        const SizedBox(height: 2),
        Text(
          agent.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
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

    final identityRow = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (leading != null) ...[leading!, const SizedBox(width: 8)],
        AgentAvatar(
          agentId: agent.id,
          name: agent.name,
          size: avatarSize,
          showHoverCard: false,
        ),
        const SizedBox(width: 16),
        Expanded(child: infoColumn),
      ],
    );

    if (compact) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: tokens.bgSecondary,
          border: Border.all(color: tokens.borderSecondary),
          borderRadius: AppRadii.brLg,
        ),
        child: identityRow,
      );
    }

    final heatmap = AgentActivityHeatmap(agentId: agent.id);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        border: Border.all(color: tokens.borderSecondary),
        borderRadius: AppRadii.brLg,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inline = constraints.maxWidth >= _heatmapInlineBreakpoint;
          if (inline) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: identityRow),
                const SizedBox(width: 20),
                heatmap,
              ],
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              identityRow,
              const SizedBox(height: 16),
              heatmap,
            ],
          );
        },
      ),
    );
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
