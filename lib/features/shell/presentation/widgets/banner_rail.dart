import 'dart:async';

import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/notifications/live_notification_lane.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// A live banner in the ambient rail: an [AppNotification] promoted to
/// [NotificationPresentation.banner], tagged with a stable id and an arrival
/// sequence so the queue can order it and key its widget/timer.
@immutable
class ActiveBanner {
  /// Creates an [ActiveBanner].
  const ActiveBanner({
    required this.id,
    required this.seq,
    required this.notification,
  });

  /// Stable id for widget keying, dismissal, and timer bookkeeping.
  final String id;

  /// Monotonic arrival order — the FIFO tie-breaker within a priority tier.
  final int seq;

  /// The promoted notification.
  final AppNotification notification;
}

/// How long a banner lingers before auto-expiring, by category. Ambient banners
/// never persist indefinitely — the operator can act or dismiss, and a stale
/// prompt clears itself. The category's dedicated surface (the event detail,
/// the calendar reconnect banner) remains the durable home for the action.
Duration _ttlFor(NotificationCategory category) {
  switch (category) {
    case NotificationCategory.meetingStartsSoon:
    case NotificationCategory.calendarAuthExpired:
      return const Duration(seconds: 120);
    // Anything else that reaches the rail (none today) gets a shorter dwell.
    // ignore: no_default_cases
    default:
      return const Duration(seconds: 45);
  }
}

/// Priority rank (lower = shown first). A meeting with a hard start time
/// outranks a calendar that merely needs reconnecting.
int _priority(NotificationCategory category) {
  switch (category) {
    case NotificationCategory.meetingStartsSoon:
      return 0;
    case NotificationCategory.calendarAuthExpired:
      return 1;
    // ignore: no_default_cases
    default:
      return 2;
  }
}

/// Categories with a genuine hard deadline — the only ones that justify
/// occupying a second visible slot when two overlap.
const _hardDeadlineCategories = {NotificationCategory.meetingStartsSoon};

/// How many banners to show at once: normally 1, but 2 when two genuinely
/// time-critical (hard-deadline) banners overlap. The rest queue.
int bannerVisibleCount(List<ActiveBanner> banners) {
  final deadlineCount = banners
      .where((b) => _hardDeadlineCategories.contains(b.notification.category))
      .length;
  return deadlineCount >= 2 ? 2 : 1;
}

/// Holds the active banner queue, fed by the LIVE notification lane filtered
/// to [NotificationPresentation.banner].
///
/// Live-lane only: `RecordingNotificationPort` (the single chokepoint every
/// produced notification flows through, before any OS-level suppression)
/// calls [ingestLive] as each notification is produced. The durable
/// notification center is deliberately NOT observed here — it is a
/// server-side history that replays on reconnect/workspace switch, and a
/// replayed entry must never resurface as a time-critical banner. Each banner
/// carries an auto-expiry timer; the rail renders only the highest-priority
/// [bannerVisibleCount], so an expiring or dismissed banner promotes the next
/// queued one automatically.
class BannerQueue extends Notifier<List<ActiveBanner>> {
  final Map<String, Timer> _timers = {};
  int _counter = 0;

  @override
  List<ActiveBanner> build() {
    final sub = ref
        .watch(liveNotificationLaneProvider)
        .stream
        .listen(ingestLive);
    ref.onDispose(() {
      sub.cancel();
      for (final timer in _timers.values) {
        timer.cancel();
      }
      _timers.clear();
    });

    return const [];
  }

  /// Enqueues [notification] when it is banner-class; anything else is
  /// ignored so the chokepoint can call this unconditionally.
  void ingestLive(AppNotification notification) {
    if (notification.presentation != NotificationPresentation.banner) {
      return;
    }
    final id = 'banner-${_counter++}';
    _timers[id] = Timer(_ttlFor(notification.category), () => dismiss(id));
    state = _ordered([
      ...state,
      ActiveBanner(id: id, seq: _counter, notification: notification),
    ]);
  }

