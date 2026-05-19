import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/presence/presentation/widgets/presence_avatar_chip.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compact "who's online" cluster for the shell title bar: up to 5 avatars
/// plus an overflow count and a do-not-disturb toggle (PRD 16 §1).
///
/// Solo-mode zero-regression: renders nothing when the workspace roster has
/// nobody else at all (no other humans, no live agents) — multiplayer chrome,
/// including the DND control, must be invisible until a second principal
/// connects.
class WorkspacePresenceRail extends ConsumerWidget {
  /// Creates a [WorkspacePresenceRail].
  const WorkspacePresenceRail({super.key});

  static const int _maxAvatars = 5;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final roster =
        ref.watch(presenceRosterProvider(workspaceId)).value ?? const [];
    final myUserId = ref.watch(currentUserIdProvider);

    final others = [
      for (final p in roster)
        if (!(p.principal is UserPrincipal && p.principal.id == myUserId)) p,
    ];
    if (others.isEmpty) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final myPresence = ref.watch(myPresenceProvider);
    final shown = others.take(_maxAvatars).toList();
    final overflow = others.length - shown.length;
    final dndTooltip = myPresence.dnd ? l10n.dndTooltipOff : l10n.dndTooltipOn;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          container: true,
          label: l10n.presenceRailLabel,
          child: ExcludeSemantics(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final p in shown)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: PresenceAvatarChip(participant: p, size: 20),
                  ),
                if (overflow > 0)
                  Padding(
                    padding: const EdgeInsets.only(left: 4),
                    child: CcAvatar(
                      size: 20,
                      initials: l10n.presencePlusCount(overflow),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        CcIconButton(
          icon: AppIcons.moon,
          size: CcButtonSize.sm,
          color: myPresence.dnd ? t.accent : null,
          tooltip: dndTooltip,
          semanticLabel: dndTooltip,
          onPressed: () =>
              ref.read(myPresenceProvider.notifier).setDnd(!myPresence.dnd),
        ),
      ],
    );
  }
}
