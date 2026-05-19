/// Supplies the raw [models.dev](https://models.dev) `api.json` document.
///
/// Implemented in the infrastructure layer (cc_infra) with the resolution
/// chain: disk cache → bundled snapshot → network fetch (5-min TTL, hourly
/// background refresh). The domain catalog only consumes the parsed map.
abstract interface class ModelsDevSource {
  /// Returns the current catalog document, or null when nothing is available.
  Future<Map<String, dynamic>?> load();

  /// Forces a refresh past the TTL (e.g. a manual "sync now"). Returns the
  /// freshly fetched document, or null on failure.
  Future<Map<String, dynamic>?> refresh({bool force = false});
}
