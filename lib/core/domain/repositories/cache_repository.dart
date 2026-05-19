abstract interface class CacheRepository {
  Future<String?> read(String workspaceId, String kind, String key);

  Future<void> put(
    String workspaceId,
    String kind,
    String key,
    String payload,
  );

  Future<void> deleteEntry(String workspaceId, String kind, String key);

  Future<void> deleteKind(String workspaceId, String kind);

  Future<void> deleteKindWithPrefix(
    String workspaceId,
    String kind,
    String keyPrefix,
  );
}
