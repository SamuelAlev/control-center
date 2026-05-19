import 'package:control_center/di/providers.dart';
import 'package:control_center/features/calendar/domain/entities/calendar_event.dart';
import 'package:control_center/features/calendar/domain/usecases/link_meeting_to_event_use_case.dart';
import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
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
  /// meeting↔event link. Returns the new meeting id, or null if the recorder
  /// did not start (e.g. no voice model / permission denied — the recorder's
  /// state carries the error for the UI to surface).
  ///
  /// Workspace is sourced from the event itself (never a separate, fallible
  /// parameter), honoring the workspace-isolation invariant.
  Future<String?> startRecordingForEvent(CalendarEvent event) async {
    final recorder = _ref.read(meetingRecorderControllerProvider.notifier);
    await recorder.start(title: event.title);

    final state = _ref.read(meetingRecorderControllerProvider);
    final meetingId = state.meetingId;
    if (!state.isRecording || meetingId == null) {
      return null;
    }

    await _ref.read(linkMeetingToEventUseCaseProvider).link(
          workspaceId: event.workspaceId,
          meetingId: meetingId,
          calendarEventId: event.id,
        );
    return meetingId;
  }
}

/// Provides the [CalendarRecordAndLinkUseCase].
final calendarRecordAndLinkProvider =
    Provider<CalendarRecordAndLinkUseCase>((ref) {
  return CalendarRecordAndLinkUseCase(ref);
});
