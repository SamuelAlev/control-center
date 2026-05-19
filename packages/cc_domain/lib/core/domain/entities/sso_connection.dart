import 'package:cc_domain/core/domain/value_objects/workspace_role.dart';

/// Which SSO protocol a connection speaks.
enum SsoProviderKind {
  /// SAML 2.0 service provider (Okta & friends).
  saml,

  /// OpenID Connect (Pocket ID & friends).
  oidc;

  /// Parses the persistence wire form; unknown values map to null.
  static SsoProviderKind? fromWire(String? wire) => switch (wire) {
    'saml' => saml,
    'oidc' => oidc,
    _ => null,
  };

  /// The persistence wire form.
  String get wireName => name;
}

/// The admin-configured single sign-on connection for this server
/// (CROSS-WORKSPACE BY DESIGN: authentication is server-wide; *membership*
/// stays workspace-scoped, gated by the auto-member policy).
///
/// One connection per [kind] — the SSO settings screen edits one SAML and one
/// OIDC row, and that screen is the only source: there is no environment path
/// that could write a row the screen would then disagree with.
class SsoConnection {
  /// Creates an [SsoConnection].
  const SsoConnection({
    required this.id,
    required this.kind,
    required this.enabled,
    this.issuer = '',
    this.clientId = '',
    this.groupsClaim = 'groups',
    this.idpMetadataXml = '',
    this.spEntityId = '',
    this.emailAttribute = 'email',
    this.displayNameAttribute = 'displayName',
    this.groupsAttribute = 'groups',
    this.defaultRole = WorkspaceRole.member,
    this.groupRoleMap = const {},
    this.autoMember = true,
    this.allowJit = true,
    this.allowIdpInitiated = false,
    this.wantResponseSigned = false,
    this.clockSkewSeconds = 90,
    required this.updatedAt,
  });

  /// Stable row id (the kind's slug, e.g. `saml`).
  final String id;

  /// The protocol this connection speaks.
  final SsoProviderKind kind;

  /// Whether logins may use this connection.
  final bool enabled;

  /// OIDC issuer base URL (kind == oidc).
  final String issuer;

  /// OIDC public-client id (kind == oidc).
  final String clientId;

  /// OIDC claim carrying group names (kind == oidc).
  final String groupsClaim;

  /// SAML IdP EntityDescriptor XML (kind == saml).
  final String idpMetadataXml;

  /// SAML our entityID; empty derives `<origin>/saml` (kind == saml).
  final String spEntityId;

  /// SAML attribute carrying the email.
  final String emailAttribute;

  /// SAML attribute carrying the display name.
  final String displayNameAttribute;

  /// SAML attribute carrying group names.
  final String groupsAttribute;

  /// Role granted when no group maps.
  final WorkspaceRole defaultRole;

  /// Group value → role (owner mappings are refused at save time).
  final Map<String, WorkspaceRole> groupRoleMap;

  /// Whether SSO users are auto-added to workspace memberships on first
  /// login (false = require an explicit invite per workspace).
  final bool autoMember;

  /// Whether unknown users may be provisioned at login (false rejects
  /// anyone without an existing account).
  final bool allowJit;

  /// SAML: accept unsolicited (IdP-initiated) Responses.
  final bool allowIdpInitiated;

  /// SAML: require a Response-root signature in addition to assertion
  /// signatures.
  final bool wantResponseSigned;

  /// SAML: validation clock skew allowance, in seconds.
  final int clockSkewSeconds;

  /// When this row was last saved.
  final DateTime updatedAt;

  /// Whether this connection has enough configured to serve logins.
  bool get configured => switch (kind) {
    SsoProviderKind.saml => idpMetadataXml.trim().isNotEmpty,
    SsoProviderKind.oidc =>
      issuer.trim().isNotEmpty && clientId.trim().isNotEmpty,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SsoConnection &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          kind == other.kind &&
          enabled == other.enabled &&
          issuer == other.issuer &&
          clientId == other.clientId &&
          groupsClaim == other.groupsClaim &&
          idpMetadataXml == other.idpMetadataXml &&
          spEntityId == other.spEntityId &&
          emailAttribute == other.emailAttribute &&
          displayNameAttribute == other.displayNameAttribute &&
          groupsAttribute == other.groupsAttribute &&
          defaultRole == other.defaultRole &&
          groupRoleMap == other.groupRoleMap &&
          autoMember == other.autoMember &&
          allowJit == other.allowJit &&
          allowIdpInitiated == other.allowIdpInitiated &&
          wantResponseSigned == other.wantResponseSigned &&
          clockSkewSeconds == other.clockSkewSeconds;

  @override
  int get hashCode => Object.hash(
    id,
    kind,
    enabled,
    issuer,
    clientId,
    groupsClaim,
    idpMetadataXml,
    spEntityId,
    emailAttribute,
    displayNameAttribute,
    groupsAttribute,
    defaultRole,
    Object.hashAllUnordered(groupRoleMap.entries),
    autoMember,
    allowJit,
    allowIdpInitiated,
    wantResponseSigned,
    clockSkewSeconds,
  );

  /// Returns a copy with optional overrides.
  SsoConnection copyWith({
    bool? enabled,
    String? issuer,
    String? clientId,
    String? groupsClaim,
    String? idpMetadataXml,
    String? spEntityId,
    String? emailAttribute,
    String? displayNameAttribute,
    String? groupsAttribute,
    WorkspaceRole? defaultRole,
    Map<String, WorkspaceRole>? groupRoleMap,
    bool? autoMember,
    bool? allowJit,
    bool? allowIdpInitiated,
    bool? wantResponseSigned,
    int? clockSkewSeconds,
    DateTime? updatedAt,
  }) {
    return SsoConnection(
      id: id,
      kind: kind,
      enabled: enabled ?? this.enabled,
      issuer: issuer ?? this.issuer,
      clientId: clientId ?? this.clientId,
      groupsClaim: groupsClaim ?? this.groupsClaim,
      idpMetadataXml: idpMetadataXml ?? this.idpMetadataXml,
      spEntityId: spEntityId ?? this.spEntityId,
      emailAttribute: emailAttribute ?? this.emailAttribute,
      displayNameAttribute: displayNameAttribute ?? this.displayNameAttribute,
      groupsAttribute: groupsAttribute ?? this.groupsAttribute,
      defaultRole: defaultRole ?? this.defaultRole,
      groupRoleMap: groupRoleMap ?? this.groupRoleMap,
      autoMember: autoMember ?? this.autoMember,
      allowJit: allowJit ?? this.allowJit,
      allowIdpInitiated: allowIdpInitiated ?? this.allowIdpInitiated,
      wantResponseSigned: wantResponseSigned ?? this.wantResponseSigned,
      clockSkewSeconds: clockSkewSeconds ?? this.clockSkewSeconds,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
