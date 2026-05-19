import 'package:control_center/features/pipelines/domain/entities/step_result.dart';
import 'package:control_center/features/pipelines/domain/ports/ticket_workflow_port.dart';
import 'package:control_center/features/pipelines/domain/repositories/pipeline_template_repository.dart';
import 'package:control_center/features/pipelines/domain/services/pipeline_body_registry.dart';
import 'package:control_center/features/pipelines/domain/services/template_renderer.dart';
import 'package:control_center/features/pipelines/domain/templates/builtin_template_seeds.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_priority.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket_provider.dart';

/// Registers the `pipeline.createTicket` body — files a ticket from pipeline
/// state through the vendor-agnostic [TicketWorkflowPort] (used by
/// escalation flows like `ci_autofix`).
///
/// Config: `extras.title` (template, default the node label), the `prompt`
/// field is the description template, optional `extras.priority` (int 0-4),
/// optional `extras.teamId` (passed to the remote provider via provider
/// extras). The created ticket id/key/url is written to `outputKey`.
void registerCreateTicketBody(
  PipelineBodyRegistry registry, {
  required PipelineTemplateRepository templateRepository,
  required TicketWorkflowPort ticketWorkflow,
  required TicketProvider provider,
}) {
  const renderer = TemplateRenderer();

  registry.registerBody(BuiltInBodyKeys.createTicket, (ctx) async {
    final workspaceId = ctx.workspaceId;
    final def = await templateRepository.getById(workspaceId, ctx.templateId);
    final config = def?.step(ctx.stepId)?.config;
    if (config == null) {
      return StepResult.failed(
        'createTicket: step "${ctx.stepId}" missing config',
      );
    }

    final title = renderer
        .render(
          (config.extras['title'] as String?) ??
              config.label ??
              'Automated ticket',
          state: ctx.renderState,
          trigger: ctx.triggerPayload,
        )
        .text;
    final description = renderer
        .render(config.prompt ?? '',
            state: ctx.renderState, trigger: ctx.triggerPayload)
        .text;
    final priority =
        TicketPriority.fromStorage((config.extras['priority'] as num?)?.toInt());
    final teamId = config.extras['teamId'] as String?;

    if (ctx.dryRun) {
      return StepResult.ok(mutatedState: {
        if (config.outputKey != null)
          config.outputKey!: {'dryRun': true, 'title': title},
      });
    }

    final ticket = await ticketWorkflow.createTicket(
      workspaceId: workspaceId,
      title: title,
      description: description,
      provider: provider,
      priority: priority,
      providerExtras: {
        if (teamId != null && teamId.isNotEmpty) 'teamId': teamId,
      },
    );

    return StepResult.ok(mutatedState: {
      if (config.outputKey != null)
        config.outputKey!: {
          'id': ticket.id,
          'key': ticket.displayKey,
          if (ticket.url != null) 'url': ticket.url,
        },
    });
  });
}
