import 'package:cc_domain/core/domain/ports/forge_credential_port.dart';
import 'package:cc_domain/core/domain/value_objects/forge_connection.dart';
import 'package:cc_domain/core/domain/value_objects/forge_host.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';

/// Reads a process environment variable. Injected so tests can drive the
/// environment source without touching `Platform.environment`.
typedef EnvLookup = String? Function(String name);

/// Probes a vendor CLI for an already-authenticated token, returning
/// `(token, username)` or null when the CLI is absent or logged out.
typedef CliProbe = Future<({String token, String username})?> Function();

/// Asks a forge who the bearer of [token] is, for the connection's username.
/// Returns null when the token is rejected or the call fails.
typedef ViewerProbe = Future<String?> Function(ForgeHost forge, String token);

/// Server-side [ForgeCredentialPort] over the shared secrets file.
///
/// Stores Settings-sourced tokens under `forge_token_<forge>` in the same 0600
/// file as the device PSKs, and layers the environment and (for GitHub) the
/// `gh` CLI underneath.
///
/// Credentials are resolved **per call**, not captured once at boot. That is
/// the difference that makes "paste a token in Settings" work without a
/// restart: the old design read `gh auth token` during startup and baked the
/// result into a Dio interceptor closure, so a token that arrived later was
/// invisible until the process was restarted.
class ForgeCredentials implements ForgeCredentialPort {
  /// Creates a [ForgeCredentials].
  ///
  /// [ghCliProbe] supplies the GitHub-only CLI fallback; leave it null on hosts
  /// with no `gh`. [viewerProbe] resolves the account name behind a token and
  /// may be null, in which case connections report authentication without a
  /// username.
  ForgeCredentials({
    required FileSecretsStore secrets,
    required EnvLookup env,
    CliProbe? ghCliProbe,
    ViewerProbe? viewerProbe,
  }) : _secrets = secrets,
       _env = env,
       _ghCliProbe = ghCliProbe,
       _viewerProbe = viewerProbe;

  final FileSecretsStore _secrets;
  final EnvLookup _env;
  final CliProbe? _ghCliProbe;
  final ViewerProbe? _viewerProbe;

  /// Cached viewer identity per forge, so the roster and "is this mine?"
  /// checks do not re-probe on every read. Invalidated whenever the forge's
  /// token changes.
  final Map<ForgeHost, String> _viewerCache = {};

  /// Cached CLI probe result. `gh auth status` shells out and can block on a
  /// locked keychain, so it runs at most once per process unless a token
  /// change invalidates it.
  Future<({String token, String username})?>? _cliResult;

  /// Environment variable names per forge, in the order they are consulted.
  ///
  /// Bitbucket Cloud authenticates with an account email plus an API token, so
  /// its token is assembled from two variables rather than read from one.
  static const Map<ForgeHost, List<String>> _envNames = {
    ForgeHost.github: ['GITHUB_TOKEN', 'GH_TOKEN'],
    ForgeHost.gitlab: ['GITLAB_TOKEN', 'CI_JOB_TOKEN'],
    ForgeHost.bitbucket: ['BITBUCKET_API_TOKEN', 'BITBUCKET_TOKEN'],
  };

  static String _secretKey(ForgeHost forge) => 'forge_token_${forge.wire}';

  /// The Bitbucket account email, needed as the username half of its basic
  /// auth. Empty when unset.
  String get bitbucketEmail => _env('BITBUCKET_EMAIL') ?? '';

  @override
  Future<String?> tokenFor(ForgeHost forge) async {
    final resolved = await _resolve(forge);
    return resolved.token.isEmpty ? null : resolved.token;
  }

  @override
  Future<void> setToken(ForgeHost forge, String token) async {
    if (token.isEmpty) {
      await clearToken(forge);
      return;
    }
    await _secrets.writePsk(_secretKey(forge), token);
    _invalidate(forge);
  }

  @override
  Future<void> clearToken(ForgeHost forge) async {
    await _secrets.deletePsk(_secretKey(forge));
    _invalidate(forge);
  }

