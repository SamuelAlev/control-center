import 'dart:math';

import 'package:cc_domain/cc_domain.dart' show AuthException;
import 'package:cc_domain/core/domain/entities/sso_connection.dart';
import 'package:cc_domain/core/domain/repositories/sso_connection_repository.dart';
import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';
import 'package:cc_persistence/cc_persistence.dart';
import 'package:cc_server_core/src/file_secrets_store.dart';
import 'package:cc_server_core/src/identity/oidc_service.dart';
import 'package:cc_server_core/src/identity/saml_service.dart';
import 'package:cc_server_core/src/identity/sso_provisioner.dart';

/// The secrets-store key holding the SCIM bearer token (0600 file store, the
/// `UserCredentialsStore` pattern — never a database column, never returned
/// to a client after generation).
const String scimTokenSecretKey = 'scim_token';

/// The secrets-store key holding the OIDC client secret (confidential IdP
/// clients only — public PKCE clients never set it). Same storage rule as
/// the SCIM token: the `sso_connections` row carries a presence flag's
/// worth of information (nothing), never the secret itself.
const String oidcClientSecretKey = 'oidc_client_secret';

/// Server-wide SSO configuration: the bridge between the persisted
/// [SsoConnection] rows (one per protocol kind), the environment seeds and
/// the live login services.
///
/// Boot order: `loadAndApply` reads the rows and pushes the derived configs
/// into [SamlService] / [OidcService] via their `updateConfig` seams (single
/// isolate, so a swap is atomic in practice). The database is the only source
/// of truth; every `sso.saveConfig` RPC persists first, then re-applies, so a
/// rejected apply can never leave the running services disagreeing with the
/// row.
class SsoSettingsService {
  /// Creates an [SsoSettingsService].
  SsoSettingsService({
    required SsoConnectionRepository connections,
    required FileSecretsStore secrets,
    required this.saml,
    required this.oidc,
    ServerSettingDao? settings,
    Future<String?> Function()? canonicalOrigin,
    DateTime Function()? now,
  }) : _connections = connections,
       _secrets = secrets,
       _settings = settings,
       _canonicalOrigin = canonicalOrigin,
       _now = now ?? DateTime.now;

  final SsoConnectionRepository _connections;
  final FileSecretsStore _secrets;
  final ServerSettingDao? _settings;
  final Future<String?> Function()? _canonicalOrigin;
  final DateTime Function() _now;

  /// The server-setting key holding the manual-pairing posture. Absent or
  /// `'true'` = enabled; `'false'` = new devices may only join via SSO
  /// (existing credentials keep working — SSO logins mint devices through
  /// the internal seam, not the pairing ops this flag gates).
  static const _pairingEnabledKey = 'auth_pairing_enabled';

  /// Hard cap on a device credential's total lifetime, in minutes (0 = the
  /// pairing default). Enterprise security questionnaires ask for this by
  /// name.
  static const sessionMaxAgeKey = 'auth_session_max_age_minutes';

  /// Idle timeout: a device whose last-seen is older than this must
  /// re-authenticate, in minutes (0 = no idle timeout).
  static const sessionIdleTimeoutKey = 'auth_session_idle_timeout_minutes';

  /// The SAML login service this reconfigures.
  final SamlService saml;

  /// The OIDC login service this reconfigures.
  final OidcService oidc;

  /// Loads the saved rows and applies them to the live services. Called once
  /// at boot, before the HTTP listener starts.
  ///
  /// The database is the ONLY source: SSO is configured in Settings → Server →
  /// Single sign-on and nowhere else. It used to seed from `CC_SAML_*` /
  /// `CC_OIDC_*` on a first boot, which meant a connection could arrive from
  /// two places and the screen could disagree with what was running.
  Future<void> loadAndApply() async {
    for (final kind in SsoProviderKind.values) {
      final row = await _connections.getByKind(kind);
      if (row != null) {
        await _apply(row);
      }
    }
  }

