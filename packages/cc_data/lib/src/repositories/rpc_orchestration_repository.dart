import 'package:cc_data/src/repositories/remote_orchestration_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/entities/orchestration_status.dart';
import 'package:cc_domain/features/orchestration/domain/repositories/orchestration_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// An [OrchestrationRepository] backed by the RPC client — the thin-client data
/// path.
///
/// Implements the domain interface over the host's `orchestration.*` ops + the
/// `orchestration.watchForWorkspace` / `orchestration.watchById`
/// subscriptions, mapping the [OrchestrationDto] wire shape back to
/// [Orchestration]. The host owns persistence and enforces workspace ownership;
/// this client never touches a database. The required `workspaceId` arguments
/// are bound server-side, so they are dropped from the wire calls.
class RpcOrchestrationRepository implements OrchestrationRepository {
  /// Creates an [RpcOrchestrationRepository] over [client].
  RpcOrchestrationRepository(RemoteRpcClient client)
    : _remote = RemoteOrchestrationRepository(client);

  final RemoteOrchestrationRepository _remote;

  /// Rebuilds an [Orchestration] from its wire DTO. The proposal travels as a
  /// JSON string; status is a `.name`; timestamps are ISO-8601 strings.
  static Orchestration _fromDto(OrchestrationDto d) => Orchestration(
    id: d.id,
    workspaceId: d.workspaceId,
    proposal: OrchestrationProposal.fromJsonString(d.proposalJson),
    parentTicketId: d.parentTicketId,
    channelId: d.channelId,
    orchestratorAgentId: d.orchestratorAgentId,
    status: OrchestrationStatus.fromStorage(d.status),
    revision: d.revision,
    approvedRevision: d.approvedRevision,
    pipelineTemplateId: d.pipelineTemplateId,
    pipelineRunId: d.pipelineRunId,
    teamId: d.teamId,
    projectId: d.projectId,
    estimatedCostCents: d.estimatedCostCents,
    maxCostCents: d.maxCostCents,
    hiredAgentIds: d.hiredAgentIds,
    errorMessage: d.errorMessage,
    createdAt: DateTime.parse(d.createdAt),
    updatedAt: DateTime.parse(d.updatedAt),
    completedAt: d.completedAt == null ? null : DateTime.parse(d.completedAt!),
  );

  static OrchestrationDto _toDto(Orchestration o) => OrchestrationDto(
    id: o.id,
    workspaceId: o.workspaceId,
    proposalJson: o.proposal.toJsonString(),
    parentTicketId: o.parentTicketId,
    channelId: o.channelId,
    orchestratorAgentId: o.orchestratorAgentId,
    status: o.status.toStorageString(),
    revision: o.revision,
    approvedRevision: o.approvedRevision,
    pipelineTemplateId: o.pipelineTemplateId,
    pipelineRunId: o.pipelineRunId,
    teamId: o.teamId,
    projectId: o.projectId,
    estimatedCostCents: o.estimatedCostCents,
    maxCostCents: o.maxCostCents,
    hiredAgentIds: o.hiredAgentIds,
    errorMessage: o.errorMessage,
    createdAt: o.createdAt.toIso8601String(),
    updatedAt: o.updatedAt.toIso8601String(),
    completedAt: o.completedAt?.toIso8601String(),
  );

  @override
  Future<void> insert(Orchestration orchestration) =>
      _remote.insert(_toDto(orchestration));

  @override
  Future<void> update(Orchestration orchestration) =>
      _remote.update(_toDto(orchestration));

  @override
  Future<Orchestration?> getById(String workspaceId, String id) async {
    final dto = await _remote.getById(id);
    return dto == null ? null : _fromDto(dto);
  }

  @override
  Future<Orchestration?> forParentTicket(
    String workspaceId,
    String ticketId,
  ) async {
    final dto = await _remote.forParentTicket(ticketId);
    return dto == null ? null : _fromDto(dto);
  }

  @override
  Future<Orchestration?> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async {
    final dto = await _remote.forPipelineRun(pipelineRunId);
    return dto == null ? null : _fromDto(dto);
  }

  @override
  Future<Orchestration?> forPipelineRunAnyWorkspace(
    String pipelineRunId,
  ) async {
    final dto = await _remote.forPipelineRunAnyWorkspace(pipelineRunId);
    return dto == null ? null : _fromDto(dto);
  }

  @override
  Future<List<Orchestration>> approvedNeedingMaterialization() async {
    final dtos = await _remote.approvedNeedingMaterialization();
    return dtos.map(_fromDto).toList();
  }

  @override
  Stream<List<Orchestration>> watchForWorkspace(String workspaceId) =>
      _remote.watchForWorkspace().map((dtos) => dtos.map(_fromDto).toList());

  @override
  Stream<Orchestration?> watchById(String workspaceId, String id) =>
      _remote.watchById(id).map((dto) => dto == null ? null : _fromDto(dto));
}
