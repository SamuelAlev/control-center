// Named JSON factories read best next to the fields they map.
// ignore_for_file: sort_constructors_first

import 'dart:convert';

import 'package:cc_domain/features/plan_studio/domain/value_objects/plan_graph.dart';

/// Lifecycle of a single-agent plan-mode artifact (PRD 17 §8).
enum PlanDocumentStatus {
  /// Being authored by the planner (not yet submitted).
  draft,

  /// Submitted; awaiting operator review in Plan Studio.
  proposed,

  /// Approved — compiled into an orchestration and executing/executed.
  approved,

  /// Rejected by the operator.
  rejected,

  /// Replaced by a newer plan in the same conversation.
  superseded;

  /// Parses a stored name, defaulting to [proposed].
  static PlanDocumentStatus fromName(String? name) =>
      PlanDocumentStatus.values.firstWhere(
        (s) => s.name == name,
        orElse: () => PlanDocumentStatus.proposed,
      );
}

/// One clarifying question the planner asked and the answer it received
/// (PRD 17 §9) — woven into the plan and kept as provenance.
class PlanClarification {
  /// Creates a clarification.
  const PlanClarification({required this.question, required this.answer});

  /// The question asked.
  final String question;

  /// The operator's answer.
  final String answer;

  /// Builds from JSON.
  factory PlanClarification.fromJson(Map<String, dynamic> json) =>
      PlanClarification(
        question: json['question'] as String? ?? '',
        answer: json['answer'] as String? ?? '',
      );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {'question': question, 'answer': answer};
}

/// A single-agent plan authored in harness plan mode (PRD 17 §8).
///
/// The conversation-scoped wrapper around the shared [PlanGraph]: same graph
/// model as an orchestration proposal, different lifecycle. Produced by the
/// `submit_plan` tool during a plan-mode run; opened in Plan Studio; on
/// approval compiled into an orchestration (single role, the authoring agent)
/// and executed by the same deterministic machinery.
class PlanDocument {
  /// Creates a document. [id]/[workspaceId]/[conversationId]/[agentId] must
  /// be non-empty; [revision] must be >= 1.
  PlanDocument({
    required this.id,
    required this.workspaceId,
    required this.conversationId,
    required this.agentId,
    required this.goal,
    required this.graph,
    this.clarifications = const [],
    this.status = PlanDocumentStatus.proposed,
    this.revision = 1,
    required this.createdAt,
    required this.updatedAt,
  }) {
    if (id.isEmpty ||
        workspaceId.isEmpty ||
        conversationId.isEmpty ||
        agentId.isEmpty) {
      throw ArgumentError(
        'PlanDocument requires non-empty id, workspaceId, conversationId, '
        'and agentId.',
      );
    }
    if (revision < 1) {
      throw ArgumentError.value(revision, 'revision', 'must be >= 1');
    }
  }

  /// Unique id (UUID v4).
  final String id;

  /// Owning workspace. Required — plans never float across workspaces.
  final String workspaceId;

  /// The conversation (channel) the plan was authored in.
  final String conversationId;

  /// The agent that authored the plan.
  final String agentId;

  /// What the plan achieves (the user's ask, restated).
  final String goal;

  /// The typed DAG (work nodes; no structural frame).
  final PlanGraph graph;

  /// Clarifying Q/A that shaped the plan (PRD 17 §9).
  final List<PlanClarification> clarifications;

  /// Lifecycle status.
  final PlanDocumentStatus status;

  /// Monotonic revision (>= 1), bumped on each replan/edit.
  final int revision;

  /// Creation timestamp.
  final DateTime createdAt;

  /// Last mutation time.
  final DateTime updatedAt;

  /// Serializes the plan body (goal + graph + clarifications) to JSON — the
  /// `planJson` column payload. Identity/lifecycle fields live in columns.
  Map<String, dynamic> bodyToJson() => {
    'goal': goal,
    'graph': graph.toJson(),
    if (clarifications.isNotEmpty)
      'clarifications': clarifications.map((c) => c.toJson()).toList(),
  };

  /// Serializes the plan body to a JSON string.
  String bodyToJsonString() => jsonEncode(bodyToJson());

  /// Builds from a stored row's fields + decoded body JSON.
  factory PlanDocument.fromBody({
    required String id,
    required String workspaceId,
    required String conversationId,
    required String agentId,
    required Map<String, dynamic> body,
    required PlanDocumentStatus status,
    required int revision,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) => PlanDocument(
    id: id,
    workspaceId: workspaceId,
    conversationId: conversationId,
    agentId: agentId,
    goal: body['goal'] as String? ?? '',
    graph: body['graph'] is Map
        ? PlanGraph.fromJson((body['graph'] as Map).cast<String, dynamic>())
        : const PlanGraph(nodes: []),
    clarifications: (body['clarifications'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => PlanClarification.fromJson(m.cast<String, dynamic>()))
        .toList(),
    status: status,
    revision: revision,
    createdAt: createdAt,
    updatedAt: updatedAt,
  );

  /// Returns a copy with replaced fields.
  PlanDocument copyWith({
    String? goal,
    PlanGraph? graph,
    List<PlanClarification>? clarifications,
    PlanDocumentStatus? status,
    int? revision,
    DateTime? updatedAt,
  }) => PlanDocument(
    id: id,
    workspaceId: workspaceId,
    conversationId: conversationId,
    agentId: agentId,
    goal: goal ?? this.goal,
    graph: graph ?? this.graph,
    clarifications: clarifications ?? this.clarifications,
    status: status ?? this.status,
    revision: revision ?? this.revision,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );

  @override
  bool operator ==(Object other) =>
      other is PlanDocument &&
      other.id == id &&
      other.status == status &&
      other.revision == revision &&
      other.updatedAt == updatedAt;

  @override
  int get hashCode => Object.hash(id, status, revision, updatedAt);
}
