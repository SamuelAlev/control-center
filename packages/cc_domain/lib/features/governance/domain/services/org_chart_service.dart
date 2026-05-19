import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/repositories/agent_repository.dart';
import 'package:cc_domain/features/governance/domain/value_objects/org_node.dart';
import 'package:cc_domain/src/errors/app_exceptions.dart';

/// Validates and builds the strict agent reporting tree.
///
/// Each agent reports to at most one manager (`reportsTo`), forming a tree with
/// no cycles and no multi-manager edges. The CEO (a top-level agent) is the
/// root. All agents in a tree belong to one workspace — the isolation boundary.
class OrgChartService {
  /// Creates an [OrgChartService].
  OrgChartService({required AgentRepository agentRepository})
    : _agents = agentRepository;

  final AgentRepository _agents;

  /// Validates that setting [agentId]'s manager to [reportsTo] keeps the tree
  /// strict: the manager must exist in the same [workspaceId], an agent may not
  /// report to itself, and the edge must not create a cycle.
  ///
  /// Throws [OrgChartException] on violation. A null [reportsTo] (top-level) is
  /// always valid.
  Future<void> validateReportsTo({
    required String workspaceId,
    required String agentId,
    required String? reportsTo,
  }) async {
    if (reportsTo == null) {
      return;
    }
    if (reportsTo == agentId) {
      throw const OrgChartException('An agent cannot report to itself.');
    }
    final manager = await _agents.getById(workspaceId, reportsTo);
    if (manager == null) {
      throw OrgChartException('Manager $reportsTo does not exist.');
    }
    if (manager.workspaceId != workspaceId) {
      throw OrgChartException(
        'Manager $reportsTo belongs to a different workspace.',
      );
    }
    // Walk up from the proposed manager; if we reach [agentId], the edge would
    // close a cycle.
    final agents = await _agents.watchByWorkspace(workspaceId).first;
    final byId = {for (final a in agents) a.id: a};
    var cursor = manager;
    final visited = <String>{};
    while (true) {
      if (cursor.id == agentId) {
        throw const OrgChartException('Reporting line would create a cycle.');
      }
      if (!visited.add(cursor.id)) {
        // Pre-existing cycle in stored data — stop walking.
        break;
      }
      final next = cursor.reportsTo;
      if (next == null) {
        break;
      }
      final parent = byId[next];
      if (parent == null) {
        break;
      }
      cursor = parent;
    }
  }

  /// Asserts that [agentId] can be deleted: a manager with direct reports may
  /// not be removed (ON DELETE RESTRICT) — its reports would be orphaned.
  /// Reassign or remove the reports first.
  ///
  /// Throws [OrgChartException] when the agent still has reports.
  Future<void> assertDeletable({
    required String workspaceId,
    required String agentId,
  }) async {
    final agents = await _agents.watchByWorkspace(workspaceId).first;
    final reports = agents.where((a) => a.reportsTo == agentId).toList();
    if (reports.isNotEmpty) {
      throw OrgChartException(
        'Agent $agentId has ${reports.length} direct report(s); reassign them '
        'before deleting.',
      );
    }
  }

  /// Builds the org tree for [workspaceId]. Top-level agents (no manager, or a
  /// manager that is missing/foreign) become roots; everyone else nests under
  /// their manager. Stored cycles are broken defensively so a bad row never
  /// hangs the builder.
  Future<List<OrgNode>> buildTree(String workspaceId) async {
    final agents = await _agents.watchByWorkspace(workspaceId).first;
    return buildTreeFrom(agents);
  }

  /// Pure tree builder over an in-memory [agents] list — testable without a
  /// repository.
  static List<OrgNode> buildTreeFrom(List<Agent> agents) {
    final nodes = {for (final a in agents) a.id: OrgNode(agent: a)};
    final roots = <OrgNode>[];
    for (final agent in agents) {
      final managerId = agent.reportsTo;
      final node = nodes[agent.id]!;
      if (managerId == null || !nodes.containsKey(managerId)) {
        roots.add(node);
        continue;
      }
      // Guard against a self/cyclic edge surfacing a child under itself.
      if (managerId == agent.id || _wouldCycle(nodes, agent.id, managerId)) {
        roots.add(node);
        continue;
      }
      nodes[managerId]!.reports.add(node);
    }
    return roots;
  }

  /// Whether attaching [childId] under [managerId] would close a cycle, given
  /// the current `reportsTo` edges in [nodes].
  static bool _wouldCycle(
    Map<String, OrgNode> nodes,
    String childId,
    String managerId,
  ) {
    var cursor = nodes[managerId]?.agent.reportsTo;
    final visited = <String>{managerId};
    while (cursor != null) {
      if (cursor == childId) {
        return true;
      }
      if (!visited.add(cursor)) {
        return true;
      }
      cursor = nodes[cursor]?.agent.reportsTo;
    }
    return false;
  }
}
