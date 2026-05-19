// Typed view over a `reviewNode` channel-message metadata payload (kind, priority, confidence, anchor).
//
// Also provides lifecycle enums and anchor support.

import 'package:cc_domain/features/pr_review/domain/value_objects/review_axis.dart';
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
  ticket;

  /// The stable wire/storage name.
  String get wireName => name;

  /// Parses a wire name, or null when unrecognized.
  static ReviewNodeKind? fromName(String? name) {
    if (name == null) {
      return null;
    }
    for (final k in ReviewNodeKind.values) {
      if (k.wireName == name) {
        return k;
      }
    }
    return null;
  }
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
  p3;

  /// The stable wire/storage name.
  String get wireName => name;

  /// Parses a wire name (case-insensitive), or null when unrecognized.
  static ReviewNodePriority? fromName(String? name) {
    if (name == null) {
      return null;
    }
    final lower = name.toLowerCase();
    for (final p in ReviewNodePriority.values) {
      if (p.wireName == lower) {
        return p;
      }
    }
    return null;
  }
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
  dismissed;

  /// The stable wire/storage name. `consensusReady` stores as
  /// `consensus_ready`, which predates the enum and is what is on disk.
  String get wireName =>
      this == ReviewNodeStatus.consensusReady ? 'consensus_ready' : name;

  /// Parses a wire name, or null when unrecognized.
  static ReviewNodeStatus? fromName(String? name) {
    if (name == null) {
      return null;
    }
    for (final s in ReviewNodeStatus.values) {
      if (s.wireName == name) {
        return s;
      }
    }
    return null;
  }
}

/// What produced a review finding.
enum ReviewFindingProvenance {
  /// A reviewer agent's judgement.
  agent,

  /// A deterministic static rule over the diff — reproducible, no tokens, and
  /// no interpretation.
  staticRule;

  /// The stable wire/storage name.
  String get wireName =>
      this == ReviewFindingProvenance.staticRule ? 'static' : 'agent';

  /// Parses a wire name, or null when unrecognized.
  static ReviewFindingProvenance? fromName(String? name) {
    if (name == null) {
      return null;
    }
    for (final p in ReviewFindingProvenance.values) {
      if (p.wireName == name) {
        return p;
      }
    }
    return null;
  }
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
    this.cohortKey,
    this.axis,
    this.provenance = ReviewFindingProvenance.agent,
    this.ruleId,
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

  /// Stable semantic-cohort key this finding routes to (PRD 18 §1). Null for
  /// findings recorded before cohorts were computed or repository-wide notes.
  final String? cohortKey;

  /// The review axis that produced this finding (PRD 18 §7). Null for findings
  /// from the legacy single-axis review path.
  final ReviewAxis? axis;

  /// Who produced this finding — a reviewer agent or a deterministic rule.
  ///
  /// The distinction is load-bearing rather than cosmetic: a regex hit and a
  /// model's judgement carry different kinds of certainty, and a reader who
  /// cannot tell them apart will either over-trust the model or dismiss the
  /// rule. Absent metadata reads as [ReviewFindingProvenance.agent], which is
  /// what every finding written before deterministic scanning was.
  final ReviewFindingProvenance provenance;

  /// The static rule that produced this finding, when [provenance] is
  /// [ReviewFindingProvenance.staticRule]. Null otherwise.
  final String? ruleId;

  /// Whether this finding came from a deterministic rule rather than an agent.
  bool get isDeterministic => provenance == ReviewFindingProvenance.staticRule;

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
    // Drop malformed nodes by returning null (the caller treats null as "skip").
    // No logging here: this is a pure domain value object, so the diagnostic is
    // the caller's responsibility.
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
      confirmedBy:
          (meta['confirmedBy'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      linkedTicketIds:
          (meta['linkedTicketIds'] as List?)?.whereType<String>().toList(
            growable: false,
          ) ??
          const [],
      cohortKey: meta['cohortKey'] is String
          ? meta['cohortKey'] as String
          : null,
      axis: ReviewAxis.fromName(meta['axis'] as String?),
      provenance:
          ReviewFindingProvenance.fromName(meta['provenance'] as String?) ??
          ReviewFindingProvenance.agent,
      ruleId: meta['ruleId'] is String ? meta['ruleId'] as String : null,
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
      if (cohortKey != null) 'cohortKey': cohortKey,
      if (axis != null) 'axis': axis!.wireName,
      // Only stamped for deterministic findings: the default is `agent`, and
      // writing it on every payload would churn every existing row's metadata
      // for no new information.
      if (provenance != ReviewFindingProvenance.agent)
        'provenance': provenance.wireName,
      if (ruleId != null) 'ruleId': ruleId,
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
    String? cohortKey,
    bool clearCohortKey = false,
    ReviewAxis? axis,
    bool clearAxis = false,
    ReviewFindingProvenance? provenance,
    String? ruleId,
  }) {
    return ReviewNodePayload(
      kind: kind ?? this.kind,
      priority: priority ?? this.priority,
      confidence: confidence ?? this.confidence,
      anchor: anchor ?? this.anchor,
      status: status ?? this.status,
      confirmedBy: confirmedBy ?? this.confirmedBy,
      linkedTicketIds: linkedTicketIds ?? this.linkedTicketIds,
      cohortKey: clearCohortKey ? null : (cohortKey ?? this.cohortKey),
      axis: clearAxis ? null : (axis ?? this.axis),
      provenance: provenance ?? this.provenance,
      ruleId: ruleId ?? this.ruleId,
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
          const ListEquality<String>().equals(
            linkedTicketIds,
            other.linkedTicketIds,
          ) &&
          cohortKey == other.cohortKey &&
          axis == other.axis &&
          provenance == other.provenance &&
          ruleId == other.ruleId;

  @override
  int get hashCode => Object.hash(
    kind,
    priority,
    confidence,
    anchor,
    status,
    Object.hashAll(confirmedBy),
    Object.hashAll(linkedTicketIds),
    cohortKey,
    axis,
    provenance,
    ruleId,
  );

  // An unrecognized kind reads as `suggestion` — the least alarming of the
  // five, so a payload from a newer writer degrades quietly rather than
  // masquerading as a bug.
  static ReviewNodeKind _parseKind(String raw) =>
      ReviewNodeKind.fromName(raw) ?? ReviewNodeKind.suggestion;

  static String _kindToString(ReviewNodeKind k) => k.wireName;

  static ReviewNodePriority? _parsePriority(Object? raw) =>
      raw is! String ? null : ReviewNodePriority.fromName(raw);

  static String _priorityToString(ReviewNodePriority p) => p.wireName;

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

  // An unrecognized status reads as `open`: a finding whose lifecycle we
  // cannot interpret is still outstanding, never silently settled.
  static ReviewNodeStatus _parseStatus(String? raw) =>
      ReviewNodeStatus.fromName(raw) ?? ReviewNodeStatus.open;

  static String _statusToString(ReviewNodeStatus s) => s.wireName;
}
