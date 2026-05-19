import 'package:cc_rpc/cc_rpc.dart';

/// The client-side view of a saved SSO connection row (the `sso.getConfig`
/// shape; secrets never appear — the SCIM token is returned once at
/// generation and nowhere else).
class RemoteSsoConnection {
  /// Creates a [RemoteSsoConnection].
  const RemoteSsoConnection({
    required this.kind,
    required this.enabled,
    required this.configured,
    this.issuer = '',
    this.clientId = '',
    this.groupsClaim = 'groups',
    this.idpMetadataXml = '',
    this.spEntityId = '',
    this.emailAttribute = 'email',
    this.displayNameAttribute = 'displayName',
    this.groupsAttribute = 'groups',
    this.defaultRole = 'member',
    this.groupRoleMap = const {},
    this.autoMember = true,
    this.allowJit = true,
    this.allowIdpInitiated = false,
    this.wantResponseSigned = false,
    this.clockSkewSeconds = 90,
  });

  /// Decodes the `sso.getConfig`/`sso.saveConfig` payload.
  factory RemoteSsoConnection.fromJson(Map<String, dynamic> json) =>
      RemoteSsoConnection(
        kind: json['kind'] as String? ?? 'saml',
        enabled: json['enabled'] as bool? ?? false,
        configured: json['enabled'] as bool? ?? false,
        issuer: json['issuer'] as String? ?? '',
        clientId: json['clientId'] as String? ?? '',
        groupsClaim: json['groupsClaim'] as String? ?? 'groups',
        idpMetadataXml: json['idpMetadataXml'] as String? ?? '',
        spEntityId: json['spEntityId'] as String? ?? '',
        emailAttribute: json['emailAttribute'] as String? ?? 'email',
        displayNameAttribute:
            json['displayNameAttribute'] as String? ?? 'displayName',
        groupsAttribute: json['groupsAttribute'] as String? ?? 'groups',
        defaultRole: json['defaultRole'] as String? ?? 'member',
        groupRoleMap: {
          for (final entry
              in (json['groupRoleMap'] as Map? ?? const {}).entries)
            '${entry.key}': '${entry.value}',
        },
        autoMember: json['autoMember'] as bool? ?? true,
        allowJit: json['allowJit'] as bool? ?? true,
        allowIdpInitiated: json['allowIdpInitiated'] as bool? ?? false,
        wantResponseSigned: json['wantResponseSigned'] as bool? ?? false,
        clockSkewSeconds: json['clockSkewSeconds'] as int? ?? 90,
      );

  /// `saml` or `oidc`.
  final String kind;

  /// Whether logins may use this connection.
  final bool enabled;

  /// Client-side hint only (has the required fields); the server re-checks.
  final bool configured;

  /// OIDC issuer.
  final String issuer;

  /// OIDC client id.
  final String clientId;

  /// OIDC groups claim.
  final String groupsClaim;

  /// SAML IdP metadata XML.
  final String idpMetadataXml;

  /// Pinned SP entity id (empty = derive from origin).
  final String spEntityId;

  /// SAML email attribute.
  final String emailAttribute;

  /// SAML display-name attribute.
  final String displayNameAttribute;

  /// SAML groups attribute.
  final String groupsAttribute;

  /// Default role wire name.
  final String defaultRole;

  /// Group → role wire names.
  final Map<String, String> groupRoleMap;

  /// Whether SSO users are auto-added to workspaces.
  final bool autoMember;

  /// Whether unknown users may be provisioned at login.
  final bool allowJit;

  /// SAML: accept IdP-initiated responses.
  final bool allowIdpInitiated;

  /// SAML: require a response-root signature too.
  final bool wantResponseSigned;

  /// SAML clock skew, seconds.
  final int clockSkewSeconds;

  /// Serializes into the `sso.saveConfig` argument shape.
  Map<String, dynamic> toSaveArgs() => {
    'kind': kind,
    'enabled': enabled,
    'issuer': issuer,
    'clientId': clientId,
    'groupsClaim': groupsClaim,
    'idpMetadataXml': idpMetadataXml,
    'spEntityId': spEntityId,
    'emailAttribute': emailAttribute,
    'displayNameAttribute': displayNameAttribute,
    'groupsAttribute': groupsAttribute,
    'defaultRole': defaultRole,
    'groupRoleMap': groupRoleMap,
    'autoMember': autoMember,
    'allowJit': allowJit,
    'allowIdpInitiated': allowIdpInitiated,
    'wantResponseSigned': wantResponseSigned,
    'clockSkewSeconds': clockSkewSeconds,
  };
}

/// Reads/mutates the server-wide SSO configuration over the RPC client.
/// Every op is server-admin gated server-side (owner of ≥1 workspace).
class RemoteSsoRepository {
  /// Creates a [RemoteSsoRepository] over [_client].
  RemoteSsoRepository(this._client);

  final RemoteRpcClient _client;

  /// The saved connection for [kind], or null when never configured.
  Future<RemoteSsoConnection?> getConfig(String kind) async {
    final result = await _client.call('sso.getConfig', {'kind': kind});
    final connection = result['connection'];
    if (connection is! Map || connection.isEmpty) {
      return null;
    }
    return RemoteSsoConnection.fromJson(connection.cast<String, dynamic>());
  }

  /// Saves [connection]; returns the persisted shape.
  Future<RemoteSsoConnection> saveConfig(RemoteSsoConnection connection) async {
    final result = await _client.call(
      'sso.saveConfig',
      connection.toSaveArgs(),
    );
    return RemoteSsoConnection.fromJson(
      (result['connection'] as Map).cast<String, dynamic>(),
    );
  }

  /// Operational status (enabled/configured flags + SCIM token presence).
  Future<Map<String, dynamic>> status() => _client.call('sso.status', const {});

  /// Tests a connection short of the browser round-trip (SAML: metadata
  /// parse + AuthnRequest build; OIDC: issuer discovery). The optional
  /// overrides test unsaved on-screen values.
  Future<Map<String, dynamic>> testConnection(
    String kind, {
    String? idpMetadataXml,
    String? issuer,
  }) => _client.call('sso.testConnection', {
    'kind': kind,
    '?idpMetadataXml': idpMetadataXml,
    '?issuer': issuer,
  });

  /// Emits the SP EntityDescriptor for the origin the user's browser uses.
  Future<String> spMetadata(String origin) async {
    final result = await _client.call('sso.spMetadata', {'origin': origin});
    return result['xml'] as String;
  }

  /// Generates a fresh SCIM bearer token — returned exactly once.
  Future<String> regenerateScimToken() async {
    final result = await _client.call('sso.scimRegenerateToken', const {});
    return result['token'] as String;
  }
}
