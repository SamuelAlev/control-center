import 'package:cc_connect_core/cc_connect_core.dart' show GitHubTokenScope;
import 'package:cc_domain/cc_domain.dart' show NetworkException;
import 'package:cc_domain/features/skills/domain/ports/skill_source_port.dart';
import 'package:cc_infra/cc_infra.dart'
    show GitHubApiClient, GitHubSkillSourceAdapter;
import 'package:cc_server_core/src/forge/github_clients.dart';

/// Which GitHub client reads one skill source repository.
///
/// The workspace's GitHub App comes first: a `read` token for that one
/// repository ([GitHubClients.forSkillSource]), clamped to the accountable
/// human. When the App cannot read it (not installed on the owner, or the
/// person's role does not clear the clamp) and a person asked, it is read as
/// that person with their own sign-in ([GitHubClients.asPerson]), which is
/// how a public catalog outside the App's installations is browsed and
/// installed. Without a person nothing falls back, and the refusal names its
/// own reason rather than reading as a missing repository.
final class SkillSourceGitHub {
  /// Creates the router over the server's GitHub clients.
  const SkillSourceGitHub(this._clients);

  final GitHubClients _clients;

  /// The client that reads [owner]/[repo] for [workspaceId].
  ///
  /// Throws [NetworkException] carrying the refusal's wire code and message
  /// when neither the App nor [actingUserId] can read it.
  Future<GitHubApiClient> clientFor(
    String workspaceId,
    String owner,
    String repo, {
    String? actingUserId,
  }) async {
    try {
      // The grant is cached, so the requests that follow reuse it.
      await _clients.mintScoped(
        workspaceId: workspaceId,
        owner: owner,
        repo: repo,
        scope: GitHubTokenScope.read,
        actingUserId: actingUserId,
        skillSource: true,
      );
      return _clients.forSkillSource(
        workspaceId,
        owner,
        actingUserId: actingUserId,
      );
    } on GitHubScopeRefused catch (e) {
      final person = actingUserId;
      final transient = switch (e.code) {
        GitHubRefusal.providerUnavailable || GitHubRefusal.rateLimited => true,
        _ => false,
      };
      if (!transient &&
          person != null &&
          person.isNotEmpty &&
          await _clients.isSignedIn(person, workspaceId: workspaceId)) {
        return _clients.asPerson(person, workspaceId: workspaceId);
      }
      throw NetworkException(e.message, code: e.code.wire);
    }
  }

  /// A [SkillSourcePort] for [workspaceId] that routes every call through
  /// [clientFor].
  SkillSourcePort catalog(String workspaceId, {String? actingUserId}) =>
      _RoutedSkillSource(this, workspaceId, actingUserId);
}

final class _RoutedSkillSource implements SkillSourcePort {
  const _RoutedSkillSource(this._router, this._workspaceId, this._actingUserId);

  final SkillSourceGitHub _router;
  final String _workspaceId;
  final String? _actingUserId;

  Future<SkillSourcePort> _adapter(String owner, String repo) async =>
      GitHubSkillSourceAdapter(
        await _router.clientFor(
          _workspaceId,
          owner,
          repo,
          actingUserId: _actingUserId,
        ),
      );

  @override
  Future<SkillSourceRepoSnapshot> repoSnapshot(
    String owner,
    String repo,
  ) async => (await _adapter(owner, repo)).repoSnapshot(owner, repo);

  @override
  Future<List<SourceSkillListing>> listSkills(
    String owner,
    String repo, {
    String? ref,
  }) async => (await _adapter(owner, repo)).listSkills(owner, repo, ref: ref);

  @override
  Future<SourceSkillFiles> resolve(
    String owner,
    String repo,
    String skillFilePath, {
    String? ref,
  }) async => (await _adapter(
    owner,
    repo,
  )).resolve(owner, repo, skillFilePath, ref: ref);
}
