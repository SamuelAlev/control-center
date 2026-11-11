import 'dart:convert';

import 'package:cc_domain/core/domain/value_objects/forge_host.dart'
    show gitHubRestApiVersion;
import 'package:cc_infra/src/log/cc_infra_log.dart';
import 'package:cc_infra/src/network/app_network.dart';
import 'package:cc_infra/src/network/error_mapper.dart';
import 'package:cc_infra/src/sandboxing/github_app_token_minter.dart'
    show
        GitHubAppConfig,
        GitHubAppTokenMinter,
        MintedToken,
        buildGitHubAppJwt;
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

/// Why a [GitHubAppClient] could not mint a one-repository token.
enum GitHubAppMintFailure {
  /// The App is not installed on the repository's owner.
  notInstalled,

  /// The App is installed on the owner, but the installation does not
  /// include the repository.
  repoNotSelected,

  /// The owner's installation is suspended.
  suspended,

  /// GitHub refused the mint for another reason (a permission the App lacks,
  /// an answer wider than asked). Final until the App is reconfigured.
  denied,

  /// GitHub refused the App's own JWT (401): a wrong private key or App id,
  /// or this host's clock off by more than GitHub tolerates. Final until the
  /// App or the clock is fixed.
  jwtRejected,

  /// GitHub was unreachable or failing. Transient: never cache it.
  unavailable,
}

/// A refused [GitHubAppClient.mintScopedForOwner]: why, and the installation
/// it concerns when there is one (so a caller can link to its repository
/// selection).
final class GitHubAppMintRefused implements Exception {
  /// Creates the refusal.
  const GitHubAppMintRefused(this.failure, this.message, {this.installation});

  /// Why.
  final GitHubAppMintFailure failure;

  /// For the operator's log.
  final String message;

  /// The owner's installation, when one exists.
  final GitHubInstallation? installation;

  @override
  String toString() => 'GitHubAppMintRefused(${failure.name}): $message';
}

/// Where an admin changes which repositories [installation] covers.
Uri gitHubInstallationSettingsUrl(GitHubInstallation installation) =>
    installation.targetType == 'Organization'
    ? Uri.https(
        'github.com',
        '/organizations/${installation.account}/settings/installations/'
            '${installation.id}',
      )
    : Uri.https('github.com', '/settings/installations/${installation.id}');

