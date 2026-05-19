import 'dart:convert';

import 'package:cc_domain/features/orchestration/domain/entities/orchestration_proposal.dart';

/// One changed node: which fields differ between two revisions.
class PlanNodeChange {
  /// Creates a change record.
  const PlanNodeChange({required this.key, required this.changedFields});

  /// The node's stable key.
  final String key;

  /// Names of the fields that changed (`title`, `description`, `roleKey`,
  /// `expectedOutputSchema`, `priority`).
  final List<String> changedFields;
}

/// A structural diff between two proposal revisions (PRD 17 §5).
class PlanDiff {
  /// Creates a diff.
  const PlanDiff({
    this.addedNodeKeys = const [],
    this.removedNodeKeys = const [],
    this.changedNodes = const [],
    this.addedEdges = const [],
    this.removedEdges = const [],
    this.goalChanged = false,
    this.rolesAdded = const [],
    this.rolesRemoved = const [],
    this.rolesReassigned = const [],
    this.maxCostCentsFrom,
    this.maxCostCentsTo,
  });

  /// Keys of nodes present only in the newer revision.
  final List<String> addedNodeKeys;

  /// Keys of nodes present only in the older revision.
  final List<String> removedNodeKeys;

  /// Nodes whose content changed.
  final List<PlanNodeChange> changedNodes;

  /// Dependency edges added (`from` must finish before `to`).
  final List<({String from, String to})> addedEdges;

  /// Dependency edges removed.
  final List<({String from, String to})> removedEdges;

  /// Whether the goal text changed.
  final bool goalChanged;

  /// Role keys added.
  final List<String> rolesAdded;

  /// Role keys removed.
  final List<String> rolesRemoved;

  /// Role keys whose assignment (existing agent / hire spec) changed.
  final List<String> rolesReassigned;

  /// Budget ceiling before (null = none set / unchanged when both null).
  final int? maxCostCentsFrom;

  /// Budget ceiling after.
  final int? maxCostCentsTo;

  /// Whether the budget ceiling changed.
  bool get budgetChanged => maxCostCentsFrom != maxCostCentsTo;

  /// Whether the two revisions are structurally identical.
  bool get isEmpty =>
      addedNodeKeys.isEmpty &&
      removedNodeKeys.isEmpty &&
      changedNodes.isEmpty &&
      addedEdges.isEmpty &&
      removedEdges.isEmpty &&
      !goalChanged &&
      rolesAdded.isEmpty &&
      rolesRemoved.isEmpty &&
      rolesReassigned.isEmpty &&
      !budgetChanged;

  /// Node keys this diff touches in any way (used to block replans of nodes
  /// with an unanswered diff — PRD 17 adversarial review).
  Set<String> get touchedNodeKeys => {
    ...addedNodeKeys,
    ...removedNodeKeys,
    ...changedNodes.map((c) => c.key),
    ...addedEdges.expand((e) => [e.from, e.to]),
    ...removedEdges.expand((e) => [e.from, e.to]),
  };
}

/// Pure structural differ over two proposal revisions.
class ProposalDiffService {
  const ProposalDiffService._();

  /// Diffs [from] → [to].
  static PlanDiff diff(OrchestrationProposal from, OrchestrationProposal to) {
    final fromNodes = {for (final t in from.subTickets) t.key: t};
    final toNodes = {for (final t in to.subTickets) t.key: t};

    final added = [
      for (final key in toNodes.keys)
        if (!fromNodes.containsKey(key)) key,
    ];
    final removed = [
      for (final key in fromNodes.keys)
        if (!toNodes.containsKey(key)) key,
    ];

    final changed = <PlanNodeChange>[];
    for (final key in fromNodes.keys) {
      final before = fromNodes[key];
      final after = toNodes[key];
      if (before == null || after == null) {
        continue;
      }
      final fields = <String>[
        if (before.title != after.title) 'title',
        if (before.description != after.description) 'description',
        if (before.roleKey != after.roleKey) 'roleKey',
        if (jsonEncode(before.expectedOutputSchema ?? const {}) !=
            jsonEncode(after.expectedOutputSchema ?? const {}))
          'expectedOutputSchema',
        if (before.priority != after.priority) 'priority',
      ];
      if (fields.isNotEmpty) {
        changed.add(PlanNodeChange(key: key, changedFields: fields));
      }
    }

    Set<(String, String)> edgesOf(Map<String, ProposedSubTicket> nodes) => {
      for (final t in nodes.values)
        for (final dep in t.dependsOn) (dep, t.key),
    };
    final fromEdges = edgesOf(fromNodes);
    final toEdges = edgesOf(toNodes);
    // Edges hanging off added/removed nodes are already reported as node
    // changes; only report edge changes between surviving nodes.
    bool survives((String, String) e) =>
        fromNodes.containsKey(e.$1) &&
        toNodes.containsKey(e.$1) &&
        fromNodes.containsKey(e.$2) &&
        toNodes.containsKey(e.$2);

    final fromRoles = {for (final r in from.roles) r.roleKey: r};
    final toRoles = {for (final r in to.roles) r.roleKey: r};
    final reassigned = <String>[];
    for (final key in fromRoles.keys) {
      final before = fromRoles[key];
      final after = toRoles[key];
      if (before == null || after == null) {
        continue;
      }
      if (before.existingAgentId != after.existingAgentId ||
          jsonEncode(before.hireSpec?.toJson() ?? const {}) !=
              jsonEncode(after.hireSpec?.toJson() ?? const {})) {
        reassigned.add(key);
      }
    }

    return PlanDiff(
      addedNodeKeys: added,
      removedNodeKeys: removed,
      changedNodes: changed,
      addedEdges: [
        for (final e in toEdges.difference(fromEdges))
          if (survives(e)) (from: e.$1, to: e.$2),
      ],
      removedEdges: [
        for (final e in fromEdges.difference(toEdges))
          if (survives(e)) (from: e.$1, to: e.$2),
      ],
      goalChanged: from.goal != to.goal,
      rolesAdded: [
        for (final key in toRoles.keys)
          if (!fromRoles.containsKey(key)) key,
      ],
      rolesRemoved: [
        for (final key in fromRoles.keys)
          if (!toRoles.containsKey(key)) key,
      ],
      rolesReassigned: reassigned,
      maxCostCentsFrom: from.budget.maxCostCents,
      maxCostCentsTo: to.budget.maxCostCents,
    );
  }
}
