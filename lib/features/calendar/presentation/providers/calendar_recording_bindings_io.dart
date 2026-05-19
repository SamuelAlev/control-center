// Desktop binding for the calendar "record this event as a meeting" hook.
//
// Delegates to the real meeting recorder (native audio capture + on-device
// transcription) — desktop-only.
library;

import 'package:control_center/features/meetings/presentation/notifiers/meeting_recorder_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Result of attempting to start a recording for a calendar event.
typedef CalendarRecordingStart = ({String? meetingId, String? error});

/// Starts the meeting recorder with [title] and reports the new meeting id (or
/// the recorder error when it did not start).
Future<CalendarRecordingStart> startCalendarEventRecording(
  Ref ref,
  String title,
) async {
  final recorder = ref.read(meetingRecorderControllerProvider.notifier);
  await recorder.start(title: title);
  final state = ref.read(meetingRecorderControllerProvider);
  if (!state.isRecording || state.meetingId == null) {
    return (meetingId: null, error: state.error);
  }
  return (meetingId: state.meetingId, error: null);
}
