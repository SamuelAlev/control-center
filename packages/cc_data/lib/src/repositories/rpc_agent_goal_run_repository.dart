import 'package:cc_data/src/wire_decode.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_rpc/cc_rpc.dart';

DateTime _parseDate(Object? raw) => switch (raw) {
  String() => DateTime.parse(raw),
  num() => DateTime.fromMillisecondsSinceEpoch(raw.toInt()),
  _ => DateTime.fromMillisecondsSinceEpoch(0),
};

DateTime? _parseOptionalDate(Object? raw) =>
    raw == null ? null : _parseDate(raw);

AgentGoalRun _agentGoalRunFromWire(Map<String, dynamic> w) => AgentGoalRun(
  id: w['id'] as String,
  workspaceId: w['workspace_id'] as String? ?? '',
  channelId: w['channel_id'] as String? ?? '',
  conversationId: w['conversation_id'] as String? ?? '',
  agentId: w['agent_id'] as String? ?? '',
  userText: w['user_text'] as String? ?? '',
  kind: AgentGoalKindWire.fromWire(w['kind'] as String?),
  status: AgentGoalStatusWire.fromWire(w['status'] as String?),
  deadlineAt: _parseOptionalDate(w['deadline_at']),
  costCapCents: (w['cost_cap_cents'] as num?)?.toInt() ?? 1,
  costCents: (w['cost_cents'] as num?)?.toInt() ?? 0,
  maxRuns: (w['max_runs'] as num?)?.toInt(),
  runCount: (w['run_count'] as num?)?.toInt() ?? 0,
  activeRunId: w['active_run_id'] as String?,
  consecutiveFailures: (w['consecutive_failures'] as num?)?.toInt() ?? 0,
  requestedByUserId: w['requested_by_user_id'] as String?,
  summary: w['summary'] as String?,
  createdAt: _parseDate(w['created_at']),
  updatedAt: _parseDate(w['updated_at']),
);

List<Map<String, dynamic>> _maps(Object? raw) => ((raw as List?) ?? const [])
    .whereType<Map>()
    .map((m) => m.cast<String, dynamic>())
    .toList();

/// The client read/control surface for durable supervised goals
/// ([AgentGoalRun] — `/goal` + `/loop`) over the `agentGoalRuns.*` RPC ops.
///
/// Standalone adapter, NOT an `AgentGoalRunRepository`: the domain port's
/// methods (`getById`, `listByWorkspace`, `upsert`, …) exist for the host's
/// supervisor and its SQLite store — no wire ops expose them and the thin
/// client never writes goal rows directly. What the client owns is the live
/// per-conversation watch plus the three instantaneous control mutations
/// (pause / resume / cancel); every other state transition (completion,
/// budget walls) happens server-side.
class RpcAgentGoalRunRepository {
  /// Creates an [RpcAgentGoalRunRepository] over the given client.
  RpcAgentGoalRunRepository(this._client);

  final RemoteRpcClient _client;

  /// Watches the durable goals of one conversation in [workspaceId], streamed
  /// live over RPC (`agentGoalRuns.watchForConversation`).
  Stream<List<AgentGoalRun>> watchForConversation(
    String workspaceId,
    String conversationId,
  ) => _client
      .subscribe('agentGoalRuns.watchForConversation', {
        'workspace_id': workspaceId,
        'conversation_id': conversationId,
      })
      .map(
        (data) => decodeRows(
          _maps(data['goals']),
          _agentGoalRunFromWire,
          what: 'agent goal run',
        ),
      );

  /// Pauses the goal; no further runs are dispatched until resumed.
  Future<void> pauseGoal(String workspaceId, String goalId) => _client.call(
    'agentGoalRuns.pause',
    {'workspace_id': workspaceId, 'goal_id': goalId},
  );

  /// Resumes a paused goal. A `budgetExhausted` goal resumes only by
  /// raising the budget: pass [raiseCostCapCents] above the spend that
  /// tripped the cap.
  Future<void> resumeGoal(
    String workspaceId,
    String goalId, {
    int? raiseCostCapCents,
  }) => _client.call('agentGoalRuns.resume', {
    'workspace_id': workspaceId,
    'goal_id': goalId,
    'raise_cost_cap_cents': ?raiseCostCapCents,
  });

  /// Cancels the goal permanently (NOT reversible).
  Future<void> cancelGoal(String workspaceId, String goalId) => _client.call(
    'agentGoalRuns.cancel',
    {'workspace_id': workspaceId, 'goal_id': goalId},
  );
}
