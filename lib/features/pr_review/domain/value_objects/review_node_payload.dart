// Typed view over a `reviewNode` channel-message metadata payload (kind, priority, confidence, anchor).
//
// Also provides lifecycle enums and anchor support.

import 'package:collection/collection.dart';

/// Kind of a review node finding.
enum ReviewNodeKind {
  /// A defect, regression, or correctness issue.
  bug,
  /// A non-blocking improvement idea.
  suggestion,
  /// A high-level recommendation or architectural note.
  recommendation,
  /// An open question for the author or another reviewer.
  question,
  /// A ticket-card spawned from this review.
  ticket,
}

/// Action-ordering priority of a review finding.
///
/// Replaces the prior `low|medium|high` severity vocabulary. Priority drives
/// what the human reads first and feeds the per-PR `ReviewVerdict` (ship /
/// hold / block).
enum ReviewNodePriority {
  /// Blocks release. Verdict goes to `block` when confidence is high enough.
  p0,
  /// Fix next cycle.
  p1,
  /// Fix eventually.
  p2,
  /// Nice-to-have.
  p3,
}

/// Lifecycle status of a review node.
enum ReviewNodeStatus {
  /// Newly posted, no peer confirmation yet.
  open,
  /// At least one peer (not the author) has confirmed.
  consensusReady,
  /// Author or CEO marked the finding resolved.
  resolved,
  /// CEO or author dismissed the finding.
  dismissed,
}

/// Source anchor for a review node (file + optional line range).
class ReviewNodeAnchor {
  /// Creates a [ReviewNodeAnchor].
  const ReviewNodeAnchor({this.filePath, this.lineNumber, this.lineEnd});

  /// File path the finding refers to. Null when the finding is repository-wide.
  final String? filePath;
  /// Starting line (inclusive).
  final int? lineNumber;
  /// Ending line (inclusive).
  final int? lineEnd;

  /// Whether any anchor field is set.
  bool get hasAnchor => filePath != null || lineNumber != null;

