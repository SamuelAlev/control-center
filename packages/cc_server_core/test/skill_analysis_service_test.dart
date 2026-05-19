import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/ports/workspace_filesystem_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_skills.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_status.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/skills/domain/entities/skill_lock.dart';
import 'package:cc_domain/features/skills/domain/ports/skill_bundle_port.dart';
import 'package:cc_domain/features/skills/domain/scanner/installed_skill_status.dart';
import 'package:cc_domain/features/skills/domain/scanner/skill_scan_types.dart';
import 'package:cc_server_core/src/skill_analysis_run_reporter.dart';
import 'package:cc_server_core/src/skill_analysis_service.dart';
import 'package:cc_server_core/src/skill_quarantine_guard.dart';
import 'package:test/test.dart';

/// The skills antivirus as a pipeline run (PRD 23 §2/§6): the service runs
/// the scans + enforcement and `runRecorded` publishes projection runs that
/// the generic pipeline UI shows — governed by the template's isEnabled
/// switch and a one-active-per-workspace dedup.
void main() {
  late _FakeBundles bundles;
  late _FakeAgents agents;
  late _FakeFs fs;
  late _FakeTemplates templates;
  late _FakeRunRepo runs;

  setUp(() {
    bundles = _FakeBundles();
    agents = _FakeAgents();
    fs = _FakeFs();
    templates = _FakeTemplates();
    runs = _FakeRunRepo();
  });

  SkillAnalysisService buildService() {
    final guard = SkillQuarantineGuard(
      agents: agents,
      bundles: bundles,
      filesystem: fs,
    );
    final reporter = SkillAnalysisRunReporter(
      runs,
      idFactory: () => 'id-${runs.seq++}',
      now: () => DateTime(2026, 1, 1, 12),
    );
    return SkillAnalysisService(
      bundles: bundles,
      quarantineGuard: guard,
      reporter: reporter,
      templates: templates,
      runs: runs,
    );
  }

  group('SkillAnalysisService.analyze', () {
    test('empty slugs scans every installed skill', () async {
      bundles.installed = ['a', 'b', 'c'];
      bundles.verdicts['a'] = SkillScanVerdict.pass;
      bundles.verdicts['b'] = SkillScanVerdict.warn;
      bundles.verdicts['c'] = SkillScanVerdict.quarantine;
      final outcome = await buildService().analyze(workspaceId: 'ws');
      expect(outcome.results.map((r) => r.slug), ['a', 'b', 'c']);
      expect(outcome.passCount, 1);
      expect(outcome.warnCount, 1);
      expect(outcome.quarantineCount, 1);
    });

    test('a quarantined skill is detached from its agents', () async {
      bundles.installed = ['bad'];
      bundles.verdicts['bad'] = SkillScanVerdict.quarantine;
      agents.seed([
        _agent('1', 'ceo', const ['bad']),
        _agent('2', 'dev', const ['ok']),
      ]);
      final outcome = await buildService().analyze(workspaceId: 'ws');
      expect(outcome.results.single.detachedAgents, ['ceo']);
      // Only the affected agent is re-synced, with its FULL attachment list.
      expect(fs.syncCalls.map((c) => c.$2), ['ceo']);
    });

    test('one skill scan failure never aborts the pass', () async {
      bundles.installed = ['good', 'boom'];
      bundles.verdicts['good'] = SkillScanVerdict.pass;
      bundles.failSlugs.add('boom');
      final outcome = await buildService().analyze(workspaceId: 'ws');
      expect(outcome.results, hasLength(2));
      expect(outcome.results.firstWhere((r) => r.slug == 'boom').error,
          isNotNull);
      expect(outcome.passCount, 1);
    });
  });

  group('SkillAnalysisService.runRecorded', () {
    test('records a completed projection run with per-skill results', () async {
      templates.definition = skillAnalysisTemplate('ws');
      bundles.installed = ['a', 'b'];
      bundles.verdicts['a'] = SkillScanVerdict.pass;
      bundles.verdicts['b'] = SkillScanVerdict.warn;

      final recorded = await buildService().runRecorded(
        workspaceId: 'ws',
        triggerEventType: SkillAnalysisTemplate.manualProjectionTriggerEventType,
      );

      expect(recorded.runId, isNotNull);
      final run = runs.runs[recorded.runId!]!;
      expect(run.templateId, SkillAnalysisTemplate.id);
      expect(run.status, PipelineRunStatus.completed);
      expect(run.dedupKey, 'skill_analysis:ws');
      expect(recorded.outcome.warnCount, 1);

      final steps = runs.stepsFor(recorded.runId!);
      expect(
        steps.firstWhere((s) => s.stepId == SkillAnalysisTemplate.triggerStepId)
            .status,
        PipelineStepStatus.completed,
      );
      final scanStep =
          steps.firstWhere((s) => s.stepId == SkillAnalysisTemplate.scanStepId);
      expect(scanStep.status, PipelineStepStatus.completed);
      expect(scanStep.outputJson, contains('"warn":1'));
    });

    test('a disabled template scans but writes no run rows', () async {
      templates.definition = skillAnalysisTemplate(
        'ws',
      ).copyWith(isEnabled: false);
      bundles.installed = ['a'];
      bundles.verdicts['a'] = SkillScanVerdict.pass;

      final recorded = await buildService().runRecorded(
        workspaceId: 'ws',
        triggerEventType: SkillAnalysisTemplate.manualProjectionTriggerEventType,
      );

      expect(recorded.runId, isNull);
      expect(runs.runs, isEmpty);
      // The antivirus itself is never disabled by the pipeline toggle.
      expect(recorded.outcome.passCount, 1);
    });

    test('an absent template scans but writes no run rows', () async {
      bundles.installed = ['a'];
      final recorded = await buildService().runRecorded(
        workspaceId: 'ws',
        triggerEventType: SkillAnalysisTemplate.manualProjectionTriggerEventType,
      );
      expect(recorded.runId, isNull);
      expect(runs.runs, isEmpty);
      expect(recorded.outcome.results, hasLength(1));
    });

    test('skips recording while a run is already active (dedup)', () async {
      templates.definition = skillAnalysisTemplate('ws');
      runs.activeDedup = PipelineRun(
        id: 'active',
        templateId: SkillAnalysisTemplate.id,
        workspaceId: 'ws',
        status: PipelineRunStatus.running,
        triggerEventType: 'manual',
        startedAt: DateTime(2026, 1, 1),
      );
      bundles.installed = ['a'];

      final recorded = await buildService().runRecorded(
        workspaceId: 'ws',
        triggerEventType: SkillAnalysisTemplate.manualProjectionTriggerEventType,
      );
      expect(recorded.runId, isNull);
      expect(runs.runs.values.where((r) => r.id != 'active'), isEmpty);
    });
  });

  group('SkillAnalysisRunReporter.reapInterrupted', () {
    test('closes its own stale projections, leaves engine runs alone',
        () async {
      runs.runs['mine'] = PipelineRun(
        id: 'mine',
        templateId: SkillAnalysisTemplate.id,
        workspaceId: 'ws',
        status: PipelineRunStatus.running,
        triggerEventType:
            SkillAnalysisTemplate.manualProjectionTriggerEventType,
        startedAt: DateTime(2026, 1, 1),
      );
      runs.steps['step'] = PipelineStepRun(
        id: 'step',
        pipelineRunId: 'mine',
        stepId: SkillAnalysisTemplate.scanStepId,
        status: PipelineStepStatus.running,
        startedAt: DateTime(2026, 1, 1),
      );
      runs.runs['engine'] = PipelineRun(
        id: 'engine',
        templateId: SkillAnalysisTemplate.id,
        workspaceId: 'ws',
        status: PipelineRunStatus.running,
        triggerEventType: 'SkillUpdated',
        startedAt: DateTime(2026, 1, 1),
      );

      final reporter = SkillAnalysisRunReporter(
        runs,
        idFactory: () => 'id',
        now: () => DateTime(2026, 1, 1, 12),
      );
      final closed = await reporter.reapInterrupted();

      expect(closed, 1);
      expect(runs.runs['mine']!.status, PipelineRunStatus.cancelled);
      expect(runs.steps['step']!.status, PipelineStepStatus.cancelled);
      // Engine-owned rows are resumable — never reaped.
      expect(runs.runs['engine']!.status, PipelineRunStatus.running);
    });
  });
}

