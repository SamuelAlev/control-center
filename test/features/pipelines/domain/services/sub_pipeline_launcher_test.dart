import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_run_status.dart';
import 'package:cc_domain/features/pipelines/domain/ports/pipeline_engine_port.dart';
import 'package:cc_domain/features/pipelines/domain/services/sub_pipeline_launcher.dart';
import 'package:flutter_test/flutter_test.dart';

/// Minimal fake [PipelineEnginePort] that records the last call to [start]
/// and returns a caller-specified result.
class FakePipelineEnginePort implements PipelineEnginePort {

  FakePipelineEnginePort({PipelineRun? run}) : result = Future.value(run);
  /// The result returned by [start].
  final Future<PipelineRun?> result;

  // --- recorded call parameters ---
  String? capturedTemplateId;
  String? capturedWorkspaceId;
  Map<String, dynamic>? capturedTriggerPayload;
  String? capturedParentPipelineRunId;
  String? capturedParentStepId;
  bool? capturedDryRun;

  @override
  Future<PipelineRun?> start(
    String templateId, {
    required String workspaceId,
    Map<String, dynamic>? triggerPayload,
    String? parentPipelineRunId,
    String? parentStepId,
    bool dryRun = false,
  }) async {
    capturedTemplateId = templateId;
    capturedWorkspaceId = workspaceId;
    capturedTriggerPayload = triggerPayload;
    capturedParentPipelineRunId = parentPipelineRunId;
    capturedParentStepId = parentStepId;
    capturedDryRun = dryRun;
    return result;
  }
}

/// Helper to create a minimal [PipelineRun] for test fakes.
PipelineRun _fakeRun({String id = 'run-fake', String templateId = 'tpl-fake'}) {
  return PipelineRun(
    id: id,
    templateId: templateId,
    workspaceId: 'ws-fake',
    status: PipelineRunStatus.pending,
    startedAt: DateTime(2025, 1, 1),
  );
}

