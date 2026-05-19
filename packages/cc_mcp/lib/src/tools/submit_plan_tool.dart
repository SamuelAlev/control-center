import 'dart:convert';

import 'package:cc_domain/core/domain/events/domain_event_bus.dart';
import 'package:cc_domain/core/domain/events/plan_events.dart';
import 'package:cc_domain/core/domain/repositories/agent_run_log_repository.dart';
import 'package:cc_domain/features/code_graph/domain/repositories/code_graph_repository.dart';
import 'package:cc_domain/features/governance/domain/entities/work_product.dart';
import 'package:cc_domain/features/governance/domain/repositories/work_product_repository.dart';
import 'package:cc_domain/features/governance/domain/services/artifact_document_codec.dart';
import 'package:cc_domain/features/governance/domain/value_objects/artifact_block.dart';
import 'package:cc_domain/features/governance/domain/value_objects/work_product_type.dart';
import 'package:cc_domain/features/mcp/domain/ports/mcp_tool_port.dart';
import 'package:cc_domain/features/messaging/domain/repositories/messaging_repository.dart';
import 'package:cc_domain/features/orchestration/domain/value_objects/plan_annotations.dart';
import 'package:cc_domain/features/plan_studio/domain/entities/plan_document.dart';
import 'package:cc_domain/features/plan_studio/domain/repositories/plan_studio_repositories.dart';
import 'package:cc_domain/features/plan_studio/domain/services/plan_graph_mermaid.dart';
import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';
import 'package:uuid/uuid.dart';

/// The plan-mode output contract (PRD 17 §8): the Planner emits a typed
/// [PlanDocument] instead of prose.
///
/// The conversation + workspace are resolved server-side from the agent's
/// active run (same resolution as `exit_plan_mode`), so a plan can only land
/// in the conversation the agent is actually working in. The graph is
/// validated structurally (unique keys, real deps, acyclic) and violations
/// come back verbatim so the agent self-corrects in the same run. A resubmit
/// supersedes the conversation's previous proposed plan and bumps the
/// revision — the document keeps one live body per conversation.
///
/// A successful submit also posts a typed `plan` message into the conversation
/// and publishes [PlanDocumentSubmitted]. Without those, a submitted plan was
/// invisible from the room it was authored in: the only way to find it was to
/// navigate to Plan Studio and notice a new card. The message carries the plan
/// id only — the bubble watches the row, so `proposed → approved → superseded`
/// re-renders live with no feed churn (the same shape
/// `propose_orchestration` uses).
class SubmitPlanTool extends McpTool {
  /// Creates a [SubmitPlanTool].
  SubmitPlanTool({
    required AgentRunLogRepository runLogRepository,
    required PlanDocumentRepository planDocuments,
    MessagingRepository? messaging,
    DomainEventBus? eventBus,
    WorkProductRepository? workProducts,
    CodeGraphRepository? codeGraph,
  }) : _runLogs = runLogRepository,
       _plans = planDocuments,
       _messaging = messaging,
       _eventBus = eventBus,
       _workProducts = workProducts,
       _codeGraph = codeGraph;

  final AgentRunLogRepository _runLogs;
  final PlanDocumentRepository _plans;

  /// Posts the plan bubble into the authoring conversation. Null skips it (the
  /// plan still lands in Plan Studio, it is just not announced).
  final MessagingRepository? _messaging;

  /// Publishes [PlanDocumentSubmitted]. Null skips it.
  final DomainEventBus? _eventBus;

  /// Snapshots the plan as a versioned work product (PRD 09 §8: "plan artifacts
  /// get a first-class versioned home"). The `PlanDocument` row keeps only the
  /// latest body — revisions are in-place — so without this a superseded plan's
  /// content is gone. Null skips the snapshot; the plan itself is unaffected.
  final WorkProductRepository? _workProducts;

  /// Resolves `symbol` provenance ids to readable names at write time. Null
  /// skips resolution (the chip falls back to the id).
  final CodeGraphRepository? _codeGraph;

