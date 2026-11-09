import 'package:cc_domain/cc_domain.dart' show ValidationException;
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/provider_app_settings.dart';

/// A provider a workspace may bring its own app for, beside GitHub (which has
/// its own `WorkspaceGitHubAppSettings` and registry columns).
enum WorkspaceAppProvider {
  /// A Google OAuth client (Calendar): client id + client secret.
  google,

  /// A Linear OAuth application (public PKCE client: client id), plus an
  /// optional service API key for automation.
  linear,

  /// A Klipy app key (GIF search).
  klipy;

  /// The wire spelling.
  String get wire => name;

  /// Parses a wire value; null when unknown.
  static WorkspaceAppProvider? fromWire(Object? wire) {
    for (final p in values) {
      if (p.wire == wire) {
        return p;
      }
    }
    return null;
  }
}

/// Whose app a workspace uses for one provider.
enum WorkspaceAppMode {
  /// This server's lane: its own app, else Control Center Connect.
  inherit,

  /// The workspace's own app. Never falls back to the server's lane.
  own;

  /// The wire spelling.
  String get wire => name;

  /// Parses a wire value; null when unknown.
  static WorkspaceAppMode? fromWire(Object? wire) => switch (wire) {
    'inherit' => inherit,
    'own' => own,
    _ => null,
  };
}

/// One provider's workspace app as reported to clients.
///
/// Presence flags, never secrets: the client secret and the keys leave the
/// server only in a request to the provider itself.
class WorkspaceProviderAppStatus {
  /// Creates a [WorkspaceProviderAppStatus].
  const WorkspaceProviderAppStatus({
    required this.provider,
    required this.mode,
    this.clientId = '',
    this.hasClientSecret = false,
    this.hasApiKey = false,
    this.hasAppKey = false,
  });

  /// Which provider.
  final WorkspaceAppProvider provider;

  /// Whose app the workspace uses.
  final WorkspaceAppMode mode;

  /// The OAuth client id (not a secret: it rides in every authorize URL).
  final String clientId;

  /// Whether an OAuth client secret is stored (Google).
  final bool hasClientSecret;

  /// Whether a service API key is stored (Linear, optional).
  final bool hasApiKey;

  /// Whether an app key is stored (Klipy).
  final bool hasAppKey;

  /// How complete the workspace's own app is. [OwnAppState.none] while the
  /// workspace inherits; [OwnAppState.partial] is a setup error that never
  /// falls back to the server's lane.
  OwnAppState get state {
    if (mode == WorkspaceAppMode.inherit) {
      return OwnAppState.none;
    }
    final complete = switch (provider) {
      WorkspaceAppProvider.google => clientId.isNotEmpty && hasClientSecret,
      WorkspaceAppProvider.linear => clientId.isNotEmpty,
      WorkspaceAppProvider.klipy => hasAppKey,
    };
    return complete ? OwnAppState.complete : OwnAppState.partial;
  }

  /// What the admin has to fix, or empty.
  String get error => state == OwnAppState.partial
      ? WorkspaceAppIncomplete(provider).message
      : '';

  /// The wire shape.
  Map<String, Object?> toJson() => {
    'provider': provider.wire,
    'mode': mode.wire,
    'client_id': clientId,
    'has_client_secret': hasClientSecret,
    'has_api_key': hasApiKey,
    'has_app_key': hasAppKey,
    'state': state.wire,
    if (error.isNotEmpty) 'error': error,
  };
}

/// Thrown when a workspace uses its own app for a provider but that app is
/// missing a required field. The lane is unavailable: it never borrows this
/// server's app or Connect instead.
final class WorkspaceAppIncomplete implements Exception {
  /// Creates the error.
  const WorkspaceAppIncomplete(this.provider);

  /// Which provider.
  final WorkspaceAppProvider provider;

  /// What the admin has to fix.
  String get message => switch (provider) {
    WorkspaceAppProvider.google =>
      'This workspace uses its own Google client, but its client id or '
          'client secret is missing. Google Calendar in this workspace will '
          'not fall back to this server\'s app.',
    WorkspaceAppProvider.linear =>
      'This workspace uses its own Linear app, but its client id is missing. '
          'Linear in this workspace will not fall back to this server\'s app.',
    WorkspaceAppProvider.klipy =>
      'This workspace uses its own Klipy app key, but none is saved. GIF '
          'search in this workspace will not fall back to this server\'s key.',
  };

  @override
  String toString() => message;
}

/// Per-workspace Google, Linear and Klipy apps.
///
/// Everything lives in [FileSecretsStore] under
/// `workspace_provider_app_<provider>_<workspaceId>_<field>`, the mode marker
/// included, so exporting a workspace never carries a secret and the mode
/// cannot outlive the credentials it describes. Clients get presence flags.
///
/// [WorkspaceAppMode.inherit] (no marker) uses the server's lane. In
/// [WorkspaceAppMode.own] the workspace's app is the only one: a missing
/// field throws [WorkspaceAppIncomplete] rather than falling through.
class WorkspaceProviderAppSettings {
  /// Creates the settings over the server's secrets file.
  WorkspaceProviderAppSettings(this._secrets);

