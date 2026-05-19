import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_status.dart';
import 'package:control_center/features/agents/presentation/widgets/skill_chip.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The left roster of a fleet/master-detail agents view: a filter field over
/// the living rows. Extracted so the global "Agents" page and the settings
/// "Agent registry" share one roster design.
///
/// Rows are always ordered attention-first (running, then blocked, failed,
/// idle, never-run) with name as the tie-break — the ordering the roster
/// exists for, so it is not a choice the host makes.
///
/// State-less by design: the host owns the query, the selection and the
/// filter [TextEditingController] and is notified through the callbacks.
class AgentRosterList extends ConsumerWidget {
  /// Creates an [AgentRosterList].
  const AgentRosterList({
    super.key,
    required this.agents,
    required this.query,
    required this.selectedId,
    required this.filterController,
    required this.onSelect,
  });

  /// Every agent in scope (the list filters/sorts this set itself).
  final List<Agent> agents;

  /// The current filter text.
  final String query;

  /// The id of the selected agent, or null if nothing is selected.
  final String? selectedId;

  /// Controller backing the filter field. Owned by the host.
  final TextEditingController filterController;

  /// Invoked with an agent id when a row is tapped.
  final ValueChanged<String> onSelect;

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
      final sa = ref
          .watch(
            agentLiveStateProvider((workspaceId: a.workspaceId, agentId: a.id)),
          )
          .sortPriority;
      final sb = ref
          .watch(
            agentLiveStateProvider((workspaceId: b.workspaceId, agentId: b.id)),
          )
          .sortPriority;
      if (sa != sb) {
        return sa.compareTo(sb);
      }
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.md,
            0,
            AppSpacing.md,
            AppSpacing.sm,
          ),
          child: CcTextField(
            controller: filterController,
            hintText: l10n.filterAgents,
            size: CcTextFieldSize.sm,
            prefix: Icon(AppIcons.search, size: 15, color: tokens.fgQuaternary),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                  ),
                  child: SettingsRailEmptyNote(message: l10n.noMatchingAgents),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
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

    // Selection reads as the settings kit's wash plus a left accent bar, the
    // same treatment the skills, providers and adapters rails use. It used to
    // be a filled brand-tinted box with a brand border, which made the selected
    // agent the loudest thing on a page whose subject is the detail pane.
    return CcTappable(
      onPressed: onTap,
      semanticLabel: '${agent.name}, ${agent.title}',
      builder: (context, states) => DecoratedBox(
        decoration: BoxDecoration(
          color: selected
              ? tokens.hoverStrong
              : states.contains(WidgetState.hovered)
              ? tokens.hover
              : null,
          border: Border(
            left: BorderSide(
              color: selected ? tokens.fgBrandPrimary : const Color(0x00000000),
              width: 2,
            ),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 8, 12, 8),
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
                      style: CcTypography.body.copyWith(
                        fontWeight: FontWeight.w600,
                        color: tokens.textPrimary,
                      ),
                    ),
                    Text(
                      agent.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CcTypography.caption.copyWith(
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
                                for (final s in shownSkills)
                                  SkillChip(label: s),
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
    );
  }
}
