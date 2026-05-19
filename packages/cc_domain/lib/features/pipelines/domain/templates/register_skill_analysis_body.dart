import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_analysis_port.dart';

/// Registers the `skills.analyze` step body — the skills antivirus as a
/// pipeline step (PRD 23 §2/§6).
///
/// Scope comes from the trigger payload: `slug` on a `SkillUpdated` event run
/// (single skill), `skill_slug` on a manual run (optional form field), empty
/// on either = every installed skill in the workspace. Delegates the actual
/// scan + quarantine enforcement to [SkillAnalysisPort] and records the
/// outcome as the `skillScanSummary` state (which is also the step's display
/// payload in the run detail).
///
/// Pipeline runs are deliberately the FAST deterministic profile
/// (`runLlmReview: false`): they fire on every skill write and disk change,
/// and the Layer 3 review is only ever additive on a static pass — the
/// interactive Scan action in settings keeps the full scan.
void registerSkillAnalysisBody(
  PipelineBodyRegistry registry, {
  required SkillAnalysisPort skillAnalysis,
}) {
  registry.registerBody(BuiltInBodyKeys.skillAnalysis, (ctx) async {
    // Event payload uses `slug` (SkillUpdated); the manual run form uses
    // `skill_slug`. Empty/absent on either = analyze every installed skill.
    final slug =
        ctx.optional<String>('slug')?.trim() ??
        ctx.optional<String>('skill_slug')?.trim();
    final slugs = (slug == null || slug.isEmpty) ? const <String>[] : [slug];

    if (ctx.dryRun) {
      return StepResult.ok(
        mutatedState: {
          'skill_scan_summary': {
            'scanned': const [],
            'pass': 0,
            'warn': 0,
            'quarantine': 0,
            'detached_agents': const [],
            'dry_run': true,
            'scope': slugs.isEmpty ? 'all skills' : slugs.join(', '),
          },
        },
      );
    }

    try {
      final outcome = await skillAnalysis.analyze(
        workspaceId: ctx.workspaceId,
        slugs: slugs,
        runLlmReview: false,
      );
      CcDomainLog.info(
        'skills.analyze: ${outcome.results.length} skill(s) scanned '
        '(${outcome.passCount} pass, ${outcome.warnCount} warn, '
        '${outcome.quarantineCount} quarantined)',
      );
      return StepResult.ok(
        mutatedState: {'skill_scan_summary': outcome.toJson()},
      );
    } on Object catch (e, st) {
      CcDomainLog.error('skills.analyze: analysis failed', e, st);
      return StepResult.failed('skills.analyze: $e');
    }
  });
}
