import 'package:control_center/features/calendar/domain/repositories/calendar_repository.dart';
import 'package:control_center/features/meetings/domain/repositories/meeting_repository.dart';

/// Links (or unlinks) a recorded meeting and a calendar event, keeping the
/// meeting's title in sync with the event's — unless the user has customized it.
///
/// This is the single linking chokepoint shared by the calendar's
/// record-and-link flow and the manual "link to event" / "link to meeting"
/// affordances, so the title-adoption rule lives in exactly one place.
class LinkMeetingToEventUseCase {
  /// Creates a [LinkMeetingToEventUseCase].
  LinkMeetingToEventUseCase({
    required CalendarRepository calendarRepository,
    required MeetingRepository meetingRepository,
  })  : _calendar = calendarRepository,
        _meetings = meetingRepository;

  final CalendarRepository _calendar;
  final MeetingRepository _meetings;

  /// Links [meetingId] to [calendarEventId] (1:1; relinking replaces the prior
  /// link). When the meeting's title is NOT user-customized, the meeting adopts
  /// the event's title — so a meeting recorded as "Meeting 2026-06-15 14:30"
  /// becomes the event's name. A meeting the user has renamed is left untouched.
  Future<void> link({
    required String workspaceId,
    required String meetingId,
    required String calendarEventId,
  }) async {
    await _calendar.linkMeetingToEvent(
      workspaceId: workspaceId,
      meetingId: meetingId,
      calendarEventId: calendarEventId,
    );
    final meeting = await _meetings.getById(workspaceId, meetingId);
    if (meeting == null || meeting.titleIsCustom) {
      return;
    }
    final event = await _calendar.getEventForMeeting(workspaceId, meetingId);
    final eventTitle = event?.title.trim() ?? '';
    if (eventTitle.isEmpty || eventTitle == meeting.title) {
      return;
    }
    await _meetings.upsert(
      meeting.copyWith(title: eventTitle, updatedAt: DateTime.now()),
    );
  }

  /// Removes [meetingId]'s calendar link. The meeting's title is left as-is
  /// (the calendar can no longer change it, but a previously-adopted title is
  /// not reverted — there is nothing meaningful to revert to).
  Future<void> unlink({
    required String workspaceId,
    required String meetingId,
  }) =>
      _calendar.unlinkMeeting(workspaceId, meetingId);
}
