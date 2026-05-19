// Web binding for the calendar "record this event as a meeting" hook.
//
// Meeting recording captures native audio + transcribes on-device — desktop-
// only. On web the hook reports an honest "not available on web" error and
// records nothing, so the calendar still renders (events are read over RPC);
// only the record-and-link action is unavailable.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Result of attempting to start a recording for a calendar event.
typedef CalendarRecordingStart = ({String? meetingId, String? error});

/// No local recorder on web — returns an honest error.
Future<CalendarRecordingStart> startCalendarEventRecording(
  Ref ref,
  String title,
) async {
  return (
    meetingId: null,
    error: 'Meeting recording is a desktop-only feature, not available on web.',
  );
}
