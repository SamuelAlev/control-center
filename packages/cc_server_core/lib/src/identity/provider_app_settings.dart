import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_infra/cc_infra.dart' show GitHubAppClient;
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/forge/forge_audit.dart';

/// A provider the server can hold its own app identity for.
///
/// Deliberately a small closed set rather than a free string: each entry has a
/// hand-written OAuth endpoint pair and a hand-written credential shape.
/// Configuring one here makes that lane run in own mode; leaving it empty
/// routes the lane through Control Center Connect (when enabled). The two
/// never mix: a half-configured own app is a setup error, not a Connect
/// fallback.
enum ProviderApp {
  /// A GitHub App: app id + private key (scoped tokens for automation) and a
  /// client id + secret (person sign-in, Web OAuth with PKCE). All four or
  /// none.
  github,

  /// A Google OAuth client (Calendar, read-only): client id + secret.
  google,

  /// A Linear OAuth application (public PKCE client: client id only), plus
  /// an optional service API key for workspace sync.
  linear;

  /// The wire spelling.
  String get wire => name;

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

/// How complete one provider's own app is.
enum OwnAppState {
  /// Nothing configured: the lane may use Connect.
  none,

  /// Some fields set, others missing: a setup error, never a Connect
  /// fallback.
  partial,

  /// Ready to use.
  complete;

  /// The wire spelling.
  String get wire => name;
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
    this.active = true,
  });

  /// Which provider.
  final ProviderApp provider;

  /// Whether the server's own apps are in force: false while the operator
  /// uses a hosted or custom Connect, when the stored app is kept but every
  /// lane ignores it.
  final bool active;

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

  /// How complete the own app is.
  OwnAppState get state {
    final fields = switch (provider) {
      ProviderApp.github => [
        appId.isNotEmpty,
        hasPrivateKey,
        clientId.isNotEmpty,
        hasClientSecret,
      ],
      ProviderApp.google => [clientId.isNotEmpty, hasClientSecret],
      ProviderApp.linear => [clientId.isNotEmpty],
    };
    if (fields.every((f) => f)) {
      return OwnAppState.complete;
    }
    return fields.any((f) => f) ? OwnAppState.partial : OwnAppState.none;
  }

  /// How complete the own app is as lanes see it: [OwnAppState.none] while
  /// it is inactive, whatever is stored.
  OwnAppState get effectiveState => active ? state : OwnAppState.none;

  /// True when this provider can run a person sign-in in own mode.
  bool get canSignIn => effectiveState == OwnAppState.complete;

  /// True when the server can act for automation on this provider without
  /// a person: a complete GitHub App, or a Linear service API key.
  bool get canActAsServer =>
      active &&
      switch (provider) {
        ProviderApp.github => state == OwnAppState.complete,
        ProviderApp.google => false,
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
    'state': state.wire,
    'active': active,
    'can_sign_in': canSignIn,
    'can_act_as_server': canActAsServer,
    'installations': installations,
    if (error.isNotEmpty) 'error': error,
  };
}

/// An OAuth client id/secret pair.
typedef OAuthAppCredentials = ({String clientId, String clientSecret});

/// Server-wide own-app credentials (GitHub App, Google client, Linear app).
///
/// Non-secrets in `server_settings`, secrets in [FileSecretsStore]; the
/// `.env` file seeds unset fields once, then the store wins.
///
/// The one chokepoint for whether they apply: `ownAppsActive` (the Connect
/// choice, `ConnectSettings.serverOwnAppsActive`) false makes [githubApp],
/// [oauthCredentials] and [linearApiKey] answer as if nothing were stored,
/// and [status] report `active: false`. The stored values stay, so choosing
/// no Connect again restores them. Null (hosts with no Connect) is active.
class ProviderAppSettings {
  /// Creates a [ProviderAppSettings].
  ProviderAppSettings({
    required this._secrets,
    this._settings,
    this._githubAppFactory,
    this._ownAppsActive,
  });

  final FileSecretsStore _secrets;
  final ServerSettingDao? _settings;
  final Future<bool> Function()? _ownAppsActive;
  final GitHubAppClient Function({required String appId, required String pem})?
  _githubAppFactory;

  static const _githubAppIdKey = 'provider_app_github_app_id';
  static const _githubClientIdKey = 'provider_app_github_client_id';
  static const _linearClientIdKey = 'provider_app_linear_client_id';
  static const _googleClientIdKey = 'provider_app_google_client_id';