  @override
  Future<List<ForgeConnection>> connections() async {
    final result = <ForgeConnection>[];
    for (final forge in ForgeHost.supported) {
      result.add(await _connectionFor(forge, probeViewer: false));
    }
    return result;
  }

  @override
  Future<ForgeConnection> testConnection(ForgeHost forge) {
    _viewerCache.remove(forge);
    return _connectionFor(forge, probeViewer: true);
  }

  /// The viewer's account name on [forge], or an empty string when unknown.
  ///
  /// This is the per-forge identity the inbox classifies against: the same
  /// human is `octocat` on GitHub and `o.cat` on GitLab, so "assigned to me"
  /// must be asked once per forge rather than compared to one global login.
  @override
  Future<String> viewerLogin(ForgeHost forge) async {
    final cached = _viewerCache[forge];
    if (cached != null) {
      return cached;
    }
    final resolved = await _resolve(forge);
    if (resolved.token.isEmpty) {
      return '';
    }
    if (resolved.username.isNotEmpty) {
      return _viewerCache[forge] = resolved.username;
    }
    final probed = await _viewerProbe?.call(forge, resolved.token);
    if (probed == null || probed.isEmpty) {
      return '';
    }
    return _viewerCache[forge] = probed;
  }

  void _invalidate(ForgeHost forge) {
    _viewerCache.remove(forge);
    if (forge == ForgeHost.github) {
      _cliResult = null;
    }
    _revision++;
  }

  int _revision = 0;

  /// Bumps whenever any credential changes. Clients of this store cache
  /// per-forge HTTP clients and compare this to know when to rebuild them.
  int get revision => _revision;

  Future<ForgeConnection> _connectionFor(
    ForgeHost forge, {
    required bool probeViewer,
  }) async {
    final resolved = await _resolve(forge);
    if (resolved.token.isEmpty) {
      return ForgeConnection.disconnected(forge);
    }
    var username = resolved.username;
    if (username.isEmpty) {
      username = probeViewer
          ? (await _viewerProbe?.call(forge, resolved.token) ?? '')
          : (_viewerCache[forge] ?? '');
      if (probeViewer && username.isNotEmpty) {
        _viewerCache[forge] = username;
      }
    }
    if (probeViewer && username.isEmpty) {
      return ForgeConnection(
        forge: forge,
        authenticated: false,
        source: resolved.source,
        error: '${forge.displayName} rejected the stored credential.',
      );
    }
    return ForgeConnection(
      forge: forge,
      authenticated: true,
      username: username,
      source: resolved.source,
    );
  }

  /// Walks the precedence chain once.
  Future<({String token, String username, ForgeCredentialSource source})>
  _resolve(ForgeHost forge) async {
    if (!forge.isSupported) {
      return (token: '', username: '', source: ForgeCredentialSource.none);
    }

    final stored = await _secrets.readPsk(_secretKey(forge));
    if (stored != null && stored.isNotEmpty) {
      return (
        token: stored,
        username: '',
        source: ForgeCredentialSource.settings,
      );
    }

    for (final name in _envNames[forge] ?? const <String>[]) {
      final value = _env(name);
      if (value != null && value.isNotEmpty) {
        return (
          token: value,
          username: '',
          source: ForgeCredentialSource.environment,
        );
      }
    }

    // The CLI fallback is GitHub-only on purpose: `gh` is the one vendor CLI
    // whose token we can read without asking the operator to paste one. There
    // is no `glab`/`bb` equivalent wired up, and pretending otherwise would
    // make GitLab look connected on a host that merely has the CLI installed.
    if (forge == ForgeHost.github && _ghCliProbe != null) {
      final cli = await (_cliResult ??= _ghCliProbe());
      if (cli != null && cli.token.isNotEmpty) {
        return (
          token: cli.token,
          username: cli.username,
          source: ForgeCredentialSource.cli,
        );
      }
    }

    return (token: '', username: '', source: ForgeCredentialSource.none);
  }
}
