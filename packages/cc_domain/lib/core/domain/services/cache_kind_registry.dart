import 'package:cc_domain/core/domain/value_objects/cache_kind.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/pr_review_cache_kinds.dart';
import 'package:cc_domain/features/repos/domain/value_objects/repo_access_cache_kinds.dart';

/// Every kind the `caches` table may hold.
///
/// An allow-list, in both directions. The retention sweep deletes only rows of
/// a kind declared here, each after its own retention, so a row of any other
/// kind is never pruned by accident. The cache store refuses (in debug and
/// tests) to write a kind that is not here, so durable state cannot slip into
/// the cache again: whatever must survive gets a table of its own.
///
/// Owners declare their kinds beside their own code and are listed here once.
// A namespace over one constant list; it is never instantiated.
// ignore: avoid_classes_with_only_static_members
abstract final class CacheKindRegistry {
  /// Every declared kind.
  static const List<CacheKind> declared = [
    ...PrReviewCacheKinds.declared,
    ...RepoAccessCacheKinds.declared,
  ];

  static final Set<String> _names = {for (final kind in declared) kind.name};

  /// Whether [name] is a declared cache kind.
  static bool isDeclared(String name) => _names.contains(name);
}
