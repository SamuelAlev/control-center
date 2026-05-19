import 'dart:typed_data';

/// Port for producing text embeddings.
///
/// The on-device implementation was lost from the working tree before
/// this turn; the concrete `EmbeddingService` stub in
/// `lib/core/infrastructure/embedding/` preserves the API contract so
/// callers compile and gracefully degrade to non-vector code paths via
/// [isReady].
abstract class EmbeddingPort {
  /// Whether the embedder is loaded and ready to produce vectors.
  bool get isReady;

  /// Dimensionality of the produced vectors.
  int get dimension;

  /// Returns a unit-norm vector for [text].
  ///
  /// Implementations may throw if called when [isReady] is `false`.
  Future<Float32List> embed(String text);
}
