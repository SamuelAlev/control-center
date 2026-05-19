import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_activity_heatmap.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/shared/widgets/github_user_hover_card.dart' show GitHubUserHoverCard;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Mirror of [GitHubUserHoverCard] for AI agents — same shell, but the
/// heatmap is fed by analytics daily stats instead of GitHub contributions.
class AgentHoverCard extends ConsumerWidget {
  /// Creates an [AgentHoverCard] for [agentId].
  const AgentHoverCard({super.key, required this.agentId});

  /// The agent to render.
  final String agentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem!;
    final theme = Theme.of(context);

    final agentAsync = ref.watch(agentDetailProvider(agentId));

    return Material(
      elevation: 0,
      borderRadius: AppRadii.brLg,
      color: tokens.bgPrimary,
      child: Container(
        width: 400,
        constraints: const BoxConstraints(maxHeight: 480),
        decoration: BoxDecoration(
          color: tokens.bgPrimary,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: tokens.borderSecondary),
          boxShadow: AppShadows.golden,
        ),
        child: agentAsync.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: CcSpinner()),
          ),
          error: (err, _) => SizedBox(
            height: 80,
            child: Center(
              child: Text(
                err.toString(),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ),
          ),
          data: (agent) => _buildContent(tokens, theme, agent),
        ),
      ),
    );
  }

  Widget _buildContent(
    DesignSystemTokens tokens,
    ThemeData theme,
    Agent? agent,
  ) {
    if (agent == null) {
      return SizedBox(
        height: 80,
        child: Center(
          child: Text(
            'Agent not found',
            style: theme.textTheme.bodySmall?.copyWith(
              color: tokens.textTertiary,
            ),
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(tokens, theme, agent),
          const SizedBox(height: 14),
          AgentActivityHeatmap(agentId: agentId),
        ],
      ),
    );
  }

  Widget _buildHeader(
    DesignSystemTokens tokens,
    ThemeData theme,
    Agent agent,
  ) {
    final initial = agent.name.isNotEmpty ? agent.name[0].toUpperCase() : '?';
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CcAvatar(size: 56, initials: initial),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                agent.name,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                agent.title,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: tokens.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (agent.hasPersona) ...[
                const SizedBox(height: 6),
                Text(
                  agent.persona!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: tokens.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
