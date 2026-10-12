/// Origin of a durable logical workspace file.
enum CatalogFileSource { upload, artifact }

/// Lifecycle of a logical file. Physical bytes may be shared with other files
/// or legacy transcripts, so a tombstone does not imply unlinking the blob.
enum CatalogFileState { draft, attached, artifact, discarded }

/// Durable logical identity of an upload or generated artifact.
class CatalogFile {
  const CatalogFile({
    required this.id,
    required this.workspaceId,
    required this.name,
    required this.path,
    required this.mediaType,
    required this.bytes,
    required this.source,
    required this.state,
    this.uploaderUserId,
    this.creatorId,
    this.ownedBytes = false,
  }) : assert(bytes >= 0),
       assert(source != CatalogFileSource.upload || uploaderUserId != null),
       assert(
         source != CatalogFileSource.artifact ||
             state == CatalogFileState.artifact,
       );

  final String id;
  final String workspaceId;
  final String name;
  final String path;
  final String mediaType;
  final int bytes;
  final CatalogFileSource source;
  final CatalogFileState state;
  final String? uploaderUserId;

  /// Agent or human principal that generated this artifact, when known.
  final String? creatorId;

  /// Whether this upload created the bytes. Existing legacy hashes must never
  /// be unlinked by a later draft upload that deduplicated against them.
  final bool ownedBytes;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CatalogFile &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          name == other.name &&
          path == other.path &&
          mediaType == other.mediaType &&
          bytes == other.bytes &&
          source == other.source &&
          state == other.state &&
          uploaderUserId == other.uploaderUserId &&
          creatorId == other.creatorId &&
          ownedBytes == other.ownedBytes;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    name,
    path,
    mediaType,
    bytes,
    source,
    state,
    uploaderUserId,
    creatorId,
    ownedBytes,
  );
}
