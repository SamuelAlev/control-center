import 'dart:async';

import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/pipeline_events.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_run_repository.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_engine.dart';

/// Listens for child-run completion and resumes the parent `flow.callPipeline`
/// step. Mirrors `TaskResumeListener` but for sub-pipeline composition.
class SubPipelineResumeListener {
  /// Creates a [SubPipelineResumeListener].
  SubPipelineResumeListener({
    required this.eventBus,
    required this.engine,
    required this.repository,
  });

  /// Bus carrying pipeline lifecycle events.
  final DomainEventBus eventBus;

  /// Engine to resume the parent step on.
  final PipelineEngine engine;

  /// Run repository to look up the completed child run + its parent link.
  final PipelineRunRepository repository;

  StreamSubscription<DomainEvent>? _sub;

  /// Starts listening.
  void start() {
    _sub = eventBus.on<DomainEvent>().listen(_onEvent);
  }

  Future<void> _onEvent(DomainEvent event) async {
    final runId = switch (event) {
      PipelineRunCompleted() => event.pipelineRunId,
      PipelineRunFailed() => event.pipelineRunId,
      _ => null,
    };
    if (runId == null) {
      return;
    }
    try {
      final child = await repository.getRun(runId);
      final parentRunId = child?.parentPipelineRunId;
      final parentStepId = child?.parentStepId;
      if (child == null || parentRunId == null || parentStepId == null) {
        return;
      }
      await engine.resumeChildFlow(
        parentRunId: parentRunId,
        parentStepId: parentStepId,
        childRun: child,
      );
    } on Object catch (e, st) {
      AppLog.e('SubPipelineResumeListener', 'resume failed', e, st);
    }
  }

  /// Stops listening.
  void dispose() {
    _sub?.cancel();
  }
}
