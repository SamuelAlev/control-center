import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_domain/features/pr_review/domain/usecases/evaluate_pr_merge_readiness.dart';

/// The slice of one open-PR snapshot entry that decides whether anything is
/// worth notifying about.
///
/// Built from the poller's wire map ([PrNotifiableState.fromWire]) rather than
/// from a [PullRequest], because the poller diffs wire maps: the previous sweep
/// is only ever available as the JSON it persisted, and reconstructing an
/// entity from it just to throw it away would invite the two sides to disagree.
///
/// Every field here is one the open-PR snapshot already writes, which is what
/// makes transition detection need **no** new persisted state: the snapshot is
/// the memory, and it survives restarts because it lives in the `caches` table.
class PrNotifiableState {
  /// Creates a [PrNotifiableState].
  const PrNotifiableState({
    required this.isDraft,
    required this.state,
    required this.authorLogin,
    required this.checksStatus,
    required this.reviewDecision,
    required this.mergeableState,
    required this.requestedReviewerLogins,
    required this.requestedTeamSlugs,
    required this.headSha,
  });

  /// Reads the slice out of one `pullRequestToWire` map.
  ///
  /// Tolerant of every field being absent: a snapshot written by an older
  /// server is a legitimate `before`, and the safe reading of a missing field
  /// is the neutral one (no checks, no decision, uncomputed mergeability), all
  /// of which suppress rather than invent a transition.
  factory PrNotifiableState.fromWire(Map<String, dynamic> wire) {
    final author = wire['author'];
    return PrNotifiableState(
      isDraft: wire['is_draft'] == true,
      state: wire['state'] as String? ?? 'open',
      authorLogin: author is Map
          ? (author['login'] as String? ?? '')
          : '',
      checksStatus: _checksFromName(wire['checks_status'] as String?),
      reviewDecision: PrReviewDecision.fromString(
        wire['review_decision'] as String?,
      ),
      mergeableState: PrMergeableState.fromString(
        wire['mergeable_state'] as String?,
      ),
      requestedReviewerLogins: [
        for (final r in (wire['requested_reviewers'] as List?) ?? const [])
          if (r is Map && r['login'] is String) r['login'] as String,
      ],
      requestedTeamSlugs: [
        for (final s in (wire['requested_team_slugs'] as List?) ?? const [])
          if (s is String) s,
      ],
      headSha: wire['head_sha'] as String? ?? '',
    );
  }

  static PrChecksStatus _checksFromName(String? name) => switch (name) {
    'pending' => PrChecksStatus.pending,
    'passing' => PrChecksStatus.passing,
    'failing' => PrChecksStatus.failing,
    _ => PrChecksStatus.none,
  };

  /// Whether the pull request is a draft.
  final bool isDraft;

  /// Lifecycle state (`open`, `closed`, `merged`).
  final String state;

  /// The author's forge login, lowercased comparisons aside.
  final String authorLogin;

  /// Rolled-up check status.
  final PrChecksStatus checksStatus;

  /// The forge's rolled-up review decision.
  final PrReviewDecision reviewDecision;

  /// The forge's mergeable verdict, usually uncomputed on the list path.
  final PrMergeableState mergeableState;

  /// Reviewers still requested (the forge drops one the moment they submit).
  final List<String> requestedReviewerLogins;

  /// Teams still requested.
  final List<String> requestedTeamSlugs;

  /// Head commit sha. Empty on a snapshot written before it was fetched.
  final String headSha;

  /// Whether the pull request is still open.
  bool get isOpen => state == 'open';

  /// Merge readiness derived from this snapshot alone.
  ({PrMergeReadiness readiness, PrBlockReason reason}) get readiness =>
      evaluatePrMergeReadiness(
        isDraft: isDraft,
        mergeableState: mergeableState,
        reviewDecision: reviewDecision,
        checksStatus: checksStatus,
        requestedReviewerLogins: requestedReviewerLogins,
        requestedTeamSlugs: requestedTeamSlugs,
      );

  /// Reviewers and teams still to respond.
  int get reviewersRemaining =>
      requestedReviewerLogins.length + requestedTeamSlugs.length;
}

/// Something happened to a pull request that is worth telling its author about.
sealed class PrTransition {
  /// Creates a [PrTransition].
  const PrTransition();
}

/// The pull request became mergeable.
final class PrBecameReadyToMerge extends PrTransition {
  /// Creates a [PrBecameReadyToMerge].
  const PrBecameReadyToMerge();
}

/// The pull request stopped being mergeable.
final class PrBecameBlocked extends PrTransition {
  /// Creates a [PrBecameBlocked].
  const PrBecameBlocked(this.reason);

