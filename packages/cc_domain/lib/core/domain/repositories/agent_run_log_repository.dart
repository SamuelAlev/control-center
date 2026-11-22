import 'package:cc_domain/core/domain/entities/agent_run_log.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_reader.dart';
import 'package:cc_domain/core/domain/value_objects/run_cost.dart';

/// The server's run log: every read a client makes ([AgentRunLogReader]),
/// the host-only reads of the liveness jobs and ticket reconciliation, and
/// every write. Implemented by the server's store; a client binds only
/// [AgentRunLogReader].
abstract class AgentRunLogRepository implements AgentRunLogReader {
  /// Runs that have not finished (pending or running) in every workspace,
  /// newest first, bounded per workspace.
  ///
  /// CROSS-WORKSPACE BY DESIGN — for the liveness jobs (the orphan-run
  /// reaper, process detection), which are defined over every workspace and
  /// only ever inspect runs still in flight. The status filter runs in the
  /// store; nothing reads finished history to find these.
  Future<List<AgentRunLog>> nonTerminal();

  /// The most recently started run for [ticketId] in [workspaceId], or null
  /// when the ticket has never been dispatched. Carries the run's payload.
  Future<AgentRunLog?> latestForTicket(String workspaceId, String ticketId);

  /// Point-in-time companion to [watchActiveByConversation]: the active run
  /// logs right now. Used by server-side one-shot decisions (the steering
  /// queue's "is anyone still working here" check) that would otherwise
  /// subscribe-and-cancel on every call.
  Future<List<AgentRunLog>> activeByConversation(
    String workspaceId,
    String conversationId,
  ) async => await watchActiveByConversation(workspaceId, conversationId).first;

  /// Upserts [log]. The workspace comes from [AgentRunLog.workspaceId]; a run
  /// log with no workspace cannot be stored and is rejected.
  ///
  /// A payload field that is null on [log] keeps its stored value, so a run
  /// read from a list can be written back without erasing its payload.
  Future<void> upsert(AgentRunLog log);

  /// Updates only this run's own usage and timing; never writes descendant cost
  /// or terminal/metadata fields. A missing run in this workspace is a no-op.
  Future<void> updateCost(String workspaceId, String runId, RunCost cost);

  /// Adds exact descendant spend in micro-dollars atomically.
  /// A missing run in this workspace is a no-op.
  Future<void> addChildCostMicros(
    String workspaceId,
    String runId,
    int amountMicros,
  );

  /// Writes only explicitly supplied runtime/observability columns. Returns
  /// false for a missing row, an empty update, or a rejected [markRunning]
  /// transition. Only pending, nonterminal rows can become running.
  Future<bool> updateRuntime(
    String workspaceId,
    String runId, {
    int? pid,
    bool markRunning = false,
    String? logPath,
    String? contextSnapshotJson,
    DateTime? lastOutputAt,
    RunLiveness? liveness,
    RunErrorFamily? errorFamily,
    String? summary,
    String? modelId,
    String? effort,
    String? taskFamily,
  });

  /// Conditionally stamps a terminal run using only terminal/observability
  /// columns. Returns false if this run was missing or already terminal.
  /// [writeCost] is false when the caller has no final usage report: a separate
  /// in-flight [updateCost] must not be replaced by a stale run snapshot.
  Future<bool> completeIfActive(AgentRunLog completed, {bool writeCost = true});
}
