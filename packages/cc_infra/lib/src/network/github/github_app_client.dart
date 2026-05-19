import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/sandboxing/github_app_token_minter.dart'
    show GitHubAppConfig, GitHubAppTokenMinter, MintedToken;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:dio/dio.dart';

/// The server's own bot identity on GitHub: what a PR author @mentions and
/// what the app's comments are authored as.
class GitHubAppBotInfo {
  /// Creates a [GitHubAppBotInfo].
  const GitHubAppBotInfo({required this.slug, required this.botLogin});

  /// The app's slug (the human-chosen name in its URL).
  final String slug;

  /// The bot account login, `<slug>[bot]` — the identity comments, reviews
  /// and mentions resolve to.
  final String botLogin;

  /// The wire shape the settings surface renders.
  Map<String, Object?> toJson() => {'slug': slug, 'bot_login': botLogin};
}

/// One installation of the GitHub App — an account (user or org) that installed
/// it, and therefore a set of repositories the server may read.
class GitHubInstallation {
  /// Creates a [GitHubInstallation].
  const GitHubInstallation({
    required this.id,
    required this.account,
    this.repositorySelection = '',
  });

  /// The numeric installation id.
  final int id;

  /// The login of the account that installed the app.
  final String account;

  /// `all` or `selected` — which of the account's repositories are covered.
  final String repositorySelection;

  /// The wire shape the settings screen renders.
  Map<String, Object?> toJson() => {
    'id': id,
    'account': account,
    'repository_selection': repositorySelection,
  };
}

/// The server's own GitHub identity, discovered rather than configured.
///
/// This is what answers work no human asked for: webhook fan-out, PR polling,
/// ticket sync, private-asset fetches. It is deliberately NOT a person's PAT —
/// background work authenticating as whoever happened to onboard first stops
/// the moment they leave, and installation tokens carry their own rate limit
/// instead of eating a human's.
///
/// It sits ON TOP of [GitHubAppTokenMinter] (which the sandbox broker already
/// uses to mint repo-scoped tokens for agent runs) and adds the two things the
/// server lane needs and a sandbox launch does not: discovering WHICH
/// installations exist, so an owner can be resolved to one without the operator
/// pasting an installation id, and caching the minted token for its lifetime.
///
/// Nothing here retries or throws upward: a failure resolves to null so the
/// caller falls through to the next credential lane, which is what keeps a
/// misconfigured app from taking the server's forge access down with it.
class GitHubAppClient {
  /// Creates a [GitHubAppClient].
  ///
  /// [dio] is injected by tests; production builds get an `api.github.com`
  /// client.
  GitHubAppClient({
    required String appId,
    required String privateKeyPem,
    Dio? dio,
    DateTime Function()? now,
  }) : _appId = appId,
       _privateKeyPem = privateKeyPem,
       _dio = dio ?? createDio(baseUrl: 'https://api.github.com'),
       _now = now ?? (() => DateTime.now().toUtc());

  /// Builds a client, or null when the credentials are absent or the private
  /// key does not parse. Null means "this server has no app identity", which
  /// every caller already handles by falling through to the next lane.
  static GitHubAppClient? tryCreate({
    required String appId,
    required String privateKeyPem,
    Dio? dio,
  }) {
    if (appId.isEmpty || privateKeyPem.isEmpty) {
      return null;
    }
    try {
      // Parsing here (rather than at first use) is what lets the settings
      // screen reject a bad key while the operator is still looking at it.
      RSAPrivateKey(privateKeyPem);
    } on Object {
      return null;
    }
    return GitHubAppClient(
      appId: appId,
      privateKeyPem: privateKeyPem,
      dio: dio,
    );
  }

  final String _appId;
  final String _privateKeyPem;
  final Dio _dio;
  final DateTime Function() _now;

  final Map<int, ({String token, DateTime expiresAt})> _tokens = {};
  final Map<String, int> _installationByOwner = {};
  List<GitHubInstallation>? _installations;
  GitHubAppBotInfo? _botInfo;

  GitHubAppTokenMinter _minterFor(int installationId) => GitHubAppTokenMinter(
    dio: _dio,
    config: GitHubAppConfig(
      appId: _appId,
      privateKeyPem: _privateKeyPem,
      installationId: '$installationId',
    ),
  );

  /// The App JWT itself, exposed so a test can verify the claims and a
  /// settings probe can call `/app` without minting anything.
  String buildAppJwt() => JWT({'iss': _appId}).sign(
    RSAPrivateKey(_privateKeyPem),
    algorithm: JWTAlgorithm.RS256,
    expiresIn: const Duration(minutes: 9),
  );

  /// The app's bot identity (`GET /app`), or null when it cannot be read.
  ///
  /// The bot login is what a PR comment must @mention and what the app's own
  /// comments come back authored as — both the mention matcher and the loop
  /// guard key on it. Cached after the first success (an app's slug does not
  /// change); a failure is not cached, and never throws: a caller without a
  /// bot login simply has no conversation surface yet.
  Future<GitHubAppBotInfo?> botInfo() async {
    final cached = _botInfo;
    if (cached != null) {
      return cached;
    }
    try {
      final response = await _dio.get<dynamic>('/app', options: _appOptions());
      final data = response.data;
      if (data is! Map<String, dynamic>) {
        return null;
      }
      final slug = data['slug'] as String? ?? '';
      if (slug.isEmpty) {
        return null;
      }
      return _botInfo = GitHubAppBotInfo(
        slug: slug,
        botLogin:
            (data['bot'] as Map<String, dynamic>?)?['username'] as String? ??
            '$slug[bot]',
      );
    } on DioException {
      return null;
    }
  }

