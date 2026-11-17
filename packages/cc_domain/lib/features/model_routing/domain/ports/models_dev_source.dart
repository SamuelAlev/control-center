import 'package:cc_domain/features/model_routing/domain/entities/model_provider.dart';

/// Supplies the [models.dev](https://models.dev) catalog: the providers and
/// models its `api.json` document describes.
///
/// Implemented in the infrastructure layer (`FileModelsDevSource`) as
/// disk cache (under the server data dir) → network fetch (6-hour TTL, with a
/// background refresh on the same cadence). There is no bundled snapshot in
/// source — a first run with no cache and no network yields null. Thin
/// clients get the same document over `models.catalog`
/// (`RpcModelsDevSource`).
///
/// A source hands out providers, not the decoded document. The document is
/// megabytes of JSON that is read exactly once; an implementation parses it
/// as it reads it (`ModelsDevParser`) so the decoded form never
/// exists in full.
abstract interface class ModelsDevSource {
  /// The catalog's providers by id, in document order, or null when nothing
  /// is available.
  Future<Map<String, ProviderEntry>?> load();

  /// Brings the catalog up to date: fetches when the cached copy is past its
  /// TTL, or regardless of it when [force] is set (a manual "sync now").
  ///
  /// Returns the providers to use from now on. Null means there is nothing
  /// newer than what this source last handed out (the fetch failed, or the
  /// copy the caller already has is still current), so the caller keeps what
  /// it holds.
  Future<Map<String, ProviderEntry>?> refresh({bool force = false});

  /// The document itself, as the JSON text models.dev serves, or null when
  /// there is none. For a host that relays it to its thin clients: passing
  /// the text along costs neither side a decode of something only the
  /// receiver will read.
  Future<String?> documentText();
}
