import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';
import 'package:flutter_riverpod/legacy.dart';

/// The review's finding filters, keyed by review space.
///
/// Lifted out of the findings list because the controls and the list no longer
/// live in the same widget: the filters are in the left rail, beside the
/// counts they change, and the findings are in the scroll beside the report.
/// Keeping the state in either one would make the other reach into it.
///
/// Per space, so opening a second pull request does not inherit the filters you
/// left on the first.
final reviewKindFilterProvider = StateProvider.autoDispose
    .family<Set<ReviewNodeKind>, String>((ref, spaceId) => const {});

/// Status filters for the same space. Empty means every status.
final reviewStatusFilterProvider = StateProvider.autoDispose
    .family<Set<ReviewNodeStatus>, String>((ref, spaceId) => const {});

/// Whether dismissed findings are listed.
///
/// Off by default and separate from [reviewStatusFilterProvider]: a dismissed
/// finding is not one status among four, it is one the reader has already
/// decided about, and it stays out of the way until they ask for it.
final reviewShowDismissedProvider = StateProvider.autoDispose
    .family<bool, String>((ref, spaceId) => false);

/// Applies the space's filters to [findings].
///
/// One implementation, so the rail's counts and the scroll's rows can never
/// disagree about what is showing.
List<ReviewFinding> applyReviewFilters<ReviewFinding extends Object>(
  List<ReviewFinding> findings, {
  required ReviewNodeKind Function(ReviewFinding) kindOf,
  required ReviewNodeStatus Function(ReviewFinding) statusOf,
  required Set<ReviewNodeKind> kinds,
  required Set<ReviewNodeStatus> statuses,
  required bool showDismissed,
}) => [
  for (final f in findings)
    if ((kinds.isEmpty || kinds.contains(kindOf(f))) &&
        (statuses.isEmpty || statuses.contains(statusOf(f))) &&
        (showDismissed || statusOf(f) != ReviewNodeStatus.dismissed))
      f,
];
