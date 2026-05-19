import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_analysis_port.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_server_core/src/skill_analysis_run_reporter.dart';
import 'package:cc_server_core/src/skill_quarantine_guard.dart';

/// The outcome of a recorded analysis pass: the scan results plus the id of
/// the pipeline run that recorded them (null when the template is disabled,
/// absent, deduplicated away, or nothing was scanned — the scan itself always
/// ran).
class RecordedSkillAnalysis {
  /// Creates a [RecordedSkillAnalysis].
  const RecordedSkillAnalysis({required this.outcome, this.runId});

  /// The scan results (always present — recording is optional).
  final SkillAnalysisOutcome outcome;

  /// The pipeline run id that recorded this pass, when one was written.
  final String? runId;
}

/// Runs the skills antivirus over installed skills and (optionally) records
/// the pass as a `skill_analysis` pipeline run (PRD 23 §2/§6).
///
/// Implements the [SkillAnalysisPort] the pipeline body drives, so engine
/// runs (manual run-picker starts, `SkillUpdated` event triggers) and the
/// settings UI's synchronous scan ops execute the SAME work. Recording is a
/// separate decision the caller makes:
///
/// * the engine path never records here — the engine writes its own run rows
///   around the body;
/// * the UI path calls [runRecorded], which writes projection rows via
///   [SkillAnalysisRunReporter].
///
/// The template's `isEnabled` switch governs ALL recording: when disabled (or
/// the template absent), [runRecorded] still scans and returns results but
/// writes nothing — the antivirus itself is never disabled by the pipeline
/// toggle, only its run history.
class SkillAnalysisService implements SkillAnalysisPort {
  /// Creates a [SkillAnalysisService].
  SkillAnalysisService({
    required SkillBundlePort bundles,
    required SkillQuarantineGuard quarantineGuard,
    required SkillAnalysisRunReporter reporter,
    required PipelineTemplateRepository templates,
    required PipelineRunRepository runs,
  }) : _bundles = bundles,
       _quarantineGuard = quarantineGuard,
       _reporter = reporter,
       _templates = templates,
       _runs = runs;

  final SkillBundlePort _bundles;
  final SkillQuarantineGuard _quarantineGuard;
  final SkillAnalysisRunReporter _reporter;
  final PipelineTemplateRepository _templates;
  final PipelineRunRepository _runs;

  @override
  Future<SkillAnalysisOutcome> analyze({
    required String workspaceId,
    List<String> slugs = const [],
    bool runLlmReview = false,
  }) async {
    var scope = slugs;
    if (scope.isEmpty) {
      scope = (await _bundles.listInstalledStatus(
        workspaceId,
      )).map((s) => s.slug).toList();
    }
    final results = <SkillAnalysisSkillResult>[];
    for (final slug in scope) {
      try {
        final scan = await _bundles.scanInstalled(
          workspaceId: workspaceId,
          slug: slug,
          runLlmReview: runLlmReview,
        );
        final detached = scan.verdict == SkillScanVerdict.quarantine
            ? await _quarantineGuard.detachQuarantined(workspaceId, slug: slug)
            : const <String>[];
        results.add(
          SkillAnalysisSkillResult(
            slug: slug,
            verdict: scan.verdict,
            llmReviewed: scan.llmReviewed,
            findings: scan.findings,
            capabilities: scan.manifest.labels,
            detachedAgents: detached,
          ),
        );
      } on Object catch (e) {
        // Best-effort per skill: one failure never aborts the pass.
        results.add(
          SkillAnalysisSkillResult(slug: slug, verdict: null, error: '$e'),
        );
      }
    }
    return SkillAnalysisOutcome(results: results);
  }

  /// Analyzes and records the pass as a projection run. Recording is skipped
  /// (the scan still runs) when: the template is disabled or absent — the
  /// user's off-switch; or a run is already active for the workspace — the
  /// dedup marker the reporter pins, so a burst of scans doesn't litter rows.
  Future<RecordedSkillAnalysis> runRecorded({
    required String workspaceId,
    List<String> slugs = const [],
    required String triggerEventType,
    Map<String, dynamic>? triggerPayload,
    bool runLlmReview = false,
  }) async {
    final template = await _templates.getById(
      workspaceId,
      SkillAnalysisTemplate.id,
    );
    final active = await _runs.activeForDedupKey(
      templateId: SkillAnalysisTemplate.id,
      workspaceId: workspaceId,
      dedupKey: 'skill_analysis:$workspaceId',
    );
    final record = template != null && template.isEnabled && active == null;
    if (!record) {
      return RecordedSkillAnalysis(
        outcome: await analyze(
          workspaceId: workspaceId,
          slugs: slugs,
          runLlmReview: runLlmReview,
        ),
      );
    }

    final run = _reporter.begin(
      workspaceId: workspaceId,
      slugs: slugs,
      triggerEventType: triggerEventType,
      triggerPayload: triggerPayload,
    );
    try {
      var scope = slugs;
      if (scope.isEmpty) {
        scope = (await _bundles.listInstalledStatus(
          workspaceId,
        )).map((s) => s.slug).toList();
      }
      final results = <SkillAnalysisSkillResult>[];
      for (final slug in scope) {
        // analyze() one slug at a time so each result streams into the run.
        final outcome = await analyze(
          workspaceId: workspaceId,
          slugs: [slug],
          runLlmReview: runLlmReview,
        );
        results.addAll(outcome.results);
        await run.addResult(outcome.results.single);
      }
      await run.finish();
      return RecordedSkillAnalysis(
        outcome: SkillAnalysisOutcome(results: results),
        runId: run.runId,
      );
    } on Object catch (e, st) {
      await run.fail(e, st);
      rethrow;
    }
  }
}
