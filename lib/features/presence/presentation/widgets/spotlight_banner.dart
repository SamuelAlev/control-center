import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/presence/domain/value_objects/participant_presence.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/presence/providers/follow_providers.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Dismissible "`<name>` is presenting" banner shown while another
/// participant (human or agent) is spotlighting this channel (PRD 16 §5).
/// A pure roster read — the auto-navigate-once side effect lives in
/// `spotlightSyncProvider`. Renders nothing when nobody else is presenting
/// here, or once this instance has been dismissed.
class SpotlightBanner extends ConsumerWidget {
  /// Creates a [SpotlightBanner] for [channelId].
  const SpotlightBanner({super.key, required this.channelId});

  /// The channel this banner watches.
  final String channelId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const SizedBox.shrink();
    }
    final roster =
        ref.watch(presenceRosterProvider(workspaceId)).value ?? const [];
    final myUserId = ref.watch(currentUserIdProvider);
    final dismissed = ref.watch(dismissedSpotlightsProvider);

    ParticipantPresence? presenter;
    for (final p in roster) {
      if (p.principal is UserPrincipal && p.principal.id == myUserId) {
        continue;
      }
      if (p.spotlightChannelId != channelId) {
        continue;
      }
      if (dismissed.contains(
        DismissedSpotlightsNotifier.keyFor(p.principal, channelId),
      )) {
        continue;
      }
      presenter = p;
      break;
    }
    if (presenter == null) {
      return const SizedBox.shrink();
    }

    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    final principal = presenter.principal;

    return Container(
      color: t.accentSoft,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      child: Row(
        children: [
          Icon(AppIcons.monitor, size: 14, color: t.accent),
          const SizedBox(width: AppSpacing.xs),
          Expanded(
            child: Text(
              l10n.spotlightPresentingBanner(presenter.displayName),
              style: TextStyle(
                color: t.accent,
                fontSize: 13,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          CcButton(
            variant: CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            onPressed: () => ref
                .read(dismissedSpotlightsProvider.notifier)
                .dismiss(principal, channelId),
            child: Text(l10n.spotlightLeave),
          ),
        ],
      ),
    );
  }
}
