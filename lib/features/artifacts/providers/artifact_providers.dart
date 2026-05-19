import 'dart:convert';

import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/services/artifact_document_codec.dart';
import 'package:cc_domain/features/governance/domain/value_objects/artifact_block.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The work-product (artifact) RPC repository over the bound-workspace session.
///
/// Until now the client had no path to work products at all: the tables, DAOs,
/// service, and MCP tools existed server-side, and nothing could read them. The
/// artifact system is what gave that plumbing a consumer.
final workProductRepositoryProvider = Provider<RpcWorkProductRepository>(
  (ref) => RpcWorkProductRepository(ref.watch(rpcClientProvider)),
);

/// Live single artifact by id.
final artifactProvider = StreamProvider.autoDispose
    .family<WorkProduct?, String>(
      (ref, workProductId) =>
          ref.watch(workProductRepositoryProvider).watchById(workProductId),
    );

/// Every artifact published into a conversation, newest first.
final channelArtifactsProvider = StreamProvider.autoDispose
    .family<List<WorkProduct>, String>(
      (ref, channelId) =>
          ref.watch(workProductRepositoryProvider).watchForChannel(channelId),
    );

/// Revision history for an artifact, oldest first.
///
/// A future rather than a stream: history is append-only and the head row is
/// already watched, so a revision landing re-renders the card without this
/// needing its own subscription. The picker refreshes when the head changes.
final artifactRevisionsProvider = FutureProvider.autoDispose
    .family<List<WorkProductRevision>, String>((ref, workProductId) async {
      // Re-fetch whenever the head row changes, so a new revision appears in the
      // picker without the operator reopening the panel.
      ref.watch(artifactProvider(workProductId));
      return ref.watch(workProductRepositoryProvider).revisions(workProductId);
    });

/// Decodes a revision's stored envelope into a renderable document.
///
/// Loose on purpose: content that was accepted and persisted must always come
/// back out, even if it was written by an older build or hand-edited. One
/// malformed block is dropped; it never blanks the card.
ArtifactDocument decodeArtifactRevision(WorkProductRevision revision) {
  final raw = revision.content.trim();
  if (raw.isEmpty) {
    return const ArtifactDocument(blocks: []);
  }
  try {
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      return ArtifactDocument.fromEnvelopeJson(decoded);
    }
  } on FormatException {
    // Not JSON at all.
  }
  // A legacy or hand-written revision holding plain markdown still renders —
  // the column predates the block schema and its doc comment said "markdown".
  return ArtifactDocument(blocks: [ArtifactMarkdownBlock(text: raw)]);
}
