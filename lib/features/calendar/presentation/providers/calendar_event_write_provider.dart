import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event_draft.dart';
import 'package:cc_domain/features/calendar/domain/entities/calendar_event_reschedule.dart';
import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:control_center/core/providers/analytics_providers.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_ui_providers.dart';
import 'package:control_center/features/calendar/presentation/utils/calendar_format.dart'
    show dayKey;
import 'package:control_center/features/calendar/providers/google_auth_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Creates and deletes events on the person's own Google calendars.
///
/// Both run SERVER-SIDE (`calendar.createEvent`, `calendar.deleteEvent`) on
/// the host's OAuth token for the caller's own account; the host stores the
/// result, so the calendar watch shows it without a client-side write.
class CalendarEventWriteService {
  /// Creates a [CalendarEventWriteService]; writes are recorded through
  /// [_analytics] when given.
  CalendarEventWriteService(this._rpc, [this._analytics]);

  final RemoteRpcClient _rpc;
  final Analytics? _analytics;

  /// Books [draft] in [workspaceId] and returns the new event's local id.
  Future<String> create(String workspaceId, CalendarEventDraft draft) async {
    final result = await _rpc.call('calendar.createEvent', {
      'workspace_id': workspaceId,
      ...draft.toArgs(),
    });
    _analytics?.track(
      AnalyticsEvents.calendarEventCreated(
        workspaceId: workspaceId,
        allDay: draft.isAllDay,
        guests: draft.attendeeEmails.length,
        conference: draft.addConference,
      ),
    );
    return result['event_id'] as String;
  }

  /// Moves [event] to [move]'s times (only this occurrence of a recurring
  /// one); Google tells the guests.
  Future<void> move(CalendarEvent event, CalendarEventReschedule move) async {
    await _rpc.call('calendar.moveEvent', {
      'workspace_id': event.workspaceId,
      ...move.toArgs(),
    });
    _analytics?.track(
      AnalyticsEvents.calendarEventMoved(
        workspaceId: event.workspaceId,
        calendarEventId: event.id,
        hadGuests: event.attendees.any((a) => !a.self),
      ),
    );
  }

  /// Deletes [event] (only this occurrence of a recurring one).
  Future<void> delete(CalendarEvent event) async {
    await _rpc.call('calendar.deleteEvent', {
      'workspace_id': event.workspaceId,
      'event_id': event.id,
    });
    _analytics?.track(
      AnalyticsEvents.calendarEventDeleted(
        workspaceId: event.workspaceId,
        calendarEventId: event.id,
        hadGuests: event.attendees.any((a) => !a.self),
      ),
    );
  }
}

/// Provides the [CalendarEventWriteService].
final calendarEventWriteServiceProvider = Provider<CalendarEventWriteService>(
  (ref) => CalendarEventWriteService(
    ref.watch(rpcClientProvider),
    ref.watch(analyticsProvider),
  ),
);

/// The calendars the person may add events to: writable calendars on their
/// own accounts that do not need a reconnect. Primary calendars first.
final writableCalendarsProvider = Provider<List<CalendarSourceView>>((ref) {
  final expired = {
    for (final account in ref.watch(accountsNeedingReauthProvider)) account.id,
  };
  return [
    for (final source in ref.watch(allCalendarsProvider))
      if (source.writable && !expired.contains(source.accountId)) source,
  ]..sort((a, b) => a.primary == b.primary ? 0 : (a.primary ? -1 : 1));
});

/// Whether [event] sits on a calendar the person may delete from.
bool canDeleteCalendarEvent(
  CalendarEvent event,
  List<CalendarSourceView> writable,
) => writable.any(
  (s) => s.accountId == event.accountId && s.id == event.calendarId,
);

/// Whether the person may drag [event] to another time: on a calendar they
/// may write to, and theirs to move ([CalendarEventReschedule.allowedFor]).
bool canMoveCalendarEvent(
  CalendarEvent event,
  List<CalendarSourceView> writable,
) =>
    canDeleteCalendarEvent(event, writable) &&
    CalendarEventReschedule.allowedFor(event);

/// A time span the person picked on the grid (or the header's new-event
/// button), with the global point the composer opens beside.
@immutable
class CalendarSlot {
  /// Creates a [CalendarSlot].
  const CalendarSlot({
    required this.start,
    required this.end,
    required this.allDay,
    required this.anchor,
  });

  /// Local start (midnight of the first day when [allDay]).
  final DateTime start;

  /// Local end (midnight after the last day when [allDay]).
  final DateTime end;

  /// Whether the span covers whole days.
  final bool allDay;

  /// Global position the composer card is placed next to.
  final Offset anchor;

  CalendarSlot _with(DateTime start, DateTime end, {bool? allDay}) =>
      CalendarSlot(
        start: start,
        end: end,
        allDay: allDay ?? this.allDay,
        anchor: anchor,
      );

  /// Moved to [start], keeping the duration (the way people expect).
  CalendarSlot withStart(DateTime start) =>
      _with(start, start.add(end.difference(this.start)));

  /// Ending at [end].
  CalendarSlot withEnd(DateTime end) => _with(start, end);

  /// Moved to [day], keeping the times.
  CalendarSlot onDay(DateTime day) {
    final shift = dayKey(day).difference(dayKey(start));
    return _with(start.add(shift), end.add(shift));
  }

  /// An all-day span running through [lastDay].
  CalendarSlot through(DateTime lastDay) =>
      _with(start, dayKey(lastDay).add(const Duration(days: 1)));

  /// The same day as a whole-day span, or as a 9:00 hour when [allDay] is
  /// turned off.
  CalendarSlot asAllDay(bool allDay) {
    final day = dayKey(start);
    final from = allDay ? day : day.add(const Duration(hours: 9));
    return _with(
      from,
      from.add(allDay ? const Duration(days: 1) : const Duration(hours: 1)),
      allDay: allDay,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CalendarSlot &&
      start == other.start &&
      end == other.end &&
      allDay == other.allDay &&
      anchor == other.anchor;

  @override
  int get hashCode => Object.hash(start, end, allDay, anchor);
}

/// The slot the composer is open for, or null when it is closed. Switching
/// workspace closes it: a half-composed event never follows the person into
/// another workspace's calendar.
class CalendarComposerNotifier extends Notifier<CalendarSlot?> {
  @override
  CalendarSlot? build() {
    ref.watch(activeWorkspaceIdProvider);
    return null;
  }

  /// Opens the composer for [slot] (replacing any open one).
  void open(CalendarSlot slot) => state = slot;

  /// Replaces the open composer's span (a [CalendarSlot] derived from the
  /// current one keeps the card where it is).
  void update(CalendarSlot slot) {
    if (state != null) {
      state = slot;
    }
  }

  /// Closes the composer.
  void close() => state = null;
}

/// Tracks the open event composer.
final calendarComposerProvider =
    NotifierProvider<CalendarComposerNotifier, CalendarSlot?>(
      CalendarComposerNotifier.new,
    );
