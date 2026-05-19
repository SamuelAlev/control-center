import 'dart:convert';

import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_persistence/database/app_database.dart';

/// Translates between Drift rows and calendar domain entities. The single
/// translation point for the calendar feature (mirrors `MeetingMapper`).
class CalendarEventMapper {
  /// Creates a [CalendarEventMapper].
  const CalendarEventMapper();

  /// Maps an event row to a domain [CalendarEvent].
  CalendarEvent toDomain(CalendarEventsTableData row) {
    return CalendarEvent(
      id: row.id,
      workspaceId: row.workspaceId,
      accountId: row.accountId,
      externalEventId: row.externalEventId,
      calendarId: row.calendarId,
      title: row.title,
      description: row.description,
      location: row.location,
      startTime: row.startTime,
      endTime: row.endTime,
      isAllDay: row.isAllDay,
      attendees: decodeAttendees(row.attendeesJson),
      meetingUrl: row.meetingUrl,
      status: CalendarEventStatus.fromStorage(row.status),
      recurringEventId: row.recurringEventId,
      alertedAt: row.alertedAt,
      updatedAt: row.updatedAt,
    );
  }

  /// Maps an account row to a domain [CalendarAccount].
  CalendarAccount accountToDomain(CalendarAccountsTableData row) {
    return CalendarAccount(
      id: row.id,
      workspaceId: row.workspaceId,
      providerId: row.providerId,
      accountEmail: row.accountEmail,
      displayName: row.displayName,
      lastSyncedAt: row.lastSyncedAt,
      authExpiredAt: row.authExpiredAt,
    );
  }

  /// Maps a calendar-source row to a domain [CalendarSource].
  CalendarSource sourceToDomain(CalendarSourcesTableData row) {
    return CalendarSource(
      workspaceId: row.workspaceId,
      accountId: row.accountId,
      id: row.calendarId,
      summary: row.summary,
      backgroundColor: row.backgroundColor,
      primary: row.primary,
      writable: row.writable,
    );
  }

  /// Decodes the stored attendees JSON array into [CalendarAttendee]s.
  List<CalendarAttendee> decodeAttendees(String json) {
    if (json.isEmpty) {
      return const <CalendarAttendee>[];
    }
    try {
      final decoded = jsonDecode(json);
      if (decoded is! List) {
        return const <CalendarAttendee>[];
      }
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(
            (m) => CalendarAttendee(
              email: m['email'] as String? ?? '',
              displayName: m['displayName'] as String?,
              responseStatus: m['responseStatus'] as String?,
              self: m['self'] as bool? ?? false,
              organizer: m['organizer'] as bool? ?? false,
            ),
          )
          .toList(growable: false);
    } catch (_) {
      return const <CalendarAttendee>[];
    }
  }

  /// Encodes [attendees] to a JSON array string for storage.
  String encodeAttendees(List<CalendarAttendee> attendees) {
    return jsonEncode(
      attendees
          .map(
            (a) => <String, dynamic>{
              'email': a.email,
              if (a.displayName != null) 'displayName': a.displayName,
              if (a.responseStatus != null) 'responseStatus': a.responseStatus,
              'self': a.self,
              'organizer': a.organizer,
            },
          )
          .toList(growable: false),
    );
  }
}
