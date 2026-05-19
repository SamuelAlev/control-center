// Seam for the diarization-model control surface the settings section reads.
//
// Desktop owns its own on-device speaker-diarization model (cc_natives FFI), so
// it controls it directly through the existing lifecycle notifier + state
// provider (`diarization_model_control_io.dart`). Web/thin clients host no
// model; they drive the SERVER's diarization model over the
// `models.diarization*` RPC ops (`diarization_model_control_web.dart`). Both
// expose the SAME two providers — `diarizationModelControlProvider` (a
// `ModelControl`) and `diarizationModelStatusSnapshotProvider`
// (`FutureProvider<ModelStatusSnapshot?>`) — so the single `DiarizationSection`
// watches them identically on both platforms. On web the status is `null` when
// the connected server exposes no model control (the section then renders an
// honest "managed on the server host" placeholder).
export 'diarization_model_control_io.dart'
    if (dart.library.js_interop) 'diarization_model_control_web.dart';
