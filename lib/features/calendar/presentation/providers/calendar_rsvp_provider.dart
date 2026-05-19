import 'package:control_center/core/network/google_calendar_api_client.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// An RSVP choice for a calendar invitation.
enum RsvpResponse {
  /// "Yes" — attending.
  accepted,

  /// "No" — not attending.
  declined,

  /// "Maybe" — tentatively attending.
  tentative;

  /// The Google Calendar `responseStatus` value.
  String get apiValue => name;
}

/// Writes the signed-in user's RSVP to a calendar invitation, then optimistically
/// updates the local store so the choice shows immediately (before the next
/// sync). Requires the connected account to have the `calendar.events` scope.
class CalendarRsvpService {
  /// Creates a [CalendarRsvpService].
  CalendarRsvpService(this._apiClient, this._repository);

  final GoogleCalendarApiClient _apiClient;
  final CalendarRepository _repository;

  /// Whether [event] can be RSVP'd to — the user is an invited attendee who is
  /// not the organizer.
  static bool canRespond(CalendarEvent event) =>
      event.attendees.any((a) => a.self && !a.organizer);

  /// The user's current response on [event], if any.
  static String? currentResponse(CalendarEvent event) => event.myResponseStatus;

  /// Sends [response] for [event]. Throws if the API call fails (e.g. the
  /// account lacks write scope) — the caller surfaces the error.
  Future<void> respond(CalendarEvent event, RsvpResponse response) async {
    final status = response.apiValue;

    // PATCH replaces the attendees array, so send the full list with only the
    // self attendee's status changed.
    final attendees = <Map<String, dynamic>>[
      for (final a in event.attendees)
        <String, dynamic>{
          'email': a.email,
          if (a.displayName != null) 'displayName': a.displayName,
          'responseStatus': a.self ? status : (a.responseStatus ?? 'needsAction'),
        },
    ];

    await _apiClient.patchEventResponse(
      accountId: event.accountId,
      calendarId: event.calendarId,
      eventId: event.externalEventId,
      attendees: attendees,
    );

    final updatedAttendees = <CalendarAttendee>[
      for (final a in event.attendees)
        if (a.self)
          CalendarAttendee(
            email: a.email,
            displayName: a.displayName,
            responseStatus: status,
            self: true,
            organizer: a.organizer,
          )
        else
          a,
    ];
    await _repository.upsertEvents([event.copyWith(attendees: updatedAttendees)]);
  }
}

/// Provides the [CalendarRsvpService].
final calendarRsvpServiceProvider = Provider<CalendarRsvpService>((ref) {
  return CalendarRsvpService(
    ref.watch(googleCalendarApiClientProvider),
    ref.watch(calendarRepositoryProvider),
  );
});