  /// The saved connection for [kind] (null when never configured).
  Future<SsoConnection?> get(SsoProviderKind kind) =>
      _connections.getByKind(kind);

  /// Validates, persists and applies [connection]. Throws [AuthException]
  /// on policy violations (enabled without required fields, owner-mapped
  /// roles) — validation happens BEFORE the write so a bad row never lands.
  ///
  /// [clientSecret] (OIDC only) replaces the stored client secret; null or
  /// empty keeps the current one — clearing happens by disabling the
  /// connection, never by blanking the field.
  Future<SsoConnection> save(
    SsoConnection connection, {
    String? clientSecret,
  }) async {
    _validate(connection);
    final row = connection.copyWith(updatedAt: _now());
    if (row.kind == SsoProviderKind.oidc &&
        clientSecret != null &&
        clientSecret.isNotEmpty) {
      await _secrets.writePsk(oidcClientSecretKey, clientSecret);
    }
    await _connections.upsert(row);
    await _apply(row);
    return row;
  }

  /// Whether an OIDC client secret is stored (presence only — the secret
  /// itself is never returned over RPC).
  Future<bool> oidcClientSecretPresent() async {
    final secret = await _secrets.readPsk(oidcClientSecretKey);
    return secret != null && secret.isNotEmpty;
  }

  /// Tests a connection short of the browser round-trip — the settings
  /// screen's test button. The optional [idpMetadataXml] / [issuer]
  /// override the saved row, so the admin tests what is on screen, saved or
  /// not. Returns the discovered facts; throws [AuthException] with a
  /// plain-language reason on failure.
  Future<Map<String, Object?>> testConnection(
    SsoProviderKind kind, {
    String? idpMetadataXml,
    String? issuer,
  }) async {
    final row = await _connections.getByKind(kind);
    switch (kind) {
      case SsoProviderKind.saml:
        final xml = (idpMetadataXml?.trim().isNotEmpty ?? false)
            ? idpMetadataXml!
            : row?.idpMetadataXml ?? '';
        if (xml.isEmpty) {
          throw const AuthException('No IdP metadata to test');
        }
        final origin = await canonicalOrigin();
        if (origin == null || origin.isEmpty) {
          throw const AuthException(
            'The server has no known public origin (set --public-url or '
            'enable a tunnel) — the ACS URL cannot be derived',
          );
        }
        final result = saml.testConnection(idpMetadataXml: xml, origin: origin);
        return {
          'entity_id': result.entityId,
          'sso_endpoint': result.ssoEndpoint,
          'sp_entity_id': result.spEntityId,
          'acs_url': result.acsUrl,
        };
      case SsoProviderKind.oidc:
        final issuerBase = (issuer?.trim().isNotEmpty ?? false)
            ? issuer!.trim()
            : row?.issuer ?? '';
        if (issuerBase.isEmpty) {
          throw const AuthException('No issuer URL to test');
        }
        final endpoints = await oidc.testDiscovery(issuerBase);
        return {
          'authorization_endpoint': endpoints.authorizationEndpoint,
          'token_endpoint': endpoints.tokenEndpoint,
        };
    }
  }

  /// The operational status the settings screen shows.
  Future<Map<String, Object?>> status() async {
    final rows = await _connections.getAll();
    final scimToken = await _secrets.readPsk(scimTokenSecretKey);
    final oidcSecretPresent = await oidcClientSecretPresent();
    return {
      for (final row in rows)
        row.kind.wireName: {
          'enabled': row.enabled,
          'configured': row.configured,
          'auto_member': row.autoMember,
          'allow_jit': row.allowJit,
          if (row.kind == SsoProviderKind.oidc)
            'client_secret_present': oidcSecretPresent,
        },
      'scim': {'token_present': scimToken != null && scimToken.isNotEmpty},
      'pairing_enabled': await isPairingEnabled(),
      if (await _canonicalOrigin?.call() case final origin?
          when origin.isNotEmpty)
        'origin': origin,
    };
  }