/// A GitHub App's identity for background work (polling, sync, bot replies):
/// installation discovery plus single-repository installation tokens on
/// [GitHubAppTokenMinter]. A refused mint throws [GitHubAppMintRefused]; the
/// caller refuses the work rather than reaching for a broader credential.
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

  final Map<String, GitHubInstallation> _installationByOwner = {};
  final Set<String> _suspendedOwners = {};
  List<GitHubInstallation>? _installations;
  DateTime? _installationsFetchedAt;
  Future<List<GitHubInstallation>>? _listing;
  GitHubAppBotInfo? _botInfo;

  /// Bumped by [invalidate]: a listing that started before it never lands.
  int _generation = 0;

  /// How long one installation listing answers every question (suspended
  /// owner, owner lookup, presence): an install or a resume is a human
  /// action, and listing per mint would cost an App JWT call each time.
  static const installationsTtl = Duration(seconds: 60);

  /// Pages of 100 a listing reads before it gives up loudly: an App this
  /// widely installed is not something one server's listing can serve, and
  /// stopping silently would read as "not installed" for every account past
  /// the last page.
  static const _maxInstallationPages = 1000;

  GitHubAppTokenMinter _minterFor(int installationId) => GitHubAppTokenMinter(
    httpClient: _httpClient,
    config: GitHubAppConfig(
      appId: _appId,
      privateKeyPem: _privateKeyPem,
      installationId: '$installationId',
    ),
    now: _now,
  );

  /// The App JWT itself ([buildGitHubAppJwt]), exposed so a test can verify
  /// the claims and a settings probe can call `/app` without minting
  /// anything.
  String buildAppJwt() => buildGitHubAppJwt(
    appId: _appId,
    privateKeyPem: _privateKeyPem,
    now: _now(),
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
  /// One listing serves every caller for [installationsTtl]; [refresh]
  /// re-reads it (the settings "test" action). A failed listing answers
  /// empty here and is not cached (a blip must not read as "installed
  /// nowhere" for long); minting uses [_listed], which throws instead.
  Future<List<GitHubInstallation>> installations({bool refresh = false}) async {
    try {
      return await _listed(refresh: refresh);
    } on GitHubAppMintRefused {
      return const [];
    }
  }

  /// The cached listing, or one fresh listing shared by every concurrent
  /// caller. Throws [GitHubAppMintRefused] ([GitHubAppMintFailure.unavailable])
  /// when GitHub cannot be read.
  Future<List<GitHubInstallation>> _listed({bool refresh = false}) {
    final cached = _installations;
    final fetchedAt = _installationsFetchedAt;
    if (!refresh &&
        cached != null &&
        fetchedAt != null &&
        _now().difference(fetchedAt) < installationsTtl) {
      return Future.value(cached);
    }
    final generation = _generation;
    final listing = _listing;
    if (listing != null) {
      return listing;
    }
    late final Future<List<GitHubInstallation>> started;
    started = _fetchInstallations(generation).whenComplete(() {
      if (identical(_listing, started)) {
        _listing = null;
      }
    });
    return _listing = started;
  }

  Future<List<GitHubInstallation>> _fetchInstallations(int generation) async {
    final parsed = <GitHubInstallation>[];
    try {
      for (var page = 1; ; page++) {
        if (page > _maxInstallationPages) {
          throw const GitHubAppMintRefused(
            GitHubAppMintFailure.unavailable,
            'The App has more installations than one listing reads '
            '(${_maxInstallationPages * 100}); refusing to answer from a '
            'partial list.',
          );
        }
        final response = await _httpClient.get(
          '/app/installations',
          query: {'per_page': '100', 'page': '$page'},
          headers: _appOptions(),
        );
        final data = httpJsonBody(response);
        if (data is! List) {
          throw const GitHubAppMintRefused(
            GitHubAppMintFailure.unavailable,
            'GitHub answered an unreadable installation list.',
          );
        }
        for (final entry in data.whereType<Map>()) {
          final installation = GitHubInstallation(
            id: (entry['id'] as num?)?.toInt() ?? 0,
            account: (entry['account'] as Map?)?['login'] as String? ?? '',
            accountId:
                ((entry['account'] as Map?)?['id'] as num?)?.toInt() ?? 0,
            targetType: entry['target_type'] as String? ?? '',
            repositorySelection: entry['repository_selection'] as String? ?? '',
            suspendedAt: DateTime.tryParse(
              entry['suspended_at'] as String? ?? '',
            ),
          );
          if (installation.id != 0) {
            parsed.add(installation);
          }
        }
        if (data.length < 100) {
          break;
        }
      }
    } on RhttpStatusCodeException catch (e) {
      if (e.statusCode == 401) {
        throw _jwtRejected('/app/installations', e);
      }
      throw GitHubAppMintRefused(
        GitHubAppMintFailure.unavailable,
        'Listing the App installations failed (HTTP ${e.statusCode}).',
      );
    } on RhttpException catch (e) {
      throw GitHubAppMintRefused(
        GitHubAppMintFailure.unavailable,
        'Listing the App installations failed: $e',
      );
    }
    // Credentials changed while this listing was in the air: it belongs to
    // the previous App and is not adopted.
    if (generation == _generation) {
      _adoptInstallations(parsed);
    }
    return parsed;
  }

  /// Records that GitHub refused this App's JWT on [endpoint] and answers the
  /// refusal. The line names the App, GitHub's request id and GitHub's own
  /// clock (`date`), so a skewed host clock shows at a glance; it never
  /// carries the JWT.
  GitHubAppMintRefused _jwtRejected(
    String endpoint,
    RhttpStatusCodeException e,
  ) {
    String header(String name) {
      for (final (key, value) in e.headers) {
        if (key.toLowerCase() == name) {
          return value;
        }
      }
      return '';
    }

    CcInfraLog.warning(
      'forge.audit ${jsonEncode({
        'event': 'github.app_jwt.rejected',
        'app_id': _appId,
        'endpoint': endpoint,
        'status': e.statusCode,
        'server_date': header('date'),
        'local_date': _now().toIso8601String(),
        'github_request_id': header('x-github-request-id'),
      })}',
    );
    return const GitHubAppMintRefused(
      GitHubAppMintFailure.jwtRejected,
      'GitHub refused the App\'s credentials (HTTP 401): check the App id '
      "and private key, and this machine's clock.",
    );
  }

  /// The installation covering [owner], from the shared listing
  /// ([installationsTtl]), or null when the App is not installed there.
  /// Throws [GitHubAppMintRefused] when GitHub cannot be read.
  Future<GitHubInstallation?> installationForOwner(String owner) async {
    await _listed();
    return _installationByOwner[owner.toLowerCase()];
  }

  /// Whether this App's installation covers [owner]/[repo] (`GET
  /// /repos/{owner}/{repo}/installation`, App JWT): true when it does, false
  /// when GitHub says no installation reaches it (not installed on the
  /// owner, or the repository not selected). Throws [GitHubAppMintRefused]
  /// when GitHub cannot be read or refuses the App's JWT. Mints nothing.
  Future<bool> coversRepository(String owner, String repo) async {
    final path =
        '/repos/${Uri.encodeComponent(owner)}/${Uri.encodeComponent(repo)}'
        '/installation';
    try {
      await _httpClient.get(path, headers: _appOptions());
      return true;
    } on RhttpStatusCodeException catch (e) {
      if (e.statusCode == 404) {
        return false;
      }
      if (e.statusCode == 401) {
        throw _jwtRejected(path, e);
      }
      throw GitHubAppMintRefused(
        GitHubAppMintFailure.unavailable,
        'GitHub failed the installation lookup for $owner/$repo '
        '(HTTP ${e.statusCode}).',
      );
    } on RhttpException catch (e) {
      throw GitHubAppMintRefused(
        GitHubAppMintFailure.unavailable,
        'GitHub was unreachable looking up $owner/$repo: $e',
      );
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
  /// Throws [GitHubAppMintRefused]: not installed on [owner], suspended, the
  /// repository not selected in the installation, a refusal, or GitHub being
  /// unreachable (transient). There is deliberately no owner-wide token:
  /// every token names its repositories.
  Future<MintedToken> mintScopedForOwner(
    String owner, {
    required List<String> repositories,
    required Map<String, String> permissions,
  }) async {
    final installation = await _installationFor(owner);
    try {
      return await _minterFor(
        installation.id,
      ).mint(repositories: repositories, permissions: permissions);
    } on RhttpStatusCodeException catch (e) {
      if (e.statusCode == 401) {
        throw _jwtRejected(
          '/app/installations/${installation.id}/access_tokens',
          e,
        );
      }
      if (isGitHubInstallationSuspendedError(e)) {
        _markSuspended(installation);
        throw GitHubAppMintRefused(
          GitHubAppMintFailure.suspended,
          'The installation on $owner is suspended.',
          installation: installation,
        );
      }
      throw switch (e.statusCode) {
        // The installation is gone (uninstalled since the listing).
        404 => () {
          _forgetListing();
          return GitHubAppMintRefused(
            GitHubAppMintFailure.notInstalled,
            'The App is no longer installed on $owner.',
          );
        }(),
        // GitHub: "There is at least one repository that does not exist or
        // is not accessible to the parent installation."
        422 => GitHubAppMintRefused(
          '${httpErrorBody(e)}'.toLowerCase().contains('permission')
              ? GitHubAppMintFailure.denied
              : GitHubAppMintFailure.repoNotSelected,
          'GitHub refused the mint on $owner (HTTP 422).',
          installation: installation,
        ),
        403 => GitHubAppMintRefused(
          GitHubAppMintFailure.denied,
          'GitHub refused the mint on $owner (HTTP ${e.statusCode}).',
          installation: installation,
        ),
        _ => GitHubAppMintRefused(
          GitHubAppMintFailure.unavailable,
          'GitHub failed the mint on $owner (HTTP ${e.statusCode}).',
          installation: installation,
        ),
      };
    } on RhttpException catch (e) {
      throw GitHubAppMintRefused(
        GitHubAppMintFailure.unavailable,
        'GitHub was unreachable minting on $owner: $e',
        installation: installation,
      );
    } on FormatException catch (e) {
      // An answer that is not a token: GitHub misbehaving, never a grant.
      throw GitHubAppMintRefused(
        GitHubAppMintFailure.unavailable,
        e.message,
        installation: installation,
      );
    } on StateError catch (e) {
      // One wider than asked (already revoked by the minter).
      throw GitHubAppMintRefused(
        GitHubAppMintFailure.denied,
        e.message,
        installation: installation,
      );
    }
  }

  /// The installation covering [owner], from the shared listing
  /// ([installationsTtl]): a miss within it is "not installed" without a
  /// second listing. Throws [GitHubAppMintRefused].
  Future<GitHubInstallation> _installationFor(String owner) async {
    if (owner.isEmpty) {
      throw const GitHubAppMintRefused(
        GitHubAppMintFailure.notInstalled,
        'No repository owner.',
      );
    }
    await _listed();
    final key = owner.toLowerCase();
    final installation = _installationByOwner[key];
    if (installation == null) {
      throw GitHubAppMintRefused(
        GitHubAppMintFailure.notInstalled,
        'The App is not installed on $owner.',
      );
    }
    if (_suspendedOwners.contains(key)) {
      throw GitHubAppMintRefused(
        GitHubAppMintFailure.suspended,
        'The installation on $owner is suspended.',
        installation: installation,
      );
    }
    return installation;
  }

  void _forgetListing() {
    _installations = null;
    _installationsFetchedAt = null;
  }

  /// Drops every cached installation, including a listing still in the air.
  /// Called when the operator changes the app credentials: what the previous
  /// app listed belongs to a different identity.
  void invalidate() {
    _generation++;
    _listing = null;
    _installationByOwner.clear();
    _suspendedOwners.clear();
    _installations = null;
    _installationsFetchedAt = null;
    _botInfo = null;
  }

  void _adoptInstallations(List<GitHubInstallation> parsed) {
    _installationByOwner.clear();
    _suspendedOwners.clear();
    for (final installation in parsed) {
      if (installation.account.isEmpty) {
        continue;
      }
      final key = installation.account.toLowerCase();
      _installationByOwner[key] = installation;
      if (installation.isSuspended) {
        _suspendedOwners.add(key);
      }
    }
    _installations = parsed;
    _installationsFetchedAt = _now();
  }

  void _markSuspended(GitHubInstallation installation) {
    if (installation.account.isNotEmpty) {
      _suspendedOwners.add(installation.account.toLowerCase());
    }
  }

  HttpHeaders _appOptions() => HttpHeaders.rawMap({
    'Authorization': 'Bearer ${buildAppJwt()}',
    'Accept': 'application/vnd.github+json',
    'X-GitHub-Api-Version': gitHubRestApiVersion,
  });
}
