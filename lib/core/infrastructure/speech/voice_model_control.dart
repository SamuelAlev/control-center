// Seam for the voice-model control surface the settings section reads.
//
// Desktop owns its own on-device speech-to-text model (cc_natives FFI), so it
// controls it directly through the existing lifecycle notifier + state provider
// (`voice_model_control_io.dart`). Web/thin clients host no model; they drive
// the SERVER's voice model over the `models.voice*` RPC ops
// (`voice_model_control_web.dart`). Both expose the SAME two providers —
// `voiceModelControlProvider` (a `ModelControl`) and
// `voiceModelStatusSnapshotProvider` (`FutureProvider<ModelStatusSnapshot?>`) —
// so the single `VoiceSection` watches them identically on both platforms. On
// web the status is `null` when the connected server exposes no model control
// (the section then renders an honest "managed on the server host"
// placeholder).
export 'voice_model_control_io.dart'
    if (dart.library.js_interop) 'voice_model_control_web.dart';