  static const _githubPrivateKeySecret = 'provider_app_github_private_key';
  static const _githubClientSecret = 'provider_app_github_client_secret';
  static const _googleClientSecret = 'provider_app_google_client_secret';
  static const _linearApiKeySecret = 'provider_app_linear_api_key';

  /// In-memory settings for hosts that wire no database (tests, the minimal
  /// server). Without this an env-seeded app would be forgotten per read.
  final Map<String, String> _memory = {};

  GitHubAppClient? _githubApp;
  bool _githubAppResolved = false;
  final List<void Function(ProviderApp provider)> _listeners = [];

  /// Runs [listener] after every [save]: a token minted by the previous app
  /// belongs to a different identity, so callers drop what they cached.
  void addListener(void Function(ProviderApp provider) listener) =>
      _listeners.add(listener);

  /// Whether the stored own apps are in force right now.
  Future<bool> active() async => await _ownAppsActive?.call() ?? true;

  /// Runs after the Connect choice changed: every own app may have turned on
  /// or off, so the cached GitHub client goes and every listener hears about
  /// every provider.
  void connectChoiceChanged() {
    _invalidate();
    for (final provider in ProviderApp.values) {
      for (final listener in List.of(_listeners)) {
        listener(provider);
      }
    }
  }

  /// Seeds each field from [env] (the server's `.env` file) once.
  ///
  /// Runs at boot, before the HTTP listener starts, so the first inbound
  /// request already sees a configured app. A field `.env` names is written
  /// only when it is unset, and only the first time `.env` names it: a
  /// marker per field records that, so a value an owner cleared or replaced
  /// in Settings stays that way across restarts.
  Future<void> loadAndApply({Map<String, String> env = const {}}) async {
    Future<void> seed(
      String key,
      String? value, {
      required Future<String?> Function(String key) read,
      required Future<void> Function(String key, String value) write,
    }) async {
      final marker = '$_envSeededPrefix$key';
      if (value == null ||
          value.trim().isEmpty ||
          await _readSetting(marker) != null) {
        return;
      }
      final existing = await read(key);
      if (existing == null || existing.isEmpty) {
        await write(key, value.trim());
      }
      await _writeSetting(marker, '1');
    }

    Future<void> seedSetting(String key, String? value) =>
        seed(key, value, read: _readSetting, write: _writeSetting);
    Future<void> seedSecret(String key, String? value) =>
        seed(key, value, read: _secrets.readPsk, write: _secrets.writePsk);

    await seedSetting(_githubAppIdKey, env['GITHUB_APP_ID']);
    await seedSecret(_githubPrivateKeySecret, env['GITHUB_APP_PRIVATE_KEY']);
    await seedSetting(_githubClientIdKey, env['GITHUB_CLIENT_ID']);
    await seedSecret(_githubClientSecret, env['GITHUB_CLIENT_SECRET']);
    await seedSetting(_googleClientIdKey, env['GOOGLE_OAUTH_CLIENT_ID']);
    await seedSecret(_googleClientSecret, env['GOOGLE_OAUTH_CLIENT_SECRET']);
    await seedSetting(_linearClientIdKey, env['LINEAR_CLIENT_ID']);
    await seedSecret(_linearApiKeySecret, env['LINEAR_API_KEY']);
    _invalidate();
  }

  /// Settings key prefix of the per-field "seeded from `.env`" markers.
  static const String _envSeededPrefix = 'provider_app_env_seeded:';

  /// The live GitHub App client, or null unless the server's own GitHub App
  /// is complete (app id, key, client id and secret). A partial app never
  /// mints anything.
  Future<GitHubAppClient?> githubApp() async {
    if (!await active()) {
      return null;
    }
    if (_githubAppResolved) {
      return _githubApp;
    }
    _githubAppResolved = true;
    if ((await status(ProviderApp.github)).state != OwnAppState.complete) {
      return _githubApp = null;
    }
    final appId = await _readSetting(_githubAppIdKey) ?? '';
    final pem = await _secrets.readPsk(_githubPrivateKeySecret) ?? '';
    final factory = _githubAppFactory;
    return _githubApp = factory != null
        ? factory(appId: appId, pem: pem)
        : GitHubAppClient.tryCreate(appId: appId, privateKeyPem: pem);
  }

