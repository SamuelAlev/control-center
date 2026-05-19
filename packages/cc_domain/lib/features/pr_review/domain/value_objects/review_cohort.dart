// Semantic file grouping for a PR (PRD 18 §1). A cohort is a content-derived,
// push-stable bucket of changed files that belong to the same bounded context
// / feature, with an ordered reading path of range-anchored layers.
//
// ignore_for_file: sort_constructors_first

import 'package:cc_domain/features/pr_review/domain/value_objects/review_diagram.dart';
import 'package:collection/collection.dart';

/// How a cohort's grouping was derived — load-bearing for honest UI labeling
/// (PRD 18 adversarial notes: the path fallback must never fake semantic
/// confidence).
enum CohortDerivation {
  /// Grouped by connected components in the code graph (semantic).
  graph,

  /// Grouped by path heuristics because the repo is not indexed. The UI labels
  /// this "grouped by path (repo not indexed)" and offers one-click indexing.
  path;

  /// The stable wire/storage name.
  String get wireName => name;

  /// Parses a stored/wire name, defaulting to [path] (the honest fallback).
  static CohortDerivation fromName(String? name) => CohortDerivation.values
      .firstWhere((d) => d.name == name, orElse: () => CohortDerivation.path);
}

/// A range-anchored layer within a cohort — one step of the guided reading
/// order, tied to a file and (optionally) a line range so the context rail's
/// summary can follow scroll (PRD 18 §2).
class CohortLayer {
  /// Creates a [CohortLayer].
  const CohortLayer({
    required this.title,
    required this.filePath,
    this.startLine,
    this.endLine,
    this.summaryMarkdown = '',
  });

  /// Short layer title (e.g. "Token refresh", "New endpoint handler").
  final String title;

  /// Repository-relative file this layer anchors to.
  final String filePath;

  /// First line of the anchored range (inclusive), or null for whole-file.
  final int? startLine;

  /// Last line of the anchored range (inclusive), or null for whole-file.
  final int? endLine;

  /// Range-specific summary rendered in the context rail.
  final String summaryMarkdown;

  /// Whether this layer anchors to a specific line range.
  bool get hasRange => startLine != null;

  /// Builds from JSON.
  factory CohortLayer.fromJson(Map<String, dynamic> json) => CohortLayer(
    title: json['title'] as String? ?? '',
    filePath: json['filePath'] as String? ?? '',
    startLine: (json['startLine'] as num?)?.toInt(),
    endLine: (json['endLine'] as num?)?.toInt(),
    summaryMarkdown: json['summaryMarkdown'] as String? ?? '',
  );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'title': title,
    'filePath': filePath,
    if (startLine != null) 'startLine': startLine,
    if (endLine != null) 'endLine': endLine,
    if (summaryMarkdown.isNotEmpty) 'summaryMarkdown': summaryMarkdown,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CohortLayer &&
          runtimeType == other.runtimeType &&
          title == other.title &&
          filePath == other.filePath &&
          startLine == other.startLine &&
          endLine == other.endLine &&
          summaryMarkdown == other.summaryMarkdown;

  @override
  int get hashCode =>
      Object.hash(title, filePath, startLine, endLine, summaryMarkdown);
}

/// A semantic cohort of a PR's changed files (PRD 18 §1).
///
/// The [cohortKey] is content-derived (dominant symbols / feature) and stable
/// across pushes, so summaries, findings, and review progress survive a rebase
/// or force-push instead of orphaning. Computed server-side on PR open and on
/// every head-SHA change; the client never computes cohorts.
class ReviewCohort {
  /// Creates a [ReviewCohort].
  const ReviewCohort({
    required this.id,
    required this.workspaceId,
    required this.prNodeId,
    required this.cohortKey,
    required this.title,
    required this.orderIndex,
    required this.impactScore,
    this.summaryMarkdown = '',
    this.derivation = CohortDerivation.path,
    this.filePaths = const [],
    this.layers = const [],
    this.diagrams = const [],
    this.headSha,
  }) : assert(cohortKey != '', 'cohortKey must not be empty'),
       assert(impactScore >= 0, 'impactScore must be non-negative');

  /// Row id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// The PR (channel node) this cohort belongs to.
  final String prNodeId;

  /// Content-derived, push-stable cohort identity.
  final String cohortKey;

  /// Human-readable cohort name ("Auth flow", "Billing API").
  final String title;

  /// Summary markdown for the whole cohort.
  final String summaryMarkdown;

