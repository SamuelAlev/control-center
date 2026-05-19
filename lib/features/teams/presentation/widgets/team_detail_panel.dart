import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/features/teams/domain/entities/team.dart';
import 'package:cc_domain/features/teams/domain/entities/team_member.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/features/teams/presentation/widgets/team_form_dialog.dart';
import 'package:control_center/features/teams/presentation/widgets/team_member_picker_dialog.dart';
import 'package:control_center/features/teams/providers/team_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The right-hand editor for a single [team]: rename/describe, pick a leader,
/// set operating instructions and add/remove members.
///
/// The leader is the source of truth for routing (`team.leaderId`); a member's
/// "leader" status is derived from it, so promoting an agent simply rewrites
/// `leaderId` and ensures the agent is a member.
///
/// ## Why it looks like this
///
/// It is the agent registry's detail pane with a different subject, so it is
/// built from the same parts: an identity header carrying the pane's actions,
/// [SettingsField] rows on one label column, and a [SettingsSaveBar] below the
/// scroll. It used to stack three bordered section cards — a box for the
/// leader select, a box for the instructions with its own Save floating
/// mid-card, a box for the members — which spent a lot of chrome saying
/// "these are three things" about one team, and hid the only commit on the
/// page inside the middle box.
class TeamDetailPanel extends ConsumerStatefulWidget {
  /// Creates a [TeamDetailPanel].
  const TeamDetailPanel({
    super.key,
    required this.team,
    required this.agents,
    required this.onDeleted,
    this.onClose,
  });

  /// The team being edited.
  final Team team;

  /// All agents in the workspace, for the leader picker and member display.
  final List<Agent> agents;

  /// Invoked after the team is deleted so the parent can clear its selection.
  final VoidCallback onDeleted;

  /// Back affordance for the narrow single-column layout. Null when the rail
  /// is visible beside the pane.
  final VoidCallback? onClose;

  @override
  ConsumerState<TeamDetailPanel> createState() => _TeamDetailPanelState();
}

