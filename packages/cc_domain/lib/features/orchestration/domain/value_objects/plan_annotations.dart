/// Plan-node annotations carried inside the proposal JSON (PRD 17).
///
/// Both live on `ProposedSubTicket` (and on plan-mode `PlanNode`s): an
/// honest, range-shaped estimate and the provenance refs that make a plan
/// auditable. Neither adds a database column — they travel with the proposal.
library;

// Named JSON factories read best next to the fields they map.
// ignore_for_file: sort_constructors_first

/// A per-node estimate: cost/duration ranges derived from history plus a
/// provenance-derived blast radius (PRD 17 §3).
///
/// **Honest or absent** is the invariant: every numeric field is nullable,
/// [sampleSize] says how much history backs the range (0 = "no history yet",
/// render exactly that — never a fabricated point value) and blast radius is
/// only present when provenance refs allowed a real impact query.
class PlanNodeEstimate {
  /// Creates an estimate.
  const PlanNodeEstimate({
    this.costCentsLow,
    this.costCentsHigh,
    this.durationMsLow,
    this.durationMsHigh,
    this.sampleSize = 0,
    this.blastRadiusFiles,
    this.blastRadiusSymbols,
  });

  /// Lower bound of predicted cost (US cents), from similar-run history.
  final int? costCentsLow;

  /// Upper bound of predicted cost (US cents).
  final int? costCentsHigh;

  /// Lower bound of predicted duration (milliseconds).
  final int? durationMsLow;

  /// Upper bound of predicted duration (milliseconds).
  final int? durationMsHigh;

  /// How many similar runs back the ranges. 0 means no history: the UI says
  /// "no history yet" and the numeric fields stay null.
  final int sampleSize;

  /// Files inside the node's impact radius (provenance-derived; null =
  /// unknown, because the node has no provenance refs).
  final int? blastRadiusFiles;

  /// Symbols inside the node's impact radius.
  final int? blastRadiusSymbols;

  /// Whether any cost/duration range exists (false = "no history yet").
  bool get hasHistory => sampleSize > 0;

  /// Builds from JSON.
  factory PlanNodeEstimate.fromJson(Map<String, dynamic> json) =>
      PlanNodeEstimate(
        costCentsLow: (json['costCentsLow'] as num?)?.toInt(),
        costCentsHigh: (json['costCentsHigh'] as num?)?.toInt(),
        durationMsLow: (json['durationMsLow'] as num?)?.toInt(),
        durationMsHigh: (json['durationMsHigh'] as num?)?.toInt(),
        sampleSize: (json['sampleSize'] as num?)?.toInt() ?? 0,
        blastRadiusFiles: (json['blastRadiusFiles'] as num?)?.toInt(),
        blastRadiusSymbols: (json['blastRadiusSymbols'] as num?)?.toInt(),
      );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    if (costCentsLow != null) 'costCentsLow': costCentsLow,
    if (costCentsHigh != null) 'costCentsHigh': costCentsHigh,
    if (durationMsLow != null) 'durationMsLow': durationMsLow,
    if (durationMsHigh != null) 'durationMsHigh': durationMsHigh,
    'sampleSize': sampleSize,
    if (blastRadiusFiles != null) 'blastRadiusFiles': blastRadiusFiles,
    if (blastRadiusSymbols != null) 'blastRadiusSymbols': blastRadiusSymbols,
  };
}

/// One provenance reference: why a plan node exists (PRD 17 §7).
class PlanProvenanceRef {
  /// Creates a ref.
  const PlanProvenanceRef({required this.kind, required this.ref, this.label});

  /// Kind of evidence: `symbol` (code-graph symbol id), `file` (repo-relative
  /// path), `memory` (memory fact id), `message` (space message id),
  /// `goal` (originating goal/ticket id), or `answer` (a clarifying-question
  /// answer message id).
  final String kind;

  /// The id/path the [kind] names.
  final String ref;

  /// Optional display label (symbol name, file basename, fact summary).
  final String? label;

  /// Builds from JSON.
  factory PlanProvenanceRef.fromJson(Map<String, dynamic> json) =>
      PlanProvenanceRef(
        kind: json['kind'] as String? ?? '',
        ref: json['ref'] as String? ?? '',
        label: json['label'] as String?,
      );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'kind': kind,
    'ref': ref,
    if (label != null) 'label': label,
  };

  @override
  bool operator ==(Object other) =>
      other is PlanProvenanceRef &&
      other.kind == kind &&
      other.ref == ref &&
      other.label == label;

  @override
  int get hashCode => Object.hash(kind, ref, label);
}