  /// The server's canonical HTTP origin (tunnel > publicUrl > loopback), or
  /// null when none could be derived.
  Future<String?> canonicalOrigin() async => await _canonicalOrigin?.call();

  /// Whether manual pairing (invite codes, device-id + pairing key, the
  /// `pairing.mint` op) is allowed. Defaults to true; disabling it makes
  /// the server SSO-only for NEW devices.
  Future<bool> isPairingEnabled() async {
    final value = await _settings?.getValue(_pairingEnabledKey);
    return value != 'false';
  }

  /// Sets the manual-pairing posture. Lockout guard: refusing to disable
  /// pairing while no SSO connection is enabled-and-configured — otherwise
  /// the server would have no working way to onboard anyone new.
  Future<void> setPairingEnabled(bool enabled) async {
    if (!enabled) {
      final usable = (await _connections.getAll()).any(
        (c) => c.enabled && c.configured,
      );
      if (!usable) {
        throw const AuthException(
          'Enable a working single sign-on connection before disabling '
          'manual pairing — otherwise no new device could ever join',
        );
      }
    }
    await _settings?.setValue(_pairingEnabledKey, enabled ? 'true' : 'false');
  }

  /// The session policy this install enforces.
  ///
  /// Both bounds default to 0 = unset, which is the pre-policy behaviour (a
  /// device credential lives until its pairing expiry). They are enforced
  /// server-side at the device check, not merely advertised — a session
  /// policy a client could ignore is a checkbox, not a control.
  Future<({int maxAgeMinutes, int idleTimeoutMinutes})> sessionPolicy() async {
    Future<int> read(String key) async {
      final raw = await _settings?.getValue(key);
      final parsed = int.tryParse(raw ?? '') ?? 0;
      return parsed < 0 ? 0 : parsed;
    }

    return (
      maxAgeMinutes: await read(sessionMaxAgeKey),
      idleTimeoutMinutes: await read(sessionIdleTimeoutKey),
    );
  }

  /// Sets the session policy (server owner only, enforced at the op).
  Future<void> setSessionPolicy({
    int? maxAgeMinutes,
    int? idleTimeoutMinutes,
  }) async {
    if (maxAgeMinutes != null) {
      await _settings?.setValue(
        sessionMaxAgeKey,
        '${maxAgeMinutes < 0 ? 0 : maxAgeMinutes}',
      );
    }
    if (idleTimeoutMinutes != null) {
      await _settings?.setValue(
        sessionIdleTimeoutKey,
        '${idleTimeoutMinutes < 0 ? 0 : idleTimeoutMinutes}',
      );
    }
  }

  /// Whether a device paired at [pairedAt] and last seen at [lastSeenAt] has
  /// fallen outside the session policy at [now].
  ///
  /// Pure given the policy, so the enforcement point can call it per request
  /// without a second settings read on the hot path.
  static bool violatesSessionPolicy({
    required ({int maxAgeMinutes, int idleTimeoutMinutes}) policy,
    required DateTime pairedAt,
    required DateTime? lastSeenAt,
    required DateTime now,
  }) {
    if (policy.maxAgeMinutes > 0 &&
        now.difference(pairedAt) > Duration(minutes: policy.maxAgeMinutes)) {
      return true;
    }
    if (policy.idleTimeoutMinutes > 0) {
      // A device that has never been seen is measured from pairing, so an
      // idle timeout cannot be dodged by never calling anything.
      final reference = lastSeenAt ?? pairedAt;
      if (now.difference(reference) >
          Duration(minutes: policy.idleTimeoutMinutes)) {
        return true;
      }
    }
    return false;
  }

  /// The unauthenticated `/auth/providers` document: which interactive
  /// auth methods this server offers. Connect screens probe this before
  /// any credential exists, so it carries ids/kinds/labels only — never
  /// configuration detail.
  Future<Map<String, Object?>> authProviders() async {
    final providers = <Map<String, Object?>>[
      for (final connection in await _connections.getAll())
        if (connection.enabled && connection.configured)
          {
            'id': connection.id,
            'kind': connection.kind.wireName,
            'label': switch (connection.kind) {
              SsoProviderKind.saml => 'SAML',
              SsoProviderKind.oidc => 'OpenID Connect',
            },
          },
    ];
    return {'providers': providers, 'pairingEnabled': await isPairingEnabled()};
  }

