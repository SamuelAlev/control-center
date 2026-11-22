import 'package:cc_data/src/wire_decode.dart';
import 'package:cc_domain/features/dispatch/domain/entities/agent_goal_run.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/goal_run_view.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_goal_status.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_contract.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_hold.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_pipeline_link.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_start_refs.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_unattended_policy.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/goal_verification.dart';
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
  spaceId: w['space_id'] as String? ?? '',
  conversationId: w['conversation_id'] as String? ?? '',
  agentId: w['agent_id'] as String? ?? '',
  userText: w['user_text'] as String? ?? '',
  status: AgentGoalStatusWire.fromWire(w['status'] as String?),
  deadlineAt: _parseOptionalDate(w['deadline_at']),
  costCapMicros: (w['cost_cap_micros'] as num?)?.toInt() ?? 1,
  costMicros: (w['cost_micros'] as num?)?.toInt() ?? 0,
  maxRuns: (w['max_runs'] as num?)?.toInt(),
  runCount: (w['run_count'] as num?)?.toInt() ?? 0,
  activeRunId: w['active_run_id'] as String?,
  consecutiveFailures: (w['consecutive_failures'] as num?)?.toInt() ?? 0,
  requestedByUserId: w['requested_by_user_id'] as String?,
  summary: w['summary'] as String?,
  // The verification state decodes leniently: a field a newer or older server
  // shapes differently reads as absent rather than dropping the goal.
  contract: GoalContract.tryFromJson(w['contract']),
  hold: GoalHoldWire.tryParse(w['hold'] as String?),
  holdUntil: _parseOptionalDate(w['hold_until']),
  holdDetail: _clip(w['hold_detail'], AgentGoalRun.maxHoldDetailLength),
  noProgressStreak: _count(w['no_progress_streak']),
  verificationRounds: _count(w['verification_rounds']),
  lastFingerprint: w['last_fingerprint'] as String?,
  lastActivityDigest: _digest(w['last_activity_digest']),
  startRefs: GoalStartRefs.tryFromJson(w['start_ref']),
  parkCount: _count(w['park_count']),
  fresh: w['fresh'] == true,
  unattended:
      GoalUnattendedPolicyWire.tryParse(w['unattended'] as String?) ??
      GoalUnattendedPolicy.wait,
  checkerAgentId: _nonEmpty(w['checker_agent_id']),
  verification: GoalVerification.tryFromJson(w['verification']),
  pipeline: GoalPipelineLink.tryOf(
    w['pipeline_run_id'] as String?,
    w['pipeline_step_id'] as String?,
  ),
  createdAt: _parseDate(w['created_at']),
  updatedAt: _parseDate(w['updated_at']),
);

/// One goal on the wire as this viewer sees it: the goal and the server's
/// `can_resume` and `can_approve` for the caller (absent reads as false: a
/// control the server would refuse is never offered).
GoalRunView _goalRunViewFromWire(Map<String, dynamic> w) => GoalRunView(
  goal: _agentGoalRunFromWire(w),
  canResume: w['can_resume'] == true,
  canApprove: w['can_approve'] == true,
);

int _count(Object? raw) => raw is num && raw >= 0 ? raw.toInt() : 0;

String? _nonEmpty(Object? raw) => raw is String && raw.isNotEmpty ? raw : null;

/// A digest the entity would refuse (empty, or longer than its limit) reads
/// as absent: a clipped digest would compare as changed work.
String? _digest(Object? raw) =>
    raw is String &&
        raw.isNotEmpty &&
        raw.length <= AgentGoalRun.maxActivityDigestLength
    ? raw
    : null;

String? _clip(Object? raw, int max) => raw is! String
    ? null
    : raw.length <= max
    ? raw
    : raw.substring(0, max);

List<Map<String, dynamic>> _maps(Object? raw) => ((raw as List?) ?? const [])
    .whereType<Map>()
    .map((m) => m.cast<String, dynamic>())
    .toList();

/// The client read/control surface for durable supervised goals
/// ([AgentGoalRun], `/goal`) over the `agentGoalRuns.*` RPC ops.
///
/// Standalone adapter, NOT an `AgentGoalRunRepository`: the domain port's
/// methods (`getById`, `listByWorkspace`, `upsert`, …) exist for the host's
/// supervisor and its SQLite store — no wire ops expose them and the thin
/// client never writes goal rows directly. What the client owns is the live
/// watches, one goal's read, the three instantaneous control mutations
/// (pause / resume / cancel), a person's close of a goal in review
/// (approve completion) and, while a goal is paused, its contract and
/// checker; every other state transition (completion, budget walls) happens
/// server-side. Every goal comes back as a [GoalRunView]: the goal plus the
/// server's per-caller `can_resume`.
class RpcAgentGoalRunRepository {
  /// Creates an [RpcAgentGoalRunRepository] over the given client.
  RpcAgentGoalRunRepository(this._client);

