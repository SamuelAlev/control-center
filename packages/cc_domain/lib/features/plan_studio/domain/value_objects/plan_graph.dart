// Named JSON factories read best next to the fields they map.
// ignore_for_file: sort_constructors_first

import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';
import 'package:cc_domain/features/orchestration/domain/value_objects/plan_annotations.dart';

/// What a plan node *is* (PRD 17 §1) — typed, never inferred from prose.
enum PlanNodeType {
  /// Upfront research feeding the work DAG.
  research,

  /// A unit of work (an orchestration sub-ticket).
  work,

  /// A bounded discussion round (one per role).
  discussion,

  /// The final synthesis producing the deliverable.
  synthesis;

  /// Parses a stored name, defaulting to [work].
  static PlanNodeType fromName(String? name) => PlanNodeType.values.firstWhere(
    (t) => t.name == name,
    orElse: () => PlanNodeType.work,
  );
}

/// One node of the shared plan graph.
///
/// [PlanGraph] is the single typed DAG both wrappers embed
/// (`OrchestrationProposal` and `PlanDocument`); the canvas, estimator and
/// differ all operate on it. Work nodes map 1:1 onto
/// [ProposedSubTicket]s; research/discussion/synthesis nodes are the
/// structural frame the materializer adds around them.
class PlanNode {
  /// Creates a node.
  const PlanNode({
    required this.key,
    required this.title,
    required this.type,
    this.roleKey,
    this.description = '',
    this.dependsOn = const [],
    this.expectedOutputSchema,
    this.priority = 'none',
    this.estimate,
    this.provenance = const [],
  });

  /// Stable identity across revisions (a sub-ticket key, or a structural
  /// `__research`/`__discussion_<role>`/`__synthesis` key).
  final String key;

  /// Node title.
  final String title;

  /// Node type.
  final PlanNodeType type;

  /// Responsible role key (null for structural nodes without one).
  final String? roleKey;

  /// Work description / prompt.
  final String description;

  /// Keys of nodes that must complete first (the DAG edges).
  final List<String> dependsOn;

  /// Output contract, when declared.
  final Map<String, dynamic>? expectedOutputSchema;

  /// Priority name (`none`/`low`/`medium`/`high`/`urgent`).
  final String priority;

  /// Last computed estimate (PRD 17 §3).
  final PlanNodeEstimate? estimate;

  /// Evidence refs (PRD 17 §7).
  final List<PlanProvenanceRef> provenance;

  /// Whether this node is an editable unit of work (vs the structural frame).
  bool get isWork => type == PlanNodeType.work;

  /// Builds from JSON.
  factory PlanNode.fromJson(Map<String, dynamic> json) => PlanNode(
    key: json['key'] as String? ?? '',
    title: json['title'] as String? ?? '',
    type: PlanNodeType.fromName(json['type'] as String?),
    roleKey: json['roleKey'] as String?,
    description: json['description'] as String? ?? '',
    dependsOn:
        (json['dependsOn'] as List?)?.whereType<String>().toList() ?? const [],
    expectedOutputSchema: (json['expectedOutputSchema'] as Map?)
        ?.cast<String, dynamic>(),
    priority: json['priority'] as String? ?? 'none',
    estimate: json['estimate'] is Map
        ? PlanNodeEstimate.fromJson(
            (json['estimate'] as Map).cast<String, dynamic>(),
          )
        : null,
    provenance: (json['provenance'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => PlanProvenanceRef.fromJson(m.cast<String, dynamic>()))
        .toList(),
  );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'key': key,
    'title': title,
    'type': type.name,
    if (roleKey != null) 'roleKey': roleKey,
    'description': description,
    'dependsOn': dependsOn,
    if (expectedOutputSchema != null)
      'expectedOutputSchema': expectedOutputSchema,
    'priority': priority,
    if (estimate != null) 'estimate': estimate!.toJson(),
    if (provenance.isNotEmpty)
      'provenance': provenance.map((p) => p.toJson()).toList(),
  };

