part of 'repo_ide_data_service.dart';

/// The identity of the commits `userId` makes by hand on `forge` in
/// `workspaceId` (`AgentCommitIdentities.forPerson`): their verified address
/// and signing key, else `unverified` (their profile's git identity), with
/// Control Center's credit when their attribution setting is on.
typedef PersonCommitIdentity =
    Future<AgentCommitIdentity?> Function({
      required String workspaceId,
      required String userId,
      required ForgeHost forge,
      GitPerson? unverified,
    });

/// What authenticates server-run git against `https://github.com/` with
/// [token]: an `Authorization` header in git's config environment, never
/// argv or a URL. Empty without a token.
Map<String, String> _githubAuthEnv(String? token) =>
    token == null || token.isEmpty
    ? const {}
    : {
        'GIT_CONFIG_PARAMETERS': forgeGitAuthConfigParameter(
          ForgeHost.github,
          token,
        ),
      };

/// Whose commit a commit made in the IDE is, and its signature.
extension _IdeCommitIdentity on RepoIdeDataService {
  /// The identity of the commits [userId] makes by hand in [repoId]'s
  /// checkout: see [PersonCommitIdentity]. With no resolver wired it is
  /// [profile] alone; null when there is nobody to name.
  Future<AgentCommitIdentity?> _personIdentity(
    String workspaceId,
    String repoId,
    String? userId, {
    GitPerson? profile,
  }) async {
    final resolve = _commitIdentity;
    if (resolve == null || userId == null || userId.isEmpty) {
      return profile == null ? null : AgentCommitIdentity.person(profile);
    }
    final repo = await _linkedRepo(workspaceId, repoId);
    return resolve(
      workspaceId: workspaceId,
      userId: userId,
      forge: repo?.forge ?? ForgeHost.local,
      unverified: profile,
    );
  }

  /// Signs the commit [userId] just made in [root] (`HEAD`) with their
  /// signing key, when [identity] has one. Returns why it could not be
  /// signed, or null.
  Future<String?> _signCommitted(
    String root,
    String? userId,
    AgentCommitIdentity? identity,
  ) => _sign(root, userId, identity, const []);

  /// Signs, with [identity]'s key, the commits of [userId]'s own that the
  /// push about to happen sends, then checks that every one of them is
  /// signed: run immediately before each IDE push.
  ///
  /// What the push sends is what the remote lacks: `<remoteTip>..HEAD` from
  /// the remote branch's fetched tip, or, without one (a branch the remote
  /// does not have), everything no remote-tracking ref reaches. Without a key
  /// nothing is signed or checked. Returns why the push must not happen, or
  /// null.
  Future<String?> _signOutgoing(
    String root,
    String? userId,
    AgentCommitIdentity? identity, {
    String? remoteTip,
  }) async {
    final range = remoteTip == null
        ? const ['HEAD', '--not', '--remotes']
        : ['$remoteTip..HEAD'];
    final error = await _sign(root, userId, identity, range);
    if (error != null) {
      return 'Nothing was pushed. $error';
    }
    final resigner = _resigner;
    if (identity?.signingKey == null ||
        resigner == null ||
        userId == null ||
        userId.isEmpty) {
      return null;
    }
    try {
      final unsigned = await resigner.unsignedOwn(
        root: root,
        identity: identity!,
        revisions: range,
      );
      if (unsigned.isEmpty) {
        return null;
      }
      final ids = unsigned.map((oid) => oid.substring(0, 12)).join(', ');
      return 'Nothing was pushed: your commits $ids are not signed with your '
          'key. They sit below a commit someone else signed, and signing '
          'them would strip that signature. Rebase them above it, then push '
          'again.';
    } on ProcessException catch (e) {
      return 'Nothing was pushed: could not check the commit signatures: '
          '${e.message}';
    }
  }

  Future<String?> _sign(
    String root,
    String? userId,
    AgentCommitIdentity? identity,
    List<String> revisions,
  ) async {
    final resigner = _resigner;
    if (identity == null ||
        identity.signingKey == null ||
        resigner == null ||
        userId == null ||
        userId.isEmpty) {
      return null;
    }
    try {
      await resigner.sign(
        root: root,
        userId: userId,
        identity: identity,
        revisions: revisions,
      );
      return null;
    } on CommitSigningUnavailable catch (e) {
      return 'Could not sign the commit: ${e.message}';
    } on ProcessException catch (e) {
      return 'Could not sign the commit: ${e.message}';
    }
  }
}
