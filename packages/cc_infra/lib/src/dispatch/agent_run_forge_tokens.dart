part of 'agent_run_gateway.dart';

/// A scope and a lowercased `owner/name`: one credential a run can hold.
typedef _ForgeTokenKey = (ForgeTokenScope, String);

/// How a run's `gh` reads GitHub: the run holds no forge token, and its `gh`
/// asks the gateway for one when it needs it. (Its git holds none either: it
/// fetches through the gateway.)
///
/// The token is the run's own (`review`: it reads code, pull requests, issues
/// and CI, and writes nothing), for one repository, bounded by the person the
/// run acts for. It is minted on the first request, handed out only for a
/// GitHub repository the run works on ([AgentRunGrant.gitHubRepos]), and
/// revoked when the run's lease closes. A run that never reads GitHub mints
/// none.
// A namespace over constants and pure functions.
// ignore: avoid_classes_with_only_static_members
abstract final class AgentRunForgeTokens {
  /// Path a run asks for its read token on, with the repository as `repo`
  /// (`owner/name` or a remote URL). Without one, the run's only GitHub
  /// repository.
  static const String path = '/agent/forge-token';

  /// File name of [ghShim] in a run's shim directory.
  static const String ghShimName = 'gh';

  /// `gh` for a run, first on its `PATH`.
  ///
  /// It finds the repository the command is about (`--repo`, `GH_REPO`, else
  /// the checkout it runs in), asks the gateway for the run's read token for
  /// it through the agent run [client] and runs the real `gh` with that
  /// token. It holds no secret and decides nothing: the gateway refuses a
  /// repository the run does not work on, and `gh` then runs signed out.
  /// Writing to GitHub stays with Control Center's tools; the token cannot.
  static String ghShim(AgentRunClientLauncher client) =>
      r'''#!/bin/sh
# Control Center: gh for this agent run. The run holds no GitHub token: the
# agent run gateway hands it a read-only one for the repository a command is
# about, when that is one of the run's own.
gh=
saved_ifs=$IFS
IFS=:
set -f
for dir in $PATH; do
  candidate=$dir/gh
  if [ -f "$candidate" ] && [ -x "$candidate" ] && ! [ "$candidate" -ef "$0" ]; then
    gh=$candidate
    break
  fi
done
set +f
IFS=$saved_ifs
if [ -z "$gh" ]; then
  echo "gh: command not found" >&2
  exit 127
fi
repo=${GH_REPO:-}
previous=
for argument; do
  case "$previous" in
    -R | --repo) repo=$argument ;;
  esac
  case "$argument" in
    --repo=*) repo=${argument#--repo=} ;;
    -R?*) repo=${argument#-R} ;;
  esac
  previous=$argument
done
if [ -z "$repo" ]; then
  repo=$(git config --get remote.origin.url 2>/dev/null)
fi
if [ -n "$CC_AGENT_GATEWAY" ] && [ -n "$CC_AGENT_RUN_TOKEN" ]; then
  if token=$('''
      '${client.shellCommand} forge-token "\$repo"'
      r''') && [ -n "$token" ]; then
    GH_TOKEN=$token
    export GH_TOKEN
  fi
fi
exec "$gh" "$@"
''';

  static final RegExp _ownerAndName = RegExp(
    r'^([A-Za-z0-9_][A-Za-z0-9_.-]*)/([A-Za-z0-9_][A-Za-z0-9_.-]*?)(\.git)?$',
  );

  /// The GitHub repository [value] names: `owner/name`, `github.com/owner/name`
  /// or a remote URL in any shape git accepts. Null when it names none.
  static ForgeRemote? repoOf(String value) {
    final plain = _ownerAndName.firstMatch(value);
    if (plain != null) {
      return (forge: ForgeHost.github, owner: plain[1]!, name: plain[2]!);
    }
    final remote = parseForgeRemote(value);
    return remote == null || remote.forge != ForgeHost.github ? null : remote;
  }
}

