part of 'agent_run_gateway.dart';

/// The token the server keeps for a run's fetches of one of its GitLab or
/// Bitbucket repositories, or why there is none (`token` null, `refusal`
/// saying what to connect). The person the run acts for ([actingUserId]) is
/// fetched for on their own token; a run nobody asked for, on the
/// repository's automation token. Never one in place of the other.
typedef AgentFetchCredential =
    Future<({String? token, String? refusal})> Function(
      String workspaceId,
      ForgeRemote repo,
      String? actingUserId,
    );

/// What a request under `/agent/git/` asks for: a fetch or a push of one
/// repository on one forge, read from the end of its path.
final class _GitRoute {
  const _GitRoute._({
    required this.forge,
    required this.owner,
    required this.name,
    required this.push,
    required this.advertisement,
  });

  final ForgeHost forge;

  /// The owner, with GitLab's nested groups (`group/sub`).
  final String owner;

  /// The repository's name, without `.git`.
  final String name;

  /// A `git-receive-pack` request; otherwise `git-upload-pack`.
  final bool push;

  /// The ref advertisement (`GET info/refs?service=…`); otherwise the POST.
  final bool advertisement;

  /// The service git asked for.
  String get service => push ? 'git-receive-pack' : 'git-upload-pack';

  /// What follows `<owner>/<name>.git/` upstream.
  String get rest => advertisement ? 'info/refs' : service;

  /// Reads `/agent/git/<host>/<owner…>/<repo>[.git]/<suffix>`. The suffix
  /// decides, the segment before it is the repository and the rest is the
  /// owner; every segment must pass [AgentRunLease.gitPath]. Anything else
  /// is refused, in one line git prints as `remote:`.
  static ({_GitRoute? route, String refusal}) parse(String method, Uri uri) {
    ({_GitRoute? route, String refusal}) refuse(String why) =>
        (route: null, refusal: why);
    final segments = uri.pathSegments;
    final host = segments.length > 2 ? segments[2] : '';
    final forge = ForgeHost.supported
        .where((f) => f.gitHost == host)
        .firstOrNull;
    if (forge == null) {
      return refuse(
        'Control Center proxies git only for '
        '${[for (final f in ForgeHost.supported) f.gitHost].join(', ')}.',
      );
    }
    final tail = segments.sublist(3);
    for (var i = 0; i + 1 < tail.length; i++) {
      if (tail[i] == 'info' && tail[i + 1] == 'lfs') {
        return refuse('Control Center does not proxy Git LFS.');
      }
    }
    final service = uri.queryParameters['service'];
    final int repoAt;
    final bool advertisement;
    final String asked;
    if (method == 'GET' &&
        tail.length >= 3 &&
        tail[tail.length - 2] == 'info' &&
        tail.last == 'refs' &&
        (service == 'git-upload-pack' || service == 'git-receive-pack')) {
      repoAt = tail.length - 3;
      advertisement = true;
      asked = service!;
    } else if (method == 'POST' &&
        tail.length >= 2 &&
        (tail.last == 'git-upload-pack' || tail.last == 'git-receive-pack')) {
      repoAt = tail.length - 2;
      advertisement = false;
      asked = tail.last;
    } else {
      return refuse(
        'Control Center proxies only git fetches and pushes over smart HTTP.',
      );
    }
    final segment = tail[repoAt];
    final name = segment.endsWith('.git')
        ? segment.substring(0, segment.length - 4)
        : segment;
    final repo = (
      forge: forge,
      owner: tail.sublist(0, repoAt).join('/'),
      name: name,
    );
    if (repoAt < 1 || AgentRunLease.gitPath(repo) == null) {
      return refuse('Control Center cannot proxy that repository path.');
    }
    return (
      route: _GitRoute._(
        forge: forge,
        owner: repo.owner,
        name: repo.name,
        push: asked == 'git-receive-pack',
        advertisement: advertisement,
      ),
      refusal: '',
    );
  }
}

