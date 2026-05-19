import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_rpc/cc_rpc.dart' show RemoteRpcClient;
import 'package:control_center/core/providers/rpc_client_provider.dart';
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

/// Writes the signed-in user's RSVP to a calendar invitation.
///
/// The write runs SERVER-SIDE over the `calendar.rsvp` RPC op: the host PATCHes
/// Google on its own OAuth token (the thin client holds none) and optimistically
/// upserts the local event, so the choice shows immediately via the calendar
/// watch stream (no client-side optimistic write needed).
class CalendarRsvpService {
  /// Creates a [CalendarRsvpService].
  CalendarRsvpService(this._rpc);

  final RemoteRpcClient _rpc;

  /// Whether [event] can be RSVP'd to — the user is an invited attendee who is
  /// not the organizer.
  static bool canRespond(CalendarEvent event) =>
      event.attendees.any((a) => a.self && !a.organizer);

  /// The user's current response on [event], if any.
  static String? currentResponse(CalendarEvent event) => event.myResponseStatus;

  /// Sends [response] for [event]. Throws if the host call fails (e.g. the
  /// account lacks write scope) — the caller surfaces the error.
  Future<void> respond(CalendarEvent event, RsvpResponse response) async {
    await _rpc.call('calendar.rsvp', {
      'event_id': event.id,
      'response': response.apiValue,
    });
  }
}

/// Provides the [CalendarRsvpService].
final calendarRsvpServiceProvider = Provider<CalendarRsvpService>((ref) {
  return CalendarRsvpService(ref.watch(rpcClientProvider));
});
