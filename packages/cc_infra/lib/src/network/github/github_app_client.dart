import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:cc_infra/src/sandboxing/github_app_token_minter.dart'
    show GitHubAppConfig, GitHubAppTokenMinter, MintedToken;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';
import 'package:rhttp/rhttp.dart';

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
    this.accountId = 0,
    this.targetType = '',
    this.repositorySelection = '',
    this.suspendedAt,
  });

  /// The numeric installation id.
  final int id;

  /// The login of the account that installed the app.
  final String account;

  /// The numeric id of that account (stable across renames), or 0.
  final int accountId;

  /// `User` or `Organization`.
  final String targetType;

  /// `all` or `selected` — which of the account's repositories are covered.
  final String repositorySelection;

  /// When GitHub suspended this installation, or null while it is active.
  final DateTime? suspendedAt;

  /// Whether GitHub has suspended this installation. Minting a token cannot
  /// succeed until a human resumes it.
  bool get isSuspended => suspendedAt != null;

  /// The wire shape the settings screen renders.
  Map<String, Object?> toJson() => {
    'id': id,
    'account': account,
    'account_id': accountId,
    'target_type': targetType,
    'repository_selection': repositorySelection,
    if (suspendedAt != null) 'suspended_at': suspendedAt!.toIso8601String(),
  };
}

/// A GitHub App's identity for background work (polling, sync, bot replies):
/// installation discovery plus single-repository installation tokens on
/// [GitHubAppTokenMinter]. Failures resolve to null; the caller refuses the
/// work rather than reaching for a broader credential.
class GitHubAppClient {
  /// Creates a [GitHubAppClient].
  ///
  /// [httpClient] is injected by tests; production builds get an
  /// `api.github.com` client.
  GitHubAppClient({
    required this._appId,
    required this._privateKeyPem,
    RhttpClient? httpClient,
    DateTime Function()? now,
  }) : _httpClient =
           httpClient ?? createHttpClient(baseUrl: 'https://api.github.com'),
       _now = now ?? (() => DateTime.now().toUtc());

  /// Builds a client, or null when the credentials are absent or the private
  /// key does not parse. Null means "this server has no app identity", which
  /// every caller already handles by falling through to the next lane.
  static GitHubAppClient? tryCreate({
    required String appId,
    required String privateKeyPem,
    RhttpClient? httpClient,
  }) {
    if (appId.isEmpty || !isReadablePrivateKey(privateKeyPem)) {
      return null;
    }
    return GitHubAppClient(
      appId: appId,
      privateKeyPem: privateKeyPem,
      httpClient: httpClient,
    );
  }

  /// Whether [privateKeyPem] parses as the RSA key an app JWT is signed with.
  ///
  /// Parsing up front (rather than at first use) is what lets the settings
  /// screen reject a bad key while the operator is still looking at it,
  /// without opening an HTTP client just to validate it.
  static bool isReadablePrivateKey(String privateKeyPem) {
    if (privateKeyPem.isEmpty) {
      return false;
    }
    try {
      RSAPrivateKey(privateKeyPem);
      return true;
    } on Object {
      return false;
    }
  }

  final String _appId;
  final String _privateKeyPem;
  final RhttpClient _httpClient;
  final DateTime Function() _now;

  final Map<String, int> _installationByOwner = {};
  final Set<int> _suspendedIds = {};
  final Set<String> _suspendedOwners = {};
  List<GitHubInstallation>? _installations;
  DateTime? _installationsFetchedAt;
  GitHubAppBotInfo? _botInfo;

  /// How often a suspended installation is re-listed. Resume is a human
  /// action; retrying mint every poll only 403s. Five minutes is the same
  /// idle cadence the conversation poller already uses.
  static const _suspendedRecheck = Duration(minutes: 5);