void main() {
  group('SubPipelineLauncher', () {
    // -------------------------------------------------------------------------
    // startChild — null engine
    // -------------------------------------------------------------------------
    group('startChild when engine is null', () {
      test('throws StateError with descriptive message', () {
        final launcher = SubPipelineLauncher();
        // engine is null by default

        expect(
          () => launcher.startChild(
            'tpl-1',
            workspaceId: 'ws-1',
            parentPipelineRunId: 'parent-run',
            parentStepId: 'step-a',
          ),
          throwsA(isA<StateError>().having(
            (e) => e.message,
            'message',
            'SubPipelineLauncher used before the engine was wired',
          )),
        );
      });

      test('throws StateError regardless of optional parameters', () {
        final launcher = SubPipelineLauncher();

        expect(
          () => launcher.startChild(
            'tpl-1',
            workspaceId: 'ws-1',
            triggerPayload: {'key': 'val'},
            parentPipelineRunId: 'parent-run',
            parentStepId: 'step-a',
            dryRun: true,
          ),
          throwsStateError,
        );
      });
    });

    // -------------------------------------------------------------------------
    // startChild — delegates to engine
    // -------------------------------------------------------------------------
    group('startChild delegates to engine', () {
      test('returns the value from engine.start() when engine returns a run', () async {
        final run = _fakeRun(id: 'child-1');
        final fake = FakePipelineEnginePort(run: run);
        final launcher = SubPipelineLauncher()..engine = fake;

        final result = await launcher.startChild(
          'tpl-child',
          workspaceId: 'ws-1',
          parentPipelineRunId: 'parent-run',
          parentStepId: 'step-a',
        );

        expect(result, same(run));
      });

      test('returns null when engine.start() returns null', () async {
        final fake = FakePipelineEnginePort(run: null);
        final launcher = SubPipelineLauncher()..engine = fake;

        final result = await launcher.startChild(
          'tpl-child',
          workspaceId: 'ws-1',
          parentPipelineRunId: 'parent-run',
          parentStepId: 'step-a',
        );

        expect(result, isNull);
      });

      test('forwards templateId as first positional argument', () async {
        final fake = FakePipelineEnginePort();
        final launcher = SubPipelineLauncher()..engine = fake;

        await launcher.startChild(
          'tpl-42',
          workspaceId: 'ws-1',
          parentPipelineRunId: 'parent-run',
          parentStepId: 'step-a',
        );

        expect(fake.capturedTemplateId, 'tpl-42');
      });

      test('forwards workspaceId', () async {
        final fake = FakePipelineEnginePort();
        final launcher = SubPipelineLauncher()..engine = fake;

        await launcher.startChild(
          'tpl-1',
          workspaceId: 'ws-custom',
          parentPipelineRunId: 'parent-run',
          parentStepId: 'step-a',
        );

        expect(fake.capturedWorkspaceId, 'ws-custom');
      });

      test('forwards triggerPayload when provided', () async {
        final fake = FakePipelineEnginePort();
        final launcher = SubPipelineLauncher()..engine = fake;
        const payload = {'issue': 123, 'action': 'opened'};

        await launcher.startChild(
          'tpl-1',
          workspaceId: 'ws-1',
          triggerPayload: payload,
          parentPipelineRunId: 'parent-run',
          parentStepId: 'step-a',
        );

        expect(fake.capturedTriggerPayload, payload);
      });

      test('forwards null triggerPayload when omitted', () async {
        final fake = FakePipelineEnginePort();
        final launcher = SubPipelineLauncher()..engine = fake;

        await launcher.startChild(
          'tpl-1',
          workspaceId: 'ws-1',
          parentPipelineRunId: 'parent-run',
          parentStepId: 'step-a',
        );

        expect(fake.capturedTriggerPayload, isNull);
      });

      test('forwards parentPipelineRunId', () async {
        final fake = FakePipelineEnginePort();
        final launcher = SubPipelineLauncher()..engine = fake;

        await launcher.startChild(
          'tpl-1',
          workspaceId: 'ws-1',
          parentPipelineRunId: 'parent-run-abc',
          parentStepId: 'step-x',
        );

        expect(fake.capturedParentPipelineRunId, 'parent-run-abc');
      });

      test('forwards parentStepId', () async {
        final fake = FakePipelineEnginePort();
        final launcher = SubPipelineLauncher()..engine = fake;

        await launcher.startChild(
          'tpl-1',
          workspaceId: 'ws-1',
          parentPipelineRunId: 'parent-run',
          parentStepId: 'step-zeta',
        );

        expect(fake.capturedParentStepId, 'step-zeta');
      });

      test('forwards dryRun = true', () async {
        final fake = FakePipelineEnginePort();
        final launcher = SubPipelineLauncher()..engine = fake;

        await launcher.startChild(
          'tpl-1',
          workspaceId: 'ws-1',
          parentPipelineRunId: 'parent-run',
          parentStepId: 'step-a',
          dryRun: true,
        );

        expect(fake.capturedDryRun, isTrue);
      });

      test('dryRun defaults to false when omitted', () async {
        final fake = FakePipelineEnginePort();
        final launcher = SubPipelineLauncher()..engine = fake;

        await launcher.startChild(
          'tpl-1',
          workspaceId: 'ws-1',
          parentPipelineRunId: 'parent-run',
          parentStepId: 'step-a',
        );

        expect(fake.capturedDryRun, isFalse);
      });

      test('all parameters forwarded together in a single call', () async {
        final fake = FakePipelineEnginePort();
        final launcher = SubPipelineLauncher()..engine = fake;
        const payload = {'ref': 'main'};

        await launcher.startChild(
          'tpl-complete',
          workspaceId: 'ws-complete',
          triggerPayload: payload,
          parentPipelineRunId: 'parent-complete',
          parentStepId: 'step-complete',
          dryRun: true,
        );

        expect(fake.capturedTemplateId, 'tpl-complete');
        expect(fake.capturedWorkspaceId, 'ws-complete');
        expect(fake.capturedTriggerPayload, payload);
        expect(fake.capturedParentPipelineRunId, 'parent-complete');
        expect(fake.capturedParentStepId, 'step-complete');
        expect(fake.capturedDryRun, isTrue);
      });
    });

    // -------------------------------------------------------------------------
    // engine setter
    // -------------------------------------------------------------------------
    group('engine field', () {
      test('is null by default', () {
        final launcher = SubPipelineLauncher();
        expect(launcher.engine, isNull);
      });

      test('can be set and read back', () {
        final fake = FakePipelineEnginePort();
        final launcher = SubPipelineLauncher()..engine = fake;

        expect(launcher.engine, same(fake));
      });

      test('can be cleared back to null', () {
        final fake = FakePipelineEnginePort();
        final launcher = SubPipelineLauncher()
          ..engine = fake
          ..engine = null;

        expect(launcher.engine, isNull);
      });
    });
  });
}
