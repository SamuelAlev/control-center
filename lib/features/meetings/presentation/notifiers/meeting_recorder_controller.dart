/// Platform seam for the meeting recorder.
///
/// Live recording captures native microphone + system-output audio and
/// transcribes it on-device (cc_natives / `record` / the speech models) — a
/// desktop-only capability with no browser equivalent. The VM build exports the
/// real `MeetingRecorderController` (`meeting_recorder_controller_io.dart`); the
/// web build exports an INERT controller that never records
/// (`meeting_recorder_controller_web.dart`) so the SAME meeting screens compile
/// and render, with data flowing over RPC while the record action is a no-op.
///
/// Both variants expose the identical public surface: the
/// `meetingRecorderControllerProvider` and the `MeetingRecorderController`
/// type with its full method set, so importers (screens, the detection /
/// toolbar controllers, the recording HUD) are unchanged across platforms.
library;

export 'meeting_recorder_controller_io.dart'
    if (dart.library.js_interop) 'meeting_recorder_controller_web.dart';