  GitHubAppTokenMinter _minterFor(int installationId) => GitHubAppTokenMinter(
    httpClient: _httpClient,
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
      final response = await _httpClient.get('/app', headers: _appOptions());
      final data = httpJsonBody(response);
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
    } on RhttpException {
      return null;
    }
  }

  /// Every account that has installed the app.
  ///
  /// Cached after the first success: installations change when a human clicks
  /// Install, not per request. [refresh] re-reads them, which is what the
  /// settings "test" action does. A cached list that includes a suspended
  /// installation is treated as stale after five minutes so a resume is
  /// picked up without a restart.
  Future<List<GitHubInstallation>> installations({bool refresh = false}) async {
    final cached = _installations;
    final fetchedAt = _installationsFetchedAt;
    final stale =
        _suspendedIds.isNotEmpty &&
        fetchedAt != null &&
        _now().difference(fetchedAt) >= _suspendedRecheck;
    if (cached != null && !refresh && !stale) {
      return cached;
    }
    try {
      final response = await _httpClient.get(
        '/app/installations',
        headers: _appOptions(),
      );
      final data = httpJsonBody(response);
      if (data is! List) {
        _adoptInstallations(const []);
        return const [];
      }
      final parsed = [
        for (final entry in data.whereType<Map>())
          GitHubInstallation(
            id: (entry['id'] as num?)?.toInt() ?? 0,
            account: (entry['account'] as Map?)?['login'] as String? ?? '',
            accountId:
                ((entry['account'] as Map?)?['id'] as num?)?.toInt() ?? 0,
            targetType: entry['target_type'] as String? ?? '',
            repositorySelection: entry['repository_selection'] as String? ?? '',
            suspendedAt: DateTime.tryParse(
              entry['suspended_at'] as String? ?? '',
            ),
          ),
      ].where((i) => i.id != 0).toList();
      _adoptInstallations(parsed);
      return parsed;
    } on RhttpException {
      // Do NOT cache a failure: a network blip would otherwise leave the app
      // permanently "not installed anywhere" until the next restart.
      return const [];
    }
  }

  /// Whether the app installation covering [owner] is suspended.
  ///
  /// Loads the installation list (honouring the suspended-recheck TTL) so the
  /// first caller of a freshly constructed client still learns the truth.
  Future<bool> isOwnerSuspended(String owner) async {
    if (owner.isEmpty) {
      return false;
    }
    await installations();
    return _suspendedOwners.contains(owner.toLowerCase());
  }

  /// Whether every known installation is suspended. Empty (no app, or none
  /// installed) is not this condition — that is a missing identity, not a
  /// paused one.
  Future<bool> allInstallationsSuspended() async {
    final list = await installations();
    if (list.isEmpty) {
      return false;
    }
    return list.every(
      (installation) =>
          installation.isSuspended || _suspendedIds.contains(installation.id),
    );
  }

  /// Logins of accounts whose installation is currently suspended.
  Future<Set<String>> suspendedOwners() async {
    await installations();
    return Set.unmodifiable(_suspendedOwners);
  }

  /// A token scoped to [repositories] under [owner], with [permissions].
  ///
  /// The installation is resolved FROM THE OWNER, per call. A server-wide
  /// installation id cannot be right: one app is installed on many accounts,
  /// and which one matters is only known once a repo is in hand — pinning one
  /// worked for a single-org host and silently minted for the wrong account
  /// (or nothing at all) everywhere else.
  ///
  /// Null when the app is not installed on [owner], or the mint fails. There
  /// is deliberately no owner-wide token: every token names its repositories.
  Future<MintedToken?> mintScopedForOwner(
    String owner, {
    required List<String> repositories,
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
    } on Object catch (e) {
      if (isGitHubInstallationSuspendedError(e)) {
        _markSuspended(installation);
      }
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
    if (_suspendedOwners.contains(key)) {
      await installations();
      if (_suspendedOwners.contains(key)) {
        return null;
      }
    }
    final cached = _installationByOwner[key];
    if (cached != null) {
      return cached;
    }
    await installations(refresh: true);
    if (_suspendedOwners.contains(key)) {
      return null;
    }
    return _installationByOwner[key];
  }

  /// Drops every cached token and installation. Called when the operator
  /// changes the app credentials — a token minted by the previous app is not
  /// merely stale, it belongs to a different identity.
  void invalidate() {
    _installationByOwner.clear();
    _suspendedIds.clear();
    _suspendedOwners.clear();
    _installations = null;
    _installationsFetchedAt = null;
    _botInfo = null;
  }

  void _adoptInstallations(List<GitHubInstallation> parsed) {
    _installationByOwner.clear();
    _suspendedIds.clear();
    _suspendedOwners.clear();
    for (final installation in parsed) {
      if (installation.account.isEmpty) {
        continue;
      }
      final key = installation.account.toLowerCase();
      if (installation.isSuspended) {
        _suspendedIds.add(installation.id);
        _suspendedOwners.add(key);
        continue;
      }
      _installationByOwner[key] = installation.id;
    }
    _installations = parsed;
    _installationsFetchedAt = _now();
  }

  void _markSuspended(int installationId) {
    _suspendedIds.add(installationId);
    final list = _installations;
    if (list != null) {
      for (final installation in list) {
        if (installation.id == installationId &&
            installation.account.isNotEmpty) {
          _suspendedOwners.add(installation.account.toLowerCase());
          _installationByOwner.remove(installation.account.toLowerCase());
        }
      }
    }
    _installationsFetchedAt ??= _now();
  }

  HttpHeaders _appOptions() => HttpHeaders.rawMap({
    'Authorization': 'Bearer ${buildAppJwt()}',
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': '2022-11-28',
  });
}
