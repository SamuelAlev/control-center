/// Platform seam for starting a meeting recording from a calendar event.
///
/// Recording is desktop-only (native audio capture + on-device transcription),
/// so this delegates to the real recorder on the VM and reports an honest "not
/// available on web" error on web — keeping the recorder controller (cc_natives)
/// off the web compile graph.
library;

export 'calendar_recording_bindings_io.dart'
    if (dart.library.js_interop) 'calendar_recording_bindings_web.dart';