  /// Returns an edited copy ([key] and [type] are identity, immutable).
  PlanNode copyWith({
    String? title,
    String? roleKey,
    String? description,
    List<String>? dependsOn,
    Map<String, dynamic>? expectedOutputSchema,
    bool clearExpectedOutputSchema = false,
    String? priority,
    PlanNodeEstimate? estimate,
    bool clearEstimate = false,
    List<PlanProvenanceRef>? provenance,
  }) => PlanNode(
    key: key,
    title: title ?? this.title,
    type: type,
    roleKey: roleKey ?? this.roleKey,
    description: description ?? this.description,
    dependsOn: dependsOn ?? this.dependsOn,
    expectedOutputSchema: clearExpectedOutputSchema
        ? null
        : (expectedOutputSchema ?? this.expectedOutputSchema),
    priority: priority ?? this.priority,
    estimate: clearEstimate ? null : (estimate ?? this.estimate),
    provenance: provenance ?? this.provenance,
  );

  /// The sub-ticket this work node maps onto. Throws for structural nodes.
  ProposedSubTicket toSubTicket() {
    if (!isWork) {
      throw StateError('Only work nodes map to sub-tickets: $key is $type.');
    }
    return ProposedSubTicket(
      key: key,
      title: title,
      roleKey: roleKey ?? '',
      description: description,
      dependsOn: dependsOn,
      expectedOutputSchema: expectedOutputSchema,
      priority: priority,
      estimate: estimate,
      provenance: provenance,
    );
  }

  /// Builds a work node from a sub-ticket.
  factory PlanNode.fromSubTicket(ProposedSubTicket ticket) => PlanNode(
    key: ticket.key,
    title: ticket.title,
    type: PlanNodeType.work,
    roleKey: ticket.roleKey,
    description: ticket.description,
    dependsOn: ticket.dependsOn,
    expectedOutputSchema: ticket.expectedOutputSchema,
    priority: ticket.priority,
    estimate: ticket.estimate,
    provenance: ticket.provenance,
  );
}

/// The shared typed plan DAG (PRD 17 clarifications: "one graph model, two
/// wrappers").
///
/// Immutable. Edges are derived from [PlanNode.dependsOn]; there is no
/// separate edge list to drift out of sync. Layout is NOT part of the model —
/// clients compute a deterministic layered layout from the graph alone.
class PlanGraph {
  /// Creates a graph.
  const PlanGraph({required this.nodes});

  /// All nodes, in stable authored order.
  final List<PlanNode> nodes;

  /// Structural key of the research node.
  static const String researchKey = '__research';

  /// Structural key of the synthesis node.
  static const String synthesisKey = '__synthesis';

  /// Structural key prefix for discussion nodes (`__discussion_<roleKey>`).
  static const String discussionKeyPrefix = '__discussion_';

  /// The node with [key], or null.
  PlanNode? node(String key) {
    for (final n in nodes) {
      if (n.key == key) {
        return n;
      }
    }
    return null;
  }

  /// The editable work nodes.
  List<PlanNode> get workNodes => nodes.where((n) => n.isWork).toList();

  /// All directed edges as (from → to) pairs (dependency → dependent).
  List<({String from, String to})> get edges => [
    for (final n in nodes)
      for (final dep in n.dependsOn) (from: dep, to: n.key),
  ];

  /// Keys of every node in the subtree rooted at [rootKey] (the node plus
  /// all transitive dependents). Used by subtree approval (PRD 17 §4).
  Set<String> subtree(String rootKey) {
    final dependents = <String, List<String>>{};
    for (final n in nodes) {
      for (final dep in n.dependsOn) {
        dependents.putIfAbsent(dep, () => []).add(n.key);
      }
    }
    final seen = <String>{};
    final queue = [rootKey];
    while (queue.isNotEmpty) {
      final key = queue.removeLast();
      if (!seen.add(key)) {
        continue;
      }
      queue.addAll(dependents[key] ?? const []);
    }
    return seen;
  }

  /// Validation errors: duplicate/empty keys, dangling `dependsOn` refs and
  /// cycles (Kahn's algorithm). Empty list = structurally valid. Role/schema
  /// validity stays with `OrchestrationProposalValidator` — this is the
  /// graph-shape half every wrapper shares.
  List<String> validate() {
    final errors = <String>[];
    final keys = <String>{};
    for (final n in nodes) {
      if (n.key.isEmpty) {
        errors.add('A node has an empty key.');
      } else if (!keys.add(n.key)) {
        errors.add('Duplicate node key: ${n.key}.');
      }
    }
    for (final n in nodes) {
      for (final dep in n.dependsOn) {
        if (dep == n.key) {
          errors.add('Node ${n.key} depends on itself.');
        } else if (!keys.contains(dep)) {
          errors.add('Node ${n.key} depends on unknown node $dep.');
        }
      }
    }
    if (errors.isEmpty && _hasCycle()) {
      errors.add('The dependency graph contains a cycle.');
    }
    return errors;
  }

