import 'dart:async';

import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/notification_providers.dart';
import 'package:control_center/di/providers.dart';
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

  @override
  Widget build(BuildContext context) {
    // Only the unread count is watched here: this widget lives in the shell
    // title bar and watching the full entries list would rebuild it on every
    // notification mutation even while the popover is closed. The entries are
    // watched by the Consumer inside the overlay, which only exists while
    // the popover is open.
    final unread = ref.watch(unreadNotificationCountProvider);

    return CcPopover(
      controller: _controller,
      toggleOnTargetTap: false,
      followerAnchor: Alignment.topRight,
      targetAnchor: Alignment.bottomRight,
      overlayBuilder: (context, _) => _NotificationPanel(
        onNavigate: (route) {
          _controller.hide();
          GoRouter.of(context).go(route);
        },
      ),
      target: _BellButton(unread: unread, onTap: _controller.toggle),
    );
  }
}

/// The popover body: a header carrying the unread count and the bulk actions,
/// over the scrolling history.
///
/// Opening the panel no longer marks everything read — that erased the one
/// thing the panel is for, telling you what you have not seen yet. Acknowledging
/// is now an explicit act, per row or via the header.
class _NotificationPanel extends ConsumerWidget {
  const _NotificationPanel({required this.onNavigate});

  final ValueChanged<String> onNavigate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final entries = ref.watch(notificationCenterProvider);
    final unread = entries.where((e) => !e.read).length;
    final actions = ref.read(notificationCenterActionsProvider);

    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxWidth: 400,
        minWidth: 360,
        maxHeight: 480,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            unread: unread,
            hasEntries: entries.isNotEmpty,
            onMarkAllRead: () => unawaited(actions.markAllRead()),
            onClearAll: () => unawaited(actions.clearAll()),
          ),
          const CcDivider(),
          if (entries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
              child: CcEmptyState(
                icon: AppIcons.bellOff,
                message: l10n.notificationsEmpty,
                iconSize: 28,
              ),
            )
          else
            // The popover is height-capped, so the history scrolls under the
            // pinned header instead of overflowing.
            Flexible(
              child: CcScrollbar(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final entry in entries.take(15))
                        _EntryTile(
                          key: ValueKey(entry.id),
                          entry: entry,
                          tokens: t,
                          onNavigate: onNavigate,
                        ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.unread,
    required this.hasEntries,
    required this.onMarkAllRead,
    required this.onClearAll,
  });

  final int unread;
  final bool hasEntries;
  final VoidCallback onMarkAllRead;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);

    return Padding(
      // Right inset matches the rows' so the header's actions land on the same
      // vertical line as each row's overflow button.
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        top: AppSpacing.sm,
        bottom: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Text(
            l10n.notificationsTitle,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: t.textPrimary,
            ),
          ),
          if (unread > 0) ...[
            const SizedBox(width: AppSpacing.xs),
            CcBadge(
              label: l10n.notificationsUnreadCount(unread),
              variant: CcBadgeVariant.brand,
            ),
          ],
          const Spacer(),
          if (unread > 0)
            CcIconButton(
              icon: AppIcons.checkCheck,
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              onPressed: onMarkAllRead,
              tooltip: l10n.markAllRead,
              semanticLabel: l10n.markAllRead,
            ),
          if (hasEntries)
            CcIconButton(
              icon: AppIcons.trash2,
              variant: CcButtonVariant.ghost,
              size: CcButtonSize.sm,
              onPressed: onClearAll,
              tooltip: l10n.clearAll,
              semanticLabel: l10n.clearAll,
            ),
        ],
      ),
    );
  }
}

/// One notification row.
///
/// Stateful only to own its overflow menu's [CcOverlayController], whose open
/// state decides whether the hover-revealed trigger stays visible.
class _EntryTile extends ConsumerStatefulWidget {
  const _EntryTile({
    super.key,
    required this.entry,
    required this.tokens,
    required this.onNavigate,
  });

  final NotificationEntry entry;
  final DesignSystemTokens tokens;
  final ValueChanged<String> onNavigate;

  @override
  ConsumerState<_EntryTile> createState() => _EntryTileState();
}

class _EntryTileState extends ConsumerState<_EntryTile> {
  /// Open state of this row's overflow menu. Tracked because the open menu's
  /// full-screen dismiss barrier ends the row's hover: without this the trigger
  /// would fade out the moment it was used.
  final CcOverlayController _menu = CcOverlayController();

  @override
  void initState() {
    super.initState();
    _menu.addListener(_onMenuChanged);
  }

  @override
  void dispose() {
    _menu
      ..removeListener(_onMenuChanged)
      ..dispose();
    super.dispose();
  }

  void _onMenuChanged() => setState(() {});