  /// Why it is blocked.
  final PrBlockReason reason;
}

/// The pull request was approved.
final class PrWasApproved extends PrTransition {
  /// Creates a [PrWasApproved].
  const PrWasApproved({required this.reviewersRemaining, this.approverLogin});

  /// Reviewers and teams still to respond after this approval.
  final int reviewersRemaining;

  /// Who approved, when it could be determined from the requested-reviewer
  /// diff alone. Null is normal and never blocks the notification — the caller
  /// may fill it in from a targeted fetch, or render an unattributed string.
  final String? approverLogin;
}

/// A reviewer requested changes.
final class PrChangesRequested extends PrTransition {
  /// Creates a [PrChangesRequested].
  const PrChangesRequested();
}

/// An approval was dismissed and the pull request needs review again.
final class PrReviewDismissed extends PrTransition {
  /// Creates a [PrReviewDismissed].
  const PrReviewDismissed();
}

/// CI went red.
final class PrChecksFailed extends PrTransition {
  /// Creates a [PrChecksFailed].
  const PrChecksFailed();
}

/// CI went green again after being red.
final class PrChecksRecovered extends PrTransition {
  /// Creates a [PrChecksRecovered].
  const PrChecksRecovered();
}

/// The transitions between two consecutive snapshots of one pull request.
///
/// [before] null is the baseline sweep and yields nothing: a server that has
/// never seen a repo must not announce its entire backlog on first contact.
///
/// Each edge fires exactly once because the persisted snapshot IS the dedupe —
/// after publishing, the caller writes [after] and the same comparison the next
/// sweep sees no edge. Nothing else needs storing.
List<PrTransition> detectPrNotifiableTransitions({
  required PrNotifiableState? before,
  required PrNotifiableState after,
}) {
  if (before == null || !after.isOpen) {
    return const [];
  }

  final transitions = <PrTransition>[];

  // Checks. `failing -> pending` is deliberately NOT recovery: a re-run
  // starting tells the author nothing they can act on, and announcing it would
  // make the eventual real recovery the second notification about one fix.
  if (before.checksStatus != PrChecksStatus.failing &&
      after.checksStatus == PrChecksStatus.failing) {
    transitions.add(const PrChecksFailed());
  } else if (before.checksStatus == PrChecksStatus.failing &&
      after.checksStatus == PrChecksStatus.passing) {
    transitions.add(const PrChecksRecovered());
  }

  // Review decision.
  final beforeDecision = before.reviewDecision;
  final afterDecision = after.reviewDecision;
  if (beforeDecision != afterDecision) {
    switch (afterDecision) {
      case PrReviewDecision.approved:
        transitions.add(
          PrWasApproved(
            reviewersRemaining: after.reviewersRemaining,
            approverLogin: _approverFromDiff(before, after),
          ),
        );
      case PrReviewDecision.changesRequested:
        transitions.add(const PrChangesRequested());
      case PrReviewDecision.reviewRequired:
        // The forge falls back to REVIEW_REQUIRED when an approval is
        // dismissed, so this edge is only meaningful coming FROM approved.
        if (beforeDecision == PrReviewDecision.approved) {
          transitions.add(const PrReviewDismissed());
        }
      case PrReviewDecision.none:
        break;
    }
  }

  // Merge readiness.
  final beforeReadiness = before.readiness.readiness;
  final afterReadiness = after.readiness;
  if (beforeReadiness != PrMergeReadiness.ready &&
      afterReadiness.readiness == PrMergeReadiness.ready) {
    transitions.add(const PrBecameReadyToMerge());
  } else if (beforeReadiness != PrMergeReadiness.blocked &&
      afterReadiness.readiness == PrMergeReadiness.blocked) {
    transitions.add(PrBecameBlocked(afterReadiness.reason));
  }

  return transitions;
}

/// The single reviewer who left the requested set on the sweep that approved.
///
/// The forge removes a reviewer from `reviewRequests` the instant they submit,
/// so on the full sweep this names the approver for free. Null when the set did
/// not shrink (an approval by someone never formally requested — very common)
/// or shrank by more than one (two reviews inside one tick), because guessing
/// between two logins is worse than not naming one.
String? _approverFromDiff(PrNotifiableState before, PrNotifiableState after) {
  final gone = before.requestedReviewerLogins
      .where(
        (l) => !after.requestedReviewerLogins.any(
          (r) => r.toLowerCase() == l.toLowerCase(),
        ),
      )
      .toList();
  return gone.length == 1 ? gone.first : null;
}