  bool _hasCycle() {
    final inDegree = <String, int>{for (final n in nodes) n.key: 0};
    final dependents = <String, List<String>>{};
    for (final n in nodes) {
      for (final dep in n.dependsOn) {
        inDegree[n.key] = (inDegree[n.key] ?? 0) + 1;
        dependents.putIfAbsent(dep, () => []).add(n.key);
      }
    }
    final queue = [
      for (final e in inDegree.entries)
        if (e.value == 0) e.key,
    ];
    var visited = 0;
    while (queue.isNotEmpty) {
      final key = queue.removeLast();
      visited++;
      for (final dependent in dependents[key] ?? const <String>[]) {
        final remaining = inDegree[dependent]! - 1;
        inDegree[dependent] = remaining;
        if (remaining == 0) {
          queue.add(dependent);
        }
      }
    }
    return visited != nodes.length;
  }

  /// Builds the full graph an [OrchestrationProposal] describes: the work
  /// DAG framed by its research/discussion/synthesis nodes, wired the way
  /// `OrchestrationMaterializer` compiles them (research gates roots,
  /// synthesis follows every work node).
  factory PlanGraph.fromProposal(OrchestrationProposal proposal) {
    final nodes = <PlanNode>[];
    final hasResearch = proposal.research.enabled;
    if (hasResearch) {
      nodes.add(
        PlanNode(
          key: researchKey,
          title: 'Research',
          type: PlanNodeType.research,
          roleKey: proposal.research.roleKey ?? proposal.synthesis.roleKey,
          description: proposal.research.prompt,
        ),
      );
    }
    if (proposal.discussion.enabled) {
      for (final role in proposal.roles) {
        nodes.add(
          PlanNode(
            key: '$discussionKeyPrefix${role.roleKey}',
            title: 'Discussion — ${role.title}',
            type: PlanNodeType.discussion,
            roleKey: role.roleKey,
            description: proposal.discussion.prompt,
            dependsOn: hasResearch ? const [researchKey] : const [],
          ),
        );
      }
    }
    for (final ticket in proposal.subTickets) {
      final node = PlanNode.fromSubTicket(ticket);
      nodes.add(
        node.dependsOn.isEmpty && hasResearch
            ? node.copyWith(dependsOn: const [researchKey])
            : node,
      );
    }
    nodes.add(
      PlanNode(
        key: synthesisKey,
        title: 'Synthesis',
        type: PlanNodeType.synthesis,
        roleKey: proposal.synthesis.roleKey,
        description: proposal.synthesis.prompt,
        expectedOutputSchema: proposal.synthesis.outputSchema,
        dependsOn: [for (final t in proposal.subTickets) t.key],
      ),
    );
    return PlanGraph(nodes: nodes);
  }

  /// Builds a work-only graph (plan-mode documents).
  factory PlanGraph.fromJson(Map<String, dynamic> json) => PlanGraph(
    nodes: (json['nodes'] as List? ?? const [])
        .whereType<Map>()
        .map((m) => PlanNode.fromJson(m.cast<String, dynamic>()))
        .toList(),
  );

  /// Serializes to JSON.
  Map<String, dynamic> toJson() => {
    'nodes': nodes.map((n) => n.toJson()).toList(),
  };

  /// Applies this graph's WORK nodes back onto [proposal] as its new
  /// sub-ticket list, stripping the structural gating edge research inserted.
  /// The frame (research/discussion/synthesis specs) is edited on the
  /// proposal itself, not through the graph.
  OrchestrationProposal applyToProposal(OrchestrationProposal proposal) =>
      proposal.copyWith(
        subTickets: [
          for (final n in workNodes)
            n
                .copyWith(
                  dependsOn: [
                    for (final dep in n.dependsOn)
                      if (proposal.subTickets.any((t) => t.key == dep) ||
                          workNodes.any((w) => w.key == dep))
                        dep,
                  ],
                )
                .toSubTicket(),
        ],
      );
}
