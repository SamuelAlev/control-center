import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_infra/cc_infra.dart' show GitHubAppClient;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/builtin_credentials.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';

/// A provider the server can hold an app identity for.
///
/// Deliberately a small closed set rather than a free string: each entry has a
/// hand-written OAuth endpoint pair and a hand-written credential shape, and a
/// provider nobody wrote those for would be configurable but non-functional.
enum ProviderApp {
  /// A GitHub App: an app id + private key (server identity) and a client
  /// id/secret (user sign-in), both from the same registration.
  github,

  /// A Linear OAuth application, plus an optional workspace API key for the
  /// server's own reads.
  linear;

  /// The wire spelling.
  String get wire => name;

  /// Whether signing in to this provider needs the app's CLIENT SECRET.
  ///
  /// GitHub's device flow does not: the device-code request and the token poll
  /// both authenticate with the client id alone, so requiring a secret would
  /// gate the sign-in on a value it never sends. Linear has no device flow —
  /// its browser round-trip is a confidential-client exchange and does.
  ///
  /// A GitHub secret is still USEFUL (it is what refreshes an expiring user
  /// token), just not required to sign in.
  bool get requiresClientSecret => this == ProviderApp.linear;

  /// Parses a wire value; null when unknown.
  static ProviderApp? fromWire(String? wire) {
    for (final p in values) {
      if (p.wire == wire) {
        return p;
      }
    }
    return null;
  }
}

/// One provider's app configuration as reported to clients.
///
/// Carries **presence flags, never secrets**. The private key and client
/// secret leave this process only in an outbound request to the provider.
class ProviderAppStatus {
  /// Creates a [ProviderAppStatus].
  const ProviderAppStatus({
    required this.provider,
    this.appId = '',
    this.clientId = '',
    this.botLogin = '',
    this.hasPrivateKey = false,
    this.hasClientSecret = false,
    this.hasApiKey = false,
    this.installations = const [],
    this.error = '',
  });

  /// Which provider.
  final ProviderApp provider;

  /// The GitHub App's numeric id; empty for providers that have none.
  final String appId;

  /// The OAuth client id (not a secret — it rides in every authorize URL).
  final String clientId;

  /// The GitHub App's bot login (`<slug>[bot]`), when probed. This is the
  /// identity a PR comment @mentions to talk to the server; empty when the
  /// app is not probed or has no readable bot account.
  final String botLogin;

  /// Whether a private key is stored.
  final bool hasPrivateKey;

  /// Whether an OAuth client secret is stored.
  final bool hasClientSecret;

  /// Whether a server-level API key is stored.
  final bool hasApiKey;

  /// The app's installations, when it has been probed.
  final List<Map<String, Object?>> installations;

  /// Why the last probe failed, or empty.
  final String error;

  /// True when this provider can run a user sign-in.
  bool get canSignIn =>
      clientId.isNotEmpty &&
      (hasClientSecret || !provider.requiresClientSecret);

  /// True when the server can act as itself on this provider.
  bool get canActAsServer => switch (provider) {
    ProviderApp.github => appId.isNotEmpty && hasPrivateKey,
    ProviderApp.linear => hasApiKey,
  };

  /// The wire shape.
  Map<String, Object?> toJson() => {
    'provider': provider.wire,
    'app_id': appId,
    'client_id': clientId,
    'bot_login': botLogin,
    'has_private_key': hasPrivateKey,
    'has_client_secret': hasClientSecret,
    'has_api_key': hasApiKey,
    'can_sign_in': canSignIn,
    'can_act_as_server': canActAsServer,
    'installations': installations,
    if (error.isNotEmpty) 'error': error,
  };
}

/// An OAuth client id/secret pair.
typedef OAuthAppCredentials = ({String clientId, String clientSecret});

/// Server-wide provider app credentials: the GitHub App and the Linear app.
///
/// Two lanes come out of one registration and this is the seam that keeps them
/// straight:
///
///  * **The server acting as itself** — a GitHub App installation token, a
///    Linear API key. Everything with no human behind it (webhooks, polling,
///    sync, private-asset fetches) authenticates this way, so background work
///    does not silently depend on one person's PAT still being valid.
///  * **A user signing in** — the same app's OAuth client id/secret, used by
///    `ProviderOAuthService` to mint a token that belongs to that user.
///
/// Storage mirrors `SsoSettingsService`, which solved this shape first:
/// non-secret fields in `server_settings`, secrets in the 0600
/// [FileSecretsStore], never a database column. The environment seeds a field
/// the FIRST time it has no stored value, so an operator can configure the
/// server with env vars and still edit it later in Settings.
class ProviderAppSettings {
  /// Creates a [ProviderAppSettings].
  ProviderAppSettings({
    required FileSecretsStore secrets,
    ServerSettingDao? settings,
    GitHubAppClient Function({required String appId, required String pem})?
    githubAppFactory,
  }) : _secrets = secrets,
       _settings = settings,
       _githubAppFactory = githubAppFactory;

  final FileSecretsStore _secrets;
  final ServerSettingDao? _settings;
  final GitHubAppClient Function({required String appId, required String pem})?
  _githubAppFactory;

