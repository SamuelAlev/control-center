import 'dart:async';

import 'package:cc_domain/core/domain/notifications/notification_category.dart';
import 'package:cc_domain/core/domain/ports/notification_port.dart';
import 'package:cc_domain/features/notifications/domain/entities/notification_feed_item.dart';
import 'package:control_center/core/notifications/notification_frame_mapper.dart';

/// The feed method of a wait announcement.
const String agentAwaitingInputMethod = 'notifications/agent_awaiting_input';

/// When an unanswered wait is raised again, measured from when it started.
///
/// A banner is gone in seconds and is easy to miss away from the desk. The
/// spacing widens because a wait ignored for ten minutes is more likely
/// unattended than unread. The last reminder comes before the 55-minute point
/// at which the gateway denies an unanswered Claude Code approval (see
/// SECURITY.md).
const List<Duration> kAgentWaitReminderSchedule = [
  Duration(minutes: 3),
  Duration(minutes: 10),
  Duration(minutes: 25),
  Duration(minutes: 45),
];

/// Raises the OS notification for an agent wait again while nobody answers it,
/// and withdraws that notification when the wait ends.
///
/// Driven by the active workspace's notification feed: the server records
/// each wait there and stamps it resolved when it ends, so the feed is the one
/// place that says both that a wait exists and that it is still open. Feed it
/// every snapshot through [update].
///
/// A reminder replaces the original OS notification (same identifier) rather
/// than adding a second one. It is skipped while one of the app's windows has
/// focus: the approval overlay, the question card and the bell are already in
/// front of the operator. It still goes through the [NotificationPort], so
/// preferences, quiet hours and focus mode apply as they do to the original.
class AgentWaitReminder {
  /// Creates an [AgentWaitReminder]. `render` maps a feed row to the
  /// notification its live frame produced; `reminderTitle` wraps that title.
  AgentWaitReminder({
    required this._port,
    required this._render,
    required this._reminderTitle,
    required this._isAppFocused,
    DateTime Function()? clock,
    this._schedule = kAgentWaitReminderSchedule,
  }) : _clock = clock ?? DateTime.now;

  final NotificationPort _port;
  final AppNotification? Function(NotificationFeedItem item) _render;
  final String Function(String title) _reminderTitle;
  final bool Function() _isAppFocused;
  final DateTime Function() _clock;
  final List<Duration> _schedule;

  /// Open waits from the current snapshot, by wait id.
  final Map<String, _OpenWait> _open = {};

  /// Waits already withdrawn this session, so each ended wait is withdrawn
  /// once rather than on every snapshot that still lists it.
  final Set<String> _withdrawn = {};

  /// Reconciles with the latest feed snapshot.
  void update(List<NotificationFeedItem> items) {
    final now = _clock();
    final listedOpen = <String>{};
    for (final item in items) {
      if (item.method != agentAwaitingInputMethod) {
        continue;
      }
      final wait = agentWaitOf(item.params);
      if (wait == null) {
        continue;
      }
      if (item.isResolved) {
        _open.remove(wait.id)?.cancel();
        // Also covers a wait that ended while the app was closed: its
        // notification may still sit in the system list with live buttons.
        if (_withdrawn.add(wait.id)) {
          _port.withdraw(wait);
        }
        continue;
      }
      listedOpen.add(wait.id);
      final open = _open[wait.id];
      if (open != null) {
        open.item = item;
        continue;
      }
      final created = _OpenWait(item);
      _open[wait.id] = created;
      _scheduleNext(created, now);
    }
    // A wait that left the snapshot without resolving (a workspace switch, a
    // trimmed feed) is not known to be over: stop reminding, withdraw nothing.
    final unlisted = [
      for (final id in _open.keys)
        if (!listedOpen.contains(id)) id,
    ];
    for (final id in unlisted) {
      _open.remove(id)?.cancel();
    }
  }

  void _scheduleNext(_OpenWait open, DateTime now) {
    while (open.nextStep < _schedule.length) {
      final due = open.item.createdAt.add(_schedule[open.nextStep]);
      if (due.isAfter(now)) {
        open.timer = Timer(due.difference(now), () => _fire(open));
        return;
      }
      // A step already behind us (the app started after it) is skipped, so
      // opening the app onto an old wait does not fire a burst of reminders.
      open.nextStep++;
    }
  }

  void _fire(_OpenWait open) {
    open.timer = null;
    open.nextStep++;
    if (!_isAppFocused()) {
      final original = _render(open.item);
      if (original != null) {
        _port.show(
          AppNotification(
            category: original.category,
            title: _reminderTitle(original.title),
            body: original.body,
            route: original.route,
            workspaceId: original.workspaceId,
            spaceId: original.spaceId,
            presentation: original.presentation,
            suppressWhenViewingTarget: original.suppressWhenViewingTarget,
            wait: original.wait,
          ),
        );
      }
    }
    _scheduleNext(open, _clock());
  }

  /// Cancels every pending reminder.
  void dispose() {
    for (final open in _open.values) {
      open.cancel();
    }
    _open.clear();
  }
}

class _OpenWait {
  _OpenWait(this.item);

  /// The latest feed row for this wait.
  NotificationFeedItem item;

  /// Index into the schedule of the next reminder.
  int nextStep = 0;

  Timer? timer;

  void cancel() {
    timer?.cancel();
    timer = null;
  }
}
