import 'package:drift/drift.dart';

/// Drift table for the server-wide SSO connection rows.
///
/// CROSS-WORKSPACE BY DESIGN: authentication is server-wide — one IdP
/// authenticates every workspace's humans and *membership* stays
/// workspace-scoped behind the connection's auto-member policy (the PRD 14
/// §13 over-grant trap). One row per protocol kind (`saml`, `oidc`); the id
/// is the kind's slug so future multi-connection support can add rows
/// without a migration.
class SsoConnectionsTable extends Table {
  /// Row id: the kind slug (`saml` / `oidc`).
  TextColumn get id => text()();

  /// Protocol kind (`saml` / `oidc`).
  TextColumn get kind => text()();

  /// Whether logins may use this connection.
  BoolColumn get enabled => boolean().withDefault(const Constant(false))();

  /// OIDC issuer base URL.
  TextColumn get issuer => text().withDefault(const Constant(''))();

  /// OIDC public-client id.
  TextColumn get clientId => text().withDefault(const Constant(''))();

  /// OIDC claim carrying group names.
  TextColumn get groupsClaim => text().withDefault(const Constant('groups'))();

  /// SAML IdP EntityDescriptor XML.
  TextColumn get idpMetadataXml => text().withDefault(const Constant(''))();

  /// SAML our entityID; empty derives `<origin>/saml`.
  TextColumn get spEntityId => text().withDefault(const Constant(''))();

  /// SAML attribute carrying the email.
  TextColumn get emailAttribute => text().withDefault(const Constant('email'))();

  /// SAML attribute carrying the display name.
  TextColumn get displayNameAttribute
  => text().withDefault(const Constant('displayName'))();

  /// SAML attribute carrying group names.
  TextColumn get groupsAttribute => text().withDefault(const Constant('groups'))();

  /// Role granted when no group maps (WorkspaceRole wire name).
  TextColumn get defaultRole => text().withDefault(const Constant('member'))();

  /// Group value → role, as a JSON object of wire names.
  TextColumn get groupRoleMap => text().withDefault(const Constant('{}'))();

  /// Whether SSO users are auto-added to workspace memberships (`all`/`none`).
  BoolColumn get autoMember => boolean().withDefault(const Constant(true))();

  /// Whether unknown users may be provisioned at login.
  BoolColumn get allowJit => boolean().withDefault(const Constant(true))();

  /// SAML: accept unsolicited (IdP-initiated) Responses.
  BoolColumn get allowIdpInitiated
  => boolean().withDefault(const Constant(false))();

  /// SAML: require a Response-root signature too.
  BoolColumn get wantResponseSigned
  => boolean().withDefault(const Constant(false))();

  /// SAML: validation clock skew, seconds.
  IntColumn get clockSkewSeconds => integer().withDefault(const Constant(90))();

  /// When this row was last saved.
  DateTimeColumn get updatedAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'sso_connections';

  @override
  Set<Column> get primaryKey => {id};
}