Agent _agent(String id, String name, List<String> skills) => Agent(
  id: id,
  name: name,
  title: name,
  agentMdPath: '/agents/$name.md',
  workspaceId: 'ws',
  skills: AgentSkills(skills),
  createdAt: DateTime(2026, 1, 1),
);

/// Fake bundle port: fixed installed list + per-slug verdicts. Models the
/// real service's quarantine semantics: a quarantined scan pins the verdict
/// into the lock (that is what enforcement reads).
class _FakeBundles implements SkillBundlePort {
  List<String> installed = [];
  final Map<String, SkillScanVerdict> verdicts = {};
  final Set<String> failSlugs = {};
  final Map<String, SkillLockEntry> _lock = {};

  @override
  Future<List<InstalledSkillStatus>> listInstalledStatus(
    String workspaceId,
  ) async => [
    for (final slug in installed)
      InstalledSkillStatus(
        slug: slug,
        lockState: InstalledSkillLockState.managed,
        computedHash: 'h-$slug',
      ),
  ];

  @override
  Future<SkillScanResult> scanInstalled({
    required String workspaceId,
    required String slug,
    bool runLlmReview = true,
  }) async {
    if (failSlugs.contains(slug)) {
      throw StateError('scan blew up for $slug');
    }
    final verdict = verdicts[slug] ?? SkillScanVerdict.pass;
    if (verdict == SkillScanVerdict.quarantine) {
      _lock[slug] = SkillLockEntry(
        slug: slug,
        source: 'workspace',
        sourceType: SkillOrigin.manual,
        skillPath: 'skills/$slug/SKILL.md',
        computedHash: 'h-$slug',
        scanVerdict: verdict,
        rulesVersion: 1,
      );
    }
    return SkillScanResult(
      verdict: verdict,
      findings: const [],
      manifest: const SkillCapabilityManifest(),
      rulesVersion: 1,
    );
  }

