import 'package:cc_domain/core/domain/entities/agent.dart';

/// A node in the rendered org chart: an [agent] plus its direct reports.
///
/// The tree is built from the strict `reportsTo` reporting lines — each agent
/// appears exactly once, under its single manager (or at the root when it has
/// no manager).
class OrgNode {
  /// Creates an [OrgNode].
  OrgNode({required this.agent, List<OrgNode>? reports})
    : reports = reports ?? <OrgNode>[];

  /// The agent at this node.
  final Agent agent;

  /// This agent's direct reports.
  final List<OrgNode> reports;

  /// Total agents in this subtree, including this node.
  int get subtreeSize =>
      1 + reports.fold<int>(0, (sum, r) => sum + r.subtreeSize);

  /// Depth of the deepest branch beneath this node (0 for a leaf).
  int get depth => reports.isEmpty
      ? 0
      : 1 + reports.map((r) => r.depth).reduce((a, b) => a > b ? a : b);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OrgNode &&
          agent == other.agent &&
          _orgListEq(reports, other.reports);

  @override
  int get hashCode => Object.hash(agent, reports.length);
}

bool _orgListEq(List<OrgNode> a, List<OrgNode> b) {
  if (a.length != b.length) {
    return false;
  }
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) {
      return false;
    }
  }
  return true;
}
