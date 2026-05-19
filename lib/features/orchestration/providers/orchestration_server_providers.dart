// VM-only orchestration providers (server-side execution half of
// `orchestration_providers.dart`).
//
// Approving an orchestration hires agents, creates teams and starts pipelines;
// cancelling tears the generated run down. Both — plus the deterministic
// `orchestration.*` pipeline bodies and the run→ticket listener — are
// server-side execution that owns the Drift `dao*` repositories and the
// concrete `PipelineEngine` directly (going over RPC would cycle through the
// in-process host). So they live here, imported by the desktop bootstrap, the
// orchestration action seam and the proposal notifier's VM path — never from the
// web graph. The web-safe UI providers (orchestration RPC reads + the proposal
// validator) stay in `orchestration_providers.dart`.
library;

import 'package:cc_domain/features/orchestration/domain/services/orchestration_run_listener.dart';
import 'package:cc_domain/features/orchestration/domain/services/register_orchestration_bodies.dart';
import 'package:cc_domain/features/orchestration/domain/usecases/cancel_orchestration_use_case.dart';
import 'package:cc_infra/src/usecases/approve_orchestration_use_case.dart';
import 'package:control_center/core/providers/event_bus_provider.dart';
import 'package:control_center/di/server_providers.dart';
import 'package:control_center/features/agents/providers/agent_server_providers.dart';
import 'package:control_center/features/pipelines/pipeline_server_providers.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Deterministic approval → materialization use case.
///
/// Server-side execution (hires agents, creates teams, starts pipelines), so it
/// binds the Dao-backed orchestration/team/template repositories directly rather
/// than the RPC ones the UI reads — going over RPC would cycle through
/// `rpcClientProvider`.
final approveOrchestrationUseCaseProvider =
    Provider<ApproveOrchestrationUseCase>((ref) {
  return ApproveOrchestrationUseCase(
    orchestrations: ref.watch(daoOrchestrationRepositoryProvider),
    hireAgent: ref.watch(hireAgentUseCaseProvider),
    teams: ref.watch(daoTeamRepositoryProvider),
    projects: ref.watch(projectServiceProvider),
    ticketWorkflow: ref.watch(ticketWorkflowServiceProvider),
    templates: ref.watch(daoPipelineTemplateRepositoryProvider),
    engine: ref.watch(pipelineEngineServerProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
});

/// User-facing cancellation use case (server-side; Dao-backed orchestration
/// repo — see [approveOrchestrationUseCaseProvider]).
final cancelOrchestrationUseCaseProvider =
    Provider<CancelOrchestrationUseCase>((ref) {
  return CancelOrchestrationUseCase(
    orchestrations: ref.watch(daoOrchestrationRepositoryProvider),
    engine: ref.watch(pipelineEngineServerProvider),
    ticketWorkflow: ref.watch(ticketWorkflowServiceProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
});

/// Registers the deterministic `orchestration.*` pipeline bodies into the
/// shared body registry. Read once at startup (orchestration → pipelines is an
/// allowed feature dependency; the reverse would be a cycle). Server-side
/// execution → Dao-backed orchestration repo.
final orchestrationBodiesProvider = Provider<void>((ref) {
  registerOrchestrationBodies(
    ref.watch(pipelineBodyRegistryProvider),
    orchestrations: ref.watch(daoOrchestrationRepositoryProvider),
    ticketWorkflow: ref.watch(ticketWorkflowServiceProvider),
    // Server-side pipeline-body EXECUTION — owns the DB directly via dao*.
    messaging: ref.watch(daoMessagingRepositoryProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
});

/// Keep-alive listener that maps generated-pipeline terminal states onto the
/// orchestration + parent ticket (server-side; Dao-backed orchestration repo).
final orchestrationRunListenerProvider =
    Provider<OrchestrationRunListener>((ref) {
  final listener = OrchestrationRunListener(
    eventBus: ref.watch(domainEventBusProvider),
    orchestrations: ref.watch(daoOrchestrationRepositoryProvider),
    ticketWorkflow: ref.watch(ticketWorkflowServiceProvider),
  )..start();
  ref.onDispose(listener.dispose);
  return listener;
});
