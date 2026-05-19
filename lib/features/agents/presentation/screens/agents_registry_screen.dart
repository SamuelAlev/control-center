import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_detail_panel.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_discover_dialog.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_form_sheet.dart';
import 'package:control_center/features/agents/presentation/widgets/agent_status.dart';
import 'package:control_center/features/agents/presentation/widgets/skill_chip.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// How the roster is ordered.
enum _AgentSort {
  /// Attention first: running, then blocked, failed, idle, never-run.
  status,

  /// Alphabetical by name.
  name,
}

/// Registry screen for managing AI agents — a master-detail "fleet roster":
/// the list on the left reports each agent's live state at a glance, the panel
/// on the right inspects and acts on the selected agent.
class AgentsRegistryScreen extends ConsumerStatefulWidget {
  /// Creates the agents registry screen.
  const AgentsRegistryScreen({super.key});

  @override
  ConsumerState<AgentsRegistryScreen> createState() =>
      _AgentsRegistryScreenState();
}

class _AgentsRegistryScreenState extends ConsumerState<AgentsRegistryScreen> {
  static const _wideBreakpoint = 720.0;

  final TextEditingController _filterCtl = TextEditingController();
  String _query = '';
  _AgentSort _sort = _AgentSort.status;
  String? _selectedId;

  @override
  void initState() {
    super.initState();
    _filterCtl.addListener(() {
      if (_filterCtl.text != _query) {
        setState(() => _query = _filterCtl.text);
      }
    });
  }

  @override
  void dispose() {
    _filterCtl.dispose();
    super.dispose();
  }

  void _openAdd(String workspaceId) =>
      showAgentFormDialog(context: context, workspaceId: workspaceId);

  void _openDiscover(String workspaceId) =>
      showDiscoverAgentsDialog(context: context, workspaceId: workspaceId);

  void _openEdit(Agent agent) => showAgentFormDialog(
        context: context,
        workspaceId: agent.workspaceId,
        agent: agent,
      );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final agentsAsync = workspaceId != null
        ? ref.watch(workspaceAgentsProvider(workspaceId))
        : ref.watch(agentsProvider);

    return PageWrapper(
      title: l10n.agents,
      actions: [
        FButton(
          onPress: workspaceId == null ? null : () => _openDiscover(workspaceId),
          variant: FButtonVariant.secondary,
          mainAxisSize: MainAxisSize.min,
          prefix: const Icon(LucideIcons.search),
          child: Text(l10n.discover),
        ),
        const SizedBox(width: 8),
        FButton(
          onPress: workspaceId == null ? null : () => _openAdd(workspaceId),
          mainAxisSize: MainAxisSize.min,
          prefix: const Icon(LucideIcons.plus),
          child: Text(l10n.addAgent),
        ),
      ],
      child: agentsAsync.when(
        data: (agents) => agents.isEmpty
            ? _EmptyState(
                onAdd: workspaceId == null ? null : () => _openAdd(workspaceId),
                onDiscover:
                    workspaceId == null ? null : () => _openDiscover(workspaceId),
              )
            : _buildMasterDetail(agents),
        loading: () => const Center(child: FCircularProgress()),
        error: (e, _) => _ErrorState(message: e.toString()),
      ),
    );
  }

  Widget _buildMasterDetail(List<Agent> agents) {
    final selected =
        agents.where((a) => a.id == _selectedId).firstOrNull;

    return LayoutBuilder(
      builder: (context, constraints) {
        final tokens = context.designSystem!;
        final wide = constraints.maxWidth >= _wideBreakpoint;

        final list = _RosterList(
          agents: agents,
          query: _query,
          sort: _sort,
          selectedId: _selectedId,
          filterController: _filterCtl,
          onSelect: (id) => setState(() => _selectedId = id),
          onSortChanged: (s) => setState(() => _sort = s),
        );

        if (!wide) {
          if (selected != null) {
            return AgentDetailPanel(
              agent: selected,
              onEdit: () => _openEdit(selected),
              onDeleted: () => setState(() => _selectedId = null),
              onClose: () => setState(() => _selectedId = null),
            );
          }
          return list;
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(width: 360, child: list),
            VerticalDivider(width: 1, thickness: 1, color: tokens.borderSecondary),
            Expanded(
              child: selected != null
                  ? AgentDetailPanel(
                      key: ValueKey(selected.id),
                      agent: selected,
                      onEdit: () => _openEdit(selected),
                      onDeleted: () => setState(() => _selectedId = null),
                    )
                  : const _NoSelection(),
            ),
          ],
        );
      },
    );
  }
}

