import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/presence/domain/value_objects/participant_presence.dart';
import 'package:cc_domain/features/presence/domain/value_objects/presence_locus.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/presence/presentation/widgets/presence_avatar_chip.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Compact avatar strip for the space header: one chip per participant
/// (human or agent) whose presence currently targets this space — viewing
/// it or typing in it (PRD 16 §1–§3).
///
/// Solo-mode zero-regression: renders nothing when the workspace roster has
/// nobody else at all (no other humans, no live agents) and nothing when
/// nobody relevant is on this specific space.
class WhosHereStrip extends ConsumerWidget {
  /// Creates a [WhosHereStrip] for [spaceId].
  const WhosHereStrip({super.key, required this.spaceId});

  /// The space this header belongs to.
  final String spaceId;

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

    final here = [
      for (final p in others)
        if (_targetsSpace(p, spaceId)) p,
    ];
    if (here.isEmpty) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final p in here)
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: PresenceAvatarChip(participant: p, spaceId: spaceId),
          ),
      ],
    );
  }

  static bool _targetsSpace(ParticipantPresence p, String spaceId) {
    final locus = p.locus;
    return (locus is SpaceLocus && locus.spaceId == spaceId) ||
        p.typingInSpaceId == spaceId;
  }
}
