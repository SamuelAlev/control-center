import 'package:cc_domain/core/domain/entities/github_user.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/agent_commit_identity.dart';
import 'package:cc_server_core/src/forge/forge_commit_author_probe.dart';
import 'package:cc_server_core/src/forge/github_clients.dart';
import 'package:cc_server_core/src/forge/github_rest.dart';

/// Who the commits made through Control Center name, credit and are signed
/// by ([AgentCommitIdentity]): an agent run's ([forRun]) and a person's own
/// in the IDE ([forPerson]).
///
/// **A person started the work.** The commits are theirs: author and
/// committer under an address their forge verified for their own sign-in
/// ([verifiedPerson]: on GitHub their noreply address, on GitLab or
/// Bitbucket the email the forge reports for the signed-in account; never a
/// self-set profile email), signed with their commit signing key when they
/// have one (never on Bitbucket, where an SSH key is also a login), and
/// crediting Control Center when their attribution setting is on.
///
/// **Nobody did.** The commits are the agent's: on a GitHub repository whose
/// workspace has a GitHub App (its own, the server's, or Connect's) the
/// App's bot, `<slug>[bot]` at `<bot user id>+<slug>[bot]@users.noreply.github.com`,
/// which GitHub attributes to the App; anywhere else
/// [AgentCommitIdentity.controlCenter]. They are never signed, and credit
/// each person accountable for the run (who armed the trigger behind it)
/// whose attribution setting is on and whom the forge vouches for.
///
/// A person who asked for a run but has no verified address there gets the
/// agent's identity too: a run never writes an unverified author. Only a
/// commit a person makes by hand may carry their unverified profile identity
/// ([forPerson]'s `unverified`), and that one is never signed.
final class AgentCommitIdentities {
  /// Creates the resolver.
  AgentCommitIdentities({
    required this.userExists,
    required this.appSlug,
    required this.botUserId,
    required this.githubAccount,
    required this.forgeAuthor,
    required this.creditsCoAuthor,
    required this.signingKeyOf,
    required this.accountableFor,
  });

  /// The server's resolver: the App slug from [github]'s lane for the
  /// workspace (an own or workspace App's `GET /app`, or Connect's signed
  /// config), the bot's user id from GitHub's public `GET /users/<login>`,
  /// and a GitLab or Bitbucket identity from the person's own token
  /// ([probeForgeCommitAuthor], remembered per token).
  factory AgentCommitIdentities.forServer({
    required GitHubClients github,
    required Future<bool> Function(String userId) userExists,
    required Future<GitHubUser?> Function(String userId, String? workspaceId)
    githubAccount,
    required Future<String?> Function(
      ForgeHost forge,
      String userId,
      String? workspaceId,
    )
    personToken,
    required Future<bool> Function(String userId, String? workspaceId)
    creditsCoAuthor,
    required Future<String?> Function(String userId) signingKeyOf,
    required Future<Set<String>> Function(String workspaceId, String runLogId)
    accountableFor,
    GitHubRest? rest,
    Future<GitPerson?> Function(ForgeHost forge, String token)? probe,
  }) {
    final transport = rest ?? GitHubRest();
    final probeAuthor = probe ?? probeForgeCommitAuthor;
    final authors = <String, GitPerson>{};
    return AgentCommitIdentities(
      userExists: userExists,
      creditsCoAuthor: creditsCoAuthor,
      signingKeyOf: signingKeyOf,
      accountableFor: accountableFor,
      appSlug: (workspaceId) async {
        final lane = await github.laneFor(workspaceId);
        switch (lane) {
          case GitHubLane.none:
            return null;
          case GitHubLane.workspaceApp || GitHubLane.ownApp:
            final app = await github.lanes.appFor(workspaceId, lane);
            return (await app?.botInfo())?.slug;
          case GitHubLane.connect:
            final config = await github.lanes.connectGitHub(
              await github.connect.targetFor(workspaceId),
            );
            return config?.appSlug;
        }
      },
      botUserId: (login) async {
        final response = await transport.send('GET', '/users/$login');
        final json = response.json;
        final id = json is Map ? json['id'] : null;
        return response.status == 200 && id is int ? id : null;
      },
      githubAccount: githubAccount,
      forgeAuthor: (forge, userId, workspaceId) async {
        final token = await personToken(forge, userId, workspaceId);
        if (token == null || token.isEmpty) {
          return null;
        }
        final key = '${forge.gitHost}\u0000$token';
        final known = authors[key];
        if (known != null) {
          return known;
        }
        final probed = await probeAuthor(forge, token);
        if (probed != null) {
          if (authors.length >= 256) {
            authors.clear();
          }
          authors[key] = probed;
        }
        return probed;
      },
    );
  }

