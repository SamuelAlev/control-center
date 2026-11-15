import 'dart:async';

import 'package:cc_domain/core/domain/events/calendar_events.dart';
import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/repositories/user_preferences_repository.dart';
import 'package:cc_domain/core/domain/repositories/workspace_repository.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:cc_host/cc_host.dart';

/// The synced preference holding a person's alert lead time in minutes, as the
/// client stores it (`SharedPreferencesNotificationPreferences`).
const meetingAlertLeadPreferenceKey =
    'notifications_calendar_alert_lead_minutes';

/// The lead time used when a person never picked one (the client's default).
const defaultMeetingAlertLeadMinutes = 5;

/// The longest lead the settings offer; the sweep looks this far ahead.
const maxMeetingAlertLeadMinutes = 30;

/// Raises [MeetingStartingSoon] once per synced calendar event, when the event
/// enters its owner's lead window.
///
/// Server-owned: the alert reaches the owner's devices and web push even when
/// no client is open. Dedup is the event's persisted `alertedAt`, so an alert
/// never fires twice, across restarts too. The window starts at "now", so a
/// meeting that started while the server was down never alerts late.
class MeetingAlertSweep {
  /// Creates a [MeetingAlertSweep].
  MeetingAlertSweep({
    required this._calendarRepository,
    required this._workspaceRepository,
    required this._userPreferences,
    required this._eventBus,
    this._interval = const Duration(seconds: 60),
    DateTime Function()? clock,
  }) : _clock = clock ?? DateTime.now;

  final CalendarRepository _calendarRepository;
  final WorkspaceRepository _workspaceRepository;
  final UserPreferencesRepository _userPreferences;
  final DomainEventBus _eventBus;
  final Duration _interval;
  final DateTime Function() _clock;

  Timer? _timer;
  bool _ticking = false;

  /// Starts the sweep and runs one immediately.
  void start() {
    if (_timer != null) {
      return;
    }
    _timer = Timer.periodic(_interval, (_) => unawaited(sweep()));
    unawaited(sweep());
  }

  /// One pass over every workspace. Overlapping calls are skipped.
  Future<void> sweep() async {
    if (_ticking) {
      return;
    }
    _ticking = true;
    try {
      final workspaces = await _workspaceRepository.watchAll().first;
      for (final w in workspaces) {
        try {
          await _sweepWorkspace(w.id);
        } on Object catch (e) {
          CcHostLog.warning('calendar: meeting alerts failed for ${w.id}: $e');
        }
      }
    } on Object catch (e) {
      CcHostLog.warning('calendar: meeting alert sweep failed: $e');
    } finally {
      _ticking = false;
    }
  }

  Future<void> _sweepWorkspace(String workspaceId) async {
    final now = _clock();
    final due = await _calendarRepository.getUpcomingEventsNeedingAlert(
      workspaceId,
      now,
      now.add(const Duration(minutes: maxMeetingAlertLeadMinutes)),
    );
    if (due.isEmpty) {
      return;
    }
    final owners = {
      for (final account in await _calendarRepository.getAccounts(workspaceId))
        account.id: account.userId,
    };
    final leads = <String, int>{};
    for (final event in due) {
      final owner = owners[event.accountId];
      // No owner, no recipient: an alert to the whole workspace about one
      // person's calendar is noise.
      if (owner == null || owner.isEmpty || !_attends(event)) {
        continue;
      }
      final lead = leads[owner] ??= await _leadMinutes(owner);
      if (event.startTime.difference(now) > Duration(minutes: lead)) {
        continue;
      }
      _eventBus.publish(
        MeetingStartingSoon(
          workspaceId: workspaceId,
          forUserId: owner,
          eventId: event.id,
          title: event.title,
          startTime: event.startTime,
          meetingUrl: event.meetingUrl,
          occurredAt: now,
        ),
      );
      await _calendarRepository.markAlerted(workspaceId, event.id, now);
    }
  }

  /// Whether the owner is going: not cancelled and not declined.
  static bool _attends(CalendarEvent event) =>
      event.status != CalendarEventStatus.cancelled &&
      !event.attendees.any((a) => a.self && a.responseStatus == 'declined');

  Future<int> _leadMinutes(String userId) async {
    final raw = await _userPreferences.get(
      userId,
      meetingAlertLeadPreferenceKey,
    );
    final minutes = int.tryParse(raw ?? '');
    return minutes == null ||
            minutes <= 0 ||
            minutes > maxMeetingAlertLeadMinutes
        ? defaultMeetingAlertLeadMinutes
        : minutes;
  }

  /// Stops the sweep.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
