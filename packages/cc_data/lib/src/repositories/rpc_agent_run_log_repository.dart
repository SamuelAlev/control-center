import 'package:cc_data/src/repositories/remote_agent_run_log_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/retry_meta.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// An [AgentRunLogRepository] backed by the RPC client — the thin-client data
/// path.
///
/// Implements the domain interface over the host's `agent_run_log.*` ops + the
/// `agent_run_log.watchByAgent` / `agent_run_log.watchActiveByConversation` /
/// `agent_run_log.watchAll` subscriptions, mapping the [AgentRunLogDto] wire
/// shape back to [AgentRunLog]. The host owns persistence; this client never
/// touches a database. Reads, watches, and the direct upsert row write are
/// served.
class RpcAgentRunLogRepository implements AgentRunLogRepository {
  /// Creates an [RpcAgentRunLogRepository] over [client].
  RpcAgentRunLogRepository(RemoteRpcClient client)
    : _remote = RemoteAgentRunLogRepository(client);

  final RemoteAgentRunLogRepository _remote;

  /// Rebuilds an [AgentRunLog] from its wire DTO. Enum fields are encoded as
  /// `.name`; timestamps are ISO-8601 strings.
  static AgentRunLog _fromDto(AgentRunLogDto d) => AgentRunLog(
    id: d.id,
    agentId: d.agentId,
    workspaceId: d.workspaceId,
    conversationId: d.conversationId,
    ticketId: d.ticketId,
    channelId: d.channelId,
    startedAt: DateTime.parse(d.startedAt),
    completedAt: d.completedAt == null ? null : DateTime.parse(d.completedAt!),
    status: RunStatus.values.asNameMap()[d.status] ?? RunStatus.pending,
    summary: d.summary,
    adapter: d.adapter,
    pid: d.pid,
    logPath: d.logPath,
    cost: RunCost(
      inputTokens: d.inputTokens,
      outputTokens: d.outputTokens,
      thoughtTokens: d.thoughtTokens,
      cachedReadTokens: d.cachedReadTokens,
      cachedWriteTokens: d.cachedWriteTokens,
      estimatedCostCents: d.estimatedCostCents,
      durationMs: d.durationMs,
      timeToFirstTokenMs: d.timeToFirstTokenMs,
    ),
    liveness: d.liveness == null
        ? null
        : RunLiveness.values.asNameMap()[d.liveness],
    errorFamily: d.errorFamily == null
        ? null
        : RunErrorFamily.values.asNameMap()[d.errorFamily],
    lastOutputAt: d.lastOutputAt == null
        ? null
        : DateTime.parse(d.lastOutputAt!),
    continuationSummary: d.continuationSummary,
    contextSnapshotJson: d.contextSnapshotJson,
    pipelineRunId: d.pipelineRunId,
    pipelineStepRunId: d.pipelineStepRunId,
    errorCode: d.errorCode,
    expectedOutputSchema: d.expectedOutputSchema,
    outputContractMode: OutputContractMode.fromStorage(d.outputContractMode),
    outputJson: d.outputJson,
    outputRejections: d.outputRejections,
    retry: RetryMeta(
      parentRunId: d.retryOfRunId,
      attempt: d.retryAttempt,
    ),
  );

  static AgentRunLogDto _toDto(AgentRunLog l) => AgentRunLogDto(
    id: l.id,
    agentId: l.agentId,
    workspaceId: l.workspaceId,
    conversationId: l.conversationId,
    ticketId: l.ticketId,
    channelId: l.channelId,
    startedAt: l.startedAt.toIso8601String(),
    completedAt: l.completedAt?.toIso8601String(),
    status: l.status.name,
    summary: l.summary,
    adapter: l.adapter,
    pid: l.pid,
    logPath: l.logPath,
    inputTokens: l.cost.inputTokens,
    outputTokens: l.cost.outputTokens,
    thoughtTokens: l.cost.thoughtTokens,
    cachedReadTokens: l.cost.cachedReadTokens,
    cachedWriteTokens: l.cost.cachedWriteTokens,
    estimatedCostCents: l.cost.estimatedCostCents,
    durationMs: l.cost.durationMs,
    timeToFirstTokenMs: l.cost.timeToFirstTokenMs,
    liveness: l.liveness?.name,
    errorFamily: l.errorFamily?.name,
    lastOutputAt: l.lastOutputAt?.toIso8601String(),
    continuationSummary: l.continuationSummary,
    contextSnapshotJson: l.contextSnapshotJson,
    pipelineRunId: l.pipelineRunId,
    pipelineStepRunId: l.pipelineStepRunId,
    errorCode: l.errorCode,
    expectedOutputSchema: l.expectedOutputSchema,
    outputContractMode: l.outputContractMode.toStorageString(),
    outputJson: l.outputJson,
    outputRejections: l.outputRejections,
    retryOfRunId: l.retry.parentRunId,
    retryAttempt: l.retry.attempt,
  );

  @override
  Stream<List<AgentRunLog>> watchByAgent(String workspaceId, String agentId) =>
      _remote
          .watchByAgent(agentId)
          .map((dtos) => dtos.map(_fromDto).toList());

  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  ) => _remote
      .watchActiveByConversation(conversationId)
      .map((dtos) => dtos.map(_fromDto).toList());

  @override
  Stream<List<AgentRunLog>> watchAll() =>
      _remote.watchAll().map((dtos) => dtos.map(_fromDto).toList());

  @override
  Future<List<AgentRunLog>> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async {
    final dtos = await _remote.forPipelineRun(pipelineRunId);
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<List<AgentRunLog>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) async {
    final dtos = await _remote.forPipelineStep(pipelineRunId, pipelineStepId);
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<AgentRunLog?> getById(String id) async {
    try {
      final dto = await _remote.get(id);
      return dto == null ? null : _fromDto(dto);
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.notFound) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<AgentRunLog?> activeRunForAgent(String agentId) async {
    final dto = await _remote.activeRunForAgent(agentId);
    return dto == null ? null : _fromDto(dto);
  }

  @override
  Future<void> upsert(AgentRunLog log) => _remote.upsert(_toDto(log));
}
