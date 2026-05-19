import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/teams/presentation/widgets/team_detail_panel.dart';
import 'package:control_center/features/teams/presentation/widgets/team_form_dialog.dart';
import 'package:control_center/features/teams/providers/team_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// The teams management surface: group agents into teams and route work
/// through a leader.
///
/// A master-detail view — the roster of teams on the left, the selected team's
/// editor (name, leader, instructions, members) on the right. Below a
/// breakpoint it collapses to a single column that swaps the list for the
/// detail when a team is selected.
///
/// Hosted by the agent registry (Settings → Workspace → Agents): teams are
/// agent constructs — their members and their leader are agents — so they are
/// managed beside the roster they draw from, not as a workspace-membership
/// page where "Teams" read as being about people.
class TeamsManagementView extends ConsumerStatefulWidget {
  /// Creates a [TeamsManagementView].
  const TeamsManagementView({required this.workspaceId, super.key});

  /// The workspace whose teams are managed.
  final String workspaceId;

  @override
  ConsumerState<TeamsManagementView> createState() =>
      _TeamsManagementViewState();
}

class _TeamsManagementViewState extends ConsumerState<TeamsManagementView> {
  static const _wideBreakpoint = 760.0;
  static const _rosterWidth = 300.0;

  String? _selectedTeamId;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          child: Row(
            children: [
              Icon(AppIcons.users, size: 18, color: tokens?.fgBrandPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.teamsTitle,
                  style: CcTypography.title.copyWith(
                    color: tokens?.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              CcButton(
                onPressed: _createTeam,
                size: CcButtonSize.sm,
                icon: AppIcons.plus,
                child: Text(l10n.teamsAddTeam),
              ),
            ],
          ),
        ),
        Expanded(child: _buildBody(context)),
      ],
    );
  }

  Widget _buildBody(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final teamsAsync = ref.watch(teamsForWorkspaceProvider(widget.workspaceId));
    final agents =
        ref.watch(workspaceAgentsProvider(widget.workspaceId)).asData?.value ??
        const <Agent>[];

    return teamsAsync.when(
      loading: () => const Center(child: CcSpinner()),
      error: (e, _) => Center(child: Text(l10n.teamsLoadError)),
      data: (teams) {
        if (teams.isEmpty) {
          return _EmptyState(onCreate: _createTeam);
        }
        final selected =
            teams.where((t) => t.id == _selectedTeamId).firstOrNull ??
            (_selectedTeamId == null ? null : teams.first);

        return LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth >= _wideBreakpoint;
            final roster = _TeamRoster(
              teams: teams,
              agents: agents,
              selectedTeamId: selected?.id,
              onSelect: (id) => setState(() => _selectedTeamId = id),
            );
            final detail = selected == null
                ? const _SelectPrompt()
                : TeamDetailPanel(
                    team: selected,
                    agents: agents,
                    onDeleted: () => setState(() => _selectedTeamId = null),
                  );

            if (!isWide) {
              return selected == null
                  ? roster
                  : Column(
                      children: [
                        _BackBar(
                          label: selected.name,
                          onBack: () => setState(() => _selectedTeamId = null),
                        ),
                        Expanded(child: detail),
                      ],
                    );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(width: _rosterWidth, child: roster),
                const CcDivider(axis: Axis.vertical),
                Expanded(child: detail),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _createTeam() async {
    final result = await showTeamFormDialog(context);
    if (result == null) {
      return;
    }
    final team = Team(
      id: const Uuid().v4(),
      workspaceId: widget.workspaceId,
      name: result.name,
      description: result.description,
      createdAt: DateTime.now().toUtc(),
    );
    await ref.read(teamRepositoryProvider).insertTeam(team);
    setState(() => _selectedTeamId = team.id);
  }
}

class _TeamRoster extends StatelessWidget {
  const _TeamRoster({
    required this.teams,
    required this.agents,
    required this.selectedTeamId,
    required this.onSelect,
  });

  final List<Team> teams;
  final List<Agent> agents;
  final String? selectedTeamId;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: teams.length,
      separatorBuilder: (_, _) => const CcDivider(),
      itemBuilder: (_, i) {
        final team = teams[i];
        return _TeamRosterTile(
          team: team,
          selected: team.id == selectedTeamId,
          onTap: () => onSelect(team.id),
        );
      },
    );
  }
}

class _TeamRosterTile extends StatelessWidget {
  const _TeamRosterTile({
    required this.team,
    required this.selected,
    required this.onTap,
  });

  final Team team;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;

    return CcTappable(
      onPressed: onTap,
      builder: (_, _) => Container(
        color: selected ? tokens?.bgSecondary : null,
        padding: const EdgeInsets.fromLTRB(16, 12, 12, 12),
        child: Row(
          children: [
            const CcAvatar(size: 32, icon: AppIcons.users),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    team.name,
                    style: CcTypography.body.copyWith(
                      fontWeight: FontWeight.w600,
                      color: tokens?.textPrimary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (team.description != null &&
                      team.description!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      team.description!,
                      style: CcTypography.caption.copyWith(
                        color: tokens?.textTertiary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (team.hasLeader)
              CcTooltip(
                message: l10n.teamHasLeaderTooltip,
                child: Icon(
                  AppIcons.shield,
                  size: 15,
                  color: tokens?.fgTertiary,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BackBar extends StatelessWidget {
  const _BackBar({required this.label, required this.onBack});

  final String label;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
      child: Row(
        children: [
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            icon: AppIcons.chevronLeft,
            onPressed: onBack,
            child: Text(AppLocalizations.of(context).teamsTitle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: CcTypography.body.copyWith(color: tokens?.textPrimary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectPrompt extends StatelessWidget {
  const _SelectPrompt();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: CcEmptyState(
        icon: AppIcons.users,
        message: l10n.teamSelectPrompt,
        description: l10n.teamSelectPromptDescription,
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Center(
      child: CcEmptyState(
        icon: AppIcons.users,
        message: l10n.teamsEmptyTitle,
        description: l10n.teamsEmptyDescription,
        action: CcButton(
          icon: AppIcons.plus,
          onPressed: onCreate,
          child: Text(l10n.teamsAddTeam),
        ),
      ),
    );
  }
}
