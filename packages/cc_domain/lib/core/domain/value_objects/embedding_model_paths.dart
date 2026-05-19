/// Resolved on-disk locations for the embedding model assets.
///
/// Pure value object: the download/resolve lifecycle lives in the app's
/// `EmbeddingModelManager`; the on-device embedder (in `cc_natives`) only
/// consumes these resolved paths. Kept in `cc_domain` so both the app
/// (resolution) and `cc_natives` (inference) can name the same type without
/// either depending on the other.
class EmbeddingModelPaths {
  /// Creates a new [EmbeddingModelPaths].
  const EmbeddingModelPaths({required this.model, required this.vocab});

  /// Absolute path to the ONNX model file.
  final String model;

  /// Absolute path to the wordpiece vocabulary file.
  final String vocab;
}
