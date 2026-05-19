import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_status.dart';
import 'package:control_center/features/agents/presentation/widgets/skill_chip.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How an [AgentRosterList] is ordered.
enum AgentRosterSort {
  /// Attention first: running, then blocked, failed, idle, never-run.
  status,

  /// Alphabetical by name.
  name,
}

/// The left roster of a fleet/master-detail agents view: a filter + sort
/// header, an agent count, and the living rows. Extracted so the global
/// "Agents" page and the settings "Agent registry" share one roster design.
///
/// State-less by design: the host owns the query, sort, selection, and the
/// filter [TextEditingController], and is notified through the callbacks.
class AgentRosterList extends ConsumerWidget {
  /// Creates an [AgentRosterList].
  const AgentRosterList({
    super.key,
    required this.agents,
    required this.query,
    required this.sort,
    required this.selectedId,
    required this.filterController,
    required this.onSelect,
    required this.onSortChanged,
  });

  /// Every agent in scope (the list filters/sorts this set itself).
  final List<Agent> agents;

  /// The current filter text.
  final String query;

  /// The current sort order.
  final AgentRosterSort sort;

  /// The id of the selected agent, or null if nothing is selected.
  final String? selectedId;

  /// Controller backing the filter field. Owned by the host.
  final TextEditingController filterController;

  /// Invoked with an agent id when a row is tapped.
  final ValueChanged<String> onSelect;

  /// Invoked when the sort order changes.
  final ValueChanged<AgentRosterSort> onSortChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem!;
    final l10n = AppLocalizations.of(context);

    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? [...agents]
        : agents
              .where(
                (a) =>
                    a.name.toLowerCase().contains(q) ||
                    a.title.toLowerCase().contains(q) ||
                    a.skills.toList().any((s) => s.toLowerCase().contains(q)),
              )
              .toList();

    filtered.sort((a, b) {
      switch (sort) {
        case AgentRosterSort.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case AgentRosterSort.status:
          final sa = ref
              .watch(
                agentLiveStateProvider((
                  workspaceId: a.workspaceId,
                  agentId: a.id,
                )),
              )
              .sortPriority;
          final sb = ref
              .watch(
                agentLiveStateProvider((
                  workspaceId: b.workspaceId,
                  agentId: b.id,
                )),
              )
              .sortPriority;
          if (sa != sb) {
            return sa.compareTo(sb);
          }
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      }
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: CcTextField(
                  controller: filterController,
                  hintText: l10n.filterAgents,
                  prefix: Icon(
                    AppIcons.search,
                    size: 16,
                    color: tokens.fgQuaternary,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 132,
                child: CcSelect<AgentRosterSort>(
                  value: sort,
                  options: [
                    CcSelectOption(
                      value: AgentRosterSort.status,
                      label: l10n.sortByStatus,
                    ),
                    CcSelectOption(
                      value: AgentRosterSort.name,
                      label: l10n.sortByName,
                    ),
                  ],
                  onChanged: onSortChanged,
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Text(
            l10n.agentCount(filtered.length, filtered.length),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: tokens.textTertiary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Text(
                    l10n.noMatchingAgents,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: tokens.textTertiary,
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(12, 0, 12, 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, i) {
                    final agent = filtered[i];
                    return AgentRosterRow(
                      agent: agent,
                      selected: agent.id == selectedId,
                      onTap: () => onSelect(agent.id),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

/// A single living roster row: presence dot + identity + quiet skills.
class AgentRosterRow extends ConsumerWidget {
  /// Creates an [AgentRosterRow].
  const AgentRosterRow({
    super.key,
    required this.agent,
    required this.selected,
    required this.onTap,
  });

  /// The agent this row represents.
  final Agent agent;

  /// Whether this row is the selected one.
  final bool selected;

  /// Invoked when the row is tapped.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem!;
    final state = ref.watch(
      agentLiveStateProvider((
        workspaceId: agent.workspaceId,
        agentId: agent.id,
      )),
    );
    final skills = agent.skills.toList();
    final shownSkills = skills.take(3).toList();
    final overflow = skills.length - shownSkills.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: CcTappable(
        onPressed: onTap,
        builder: (context, states) => DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? tokens.bgBrandPrimary
                : states.contains(WidgetState.hovered)
                ? tokens.bgSecondary
                : Colors.transparent,
            borderRadius: AppRadii.brSm,
            border: Border.all(
              color: selected ? tokens.borderBrand : Colors.transparent,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 10),
                  child: AgentStatusDot(
                    visual: AgentStatusVisual.resolve(
                      state,
                      tokens,
                      AppLocalizations.of(context),
                    ),
                  ),
                ),
                AgentAvatar(
                  agentId: agent.id,
                  name: agent.name,
                  size: 28,
                  showHoverCard: false,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        agent.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                        ),
                      ),
                      Text(
                        agent.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: tokens.textTertiary,
                        ),
                      ),
                      if (shownSkills.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Expanded(
                              child: Wrap(
                                spacing: 6,
                                runSpacing: 6,
                                children: [
                                  for (final s in shownSkills) SkillChip(label: s),
                                ],
                              ),
                            ),
                            if (overflow > 0) ...[
                              const SizedBox(width: 6),
                              SkillOverflowChip(count: overflow),
                            ],
                          ],
                        ),
                      ],
                    ],
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
