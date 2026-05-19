import 'dart:convert';

import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/orchestration_revision.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/playbook.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads/mutates the Plan Studio surface (PRD 17) over the RPC client.
///
/// Backs the web build and the desktop in remote mode. The workspace is bound
/// server-side, so no `workspace_id` travels on the wire — the host injects
/// the authoritative one and enforces ownership. Mirrors the
/// `orchestration.*` (revision/partial-approval), `plan.*` and `playbook.*`
/// ops + their watch queries in the host catalog. Parses wire maps straight
/// into the shipped domain entities (no separate DTO layer — the entities own
/// their JSON codecs).
class RemotePlanStudioRepository {
  /// Creates a [RemotePlanStudioRepository] over [_client].
  RemotePlanStudioRepository(this._client);

  final RemoteRpcClient _client;

  // ── Revisions (PRD 17 §5) ──

  /// The append-only revision history of [orchestrationId], oldest first.
  Future<List<OrchestrationRevision>> revisions(String orchestrationId) async {
    final data = await _client.call('orchestration.revisions', {
      'orchestration_id': orchestrationId,
    });
    return _revisions(data);
  }

  /// Live revision history, oldest first.
  Stream<List<OrchestrationRevision>> watchRevisions(String orchestrationId) =>
      _client
          .subscribe('orchestration.watchRevisions', {
            'orchestration_id': orchestrationId,
          })
          .map(_revisions);

  /// Saves an operator-edited proposal as a new revision. Throws a
  /// [RemoteRpcException] with a "plan moved on" message when [baseRevision]
  /// is stale (optimistic concurrency).
  Future<void> saveRevision({
    required String orchestrationId,
    required OrchestrationProposal proposal,
    required int baseRevision,
  }) => _client.call('orchestration.saveRevision', {
    'orchestration_id': orchestrationId,
    'proposal_json': proposal.toJsonString(),
    'base_revision': baseRevision,
  });

  // ── Approval (PRD 17 §4) ──

  /// Approves an orchestration. When [approvedNodeKeys] is non-null, only
  /// those nodes (which must be dependency-closed — enforced server-side)
  /// execute; the rest materialize behind suspended approval gates.
  Future<void> approve(
    String orchestrationId, {
    Set<String>? approvedNodeKeys,
  }) => _client.call('orchestration.approve', {
    'orchestration_id': orchestrationId,
    if (approvedNodeKeys != null)
      'approved_node_keys': approvedNodeKeys.toList(),
  });

  /// Widens an executing partial approval, resuming the newly approved nodes'
  /// gates.
  Future<void> approveNodes(String orchestrationId, Set<String> nodeKeys) =>
      _client.call('orchestration.approveNodes', {
        'orchestration_id': orchestrationId,
        'node_keys': nodeKeys.toList(),
      });

  /// Cancels an orchestration.
  Future<void> cancel(String orchestrationId) => _client.call(
    'orchestration.cancel',
    {'orchestration_id': orchestrationId},
  );

  // ── Estimate (PRD 17 §3) ──

  /// Computes + persists per-node estimates for an orchestration, returning
  /// the raw estimate payload (`nodes`, totals, budget, flags).
  Future<Map<String, dynamic>> estimateOrchestration(
    String orchestrationId,
  ) async {
    final data = await _client.call('plan.estimate', {
      'orchestration_id': orchestrationId,
    });
    return (data['estimate'] as Map?)?.cast<String, dynamic>() ?? const {};
  }

  /// Computes + persists per-node estimates for a plan document.
  Future<Map<String, dynamic>> estimatePlan(String planId) async {
    final data = await _client.call('plan.estimate', {'plan_id': planId});
    return (data['estimate'] as Map?)?.cast<String, dynamic>() ?? const {};
  }

  // ── Plan drift (PRD 17 §6) ──

  /// The divergence markers for an orchestration (`{nodeKey: {reasons, at,
  /// held}}`).
  Future<Map<String, dynamic>> divergence(String orchestrationId) async {
    final data = await _client.call('orchestration.divergence', {
      'orchestration_id': orchestrationId,
    });
    return (data['markers'] as Map?)?.cast<String, dynamic>() ?? const {};
  }

  /// Resumes a node held by the stop-and-ask drift policy.
  Future<void> continueNode(String orchestrationId, String nodeKey) =>
      _client.call('orchestration.continueNode', {
        'orchestration_id': orchestrationId,
        'node_key': nodeKey,
      });

  // ── Plan-mode documents (PRD 17 §8) ──

  /// Live plan documents for the workspace, newest first.
  Stream<List<PlanDocument>> watchPlanDocuments() =>
      _client.subscribe('plan.watchForWorkspace', const {}).map(_plans);

  /// Live single plan document by id.
  Stream<PlanDocument?> watchPlanById(String planId) => _client
      .subscribe('plan.watchById', {'plan_id': planId})
      .map((d) => _plan(d['plan']));

  /// A plan document by id, or null.
  Future<PlanDocument?> getPlan(String planId) async {
    final data = await _client.call('plan.getById', {'plan_id': planId});
    return _plan(data['plan']);
  }

  /// Approves a plan document (compiles + materializes the same way an
  /// orchestration approval does). Returns the created orchestration id.
  Future<String> approvePlan(
    String planId, {
    Set<String>? approvedNodeKeys,
    int? maxCostCents,
  }) async {
    final data = await _client.call('plan.approve', {
      'plan_id': planId,
      if (approvedNodeKeys != null)
        'approved_node_keys': approvedNodeKeys.toList(),
      'max_cost_cents': ?maxCostCents,
    });
    return data['orchestration_id'] as String? ?? '';
  }

