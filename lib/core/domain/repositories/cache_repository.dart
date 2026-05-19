/// Repository for caching key-value payloads scoped by workspace and kind.
abstract interface class CacheRepository {
  /// Reads a cached payload by [workspaceId], [kind], and [key].
  ///
  /// Returns `null` if no entry exists.
  Future<String?> read(String workspaceId, String kind, String key);

  /// Stores a [payload] under [workspaceId], [kind], and [key].
  Future<void> put(
    String workspaceId,
    String kind,
    String key,
    String payload,
  );

  /// Deletes a specific cache entry.
  Future<void> deleteEntry(String workspaceId, String kind, String key);

  /// Deletes all entries for a given [kind] under [workspaceId].
  Future<void> deleteKind(String workspaceId, String kind);

  /// Deletes all entries for [kind] where the key starts with [keyPrefix].
  Future<void> deleteKindWithPrefix(
    String workspaceId,
    String kind,
    String keyPrefix,
  );
}
