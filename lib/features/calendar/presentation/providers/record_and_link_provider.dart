import 'package:cc_domain/features/calendar/domain/entities/calendar_event.dart';
import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:control_center/core/providers/analytics_providers.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/calendar/domain/usecases/link_meeting_to_event_use_case.dart';
import 'package:control_center/features/calendar/presentation/providers/calendar_recording_bindings.dart';
import 'package:control_center/shared/utils/open_url.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provides the [LinkMeetingToEventUseCase] — the shared link/unlink chokepoint
/// that also keeps a meeting's title in sync with its calendar event.
final linkMeetingToEventUseCaseProvider = Provider<LinkMeetingToEventUseCase>((
  ref,
) {
  return LinkMeetingToEventUseCase(
    calendarRepository: ref.watch(calendarRepositoryProvider),
    meetingRepository: ref.watch(meetingRepositoryProvider),
  );
});

/// Opens a meeting's call link in the system browser; false when the system
/// refused it. A provider so tests join without launching a browser.
final meetingLinkOpenerProvider = Provider<bool Function(String url)>(
  (ref) => openExternalUrl,
);

/// Joins a calendar event's call and records it: opens the call link (when
/// the event has one), starts a meeting recording seeded from the event and
/// links the resulting `Meeting` back to the event.
class CalendarRecordAndLinkUseCase {
  /// Creates a [CalendarRecordAndLinkUseCase].
  CalendarRecordAndLinkUseCase(this._ref);

  final Ref _ref;

  /// How long [startRecordingForEventId] waits for the event to load.
  static const _lookupTimeout = Duration(seconds: 10);

  /// Opens [url], a meeting's call link, in the system browser.
  bool join(String url) => _ref.read(meetingLinkOpenerProvider)(url);

  /// [startRecordingForEvent] for an event known only by id, as a
  /// notification knows it. A null meeting id with a null error means the
  /// event could not be found.
  Future<CalendarRecordingStart> startRecordingForEventId({
    required String workspaceId,
    required String eventId,
  }) async {
    final event = await _ref
        .read(calendarRepositoryProvider)
        .watchEventById(workspaceId, eventId)
        .first
        .timeout(_lookupTimeout, onTimeout: () => null);
    if (event == null) {
      return (meetingId: null, error: null);
    }
    return startRecordingForEvent(event);
  }

  /// Opens the event's call link first, when it has one: joining has the
  /// deadline, and it must not wait on (or be lost to) the recorder. Then
  /// starts the recorder with the event's title and, once recording, writes a
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
    final url = event.meetingUrl;
    if (url != null) {
      join(url);
    }
    final result = await startCalendarEventRecording(_ref, event.title);
    final meetingId = result.meetingId;
    if (meetingId == null) {
      return result;
    }

    await _ref
        .read(linkMeetingToEventUseCaseProvider)
        .link(
          workspaceId: event.workspaceId,
          meetingId: meetingId,
          calendarEventId: event.id,
        );
    _ref.track(
      AnalyticsEvents.calendarEventRecorded(
        workspaceId: event.workspaceId,
        calendarEventId: event.id,
      ),
    );
    return result;
  }
}

/// Provides the [CalendarRecordAndLinkUseCase].
final calendarRecordAndLinkProvider = Provider<CalendarRecordAndLinkUseCase>((
  ref,
) {
  return CalendarRecordAndLinkUseCase(ref);
});