  static const _uuid = Uuid();

  @override
  String get name => 'submit_plan';

  @override
  String get description =>
      'Submit your plan as a typed dependency graph (plan mode\'s output '
      'contract). The plan opens in Plan Studio where the operator reviews, '
      'edits, estimates and approves it — execution starts only after '
      'approval. Nodes with no dependencies run in parallel. Cite provenance '
      'on every node (which file/symbol/fact motivated it). After submitting, '
      'STOP and wait; to replace the plan, call submit_plan again.';

  @override
  Map<String, dynamic> get inputSchema => {
    'type': 'object',
    'properties': {
      'workspace_id': {'type': 'string'},
      'agent_id': {
        'type': 'string',
        'description': 'Your own agent id (resolves the active run).',
      },
      'goal': {
        'type': 'string',
        'description': 'What the plan achieves — the ask, restated.',
      },
      'nodes': {
        'type': 'array',
        'description':
            'The work DAG. Each: {key, title, description, dependsOn[], '
            'expectedOutputSchema?, priority?, provenance[]}. provenance '
            'refs: {kind: symbol|file|memory|message|goal|answer, ref, '
            'label?}.',
        'items': {'type': 'object'},
      },
      'clarifications': {
        'type': 'array',
        'description':
            'Clarifying questions you asked and the answers received: '
            '[{question, answer}]. Recorded as provenance.',
        'items': {'type': 'object'},
      },
    },
    'required': ['workspace_id', 'agent_id', 'goal', 'nodes'],
  };

  @override
  Future<CallResult> run(Map<String, dynamic> arguments) async {
    final workspaceId = arguments['workspace_id'];
    if (workspaceId is! String || workspaceId.isEmpty) {
      return CallResult.error('Missing or invalid argument: workspace_id');
    }
    final agentId = arguments['agent_id'];
    if (agentId is! String || agentId.isEmpty) {
      return CallResult.error('Missing or invalid argument: agent_id');
    }
    final goal = arguments['goal'];
    if (goal is! String || goal.trim().isEmpty) {
      return CallResult.error('Missing or invalid argument: goal');
    }

    final run = await _runLogs.activeRunForAgent(workspaceId, agentId);
    if (run == null) {
      return CallResult.error(
        'No active run found for agent $agentId — submit_plan applies to the '
        'conversation your current run is working in.',
      );
    }
    if (run.workspaceId != workspaceId) {
      return CallResult.error(
        'The active run belongs to a different workspace.',
      );
    }
    final conversationId = run.conversationId ?? run.channelId;
    if (conversationId == null || conversationId.isEmpty) {
      return CallResult.error(
        'Your active run is not tied to a conversation — a plan needs one.',
      );
    }

    PlanGraph graph;
    final List<PlanClarification> clarifications;
    try {
      graph = PlanGraph(
        nodes: (arguments['nodes'] as List? ?? const [])
            .whereType<Map>()
            .map((m) => PlanNode.fromJson(m.cast<String, dynamic>()))
            .toList(),
      );
      clarifications = (arguments['clarifications'] as List? ?? const [])
          .whereType<Map>()
          .map((m) => PlanClarification.fromJson(m.cast<String, dynamic>()))
          .toList();
    } on Object catch (e) {
      return CallResult.error('Could not parse the plan: $e');
    }
    if (graph.nodes.isEmpty) {
      return CallResult.error('The plan has no nodes.');
    }
    final violations = graph.validate();
    if (violations.isNotEmpty) {
      return CallResult.error(
        'The plan graph is not valid:\n'
        '${violations.map((v) => '- $v').join('\n')}\n'
        'Fix these and call submit_plan again.',
      );
    }

    graph = await _labelProvenance(workspaceId, graph);

    final now = DateTime.now();
    final previous = await _plans.latestForConversation(
      workspaceId,
      conversationId,
    );
    if (previous != null &&
        (previous.status == PlanDocumentStatus.proposed ||
            previous.status == PlanDocumentStatus.draft)) {
      await _plans.upsert(
        previous.copyWith(
          status: PlanDocumentStatus.superseded,
          updatedAt: now,
        ),
      );
    }
    final doc = PlanDocument(
      id: _uuid.v4(),
      workspaceId: workspaceId,
      conversationId: conversationId,
      agentId: agentId,
      goal: goal.trim(),
      graph: graph,
      clarifications: clarifications,
      revision: (previous?.revision ?? 0) + 1,
      createdAt: now,
      updatedAt: now,
    );
    await _plans.upsert(doc);

    // Announce it in the room it was authored in. Best-effort: a messaging
    // failure must not lose an already-persisted plan.
    final messaging = _messaging;
    if (messaging != null) {
      try {
        await messaging.sendMessage(
          workspaceId: workspaceId,
          channelId: conversationId,
          content:
              'Submitted a plan for: ${doc.goal}\n\n'
              '${graph.nodes.length} '
              '${graph.nodes.length == 1 ? 'step' : 'steps'}'
              '${doc.revision > 1 ? ' (revision ${doc.revision})' : ''}. '
              'Review and approve to run it.',
          senderId: agentId,
          senderType: 'agent',
          messageType: 'plan',
          metadata: {'planId': doc.id, 'revision': doc.revision},
          id: _uuid.v4(),
        );
      } on Object catch (_) {
        // Swallowed on purpose — the plan exists and Plan Studio shows it.
      }
    }
    await _snapshotAsWorkProduct(doc, agentId);
    _eventBus?.publish(
      PlanDocumentSubmitted(
        planId: doc.id,
        workspaceId: workspaceId,
        conversationId: conversationId,
        revision: doc.revision,
        agentId: agentId,
        nodeCount: graph.nodes.length,
        occurredAt: now,
      ),
    );

    return CallResult.success(
      jsonEncode({
        'plan_id': doc.id,
        'revision': doc.revision,
        'status': 'pending_review',
        'message':
            'Plan submitted — the operator reviews it in Plan Studio. '
            'Stop here; execution starts only after approval.',
      }),
    );
  }

