import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/space_management/space_autonomy.dart';
import 'package:cc_remote/widgets/space_management/space_controls.dart';
import 'package:cc_remote/widgets/space_management/space_participants.dart';
import 'package:cc_remote/widgets/space_management/space_repositories.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

class SpaceFormContent extends StatelessWidget {
  const SpaceFormContent({
    required this.workspaceId,
    required this.space,
    required this.role,
    required this.selfId,
    required this.agents,
    required this.members,
    required this.repos,
    required this.participants,
    required this.baseBranches,
    required this.autonomy,
    required this.name,
    required this.mode,
    required this.allRepos,
    required this.selectedRepos,
    required this.selectedAgents,
    required this.selectedPeople,
    required this.busy,
    required this.error,
    required this.createdSpaceId,
    required this.branchController,
    required this.onClearError,
    required this.onManageCreated,
    required this.onMode,
    required this.onAgent,
    required this.onHuman,
    required this.onAllRepos,
    required this.onClearRepos,
    required this.onRepo,
    required this.onBranch,
    required this.onAutonomy,
    required this.onSubmit,
    required this.onArchive,
    super.key,
  });

  final String workspaceId;
  final SpaceDto? space;
  final WorkspaceRole role;
  final String? selfId;
  final List<AgentDto> agents;
  final List<WorkspaceMemberDto> members;
  final List<Repo> repos;
  final List<SpaceParticipantDto> participants;
  final Map<String, String> baseBranches;
  final Map<String, String> autonomy;
  final TextEditingController name;
  final Mode mode;
  final bool allRepos;
  final Set<String> selectedRepos;
  final Set<String> selectedAgents;
  final Set<String> selectedPeople;
  final bool busy;
  final String? error;
  final String? createdSpaceId;
  final TextEditingController Function(String) branchController;
  final VoidCallback onClearError;
  final VoidCallback onManageCreated;
  final ValueChanged<Mode> onMode;
  final ValueChanged<String> onAgent;
  final ValueChanged<String> onHuman;
  final VoidCallback onAllRepos;
  final VoidCallback onClearRepos;
  final ValueChanged<String> onRepo;
  final void Function(String, String) onBranch;
  final void Function(String, String?) onAutonomy;
  final VoidCallback onSubmit;
  final VoidCallback onArchive;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final editable = role.canWrite && !busy && createdSpaceId == null;
    final editing = space != null;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (error != null) ...[
          CcAlert(
            variant: CcAlertVariant.danger,
            title: l10n.mobileSpacesOperationFailed,
            description: Text(error!),
            onClose: onClearError,
          ),
          const SizedBox(height: 16),
        ],
        if (createdSpaceId != null) ...[
          CcAlert(
            title: l10n.mobileSpacesCreatedRetry,
            action: CcButton(
              size: CcButtonSize.lg,
              onPressed: onManageCreated,
              child: Text(l10n.mobileSpacesManage),
            ),
          ),
          const SizedBox(height: 16),
        ],
        CcTextField(
          controller: name,
          label: l10n.mobileSpacesName,
          enabled: editable,
        ),
        SpaceHeading(l10n.mobileSpacesMode),
        for (final choice in Mode.values)
          SpacePick(
            switch (choice) {
              Mode.chat => l10n.mobileSpacesModeChat,
              Mode.review => l10n.mobileSpacesModeReview,
              Mode.plan => l10n.mobileSpacesModePlan,
              Mode.orchestrate => l10n.mobileSpacesModeOrchestrate,
            },
            mode == choice,
            editable ? () => onMode(choice) : null,
          ),
        SpaceParticipants(
          workspaceId: workspaceId,
          agents: agents,
          members: members,
          participants: participants,
          selectedAgents: selectedAgents,
          selectedPeople: selectedPeople,
          selfId: selfId,
          editing: editing,
          enabled: editable,
          onAgent: onAgent,
          onHuman: onHuman,
        ),
        SpaceRepositories(
          workspaceId: workspaceId,
          repos: repos,
          selected: selectedRepos,
          allRepos: allRepos,
          editing: editing,
          enabled: editable,
          baseBranches: baseBranches,
          branchController: branchController,
          onAllRepos: onAllRepos,
          onClear: onClearRepos,
          onRepo: onRepo,
          onBranch: onBranch,
        ),
        if (editing)
          SpaceAutonomy(
            workspaceId: workspaceId,
            agents: agents,
            participants: participants,
            levels: autonomy,
            enabled: role.isAdmin && !busy,
            onSet: onAutonomy,
          ),
        const SizedBox(height: 24),
        if (role.canWrite)
          CcButton(
            size: CcButtonSize.lg,
            onPressed: busy ? null : onSubmit,
            child: Text(
              editing ? l10n.mobileSpacesSave : l10n.mobileSpacesCreate,
            ),
          ),
        if (editing && role.canWrite) ...[
          const SizedBox(height: 16),
          CcButton(
            size: CcButtonSize.lg,
            variant: space!.archivedAt == null
                ? CcButtonVariant.destructive
                : CcButtonVariant.secondary,
            onPressed: busy ? null : onArchive,
            child: Text(
              space!.archivedAt == null
                  ? l10n.mobileSpacesArchive
                  : l10n.mobileSpacesReopen,
            ),
          ),
        ],
        const SizedBox(height: 32),
      ],
    );
  }
}
