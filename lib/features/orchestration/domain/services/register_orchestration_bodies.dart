import 'dart:convert';

import 'package:control_center/core/domain/events/domain_event_bus.dart';
import 'package:control_center/core/domain/events/orchestration_events.dart';
import 'package:control_center/core/utils/app_log.dart';
import 'package:control_center/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:control_center/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:control_center/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:control_center/features/pipelines/domain/entities/step_result.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:control_center/features/ticketing/domain/services/ticket_workflow_service.dart';
import 'package:uuid/uuid.dart';

/// Registers the deterministic `orchestration.*` bodies used by generated
/// orchestration pipelines. No LLM in these bodies — they reconcile state and
/// persist the canonical record.
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
  // cover gaps), records `failed_inputs`, and flips the orchestration to
  // `synthesizing`.
  registry.registerBody(BuiltInBodyKeys.orchestrationMarkPhase, (ctx) async {
    final orchestrationId = ctx.optional<String>('orchestrationId');
    if (orchestrationId == null || orchestrationId.isEmpty) {
      return StepResult.failed('orchestration.markPhase: missing orchestrationId');
    }
    final orchestration =
        await orchestrations.getById(ctx.workspaceId, orchestrationId);
    if (orchestration == null) {
      return StepResult.failed(
        'orchestration.markPhase: orchestration not found in this workspace',
      );
    }
    final mutated = <String, dynamic>{};
    final failed = <String>[];
    for (final t in orchestration.proposal.subTickets) {
      final key = 'out_${t.key}';
      if (ctx.state[key] == null) {
        mutated[key] = {'failed': true, 'key': t.key};
        failed.add(t.key);
      }
    }
    mutated['failed_inputs'] = failed;

    if (orchestration.status == OrchestrationStatus.executing) {
      await orchestrations.update(
        orchestration.copyWith(
          status: OrchestrationStatus.synthesizing,
          updatedAt: DateTime.now(),
        ),
      );
    }
    return StepResult.ok(mutatedState: mutated);
  });

  // orchestration.persistDeliverable — writes the synthesis output to the
  // parent ticket, completes it, posts the deliverable, and marks the
  // orchestration completed. Idempotent: re-running after a crash skips when
  // the orchestration is already completed.
  registry.registerBody(BuiltInBodyKeys.orchestrationPersistDeliverable,
      (ctx) async {
    final orchestrationId = ctx.optional<String>('orchestrationId');
    if (orchestrationId == null || orchestrationId.isEmpty) {
      return StepResult.failed(
        'orchestration.persistDeliverable: missing orchestrationId',
      );
    }
    final orchestration =
        await orchestrations.getById(ctx.workspaceId, orchestrationId);
    if (orchestration == null) {
      return StepResult.failed(
        'orchestration.persistDeliverable: orchestration not found',
      );
    }
    if (orchestration.status == OrchestrationStatus.completed) {
      return StepResult.ok(mutatedState: const {'orchestrationCompleted': true});
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
        output: deliverable,
        force: true,
      );
    }

    final channelId = orchestration.channelId;
    if (channelId != null && channelId.isNotEmpty) {
      await messaging.sendMessage(
        channelId: channelId,
        content: _renderDeliverable(orchestration.proposal.goal, deliverable),
        senderId: orchestration.orchestratorAgentId ?? 'system',
        senderType: 'agent',
        messageType: 'text',
        id: uuid.v4(),
      );
      await messaging.sendMessage(
        channelId: channelId,
        content: 'Orchestration completed — deliverable posted to the ticket.',
        senderId: 'system',
        senderType: 'agent',
        messageType: 'system',
        id: uuid.v4(),
      );
    }

    await orchestrations.update(
      orchestration.copyWith(
        status: OrchestrationStatus.completed,
        completedAt: now,
        updatedAt: now,
      ),
    );
    eventBus.publish(OrchestrationCompleted(
      orchestrationId: orchestration.id,
      workspaceId: ctx.workspaceId,
      occurredAt: now,
    ));

    AppLog.i('orchestration.persistDeliverable',
        'Completed orchestration ${orchestration.id}');
    return StepResult.ok(mutatedState: const {'orchestrationCompleted': true});
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
