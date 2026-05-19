// The contract for moving a review finding between statuses.
//
// A port rather than a direct call because two very different callers need the
// same behaviour: the MCP tool an agent reaches for, and the RPC op behind a
// button a person presses. Both must leave identical state — the status
// written through the typed payload, a trace in the room, and a suppression
// fact on a dismissal — or "dismissed by an agent" and "dismissed by me" mean
// subtly different things and the review's own history stops being readable.

import 'package:cc_domain/features/pr_review/domain/value_objects/review_node_payload.dart';

/// The outcome of a status change.
class ReviewFindingStatusChange {
  /// Creates a [ReviewFindingStatusChange].
  const ReviewFindingStatusChange({
    required this.nodeMessageId,
    required this.status,
    required this.previousStatus,
    required this.suppressionRecorded,
  });

  /// The finding that moved.
  final String nodeMessageId;

  /// Where it moved to.
  final ReviewNodeStatus status;

  /// Where it was, so a caller can report a no-op honestly rather than
  /// claiming to have changed something that was already there.
  final ReviewNodeStatus previousStatus;

  /// Whether a suppression fact was written. Dismissals only, and false when
  /// the memory collaborators are not wired.
  final bool suppressionRecorded;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewFindingStatusChange &&
          runtimeType == other.runtimeType &&
          nodeMessageId == other.nodeMessageId &&
          status == other.status &&
          previousStatus == other.previousStatus &&
          suppressionRecorded == other.suppressionRecorded;

  @override
  int get hashCode =>
      Object.hash(nodeMessageId, status, previousStatus, suppressionRecorded);
}

/// Thrown when the named finding is not in the space.
class ReviewFindingNotFound implements Exception {
  /// Creates a [ReviewFindingNotFound].
  const ReviewFindingNotFound(this.nodeMessageId);

  /// The id that did not resolve.
  final String nodeMessageId;

  @override
  String toString() => 'Review finding not found: $nodeMessageId';
}

/// Moves a review finding between [ReviewNodeStatus] values.
abstract class ReviewFindingStatusPort {
  /// Sets [nodeMessageId]'s status to [status].
  ///
  /// [actorLabel] is who did it, as it should read in the room — a person's
  /// display name or an agent id. [reason] is what a dismissal is worth
  /// capturing for: it becomes the suppression fact future reviewers read.
  ///
  /// Throws [ReviewFindingNotFound] when the finding is not in the space.
  Future<ReviewFindingStatusChange> setStatus({
    required String workspaceId,
    required String spaceId,
    required String nodeMessageId,
    required ReviewNodeStatus status,
    required String actorLabel,
    String? reason,
  });
}
