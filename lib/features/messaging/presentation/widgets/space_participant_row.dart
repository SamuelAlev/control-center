import 'package:cc_domain/features/messaging/domain/entities/space_participant.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/providers/space_autonomy_provider.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One agent participant in the manage-space dialog: avatar, name and title,
/// a remove button, and the per-space autonomy dial beneath.
class SpaceParticipantRow extends ConsumerWidget {
  /// Creates a [SpaceParticipantRow].
  const SpaceParticipantRow({
    super.key,
    required this.spaceId,
    required this.participant,
    required this.onRemove,
  });

  /// The space this participant belongs to — scopes the autonomy read/write.
  final String spaceId;

  /// The agent participant this row shows.
  final SpaceParticipant participant;

  /// Removes the participant from the space.
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final agentAsync = ref.watch(agentDetailProvider(participant.principalId));
    final name = agentAsync.value?.name ?? '...';
    final title = agentAsync.value?.title ?? '';
    final l10n = AppLocalizations.of(context);
    final autonomy =
        ref.watch(spaceAutonomyProvider(spaceId)).value ??
        const <String, AutonomyLevel?>{};
    final currentLevel = autonomy[participant.principalId];
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final canSetAutonomy =
        workspaceId != null &&
        (ref.watch(myWorkspaceRoleProvider(workspaceId))?.isAdmin ?? false);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AgentAvatar(
                agentId: participant.principalId,
                name: name,
                size: 24,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: CcTypography.body.copyWith(
                        color: tokens.textTertiary,
                      ),
                    ),
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: CcTypography.caption.copyWith(
                          color: tokens.textTertiary,
                        ),
                      ),
                  ],
                ),
              ),
              CcTooltip(
                message: l10n.remove,
                child: CcIconButton(
                  icon: AppIcons.x,
                  semanticLabel: l10n.remove,
                  onPressed: onRemove,
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsetsDirectional.only(
              top: 6,
              start: 34,
              end: 4,
            ),
            child: CcSelect<AutonomyLevel?>(
              label: l10n.autonomyDialLabel,
              // The dial decides whether this agent's risky effects are
              // pre-approved, so it carries the same admin floor as the
              // guardrail matrix it would otherwise neutralize (the server
              // enforces it; this keeps the control honest rather than
              // offering an action that will be refused).
              enabled: canSetAutonomy,
              options: [
                CcSelectOption(value: null, label: l10n.autonomyDefaultOption),
                CcSelectOption(
                  value: AutonomyLevel.proposeOnly,
                  label: l10n.autonomyProposeOnly,
                ),
                CcSelectOption(
                  value: AutonomyLevel.actWithApproval,
                  label: l10n.autonomyActWithApproval,
                ),
                CcSelectOption(
                  value: AutonomyLevel.actFreely,
                  label: l10n.autonomyActFreely,
                ),
              ],
              value: currentLevel,
              onChanged: (level) => setSpaceAutonomy(
                ref.read(rpcClientProvider),
                spaceId: spaceId,
                agentId: participant.principalId,
                level: level,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
