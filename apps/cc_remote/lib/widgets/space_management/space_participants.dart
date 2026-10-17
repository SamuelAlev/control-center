import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/space_management/space_controls.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

class SpaceParticipants extends StatelessWidget {
  const SpaceParticipants({
    required this.workspaceId,
    required this.agents,
    required this.members,
    required this.participants,
    required this.selectedAgents,
    required this.selectedPeople,
    required this.selfId,
    required this.editing,
    required this.enabled,
    required this.onAgent,
    required this.onHuman,
    super.key,
  });

  final String workspaceId;
  final List<AgentDto> agents;
  final List<WorkspaceMemberDto> members;
  final List<SpaceParticipantDto> participants;
  final Set<String> selectedAgents;
  final Set<String> selectedPeople;
  final String? selfId;
  final bool editing;
  final bool enabled;
  final ValueChanged<String> onAgent;
  final ValueChanged<String> onHuman;

  bool _has(String type, String id) => participants.any(
    (participant) =>
        participant.participantType == type && participant.principalId == id,
  );

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final scopedAgents = agents.where(
      (agent) => agent.workspaceId == workspaceId,
    );
    final scopedMembers = members.where(
      (member) => member.workspaceId == workspaceId,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SpaceHeading(l10n.mobileSpacesAgents),
        if (scopedAgents.isEmpty)
          Text(
            l10n.mobileSpacesNoAgents,
            style: TextStyle(color: tokens.textSecondary),
          ),
        for (final agent in scopedAgents)
          SpacePick(
            agent.name,
            editing
                ? _has('agent', agent.id)
                : selectedAgents.contains(agent.id),
            enabled ? () => onAgent(agent.id) : null,
          ),
        SpaceHeading(l10n.mobileSpacesMembers),
        if (scopedMembers.isEmpty)
          Text(
            l10n.mobileSpacesNoMembers,
            style: TextStyle(color: tokens.textSecondary),
          ),
        for (final member in scopedMembers)
          SpacePick(
            member.displayName?.isNotEmpty == true
                ? member.displayName!
                : member.userId,
            editing
                ? _has('user', member.userId)
                : member.userId == selfId ||
                      selectedPeople.contains(member.userId),
            enabled && member.userId != selfId
                ? () => onHuman(member.userId)
                : null,
          ),
      ],
    );
  }
}
