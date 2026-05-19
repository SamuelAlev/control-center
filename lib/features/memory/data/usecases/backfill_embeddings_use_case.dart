import 'package:control_center/core/database/app_database.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_service.dart';

/// One-shot job that fills in missing embeddings on memory facts.
///
/// Stub: the original implementation walked `memory_facts` rows with
/// null `embedding` blobs and re-vectorized them. With the embedder
/// disabled in this build the job is a no-op that returns 0.
class BackfillEmbeddingsUseCase {
  /// Creates a new [BackfillEmbeddingsUseCase].
  BackfillEmbeddingsUseCase({
    required AppDatabase database,
    EmbeddingService? embeddingService,
  }) : _embeddingService = embeddingService;

  final EmbeddingService? _embeddingService;

  /// Backfills missing embeddings. Returns the count actually written.
  Future<int> execute() async {
    final service = _embeddingService;
    if (service == null || !service.isReady) {
      return 0;
    }
    return 0;
  }
}
