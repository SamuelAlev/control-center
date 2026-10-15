import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/presence/domain/value_objects/participant_presence.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/presence/providers/follow_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/utils/avatar_initials.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A user avatar on the space header or workspace presence rail, with a
/// status dot, a textual status tooltip and a tap that toggles following.
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
    final principal = participant.principal;
    if (principal is! UserPrincipal) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final following =
        ref.watch(followedPrincipalProvider) == participant.principal;

    final isTyping = spaceId != null && participant.typingInSpaceId == spaceId;

    final String statusLabel;
    final Color dotColor;
    if (isTyping) {
      statusLabel = l10n.presenceTyping;
      dotColor = t.fgBrandPrimary;
    } else if (participant.availability == PresenceAvailability.idle) {
      statusLabel = l10n.presenceIdle;
      dotColor = t.fgQuaternary;
    } else {
      statusLabel = l10n.presenceOnline;
      dotColor = t.success;
    }

    final tooltipText = l10n.presenceNameStatus(
      participant.displayName,
      statusLabel,
    );
    final avatar = CcAvatar(
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
          onTap: () =>
              ref.read(followedPrincipalProvider.notifier).toggle(principal),
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
                PositionedDirectional(
                  end: -1,
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