  /// Whether `userId` names a user.
  final Future<bool> Function(String userId) userExists;

  /// The slug of `workspaceId`'s GitHub App, or null when it has none (or
  /// GitHub did not answer for it).
  final Future<String?> Function(String workspaceId) appSlug;

  /// The GitHub user id of the bot account `botLogin`, or null when GitHub
  /// did not answer.
  final Future<int?> Function(String botLogin) botUserId;

  /// `userId`'s GitHub account from their own sign-in in `workspaceId`, or
  /// null when they are not signed in.
  final Future<GitHubUser?> Function(String userId, String? workspaceId)
  githubAccount;

  /// The name and verified email GitLab or Bitbucket reports for `userId`'s
  /// own sign-in in `workspaceId`, or null.
  final Future<GitPerson?> Function(
    ForgeHost forge,
    String userId,
    String? workspaceId,
  )
  forgeAuthor;

  /// Whether commits that involve `userId` in `workspaceId` carry co-author
  /// credit: the workspace's attribution override, else their own
  /// preference (`resolveAgentCommitAttribution`).
  final Future<bool> Function(String userId, String? workspaceId)
  creditsCoAuthor;

  /// The `ssh-ed25519 <base64>` key `userId`'s commits are signed with, or
  /// null when they set up none.
  final Future<String?> Function(String userId) signingKeyOf;

  /// Everyone accountable for the run nobody asked for that `runLogId`
  /// records in `workspaceId`: the people who armed the trigger behind it.
  final Future<Set<String>> Function(String workspaceId, String runLogId)
  accountableFor;

  final Map<String, int> _botIds = {};

  /// The agent identity for commits on [forge] (null or local: no forge
  /// checkout, treated as GitHub) in [workspaceId].
  Future<GitPerson> agentFor(String? workspaceId, {ForgeHost? forge}) async {
    if (workspaceId == null || workspaceId.isEmpty || !_isGitHub(forge)) {
      return AgentCommitIdentity.controlCenter;
    }
    final slug = await appSlug(workspaceId);
    if (slug == null || slug.isEmpty) {
      return AgentCommitIdentity.controlCenter;
    }
    final login = '$slug[bot]';
    var id = _botIds[login];
    if (id == null) {
      // An App's bot account never changes id: one answer serves for good.
      // Until GitHub answers, the bare-login noreply form stands in.
      final fetched = await botUserId(login);
      if (fetched != null && fetched > 0) {
        id = _botIds[login] = fetched;
      }
    }
    return AgentCommitIdentity.githubAppBot(botUserId: id ?? 0, slug: slug);
  }

  /// Every identity that is "the agent" in [workspaceId]: its GitHub App's
  /// bot (when it has one) and Control Center. A commit authored as one of
  /// these is agent work wherever it is pushed from.
  Future<List<GitPerson>> agentsOf(String workspaceId) async {
    final bot = await agentFor(workspaceId, forge: ForgeHost.github);
    return [
      bot,
      if (bot != AgentCommitIdentity.controlCenter)
        AgentCommitIdentity.controlCenter,
    ];
  }

  /// The commit identity of an agent run [userId] asked for in
  /// [workspaceId] (null [userId]: nobody did; [runLogId] then says who is
  /// accountable for it), working in a checkout on [forge]. Null when
  /// [userId] names no user.
  Future<AgentCommitIdentity?> forRun(
    String? userId, {
    String? workspaceId,
    String? runLogId,
    ForgeHost? forge,
  }) async {
    if (userId == null || userId.isEmpty) {
      return AgentCommitIdentity.automation(
        agent: await agentFor(workspaceId, forge: forge),
        accountable: await _accountable(workspaceId, runLogId, forge),
      );
    }
    if (!await userExists(userId)) {
      return null;
    }
    return await forPerson(userId, workspaceId: workspaceId, forge: forge) ??
        AgentCommitIdentity.automation(
          agent: await agentFor(workspaceId, forge: forge),
        );
  }

