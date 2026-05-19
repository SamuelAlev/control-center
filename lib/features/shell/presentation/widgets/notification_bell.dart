import 'package:control_center/core/domain/notifications/notification_category.dart';
import 'package:control_center/core/notifications/notification_center.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
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

class _NotificationBellState extends ConsumerState<NotificationBell>
    with SingleTickerProviderStateMixin {
  late final FPopoverController _controller = FPopoverController(vsync: this);

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

    return FPopoverMenu.tiles(
      control: FPopoverControl.managed(controller: _controller),
      style: const FPopoverMenuStyleDelta.delta(maxWidth: 380),
      divider: FItemDivider.none,
      menu: [
        FTileGroup(
          children: [
            FTile(
              title: Text(
                l10n.notificationsTitle,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
        FTileGroup(
          children: entries.isEmpty
              ? [
                  FTile(
                    prefix: const Icon(LucideIcons.bellOff, size: 16),
                    title: Text(l10n.notificationsEmpty),
                  ),
                ]
              : [
                  for (final entry in entries.take(15))
                    _entryTile(context, entry),
                ],
        ),
      ],
      child: _BellButton(unread: unread, onTap: _open),
    );
  }

  FTile _entryTile(BuildContext context, NotificationEntry entry) {
    final n = entry.notification;
    return FTile(
      prefix: Icon(_iconFor(n.category), size: 16),
      title: Text(n.title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(n.body, maxLines: 2, overflow: TextOverflow.ellipsis),
      suffix: Text(
        _relativeTime(entry.receivedAt),
        style: TextStyle(
          fontSize: 11,
          color: context.theme.colors.mutedForeground,
        ),
      ),
      onPress: () {
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
    final colors = context.theme.colors;
    final l10n = AppLocalizations.of(context);
    return FTooltip(
      tipAnchor: Alignment.topCenter,
      childAnchor: Alignment.bottomCenter,
      tipBuilder: (_, _) => Text(l10n.notificationsTooltip),
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
                  color: colors.mutedForeground,
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
                        color: colors.primary,
                        borderRadius: AppRadii.brSm,
                        border: Border.all(color: colors.background, width: 1.5),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: TextStyle(
                          color: colors.primaryForeground,
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