  final FileSecretsStore _secrets;
  final List<void Function(String workspaceId, WorkspaceAppProvider provider)>
  _listeners = [];

  static const String _prefix = 'workspace_provider_app_';
  static const String _mode = 'mode';
  static const String _clientId = 'client_id';
  static const String _clientSecret = 'client_secret';
  static const String _apiKey = 'api_key';
  static const String _appKey = 'app_key';

  /// The fields [provider] stores, in wire spelling.
  static List<String> fieldsOf(WorkspaceAppProvider provider) =>
      switch (provider) {
        WorkspaceAppProvider.google => const [_clientId, _clientSecret],
        WorkspaceAppProvider.linear => const [_clientId, _apiKey],
        WorkspaceAppProvider.klipy => const [_appKey],
      };

  /// Secrets-file key for one field of [workspaceId]'s [provider] app.
  static String secretKey(
    String workspaceId,
    WorkspaceAppProvider provider,
    String field,
  ) => '$_prefix${provider.wire}_${workspaceId}_$field';

  /// True when [key] is one of [workspaceId]'s Google, Linear or Klipy app
  /// fields.
  static bool isWorkspaceSecret(String key, String workspaceId) =>
      WorkspaceAppProvider.values.any(
        (provider) => _keysOf(workspaceId, provider).contains(key),
      );

  /// Every key [provider]'s app may occupy in [workspaceId], matched exactly
  /// so one workspace id that prefixes another never reaches its keys.
  static Set<String> _keysOf(
    String workspaceId,
    WorkspaceAppProvider provider,
  ) => {
    secretKey(workspaceId, provider, _mode),
    for (final field in fieldsOf(provider))
      secretKey(workspaceId, provider, field),
  };

  /// Runs [listener] whenever the app a workspace uses for a provider stops
  /// being the same app (mode or client id changed, or the Klipy key). Grants
  /// the previous app issued belong to a different client, so callers drop
  /// them.
  void addListener(
    void Function(String workspaceId, WorkspaceAppProvider provider) listener,
  ) => _listeners.add(listener);

  /// Whose app [workspaceId] uses for [provider].
  Future<WorkspaceAppMode> mode(
    String workspaceId,
    WorkspaceAppProvider provider,
  ) async =>
      await _read(workspaceId, provider, _mode) == WorkspaceAppMode.own.wire
      ? WorkspaceAppMode.own
      : WorkspaceAppMode.inherit;

  /// Whether [workspaceId] uses its own app for [provider].
  Future<bool> ownsApp(
    String workspaceId,
    WorkspaceAppProvider provider,
  ) async =>
      workspaceId.isNotEmpty &&
      await mode(workspaceId, provider) == WorkspaceAppMode.own;

  /// [provider]'s configuration in [workspaceId], for the settings card.
  Future<WorkspaceProviderAppStatus> status(
    String workspaceId,
    WorkspaceAppProvider provider,
  ) async => WorkspaceProviderAppStatus(
    provider: provider,
    mode: await mode(workspaceId, provider),
    clientId: await _read(workspaceId, provider, _clientId),
    hasClientSecret: (await _read(
      workspaceId,
      provider,
      _clientSecret,
    )).isNotEmpty,
    hasApiKey: (await _read(workspaceId, provider, _apiKey)).isNotEmpty,
    hasAppKey: (await _read(workspaceId, provider, _appKey)).isNotEmpty,
  );

  /// Every provider's configuration in [workspaceId].
  Future<List<WorkspaceProviderAppStatus>> statuses(String workspaceId) async =>
      [
        for (final provider in WorkspaceAppProvider.values)
          await status(workspaceId, provider),
      ];

  /// Switches [workspaceId] between the server's lane and its own app for
  /// [provider]. Going back to the server's lane deletes the workspace's
  /// fields, so no secret outlives the choice that used it.
  Future<WorkspaceProviderAppStatus> setMode(
    String workspaceId,
    WorkspaceAppProvider provider,
    WorkspaceAppMode next,
  ) async {
    final before = await _identity(workspaceId, provider);
    switch (next) {
      case WorkspaceAppMode.own:
        await _secrets.writePsk(
          secretKey(workspaceId, provider, _mode),
          WorkspaceAppMode.own.wire,
        );
      case WorkspaceAppMode.inherit:
        final keys = _keysOf(workspaceId, provider);
        await _secrets.deleteMatching(keys.contains);
    }
    await _notifyIfChanged(workspaceId, provider, before);
    return status(workspaceId, provider);
  }

