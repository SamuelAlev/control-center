import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/widgets/space_management/space_controls.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

class SpaceAutonomy extends StatelessWidget {
  const SpaceAutonomy({
    required this.workspaceId,
    required this.agents,
    required this.participants,
    required this.levels,
    required this.enabled,
    required this.onSet,
    super.key,
  });

  final String workspaceId;
  final List<AgentDto> agents;
  final List<SpaceParticipantDto> participants;
  final Map<String, String> levels;
  final bool enabled;
  final void Function(String agentId, String? level) onSet;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final participantIds = {
      for (final participant in participants)
        if (participant.participantType == 'agent') participant.principalId,
    };
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SpaceHeading(l10n.mobileSpacesAutonomy),
        Text(
          l10n.mobileSpacesAutonomyNotice,
          style: TextStyle(fontSize: 12, color: tokens.textSecondary),
        ),
        for (final agent in agents.where(
          (agent) =>
              agent.workspaceId == workspaceId &&
              participantIds.contains(agent.id),
        )) ...[
          SpaceHeading(agent.name),
          for (final (label, level) in [
            (l10n.mobileSpacesAutonomyInherited, null),
            (l10n.mobileSpacesAutonomyPropose, 'proposeOnly'),
            (l10n.mobileSpacesAutonomyApproval, 'actWithApproval'),
            (l10n.mobileSpacesAutonomyFreely, 'actFreely'),
          ])
            SpacePick(
              label,
              levels[agent.id] == level,
              enabled ? () => onSet(agent.id, level) : null,
            ),
        ],
      ],
    );
  }
}
