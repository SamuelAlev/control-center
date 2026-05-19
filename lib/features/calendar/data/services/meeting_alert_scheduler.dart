import 'dart:async';

import 'package:control_center/core/domain/events/calendar_events.dart';
import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:flutter/foundation.dart';

/// Per-minute scheduler that fires [MeetingStartingSoon] for the active
/// workspace's events entering the configured lead window.
///
/// Dedup is persisted via the event's `alertedAt` (set by [CalendarRepository.
/// markAlerted]) so an alert never fires twice — including across app restarts.
/// Replay of *past* meetings is impossible by construction: the lookup window
/// starts at "now", so an event whose start already passed while the app was
/// closed is never returned and never alerts.
class MeetingAlertScheduler {
  /// Creates a [MeetingAlertScheduler].
  MeetingAlertScheduler({
    required CalendarRepository repository,
    required DomainEventBus eventBus,
    required String? Function() activeWorkspaceId,
    required Future<int> Function() leadTimeMinutes,
    Duration tick = const Duration(seconds: 60),
  })  : _repository = repository,
        _eventBus = eventBus,
        _activeWorkspaceId = activeWorkspaceId,
        _leadTimeMinutes = leadTimeMinutes,
        _tick = tick;

  final CalendarRepository _repository;
  final DomainEventBus _eventBus;
  final String? Function() _activeWorkspaceId;
  final Future<int> Function() _leadTimeMinutes;
  final Duration _tick;

  Timer? _timer;

  /// Starts the scheduler (runs an immediate tick too, so an in-window event
  /// alerts as soon as the app opens).
  void start() {
    if (_timer != null) {
      return;
    }
    _timer = Timer.periodic(_tick, (_) => unawaited(runOnce()));
    unawaited(runOnce());
  }

  /// Stops the scheduler.
  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  /// Whether the scheduler is running.
  bool get isRunning => _timer != null;

  /// Runs a single scan: publishes [MeetingStartingSoon] for each due event and
  /// marks it alerted. Exposed for deterministic testing.
  @visibleForTesting
  Future<void> runOnce() async {
    final workspaceId = _activeWorkspaceId();
    if (workspaceId == null) {
      return;
    }
    try {
      final lead = await _leadTimeMinutes();
      final now = DateTime.now();
      final due = await _repository.getUpcomingEventsNeedingAlert(
        workspaceId,
        now,
        now.add(Duration(minutes: lead)),
      );
      for (final event in due) {
        _eventBus.publish(
          MeetingStartingSoon(
            workspaceId: workspaceId,
            eventId: event.id,
            title: event.title,
            startTime: event.startTime,
            meetingUrl: event.meetingUrl,
            occurredAt: now,
          ),
        );
        await _repository.markAlerted(workspaceId, event.id, now);
      }
    } on Object catch (e) {
      AppLog.w('meeting_alert', 'Alert scan failed: $e');
    }
  }

  /// Disposes the timer.
  void dispose() => stop();
}