  /// Reading order among the PR's cohorts (0-based; lower reads first).
  final int orderIndex;

  /// Impact weight used to order cohorts and weight the risk heatmap
  /// (PRD 18 §6). Higher = more transitively affected callers/tests/endpoints.
  final int impactScore;

  /// How this cohort was derived (semantic vs path fallback).
  final CohortDerivation derivation;

  /// Repository-relative changed files in this cohort.
  final List<String> filePaths;

  /// Ordered reading layers.
  final List<CohortLayer> layers;

  /// Generated, graph-verified diagrams for this cohort's walkthrough
  /// (PRD 18 §3) — e.g. a sequence diagram for a new call flow.
  final List<ReviewDiagram> diagrams;

  /// The head SHA this cohort was computed against; changes each push.
  final String? headSha;

  /// Whether this cohort was grouped by path heuristics (unindexed repo).
  bool get isPathDerived => derivation == CohortDerivation.path;

  /// Builds from JSON.
  factory ReviewCohort.fromJson(Map<String, dynamic> json) => ReviewCohort(
    id: json['id'] as String? ?? '',
    workspaceId: json['workspaceId'] as String? ?? '',
    prNodeId: json['prNodeId'] as String? ?? '',
    cohortKey: json['cohortKey'] as String? ?? '',
    title: json['title'] as String? ?? '',
    summaryMarkdown: json['summaryMarkdown'] as String? ?? '',
    orderIndex: (json['orderIndex'] as num?)?.toInt() ?? 0,
    impactScore: (json['impactScore'] as num?)?.toInt() ?? 0,
    derivation: CohortDerivation.fromName(json['derivation'] as String?),
    filePaths:
        (json['filePaths'] as List?)?.whereType<String>().toList() ?? const [],
    layers: (json['layers'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => CohortLayer.fromJson(m.cast<String, dynamic>()))
        .toList(),
    diagrams: (json['diagrams'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => ReviewDiagram.fromJson(m.cast<String, dynamic>()))
        .toList(),
    headSha: json['headSha'] as String?,
  );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'workspaceId': workspaceId,
    'prNodeId': prNodeId,
    'cohortKey': cohortKey,
    'title': title,
    'summaryMarkdown': summaryMarkdown,
    'orderIndex': orderIndex,
    'impactScore': impactScore,
    'derivation': derivation.wireName,
    'filePaths': filePaths,
    'layers': layers.map((l) => l.toJson()).toList(),
    if (diagrams.isNotEmpty)
      'diagrams': diagrams.map((d) => d.toJson()).toList(),
    if (headSha != null) 'headSha': headSha,
  };

  /// Returns an edited copy.
  ReviewCohort copyWith({
    String? title,
    String? summaryMarkdown,
    int? orderIndex,
    int? impactScore,
    CohortDerivation? derivation,
    List<String>? filePaths,
    List<CohortLayer>? layers,
    List<ReviewDiagram>? diagrams,
    String? headSha,
  }) => ReviewCohort(
    id: id,
    workspaceId: workspaceId,
    prNodeId: prNodeId,
    cohortKey: cohortKey,
    title: title ?? this.title,
    summaryMarkdown: summaryMarkdown ?? this.summaryMarkdown,
    orderIndex: orderIndex ?? this.orderIndex,
    impactScore: impactScore ?? this.impactScore,
    derivation: derivation ?? this.derivation,
    filePaths: filePaths ?? this.filePaths,
    layers: layers ?? this.layers,
    diagrams: diagrams ?? this.diagrams,
    headSha: headSha ?? this.headSha,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewCohort &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          prNodeId == other.prNodeId &&
          cohortKey == other.cohortKey &&
          title == other.title &&
          summaryMarkdown == other.summaryMarkdown &&
          orderIndex == other.orderIndex &&
          impactScore == other.impactScore &&
          derivation == other.derivation &&
          const ListEquality<String>().equals(filePaths, other.filePaths) &&
          const ListEquality<CohortLayer>().equals(layers, other.layers) &&
          const ListEquality<ReviewDiagram>().equals(
            diagrams,
            other.diagrams,
          ) &&
          headSha == other.headSha;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    prNodeId,
    cohortKey,
    title,
    summaryMarkdown,
    orderIndex,
    impactScore,
    derivation,
    Object.hashAll(filePaths),
    Object.hashAll(layers),
    Object.hashAll(diagrams),
    headSha,
  );
}
