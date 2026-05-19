import 'package:cc_data/src/repositories/remote_agent_run_log_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/ports/run_transcript_relay_port.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/core/domain/value_objects/agent_run_role.dart';
import 'package:cc_domain/core/domain/value_objects/output_contract_mode.dart';
import 'package:cc_domain/core/domain/value_objects/retry_meta.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update_codec.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// An [AgentRunLogRepository] backed by the RPC client — the thin-client data
/// path.
///
/// Implements the domain interface over the host's `agent_run_log.*` ops + the
/// `agent_run_log.watchByAgent` / `agent_run_log.watchActiveByConversation` /
/// `agent_run_log.watchAll` subscriptions, mapping the [AgentRunLogDto] wire
/// shape back to [AgentRunLog]. The host owns persistence; this client never
/// touches a database. Reads, watches and the direct upsert row write are
/// served.
class RpcAgentRunLogRepository
    implements AgentRunLogRepository, RunTranscriptRelayPort {
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
    spaceId: d.spaceId,
    startedAt: DateTime.parse(d.startedAt),
    completedAt: d.completedAt == null ? null : DateTime.parse(d.completedAt!),
    status: _runStatusByName[d.status] ?? RunStatus.pending,
    summary: d.summary,
    adapter: d.adapter,
    modelId: d.modelId,
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
    liveness: d.liveness == null ? null : _runLivenessByName[d.liveness],
    errorFamily: d.errorFamily == null
        ? null
        : _runErrorFamilyByName[d.errorFamily],
    lastOutputAt: d.lastOutputAt == null
        ? null
        : DateTime.parse(d.lastOutputAt!),
    continuationSummary: d.continuationSummary,
    contextSnapshotJson: d.contextSnapshotJson,
    pipelineRunId: d.pipelineRunId,
    pipelineStepId: d.pipelineStepId,
    errorCode: d.errorCode,
    expectedOutputSchema: d.expectedOutputSchema,
    outputContractMode: OutputContractMode.fromStorage(d.outputContractMode),
    outputJson: d.outputJson,
    outputRejections: d.outputRejections,
    retry: RetryMeta(parentRunId: d.retryOfRunId, attempt: d.retryAttempt),
    role: AgentRunRole.tryParse(d.agentRole),
    childCostCents: d.childCostCents,
    parentRunId: d.parentRunId,
    spawnToolCallId: d.spawnToolCallId,
  );

  static AgentRunLogDto _toDto(AgentRunLog l) => AgentRunLogDto(
    id: l.id,
    agentId: l.agentId,
    workspaceId: l.workspaceId,
    conversationId: l.conversationId,
    ticketId: l.ticketId,
    spaceId: l.spaceId,
    startedAt: l.startedAt.toIso8601String(),
    completedAt: l.completedAt?.toIso8601String(),
    status: l.status.name,
    summary: l.summary,
    adapter: l.adapter,
    modelId: l.modelId,
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
    pipelineStepId: l.pipelineStepId,
    errorCode: l.errorCode,
    expectedOutputSchema: l.expectedOutputSchema,
    outputContractMode: l.outputContractMode.toStorageString(),
    outputJson: l.outputJson,
    outputRejections: l.outputRejections,
    retryOfRunId: l.retry.parentRunId,
    retryAttempt: l.retry.attempt,
    agentRole: l.role.name,
    childCostCents: l.childCostCents,
    parentRunId: l.parentRunId,
    spawnToolCallId: l.spawnToolCallId,
  );

  @override
  Stream<List<AgentRunLog>> watchByAgent(String workspaceId, String agentId) =>
      _remote
          .watchByAgent(workspaceId, agentId)
          .map((dtos) => dtos.map(_fromDto).toList());

  @override
  @override
  Future<List<AgentRunLog>> activeByConversation(
    String workspaceId,
    String conversationId,
  ) async => await watchActiveByConversation(workspaceId, conversationId).first;

  @override
  Stream<List<AgentRunLog>> watchActiveByConversation(
    String workspaceId,
    String conversationId,
  ) => _remote
      .watchActiveByConversation(workspaceId, conversationId)
      .map((dtos) => dtos.map(_fromDto).toList());

  @override
  Stream<List<AgentRunLog>> watchActiveBySpace(
    String workspaceId,
    String spaceId,
  ) => _remote
      .watchActiveBySpace(workspaceId, spaceId)
      .map((dtos) => dtos.map(_fromDto).toList());

  @override
  Stream<List<AgentRunLog>> watchByConversation(
    String workspaceId,
    String conversationId,
  ) => _remote
      .watchByConversation(workspaceId, conversationId)
      .map((dtos) => dtos.map(_fromDto).toList());

  @override
  Stream<List<AgentRunLog>> watchBySpace(String workspaceId, String spaceId) =>
      _remote
          .watchBySpace(workspaceId, spaceId)
          .map((dtos) => dtos.map(_fromDto).toList());

  @override
  Stream<List<AgentRunLog>> watchAll() =>
      _remote.watchAll().map((dtos) => dtos.map(_fromDto).toList());

  @override
  Stream<List<AgentRunLog>> watchRecent(int limit) =>
      _remote.watchRecent(limit).map((dtos) => dtos.map(_fromDto).toList());

  @override
  Future<List<AgentRunLog>> forPipelineRun(
    String workspaceId,
    String pipelineRunId,
  ) async {
    final dtos = await _remote.forPipelineRun(workspaceId, pipelineRunId);
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<List<AgentRunLog>> forPipelineStep(
    String workspaceId,
    String pipelineRunId,
    String pipelineStepId,
  ) async {
    final dtos = await _remote.forPipelineStep(
      workspaceId,
      pipelineRunId,
      pipelineStepId,
    );
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<AgentRunLog?> getById(String workspaceId, String id) async {
    try {
      final dto = await _remote.get(workspaceId, id);
      return dto == null ? null : _fromDto(dto);
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.notFound) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<AgentRunLog?> activeRunForAgent(
    String workspaceId,
    String agentId,
  ) async {
    final dto = await _remote.activeRunForAgent(workspaceId, agentId);
    return dto == null ? null : _fromDto(dto);
  }

  @override
  Future<void> upsert(AgentRunLog log) => _remote.upsert(_toDto(log));

  // ---- RunTranscriptRelayPort ----
  //
  // The same class serves both, exactly as `RpcMessagingRepository` also
  // implements `SpaceTurnRelayPort`: one RPC client, one place that knows the
  // `agent_run_log.*` wire shapes. Only the READ side lives here — the server
  // that runs the agent loop owns every transcript write.

  @override
  Stream<RunTranscriptEvent> watchRunTranscript(String runId) => _remote
      .watchRunTranscript(runId)
      .map(runTranscriptEventFromWire)
      .where((e) => e != null)
      .cast<RunTranscriptEvent>();

  @override
  Future<List<TranscriptSegment>> fetchRunTranscript(String runId) async {
    try {
      final data = await _remote.getTranscript(runId);
      return decodeTranscript(data['segments']);
    } on RemoteRpcException catch (e) {
      // A server that does not serve the op at all is a different situation
      // from a run with nothing recorded — surface it so the UI can say so.
      if (e.code == RpcErrorCodes.opUnknown) {
        throw const RunActivityUnsupportedException();
      }
      // A run that vanished genuinely has nothing to show.
      if (e.code == RpcErrorCodes.notFound) {
        return const [];
      }
      rethrow;
    }
  }
}

// Enum name→value lookups, built ONCE.
//
// `EnumType.values.asNameMap()` ALLOCATES A NEW MAP on every call, and
// these run per field per row per emission — the delta path re-maps a whole
// table on every frame, so a single ticket change built four fresh maps per
// ticket in the workspace.
final Map<String, RunErrorFamily> _runErrorFamilyByName = RunErrorFamily.values
    .asNameMap();
final Map<String, RunLiveness> _runLivenessByName = RunLiveness.values
    .asNameMap();
final Map<String, RunStatus> _runStatusByName = RunStatus.values.asNameMap();