  /// Builds an anchor from a flat metadata map.
  static ReviewNodeAnchor fromMetadata(Map<String, dynamic> meta) {
    return ReviewNodeAnchor(
      filePath: meta['filePath'] is String ? meta['filePath'] as String : null,
      lineNumber: meta['lineNumber'] is int ? meta['lineNumber'] as int : null,
      lineEnd: meta['lineEnd'] is int ? meta['lineEnd'] as int : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewNodeAnchor &&
          runtimeType == other.runtimeType &&
          filePath == other.filePath &&
          lineNumber == other.lineNumber &&
          lineEnd == other.lineEnd;

  @override
  int get hashCode => Object.hash(filePath, lineNumber, lineEnd);
}

/// Typed view over a `reviewNode` channel-message metadata payload.
///
/// `priority` and `confidence` are required at the read boundary —
/// [fromMetadata] returns `null` when either is missing or out of range, so
/// malformed payloads disappear from the UI and the verdict computation
/// instead of polluting them.
class ReviewNodePayload {
  /// Creates a [ReviewNodePayload].
  const ReviewNodePayload({
    required this.kind,
    required this.priority,
    required this.confidence,
    required this.anchor,
    required this.status,
    this.confirmedBy = const [],
    this.linkedTicketIds = const [],
  });

  /// Finding kind.
  final ReviewNodeKind kind;
  /// Action-ordering priority (P0..P3).
  final ReviewNodePriority priority;
  /// Reviewer self-assessed confidence, clamped to `[0.0, 1.0]`.
  final double confidence;
  /// Source anchor.
  final ReviewNodeAnchor anchor;
  /// Lifecycle status.
  final ReviewNodeStatus status;
  /// Agent ids that have confirmed this finding (must exclude the author).
  final List<String> confirmedBy;
  /// Ticket ids spawned from this finding.
  final List<String> linkedTicketIds;

  /// Whether this finding has at least one peer confirmation.
  /// Author is presumed already excluded from [confirmedBy] by the writer.
  bool get hasPeerConfirmation => confirmedBy.isNotEmpty;

  /// Parses a payload from a metadata map. Returns null on missing kind,
  /// missing/invalid priority, or out-of-range confidence.
  static ReviewNodePayload? fromMetadata(Map<String, dynamic>? meta) {
    if (meta == null) {
      return null;
    }
    final kindRaw = meta['nodeType'] as String?;
    if (kindRaw == null) {
      return null;
    }
    final priority = _parsePriority(meta['priority']);
    if (priority == null) {
      return null;
    }
    final confidence = _parseConfidence(meta['confidence']);
    if (confidence == null) {
      return null;
    }
    return ReviewNodePayload(
      kind: _parseKind(kindRaw),
      priority: priority,
      confidence: confidence,
      anchor: ReviewNodeAnchor.fromMetadata(meta),
      status: _parseStatus(meta['status'] as String?),
      confirmedBy: (meta['confirmedBy'] as List?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const [],
      linkedTicketIds: (meta['linkedTicketIds'] as List?)
              ?.whereType<String>()
              .toList(growable: false) ??
          const [],
    );
  }

  /// Serializes this payload back to a flat metadata map.
  Map<String, dynamic> toMetadata() {
    return {
      'nodeType': _kindToString(kind),
      'priority': _priorityToString(priority),
      'confidence': confidence,
      'status': _statusToString(status),
      'confirmedBy': confirmedBy,
      'linkedTicketIds': linkedTicketIds,
      if (anchor.filePath != null) 'filePath': anchor.filePath,
      if (anchor.lineNumber != null) 'lineNumber': anchor.lineNumber,
      if (anchor.lineEnd != null) 'lineEnd': anchor.lineEnd,
    };
  }

  /// Returns a copy with overrides.
  ReviewNodePayload copyWith({
    ReviewNodeKind? kind,
    ReviewNodePriority? priority,
    double? confidence,
    ReviewNodeAnchor? anchor,
    ReviewNodeStatus? status,
    List<String>? confirmedBy,
    List<String>? linkedTicketIds,
  }) {
    return ReviewNodePayload(
      kind: kind ?? this.kind,
      priority: priority ?? this.priority,
      confidence: confidence ?? this.confidence,
      anchor: anchor ?? this.anchor,
      status: status ?? this.status,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      linkedTicketIds: linkedTicketIds ?? this.linkedTicketIds,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewNodePayload &&
          runtimeType == other.runtimeType &&
          kind == other.kind &&
          priority == other.priority &&
          confidence == other.confidence &&
          anchor == other.anchor &&
          status == other.status &&
          const ListEquality<String>().equals(confirmedBy, other.confirmedBy) &&
          const ListEquality<String>().equals(linkedTicketIds, other.linkedTicketIds);

  @override
  int get hashCode => Object.hash(
        kind,
        priority,
        confidence,
        anchor,
        status,
        Object.hashAll(confirmedBy),
        Object.hashAll(linkedTicketIds),
      );

  static ReviewNodeKind _parseKind(String raw) {
    switch (raw) {
      case 'bug':
        return ReviewNodeKind.bug;
      case 'suggestion':
        return ReviewNodeKind.suggestion;
      case 'recommendation':
        return ReviewNodeKind.recommendation;
      case 'question':
        return ReviewNodeKind.question;
      case 'ticket':
        return ReviewNodeKind.ticket;
      default:
        return ReviewNodeKind.suggestion;
    }
  }

  static String _kindToString(ReviewNodeKind k) {
    switch (k) {
      case ReviewNodeKind.bug:
        return 'bug';
      case ReviewNodeKind.suggestion:
        return 'suggestion';
      case ReviewNodeKind.recommendation:
        return 'recommendation';
      case ReviewNodeKind.question:
        return 'question';
      case ReviewNodeKind.ticket:
        return 'ticket';
    }
  }

  static ReviewNodePriority? _parsePriority(Object? raw) {
    if (raw is! String) {
      return null;
    }
    switch (raw) {
      case 'p0':
        return ReviewNodePriority.p0;
      case 'p1':
        return ReviewNodePriority.p1;
      case 'p2':
        return ReviewNodePriority.p2;
      case 'p3':
        return ReviewNodePriority.p3;
      default:
        return null;
    }
  }

  static String _priorityToString(ReviewNodePriority p) {
    switch (p) {
      case ReviewNodePriority.p0:
        return 'p0';
      case ReviewNodePriority.p1:
        return 'p1';
      case ReviewNodePriority.p2:
        return 'p2';
      case ReviewNodePriority.p3:
        return 'p3';
    }
  }

  static double? _parseConfidence(Object? raw) {
    if (raw is! num) {
      return null;
    }
    final value = raw.toDouble();
    if (value.isNaN || value < 0.0 || value > 1.0) {
      return null;
    }
    return value;
  }

  static ReviewNodeStatus _parseStatus(String? raw) {
    switch (raw) {
      case 'consensus_ready':
        return ReviewNodeStatus.consensusReady;
      case 'resolved':
        return ReviewNodeStatus.resolved;
      case 'dismissed':
        return ReviewNodeStatus.dismissed;
      default:
        return ReviewNodeStatus.open;
    }
  }

  static String _statusToString(ReviewNodeStatus s) {
    switch (s) {
      case ReviewNodeStatus.open:
        return 'open';
      case ReviewNodeStatus.consensusReady:
        return 'consensus_ready';
      case ReviewNodeStatus.resolved:
        return 'resolved';
      case ReviewNodeStatus.dismissed:
        return 'dismissed';
    }
  }
}
