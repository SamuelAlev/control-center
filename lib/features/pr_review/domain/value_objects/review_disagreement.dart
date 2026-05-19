import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/features/pr_review/domain/value_objects/review_node_payload.dart';

/// A detected disagreement between two reviewer agents on the same finding.
///
/// Surfaced at the top of the review panel to prompt synthesis discussion.
class ReviewDisagreement {
  /// Creates a [ReviewDisagreement].
  const ReviewDisagreement({
    required this.nodeA,
    required this.nodeB,
    required this.description,
  });

  /// First finding (the one with higher perceived severity).
  final ChannelMessage nodeA;

  /// Second finding (conflicting assessment).
  final ChannelMessage nodeB;

  /// Short human-readable summary of the disagreement.
  final String description;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewDisagreement &&
          runtimeType == other.runtimeType &&
          nodeA == other.nodeA &&
          nodeB == other.nodeB &&
          description == other.description;

  @override
  int get hashCode => Object.hash(nodeA, nodeB, description);

  /// The file:line anchor shared by both nodes (from [nodeA]).
  String get anchor {
    final payload = ReviewNodePayload.fromMetadata(nodeA.metadata);
    final a = payload?.anchor;
    if (a == null || a.filePath == null) {
      return 'general finding';
    }
    return a.lineNumber != null ? '${a.filePath}:${a.lineNumber}' : a.filePath!;
  }
}

/// Detects disagreements in a list of review-node messages.
///
/// Two nodes disagree when they reference the same file+line but their
/// priorities differ by ≥ 2 levels or one is a `bug` while the other is a
/// `suggestion`.
List<ReviewDisagreement> detectDisagreements(List<ChannelMessage> messages) {
  final nodes = messages
      .where((m) => m.messageType == ChannelMessageType.reviewNode)
      .toList();

  final disagreements = <ReviewDisagreement>[];

  for (var i = 0; i < nodes.length; i++) {
    final a = nodes[i];
    final payloadA = ReviewNodePayload.fromMetadata(a.metadata);
    if (payloadA == null || !payloadA.anchor.hasAnchor) {
      continue;
    }

    for (var j = i + 1; j < nodes.length; j++) {
      final b = nodes[j];
      if (b.senderId == a.senderId) {
        continue; // same agent — not a disagreement
      }

      final payloadB = ReviewNodePayload.fromMetadata(b.metadata);
      if (payloadB == null) {
        continue;
      }

      if (!_sameAnchor(payloadA.anchor, payloadB.anchor)) {
        continue;
      }

      final desc = _disagreementDescription(payloadA, payloadB);
      if (desc == null) {
        continue;
      }

      disagreements.add(
        ReviewDisagreement(nodeA: a, nodeB: b, description: desc),
      );
    }
  }

  return disagreements;
}

bool _sameAnchor(ReviewNodeAnchor a, ReviewNodeAnchor b) {
  if (a.filePath == null || b.filePath == null) {
    return false;
  }
  if (a.filePath != b.filePath) {
    return false;
  }
  if (a.lineNumber == null && b.lineNumber == null) {
    return true;
  }
  final aStart = a.lineNumber ?? 0;
  final aEnd = a.lineEnd ?? aStart;
  final bStart = b.lineNumber ?? 0;
  final bEnd = b.lineEnd ?? bStart;
  return aStart <= bEnd && bStart <= aEnd;
}

String? _disagreementDescription(ReviewNodePayload a, ReviewNodePayload b) {
  final priorityGap = (a.priority.index - b.priority.index).abs();
  final kindConflict =
      a.kind == ReviewNodeKind.bug && b.kind == ReviewNodeKind.suggestion;

  if (priorityGap >= 2) {
    final higher = a.priority.index < b.priority.index ? a : b;
    final lower = a.priority.index > b.priority.index ? a : b;
    return '${_priorityLabel(higher.priority)} vs '
        '${_priorityLabel(lower.priority)} — '
        'reviewers disagree on severity';
  }

  if (kindConflict) {
    return 'Bug vs suggestion — reviewers disagree on whether this is blocking';
  }

  return null;
}

String _priorityLabel(ReviewNodePriority p) => switch (p) {
  ReviewNodePriority.p0 => 'P0 (block)',
  ReviewNodePriority.p1 => 'P1 (hold)',
  ReviewNodePriority.p2 => 'P2',
  ReviewNodePriority.p3 => 'P3',
};
