import 'dart:typed_data';

import 'package:cc_domain/core/domain/ports/embedding_port.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';

/// Backfills missing embeddings for channel messages.
class BackfillMessageEmbeddingsUseCase {
  /// Creates a [BackfillMessageEmbeddingsUseCase].
  BackfillMessageEmbeddingsUseCase({
    required MessagingRepository messagingRepository,
    EmbeddingPort? embeddingService,
  }) : _messagingRepository = messagingRepository,
       _embeddingService = embeddingService;

  final MessagingRepository _messagingRepository;
  final EmbeddingPort? _embeddingService;

  /// Embeds unembedded messages of a single workspace, up to a batch of 200.
  ///
  /// One workspace per call: [workspaceId] both selects the messages read and
  /// routes each embedding back to the workspace its message came from, so a
  /// backfill can never write a vector into a neighbouring workspace.
  Future<int> execute(String workspaceId) async {
    if (_embeddingService == null || !_embeddingService.isReady) {
      return 0;
    }

    final messages = await _messagingRepository.getMessagesWithoutEmbedding(
      workspaceId,
      limit: 200,
    );
    if (messages.isEmpty) {
      return 0;
    }

    var count = 0;
    for (final m in messages) {
      try {
        final embedding = await _embeddingService.embed(m.content);
        final blob = Uint8List.view(embedding.buffer);
        await _messagingRepository.updateMessageEmbedding(
          workspaceId,
          m.id,
          blob,
        );
        count++;
      } catch (e) {
        CcDomainLog.error(
          'BackfillMessageEmbeddings: failed for ${m.id}: $e',
          e,
        );
      }
    }

    return count;
  }
}
