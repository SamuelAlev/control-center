// One finalized review pass over a PR — the record that makes the NEXT manual
// review delta-aware.
//
// Without a snapshot, every re-review restates the entire finding list and the
// reader has to remember which ones they already dealt with. With one, a pass
// can say "3 resolved, 2 new, 4 still open" and point at exactly which.
//
// ignore_for_file: sort_constructors_first

import 'package:cc_domain/features/pr_review/domain/services/finding_fingerprint.dart';
import 'package:cc_domain/features/pr_review/domain/value_objects/review_verdict.dart';

/// Counts describing one review pass, and how its findings were dealt with.
///
/// These are the "made / addressed" counters: how many findings a review
/// produced versus how many a human actually acted on. A reviewer that files
/// 200 findings nobody ever resolves is not doing well, and only this ratio
/// makes that visible.
class ReviewRunStats {
  /// Creates a [ReviewRunStats].
  const ReviewRunStats({
    this.findingsTotal = 0,
    this.resolved = 0,
    this.dismissed = 0,
    this.stillOpen = 0,
    this.newCount = 0,
  });

  /// Findings the pass carried, in any status.
  final int findingsTotal;

  /// Findings marked resolved.
  final int resolved;

  /// Findings dismissed as not worth acting on.
  final int dismissed;

  /// Findings still outstanding when the pass finalized.
  final int stillOpen;

  /// Findings this pass reported that the previous pass did not.
  final int newCount;

  /// Findings a human acted on either way.
  int get addressed => resolved + dismissed;

  /// The share of findings a human actually FIXED.
  ///
  /// This is the number that says whether the review is worth running, and it
  /// is deliberately not [addressed]: a dismissal is a rejection, and counting
  /// it as engagement is how a reviewer congratulates itself for being
  /// ignored. Reporting volume rises with noise; this does not.
  ///
  /// Zero findings reads as zero rather than one — a review with nothing to
  /// act on should not inflate the average either way.
  double get actionRate => findingsTotal == 0 ? 0 : resolved / findingsTotal;

  /// The share of findings a human explicitly rejected.
  ///
  /// The noise signal, and the one to watch when tuning: a rising dismissal
  /// rate means the review is reporting things this team does not want, which
  /// is what the suppression loop and the level floors exist to correct.
  double get dismissalRate =>
      findingsTotal == 0 ? 0 : dismissed / findingsTotal;

  /// Builds from a stored map, tolerating absence.
  factory ReviewRunStats.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const ReviewRunStats();
    }
    return ReviewRunStats(
      findingsTotal: (json['findingsTotal'] as num?)?.toInt() ?? 0,
      resolved: (json['resolved'] as num?)?.toInt() ?? 0,
      dismissed: (json['dismissed'] as num?)?.toInt() ?? 0,
      stillOpen: (json['stillOpen'] as num?)?.toInt() ?? 0,
      newCount: (json['newCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'findingsTotal': findingsTotal,
    'resolved': resolved,
    'dismissed': dismissed,
    'stillOpen': stillOpen,
    'newCount': newCount,
  };

  /// Sums two stat blocks (used to aggregate a workspace's passes).
  ReviewRunStats operator +(ReviewRunStats other) => ReviewRunStats(
    findingsTotal: findingsTotal + other.findingsTotal,
    resolved: resolved + other.resolved,
    dismissed: dismissed + other.dismissed,
    stillOpen: stillOpen + other.stillOpen,
    newCount: newCount + other.newCount,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewRunStats &&
          runtimeType == other.runtimeType &&
          findingsTotal == other.findingsTotal &&
          resolved == other.resolved &&
          dismissed == other.dismissed &&
          stillOpen == other.stillOpen &&
          newCount == other.newCount;

  @override
  int get hashCode =>
      Object.hash(findingsTotal, resolved, dismissed, stillOpen, newCount);
}

/// A finalized review pass.
class ReviewRunSnapshot {
  /// Creates a [ReviewRunSnapshot].
  const ReviewRunSnapshot({
    required this.id,
    required this.workspaceId,
    required this.prExternalId,
    required this.spaceId,
    required this.finalizedAt,
    this.headSha,
    this.verdict,
    this.fingerprints = const [],
    this.stats = const ReviewRunStats(),
  });

  /// Row id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// The PR this pass reviewed.
  final String prExternalId;

  /// The review space the pass ran in.
  final String spaceId;

  /// When the pass finalized.
  final DateTime finalizedAt;

  /// The head SHA reviewed, when known.
  final String? headSha;

  /// The verdict the pass reached.
  final ReviewVerdict? verdict;

  /// Fingerprints of every finding the pass carried.
  final List<FindingFingerprint> fingerprints;

  /// The pass's counts.
  final ReviewRunStats stats;

  /// Fingerprints the pass left outstanding — the input to the next delta.
  List<FindingFingerprint> get openFingerprints => [
    for (final f in fingerprints)
      if (f.isOpen) f,
  ];

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewRunSnapshot &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          prExternalId == other.prExternalId &&
          spaceId == other.spaceId &&
          finalizedAt == other.finalizedAt &&
          headSha == other.headSha;

  @override
  int get hashCode =>
      Object.hash(id, workspaceId, prExternalId, spaceId, finalizedAt, headSha);
}
