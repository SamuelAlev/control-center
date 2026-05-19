import 'package:cc_data/src/wire_decode.dart';
import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_domain/features/governance/domain/entities/approval.dart';
import 'package:cc_domain/features/governance/domain/entities/approval_comment.dart';
import 'package:cc_domain/features/governance/domain/entities/org_goal.dart';
import 'package:cc_domain/features/governance/domain/repositories/approval_repository.dart';
import 'package:cc_domain/features/governance/domain/repositories/goal_repository.dart';
import 'package:cc_domain/features/governance/domain/value_objects/agent_presence.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_kind.dart';
import 'package:cc_domain/features/governance/domain/value_objects/approval_status.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_goal_level.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_goal_status.dart';
import 'package:cc_rpc/cc_rpc.dart';

// Governance (PRD 09) read surface over RPC — the thin-client data path for the
// goal hierarchy, board approvals + their comment threads and computed agent
// presence. These adapters parse the server's wire maps (the `*ToWire` shapes
// in `remote_rpc_catalog.dart`) straight into the domain types. The host owns
// persistence + the decision/heartbeat state machines, so every WRITE method
// throws — writes flow through the governance MCP tools server-side, never here.

DateTime _parseDate(Object? iso) => iso is String
    ? DateTime.parse(iso)
    : DateTime.fromMillisecondsSinceEpoch(0);

OrgGoal _goalFromWire(Map<String, dynamic> w) => OrgGoal(
  id: w['id'] as String,
  workspaceId: w['workspace_id'] as String? ?? '',
  title: w['title'] as String? ?? '',
  level: OrgGoalLevel.fromStorage(w['level'] as String?),
  parentGoalId: w['parent_goal_id'] as String?,
  description: w['description'] as String?,
  status: OrgGoalStatus.fromStorage(w['status'] as String?),
  ownerAgentId: w['owner_agent_id'] as String?,
  teamId: w['team_id'] as String?,
  targetTicketId: w['target_ticket_id'] as String?,
  progress: (w['progress'] as num?)?.toInt() ?? 0,
  createdAt: _parseDate(w['created_at']),
  updatedAt: _parseDate(w['updated_at']),
);

Approval _approvalFromWire(Map<String, dynamic> w) => Approval(
  id: w['id'] as String,
  workspaceId: w['workspace_id'] as String? ?? '',
  title: w['title'] as String? ?? '',
  description: w['description'] as String?,
  kind: ApprovalKind.fromStorage(w['kind'] as String?),
  status: ApprovalStatus.fromStorage(w['status'] as String?),
  requestedByActorType: w['requested_by_actor_type'] as String? ?? 'agent',
  requestedById: w['requested_by_id'] as String?,
  linkedTicketIds: ((w['linked_ticket_ids'] as List?) ?? const [])
      .map((e) => e.toString())
      .toList(),
  linkedEntityType: w['linked_entity_type'] as String?,
  linkedEntityId: w['linked_entity_id'] as String?,
  decidedByActorType: w['decided_by_actor_type'] as String?,
  decidedById: w['decided_by_id'] as String?,
  decisionReason: w['decision_reason'] as String?,
  createdAt: _parseDate(w['created_at']),
  decidedAt: w['decided_at'] is String
      ? DateTime.parse(w['decided_at'] as String)
      : null,
  updatedAt: _parseDate(w['updated_at']),
);

ApprovalComment _commentFromWire(Map<String, dynamic> w) => ApprovalComment(
  id: w['id'] as String,
  approvalId: w['approval_id'] as String? ?? '',
  workspaceId: w['workspace_id'] as String? ?? '',
  authorType: w['author_type'] as String? ?? 'user',
  authorId: w['author_id'] as String?,
  body: w['body'] as String? ?? '',
  createdAt: _parseDate(w['created_at']),
);

AgentPresence _presenceFromWire(Map<String, dynamic> w) => AgentPresence(
  availability:
      _agentAvailabilityByName[w['availability'] as String?] ??
      AgentAvailability.offline,
  workload: _workloadByName[w['workload'] as String?] ?? Workload.idle,
  runningCount: (w['running_count'] as num?)?.toInt() ?? 0,
  queuedCount: (w['queued_count'] as num?)?.toInt() ?? 0,
  capacity: (w['capacity'] as num?)?.toInt() ?? 0,
);

List<Map<String, dynamic>> _maps(Object? raw) => ((raw as List?) ?? const [])
    .whereType<Map>()
    .map((m) => m.cast<String, dynamic>())
    .toList();

/// A [GoalRepository] backed by the RPC client (read-only).
class RpcGoalRepository implements GoalRepository {
  /// Creates an [RpcGoalRepository] over the given client.
  RpcGoalRepository(this._client);

  final RemoteRpcClient _client;