  @override
  Widget build(BuildContext context) {
    final t = widget.tokens;
    final l10n = AppLocalizations.of(context);
    final entry = widget.entry;
    final n = entry.notification;
    final accent = _colorFor(n.category, t);
    final unread = !entry.read;
    final actions = ref.read(notificationCenterActionsProvider);

    // Hold, then drag: right uncovers delete, left uncovers the read toggle.
    // Both verbs stay in the overflow menu below — the drag is a shortcut for
    // someone who already knows it is there, never the only way to reach them.
    return CcSwipeActions(
      startAction: CcSwipeAction(
        icon: AppIcons.trash2,
        label: l10n.delete,
        background: t.bgErrorSolid,
        foreground: t.textWhite,
        onTriggered: () => unawaited(actions.dismiss(entry.id)),
      ),
      // Mirrors the menu item rather than hard-coding "read": a row you already
      // acknowledged can be pushed back to unread the same way you cleared it.
      endAction: CcSwipeAction(
        icon: unread ? AppIcons.check : AppIcons.circleDot,
        label: unread
            ? l10n.notificationsMarkRead
            : l10n.notificationsMarkUnread,
        background: t.bgSuccessSolid,
        foreground: t.textWhite,
        onTriggered: () => unawaited(actions.setRead(entry.id, read: unread)),
      ),
      child: CcTappable(
        onPressed: () {
          // Following a notification is reading it; leaving it bold after you
          // acted on it is the badge lying.
          if (unread) {
            unawaited(actions.setRead(entry.id, read: true));
          }
          widget.onNavigate(n.route);
        },
        semanticLabel: '${n.title}. ${n.body}',
        builder: (context, states) {
          // Hover reveals it; the row's FOCUS reveals it too, because the hidden
          // state is pointer-inert and a keyboard user would otherwise have no
          // way to reach these actions at all. The menu's own open state is the
          // third case: its dismiss barrier swallows hover, so without it the
          // trigger would fade out from under the menu it just opened.
          final showMenu =
              states.contains(WidgetState.hovered) ||
              states.contains(WidgetState.focused) ||
              _menu.isOpen;
          return DecoratedBox(
            decoration: BoxDecoration(
              // An unread row carries a faint wash and a spine in its category's
              // color. Neither is the only signal: the spine is present-vs-absent
              // and the title's weight changes, so unread survives grayscale and
              // color blindness. The read row keeps a TRANSPARENT spine of the
              // same width, so acknowledging one never shifts its text sideways.
              color: states.contains(WidgetState.pressed)
                  ? t.hoverStrong
                  : states.contains(WidgetState.hovered)
                  ? t.hover
                  : unread
                  ? accent.withValues(alpha: 0.05)
                  : null,
              border: Border(
                left: BorderSide(
                  color: unread ? accent : const Color(0x00000000),
                  width: 2,
                ),
              ),
            ),
            child: Padding(
              // The right inset clears the scrollbar: `RawScrollbar` paints its
              // 8px thumb OVER the content rather than reserving a gutter, so
              // without this the overflow button sits under the thumb. The wash
              // and the spine stay full-bleed — only the content is inset.
              padding: const EdgeInsets.only(
                left: AppSpacing.sm,
                right: AppSpacing.md,
                top: AppSpacing.sm,
                bottom: AppSpacing.sm,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CategoryIcon(
                    category: n.category,
                    color: accent,
                    unread: unread,
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                n.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  height: 1.3,
                                  // The title is the row's headline, so it stays
                                  // heavy either way; unread takes the top step
                                  // so the weight difference still reads.
                                  fontWeight: unread
                                      ? FontWeight.w700
                                      : FontWeight.w600,
                                  color: unread
                                      ? t.textPrimary
                                      : t.textSecondary,
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Text(
                              _relativeTime(entry.receivedAt),
                              style: TextStyle(
                                fontSize: 11,
                                height: 1.3,
                                color: t.textTertiary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 1),
                        Text(
                          n.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: unread ? t.textSecondary : t.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // The gap separates the timestamp from the overflow button's
                  // 32px hover wash, not from its glyph — at a hairline the wash
                  // butted straight against "1h" the moment the row was hovered.
                  // Widening it moves the button LEFT, away from the scrollbar,
                  // so the right inset below still owns that clearance.
                  const SizedBox(width: AppSpacing.sm),
                  // The slot is always laid out; only its contents fade, so
                  // revealing it cannot reflow the text beside it. The hidden
                  // state is pointer-inert too — an invisible button must not
                  // swallow a click meant for the row.
                  AnimatedOpacity(
                    opacity: showMenu ? 1 : 0,
                    duration: const Duration(milliseconds: 90),
                    child: IgnorePointer(
                      ignoring: !showMenu,
                      child: CcMenu(
                        controller: _menu,
                        // The target IS the button, so it owns the tap and
                        // renders its own hover/press wash. Left wrapped in the
                        // menu's default tappable it was a bare glyph that never
                        // reacted to the pointer.
                        toggleOnTargetTap: false,
                        targetAnchor: Alignment.bottomRight,
                        followerAnchor: Alignment.topRight,
                        minWidth: 172,
                        items: [
                          CcMenuItem(
                            label: unread
                                ? l10n.notificationsMarkRead
                                : l10n.notificationsMarkUnread,
                            icon: unread ? AppIcons.check : AppIcons.circleDot,
                            onSelected: () => unawaited(
                              actions.setRead(entry.id, read: unread),
                            ),
                          ),
                          // The in-flow half of per-repository mute: muting is
                          // something you want WHILE being annoyed, not after
                          // navigating to Settings. The undo lives there.
                          if (entry.repoFullName case final repo?)
                            CcMenuItem(
                              label: l10n.notificationsMuteRepo,
                              icon: AppIcons.bellOff,
                              onSelected: () => unawaited(
                                ref
                                    .read(notificationPreferencesProvider)
                                    .setRepoMuted(repo, muted: true)
                                    .then(
                                      (_) => ref.invalidate(mutedReposProvider),
                                    ),
                              ),
                            ),
                          CcMenuItem(
                            label: l10n.delete,
                            icon: AppIcons.trash2,
                            destructive: true,
                            onSelected: () =>
                                unawaited(actions.dismiss(entry.id)),
                          ),
                        ],
                        target: CcIconButton(
                          icon: AppIcons.moreHorizontal,
                          variant: CcButtonVariant.ghost,
                          size: CcButtonSize.sm,
                          onPressed: _menu.toggle,
                          tooltip: l10n.notificationsEntryActions,
                          semanticLabel: l10n.notificationsEntryActions,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// The category glyph in a tinted plate — the row's fastest "what is this".
class _CategoryIcon extends StatelessWidget {
  const _CategoryIcon({
    required this.category,
    required this.color,
    required this.unread,
  });

  final NotificationCategory category;
  final Color color;
  final bool unread;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        // A read row's plate steps back rather than going gray: the category
        // stays identifiable in the history, just quieter.
        color: color.withValues(alpha: unread ? 0.14 : 0.08),
        borderRadius: AppRadii.brSm,
      ),
      alignment: Alignment.center,
      child: Icon(
        _iconFor(category),
        size: 14,
        color: unread ? color : color.withValues(alpha: 0.7),
      ),
    );
  }
}

IconData _iconFor(NotificationCategory category) => switch (category) {
  NotificationCategory.agentRunCompleted => AppIcons.bot,
  NotificationCategory.pullRequestPublished => AppIcons.gitPullRequest,
  NotificationCategory.prMerged => AppIcons.gitMerge,
  NotificationCategory.newMessage => AppIcons.messageSquare,
  NotificationCategory.prMentioned => AppIcons.gitPullRequestArrow,
  NotificationCategory.reviewRequested => AppIcons.gitPullRequestArrow,
  NotificationCategory.reviewStale => AppIcons.gitCommitHorizontal,
  NotificationCategory.prMergeReadiness => AppIcons.gitMerge,
  NotificationCategory.prReviewDecision => AppIcons.checkCheck,
  NotificationCategory.prChecksStatus => AppIcons.circleX,
  NotificationCategory.prThreadActivity => AppIcons.messageSquare,
  NotificationCategory.ticketAssigned => AppIcons.ticket,
  NotificationCategory.ticketStatusChanged => AppIcons.ticketCheck,
  NotificationCategory.meetingStartsSoon => AppIcons.calendarClock,
  NotificationCategory.calendarAuthExpired => AppIcons.calendarX,
  NotificationCategory.rigStatusChanged => AppIcons.monitor,
};

/// The category's color, read from design tokens (never a literal) so both
/// themes and the contrast floor hold.
///
/// Semantics over decoration: green = it landed, red = it needs you, amber =
/// it is about to happen, purple = merged (the forge's own convention), brand
/// = it is addressed to you.
Color _colorFor(NotificationCategory category, DesignSystemTokens t) =>
    switch (category) {
      NotificationCategory.prMerged ||
      NotificationCategory.prMergeReadiness => t.fgMergedPrimary,
      NotificationCategory.agentRunCompleted ||
      NotificationCategory.ticketStatusChanged ||
      NotificationCategory.prReviewDecision => t.fgSuccessPrimary,
      NotificationCategory.calendarAuthExpired ||
      NotificationCategory.prChecksStatus => t.fgErrorPrimary,
      NotificationCategory.meetingStartsSoon ||
      NotificationCategory.reviewStale => t.fgWarningPrimary,
      NotificationCategory.prMentioned ||
      NotificationCategory.newMessage ||
      NotificationCategory.reviewRequested ||
      NotificationCategory.prThreadActivity ||
      NotificationCategory.ticketAssigned => t.fgBrandPrimary,
      NotificationCategory.pullRequestPublished ||
      NotificationCategory.rigStatusChanged => t.fgSecondary,
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
                  color: tokens?.fgBrandPrimary,
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
                    color: tokens?.textWhite ?? const Color(0xFFFFFFFF),
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
