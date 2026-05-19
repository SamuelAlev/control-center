import 'package:cc_domain/features/presence/domain/value_objects/participant_presence.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/presence/providers/follow_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/avatar_initials.dart';
import 'package:control_center/shared/widgets/agent_avatar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One avatar chip on a presence surface (the space header's "who's here"
/// strip and the shell's workspace presence rail): the participant's avatar
/// with a small status dot, a tooltip that always states the status in text
/// (never color-alone, AAA) and a tap that toggles follow (PRD 16 §4).
class PresenceAvatarChip extends ConsumerWidget {
  /// Creates a [PresenceAvatarChip].
  const PresenceAvatarChip({
    super.key,
    required this.participant,
    this.spaceId,
    this.size = 22,
  });

  /// The participant this chip represents.
  final ParticipantPresence participant;

  /// When set, the chip renders a "typing" status if [participant] is
  /// currently typing in this space.
  final String? spaceId;

  /// Avatar diameter in logical pixels.
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final following =
        ref.watch(followedPrincipalProvider) == participant.principal;

    final isTyping = spaceId != null && participant.typingInSpaceId == spaceId;

    final String statusLabel;
    final Color dotColor;
    if (participant.isAgent) {
      switch (participant.agent?.state) {
        case AgentLiveState.thinking:
          statusLabel = l10n.presenceAgentThinking;
          dotColor = t.fgBrandPrimary;
        case AgentLiveState.running:
          statusLabel = l10n.presenceAgentRunning;
          dotColor = t.fgBrandPrimary;
        case AgentLiveState.blockedOnApproval:
          statusLabel = l10n.presenceAgentBlocked;
          dotColor = t.fgWarningPrimary;
        case AgentLiveState.done:
        case null:
          statusLabel = l10n.presenceAgentDone;
          dotColor = t.fgQuaternary;
      }
    } else if (isTyping) {
      statusLabel = l10n.presenceTyping;
      dotColor = t.fgBrandPrimary;
    } else if (participant.availability == PresenceAvailability.idle) {
      statusLabel = l10n.presenceIdle;
      dotColor = t.fgQuaternary;
    } else {
      statusLabel = l10n.presenceOnline;
      dotColor = t.success;
    }

    final cost = participant.agent?.costUsd;
    final tooltipText = cost != null
        ? l10n.presenceNameStatusCost(
            participant.displayName,
            statusLabel,
            '\$${cost.toStringAsFixed(2)}',
          )
        : l10n.presenceNameStatus(participant.displayName, statusLabel);

    final avatar = participant.isAgent
        ? AgentAvatar(
            agentId: participant.principal.id,
            name: participant.displayName,
            size: size,
            showHoverCard: false,
          )
        : CcAvatar(
            size: size,
            initials: avatarInitials(participant.displayName, maxLetters: 1),
          );

    return CcTooltip(
      message: tooltipText,
      // The click cursor is the affordance *and* the guard: the rail sits in
      // the window-drag title bar, and `WindowDragArea` reads the resolved
      // cursor to decide whether a press belongs to the child. Without one this
      // chip is inert chrome to it, so tapping an avatar dragged the window.
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => ref
              .read(followedPrincipalProvider.notifier)
              .toggle(participant.principal),
          child: Container(
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: following
                  ? Border.all(color: t.accent, width: 1.5)
                  : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                avatar,
                Positioned(
                  right: -1,
                  bottom: -1,
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: dotColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: t.bgPrimary, width: 1.5),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
