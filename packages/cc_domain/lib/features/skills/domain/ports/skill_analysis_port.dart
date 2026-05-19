import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';

/// One skill's result within a [SkillAnalysisOutcome].
class SkillAnalysisSkillResult {
  /// Creates a [SkillAnalysisSkillResult].
  SkillAnalysisSkillResult({
    required this.slug,
    required this.verdict,
    this.llmReviewed = false,
    this.findings = const [],
    this.capabilities = const [],
    this.detachedAgents = const [],
    this.error,
  }) {
    if (slug.isEmpty) {
      throw ArgumentError('slug must not be empty');
    }
  }

  /// Decodes from the wire/JSON shape shared by the RPC op and the step-run
  /// output rows.
  factory SkillAnalysisSkillResult.fromJson(Map<String, dynamic> json) =>
      SkillAnalysisSkillResult(
        slug: json['slug'] as String? ?? '',
        verdict: json['verdict'] == null
            ? null
            : SkillScanVerdict.fromWire(json['verdict'] as String),
        llmReviewed: json['llm_reviewed'] as bool? ?? false,
        findings: [
          for (final f in (json['findings'] as List?) ?? const [])
            if (f is Map) SkillScanFinding.fromJson(f.cast<String, dynamic>()),
        ],
        capabilities: [
          for (final c in (json['capabilities'] as List?) ?? const [])
            if (c is String) c,
        ],
        detachedAgents: [
          for (final a in (json['detached_agents'] as List?) ?? const [])
            if (a is String) a,
        ],
        error: json['error'] as String?,
      );

  /// The skill slug.
  final String slug;

  /// The scan verdict (null when this skill's scan errored — see [error]).
  final SkillScanVerdict? verdict;

  /// Whether the Layer 3 LLM review ran as part of this scan.
  final bool llmReviewed;

  /// Every finding the scanner recorded.
  final List<SkillScanFinding> findings;

  /// Human-readable capability labels the skill declared.
  final List<String> capabilities;

  /// Agents the skill was detached from (present only on quarantine).
  final List<String> detachedAgents;

  /// Why this skill's scan failed (best-effort pass: one skill's failure
  /// never aborts the analysis).
  final String? error;

  /// Serializes to the wire/JSON shape.
  Map<String, dynamic> toJson() => {
    'slug': slug,
    if (verdict != null) 'verdict': verdict!.wire,
    'llm_reviewed': llmReviewed,
    'findings': [for (final f in findings) f.toJson()],
    'capabilities': capabilities,
    'detached_agents': detachedAgents,
    if (error != null) 'error': error,
  };
}

/// The aggregate outcome of one skill-analysis pass over a workspace.
class SkillAnalysisOutcome {
  /// Creates a [SkillAnalysisOutcome].
  SkillAnalysisOutcome({required this.results})
    : passCount = results
          .where((r) => r.verdict == SkillScanVerdict.pass)
          .length,
      warnCount = results
          .where((r) => r.verdict == SkillScanVerdict.warn)
          .length,
      quarantineCount = results
          .where((r) => r.verdict == SkillScanVerdict.quarantine)
          .length;

  /// Decodes from the wire/JSON shape shared by the RPC op and step output.
  factory SkillAnalysisOutcome.fromJson(Map<String, dynamic> json) =>
      SkillAnalysisOutcome(
        results: [
          for (final r in (json['scanned'] as List?) ?? const [])
            if (r is Map)
              SkillAnalysisSkillResult.fromJson(r.cast<String, dynamic>()),
        ],
      );

  /// One entry per skill the pass attempted.
  final List<SkillAnalysisSkillResult> results;

  /// How many scanned clean.
  final int passCount;

  /// How many scanned with warnings.
  final int warnCount;

  /// How many were quarantined (and therefore detached from their agents).
  final int quarantineCount;

  /// Agents detached during this pass (aggregate across quarantined skills).
  List<String> get detachedAgents => [
    for (final r in results)
      for (final a in r.detachedAgents) a,
  ];

  /// Serializes to the wire/JSON shape (also used as the step's output and
  /// the run's `skillScanSummary` state).
  Map<String, dynamic> toJson() => {
    'scanned': [for (final r in results) r.toJson()],
    'pass': passCount,
    'warn': warnCount,
    'quarantine': quarantineCount,
    'detached_agents': detachedAgents,
  };
}

/// Runs the skills antivirus over a set of installed skills (PRD 23 §2/§6).
///
/// Implemented server-side; consumed by the `skill_analysis` pipeline step
/// body (so manual and event-triggered runs execute it) and by the settings
/// UI's synchronous scan ops. Pure scan + enforcement — no run bookkeeping
/// (the engine records engine runs; the reporter records projections).
abstract interface class SkillAnalysisPort {
  /// Scans the given [slugs]' current on-disk bytes (empty = every installed
  /// skill in [workspaceId]), detaching quarantined skills from their agents.
  /// Best-effort per skill: a failure is captured in the outcome's per-skill
  /// `error`, never thrown for the batch.
  Future<SkillAnalysisOutcome> analyze({
    required String workspaceId,
    List<String> slugs,
    bool runLlmReview,
  });
}
