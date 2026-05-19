// Seam for the voice section's DESKTOP-ONLY extras (model picker, VAD row,
// audio-input device picker + mic test).
//
// These sub-features are device-local: the ASR model selection, the bundled
// Silero VAD, and the mic-test recorder (`package:record`) all run against the
// SERVER host's hardware/filesystem, NOT the browser. So the single
// `VoiceSection` widget renders them through this seam: the real rows on the VM
// (`voice_section_extras_io.dart`), nothing on web
// (`voice_section_extras_web.dart`) — the web build never pulls `record` or the
// audio-input providers, and the section shows just the (server-reported) model
// status + actions.
export 'voice_section_extras_io.dart'
    if (dart.library.js_interop) 'voice_section_extras_web.dart';
