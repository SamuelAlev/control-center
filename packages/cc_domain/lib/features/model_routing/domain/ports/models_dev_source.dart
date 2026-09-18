/// Supplies the raw [models.dev](https://models.dev) `api.json` document.
///
/// Implemented in the infrastructure layer (`FileModelsDevSource`) as
/// disk cache (under the server data dir) → network fetch (1-hour TTL,
/// hourly background refresh). There is no bundled snapshot in source —
/// a first run with no cache and no network yields null. Thin clients read
/// the same document over `models.catalog`. The domain catalog only consumes
/// the parsed map.
abstract interface class ModelsDevSource {
  /// Returns the current catalog document, or null when nothing is available.
  Future<Map<String, dynamic>?> load();

  /// Forces a refresh past the TTL (e.g. a manual "sync now"). Returns the
  /// freshly fetched document, or null on failure.
  Future<Map<String, dynamic>?> refresh({bool force = false});
}
