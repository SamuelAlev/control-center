import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/calendar/domain/usecases/link_meeting_to_event_use_case.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_recording_bindings.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [LinkMeetingToEventUseCase] — the shared link/unlink chokepoint
/// that also keeps a meeting's title in sync with its calendar event.
final linkMeetingToEventUseCaseProvider =
    Provider<LinkMeetingToEventUseCase>((ref) {
  return LinkMeetingToEventUseCase(
    calendarRepository: ref.watch(calendarRepositoryProvider),
    meetingRepository: ref.watch(meetingRepositoryProvider),
  );
});

/// Starts a meeting recording seeded from a calendar event and links the
/// resulting `Meeting` back to the event.
class CalendarRecordAndLinkUseCase {
  /// Creates a [CalendarRecordAndLinkUseCase].
  CalendarRecordAndLinkUseCase(this._ref);

  final Ref _ref;

  /// Starts the recorder with the event's title and, once recording, writes a
  /// meeting↔event link. Returns the new meeting id (and a null error), or a
  /// null meeting id plus the error when the recorder did not start (e.g. no
  /// voice model / permission denied, or web where recording is unavailable).
  ///
  /// Recording is desktop-only, so it goes through the recording seam; the
  /// link write is plain repository work and runs on both targets.
  ///
  /// Workspace is sourced from the event itself (never a separate, fallible
  /// parameter), honoring the workspace-isolation invariant.
  Future<CalendarRecordingStart> startRecordingForEvent(
    CalendarEvent event,
  ) async {
    final result = await startCalendarEventRecording(_ref, event.title);
    final meetingId = result.meetingId;
    if (meetingId == null) {
      return result;
    }

    await _ref.read(linkMeetingToEventUseCaseProvider).link(
          workspaceId: event.workspaceId,
          meetingId: meetingId,
          calendarEventId: event.id,
        );
    return result;
  }
}

/// Provides the [CalendarRecordAndLinkUseCase].
final calendarRecordAndLinkProvider =
    Provider<CalendarRecordAndLinkUseCase>((ref) {
  return CalendarRecordAndLinkUseCase(ref);
});
