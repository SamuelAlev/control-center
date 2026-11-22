import 'dart:convert';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/logging/cc_domain_log.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_domain/features/pipelines/domain/entities/step_result.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_context.dart';
import 'package:cc_domain/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:cc_domain/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:uuid/uuid.dart';

/// How many times an orchestration body re-reads an orchestration whose run
/// is not recorded yet, [kOrchestrationRunRecordStep] apart: the approval
/// records the run id right after the engine started the run, and the run's
/// first step may get here before that write.
const int kOrchestrationRunRecordAttempts = 50;

/// The pause between those reads.
const Duration kOrchestrationRunRecordStep = Duration(milliseconds: 100);

/// The orchestration named by the step's `orchestration_id`, when this run
/// is that orchestration's run (`pipeline_run_id`), else the step's failure
/// message. `orchestration_id` comes from the run's state or its trigger
/// payload, which a member's own run can set: an orchestration body acts
/// only for the orchestration's own run, never for another run that names
/// it.
Future<(Orchestration?, String?)> _orchestrationOfRun(
  PipelineContext ctx,
  OrchestrationRepository orchestrations,
  String body,
) async {
  final orchestrationId = ctx.optional<String>('orchestration_id');
  if (orchestrationId == null || orchestrationId.isEmpty) {
    return (null, '$body: missing orchestration_id');
  }
  for (var attempt = 1; ; attempt++) {
    final orchestration = await orchestrations.getById(
      ctx.workspaceId,
      orchestrationId,
    );
    if (orchestration == null) {
      return (null, '$body: orchestration not found in this workspace');
    }
    final runId = orchestration.pipelineRunId;
    if (runId == ctx.pipelineRunId) {
      return (orchestration, null);
    }
    if (runId != null || attempt >= kOrchestrationRunRecordAttempts) {
      return (null, '$body: this run is not the orchestration\'s run');
    }
    await Future<void>.delayed(kOrchestrationRunRecordStep);
  }
}