  /// Removes the banner with [id] (dismiss or auto-expiry) and cancels its
  /// timer. Promoting the next queued banner is implicit — the rail re-renders
  /// from the shortened list.
  void dismiss(String id) {
    _timers.remove(id)?.cancel();
    final next = state.where((b) => b.id != id).toList();
    if (next.length != state.length) {
      state = next;
    }
  }

  /// Orders by priority (highest first), then FIFO by arrival within a tier.
  List<ActiveBanner> _ordered(List<ActiveBanner> banners) {
    final sorted = [...banners]
      ..sort((a, b) {
        final byPriority = _priority(
          a.notification.category,
        ).compareTo(_priority(b.notification.category));
        return byPriority != 0 ? byPriority : a.seq.compareTo(b.seq);
      });
    return sorted;
  }
}

/// The active banner queue.
final bannerQueueProvider = NotifierProvider<BannerQueue, List<ActiveBanner>>(
  BannerQueue.new,
);

/// Ambient rail that surfaces time-critical, actionable events as floating
/// [CcBanner]s near the top of the shell (PRD 25 §1).
///
/// Mapper-driven: it renders whatever the notification stream promoted to
/// [NotificationPresentation.banner], never a hardcoded event list. Renders
/// nothing when the queue is empty, so it is safe to mount permanently.
class BannerRail extends ConsumerWidget {
  /// Creates a [BannerRail].
  const BannerRail({super.key});

  /// Top offset that clears the shell title bar (40px) plus a gap.
  static const double _topInset = 40 + AppSpacing.md;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final banners = ref.watch(bannerQueueProvider);
    if (banners.isEmpty) {
      return const SizedBox.shrink();
    }
    final visible = banners.take(bannerVisibleCount(banners)).toList();

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            _topInset,
            AppSpacing.lg,
            0,
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final banner in visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: _BannerCard(
                      key: ValueKey(banner.id),
                      banner: banner,
                      onDismiss: () => ref
                          .read(bannerQueueProvider.notifier)
                          .dismiss(banner.id),
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

/// Maps one [ActiveBanner] to a [CcBanner], choosing the variant, glyph, and
/// route-navigating actions per category. Every action navigates via the
/// existing router to the notification's own deep link, then dismisses.
class _BannerCard extends StatelessWidget {
  const _BannerCard({super.key, required this.banner, required this.onDismiss});

  final ActiveBanner banner;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final notification = banner.notification;

    void goThenDismiss() {
      context.go(notification.route);
      onDismiss();
    }

    final (
      CcBannerVariant variant,
      IconData icon,
      List<CcBannerAction> actions,
    ) = switch (notification.category) {
      NotificationCategory.meetingStartsSoon => (
        CcBannerVariant.info,
        AppIcons.calendarClock,
        [
          CcBannerAction(
            label: l10n.bannerMeetingJoin,
            onPressed: goThenDismiss,
            primary: true,
          ),
          CcBannerAction(
            label: l10n.bannerMeetingRecordAndLink,
            onPressed: goThenDismiss,
          ),
        ],
      ),
      NotificationCategory.calendarAuthExpired => (
        CcBannerVariant.warning,
        AppIcons.calendarX,
        [
          CcBannerAction(
            label: l10n.bannerCalendarReconnect,
            onPressed: goThenDismiss,
            primary: true,
          ),
        ],
      ),
      // Defensive: any other category that reaches the rail still shows a
      // dismissible banner that opens its route.
      // ignore: no_default_cases
      _ => (
        CcBannerVariant.info,
        AppIcons.bell,
        [
          CcBannerAction(
            label: l10n.bannerView,
            onPressed: goThenDismiss,
            primary: true,
          ),
        ],
      ),
    };

    return CcBanner(
      title: notification.title,
      body: notification.body,
      variant: variant,
      icon: icon,
      actions: actions,
      onDismiss: onDismiss,
      dismissLabel: l10n.dismiss,
    );
  }
}
