import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/teams/presentation/widgets/team_detail_panel.dart';
import 'package:control_center/features/teams/presentation/widgets/team_form_dialog.dart';
import 'package:control_center/features/teams/providers/team_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

/// The teams management surface: group agents into teams and route work
/// through a leader.
///
/// Hosted by the agent registry (Settings → Workspace → Agents): teams are
/// agent constructs — their members and their leader are agents — so they are
/// managed beside the roster they draw from, not as a workspace-membership
/// page where "Teams" read as being about people.
///
/// ## Why it looks like this
///
/// It sits in the registry's body, so it is built from the registry's parts:
/// one [SectionCard] with a state strip over a [SettingsMasterDetail]. It used
/// to invent its own page instead — a bare title row, a rail of divider-
/// separated tiles, and a detail pane of stacked cards — which meant the two
/// halves of the same screen disagreed about what a rail row, a card and a
/// heading look like the moment you pressed the toolbar toggle between them.
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
  static const _wideBreakpoint = 720.0;
  static const _rosterWidth = 300.0;

  /// Past this many teams the rail earns a search field. Under it, a filter is
  /// chrome over a list you can already read in one glance.
  static const _filterThreshold = 6;

  String? _selectedTeamId;
  final _filterCtl = TextEditingController();
  String _query = '';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final teamsAsync = ref.watch(teamsForWorkspaceProvider(widget.workspaceId));
    final agents =
        ref.watch(workspaceAgentsProvider(widget.workspaceId)).asData?.value ??
        const <Agent>[];

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: SectionCard(
        label: l10n.teamsTitle,
        padding: const EdgeInsets.fromLTRB(0, 14, 0, 0),
        headerPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.md,
        ),
        expands: true,
        trailing: CcButton(
          onPressed: _createTeam,
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          icon: AppIcons.plus,
          child: Text(l10n.teamsAddTeam),
        ),
        child: teamsAsync.when(
          loading: () => const Center(child: CcSpinner()),
          error: (e, _) => Center(child: Text(l10n.teamsLoadError)),
          data: (teams) => teams.isEmpty
              ? _EmptyState(onCreate: _createTeam)
              : _buildBody(context, l10n, teams, agents),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppLocalizations l10n,
    List<Team> teams,
    List<Agent> agents,
  ) {
    final withLeader = teams.where((t) => t.hasLeader).length;
    final selected =
        teams.where((t) => t.id == _selectedTeamId).firstOrNull ??
        (_selectedTeamId == null ? null : teams.first);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: SettingsSummary(
            facts: [
              SettingsFact(label: l10n.teamsTitle, value: '${teams.length}'),
              SettingsFact(
                label: l10n.teamsSummaryWithLeader,
                value: l10n.settingsCountOfTotal(withLeader, teams.length),
                // A leaderless team has nowhere to route work, so the count is
                // a state to act on rather than a number to note.
                tone: withLeader == teams.length
                    ? CcStatusTone.positive
                    : CcStatusTone.caution,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        const CcDivider(),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= _wideBreakpoint;
              final roster = _TeamRoster(
                teams: teams,
                selectedTeamId: selected?.id,
                query: _query,
                filterController: _filterCtl,
                showFilter: teams.length > _filterThreshold,
                onSelect: (id) => setState(() => _selectedTeamId = id),
              );
              final detail = selected == null
                  ? const _SelectPrompt()
                  : TeamDetailPanel(
                      key: ValueKey(selected.id),
                      team: selected,
                      agents: agents,
                      onClose: isWide
                          ? null
                          : () => setState(() => _selectedTeamId = null),
                      onDeleted: () => setState(() => _selectedTeamId = null),
                    );

              if (!isWide) {
                return selected == null ? roster : detail;
              }

              return SettingsMasterDetail(
                railWidth: _rosterWidth,
                stretch: true,
                railPadding: const EdgeInsets.only(top: AppSpacing.md),
                rail: roster,
                detail: detail,
              );
            },
          ),
        ),
      ],
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

/// The rail: an optional filter, the live count, and one row per team.
class _TeamRoster extends StatelessWidget {
  const _TeamRoster({
    required this.teams,
    required this.selectedTeamId,
    required this.query,
    required this.filterController,
    required this.showFilter,
    required this.onSelect,
  });

  final List<Team> teams;
  final String? selectedTeamId;
  final String query;
  final TextEditingController filterController;
  final bool showFilter;
  final ValueChanged<String?> onSelect;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final q = query.trim().toLowerCase();
    final visible = q.isEmpty
        ? teams
        : teams
              .where(
                (t) =>
                    t.name.toLowerCase().contains(q) ||
                    (t.description ?? '').toLowerCase().contains(q),
              )
              .toList();

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (showFilter) ...[
                CcTextField(
                  controller: filterController,
                  hintText: l10n.teamsFilterHint,
                  size: CcTextFieldSize.sm,
                  prefix: Icon(
                    AppIcons.search,
                    size: 15,
                    color: tokens.fgQuaternary,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
              Text(
                l10n.teamCountLabel(visible.length),
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: visible.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: SettingsRailEmptyNote(message: 'No matches.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.only(bottom: AppSpacing.lg),
                  itemCount: visible.length,
                  itemBuilder: (_, i) => _TeamRosterTile(
                    team: visible[i],
                    selected: visible[i].id == selectedTeamId,
                    onTap: () => onSelect(visible[i].id),
                  ),
                ),
        ),
      ],
    );
  }
}

/// One rail row. Selection reads as the settings kit's wash plus a left accent
/// bar, the same treatment the agent roster beside it uses.
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
    final tokens = context.designSystem ?? DesignSystemTokens.light();

    return CcTappable(
      onPressed: onTap,
      semanticLabel: team.name,
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
            children: [
              const CcAvatar(size: 28, icon: AppIcons.users),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      team.name,
                      style: CcTypography.bodySm.copyWith(
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: tokens.textPrimary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (team.description != null &&
                        team.description!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        team.description!,
                        style: CcTypography.caption.copyWith(
                          color: tokens.textTertiary,
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
                    size: 14,
                    color: tokens.fgTertiary,
                  ),
                ),
            ],
          ),
        ),
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
        iconSize: 32,
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
        iconSize: 32,
        action: CcButton(
          icon: AppIcons.plus,
          onPressed: onCreate,
          child: Text(l10n.teamsAddTeam),
        ),
      ),
    );
  }
}
