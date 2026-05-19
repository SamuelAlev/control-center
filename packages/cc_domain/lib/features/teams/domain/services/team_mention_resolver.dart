import 'package:cc_domain/features/teams/domain/entities/team.dart';

/// Resolves a free-text mention token (e.g. `FrontendTeam`) to a [Team].
///
/// Matching is case-insensitive on the team name with spaces and a trailing
/// "team" suffix normalised away, so `@FrontendTeam`, `@frontend-team`, and
/// `@Frontend` all resolve to a team named "Frontend". Returns `null` on no
/// match or an ambiguous (2+) match — the caller decides how to surface that.
class TeamMentionResolver {
  const TeamMentionResolver();

  /// Resolves [token] against [teams]. Returns the single match or `null`.
  Team? resolve(String token, List<Team> teams) {
    final needle = _normalise(token);
    if (needle.isEmpty) {
      return null;
    }
    final matches = teams.where((t) => _normalise(t.name) == needle).toList();
    return matches.length == 1 ? matches.first : null;
  }

  String _normalise(String value) {
    final lower = value.toLowerCase().trim();
    final compact = lower.replaceAll(RegExp(r'[\s_-]+'), '');
    return compact.endsWith('team') && compact.length > 4
        ? compact.substring(0, compact.length - 4)
        : compact;
  }
}