  /// Fills in the display label of `symbol` provenance refs the agent left
  /// unlabelled.
  ///
  /// A code-graph symbol id is `hash(workspace | repo | file | qualifiedName)` —
  /// deterministic and unreadable. The schema asks for a `label` and agents
  /// routinely omit it, which surfaced in Plan Studio as a `symbol:<hash>` chip
  /// that told the operator nothing. The server owns the symbol table, so it
  /// resolves the name ONCE here, at write time, rather than every client
  /// re-resolving it per chip forever (a client cannot: the id is opaque and
  /// there is no symbol read op).
  ///
  /// Best-effort by construction: an unindexed repo, a re-indexed symbol, or a
  /// code-graph failure leaves the ref exactly as the agent wrote it. A plan
  /// must never fail to submit over a cosmetic label.
  Future<PlanGraph> _labelProvenance(
    String workspaceId,
    PlanGraph graph,
  ) async {
    final repo = _codeGraph;
    if (repo == null) {
      return graph;
    }
    // One lookup per distinct id: a plan commonly cites the same symbol from
    // several nodes.
    final resolved = <String, String?>{};
    var changed = false;
    final nodes = <PlanNode>[];
    for (final node in graph.nodes) {
      final refs = <PlanProvenanceRef>[];
      var nodeChanged = false;
      for (final ref in node.provenance) {
        final needsLabel =
            ref.kind == 'symbol' &&
            (ref.label?.trim().isEmpty ?? true) &&
            ref.ref.trim().isNotEmpty;
        if (!needsLabel) {
          refs.add(ref);
          continue;
        }
        final id = ref.ref.trim();
        if (!resolved.containsKey(id)) {
          resolved[id] = await _symbolName(repo, workspaceId, id);
        }
        final name = resolved[id];
        if (name == null) {
          refs.add(ref);
          continue;
        }
        refs.add(PlanProvenanceRef(kind: ref.kind, ref: ref.ref, label: name));
        nodeChanged = true;
      }
      nodes.add(nodeChanged ? node.copyWith(provenance: refs) : node);
      changed = changed || nodeChanged;
    }
    return changed ? PlanGraph(nodes: nodes) : graph;
  }