  @override
  Future<SkillLock> readLock(String workspaceId) async =>
      SkillLock(skills: Map.of(_lock));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeAgents implements AgentRepository {
  final List<Agent> _agents = [];

  void seed(List<Agent> list) => _agents.addAll(list);

  @override
  Stream<List<Agent>> watchByWorkspace(String workspaceId) =>
      Stream.value(List.of(_agents));

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeFs implements WorkspaceFilesystemPort {
  final List<(String, String, List<String>)> syncCalls = [];

  @override
  Future<void> syncAgentSkillLinks(
    String workspaceId,
    String agentSlug,
    List<String> skillSlugs,
  ) async {
    syncCalls.add((workspaceId, agentSlug, List.of(skillSlugs)));
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _FakeTemplates implements PipelineTemplateRepository {
  PipelineDefinition? definition;

  @override
  Future<PipelineDefinition?> getById(
    String workspaceId,
    String templateId,
  ) async => definition == null || definition!.templateId != templateId
        ? null
        : definition;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

/// In-memory run repo over the shape the engine test uses, plus the dedup
/// lookup the service gates recording on.
class _FakeRunRepo implements PipelineRunRepository {
  final Map<String, PipelineRun> runs = {};
  final Map<String, PipelineStepRun> steps = {};
  PipelineRun? activeDedup;
  int seq = 0;

  List<PipelineStepRun> stepsFor(String runId) =>
      steps.values.where((s) => s.pipelineRunId == runId).toList();

  @override
  Future<PipelineRun?> getRun(String id) async => runs[id];

  @override
  Future<void> insertRun(PipelineRun run) async => runs[run.id] = run;

  @override
  Future<void> updateRun(PipelineRun run) async => runs[run.id] = run;

  @override
  Future<void> updateRunState(String runId, Map<String, dynamic> state) async {
    final existing = runs[runId];
    if (existing != null) {
      runs[runId] = existing.copyWith(state: state);
    }
  }

  @override
  Future<List<PipelineStepRun>> stepRunsForPipeline(String pipelineRunId) async =>
      stepsFor(pipelineRunId);

  @override
  Future<void> insertStepRun(PipelineStepRun stepRun) async =>
      steps[stepRun.id] = stepRun;

  @override
  Future<void> updateStepRun(
    String workspaceId,
    String stepRunId, {
    PipelineStepStatus? status,
    String? inputJson,
    String? outputJson,
    String? channelId,
    String? errorMessage,
    String? errorStackTrace,
    DateTime? finishedAt,
  }) async {
    final current = steps[stepRunId];
    if (current == null) {
      return;
    }
    steps[stepRunId] = PipelineStepRun(
      id: current.id,
      pipelineRunId: current.pipelineRunId,
      stepId: current.stepId,
      status: status ?? current.status,
      inputJson: inputJson ?? current.inputJson,
      outputJson: outputJson ?? current.outputJson,
      channelId: channelId ?? current.channelId,
      errorMessage: errorMessage ?? current.errorMessage,
      branchIndex: current.branchIndex,
      attemptCount: current.attemptCount,
      startedAt: current.startedAt,
      finishedAt: finishedAt ?? current.finishedAt,
    );
  }

  @override
  Future<List<PipelineRun>> nonTerminalRuns() async =>
      runs.values.where((r) => !r.isTerminal).toList();

  @override
  Future<PipelineRun?> activeForDedupKey({
    required String templateId,
    required String workspaceId,
    required String dedupKey,
  }) async => activeDedup;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