/// Registers the deterministic `orchestration.*` bodies used by generated
/// orchestration pipelines. No LLM in these bodies — they reconcile state and
/// persist the canonical record, and only for the orchestration whose run
/// this is ([_orchestrationOfRun]).
void registerOrchestrationBodies(
  PipelineBodyRegistry registry, {
  required OrchestrationRepository orchestrations,
  required TicketWorkflowService ticketWorkflow,
  required MessagingRepository messaging,
  required DomainEventBus eventBus,
}) {
  const uuid = Uuid();

  // orchestration.markPhase — the work-DAG join. Writes a `{failed:true}`
  // sentinel for every sub-ticket that produced no `out_<key>` (so downstream
  // `{{out_<key>}}` placeholders always resolve and the synthesis step can
  // cover gaps), records `failed_inputs` and flips the orchestration to
  // `synthesizing`.
  registry.registerBody(BuiltInBodyKeys.orchestrationMarkPhase, (ctx) async {
    final (orchestration, refusal) = await _orchestrationOfRun(
      ctx,
      orchestrations,
      'orchestration.markPhase',
    );
    if (orchestration == null) {
      return StepResult.failed(refusal!);
    }
    final mutated = <String, dynamic>{};
    final failed = <String>[];
    for (final t in orchestration.proposal.subTickets) {
      final key = 'out_${t.key}';
      final value = ctx.state[key];
      if (value == null) {
        mutated[key] = {'failed': true, 'key': t.key};
        failed.add(t.key);
      } else if (value is Map && value['failed'] == true) {
        // The engine's continueOnFail marker: already resolvable downstream,
        // but still a gap the synthesis step must cover.
        failed.add(t.key);
      }
    }
    mutated['failed_inputs'] = failed;

    await orchestrations.change(
      ctx.workspaceId,
      orchestration.id,
      (current) => current.status == OrchestrationStatus.executing
          ? current.copyWith(
              status: OrchestrationStatus.synthesizing,
              updatedAt: DateTime.now(),
            )
          : null,
    );
    return StepResult.ok(mutatedState: mutated);
  });

  // orchestration.awaitApproval — the partial-approval gate (PRD 17 §4).
  // Completes immediately once its node key is in the orchestration's
  // approved set; otherwise suspends. `approveNodes` releases the gate via
  // `PipelineEngine.resumeStep` and any crash-recovery re-run of this body
  // re-reads the approved set from the row, so both paths agree.
  registry.registerBody(BuiltInBodyKeys.orchestrationAwaitApproval, (
    ctx,
  ) async {
    final nodeKey = ctx.optional<String>('node_key');
    if (nodeKey == null || nodeKey.isEmpty) {
      return StepResult.failed(
        'orchestration.awaitApproval: missing orchestration_id/node_key',
      );
    }
    final (orchestration, refusal) = await _orchestrationOfRun(
      ctx,
      orchestrations,
      'orchestration.awaitApproval',
    );
    if (orchestration == null) {
      return StepResult.failed(refusal!);
    }
    if (orchestration.isNodeApproved(nodeKey)) {
      return StepResult.ok();
    }
    return StepResult.suspendUntilEvent('orchestration.nodeApproved');
  });

  // orchestration.persistDeliverable — writes the synthesis output to the
  // parent ticket, completes it, posts the deliverable and marks the
  // orchestration completed. Idempotent: re-running after a crash skips when
  // the orchestration is already completed.
  registry.registerBody(BuiltInBodyKeys.orchestrationPersistDeliverable, (
    ctx,
  ) async {
    final (orchestration, refusal) = await _orchestrationOfRun(
      ctx,
      orchestrations,
      'orchestration.persistDeliverable',
    );
    if (orchestration == null) {
      return StepResult.failed(refusal!);
    }
    if (orchestration.status == OrchestrationStatus.completed) {
      return StepResult.ok(
        mutatedState: const {'orchestration_completed': true},
      );
    }

    final deliverableRaw = ctx.state['deliverable'];
    final deliverable = deliverableRaw is Map<String, dynamic>
        ? deliverableRaw
        : <String, dynamic>{'result': deliverableRaw};
    final now = DateTime.now();
    final parentTicketId = orchestration.parentTicketId;

    if (parentTicketId != null && parentTicketId.isNotEmpty) {
      await ticketWorkflow.completeTicket(
        parentTicketId,
        workspaceId: ctx.workspaceId,
        force: true,
      );
    }

    final spaceId = orchestration.spaceId;
    if (spaceId != null && spaceId.isNotEmpty) {
      await messaging.sendMessage(
        workspaceId: ctx.workspaceId,
        spaceId: spaceId,
        content: _renderDeliverable(orchestration.proposal.goal, deliverable),
        senderId: orchestration.orchestratorAgentId ?? 'system',
        senderType: orchestration.orchestratorAgentId == null
            ? 'system'
            : 'agent',
        messageType: 'text',
        id: uuid.v4(),
      );
      await messaging.sendMessage(
        workspaceId: ctx.workspaceId,
        spaceId: spaceId,
        content: 'Orchestration completed — deliverable posted to the ticket.',
        senderId: 'system',
        senderType: 'system',
        messageType: 'system',
        id: uuid.v4(),
      );
    }

    await orchestrations.change(
      ctx.workspaceId,
      orchestration.id,
      (current) => current.status == OrchestrationStatus.completed
          ? null
          : current.copyWith(
              status: OrchestrationStatus.completed,
              completedAt: now,
              updatedAt: now,
            ),
    );

    CcDomainLog.info(
      'orchestration.persistDeliverable: Completed orchestration ${orchestration.id}',
    );
    return StepResult.ok(mutatedState: const {'orchestration_completed': true});
  });
}

String _renderDeliverable(String goal, Map<String, dynamic> deliverable) {
  final buf = StringBuffer()..writeln('## Deliverable — $goal');
  deliverable.forEach((key, value) {
    buf.writeln();
    buf.writeln('### $key');
    if (value is String) {
      buf.writeln(value);
    } else if (value is List) {
      for (final item in value) {
        buf.writeln('- $item');
      }
    } else {
      buf.writeln('```json');
      buf.writeln(const JsonEncoder.withIndent('  ').convert(value));
      buf.writeln('```');
    }
  });
  return buf.toString();
}