  /// The readable name of symbol [id], or null when it can't be resolved.
  Future<String?> _symbolName(
    CodeGraphRepository repo,
    String workspaceId,
    String id,
  ) async {
    try {
      final symbol = await repo.getById(workspaceId, id);
      if (symbol == null) {
        return null;
      }
      final qualified = symbol.qualifiedName.trim();
      return qualified.isNotEmpty ? qualified : symbol.name.trim();
    } on Object catch (_) {
      return null;
    }
  }

  /// Records the plan as a work-product revision so it survives being
  /// superseded, appears in the conversation's artifacts panel and is readable
  /// by other agents through `artifact://`.
  ///
  /// The body is a typed block document: the goal as markdown, the graph as a
  /// mermaid diagram and the nodes as a table. Best-effort — a snapshot failure
  /// must never lose an already-persisted plan.
  Future<void> _snapshotAsWorkProduct(PlanDocument doc, String agentId) async {
    final repo = _workProducts;
    if (repo == null) {
      return;
    }
    try {
      final rows = <List<String>>[
        for (final n in doc.graph.nodes)
          [n.key, n.title, n.type.name, n.dependsOn.join(', ')],
      ];
      final document = ArtifactDocument(
        blocks: [
          ArtifactMarkdownBlock(text: '**Goal.** ${doc.goal}'),
          ArtifactMermaidBlock(source: planGraphToMermaid(doc.graph)),
          ArtifactTableBlock(
            columns: const [
              ArtifactColumn(key: 'key', label: 'Key'),
              ArtifactColumn(key: 'title', label: 'Step'),
              ArtifactColumn(key: 'type', label: 'Type'),
              ArtifactColumn(key: 'dependsOn', label: 'Depends on'),
            ],
            rows: rows,
          ),
          if (doc.clarifications.isNotEmpty)
            ArtifactMarkdownBlock(
              text: [
                '**Clarifications**',
                for (final c in doc.clarifications)
                  '- ${c.question} — ${c.answer}',
              ].join('\n'),
            ),
        ],
      );
      final now = DateTime.now();
      final existing = await repo.forTicket(
        doc.workspaceId,
        doc.conversationId,
      );
      final prior = existing
          .where((w) => w.artifactType == WorkProductType.plan)
          .firstOrNull;
      final revisionId = _uuid.v4();
      final productId = prior?.id ?? _uuid.v4();
      if (prior == null) {
        await repo.upsert(
          WorkProduct(
            id: productId,
            workspaceId: doc.workspaceId,
            ticketId: doc.conversationId,
            agentId: agentId,
            title: 'Plan: ${doc.goal}',
            artifactType: WorkProductType.plan,
            currentRevisionId: revisionId,
            createdAt: now,
            updatedAt: now,
          ),
        );
      }
      final priorRevisions = prior == null
          ? const <WorkProductRevision>[]
          : await repo.getRevisions(doc.workspaceId, productId);
      await repo.addRevision(
        WorkProductRevision(
          id: revisionId,
          workProductId: productId,
          workspaceId: doc.workspaceId,
          revisionNumber: priorRevisions.length + 1,
          content: jsonEncode(document.toEnvelopeJson()),
          baseRevisionId: priorRevisions.isEmpty
              ? null
              : priorRevisions.last.id,
          authorType: 'agent',
          authorId: agentId,
          summary: 'Plan revision ${doc.revision}',
          createdAt: now,
        ),
      );
      if (prior != null) {
        await repo.upsert(
          prior.copyWith(currentRevisionId: revisionId, updatedAt: now),
        );
      }
    } on Object catch (_) {
      // The plan exists and Plan Studio shows it; the snapshot is additive.
    }
  }
}
