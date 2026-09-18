import 'package:cc_domain/features/newsfeed/domain/filter_list_update_state.dart';

/// Host-owned ABP filter lists used by the newsfeed content blocker.
///
/// The server fetches EasyList / uBlock lists, caches them under its data
/// dir, and serves the merged rule list over `newsfeed.filterLists.*`.
/// Thin clients never dial those URLs.
abstract interface class FilterListPort {
  /// Current update metadata (rule counts, last success).
  Future<FilterListUpdateState> readState();

  /// Refreshes the lists. When [force] is false, a fresh cache is reused.
  Future<FilterListUpdateState> refresh({bool force = false});

  /// Merged content-blocker rules, or an empty list before the first fetch.
  Future<List<Map<String, dynamic>>> readBlocklist();

  /// Tracking query parameters to strip from article URLs.
  Future<Set<String>> readRemoveParams();
}
