import 'package:cc_domain/features/ticketing/domain/worktree/worktree_ticket_link.dart';

/// Resolves the "current" ticket for an agent operating inside a worktree.
///
/// When an agent says "operate on the current ticket" (or passes `--current` to
/// the ticket CLI), Control Center resolves it from the worktree the agent is
/// running in: the worktree whose on-disk path contains the agent's working
/// directory, picking the deepest (longest-prefix) match when worktrees nest.
class CurrentTicketResolver {
  /// Creates a [CurrentTicketResolver] over a [WorktreeTicketLinkPort].
  const CurrentTicketResolver(this._port);

  final WorktreeTicketLinkPort _port;

  /// Resolves the ticket linked to the worktree containing [workingDirectory],
  /// scoped to [workspaceId]. Returns null when no linked worktree contains the
  /// directory.
  Future<WorktreeTicketRef?> resolve({
    required String workspaceId,
    required String workingDirectory,
  }) async {
    final cwd = _normalize(workingDirectory);
    final candidates = await _port.forWorkspace(workspaceId);

    WorktreeTicketRef? best;
    var bestLen = -1;
    for (final ref in candidates) {
      if (!ref.hasTicket) {
        continue;
      }
      final base = _normalize(ref.path);
      if (_contains(base, cwd) && base.length > bestLen) {
        best = ref;
        bestLen = base.length;
      }
    }
    return best;
  }

  /// Whether [base] equals or is a path-segment prefix of [path]. Guards against
  /// `/a/b` matching `/a/bc` by requiring a separator (or exact equality).
  static bool _contains(String base, String path) {
    if (base == path) {
      return true;
    }
    return path.startsWith('$base/');
  }

  /// Strips a single trailing slash so `/a/b/` and `/a/b` compare equal.
  static String _normalize(String path) {
    if (path.length > 1 && path.endsWith('/')) {
      return path.substring(0, path.length - 1);
    }
    return path;
  }
}