  /// The own-app OAuth client for [provider], or null when none is
  /// configured or own apps are inactive. Throws [OwnAppIncomplete] when it
  /// is half-configured (and active).
  Future<OAuthAppCredentials?> oauthCredentials(ProviderApp provider) async {
    final current = await status(provider);
    switch (current.effectiveState) {
      case OwnAppState.none:
        return null;
      case OwnAppState.partial:
        throw OwnAppIncomplete(provider);
      case OwnAppState.complete:
        final secretKey = switch (provider) {
          ProviderApp.github => _githubClientSecret,
          ProviderApp.google => _googleClientSecret,
          ProviderApp.linear => null,
        };
        return (
          clientId: current.clientId,
          clientSecret: secretKey == null
              ? ''
              : await _secrets.readPsk(secretKey) ?? '',
        );
    }
  }

  /// The server-level Linear API key, or empty (also while own apps are
  /// inactive).
  Future<String> linearApiKey() async => await active()
      ? await _storedLinearApiKey()
      : '';

  Future<String> _storedLinearApiKey() async =>
      await _secrets.readPsk(_linearApiKeySecret) ?? '';

  /// Every provider's configuration, for the settings screen.
  ///
  /// [probe] additionally asks GitHub which installations the app has — a
  /// network call, so it is opt-in rather than part of every settings read.
  Future<List<ProviderAppStatus>> statuses({bool probe = false}) async => [
    for (final provider in ProviderApp.values)
      await status(provider, probe: probe),
  ];

  /// One provider's configuration.
  Future<ProviderAppStatus> status(
    ProviderApp provider, {
    bool probe = false,
  }) async {
    final active = await this.active();
    switch (provider) {
      case ProviderApp.github:
        final appId = await _readSetting(_githubAppIdKey) ?? '';
        final pem = await _secrets.readPsk(_githubPrivateKeySecret) ?? '';
        var installations = const <Map<String, Object?>>[];
        var error = '';
        var botLogin = '';
        if (probe && !active) {
          error =
              'This server uses Control Center Connect, so its own GitHub '
              'App is not in use. Choose "Use my own apps" to use it.';
        } else if (probe && appId.isNotEmpty && pem.isNotEmpty) {
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
          clientId: await _readSetting(_githubClientIdKey) ?? '',
          botLogin: botLogin,
          hasPrivateKey: pem.isNotEmpty,
          hasClientSecret:
              (await _secrets.readPsk(_githubClientSecret) ?? '').isNotEmpty,
          installations: installations,
          error: error,
          active: active,
        );
      case ProviderApp.google:
        return ProviderAppStatus(
          provider: provider,
          clientId: await _readSetting(_googleClientIdKey) ?? '',
          hasClientSecret:
              (await _secrets.readPsk(_googleClientSecret) ?? '').isNotEmpty,
          active: active,
        );
      case ProviderApp.linear:
        return ProviderAppStatus(
          provider: provider,
          clientId: await _readSetting(_linearClientIdKey) ?? '',
          hasApiKey: (await _storedLinearApiKey()).isNotEmpty,
          active: active,
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
          if (!GitHubAppClient.isReadablePrivateKey(privateKeyPem.trim())) {
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
      case ProviderApp.google:
        await _applySetting(_googleClientIdKey, clientId);
        await _applySecret(_googleClientSecret, clientSecret);
      case ProviderApp.linear:
        await _applySetting(_linearClientIdKey, clientId);
        await _applySecret(_linearApiKeySecret, apiKey);
    }
    forgeAudit(ForgeAuditEvent.providerAppSaved, {
      'provider': provider.name,
      'scope': 'server',
      // Names only: which fields this save set or cleared.
      'fields': [
        if (appId != null) 'app_id',
        if (clientId != null) 'client_id',
        if (clientSecret != null) 'client_secret',
        if (privateKeyPem != null) 'private_key',
        if (apiKey != null) 'api_key',
      ].join(','),
    });
    _invalidate();
    for (final listener in List.of(_listeners)) {
      listener(provider);
    }
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

/// Thrown when an own app is half-configured.
final class OwnAppIncomplete implements Exception {
  /// Creates the error.
  const OwnAppIncomplete(this.provider);

  /// Which provider.
  final ProviderApp provider;

  /// What the operator has to fix.
  String get message => switch (provider) {
    ProviderApp.github =>
      'This server\'s GitHub App is only partly set up. Add the app id, '
          'private key, client id and client secret — or clear them all to '
          'use Control Center Connect.',
    ProviderApp.google =>
      'This server\'s Google client is only partly set up. Add both the '
          'client id and the client secret — or clear them to use Control '
          'Center Connect.',
    ProviderApp.linear => 'This server\'s Linear app is only partly set up.',
  };

  @override
  String toString() => message;
}