  static const _githubAppIdKey = 'provider_app_github_app_id';
  static const _githubClientIdKey = 'provider_app_github_client_id';
  static const _linearClientIdKey = 'provider_app_linear_client_id';

  static const _githubPrivateKeySecret = 'provider_app_github_private_key';
  static const _githubClientSecret = 'provider_app_github_client_secret';
  static const _linearClientSecret = 'provider_app_linear_client_secret';
  static const _linearApiKeySecret = 'provider_app_linear_api_key';

  /// In-memory settings for hosts that wire no database (tests, the minimal
  /// server). Without this an env-seeded app would be forgotten per read.
  final Map<String, String> _memory = {};

  GitHubAppClient? _githubApp;
  bool _githubAppResolved = false;

  /// Seeds unset fields from [env] (and the release build's built-in
  /// credentials, which arrive as env entries from the caller).
  ///
  /// Runs once at boot, before the HTTP listener starts, so the first inbound
  /// request already sees a configured app.
  Future<void> loadAndApply({Map<String, String> env = const {}}) async {
    Future<void> seedSetting(String key, String? value) async {
      if (value == null || value.trim().isEmpty) {
        return;
      }
      if ((await _readSetting(key)) == null) {
        await _writeSetting(key, value.trim());
      }
    }

    Future<void> seedSecret(String key, String? value) async {
      if (value == null || value.trim().isEmpty) {
        return;
      }
      final existing = await _secrets.readPsk(key);
      if (existing == null || existing.isEmpty) {
        await _secrets.writePsk(key, value.trim());
      }
    }

    // GITHUB_APP_ID / GITHUB_APP_PRIVATE_KEY are the names the sandbox token
    // broker already reads, so a host that configured fine-grained agent
    // tokens gets the server lane for free rather than pasting the same key
    // under a second name.
    await seedSetting(_githubAppIdKey, env['GITHUB_APP_ID']);
    await seedSecret(_githubPrivateKeySecret, env['GITHUB_APP_PRIVATE_KEY']);
    await seedSetting(_githubClientIdKey, env['GITHUB_CLIENT_ID']);
    // The GitHub client secret is never baked into a build (the device flow
    // does not send one), but it does seed from the environment like Linear's:
    // it is what lets an operator whose own app has token expiry on refresh
    // user tokens instead of re-prompting a sign-in every eight hours.
    await seedSecret(_githubClientSecret, env['GITHUB_CLIENT_SECRET']);
    await seedSetting(_linearClientIdKey, env['LINEAR_CLIENT_ID']);
    await seedSecret(_linearClientSecret, env['LINEAR_CLIENT_SECRET']);
    await seedSecret(_linearApiKeySecret, env['LINEAR_API_KEY']);
    _invalidate();
  }

  /// The live GitHub App client, or null when this server has no app identity.
  Future<GitHubAppClient?> githubApp() async {
    if (_githubAppResolved) {
      return _githubApp;
    }
    _githubAppResolved = true;
    final appId = await _readSetting(_githubAppIdKey) ?? '';
    final pem = await _secrets.readPsk(_githubPrivateKeySecret) ?? '';
    if (appId.isEmpty || pem.isEmpty) {
      return _githubApp = null;
    }
    final factory = _githubAppFactory;
    return _githubApp = factory != null
        ? factory(appId: appId, pem: pem)
        : GitHubAppClient.tryCreate(appId: appId, privateKeyPem: pem);
  }

  /// The OAuth client credentials for [provider], or null when it cannot run a
  /// sign-in.
  ///
  /// The client SECRET may come back empty: a device flow does not send one,
  /// so requiring it would gate GitHub's sign-in on a value nothing uses. It
  /// is required only where the flow actually is a confidential-client
  /// exchange — see [ProviderApp.requiresClientSecret].
  Future<OAuthAppCredentials?> oauthCredentials(ProviderApp provider) async {
    final (idKey, secretKey) = switch (provider) {
      ProviderApp.github => (_githubClientIdKey, _githubClientSecret),
      ProviderApp.linear => (_linearClientIdKey, _linearClientSecret),
    };
    final clientId = await _readSetting(idKey) ?? _builtinClientId(provider);
    final clientSecret = await _secrets.readPsk(secretKey) ?? '';
    if (clientId.isEmpty ||
        (clientSecret.isEmpty && provider.requiresClientSecret)) {
      return null;
    }
    return (clientId: clientId, clientSecret: clientSecret);
  }

  /// The server-level Linear API key, or empty.
  Future<String> linearApiKey() async =>
      await _secrets.readPsk(_linearApiKeySecret) ?? '';

  /// Every provider's configuration, for the settings screen.
  ///
  /// [probe] additionally asks GitHub which installations the app has — a
  /// network call, so it is opt-in rather than part of every settings read.
  Future<List<ProviderAppStatus>> statuses({bool probe = false}) async => [
    await status(ProviderApp.github, probe: probe),
    await status(ProviderApp.linear, probe: probe),
  ];

