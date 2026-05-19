import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/newsfeed/data/repositories/shared_prefs_site_allowlist_repository.dart';
import 'package:control_center/features/newsfeed/domain/repositories/site_allowlist_repository.dart';
import 'package:control_center/features/newsfeed/providers/newsfeed_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider for the [SiteAllowlistRepository] implementation.
final siteAllowlistRepositoryProvider = Provider<SiteAllowlistRepository>((
  ref,
) {
  return SharedPrefsSiteAllowlistRepository(
    ref.watch(sharedPreferencesProvider),
  );
});

/// Streams the current per-domain allowlist.
final siteAllowlistProvider = StreamProvider<Set<String>>((ref) {
  return ref.watch(siteAllowlistRepositoryProvider).watch();
});

/// True iff blocking is enabled for the given URL — i.e. the master
/// content-blocking switch is on AND the URL's host is not on the
/// allowlist. Returns `true` while the allowlist is still loading
/// (fail-closed: blocking is the default).
final siteBlockingEnabledProvider = Provider.family<bool, String>((ref, url) {
  final masterOn = ref.watch(contentBlockingProvider);
  if (!masterOn) {
    return false;
  }
  final allowed = ref.watch(siteAllowlistProvider).value;
  if (allowed == null || allowed.isEmpty) {
    return true;
  }
  final repo = ref.watch(siteAllowlistRepositoryProvider);
  return !repo.isAllowedUrl(url, allowed);
});
