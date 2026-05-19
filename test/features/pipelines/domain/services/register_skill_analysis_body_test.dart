import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/pipelines/domain/templates/register_skill_analysis_body.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_analysis_port.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:flutter_test/flutter_test.dart';

/// The `skills.analyze` step body: the skills antivirus as a pipeline step.
/// Scope comes from the trigger payload (`slug` on SkillUpdated runs,
/// `skill_slug` on manual form runs, empty = every installed skill), the work
/// is delegated to SkillAnalysisPort and the outcome lands in state as
/// `skillScanSummary`.
void main() {
  late _FakeAnalysis analysis;
  late PipelineBodyRegistry registry;

  setUp(() {
    analysis = _FakeAnalysis();
    registry = PipelineBodyRegistry();
    registerSkillAnalysisBody(registry, skillAnalysis: analysis);
  });

  PipelineContext ctx({Map<String, dynamic>? payload, bool dryRun = false}) =>
      PipelineContext(
        pipelineRunId: 'run-1',
        templateId: SkillAnalysisTemplate.id,
        stepId: SkillAnalysisTemplate.scanStepId,
        stepRunId: 'step-1',
        workspaceId: 'ws-1',
        state: const {},
        triggerPayload: payload,
        dryRun: dryRun,
      );

  test('registers under the skills.analyze body key', () {
    expect(registry.hasBody(BuiltInBodyKeys.skillAnalysis), isTrue);
  });

  test('analyzes the event payload slug', () async {
    analysis.outcome = SkillAnalysisOutcome(results: const []);
    final result = await registry.body(BuiltInBodyKeys.skillAnalysis)(
      ctx(payload: {'slug': 'pdf-tools', 'origin': 'watch'}),
    );
    expect(result.isFailed, isFalse);
    expect(analysis.lastSlugs, ['pdf-tools']);
    // Pipeline runs are the fast deterministic profile — no LLM pass.
    expect(analysis.lastRunLlmReview, isFalse);
    final summary =
        result.mutatedState!['skill_scan_summary'] as Map<String, dynamic>;
    expect(summary['pass'], 0);
  });

  test(
    'manual form skill_slug scopes the scan; empty scans everything',
    () async {
      await registry.body(BuiltInBodyKeys.skillAnalysis)(
        ctx(payload: {'skill_slug': 'my-skill'}),
      );
      expect(analysis.lastSlugs, ['my-skill']);

      await registry.body(BuiltInBodyKeys.skillAnalysis)(ctx(payload: {}));
      expect(analysis.lastSlugs, isEmpty);
    },
  );

  test('records the tallies in state', () async {
    analysis.outcome = SkillAnalysisOutcome(
      results: [
        SkillAnalysisSkillResult(slug: 'a', verdict: SkillScanVerdict.pass),
        SkillAnalysisSkillResult(
          slug: 'b',
          verdict: SkillScanVerdict.quarantine,
        ),
      ],
    );
    final result = await registry.body(BuiltInBodyKeys.skillAnalysis)(
      ctx(payload: {}),
    );
    final summary = result.mutatedState!['skill_scan_summary'] as Map;
    expect(summary['pass'], 1);
    expect(summary['quarantine'], 1);
    expect(summary['scanned'], hasLength(2));
  });

  test('dry-run short-circuits without touching the port', () async {
    final result = await registry.body(BuiltInBodyKeys.skillAnalysis)(
      ctx(payload: {'slug': 'x'}, dryRun: true),
    );
    expect(result.isFailed, isFalse);
    expect(analysis.calls, 0);
  });

  test('a port failure fails the step (recorded by the engine)', () async {
    analysis.throwObject = StateError('scanner down');
    final result = await registry.body(BuiltInBodyKeys.skillAnalysis)(
      ctx(payload: {}),
    );
    expect(result.isFailed, isTrue);
    expect(result.errorMessage, contains('scanner down'));
  });

  test('the seeded template wires the body key and output key', () {
    final template = skillAnalysisTemplate('ws-1');
    final scan = template.steps.singleWhere(
      (s) => s.id == SkillAnalysisTemplate.scanStepId,
    );
    expect(scan.bodyKey, BuiltInBodyKeys.skillAnalysis);
    expect(scan.config.outputKey, 'skill_scan_summary');
    // Manually runnable from the run page (trigger row seeded separately).
    expect(template.inputs.single.key, 'skill_slug');
  });
}

class _FakeAnalysis implements SkillAnalysisPort {
  SkillAnalysisOutcome outcome = SkillAnalysisOutcome(results: const []);
  Object? throwObject;
  int calls = 0;
  List<String>? lastSlugs;
  bool? lastRunLlmReview;

  @override
  Future<SkillAnalysisOutcome> analyze({
    required String workspaceId,
    List<String> slugs = const [],
    bool runLlmReview = false,
  }) async {
    calls++;
    lastSlugs = slugs;
    lastRunLlmReview = runLlmReview;
    if (throwObject != null) {
      throw throwObject!;
    }
    return outcome;
  }
}
