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
}