/// The gateway's fetch proxy.
///
/// A fetch is a read, so it asks no one: the "network egress" rule for the
/// forge's host is resolved, and only a deny refuses it (as only a deny takes
/// a sandbox's network away). A repository the run works on is forwarded on
/// a credential the server keeps: on GitHub the run's `review` token
/// ([_ForgeTokens]), on GitLab and Bitbucket the [AgentFetchCredential].
///
/// Any other repository is forwarded with no credential at all, as git would
/// fetch it without the gateway: the rewrites are prefix matches, so
/// `acme/widgets` also routes `acme/widgets-extra` here. That holds only for
/// a host a sandbox reaches by itself ([kBaselineAllowedDomains]); on any
/// other host it is refused, so the proxy opens no destination a run could
/// not already reach. The credential goes upstream only: never into a
/// response, a log line or an error.
extension _Fetch on AgentRunGateway {
  Future<void> _fetch(
    HttpRequest request,
    AgentRunGrant grant,
    String secret,
    _GitRoute route,
  ) async {
    final forge = route.forge;
    final summary =
        'git fetch from ${forge.gitHost}/${route.owner}/'
        '${route.name}';
    const classes = {ActionClass.networkEgress};
    final resolution = await _guard.resolve(
      workspaceId: grant.workspaceId,
      classes: classes,
      spaceId: grant.spaceId,
      agentId: grant.agentId,
      mode: grant.mode,
      request: ActionRequest(classes: classes, hosts: [forge.gitHost]),
    );
    if (resolution.decision == ActionDecision.deny) {
      await request.drain<void>();
      _guard.recordOutcome(
        workspaceId: grant.workspaceId,
        resolution: resolution,
        applied: ActionDecision.deny,
        classes: classes,
        agentId: grant.agentId,
        spaceId: grant.spaceId,
        actionSummary: summary,
        onBehalfOfUserId: grant.actingUserId,
        runId: grant.runId,
      );
      return AgentRunGateway._plain(
        request,
        HttpStatus.forbidden,
        'Control Center policy: ${resolution.driving.reason}',
      );
    }

    // The run's own repository is forwarded under the name the server
    // recorded, so its credential only ever reaches that path.
    final own = grant.repoOn(forge, route.owner, route.name);
    if (own == null && !kBaselineAllowedDomains.contains(forge.gitHost)) {
      await request.drain<void>();
      return AgentRunGateway._plain(
        request,
        HttpStatus.forbidden,
        'Control Center proxies only this run\'s own repositories on '
        '${forge.displayName}.',
      );
    }
    String? authorization;
    if (own != null) {
      final credential = await _fetchAuthorization(grant, secret, own);
      if (credential.authorization == null) {
        await request.drain<void>();
        return AgentRunGateway._plain(
          request,
          HttpStatus.serviceUnavailable,
          credential.refusal,
        );
      }
      authorization = credential.authorization;
    }
    final upstream = _upstream(
      forge,
      own?.owner ?? route.owner,
      own?.name ?? route.name,
      route.rest,
      service: route.advertisement ? route.service : null,
    );
    final client = _httpClient();
    try {
      final out = await AgentRunGateway._openUpstream(
        client,
        request,
        upstream,
        authorization,
      );
      if (!route.advertisement) {
        // Negotiation and packs are streamed both ways, never held.
        out.headers.chunkedTransferEncoding = true;
        await out.addStream(request);
      }
      final response = await out.close();
      await AgentRunGateway._relay(request, response, forge);
    } finally {
      client.close();
    }
  }

  /// The `Authorization` a fetch of the run's own [repo] is forwarded with,
  /// or the refusal git prints instead.
  Future<({String? authorization, String refusal})> _fetchAuthorization(
    AgentRunGrant grant,
    String secret,
    ForgeRemote repo,
  ) async {
    final forge = repo.forge;
    final fullName = '${repo.owner}/${repo.name}';
    if (forge == ForgeHost.github) {
      const scope = ForgeTokenScope.review;
      final token = await _token(grant, secret, repo.owner, repo.name, scope);
      return token == null
          ? (
              authorization: null,
              refusal:
                  _tokenRefusal(secret, repo.owner, repo.name, scope) ??
                  'Control Center has no GitHub credential that can read '
                      '$fullName. Install the GitHub App on it or connect '
                      'GitHub.',
            )
          : (
              authorization: forgeGitBasicAuthorization(forge, token),
              refusal: '',
            );
    }
    final lookup = _fetchCredential;
    final answer = lookup == null
        ? null
        : await lookup(grant.workspaceId, repo, grant.actingUserId);
    final token = answer?.token;
    if (token == null || token.isEmpty) {
      final refusal = answer?.refusal;
      return (
        authorization: null,
        refusal: refusal != null && refusal.isNotEmpty
            ? 'Control Center: $refusal'
            : 'Control Center has no ${forge.displayName} credential that '
                  'can read $fullName.',
      );
    }
    return (
      authorization: forgeGitBasicAuthorization(forge, token),
      refusal: '',
    );
  }
}