  /// The identity of commits that are [userId]'s own on [forge] in
  /// [workspaceId]: their verified address, their signing key and Control
  /// Center's credit when their attribution setting is on.
  ///
  /// With no verified address the answer is null, unless [unverified] names
  /// what to commit as instead (a commit they make by hand in the IDE keeps
  /// their profile's git identity, as from their own clone): that identity is
  /// never signed, since no forge would show its signature as theirs.
  Future<AgentCommitIdentity?> forPerson(
    String userId, {
    String? workspaceId,
    ForgeHost? forge,
    GitPerson? unverified,
  }) async {
    final verified = await verifiedPerson(
      userId,
      workspaceId: workspaceId,
      forge: forge,
    );
    final person = verified ?? unverified;
    if (person == null) {
      return null;
    }
    return AgentCommitIdentity.person(
      person,
      creditAgent: await creditsCoAuthor(userId, workspaceId),
      signingKey: verified == null || !_verifiesSigningKeys(forge)
          ? null
          : await signingKeyOf(userId),
    );
  }

  /// Whether a commit signed with a person's signing key can show as
  /// verified on [forge] without that key being anything more than a
  /// signing key there. GitHub and GitLab register signing keys as such.
  /// Bitbucket has no signing-only key: an SSH key on a Bitbucket account is
  /// also a git login, so nobody should add this server's key there and
  /// commits on Bitbucket stay unsigned.
  static bool _verifiesSigningKeys(ForgeHost? forge) =>
      forge != ForgeHost.bitbucket;

  /// [userId] as a git identity on [forge], under an address that forge
  /// verified for their own sign-in in [workspaceId], or null.
  Future<GitPerson?> verifiedPerson(
    String userId, {
    String? workspaceId,
    ForgeHost? forge,
  }) async {
    if (!_isGitHub(forge)) {
      final reported = await forgeAuthor(forge!, userId, workspaceId);
      return reported == null ? null : _writable(reported.name, reported.email);
    }
    final account = await githubAccount(userId, workspaceId);
    if (account == null || account.login.isEmpty) {
      return null;
    }
    return _writable(
      account.name ?? '',
      AgentCommitIdentity.githubNoreply(
        accountId: account.id,
        login: account.login,
      ),
      fallbackName: account.login,
    );
  }

  static final RegExp _notWritable = RegExp('[<>\r\n\x00]');

  /// [name] and [email] as git writes them ([AgentCommitIdentity.asGitWrites]),
  /// with [fallbackName] standing in for a name git would write as nothing
  /// (a display name of quotes or punctuation only). Null when either still
  /// is not a git identity: that person is then not written as an author.
  static GitPerson? _writable(
    String name,
    String email, {
    String? fallbackName,
  }) {
    bool usable(String text) =>
        text.isNotEmpty && !text.contains(_notWritable);
    final writtenEmail = AgentCommitIdentity.asGitWrites(email);
    var writtenName = AgentCommitIdentity.asGitWrites(name);
    if (!usable(writtenName)) {
      writtenName = AgentCommitIdentity.asGitWrites(fallbackName ?? '');
    }
    return usable(writtenName) && usable(writtenEmail)
        ? (name: writtenName, email: writtenEmail)
        : null;
  }

  /// The people a run nobody asked for credits: everyone accountable for it
  /// whose attribution setting is on and whom [forge] vouches for, in a
  /// stable order.
  Future<List<GitPerson>> _accountable(
    String? workspaceId,
    String? runLogId,
    ForgeHost? forge,
  ) async {
    if (workspaceId == null ||
        workspaceId.isEmpty ||
        runLogId == null ||
        runLogId.isEmpty) {
      return const [];
    }
    final people = <GitPerson>[];
    for (final userId in (await accountableFor(
      workspaceId,
      runLogId,
    )).toList()..sort()) {
      if (userId.isEmpty ||
          !await userExists(userId) ||
          !await creditsCoAuthor(userId, workspaceId)) {
        continue;
      }
      final person = await verifiedPerson(
        userId,
        workspaceId: workspaceId,
        forge: forge,
      );
      if (person != null && !people.any((p) => p.email == person.email)) {
        people.add(person);
      }
    }
    return people;
  }

  static bool _isGitHub(ForgeHost? forge) =>
      forge == null || forge == ForgeHost.github || forge == ForgeHost.local;
}
