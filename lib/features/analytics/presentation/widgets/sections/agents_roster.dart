import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/analytics/domain/entities/agent_scorecard.dart';
import 'package:control_center/features/analytics/presentation/widgets/sections/analytics_shared.dart';
import 'package:control_center/features/analytics/providers/analytics_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A searchable, sortable roster of workspace agents showing their scorecards
/// and linking to each agent's detail page.
class AgentsRoster extends ConsumerWidget {
/// Creates the roster widget with search text, sort mode, and change callback.
  const AgentsRoster({super.key, 
    required this.controller,
    required this.query,
    required this.sort,
    required this.onSortChanged,
  });

/// Controller for the search text field.
  final TextEditingController controller;
/// Current search query string.
  final String query;
/// Active sort mode for the agent list.
  final AgentSort sort;
/// Callback invoked when the user changes the sort mode.
  final ValueChanged<AgentSort> onSortChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);

    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final scorecards = ref.watch(allAgentScorecardsProvider);
    final agents = workspaceId != null
        ? ref.watch(workspaceAgentsProvider(workspaceId))
        : ref.watch(agentsProvider);
    final totalAgents = agents.value?.length ?? 0;

    return SectionCard(
      label: l10n.agentsLabel,
      title: Text(l10n.allAgentsCount(totalAgents)),
      trailing: SizedBox(
        width: 220,
        child: FTextField(
          control: FTextFieldControl.managed(controller: controller),
          hint: l10n.searchAgents,
          prefixBuilder: (_, _, _) => const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(LucideIcons.search, size: 14),
          ),
          inputFormatters: [LengthLimitingTextInputFormatter(40)],
        ),
      ),
      child: scorecards.when(
        loading: () => const SizedBox(
          height: 180,
          child: Center(child: FCircularProgress()),
        ),
        error: (e, _) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 24),
          child: Center(child: Text(l10n.failedWithError('$e'))),
        ),
        data: (cards) {
          if (cards.isEmpty) {
            return const SectionEmpty(
              icon: LucideIcons.users,
              message: 'No agent activity yet',
            );
          }

          final filtered = cards
              .where((c) => query.isEmpty ||
                  c.agentName.toLowerCase().contains(query.toLowerCase()))
              .toList()
            ..sort((a, b) {
              switch (sort) {
                case AgentSort.xp:
                  return b.totalXp.compareTo(a.totalXp);
                case AgentSort.runs:
                  return b.totalRuns.compareTo(a.totalRuns);
                case AgentSort.success:
                  return b.successRate.compareTo(a.successRate);
                case AgentSort.prsMerged:
                  return b.totalPrsMerged.compareTo(a.totalPrsMerged);
              }
            });

          final maxXp = filtered.isEmpty
              ? 1
              : filtered.map((c) => c.totalXp).reduce((a, b) => a > b ? a : b);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _AgentsHeaderRow(sort: sort, onSortChanged: onSortChanged),
              const SizedBox(height: 6),
              const Divider(height: 1),
              if (filtered.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: Text(l10n.noAgentsMatchSearch)),
                )
              else
                for (var i = 0; i < filtered.length; i++)
                  _AgentRow(
                    card: filtered[i],
                    maxXp: maxXp == 0 ? 1 : maxXp,
                    isLast: i == filtered.length - 1,
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _AgentsHeaderRow extends StatelessWidget {
  const _AgentsHeaderRow({required this.sort, required this.onSortChanged});
  final AgentSort sort;
  final ValueChanged<AgentSort> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 34, child: Text('')),
          Expanded(
            flex: 3,
            child: _HeaderLabel(label: l10n.agent),
          ),
          SizedBox(
            width: 56,
            child: _HeaderLabel(label: l10n.level, align: TextAlign.right),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 72,
            child: _SortableHeader(
              label: l10n.runs,
              active: sort == AgentSort.runs,
              onTap: () => onSortChanged(AgentSort.runs),
            ),
          ),
          SizedBox(
            width: 72,
            child: _SortableHeader(
              label: l10n.success,
              active: sort == AgentSort.success,
              onTap: () => onSortChanged(AgentSort.success),
            ),
          ),
          SizedBox(
            width: 72,
            child: _SortableHeader(
              label: l10n.merged,
              active: sort == AgentSort.prsMerged,
              onTap: () => onSortChanged(AgentSort.prsMerged),
            ),
          ),
          Expanded(
            flex: 2,
            child: _SortableHeader(
              label: l10n.xp,
              active: sort == AgentSort.xp,
              onTap: () => onSortChanged(AgentSort.xp),
              align: TextAlign.left,
            ),
          ),
        ],
      ),
    );
  }
}

