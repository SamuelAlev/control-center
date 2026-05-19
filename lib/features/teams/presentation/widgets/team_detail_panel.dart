import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/teams/presentation/widgets/team_form_dialog.dart';
import 'package:control_center/features/teams/presentation/widgets/team_member_picker_dialog.dart';
import 'package:control_center/features/teams/providers/team_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The right-hand editor for a single [team]: rename/describe, pick a leader,
/// set operating instructions, and add/remove members.
///
/// The leader is the source of truth for routing (`team.leaderId`); a member's
/// "leader" status is derived from it, so promoting an agent simply rewrites
/// `leaderId` and ensures the agent is a member.
class TeamDetailPanel extends ConsumerStatefulWidget {
  /// Creates a [TeamDetailPanel].
  const TeamDetailPanel({
    super.key,
    required this.team,
    required this.agents,
    required this.onDeleted,
  });

  /// The team being edited.
  final Team team;

  /// All agents in the workspace, for the leader picker and member display.
  final List<Agent> agents;

  /// Invoked after the team is deleted so the parent can clear its selection.
  final VoidCallback onDeleted;

  @override
  ConsumerState<TeamDetailPanel> createState() => _TeamDetailPanelState();
}

class _TeamDetailPanelState extends ConsumerState<TeamDetailPanel> {
  late final TextEditingController _instructionsCtrl;

  @override
  void initState() {
    super.initState();
    _instructionsCtrl = TextEditingController(
      text: widget.team.instructions ?? '',
    );
  }

  @override
  void didUpdateWidget(TeamDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-sync the instructions field when a different team is selected.
    if (oldWidget.team.id != widget.team.id) {
      _instructionsCtrl.text = widget.team.instructions ?? '';
    }
  }

  @override
  void dispose() {
    _instructionsCtrl.dispose();
    super.dispose();
  }

  Team get _team => widget.team;

  Agent? _agentById(String? id) =>
      id == null ? null : widget.agents.where((a) => a.id == id).firstOrNull;

  void _toast(String message, {bool error = false}) {
    if (!mounted) {
      return;
    }
    CcToastScope.of(context).show(
      message,
      variant: error ? CcToastVariant.danger : CcToastVariant.success,
    );
  }

  Future<void> _editDetails() async {
    final result = await showTeamFormDialog(
      context,
      initialName: _team.name,
      initialDescription: _team.description,
    );
    if (result == null) {
      return;
    }
    await ref
        .read(teamRepositoryProvider)
        .updateTeam(
          _team.copyWith(
            name: result.name,
            description: result.description,
            clearDescription: result.description == null,
          ),
        );
  }

  Future<void> _setLeader(String? agentId) async {
    final repo = ref.read(teamRepositoryProvider);
    await repo.updateTeam(
      agentId == null
          ? _team.copyWith(clearLeader: true)
          : _team.copyWith(leaderId: agentId),
    );
    // The leader must also be a member so it appears in the roster context.
    if (agentId != null) {
      await repo.addMember(
        ref.requireWorkspaceId(),
        TeamMember(
          teamId: _team.id,
          agentId: agentId,
          role: TeamMemberRole.leader,
        ),
      );
    }
  }

  Future<void> _saveInstructions() async {
    final saved = AppLocalizations.of(context).teamSaved;
    final text = _instructionsCtrl.text.trim();
    await ref
        .read(teamRepositoryProvider)
        .updateTeam(
          text.isEmpty
              ? _team.copyWith(clearInstructions: true)
              : _team.copyWith(instructions: text),
        );
    _toast(saved);
  }

  Future<void> _addMembers(List<TeamMember> current) async {
    final memberIds = current.map((m) => m.agentId).toSet();
    final candidates =
        widget.agents.where((a) => !memberIds.contains(a.id)).toList()..sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
    final chosen = await showTeamMemberPickerDialog(
      context,
      candidates: candidates,
    );
    if (chosen == null || chosen.isEmpty) {
      return;
    }
    final repo = ref.read(teamRepositoryProvider);
    for (final id in chosen) {
      await repo.addMember(
        _team.workspaceId,
        TeamMember(teamId: _team.id, agentId: id),
      );
    }
  }

  Future<void> _removeMember(String agentId) async {
    final repo = ref.read(teamRepositoryProvider);
    await repo.removeMember(context.currentWorkspaceId!, _team.id, agentId);
    // Removing the current leader leaves the team leaderless.
    if (_team.leaderId == agentId) {
      await repo.updateTeam(_team.copyWith(clearLeader: true));
    }
  }

