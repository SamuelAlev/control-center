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
  ///
  /// Which message holds a claimed file is recorded by the message write
  /// itself, not here: the claim runs before the message exists.
  Future<void> claim(
    String workspaceId,
    String userId,
    List<({String fileId, String path})> attachments,
  );

  /// Tombstones only an unclaimed draft owned by [userId]. Safe to repeat.
  Future<void> discard(String workspaceId, String userId, String fileId);

  /// Only after a completed explicit discard, under the blob hash lock.
  /// Bytes the upload did not create (it deduplicated against existing
  /// content) are never eligible, and neither are bytes any live catalog row
  /// (a draft, an attachment a message holds, an artifact) still names. The
  /// answer comes from the catalog alone: every message attachment of an
  /// uploaded blob is claimed through it.
  Future<bool> canReclaim(String workspaceId, String path);
}