class _HeaderLabel extends StatelessWidget {
  const _HeaderLabel({required this.label, this.align = TextAlign.left});
  final String label;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final theme = FTheme.of(context);
    return Text(
      label.toUpperCase(),
      textAlign: align,
      style: TextStyle(
        fontSize: 12,
        height: 1.4,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.6,
        color: tokens?.textTertiary ?? theme.colors.mutedForeground,
      ),
    );
  }
}

class _SortableHeader extends StatelessWidget {
  const _SortableHeader({
    required this.label,
    required this.active,
    required this.onTap,
    this.align = TextAlign.right,
  });
  final String label;
  final bool active;
  final VoidCallback onTap;
  final TextAlign align;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final theme = FTheme.of(context);
    final color = active
        ? (tokens?.textPrimary ?? theme.colors.foreground)
        : (tokens?.textTertiary ?? theme.colors.mutedForeground);
    return InkWell(
      borderRadius: BorderRadius.circular(4),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisAlignment: align == TextAlign.right
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 12,
                height: 1.4,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.6,
                color: color,
              ),
            ),
            if (active) ...[
              const SizedBox(width: 3),
              Icon(LucideIcons.arrowDown, size: 12, color: color),
            ],
          ],
        ),
      ),
    );
  }
}

class _AgentRow extends StatelessWidget {
  const _AgentRow({
    required this.card,
    required this.maxXp,
    required this.isLast,
  });

  final AgentScorecard card;
  final int maxXp;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    final theme = FTheme.of(context);
    final tokens = context.designSystem;
    final accent = Theme.of(context).colorScheme.primary;
    final muted = tokens?.textTertiary ?? theme.colors.mutedForeground;
    final fg = tokens?.textPrimary ?? theme.colors.foreground;
    final successPct = (card.successRate * 100).round();
    final successColor = successPct >= 90
        ? (tokens?.fgSuccessPrimary ?? theme.colors.primary)
        : successPct >= 70
            ? (tokens?.fgWarningPrimary ?? theme.colors.primary)
            : (tokens?.fgErrorPrimary ?? theme.colors.primary);

    return InkWell(
      onTap: () => context.go(analyticsAgentRoute(card.agentId)),
      child: Container(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isLast
                  ? Colors.transparent
                  : (tokens?.borderSecondary ?? theme.colors.border)
                      .withValues(alpha: 0.6),
            ),
          ),
        ),
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            AgentAvatar(name: card.agentName, size: 28, color: accent),
            const SizedBox(width: 6),
            Expanded(
              flex: 3,
              child: Text(
                card.agentName,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ),
            SizedBox(
              width: 56,
              child: Text(
                'Lv ${card.level}',
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: muted,
                ),
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              width: 72,
              child: Text(
                '${card.totalRuns}',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12, color: fg),
              ),
            ),
            SizedBox(
              width: 72,
              child: card.totalRuns == 0
                  ? Text(
                      '—',
                      textAlign: TextAlign.right,
                      style: TextStyle(fontSize: 12, color: muted),
                    )
                  : Text(
                      '$successPct%',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: successColor,
                      ),
                    ),
            ),
            SizedBox(
              width: 72,
              child: Text(
                '${card.totalPrsMerged}',
                textAlign: TextAlign.right,
                style: TextStyle(fontSize: 12, color: fg),
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(3),
                        child: LinearProgressIndicator(
                          value: (card.totalXp / maxXp).clamp(0, 1),
                          minHeight: 6,
                          backgroundColor:
                              tokens?.bgTertiary ?? theme.colors.muted,
                          valueColor: AlwaysStoppedAnimation(accent),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 48,
                      child: Text(
                        compactInt(card.totalXp),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: fg,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