  @override
  Stream<List<OrgGoal>> watchByWorkspace(String workspaceId) => _client
      .subscribe('goals.watchForWorkspace', {'workspace_id': workspaceId})
      .map(
        (data) =>
            decodeRows(_maps(data['goals']), _goalFromWire, what: 'org goal'),
      );

  @override
  Future<List<OrgGoal>> listByWorkspace(String workspaceId) =>
      watchByWorkspace(workspaceId).first;

  @override
  Future<List<OrgGoal>> childrenOf(
    String workspaceId,
    String parentGoalId,
  ) async {
    final all = await listByWorkspace(workspaceId);
    return all.where((g) => g.parentGoalId == parentGoalId).toList();
  }

  @override
  Future<OrgGoal?> getById(String workspaceId, String id) async {
    try {
      final data = await _client.call('goals.get', {
        'workspace_id': workspaceId,
        'goal_id': id,
      });
      final goal = data['goal'];
      return goal is Map ? _goalFromWire(goal.cast<String, dynamic>()) : null;
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.notFound) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<void> upsert(OrgGoal goal) =>
      throw UnsupportedError('Goals are managed on the server host.');

  @override
  Future<void> delete(String workspaceId, String id) =>
      throw UnsupportedError('Goals are managed on the server host.');
}

/// An [ApprovalRepository] backed by the RPC client (read-only).
class RpcApprovalRepository implements ApprovalRepository {
  /// Creates an [RpcApprovalRepository] over the given client.
  RpcApprovalRepository(this._client);

  final RemoteRpcClient _client;

  @override
  Stream<List<Approval>> watchByWorkspace(String workspaceId) => _client
      .subscribe('approvals.watchForWorkspace', {'workspace_id': workspaceId})
      .map(
        (data) => decodeRows(
          _maps(data['approvals']),
          _approvalFromWire,
          what: 'approval',
        ),
      );

  @override
  Stream<List<Approval>> watchByStatus(String workspaceId, String status) =>
      watchByWorkspace(
        workspaceId,
      ).map((list) => list.where((a) => a.status.storage == status).toList());

  @override
  Future<Approval?> getById(String workspaceId, String id) async {
    try {
      final data = await _client.call('approvals.get', {
        'workspace_id': workspaceId,
        'approval_id': id,
      });
      final approval = data['approval'];
      return approval is Map
          ? _approvalFromWire(approval.cast<String, dynamic>())
          : null;
    } on RemoteRpcException catch (e) {
      if (e.code == RpcErrorCodes.notFound) {
        return null;
      }
      rethrow;
    }
  }

  @override
  Future<List<ApprovalComment>> getComments(
    String workspaceId,
    String approvalId,
  ) async {
    final data = await _client.call('approvals.getComments', {
      'workspace_id': workspaceId,
      'approval_id': approvalId,
    });
    return decodeRows(
      _maps(data['comments']),
      _commentFromWire,
      what: 'approval comment',
    );
  }

  /// The host exposes no comment-stream op, so this emits a single snapshot of
  /// the current thread (the read surface does not require live comment fan-out).
  @override
  Stream<List<ApprovalComment>> watchComments(
    String workspaceId,
    String approvalId,
  ) => Stream.fromFuture(getComments(workspaceId, approvalId));

  @override
  Future<void> upsert(Approval approval) =>
      throw UnsupportedError('Approvals are managed on the server host.');

  @override
  Future<void> delete(String workspaceId, String id) =>
      throw UnsupportedError('Approvals are managed on the server host.');

  @override
  Future<void> addComment(ApprovalComment comment) =>
      throw UnsupportedError('Approvals are managed on the server host.');
}

/// Reads computed agent presence (availability × workload) over RPC, keyed by
/// agent id. Not a domain repository — the host composes presence from several
/// repositories, so the client only reads the result.
class RpcAgentPresenceReader {
  /// Creates an [RpcAgentPresenceReader] over the given client.
  RpcAgentPresenceReader(this._client);

  final RemoteRpcClient _client;

  /// Presence for every agent in [workspaceId], keyed by agent id.
  Future<Map<String, AgentPresence>> presenceForWorkspace(
    String workspaceId,
  ) async {
    final data = await _client.call('agent_presence.forWorkspace', {
      'workspace_id': workspaceId,
    });
    final raw = data['presence'];
    if (raw is! Map) {
      return const {};
    }
    return {
      for (final entry in raw.entries)
        entry.key as String: _presenceFromWire(
          (entry.value as Map).cast<String, dynamic>(),
        ),
    };
  }
}

// Enum name→value lookups, built ONCE.
//
// `EnumType.values.asNameMap()` ALLOCATES A NEW MAP on every call, and
// these run per field per row per emission — the delta path re-maps a whole
// table on every frame, so a single ticket change built four fresh maps per
// ticket in the workspace.
final Map<String, AgentAvailability> _agentAvailabilityByName =
    AgentAvailability.values.asNameMap();
final Map<String, Workload> _workloadByName = Workload.values.asNameMap();
