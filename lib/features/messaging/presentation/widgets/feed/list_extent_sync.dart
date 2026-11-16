import 'dart:math' as math;

import 'package:super_sliver_list/super_sliver_list.dart';

/// Re-aligns [controller]'s index-keyed extent cache after the list's rows
/// changed from [oldKeys] to [newKeys].
///
/// `SuperListView` caches extents BY INDEX. When rows are inserted or removed
/// anywhere but the end, every row past the change inherits a neighbour's
/// extent unless the list is told. This diffs the two key lists — both in
/// LIST INDEX order (for the reverse feed, index 0 is the newest row) and each
/// free of duplicates — down to a common prefix and a common suffix, then
/// removes the differing old middle (highest index first) and adds the new
/// middle (ascending). The controller's item count goes from
/// `oldKeys.length` to `newKeys.length`, and every key outside the middle
/// keeps its extent, measured or estimated, at its new index. Rows in the new
/// middle start as estimates.
///
/// Requirements on the caller:
///
/// * `ListController.addItem` asks the list's `extentEstimation` callback for
///   the NEW index straight away, so the estimator must already resolve
///   against the new item list when this runs.
/// * The keys must cover EVERY item the list builds, including trailing
///   non-message rows such as the feed's load-more spinner (give it a stable
///   key of its own). The list's item count must equal `oldKeys.length`.
///
/// Returns false and changes nothing when the controller is detached, when
/// the list is mid-layout ([ListController.isLocked], where these calls
/// throw), or when the list's item count is not `oldKeys.length` — which
/// happens legitimately when the list element was recreated (a fresh list
/// starts empty) and the caller still holds the previous keys; the list's own
/// resize then estimates every row. Returns true otherwise, including the
/// no-op case of identical key lists.
bool syncListExtents(
  ListController controller,
  List<String> oldKeys,
  List<String> newKeys,
) {
  if (!controller.isAttached || controller.isLocked) {
    return false;
  }
  if (controller.numberOfItems != oldKeys.length) {
    return false;
  }
  final shared = math.min(oldKeys.length, newKeys.length);
  var prefix = 0;
  while (prefix < shared && oldKeys[prefix] == newKeys[prefix]) {
    prefix++;
  }
  if (prefix == oldKeys.length && prefix == newKeys.length) {
    return true;
  }
  // Capped so the suffix never overlaps the prefix.
  final suffixLimit = shared - prefix;
  var suffix = 0;
  while (suffix < suffixLimit &&
      oldKeys[oldKeys.length - 1 - suffix] ==
          newKeys[newKeys.length - 1 - suffix]) {
    suffix++;
  }
  final oldMiddleEnd = oldKeys.length - suffix;
  final newMiddleEnd = newKeys.length - suffix;
  for (var i = oldMiddleEnd - 1; i >= prefix; i--) {
    controller.removeItem(i);
  }
  for (var i = prefix; i < newMiddleEnd; i++) {
    controller.addItem(i);
  }
  return true;
}
