import 'package:cc_domain/core/domain/value_objects/cache_kind.dart';

/// The `caches` kind holding which linked repositories the server could not
/// reach on its last probes.
///
/// A cache: every state is re-established by the next probe sweep, so a
/// deleted row costs one sweep of "unknown", never a wrong answer.
abstract final class RepoAccessCacheKinds {
  /// One row per workspace (key `v1`): the list of repositories in trouble.
  static const String repoAccess = 'repoAccess';

  /// Every kind above, with its retention.
  ///
  /// Three weeks, like the forge answers: the row is rewritten whenever a
  /// repository's state changes, so only a workspace nobody probed in that
  /// time loses it.
  static const List<CacheKind> declared = [
    CacheKind(repoAccess, retention: Duration(days: 21)),
  ];
}
