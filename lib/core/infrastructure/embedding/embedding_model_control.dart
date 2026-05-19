// Seam for the embedding-model control surface the settings section reads.
//
// Desktop owns its own on-device embedding model (cc_natives FFI), so it
// controls it directly through the existing lifecycle controller + state
// provider (`embedding_model_control_io.dart`). Web/thin clients host no model;
// they drive the SERVER's embedding model over the `models.embedding*` RPC ops
// (`embedding_model_control_web.dart`). Both expose the SAME two providers —
// `embeddingModelControlProvider` (a `ModelControl`) and
// `embeddingModelStatusSnapshotProvider`
// (`FutureProvider<ModelStatusSnapshot?>`) — so the single `EmbeddingSection`
// watches them identically on both platforms. On web the status is `null` when
// the connected server exposes no model control (the section then renders an
// honest "managed on the server host" placeholder).
export 'embedding_model_control_io.dart'
    if (dart.library.js_interop) 'embedding_model_control_web.dart';
