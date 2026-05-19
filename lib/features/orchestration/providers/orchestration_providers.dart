import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/orchestration/data/repositories/dao_orchestration_repository.dart';
import 'package:control_center/features/orchestration/domain/entities/orchestration.dart';
import 'package:control_center/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:control_center/features/orchestration/domain/services/orchestration_proposal_validator.dart';
import 'package:control_center/features/orchestration/domain/services/orchestration_run_listener.dart';
import 'package:control_center/features/orchestration/domain/services/register_orchestration_bodies.dart';
import 'package:control_center/features/orchestration/domain/usecases/approve_orchestration_use_case.dart';
import 'package:control_center/features/orchestration/domain/usecases/cancel_orchestration_use_case.dart';
import 'package:control_center/features/pipelines/providers/pipeline_providers.dart';
import 'package:control_center/features/teams/providers/team_providers.dart';
import 'package:control_center/features/ticketing/domain/entities/ticket.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Binds the [OrchestrationRepository] to its Drift implementation.
final orchestrationRepositoryProvider = Provider<OrchestrationRepository>(
  (ref) => DaoOrchestrationRepository(ref.watch(orchestrationDaoProvider)),
);

/// Provides the deterministic proposal validator, wired to the shared schema
/// validator so declared output schemas are checked for well-formedness.
final orchestrationProposalValidatorProvider =
    Provider<OrchestrationProposalValidator>(
  (ref) => OrchestrationProposalValidator(
    schemaValidator: ref.watch(schemaValidatorProvider),
  ),
);

/// Watches a single orchestration by id within [workspaceId].
final orchestrationProvider =
    StreamProvider.family<Orchestration?, ({String workspaceId, String id})>(
  (ref, args) => ref
      .watch(orchestrationRepositoryProvider)
      .watchById(args.workspaceId, args.id),
);

/// Watches all orchestrations in a workspace, newest first.
final workspaceOrchestrationsProvider =
    StreamProvider.family<List<Orchestration>, String>(
  (ref, workspaceId) => ref
      .watch(orchestrationRepositoryProvider)
      .watchForWorkspace(workspaceId),
);

/// Live child sub-tickets of an orchestration's parent ticket (for in-bubble
/// progress). Derived from the workspace ticket stream filtered by parent.
final orchestrationChildTicketsProvider = StreamProvider.family<List<Ticket>,
    ({String workspaceId, String parentTicketId})>(
  (ref, args) => ref
      .watch(ticketRepositoryProvider)
      .watchForWorkspace(args.workspaceId)
      .map((tickets) => tickets
          .where((t) => t.parentTicketId == args.parentTicketId)
          .toList()),
);

/// Deterministic approval → materialization use case.
final approveOrchestrationUseCaseProvider =
    Provider<ApproveOrchestrationUseCase>((ref) {
  return ApproveOrchestrationUseCase(
    orchestrations: ref.watch(orchestrationRepositoryProvider),
    hireAgent: ref.watch(hireAgentUseCaseProvider),
    teams: ref.watch(teamRepositoryProvider),
    projects: ref.watch(projectServiceProvider),
    ticketWorkflow: ref.watch(ticketWorkflowServiceProvider),
    templates: ref.watch(pipelineTemplateRepositoryProvider),
    engine: ref.watch(pipelineEngineProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
});

/// User-facing cancellation use case.
final cancelOrchestrationUseCaseProvider =
    Provider<CancelOrchestrationUseCase>((ref) {
  return CancelOrchestrationUseCase(
    orchestrations: ref.watch(orchestrationRepositoryProvider),
    engine: ref.watch(pipelineEngineProvider),
    ticketWorkflow: ref.watch(ticketWorkflowServiceProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
});

/// Registers the deterministic `orchestration.*` pipeline bodies into the
/// shared body registry. Read once at startup (orchestration → pipelines is an
/// allowed feature dependency; the reverse would be a cycle).
final orchestrationBodiesProvider = Provider<void>((ref) {
  registerOrchestrationBodies(
    ref.watch(pipelineBodyRegistryProvider),
    orchestrations: ref.watch(orchestrationRepositoryProvider),
    ticketWorkflow: ref.watch(ticketWorkflowServiceProvider),
    messaging: ref.watch(messagingRepositoryProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
});

/// Keep-alive listener that maps generated-pipeline terminal states onto the
/// orchestration + parent ticket.
final orchestrationRunListenerProvider =
    Provider<OrchestrationRunListener>((ref) {
  final listener = OrchestrationRunListener(
    eventBus: ref.watch(domainEventBusProvider),
    orchestrations: ref.watch(orchestrationRepositoryProvider),
    ticketWorkflow: ref.watch(ticketWorkflowServiceProvider),
  )..start();
  ref.onDispose(listener.dispose);
  return listener;
});
