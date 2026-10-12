import 'package:cc_domain/core/domain/entities/catalog_file.dart';

/// Workspace-scoped logical ownership of stored files, independent of their bytes.
abstract interface class FileCatalogRepository {
  Future<CatalogFile> createUpload({
    required String workspaceId,
    required String uploaderUserId,
    required String name,
    required String path,
    required String mediaType,
    required int bytes,
    bool ownedBytes,
  });

  Future<CatalogFile> recordArtifact({
    required String workspaceId,
    required String name,
    required String path,
    required String mediaType,
    required int bytes,
    String? creatorId,
  });

  Future<CatalogFile?> byId(String workspaceId, String fileId);
  Future<bool> hasPath(String workspaceId, String path);

  /// Validates every file before changing any, then permanently claims drafts.
  Future<void> claim(
    String workspaceId,
    String userId,
    List<({String fileId, String path})> attachments,
  );

  /// Tombstones only an unclaimed draft owned by [userId]. Safe to repeat.
  Future<void> discard(String workspaceId, String userId, String fileId);

  /// Only after a completed explicit discard, under the blob hash lock.
  /// Legacy content not created by an upload is never eligible.
  Future<bool> canReclaim(String workspaceId, String path);
}
