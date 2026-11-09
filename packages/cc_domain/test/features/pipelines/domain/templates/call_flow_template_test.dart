import 'package:cc_domain/features/pipelines/domain/entities/pipeline_node_config.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_step_definition.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_kind.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:cc_domain/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/services/sub_pipeline_launcher.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/pipelines/domain/templates/call_flow_template.dart';
import 'package:test/test.dart';

/// `flow.callPipeline`: one child per calling step, and no cross-template
/// cycles (audit: callFlow dedup + cycle detection).
void main() {
  late _Runs runs;
  late _Engine engine;
  late PipelineBodyRegistry registry;

  setUp(() {
    runs = _Runs();
    engine = _Engine();
    registry = PipelineBodyRegistry();
    registerCallFlowBody(
      registry,
      templateRepository: _NoTemplates(),
      runRepository: runs,
      launcher: SubPipelineLauncher()..engine = engine,
    );
  });

  PipelineRun run(String id, String templateId, {String? parent}) =>
      PipelineRun(
        id: id,
        templateId: templateId,
        workspaceId: 'ws',
        status: PipelineRunStatus.running,
        parentPipelineRunId: parent,
        parentStepId: parent == null ? null : 'call',
        startedAt: DateTime(2026),
      );

  PipelineContext ctx(String runId, String templateId, String target) =>
      PipelineContext(
        pipelineRunId: runId,
        templateId: templateId,
        stepId: 'call',
        stepRunId: 'sr-$runId',
        workspaceId: 'ws',
        state: const {},
        step: PipelineStepDefinition(
          id: 'call',
          kind: StepKind.listen,
          bodyKey: BuiltInBodyKeys.callFlow,
          config: PipelineNodeConfig(extras: {'templateId': target}),
        ),
      );

  StepBodyFn body() => registry.body(BuiltInBodyKeys.callFlow);

  test('starts the child with a per-step dedup key', () async {
    runs.rows['r1'] = run('r1', 'A');
    final result = await body()(ctx('r1', 'A', 'B'));
    expect(result.isSuspended, isTrue);
    expect(engine.starts.single.dedupKey, callFlowDedupKey('r1', 'call'));
    expect(engine.starts.single.parentPipelineRunId, 'r1');
  });

  test('a re-fired step re-attaches to its running child', () async {
    runs.rows['r1'] = run('r1', 'A');
    runs.active[callFlowDedupKey('r1', 'call')] = run('child', 'B');
    final result = await body()(ctx('r1', 'A', 'B'));
    expect(result.suspendUntilEvent, 'childFlow:child');
    expect(engine.starts, isEmpty);
  });

  test('A → B → A is refused as a cycle', () async {
    runs.rows['ra'] = run('ra', 'A');
    runs.rows['rb'] = run('rb', 'B', parent: 'ra');
    final result = await body()(ctx('rb', 'B', 'A'));
    expect(result.isFailed, isTrue);
    expect(result.errorMessage, contains('cycle'));
    expect(engine.starts, isEmpty);
  });

  test('nesting is bounded', () async {
    String? parent;
    for (var i = 0; i < kMaxSubPipelineDepth; i++) {
      runs.rows['r$i'] = run('r$i', 'T$i', parent: parent);
      parent = 'r$i';
    }
    const deepest = kMaxSubPipelineDepth - 1;
    final result = await body()(ctx('r$deepest', 'T$deepest', 'Fresh'));
    expect(result.isFailed, isTrue);
    expect(result.errorMessage, contains('deep'));
  });
}

class _Runs implements PipelineRunReader {
  final Map<String, PipelineRun> rows = {};
  final Map<String, PipelineRun> active = {};

  @override
  Future<PipelineRun?> getRun(String id) async => rows[id];

  @override
  Future<PipelineRun?> activeForDedupKey({
    required String templateId,
    required String workspaceId,
    required String dedupKey,
  }) async => active[dedupKey];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class _NoTemplates implements PipelineTemplateRepository {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

typedef _Start = ({String? dedupKey, String? parentPipelineRunId});

class _Engine implements PipelineEnginePort {
  final List<_Start> starts = [];

  @override
  Future<PipelineRun?> start(
    String templateId, {
    required String workspaceId,
    String? triggerEventType,
    Map<String, dynamic>? triggerPayload,
    String? dedupKey,
    String? parentPipelineRunId,
    String? parentStepId,
    bool dryRun = false,
    String? requestedByUserId,
  }) async {
    starts.add((dedupKey: dedupKey, parentPipelineRunId: parentPipelineRunId));
    return PipelineRun(
      id: 'child-${starts.length}',
      templateId: templateId,
      workspaceId: workspaceId,
      status: PipelineRunStatus.pending,
      startedAt: DateTime(2026),
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
