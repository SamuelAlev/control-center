/// Platform seam for the one capability the desktop and web genuinely differ
/// in at the composition root: browser audio capture for the web meeting
/// recorder. Every other "host" capability is the same RPC adapter on both
/// targets and is declared directly in `providers.dart`.
library;

export 'audio_capture_bindings_io.dart'
    if (dart.library.js_interop) 'audio_capture_bindings_web.dart';
