/// What one subscriber may see of the workspace presence roster.
///
/// Membership puts a person on the roster; it does not let them see where in
/// the code another member is. A roster entry's locus (space, file, PR), the
/// space someone is typing in or presenting, and their worktree claims all
/// name repository-backed places, so each is shown only when the viewer could
/// open that place themselves. Who is online, and whether they are idle, stays
/// visible to every member.
///
/// Tickets, notes and plan nodes are workspace-scoped records with no
/// per-repository grant, so loci and claims on them pass through.
class PresenceViewer {
  /// A viewer for whom nothing is hidden (an admin, a member granted every
  /// linked repository, or a catalog with no membership wiring).
  const PresenceViewer.unrestricted()
    : unrestricted = true,
      readableRepoIds = const {},
      repoIdsByCoordinate = const {},
      canReadSpace = null,
      _spaces = const {};

  /// A viewer whose grants exclude at least one linked repository.
  PresenceViewer.restricted({
    required this.readableRepoIds,
    required this.repoIdsByCoordinate,
    required Future<bool> Function(String spaceId) this.canReadSpace,
  }) : unrestricted = false,
       _spaces = {};

  /// Whether the roster passes through untouched.
  final bool unrestricted;

  /// Linked repositories the viewer holds a read grant on.
  final Set<String> readableRepoIds;

  /// Linked repositories by lowercased `owner/name`.
  final Map<String, String> repoIdsByCoordinate;

  /// Whether the viewer may open a space (every repo it exposes is granted).
  final Future<bool> Function(String spaceId)? canReadSpace;
  final Map<String, bool> _spaces;

  Future<bool> _space(String spaceId) async =>
      _spaces[spaceId] ??= await canReadSpace!(spaceId);

  bool _repo(String repoId) => readableRepoIds.contains(repoId);

  bool _coordinate(String fullName) {
    final id = repoIdsByCoordinate[fullName.toLowerCase()];
    return id != null && _repo(id);
  }

  Future<bool> _locus(Map<String, dynamic> locus) async => switch (locus['t']) {
    'sp' => switch (locus['c']) {
      final String id when id.isNotEmpty => await _space(id),
      _ => false,
    },
    'file' => switch (locus['r']) {
      final String id => _repo(id),
      _ => false,
    },
    'pr' => switch (locus['r']) {
      final String name => _coordinate(name),
      _ => false,
    },
    'tk' || 'plan' => true,
    _ => false,
  };

  Future<bool> _claim(Map<String, dynamic> claim) async => switch (claim['t']) {
    // A worktree claim's id is the space/conversation the worktree serves.
    'worktree' => switch (claim['id']) {
      final String id when id.isNotEmpty => await _space(id),
      _ => false,
    },
    'ticket' || 'note' || 'plan' => true,
    _ => false,
  };

  /// [roster] (hub wire maps) as this viewer may see it.
  Future<List<Map<String, dynamic>>> redact(
    List<Map<String, dynamic>> roster,
  ) async {
    if (unrestricted) {
      return roster;
    }
    return [for (final entry in roster) await _redactEntry(entry)];
  }

  Future<Map<String, dynamic>> _redactEntry(Map<String, dynamic> entry) async {
    final out = Map<String, dynamic>.of(entry);
    if (out['l'] case final Map<dynamic, dynamic> locus
        when !await _locus(locus.cast<String, dynamic>())) {
      out.remove('l');
    }
    for (final key in const ['ty', 'sp']) {
      if (out[key] case final String spaceId when !await _space(spaceId)) {
        out.remove(key);
      }
    }
    if (out['cl'] case final List<dynamic> claims) {
      final kept = [
        for (final c in claims)
          if (c is Map && await _claim(c.cast<String, dynamic>())) c,
      ];
      if (kept.isEmpty) {
        out.remove('cl');
      } else {
        out['cl'] = kept;
      }
    }
    return out;
  }
}
