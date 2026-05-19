import 'package:cc_ui/cc_ui.dart';
import 'package:collection/collection.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// What moved since the previous finalized review pass.
///
/// The strip exists because a re-review otherwise restates every finding and
/// the reader has to remember which ones they already dealt with. Three
/// numbers turn "here are 14 findings again" into "two of these are new".
class ReviewArtifactDelta extends StatelessWidget {
  /// Creates a [ReviewArtifactDelta].
  const ReviewArtifactDelta({super.key, required this.delta});

  /// The `deltaSinceLast` metadata block of the latest review summary.
  final ReviewDelta delta;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem!;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: ds.bgSecondary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(AppIcons.gitCompareArrows, size: 13, color: ds.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              l10n.reviewHubDeltaSummary(
                delta.resolved,
                delta.added,
                delta.stillOpen,
              ),
              style: TextStyle(color: ds.textSecondary, fontSize: 12),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (delta.previousHeadSha != null) ...[
            const SizedBox(width: 8),
            Text(
              l10n.reviewHubDeltaPreviousSha(_short(delta.previousHeadSha!)),
              style: TextStyle(color: ds.textTertiary, fontSize: 10),
            ),
          ],
        ],
      ),
    );
  }

  String _short(String sha) => sha.length <= 7 ? sha : sha.substring(0, 7);
}

/// The parsed `deltaSinceLast` block of a review summary.
class ReviewDelta {
  /// Creates a [ReviewDelta].
  const ReviewDelta({
    required this.resolved,
    required this.added,
    required this.stillOpen,
    this.previousHeadSha,
    this.newMessageIds = const {},
    this.stillOpenMessageIds = const {},
  });

  /// Findings the previous pass reported that this one no longer does.
  final int resolved;

  /// Findings this pass reports that the previous one did not.
  final int added;

  /// Findings present in both passes and still outstanding.
  final int stillOpen;

  /// The head SHA the previous pass reviewed.
  final String? previousHeadSha;

  /// Message ids of the new findings, for per-row badging.
  final Set<String> newMessageIds;

  /// Message ids of the carried-over findings.
  final Set<String> stillOpenMessageIds;

  /// Whether nothing moved (or there was no previous pass to compare against).
  bool get isEmpty => resolved == 0 && added == 0 && stillOpen == 0;

  /// Value equality, so a re-parse of the SAME summary metadata compares equal.
  ///
  /// This is reached through `ReviewArtifact ==`, which is what stops a
  /// derived provider from notifying on every unrelated message in the
  /// space. Without it the fallback is identity, and a freshly-parsed
  /// identical delta is never identical.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewDelta &&
          runtimeType == other.runtimeType &&
          resolved == other.resolved &&
          added == other.added &&
          stillOpen == other.stillOpen &&
          previousHeadSha == other.previousHeadSha &&
          const SetEquality<String>().equals(
            newMessageIds,
            other.newMessageIds,
          ) &&
          const SetEquality<String>().equals(
            stillOpenMessageIds,
            other.stillOpenMessageIds,
          );

  @override
  int get hashCode => Object.hash(
    resolved,
    added,
    stillOpen,
    previousHeadSha,
    const SetEquality<String>().hash(newMessageIds),
    const SetEquality<String>().hash(stillOpenMessageIds),
  );

  /// Parses the block from a `review_summary` message's metadata, or null when
  /// the review has no previous pass to compare against.
  static ReviewDelta? fromMetadata(Map<String, dynamic>? metadata) {
    final raw = metadata?['deltaSinceLast'];
    if (raw is! Map) {
      return null;
    }
    final map = raw.cast<String, dynamic>();
    return ReviewDelta(
      resolved: (map['resolved'] as num?)?.toInt() ?? 0,
      added: (map['new'] as num?)?.toInt() ?? 0,
      stillOpen: (map['stillOpen'] as num?)?.toInt() ?? 0,
      previousHeadSha: map['previousHeadSha'] as String?,
      newMessageIds:
          (map['newMessageIds'] as List?)?.whereType<String>().toSet() ??
          const {},
      stillOpenMessageIds:
          (map['stillOpenMessageIds'] as List?)?.whereType<String>().toSet() ??
          const {},
    );
  }
}
