/// Platform seam for the meeting recorder. Both implementations share the
/// same control surface: production captures audio and streams it to the host;
/// the public demo asks the server for a fixed, fictional transcript instead
/// without opening the microphone or system capture on either platform.
library;

export 'meeting_recorder_controller_io.dart'
    if (dart.library.js_interop) 'meeting_recorder_controller_web.dart';