  /// Sets a plan document's status (e.g. reject).
  Future<void> updatePlanStatus(String planId, PlanDocumentStatus status) =>
      _client.call('plan.updateStatus', {
        'plan_id': planId,
        'status': status.name,
      });

  /// Deletes a plan document.
  Future<void> deletePlan(String planId) =>
      _client.call('plan.delete', {'plan_id': planId});

  // ── Playbooks (PRD 17 §10) ──

  /// Live playbooks for the workspace, by name.
  Stream<List<Playbook>> watchPlaybooks() =>
      _client.subscribe('playbook.watchForWorkspace', const {}).map(_playbooks);

  /// A playbook by id, or null.
  Future<Playbook?> getPlaybook(String playbookId) async {
    final data = await _client.call('playbook.getById', {
      'playbook_id': playbookId,
    });
    return _playbook(data['playbook']);
  }

  /// Saves (creates or version-bumps) a playbook.
  Future<Playbook?> savePlaybook(Playbook playbook) async {
    final data = await _client.call('playbook.save', {
      'playbook': _playbookToWire(playbook),
    });
    return _playbook(data['playbook']);
  }

  /// Deletes a playbook.
  Future<void> deletePlaybook(String playbookId) =>
      _client.call('playbook.delete', {'playbook_id': playbookId});

  /// Instantiates + proposes a playbook run against [ticketId]. Returns the
  /// propose result (`orchestration_id`, `revision`, `status`, `message`).
  Future<Map<String, dynamic>> runPlaybook({
    required String playbookId,
    required String ticketId,
    required Map<String, String> args,
  }) => _client.call('playbook.run', {
    'playbook_id': playbookId,
    'ticket_id': ticketId,
    'args': args,
  });

  // ── Parsers ──

  List<OrchestrationRevision> _revisions(Map<String, dynamic> data) =>
      ((data['revisions'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => _revision(m.cast<String, dynamic>()))
          .toList();

  OrchestrationRevision _revision(Map<String, dynamic> w) =>
      OrchestrationRevision(
        id: w['id'] as String,
        workspaceId: w['workspace_id'] as String? ?? '',
        orchestrationId: w['orchestration_id'] as String? ?? '',
        revision: (w['revision'] as num?)?.toInt() ?? 1,
        proposal: OrchestrationProposal.fromJsonString(
          w['proposal_json'] as String? ?? '{}',
        ),
        authoredBy: w['authored_by'] as String? ?? 'unknown',
        authorKind: w['author_kind'] as String? ?? 'user',
        createdAt:
            DateTime.tryParse(w['created_at'] as String? ?? '') ??
            DateTime.fromMillisecondsSinceEpoch(0),
      );

  List<PlanDocument> _plans(Map<String, dynamic> data) =>
      ((data['plans'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => _planFromWire(m.cast<String, dynamic>()))
          .toList();

  PlanDocument? _plan(Object? raw) =>
      raw is Map ? _planFromWire(raw.cast<String, dynamic>()) : null;

  PlanDocument _planFromWire(Map<String, dynamic> w) => PlanDocument.fromBody(
    id: w['id'] as String,
    workspaceId: w['workspace_id'] as String? ?? '',
    conversationId: w['conversation_id'] as String? ?? '',
    agentId: w['agent_id'] as String? ?? '',
    body: _decodeBody(w['plan_json'] as String? ?? '{}'),
    status: PlanDocumentStatus.fromName(w['status'] as String?),
    revision: (w['revision'] as num?)?.toInt() ?? 1,
    createdAt:
        DateTime.tryParse(w['created_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt:
        DateTime.tryParse(w['updated_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  List<Playbook> _playbooks(Map<String, dynamic> data) =>
      ((data['playbooks'] as List?) ?? const [])
          .whereType<Map>()
          .map((m) => _playbookFromWire(m.cast<String, dynamic>()))
          .toList();

  Playbook? _playbook(Object? raw) =>
      raw is Map ? _playbookFromWire(raw.cast<String, dynamic>()) : null;

  Playbook _playbookFromWire(Map<String, dynamic> w) => Playbook(
    id: w['id'] as String,
    workspaceId: w['workspace_id'] as String? ?? '',
    name: w['name'] as String? ?? '',
    description: w['description'] as String? ?? '',
    params: Playbook.paramsFromJsonString(w['params_json'] as String? ?? '[]'),
    sourceProposal: OrchestrationProposal.fromJsonString(
      w['source_proposal_json'] as String? ?? '{}',
    ),
    version: (w['version'] as num?)?.toInt() ?? 1,
    createdAt:
        DateTime.tryParse(w['created_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
    updatedAt:
        DateTime.tryParse(w['updated_at'] as String? ?? '') ??
        DateTime.fromMillisecondsSinceEpoch(0),
  );

  Map<String, dynamic> _playbookToWire(Playbook p) => {
    'id': p.id,
    'workspace_id': p.workspaceId,
    'name': p.name,
    'description': p.description,
    'params_json': p.paramsToJsonString(),
    'source_proposal_json': p.sourceProposal.toJsonString(),
    'version': p.version,
  };

  Map<String, dynamic> _decodeBody(String raw) {
    try {
      final map = jsonDecode(raw);
      return map is Map<String, dynamic> ? map : const {};
    } catch (_) {
      return const {};
    }
  }
}
