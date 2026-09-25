/// Tracks ask hops only while their callers are waiting for a reply.
///
/// An ask to an already waiting ancestor would deadlock the two agent turns.
/// The same chain is consulted by task delegation, so a recipient cannot
/// delegate work back to an agent currently waiting on its answer.
class PendingDelegationHops {
  final Map<String, List<(String, String)>> _byWorkspace = {};

  /// An ordered ancestor chain ending at [agentId]. Returns the longest
  /// reachable chain; callers can check the proposed recipient against all
  /// chains via [wouldCycle] when concurrent asks converge on one agent.
  List<String> chain(String workspaceId, String agentId) {
    final edges = _byWorkspace[workspaceId] ?? const <(String, String)>[];
    List<String> visit(String current, Set<String> seen) {
      if (!seen.add(current)) return [current];
      var longest = <String>[current];
      for (final (from, to) in edges) {
        if (to != current || seen.contains(from)) continue;
        final candidate = [
          ...visit(from, {...seen}),
          current,
        ];
        if (candidate.length > longest.length) longest = candidate;
      }
      return longest;
    }

    return visit(agentId, {});
  }

  /// Also searches shorter concurrent paths (not just [chain]'s longest).
  bool wouldCycle(String workspaceId, String fromAgentId, String toAgentId) {
    final edges = _byWorkspace[workspaceId] ?? const <(String, String)>[];
    final seen = <String>{};
    bool visit(String current) {
      if (current == toAgentId) return true;
      if (!seen.add(current)) return false;
      for (final (from, to) in edges) {
        if (to == current && visit(from)) return true;
      }
      return false;
    }

    return visit(fromAgentId);
  }

  /// Registers an allowed ask. The returned callback removes one occurrence,
  /// including when multiple requests have identical endpoints.
  void Function() enter(
    String workspaceId,
    String fromAgentId,
    String toAgentId,
  ) {
    final edges = _byWorkspace.putIfAbsent(workspaceId, () => []);
    final edge = (fromAgentId, toAgentId);
    edges.add(edge);
    var removed = false;
    return () {
      if (removed) return;
      removed = true;
      edges.remove(edge);
      if (edges.isEmpty) _byWorkspace.remove(workspaceId);
    };
  }
}