  Future<void> _delete() async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.teamDeleteTitle,
        content: Text(l10n.teamDeleteBody(_team.name)),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(ctx, false),
            variant: CcButtonVariant.ghost,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(ctx, true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref
        .read(teamRepositoryProvider)
        .deleteTeam(_team.workspaceId, _team.id);
    widget.onDeleted();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final membersAsync = ref.watch(teamMembersProvider(_team.id));

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      children: [
        _Header(team: _team, onEdit: _editDetails, onDelete: _delete),
        const SizedBox(height: 16),
        SectionCard(
          label: l10n.teamLeaderLabel,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.teamLeaderHelp,
                  style: CcTypography.caption.copyWith(
                    color: context.designSystem?.textTertiary,
                  ),
                ),
                const SizedBox(height: 10),
                CcSelect<String>(
                  value: _team.leaderId,
                  hintText: l10n.teamNoLeader,
                  onChanged: (id) => _setLeader(id.isEmpty ? null : id),
                  options: [
                    CcSelectOption(value: '', label: l10n.teamNoLeader),
                    for (final a in widget.agents)
                      CcSelectOption(value: a.id, label: a.name),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        _InstructionsCard(
          controller: _instructionsCtrl,
          onSave: _saveInstructions,
        ),
        const SizedBox(height: 16),
        membersAsync.when(
          loading: () => const Center(
            child: Padding(padding: EdgeInsets.all(24), child: CcSpinner()),
          ),
          error: (e, _) => Text(l10n.teamMembersError),
          data: (members) => _MembersCard(
            members: members,
            leaderId: _team.leaderId,
            agentById: _agentById,
            onAdd: () => _addMembers(members),
            onRemove: _removeMember,
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({
    required this.team,
    required this.onEdit,
    required this.onDelete,
  });

  final Team team;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const CcAvatar(size: 44, icon: AppIcons.users),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                team.name,
                style: CcTypography.title.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tokens?.textPrimary,
                ),
              ),
              if (team.description != null && team.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  team.description!,
                  style: CcTypography.body.copyWith(
                    color: tokens?.textTertiary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 8),
        CcButton(
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          icon: AppIcons.pencil,
          onPressed: onEdit,
          child: Text(l10n.edit),
        ),
        const SizedBox(width: 8),
        CcButton(
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          onPressed: onDelete,
          child: Icon(AppIcons.trash2, size: 16, color: tokens?.fgTertiary),
        ),
      ],
    );
  }
}

class _InstructionsCard extends StatelessWidget {
  const _InstructionsCard({required this.controller, required this.onSave});

  final TextEditingController controller;
  final Future<void> Function() onSave;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return SectionCard(
      label: l10n.teamInstructionsLabel,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.teamInstructionsHelp,
              style: CcTypography.caption.copyWith(
                color: context.designSystem?.textTertiary,
              ),
            ),
            const SizedBox(height: 10),
            CcTextArea(
              controller: controller,
              hintText: l10n.teamInstructionsHint,
              minLines: 3,
              maxLines: 8,
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: CcButton(
                size: CcButtonSize.sm,
                onPressed: onSave,
                child: Text(l10n.save),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembersCard extends StatelessWidget {
  const _MembersCard({
    required this.members,
    required this.leaderId,
    required this.agentById,
    required this.onAdd,
    required this.onRemove,
  });

  final List<TeamMember> members;
  final String? leaderId;
  final Agent? Function(String?) agentById;
  final VoidCallback onAdd;
  final void Function(String agentId) onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // Leader first, then alphabetical by display name.
    final sorted = [...members]
      ..sort((a, b) {
        if (a.agentId == leaderId) {
          return -1;
        }
        if (b.agentId == leaderId) {
          return 1;
        }
        final an = agentById(a.agentId)?.name ?? a.agentId;
        final bn = agentById(b.agentId)?.name ?? b.agentId;
        return an.toLowerCase().compareTo(bn.toLowerCase());
      });

    return SectionCard(
      label: l10n.teamMemberCount(members.length),
      headerPadding: const EdgeInsets.fromLTRB(16, 0, 8, 8),
      trailing: CcButton(
        variant: CcButtonVariant.ghost,
        size: CcButtonSize.sm,
        icon: AppIcons.userPlus,
        onPressed: onAdd,
        child: Text(l10n.teamAddMember),
      ),
      child: sorted.isEmpty
          ? _MembersEmpty(onAdd: onAdd)
          : ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: sorted.length,
              separatorBuilder: (_, _) => const CcDivider(),
              itemBuilder: (_, i) {
                final member = sorted[i];
                return _MemberRow(
                  agent: agentById(member.agentId),
                  agentId: member.agentId,
                  isLeader: member.agentId == leaderId,
                  onRemove: () => onRemove(member.agentId),
                );
              },
            ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.agent,
    required this.agentId,
    required this.isLeader,
    required this.onRemove,
  });

  final Agent? agent;
  final String agentId;
  final bool isLeader;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final name = agent?.name ?? l10n.teamUnknownAgent;
    final skills = agent != null && agent!.skills.isNotEmpty
        ? agent!.skills.join(', ')
        : null;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      child: Row(
        children: [
          const CcAvatar(size: 32, icon: AppIcons.user),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: CcTypography.body.copyWith(
                          fontWeight: FontWeight.w600,
                          color: tokens?.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLeader) ...[
                      const SizedBox(width: 8),
                      CcBadge(
                        label: l10n.teamLeaderBadge,
                        variant: CcBadgeVariant.brand,
                        icon: AppIcons.shield,
                      ),
                    ],
                  ],
                ),
                if (skills != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    skills,
                    style: CcTypography.caption.copyWith(
                      color: tokens?.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          CcTooltip(
            message: l10n.teamRemoveMember,
            child: CcButton(
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              onPressed: onRemove,
              child: Icon(AppIcons.x, size: 16, color: tokens?.fgTertiary),
            ),
          ),
        ],
      ),
    );
  }
}

class _MembersEmpty extends StatelessWidget {
  const _MembersEmpty({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
      child: CcEmptyState(
        icon: AppIcons.users,
        message: l10n.teamMembersEmpty,
        description: l10n.teamMembersEmptyDescription,
        iconSize: 32,
        action: CcButton(
          size: CcButtonSize.sm,
          icon: AppIcons.userPlus,
          onPressed: onAdd,
          child: Text(l10n.teamAddMember),
        ),
      ),
    );
  }
}