  /// Generates a fresh SCIM bearer token, persists it and returns it — the
  /// ONE time it is ever visible. Constant-time verified afterwards.
  Future<String> regenerateScimToken() async {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    final token = bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
    await _secrets.writePsk(scimTokenSecretKey, token);
    return token;
  }

  /// Whether a SCIM bearer token has been generated.
  Future<bool> scimTokenPresent() async {
    final token = await _secrets.readPsk(scimTokenSecretKey);
    return token != null && token.isNotEmpty;
  }

  /// Constant-time check of a presented SCIM bearer token.
  Future<bool> verifyScimToken(String presented) async {
    final stored = await _secrets.readPsk(scimTokenSecretKey);
    if (stored == null || stored.isEmpty) {
      return false;
    }
    return _constantTimeEquals(stored, presented);
  }

  Future<void> _apply(SsoConnection row) async {
    switch (row.kind) {
      case SsoProviderKind.saml:
        saml.updateConfig(_samlConfigFrom(row));
      case SsoProviderKind.oidc:
        oidc.updateConfig(await _oidcConfigFrom(row));
    }
  }

  void _validate(SsoConnection connection) {
    if (connection.enabled && !connection.configured) {
      throw const AuthException(
        'The connection is missing required fields (SAML: IdP metadata; '
        'OIDC: issuer and client id)',
      );
    }
    if (connection.enabled &&
        connection.kind == SsoProviderKind.oidc &&
        !OidcConfig.isIssuerAllowed(connection.issuer)) {
      throw const AuthException(
        'The issuer must be an https URL (http is allowed only for a '
        'loopback issuer during local development)',
      );
    }
    for (final role in connection.groupRoleMap.values) {
      if (role == WorkspaceRole.owner) {
        throw const AuthException(
          'SSO group mappings may not grant the owner role',
        );
      }
    }
    if (connection.defaultRole == WorkspaceRole.owner) {
      throw const AuthException('The default SSO role may not be owner');
    }
  }

  SamlConfig _samlConfigFrom(SsoConnection row) => SamlConfig(
    idpMetadataXml: row.enabled ? row.idpMetadataXml : '',
    spEntityId: row.spEntityId,
    emailAttribute: row.emailAttribute,
    displayNameAttribute: row.displayNameAttribute,
    groupsAttribute: row.groupsAttribute,
    defaultRole: row.defaultRole,
    groupRoleMap: row.groupRoleMap,
    autoMemberMode: row.autoMember
        ? SsoAutoMemberMode.all
        : SsoAutoMemberMode.none,
    allowJit: row.allowJit,
    allowIdpInitiated: row.allowIdpInitiated,
    wantResponseSigned: row.wantResponseSigned,
    clockSkew: SamlConfig.clampClockSkew(row.clockSkewSeconds),
  );

  Future<OidcConfig> _oidcConfigFrom(SsoConnection row) async => OidcConfig(
    issuer: row.enabled ? row.issuer : '',
    clientId: row.enabled ? row.clientId : '',
    clientSecret: row.enabled
        ? (await _secrets.readPsk(oidcClientSecretKey)) ?? ''
        : '',
    defaultRole: row.defaultRole,
    groupRoleMap: row.groupRoleMap,
    groupsClaim: row.groupsClaim,
    autoMemberMode: row.autoMember
        ? SsoAutoMemberMode.all
        : SsoAutoMemberMode.none,
    allowJit: row.allowJit,
  );

  /// Length-checked, early-exit-free comparison (both branches always run so
  /// the timing does not leak the stored length).
  static bool _constantTimeEquals(String a, String b) {
    var diff = a.length ^ b.length;
    for (var i = 0; i < a.length && i < b.length; i++) {
      diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return diff == 0;
  }
}
