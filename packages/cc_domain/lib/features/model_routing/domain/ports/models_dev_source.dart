import 'package:cc_domain/features/model_routing/domain/entities/credential_account.dart';
import 'package:cc_domain/features/model_routing/domain/entities/usage.dart';

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

/// Fetches a live usage/quota report for a credential, when the provider
/// exposes a usage API. Optional — most providers won't implement it, in which
/// case credential ranking falls back to observed cost history.
abstract interface class UsageReportSource {
  /// Fetches the usage report for [account], or null when unavailable.
  Future<UsageReport?> fetch(CredentialAccount account, {String? modelId});
}
