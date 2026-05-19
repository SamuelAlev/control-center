// Structured walkthrough-style review summary carried in `review_summary`
// message metadata alongside the deterministic verdict fields.
//
// The narrative is authored by the finalizing agent from deterministic inputs
// (cohorts, findings, axis results); this VO is the typed envelope so the
// Review Hub and the GitHub publisher render the same structure. Parsing is
// null-on-malformed (same discipline as [ReviewNodePayload]): a legacy
// summary without these keys parses to null and callers fall back to the
// message's markdown body.
//
// ignore_for_file: sort_constructors_first

import 'package:collection/collection.dart';

/// One area section of the walkthrough (a cohort's narrative).
class ReviewWalkthroughArea {
  /// Creates a [ReviewWalkthroughArea]. An empty [cohortKey] is parseable
  /// (malformed stored sections decode instead of throwing) but is dropped by
  /// [ReviewWalkthroughSummary.fromMetadata].
  const ReviewWalkthroughArea({
    required this.cohortKey,
    required this.title,
    this.bullets = const [],
    this.files = const [],
  });

  /// The cohort this section narrates (joins `ReviewCohort.cohortKey`).
  final String cohortKey;

  /// Human-readable area title ("Auth flow", "Billing API").
  final String title;

  /// What changed in this area, as short narrative bullets.
  final List<String> bullets;

  /// The changed files this area covers, so the walkthrough can be read as a
  /// table of concerns rather than a flat file list. Empty on summaries
  /// written before the table existed.
  final List<String> files;

  /// Builds from JSON.
  factory ReviewWalkthroughArea.fromJson(Map<String, dynamic> json) =>
      ReviewWalkthroughArea(
        cohortKey: json['cohortKey'] as String? ?? '',
        title: json['title'] as String? ?? '',
        bullets: (json['bullets'] as List? ?? const [])
            .whereType<String>()
            .toList(),
        files: (json['files'] as List? ?? const [])
            .whereType<String>()
            .toList(),
      );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'cohortKey': cohortKey,
    'title': title,
    'bullets': bullets,
    if (files.isNotEmpty) 'files': files,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewWalkthroughArea &&
          cohortKey == other.cohortKey &&
          title == other.title &&
          const ListEquality<String>().equals(bullets, other.bullets) &&
          const ListEquality<String>().equals(files, other.files);

  @override
  int get hashCode => Object.hash(
    cohortKey,
    title,
    Object.hashAll(bullets),
    Object.hashAll(files),
  );
}

/// The structured review summary: headline, per-area walkthrough, risk notes.
class ReviewWalkthroughSummary {
  /// Creates a [ReviewWalkthroughSummary].
  const ReviewWalkthroughSummary({
    required this.headline,
    this.areas = const [],
    this.riskNotes = const [],
    this.headSha,
    this.effortScore,
    this.effortMinutes,
  });

  /// One-line "what this PR does".
  final String headline;

  /// Per-area narrative sections, in the deterministic impact/reading order.
  final List<ReviewWalkthroughArea> areas;

  /// Cross-cutting risks worth flagging above the per-area detail.
  final List<String> riskNotes;

  /// The head SHA the summarized review ran against (pushes invalidate).
  final String? headSha;

  /// How much effort reading this review is likely to take, 1 (trivial) to 5
  /// (very complex). Computed deterministically, never asked of the model.
  final int? effortScore;

  /// The same estimate in minutes, for readers who want the number rather than
  /// the band.
  final int? effortMinutes;

  /// Whether this summary carries no narrative content at all.
  bool get isAbsent => headline.isEmpty && areas.isEmpty;

  /// Returns a copy with overrides ([headSha] overridable to null).
  ReviewWalkthroughSummary copyWith({
    String? headline,
    List<ReviewWalkthroughArea>? areas,
    List<String>? riskNotes,
    Object? headSha = _sentinel,
    int? effortScore,
    int? effortMinutes,
  }) {
    return ReviewWalkthroughSummary(
      headline: headline ?? this.headline,
      areas: areas ?? this.areas,
      riskNotes: riskNotes ?? this.riskNotes,
      headSha: headSha == _sentinel ? this.headSha : headSha as String?,
      effortScore: effortScore ?? this.effortScore,
      effortMinutes: effortMinutes ?? this.effortMinutes,
    );
  }

  static const _sentinel = Object();

  /// Serializes to flat metadata keys for the `review_summary` message
  /// (namespaced `summary*` so they coexist with the verdict fields).
  Map<String, dynamic> toMetadata() => {
    if (headline.isNotEmpty) 'summaryHeadline': headline,
    if (areas.isNotEmpty) 'summaryAreas': areas.map((a) => a.toJson()).toList(),
    if (riskNotes.isNotEmpty) 'summaryRisks': riskNotes,
    if (headSha != null) 'summaryHeadSha': headSha,
    if (effortScore != null) 'summaryEffortScore': effortScore,
    if (effortMinutes != null) 'summaryEffortMinutes': effortMinutes,
  };

  /// Parses from a `review_summary`-style metadata map. Returns null when the
  /// structured keys are absent (legacy summaries) or every field is
  /// malformed — callers then fall back to the markdown body.
  static ReviewWalkthroughSummary? fromMetadata(Map<String, dynamic>? meta) {
    if (meta == null) {
      return null;
    }
    final headline = meta['summaryHeadline'];
    final rawAreas = meta['summaryAreas'];
    final risks = (meta['summaryRisks'] as List? ?? const [])
        .whereType<String>()
        .toList();
    final headSha = meta['summaryHeadSha'];
    final areas = rawAreas is List
        ? rawAreas
              .whereType<Map>()
              .map(
                (m) =>
                    ReviewWalkthroughArea.fromJson(m.cast<String, dynamic>()),
              )
              .where((a) => a.cohortKey.isNotEmpty)
              .toList()
        : const <ReviewWalkthroughArea>[];
    if (headline is! String && areas.isEmpty) {
      return null;
    }
    return ReviewWalkthroughSummary(
      headline: headline is String ? headline : '',
      areas: areas,
      riskNotes: risks,
      headSha: headSha is String ? headSha : null,
      effortScore: meta['summaryEffortScore'] is int
          ? meta['summaryEffortScore'] as int
          : null,
      effortMinutes: meta['summaryEffortMinutes'] is int
          ? meta['summaryEffortMinutes'] as int
          : null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ReviewWalkthroughSummary &&
          headline == other.headline &&
          const ListEquality<ReviewWalkthroughArea>().equals(
            areas,
            other.areas,
          ) &&
          const ListEquality<String>().equals(riskNotes, other.riskNotes) &&
          headSha == other.headSha &&
          effortScore == other.effortScore &&
          effortMinutes == other.effortMinutes;

  @override
  int get hashCode => Object.hash(
    headline,
    Object.hashAll(areas),
    Object.hashAll(riskNotes),
    headSha,
    effortScore,
    effortMinutes,
  );
}