/// The left roster: filter + sort header, count, and the living rows.
class _RosterList extends ConsumerWidget {
  const _RosterList({
    required this.agents,
    required this.query,
    required this.sort,
    required this.selectedId,
    required this.filterController,
    required this.onSelect,
    required this.onSortChanged,
  });

  final List<Agent> agents;
  final String query;
  final _AgentSort sort;
  final String? selectedId;
  final TextEditingController filterController;
  final ValueChanged<String> onSelect;
  final ValueChanged<_AgentSort> onSortChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem!;
    final l10n = AppLocalizations.of(context);

    final q = query.trim().toLowerCase();
    final filtered = q.isEmpty
        ? [...agents]
        : agents.where((a) {
            return a.name.toLowerCase().contains(q) ||
                a.title.toLowerCase().contains(q) ||
                a.skills.toList().any((s) => s.toLowerCase().contains(q));
          }).toList();

    filtered.sort((a, b) {
      switch (sort) {
        case _AgentSort.name:
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        case _AgentSort.status:
          final sa = ref.watch(agentLiveStateProvider(a.id)).sortPriority;
          final sb = ref.watch(agentLiveStateProvider(b.id)).sortPriority;
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
                child: FTextField(
                  control: FTextFieldControl.managed(
                    controller: filterController,
                  ),
                  hint: l10n.filterAgents,
                  prefixBuilder: (_, _, _) => Padding(
                    padding: const EdgeInsets.only(left: 10, right: 6),
                    child: Icon(
                      LucideIcons.search,
                      size: 16,
                      color: tokens.fgQuaternary,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 132,
                child: FSelect<_AgentSort>(
                  items: {
                    l10n.sortByStatus: _AgentSort.status,
                    l10n.sortByName: _AgentSort.name,
                  },
                  control: FSelectControl<_AgentSort>.lifted(
                    value: sort,
                    onChange: (v) => onSortChanged(v ?? _AgentSort.status),
                  ),
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
                    return _AgentRow(
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
class _AgentRow extends ConsumerWidget {
  const _AgentRow({
    required this.agent,
    required this.selected,
    required this.onTap,
  });

  final Agent agent;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem!;
    final state = ref.watch(agentLiveStateProvider(agent.id));
    final skills = agent.skills.toList();
    final shownSkills = skills.take(3).toList();
    final overflow = skills.length - shownSkills.length;

    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: FTappable(
        onPress: onTap,
        focusedOutlineStyle: const FFocusedOutlineStyleDelta.context(),
        builder: (context, states, child) => DecoratedBox(
          decoration: BoxDecoration(
            color: selected
                ? tokens.bgBrandPrimary
                : states.contains(FTappableVariant.hovered)
                    ? tokens.bgSecondary
                    : Colors.transparent,
            borderRadius: AppRadii.brSm,
            border: Border.all(
              color: selected ? tokens.borderBrand : Colors.transparent,
            ),
          ),
          child: child,
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

/// Placeholder shown in the detail pane when no agent is selected (wide view).
class _NoSelection extends StatelessWidget {
  const _NoSelection();

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    return Container(
      color: tokens.bgPrimary,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.users, size: 32, color: tokens.fgQuaternary),
          const SizedBox(height: 12),
          Text(
            l10n.selectAnAgent,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: tokens.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.selectAnAgentHint,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({this.onAdd, this.onDiscover});

  final VoidCallback? onAdd;
  final VoidCallback? onDiscover;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: tokens.bgSecondary,
              shape: BoxShape.circle,
            ),
            child: Icon(LucideIcons.bot, size: 40, color: tokens.fgQuaternary),
          ),
          const SizedBox(height: 20),
          Text(
            l10n.noAgentsDiscovered,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              l10n.noAgentsDiscoveredHint,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: tokens.textTertiary,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              FButton(
                onPress: onDiscover,
                variant: FButtonVariant.secondary,
                mainAxisSize: MainAxisSize.min,
                prefix: const Icon(LucideIcons.search),
                child: Text(l10n.discoverAgents),
              ),
              const SizedBox(width: 12),
              FButton(
                onPress: onAdd,
                mainAxisSize: MainAxisSize.min,
                prefix: const Icon(LucideIcons.plus),
                child: Text(l10n.addAgent),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            LucideIcons.triangleAlert,
            size: 40,
            color: tokens.fgErrorSecondary,
          ),
          const SizedBox(height: 16),
          Text(
            l10n.errorLoadingAgents,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: tokens.textTertiary,
            ),
          ),
        ],
      ),
    );
  }
}