  /// Every account that has installed the app.
  ///
  /// Cached after the first success: installations change when a human clicks
  /// Install, not per request. [refresh] re-reads them, which is what the
  /// settings "test" action does.
  Future<List<GitHubInstallation>> installations({bool refresh = false}) async {
    final cached = _installations;
    if (cached != null && !refresh) {
      return cached;
    }
    try {
      final response = await _dio.get<dynamic>(
        '/app/installations',
        options: _appOptions(),
      );
      final data = response.data;
      if (data is! List) {
        return _installations = const [];
      }
      final parsed = [
        for (final entry in data.whereType<Map>())
          GitHubInstallation(
            id: (entry['id'] as num?)?.toInt() ?? 0,
            account: (entry['account'] as Map?)?['login'] as String? ?? '',
            repositorySelection: entry['repository_selection'] as String? ?? '',
          ),
      ].where((i) => i.id != 0).toList();
      for (final installation in parsed) {
        if (installation.account.isNotEmpty) {
          _installationByOwner[installation.account.toLowerCase()] =
              installation.id;
        }
      }
      return _installations = parsed;
    } on DioException {
      // Do NOT cache a failure: a network blip would otherwise leave the app
      // permanently "not installed anywhere" until the next restart.
      return const [];
    }
  }

  /// An installation token covering [owner] (an org or user login), or null
  /// when the app is not installed there.
  ///
  /// Resolution is by ACCOUNT, not by repository: `/repos/{o}/{r}/installation`
  /// answers the same question one repo at a time, and the server asks about
  /// many repos under a handful of owners.
  Future<String?> tokenForOwner(String owner) async {
    if (owner.isEmpty) {
      return null;
    }
    final id = await _installationIdFor(owner);
    return id == null ? null : tokenForInstallation(id);
  }

  /// An installation token for [installationId], minted or served from cache.
  ///
  /// GitHub issues these for an hour; the cache is honoured until five minutes
  /// before expiry so a token cannot die mid-request.
  Future<String?> tokenForInstallation(int installationId) async {
    final cached = _tokens[installationId];
    if (cached != null &&
        cached.expiresAt.isAfter(_now().add(const Duration(minutes: 5)))) {
      return cached.token;
    }
    try {
      final minted = await _minterFor(installationId).mint();
      _tokens[installationId] = (
        token: minted.token,
        expiresAt:
            minted.expiresAt?.toUtc() ??
            _now().add(const Duration(minutes: 55)),
      );
      return minted.token;
    } on Object {
      // A revoked app, a suspended installation, GitHub being down: all mean
      // "no app credential right now", and the caller has other lanes.
      return null;
    }
  }

  /// A token scoped to [repositories] under [owner], with [permissions].
  ///
  /// The installation is resolved FROM THE OWNER, per call. A server-wide
  /// installation id cannot be right: one app is installed on many accounts,
  /// and which one matters is only known once a repo is in hand — pinning one
  /// worked for a single-org host and silently minted for the wrong account
  /// (or nothing at all) everywhere else.
  ///
  /// Null when the app is not installed on [owner], or the mint fails; the
  /// caller falls back to a broader credential rather than failing the run.
  Future<MintedToken?> mintScopedForOwner(
    String owner, {
    List<String> repositories = const [],
    Map<String, String> permissions = const {},
  }) async {
    final installation = await _installationIdFor(owner);
    if (installation == null) {
      return null;
    }
    try {
      return await _minterFor(
        installation,
      ).mint(repositories: repositories, permissions: permissions);
    } on Object {
      return null;
    }
  }

  /// Revokes a token this client minted (`DELETE /installation/token`).
  Future<void> revokeToken(String token) async {
    try {
      await _minterFor(0).revoke(token);
    } on Object {
      // Best-effort: the token expires within the hour regardless.
    }
  }

  /// The installation covering [owner], or null when the app is not installed
  /// there. Cached; a miss re-reads the list once in case it was just added.
  Future<int?> _installationIdFor(String owner) async {
    if (owner.isEmpty) {
      return null;
    }
    final key = owner.toLowerCase();
    final cached = _installationByOwner[key];
    if (cached != null) {
      return cached;
    }
    await installations(refresh: true);
    return _installationByOwner[key];
  }

  /// A token for whichever installation answers first, for work that is not
  /// about one owner (fetching a private asset, probing that the credentials
  /// work at all). Null when the app has no installations.
  Future<String?> anyInstallationToken() async {
    for (final installation in await installations()) {
      final token = await tokenForInstallation(installation.id);
      if (token != null) {
        return token;
      }
    }
    return null;
  }

  /// Drops every cached token and installation. Called when the operator
  /// changes the app credentials — a token minted by the previous app is not
  /// merely stale, it belongs to a different identity.
  void invalidate() {
    _tokens.clear();
    _installationByOwner.clear();
    _installations = null;
    _botInfo = null;
  }

  Options _appOptions() => Options(
    headers: {
      'Authorization': 'Bearer ${buildAppJwt()}',
      'Accept': 'application/vnd.github+json',
      'X-GitHub-Api-Version': '2022-11-28',
    },
  );
}