class _TeamDetailPanelState extends ConsumerState<TeamDetailPanel> {
  late final TextEditingController _instructionsCtrl;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _instructionsCtrl = TextEditingController(
      text: widget.team.instructions ?? '',
    );
    _instructionsCtrl.addListener(_onInstructionsChanged);
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
    _instructionsCtrl
      ..removeListener(_onInstructionsChanged)
      ..dispose();
    super.dispose();
  }

  void _onInstructionsChanged() => setState(() {});

  Team get _team => widget.team;

  /// The instructions are the only value on this pane that is committed rather
  /// than applied on change (the leader select writes straight through, the
  /// way every other select in settings does).
  bool get _dirty =>
      _instructionsCtrl.text.trim() != (_team.instructions ?? '').trim();

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
    setState(() => _saving = true);
    try {
      await ref
          .read(teamRepositoryProvider)
          .updateTeam(
            text.isEmpty
                ? _team.copyWith(clearInstructions: true)
                : _team.copyWith(instructions: text),
          );
      _toast(saved);
    } finally {
      if (mounted) {
        setState(() => _saving = false);
      }
    }
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.lg,
              AppSpacing.xl,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _Header(
                  team: _team,
                  onEdit: _editDetails,
                  onDelete: _delete,
                  onClose: widget.onClose,
                ),
                const SizedBox(height: AppSpacing.xl),
                SettingsGroup(
                  showRule: true,
                  children: [
                    SettingsField(
                      label: l10n.teamLeaderLabel,
                      description: l10n.teamLeaderHelp,
                      child: CcSelect<String>(
                        value: _team.leaderId,
                        hintText: l10n.teamNoLeader,
                        onChanged: (id) => _setLeader(id.isEmpty ? null : id),
                        options: [
                          CcSelectOption(value: '', label: l10n.teamNoLeader),
                          for (final a in widget.agents)
                            CcSelectOption(value: a.id, label: a.name),
                        ],
                      ),
                    ),
                    SettingsField(
                      label: l10n.teamInstructionsLabel,
                      description: l10n.teamInstructionsHelp,
                      layout: SettingsFieldLayout.stacked,
                      optional: true,
                      child: CcTextArea(
                        controller: _instructionsCtrl,
                        hintText: l10n.teamInstructionsHint,
                        minLines: 3,
                        maxLines: 8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                membersAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.all(AppSpacing.xl),
                    child: Center(child: CcSpinner()),
                  ),
                  error: (e, _) => Text(l10n.teamMembersError),
                  data: (members) => _MembersGroup(
                    members: members,
                    leaderId: _team.leaderId,
                    agentById: _agentById,
                    onAdd: () => _addMembers(members),
                    onRemove: _removeMember,
                  ),
                ),
              ],
            ),
          ),
        ),
        SettingsSaveBar(
          dirty: _dirty,
          busy: _saving,
          onSave: _saveInstructions,
          onDiscard: () => _instructionsCtrl.text = _team.instructions ?? '',
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
    this.onClose,
  });

  final Team team;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (onClose != null) ...[
          CcIconButton(
            icon: AppIcons.arrowLeft,
            tooltip: l10n.backLabel,
            onPressed: onClose,
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        const CcAvatar(size: 40, icon: AppIcons.users),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                team.name,
                style: CcTypography.title.copyWith(
                  fontWeight: FontWeight.w700,
                  color: tokens.textPrimary,
                ),
              ),
              if (team.description != null && team.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  team.description!,
                  style: CcTypography.bodySm.copyWith(
                    color: tokens.textTertiary,
                    height: 1.4,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        CcButton(
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          icon: AppIcons.pencil,
          onPressed: onEdit,
          child: Text(l10n.edit),
        ),
        const SizedBox(width: AppSpacing.sm),
        CcIconButton(
          icon: AppIcons.trash2,
          variant: CcButtonVariant.destructive,
          size: CcButtonSize.sm,
          tooltip: l10n.teamDeleteTitle,
          semanticLabel: l10n.teamDeleteTitle,
          onPressed: onDelete,
        ),
      ],
    );
  }
}

/// The members block: a titled group whose heading IS the count, with the add
/// action on the heading row and the members as peer rows under a hairline.
class _MembersGroup extends StatelessWidget {
  const _MembersGroup({
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

    return SettingsGroup(
      title: l10n.teamMemberCount(members.length),
      showRule: true,
      separator: SettingsGroupSeparator.rule,
      trailing: CcButton(
        variant: CcButtonVariant.secondary,
        size: CcButtonSize.sm,
        icon: AppIcons.userPlus,
        onPressed: onAdd,
        child: Text(l10n.teamAddMember),
      ),
      children: [
        if (sorted.isEmpty)
          _MembersEmpty(onAdd: onAdd)
        else
          for (final member in sorted)
            _MemberRow(
              agent: agentById(member.agentId),
              agentId: member.agentId,
              isLeader: member.agentId == leaderId,
              onRemove: () => onRemove(member.agentId),
            ),
      ],
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
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final name = agent?.name ?? l10n.teamUnknownAgent;
    final skills = agent != null && agent!.skills.isNotEmpty
        ? agent!.skills.join(', ')
        : null;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          const CcAvatar(size: 28, icon: AppIcons.user),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        name,
                        style: CcTypography.bodySm.copyWith(
                          fontWeight: FontWeight.w600,
                          color: tokens.textPrimary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isLeader) ...[
                      const SizedBox(width: AppSpacing.sm),
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
                      color: tokens.textTertiary,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          CcIconButton(
            icon: AppIcons.x,
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            tooltip: l10n.teamRemoveMember,
            semanticLabel: l10n.teamRemoveMember,
            onPressed: onRemove,
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
    // Sized for a block inside a form, not for a whole page: the members list
    // is one section of a pane, so its empty state must not out-weigh the
    // fields above it.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
      child: CcEmptyState(
        icon: AppIcons.users,
        message: l10n.teamMembersEmpty,
        description: l10n.teamMembersEmptyDescription,
        iconSize: 24,
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
