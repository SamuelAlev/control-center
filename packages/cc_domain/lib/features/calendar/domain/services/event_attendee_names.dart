import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';

/// De-duplicated display names of a calendar [event]'s attendees, in invitee
/// order, filtered by whether they are the local user.
///
/// `self: true` returns only the local user (for the "me" channel); `self:
/// false` returns the other invitees (for the "them" channel). Each name is the
/// attendee's [CalendarAttendee.displayLabel] — the provider display name when
/// present, otherwise a readable name derived from the email. Empty when there
/// is no event. Pure so the speaker→invitee mapping is unit-testable.
List<String> eventAttendeeNames(
  CalendarEvent? event, {
  required bool self,
}) {
  if (event == null) {
    return const [];
  }
  final names = <String>[];
  for (final a in event.attendees) {
    if (a.self != self) {
      continue;
    }
    final name = a.displayLabel;
    if (name.isNotEmpty && !names.contains(name)) {
      names.add(name);
    }
  }
  return names;
}