/// The forge tokens the gateway mints for a run and revokes when its lease
/// closes: `write` to forward a push the policy allowed (never returned to
/// the run), and `review` for what the run itself reads
/// ([AgentRunForgeTokens]).
extension _ForgeTokens on AgentRunGateway {
  /// Hands the run its read token for one of the repositories it works on.
  ///
  /// Which repositories those are comes from the run's grant, never from the
  /// request; the broker then holds the mint to the workspace's link and to
  /// what the person the run acts for may read.
  Future<void> _forgeToken(
    HttpRequest request,
    AgentRunGrant grant,
    String secret,
  ) async {
    final asked = (request.uri.queryParameters['repo'] ?? '').trim();
    final named = asked.isEmpty ? null : AgentRunForgeTokens.repoOf(asked);
    final repo = asked.isEmpty
        ? grant.soleGitHubRepo
        : named == null
        ? null
        : grant.repoOn(ForgeHost.github, named.owner, named.name);
    if (repo == null) {
      final own = [for (final r in grant.gitHubRepos) '${r.owner}/${r.name}'];
      return AgentRunGateway._plain(
        request,
        asked.isEmpty ? HttpStatus.badRequest : HttpStatus.forbidden,
        own.isEmpty
            ? 'Control Center: this run works on no GitHub repository, so it '
                  'has no GitHub token.'
            : asked.isEmpty
            ? 'Control Center: this run works on several repositories '
                  '(${own.join(', ')}). Run the command inside one of them, '
                  'or name it (--repo owner/name).'
            : 'Control Center: this run has no GitHub token for '
                  '${named == null ? 'that' : '${named.owner}/${named.name}'}. '
                  'It reads the repositories it works on: ${own.join(', ')}.',
      );
    }
    const scope = ForgeTokenScope.review;
    final token = await _token(grant, secret, repo.owner, repo.name, scope);
    if (token == null) {
      return AgentRunGateway._plain(
        request,
        HttpStatus.serviceUnavailable,
        _tokenRefusal(secret, repo.owner, repo.name, scope) ??
            'Control Center has no GitHub credential that can read '
                '${repo.owner}/${repo.name}. Install the GitHub App on it or '
                'connect GitHub.',
      );
    }
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.text
      ..headers.set(HttpHeaders.cacheControlHeader, 'no-store')
      ..write(token);
    await request.response.close();
  }

  /// The [scope] token for `owner/name` on this run, minted at most once at a
  /// time: two requests minting in parallel would leave the first credential
  /// in nobody's cache, live and never revoked.
  Future<String?> _token(
    AgentRunGrant grant,
    String secret,
    String owner,
    String name,
    ForgeTokenScope scope,
  ) {
    final key = _tokenKey(scope, owner, name);
    final flights = _tokenMints.putIfAbsent(secret, () => {});
    final inFlight = flights[key];
    if (inFlight != null) {
      return inFlight;
    }
    final mint = _mintToken(grant, secret, key, owner, name);
    flights[key] = mint;
    return mint.whenComplete(() {
      if (identical(_tokenMints[secret]?[key], mint)) {
        _tokenMints[secret]!.remove(key);
      }
    });
  }

  Future<String?> _mintToken(
    AgentRunGrant grant,
    String secret,
    _ForgeTokenKey key,
    String owner,
    String name,
  ) async {
    final cache = _tokens.putIfAbsent(secret, () => {});
    final cached = cache[key];
    final expiresAt = cached?.expiresAt;
    if (cached != null &&
        (expiresAt == null ||
            expiresAt.isAfter(
              DateTime.now().add(const Duration(minutes: 5)),
            ))) {
      return cached.environment['GH_TOKEN'];
    }
    // A push for a person rides their own sign-in narrowed to this one
    // repository, so GitHub's "the last pusher cannot approve" rule sees
    // them. It never leaves the gateway. A run nobody asked for pushes as
    // the App on a server's or workspace's own App; on Control Center
    // Connect its bot never pushes, so the broker refuses and its note
    // ("needs a person who asked for it") is what git prints. What a run
    // reads with is the workspace's automation, bounded by the same person.
    final (scope, _) = key;
    final actor = grant.actingUserId;
    final minted = await _broker.mint(
      conversationId: grant.conversationId,
      scope: scope,
      repoOwner: owner,
      repoName: name,
      actingUserId: actor,
      workspaceId: grant.workspaceId,
      personal:
          scope == ForgeTokenScope.write && actor != null && actor.isNotEmpty,
    );
    final token = minted.environment['GH_TOKEN'];
    // The lease closed while the mint was out: nothing will revoke this one
    // later, so it is revoked now and the request gets no token.
    final closed = !_grants.containsKey(secret);
    if (token == null || token.isEmpty || closed) {
      if (!closed && minted.notes.isNotEmpty) {
        _tokenRefusals.putIfAbsent(secret, () => {})[key] = minted.notes.join(
          ' ',
        );
      }
      await _revokeQuietly(minted.handle);
      return null;
    }
    _tokenRefusals[secret]?.remove(key);
    final replaced = cache[key];
    cache[key] = minted;
    if (replaced != null && replaced.handle != minted.handle) {
      unawaited(_revokeQuietly(replaced.handle));
    }
    return token;
  }

  /// Why the last [scope] mint for `owner/name` on this run was refused, as
  /// `Control Center: <reason>`, or null when none was.
  String? _tokenRefusal(
    String secret,
    String owner,
    String name,
    ForgeTokenScope scope,
  ) {
    final note = _tokenRefusals[secret]?[_tokenKey(scope, owner, name)];
    return note == null ? null : 'Control Center: $note';
  }

  static _ForgeTokenKey _tokenKey(
    ForgeTokenScope scope,
    String owner,
    String name,
  ) => (scope, '${owner.toLowerCase()}/${name.toLowerCase()}');

  Future<void> _revokeQuietly(String handle) async {
    try {
      await _broker.revoke(handle);
    } on Object catch (e) {
      CcInfraLog.warning('agent gateway: revoke failed: $e');
    }
  }
}