  /// One provider's configuration.
  Future<ProviderAppStatus> status(
    ProviderApp provider, {
    bool probe = false,
  }) async {
    switch (provider) {
      case ProviderApp.github:
        final appId = await _readSetting(_githubAppIdKey) ?? '';
        final pem = await _secrets.readPsk(_githubPrivateKeySecret) ?? '';
        var installations = const <Map<String, Object?>>[];
        var error = '';
        var botLogin = '';
        if (probe && appId.isNotEmpty && pem.isNotEmpty) {
          final app = await githubApp();
          if (app == null) {
            error =
                'The private key could not be read. Paste the whole .pem '
                'file GitHub gave you, including its BEGIN and END lines.';
          } else {
            botLogin = (await app.botInfo())?.botLogin ?? '';
            final found = await app.installations(refresh: true);
            installations = [for (final i in found) i.toJson()];
            if (installations.isEmpty) {
              error =
                  'The credentials work, but the app is not installed on any '
                  'account yet — install it from its GitHub App page.';
            }
          }
        }
        return ProviderAppStatus(
          provider: provider,
          appId: appId,
          clientId:
              await _readSetting(_githubClientIdKey) ?? builtinGitHubClientId,
          botLogin: botLogin,
          hasPrivateKey: pem.isNotEmpty,
          hasClientSecret:
              (await _secrets.readPsk(_githubClientSecret) ?? '').isNotEmpty,
          installations: installations,
          error: error,
        );
      case ProviderApp.linear:
        return ProviderAppStatus(
          provider: provider,
          clientId: await _readSetting(_linearClientIdKey) ?? '',
          hasClientSecret:
              (await _secrets.readPsk(_linearClientSecret) ?? '').isNotEmpty,
          hasApiKey: (await linearApiKey()).isNotEmpty,
        );
    }
  }

  /// Saves [provider]'s configuration.
  ///
  /// Null leaves a field alone; an EMPTY STRING clears it. That distinction is
  /// what lets the settings form submit without re-typing a secret it was
  /// never shown, while still offering a way to remove one.
  ///
  /// Throws [AuthException] when a GitHub private key does not parse — a key
  /// that fails here fails every background request later, with no screen to
  /// report it on.
  Future<ProviderAppStatus> save(
    ProviderApp provider, {
    String? appId,
    String? clientId,
    String? clientSecret,
    String? privateKeyPem,
    String? apiKey,
  }) async {
    switch (provider) {
      case ProviderApp.github:
        if (privateKeyPem != null && privateKeyPem.trim().isNotEmpty) {
          final probe = GitHubAppClient.tryCreate(
            appId: appId?.trim().isNotEmpty ?? false
                ? appId!.trim()
                : (await _readSetting(_githubAppIdKey) ?? 'probe'),
            privateKeyPem: privateKeyPem.trim(),
          );
          if (probe == null) {
            throw const AuthException(
              'That private key could not be read. Paste the whole .pem file '
              'GitHub gave you, including its BEGIN and END lines.',
            );
          }
        }
        await _applySetting(_githubAppIdKey, appId);
        await _applySetting(_githubClientIdKey, clientId);
        await _applySecret(_githubPrivateKeySecret, privateKeyPem);
        await _applySecret(_githubClientSecret, clientSecret);
      case ProviderApp.linear:
        await _applySetting(_linearClientIdKey, clientId);
        await _applySecret(_linearClientSecret, clientSecret);
        await _applySecret(_linearApiKeySecret, apiKey);
    }
    _invalidate();
    return status(provider);
  }

  /// Drops the cached GitHub client so the next read rebuilds it. A token
  /// minted by the previous app is not stale, it is a different identity.
  void _invalidate() {
    _githubApp?.invalidate();
    _githubApp = null;
    _githubAppResolved = false;
  }

  Future<void> _applySetting(String key, String? value) async {
    if (value == null) {
      return;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await _deleteSetting(key);
      return;
    }
    await _writeSetting(key, trimmed);
  }

  Future<void> _applySecret(String key, String? value) async {
    if (value == null) {
      return;
    }
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      await _secrets.deletePsk(key);
      return;
    }
    await _secrets.writePsk(key, trimmed);
  }

  /// The client id this build ships, when it ships one.
  ///
  /// This is what makes "Sign in with GitHub" work on an official build with
  /// nothing configured: a device-flow client id is public by design, so it can
  /// travel in the binary. An operator's own value always wins over it.
  static String _builtinClientId(ProviderApp provider) => switch (provider) {
    ProviderApp.github => builtinGitHubClientId,
    // No Linear app ships: its flow is a confidential-client redirect, which
    // would need a secret in the binary and a callback URL per install.
    ProviderApp.linear => '',
  };

  Future<String?> _readSetting(String key) async {
    final dao = _settings;
    final value = dao == null ? _memory[key] : await dao.getValue(key);
    return (value == null || value.isEmpty) ? null : value;
  }

  Future<void> _writeSetting(String key, String value) async {
    final dao = _settings;
    if (dao == null) {
      _memory[key] = value;
      return;
    }
    await dao.setValue(key, value);
  }

  Future<void> _deleteSetting(String key) async {
    final dao = _settings;
    if (dao == null) {
      _memory.remove(key);
      return;
    }
    await dao.deleteValue(key);
  }
}
