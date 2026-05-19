import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/notifications/notification_category.dart';
import 'package:control_center/core/notifications/notification_center.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Top-bar notification center: a bell with an unread badge that opens a
/// popover listing recent activity (the durable in-app history of events the
/// app would otherwise only show as ephemeral OS toasts).
class NotificationBell extends ConsumerStatefulWidget {
  /// Creates a [NotificationBell].
  const NotificationBell({super.key});

  @override
  ConsumerState<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends ConsumerState<NotificationBell> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _open() {
    _controller.toggle();
    // Opening the center acknowledges the unread items.
    ref.read(notificationCenterProvider.notifier).markAllRead();
  }

  @override
  Widget build(BuildContext context) {
    final entries = ref.watch(notificationCenterProvider);
    final unread = ref.watch(unreadNotificationCountProvider);
    final l10n = AppLocalizations.of(context);

    return CcPopover(
      controller: _controller,
      toggleOnTargetTap: false,
      followerAnchor: Alignment.topRight,
      targetAnchor: Alignment.bottomRight,
      overlayBuilder: (context, _) {
        final t = context.designSystem ?? DesignSystemTokens.light();
        return ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380, minWidth: 320),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                CcTile(
                  title: Text(
                    l10n.notificationsTitle,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const CcDivider(),
                if (entries.isEmpty)
                  CcTile(
                    leading: const Icon(LucideIcons.bellOff, size: 16),
                    title: Text(l10n.notificationsEmpty),
                  )
                else
                  for (final entry in entries.take(15))
                    _entryTile(context, entry, t),
              ],
            ),
          ),
        );
      },
      target: _BellButton(unread: unread, onTap: _open),
    );
  }

  Widget _entryTile(
    BuildContext context,
    NotificationEntry entry,
    DesignSystemTokens t,
  ) {
    final n = entry.notification;
    return CcTile(
      leading: Icon(_iconFor(n.category), size: 16),
      title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text(
        _relativeTime(entry.receivedAt),
        style: TextStyle(fontSize: 11, color: t.textTertiary),
      ),
      onTap: () {
        _controller.hide();
        GoRouter.of(context).go(n.route);
      },
    );
  }

  IconData _iconFor(NotificationCategory category) => switch (category) {
        NotificationCategory.agentRunCompleted => LucideIcons.bot,
        NotificationCategory.pullRequestPublished => LucideIcons.gitPullRequest,
        NotificationCategory.prMerged => LucideIcons.gitMerge,
        NotificationCategory.newMessage => LucideIcons.messageSquare,
        NotificationCategory.externalPr => LucideIcons.gitPullRequestArrow,
        NotificationCategory.ticketAssigned => LucideIcons.ticket,
        NotificationCategory.ticketStatusChanged => LucideIcons.ticketCheck,
        NotificationCategory.meetingStartsSoon => LucideIcons.calendarClock,
        NotificationCategory.calendarAuthExpired => LucideIcons.calendarX,
      };

  String _relativeTime(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inSeconds < 60) {
      return 'now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h';
    }
    return '${diff.inDays}d';
  }
}

class _BellButton extends StatelessWidget {
  const _BellButton({required this.unread, required this.onTap});

  final int unread;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    return CcTooltip(
      followerAnchor: Alignment.topCenter,
      targetAnchor: Alignment.bottomCenter,
      message: l10n.notificationsTooltip,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: SizedBox(
            width: 30,
            height: 24,
            child: Stack(
              clipBehavior: Clip.none,
              alignment: Alignment.center,
              children: [
                Icon(
                  LucideIcons.bell,
                  size: 16,
                  color: tokens?.textTertiary,
                ),
                if (unread > 0)
                  Positioned(
                    top: -1,
                    right: 1,
                    child: Container(
                      constraints: const BoxConstraints(minWidth: 15),
                      height: 15,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      decoration: BoxDecoration(
                        color: tokens?.textPrimary,
                        borderRadius: AppRadii.brSm,
                        border: Border.all(
                          color: tokens?.bgPrimary ?? const Color(0xFFFFFFFF),
                          width: 1.5,
                        ),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: TextStyle(
                          color: tokens?.textWhite,
                          fontSize: 9,
                          height: 1,
                          fontWeight: FontWeight.w700,
                        ),
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