  final RemoteRpcClient _client;

  /// Watches every durable goal in [workspaceId], newest first.
  Stream<List<GoalRunView>> watchForWorkspace(String workspaceId) => _client
      .subscribe('agentGoalRuns.watchForWorkspace', {
        'workspace_id': workspaceId,
      })
      .map(
        (data) => decodeRows(
          _maps(data['goals']),
          _goalRunViewFromWire,
          what: 'agent goal run',
        ),
      );

  /// Watches the durable goals of one conversation in [workspaceId], streamed
  /// live over RPC (`agentGoalRuns.watchForConversation`).
  Stream<List<GoalRunView>> watchForConversation(
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
          _goalRunViewFromWire,
          what: 'agent goal run',
        ),
      );

  /// Pauses the goal; no further runs are dispatched until resumed.
  Future<void> pauseGoal(String workspaceId, String goalId) => _client.call(
    'agentGoalRuns.pause',
    {'workspace_id': workspaceId, 'goal_id': goalId},
  );

  /// Resumes a paused goal. A `budgetExhausted` goal resumes only by
  /// raising the budget: pass [raiseCostCapMicros] above the spend that
  /// tripped the cap.
  Future<void> resumeGoal(
    String workspaceId,
    String goalId, {
    int? raiseCostCapMicros,
  }) => _client.call('agentGoalRuns.resume', {
    'workspace_id': workspaceId,
    'goal_id': goalId,
    'raise_cost_cap_micros': ?raiseCostCapMicros,
  });

  /// Cancels the goal permanently (NOT reversible).
  Future<void> cancelGoal(String workspaceId, String goalId) => _client.call(
    'agentGoalRuns.cancel',
    {'workspace_id': workspaceId, 'goal_id': goalId},
  );

  /// One goal of [workspaceId] (`agentGoalRuns.get`); the server refuses a
  /// goal of a space the caller may not read.
  Future<GoalRunView> getGoal(String workspaceId, String goalId) async {
    final data = await _client.call('agentGoalRuns.get', {
      'workspace_id': workspaceId,
      'goal_id': goalId,
    });
    return _goalOf(data);
  }

  /// Replaces a paused goal's contract (what done means), or clears it with
  /// null. Refused with `goal_not_paused` unless the goal is paused and
  /// `goal_contract_invalid` for a contract past its limits. Returns the
  /// goal as written.
  Future<GoalRunView> setContract(
    String workspaceId,
    String goalId,
    GoalContract? contract,
  ) async {
    final data = await _client.call('agentGoalRuns.setContract', {
      'workspace_id': workspaceId,
      'goal_id': goalId,
      'contract': contract?.toJson(),
    });
    return _goalOf(data);
  }

  /// Sets a paused goal's checker, the agent that reviews its completion
  /// claim, or clears it with null (the goal's own agent reviews then).
  /// Refused with `goal_not_paused`, `goal_checker_unknown` or
  /// `goal_checker_is_goal_agent`. Returns the goal as written.
  Future<GoalRunView> setChecker(
    String workspaceId,
    String goalId,
    String? checkerAgentId,
  ) async {
    final data = await _client.call('agentGoalRuns.setChecker', {
      'workspace_id': workspaceId,
      'goal_id': goalId,
      'checker_agent_id': checkerAgentId,
    });
    return _goalOf(data);
  }

  /// Closes a goal that waits for review (`paused`, hold `needs_review`) as
  /// done, on a person's word and without a passing verification
  /// (`agentGoalRuns.approveCompletion`). Refused with `goal_not_in_review`
  /// for a goal in any other state. Returns the closed goal.
  Future<GoalRunView> approveCompletion(
    String workspaceId,
    String goalId,
  ) async {
    final data = await _client.call('agentGoalRuns.approveCompletion', {
      'workspace_id': workspaceId,
      'goal_id': goalId,
    });
    return _goalOf(data);
  }

  static GoalRunView _goalOf(Map<String, dynamic> data) {
    final goal = data['goal'];
    if (goal is! Map) {
      throw const FormatException('the server sent no goal');
    }
    return _goalRunViewFromWire(goal.cast<String, dynamic>());
  }
}