  /// Saves fields of [workspaceId]'s own [provider] app (`client_id`,
  /// `client_secret`, `api_key`, `app_key`). A field that is not in [fields]
  /// is left alone; an empty string clears it. Saving puts the workspace on
  /// its own app. Throws [ValidationException] for a field [provider] does
  /// not have.
  Future<WorkspaceProviderAppStatus> save(
    String workspaceId,
    WorkspaceAppProvider provider,
    Map<String, String> fields,
  ) async {
    final allowed = fieldsOf(provider);
    for (final field in fields.keys) {
      if (!allowed.contains(field)) {
        throw ValidationException(
          '${provider.wire} has no "$field" field. It takes '
          '${allowed.join(', ')}.',
        );
      }
    }
    final before = await _identity(workspaceId, provider);
    await _secrets.writePsk(
      secretKey(workspaceId, provider, _mode),
      WorkspaceAppMode.own.wire,
    );
    for (final MapEntry(:key, :value) in fields.entries) {
      final trimmed = value.trim();
      final secret = secretKey(workspaceId, provider, key);
      if (trimmed.isEmpty) {
        await _secrets.deletePsk(secret);
      } else {
        await _secrets.writePsk(secret, trimmed);
      }
    }
    await _notifyIfChanged(workspaceId, provider, before);
    return status(workspaceId, provider);
  }

  /// The OAuth client [workspaceId] signs people in to [provider] with
  /// (Google or Linear): null while it inherits; throws
  /// [WorkspaceAppIncomplete] when its own app is missing a field. Linear's
  /// secret is empty (public PKCE client).
  Future<OAuthAppCredentials?> oauthCredentials(
    String workspaceId,
    WorkspaceAppProvider provider,
  ) async {
    if (provider == WorkspaceAppProvider.klipy) {
      throw ArgumentError.value(provider, 'provider', 'not an OAuth client');
    }
    if (!await ownsApp(workspaceId, provider)) {
      return null;
    }
    final current = await status(workspaceId, provider);
    if (current.state != OwnAppState.complete) {
      throw WorkspaceAppIncomplete(provider);
    }
    return (
      clientId: current.clientId,
      clientSecret: provider == WorkspaceAppProvider.google
          ? await _read(workspaceId, provider, _clientSecret)
          : '',
    );
  }

  /// The client id a grant in [workspaceId] must have been issued to when it
  /// uses its own [provider] app, even half-configured (empty when the id is
  /// missing). Null while it inherits.
  Future<String?> ownClientId(
    String workspaceId,
    WorkspaceAppProvider provider,
  ) async => await ownsApp(workspaceId, provider)
      ? _read(workspaceId, provider, _clientId)
      : null;

  /// The Linear service API key automation in [workspaceId] may use: null
  /// while it inherits (the server's key applies), else the workspace's own
  /// key or empty when it has none. Never the server's key in own mode.
  Future<String?> linearApiKey(String workspaceId) async =>
      await ownsApp(workspaceId, WorkspaceAppProvider.linear)
      ? _read(workspaceId, WorkspaceAppProvider.linear, _apiKey)
      : null;

  /// [workspaceId]'s own Klipy app key: null while it inherits; throws
  /// [WorkspaceAppIncomplete] when it uses its own key but none is saved.
  Future<String?> klipyAppKey(String workspaceId) async {
    if (!await ownsApp(workspaceId, WorkspaceAppProvider.klipy)) {
      return null;
    }
    final key = await _read(workspaceId, WorkspaceAppProvider.klipy, _appKey);
    if (key.isEmpty) {
      throw const WorkspaceAppIncomplete(WorkspaceAppProvider.klipy);
    }
    return key;
  }

  /// Deletes every Google, Linear and Klipy app field of [workspaceId].
  Future<int> deleteForWorkspace(String workspaceId) =>
      _secrets.deleteMatching((key) => isWorkspaceSecret(key, workspaceId));

  /// What identifies the app: a change means grants it issued are someone
  /// else's now. A Google or Linear secret or a Linear API key is not part
  /// of it (same client, same grants).
  Future<String> _identity(
    String workspaceId,
    WorkspaceAppProvider provider,
  ) async {
    final mode = await this.mode(workspaceId, provider);
    if (mode == WorkspaceAppMode.inherit) {
      return '';
    }
    final id = provider == WorkspaceAppProvider.klipy
        ? (await _read(workspaceId, provider, _appKey)).hashCode.toString()
        : await _read(workspaceId, provider, _clientId);
    return 'own:$id';
  }

  Future<void> _notifyIfChanged(
    String workspaceId,
    WorkspaceAppProvider provider,
    String before,
  ) async {
    if (await _identity(workspaceId, provider) == before) {
      return;
    }
    for (final listener in List.of(_listeners)) {
      listener(workspaceId, provider);
    }
  }

  Future<String> _read(
    String workspaceId,
    WorkspaceAppProvider provider,
    String field,
  ) async =>
      (await _secrets.readPsk(secretKey(workspaceId, provider, field)) ?? '')
          .trim();
}
