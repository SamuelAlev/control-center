import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/github_content_client.dart';

/// Process-lifetime cache of the authenticated GitHub viewer's login and
/// org → team slugs. Shared by the notifications poller (pending-team gate)
/// and `github.currentUser` (inbox classification) so `GET /user/teams` is
/// not fetched twice.
///
/// **Only successes are cached for the process lifetime.** A failure (or an
/// answer with no user, e.g. the host has no token yet) is held for
/// [retryAfter] and then retried. This used to be a permanent latch: the first
/// failing lookup set an `unavailable` flag and memoized the failed future
/// forever, so a single GitHub 503 during a service incident left
/// `github.currentUser` answering null — successfully, with nothing for a
/// client to retry — until the server process was restarted. Every inbox
/// section is classified relative to that login
/// (`ClassifyPrInboxUseCase` returns an all-empty inbox for an empty login),
/// so one transient error silently emptied the operator's inbox for the rest
/// of the day and told them they were all caught up.
///
/// The cool-down is what keeps the retry from becoming a hot loop against a
/// service that is already struggling: callers arriving inside the window get
/// the null answer without a request.
class ViewerGitHubIdentityCache {
  /// Creates a [ViewerGitHubIdentityCache] over the GitHub content client.
  ///
  /// [retryAfter] bounds how often a failed lookup is retried; [now] is
  /// injectable so tests can advance the cool-down without waiting.
  ViewerGitHubIdentityCache(
    this._content, {
    this.retryAfter = const Duration(minutes: 1),
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  final GitHubContentClient _content;
  final DateTime Function() _now;

  /// Minimum spacing between retries of a lookup that failed.
  final Duration retryAfter;

  GitHubUser? _user;
  Future<GitHubUser?>? _userLoad;
  DateTime? _userFailedAt;
  bool _userFailureLogged = false;

  Map<String, Set<String>>? _teams;
  Future<Map<String, Set<String>>?>? _teamsLoad;
  DateTime? _teamsFailedAt;
  bool _teamsFailureLogged = false;

  /// The authenticated user, or null when the lookup failed or the host holds
  /// no token. A null is retried once [retryAfter] has elapsed.
  Future<GitHubUser?> user() {
    final cached = _user;
    if (cached != null) {
      return Future.value(cached);
    }
    final inFlight = _userLoad;
    if (inFlight != null) {
      return inFlight;
    }
    if (_coolingDown(_userFailedAt)) {
      return Future.value();
    }
    return _userLoad = _loadUser().whenComplete(() => _userLoad = null);
  }

  /// Org (lower-case) → team slugs (lower-case). Null when the lookup failed
  /// (retried once [retryAfter] has elapsed); an empty map means the viewer
  /// belongs to no teams and is cached like any other success.
  Future<Map<String, Set<String>>?> teams() {
    final cached = _teams;
    if (cached != null) {
      return Future.value(cached);
    }
    final inFlight = _teamsLoad;
    if (inFlight != null) {
      return inFlight;
    }
    if (_coolingDown(_teamsFailedAt)) {
      return Future.value();
    }
    return _teamsLoad = _loadTeams().whenComplete(() => _teamsLoad = null);
  }

  bool _coolingDown(DateTime? failedAt) =>
      failedAt != null && _now().difference(failedAt) < retryAfter;

  Future<GitHubUser?> _loadUser() async {
    try {
      final user = await _content.getAuthenticatedUser();
      if (user == null || user.login.isEmpty) {
        // A well-formed "no viewer" answer: the host has no usable token yet.
        // Not an error, but not an identity either — hold it briefly so a
        // token added later is picked up without a restart.
        _userFailedAt = _now();
        return null;
      }
      _user = user;
      _userFailedAt = null;
      _userFailureLogged = false;
      return user;
    } on Object catch (e) {
      _userFailedAt = _now();
      // One line per failure streak: a multi-hour incident should not fill the
      // log with a warning per retry.
      if (!_userFailureLogged) {
        _userFailureLogged = true;
        CcInfraLog.warning(
          'github_identity: viewer login unavailable (retrying in '
          '${retryAfter.inSeconds}s): $e',
        );
      }
      return null;
    }
  }

  Future<Map<String, Set<String>>?> _loadTeams() async {
    try {
      final teams = await _content.listViewerTeams();
      final byOrg = <String, Set<String>>{};
      for (final team in teams) {
        (byOrg[team.org.toLowerCase()] ??= <String>{}).add(
          team.slug.toLowerCase(),
        );
      }
      _teams = byOrg;
      _teamsFailedAt = null;
      _teamsFailureLogged = false;
      return byOrg;
    } on Object catch (e) {
      _teamsFailedAt = _now();
      if (!_teamsFailureLogged) {
        _teamsFailureLogged = true;
        CcInfraLog.warning(
          'github_identity: viewer teams unavailable (retrying in '
          '${retryAfter.inSeconds}s): $e',
        );
      }
      return null;
    }
  }
}
