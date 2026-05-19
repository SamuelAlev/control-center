import 'dart:async';

import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/shell/providers/notification_center_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    // Opening the center acknowledges the unread items (server-side, so the
    // acknowledgement follows the user to their other devices).
    unawaited(ref.read(notificationCenterActionsProvider).markAllRead());
  }

  @override
  Widget build(BuildContext context) {
    // Only the unread count is watched here: this widget lives in the shell
    // title bar, and watching the full entries list would rebuild it on every
    // notification mutation even while the popover is closed. The entries are
    // watched by the Consumer inside the overlay, which only exists while
    // the popover is open.
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
          constraints: const BoxConstraints(
            maxWidth: 380,
            minWidth: 320,
            maxHeight: 480,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Consumer(
              builder: (context, ref, _) {
                final entries = ref.watch(notificationCenterProvider);
                return Column(
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
                        leading: const Icon(AppIcons.bellOff, size: 16),
                        title: Text(l10n.notificationsEmpty),
                      )
                    else
                      // The popover is height-capped, so the history scrolls
                      // under the pinned header instead of overflowing.
                      Flexible(
                        child: SingleChildScrollView(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              for (final entry in entries.take(15))
                                _entryTile(context, entry, t),
                            ],
                          ),
                        ),
                      ),
                  ],
                );
              },
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
    NotificationCategory.agentRunCompleted => AppIcons.bot,
    NotificationCategory.pullRequestPublished => AppIcons.gitPullRequest,
    NotificationCategory.prMerged => AppIcons.gitMerge,
    NotificationCategory.newMessage => AppIcons.messageSquare,
    NotificationCategory.prMentioned => AppIcons.gitPullRequestArrow,
    NotificationCategory.reviewRequested => AppIcons.gitPullRequestArrow,
    NotificationCategory.ticketAssigned => AppIcons.ticket,
    NotificationCategory.ticketStatusChanged => AppIcons.ticketCheck,
    NotificationCategory.meetingStartsSoon => AppIcons.calendarClock,
    NotificationCategory.calendarAuthExpired => AppIcons.calendarX,
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
    return Stack(
      clipBehavior: Clip.none,
      children: [
        CcIconButton(
          icon: AppIcons.bell,
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          onPressed: onTap,
          tooltip: l10n.notificationsTooltip,
          semanticLabel: l10n.notificationsTooltip,
        ),
        if (unread > 0)
          Positioned(
            top: 2,
            right: 2,
            // Never absorb the tap; the button underneath owns it.
            child: IgnorePointer(
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
                    // The inverse of the textPrimary fill, so the count stays
                    // legible in both themes (textWhite is white-on-white on
                    // dark).
                    color: tokens?.bgPrimary ?? const Color(0xFFFFFFFF),
                    fontSize: 9,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
