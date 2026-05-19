import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/github_content_client.dart';

/// Process-lifetime cache of the authenticated GitHub viewer's login and
/// org → team slugs. Shared by the notifications poller (pending-team gate)
/// and `github.currentUser` (inbox classification) so `GET /user/teams` is
/// not fetched twice.
class ViewerGitHubIdentityCache {
  /// Creates a [ViewerGitHubIdentityCache] over the GitHub content client.
  ViewerGitHubIdentityCache(this._content);

  final GitHubContentClient _content;

  bool _userUnavailable = false;
  bool _teamsUnavailable = false;
  bool _teamsFailureLogged = false;
  Future<GitHubUser?>? _userLoad;
  Future<Map<String, Set<String>>?>? _teamsLoad;

  /// The authenticated user, or null when the lookup failed (not retried).
  Future<GitHubUser?> user() => _userLoad ??= _loadUser();

  /// Org (lower-case) → team slugs (lower-case). Null when the lookup failed
  /// (not retried); an empty map means the viewer belongs to no teams.
  Future<Map<String, Set<String>>?> teams() => _teamsLoad ??= _loadTeams();

  Future<GitHubUser?> _loadUser() async {
    if (_userUnavailable) {
      return null;
    }
    try {
      final user = await _content.getAuthenticatedUser();
      if (user == null || user.login.isEmpty) {
        _userUnavailable = true;
        return null;
      }
      return user;
    } on Object catch (e) {
      _userUnavailable = true;
      CcInfraLog.warning('github_identity: viewer login unavailable: $e');
      return null;
    }
  }

  Future<Map<String, Set<String>>?> _loadTeams() async {
    if (_teamsUnavailable) {
      return null;
    }
    try {
      final teams = await _content.listViewerTeams();
      final byOrg = <String, Set<String>>{};
      for (final team in teams) {
        (byOrg[team.org.toLowerCase()] ??= <String>{}).add(
          team.slug.toLowerCase(),
        );
      }
      return byOrg;
    } on Object catch (e) {
      _teamsUnavailable = true;
      if (!_teamsFailureLogged) {
        _teamsFailureLogged = true;
        CcInfraLog.warning('github_identity: viewer teams unavailable: $e');
      }
      return null;
    }
  }
}
