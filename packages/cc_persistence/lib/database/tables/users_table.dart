import 'package:drift/drift.dart';

/// Drift table for global user identities.
///
/// CROSS-WORKSPACE BY DESIGN: users are server-wide identities (like `repos`);
/// *membership* is what is workspace-scoped (`workspace_members`). Access to
/// workspace data is decided by membership, never by mere existence of a user
/// row.
@TableIndex(name: 'idx_users_handle', columns: {#handle}, unique: true)
class UsersTable extends Table {
  /// Unique user identifier.
  TextColumn get id => text()();

  /// Unique short handle (mention name).
  TextColumn get handle => text()();

  /// Display name shown across the UI.
  TextColumn get displayName => text()();

  /// Optional email address (invites work without one).
  TextColumn get email => text().nullable()();

  /// Optional avatar reference (server media ref or remote URL).
  TextColumn get avatarRef => text().nullable()();

  /// Git author name for commits made on this user's behalf.
  TextColumn get gitAuthorName => text().nullable()();

  /// Git author email for commits made on this user's behalf.
  TextColumn get gitAuthorEmail => text().nullable()();

  /// The SSO provider's immutable subject id (SAML NameID / SCIM externalId)
  /// when the user arrived via SSO/SCIM. Pinned with [ssoIssuer] so a later
  /// email change at the provider cannot silently take over the account.
  TextColumn get ssoSubject => text().nullable()();

  /// The issuer whose [ssoSubject] this is (IdP entity id or SCIM
  /// namespace).
  TextColumn get ssoIssuer => text().nullable()();

  /// When SCIM deprovisioning disabled the account (null = active). A
  /// deactivated user keeps their row (attribution is permanent) but cannot
  /// log in, holds no devices and belongs to no workspace.
  DateTimeColumn get deactivatedAt => dateTime().nullable()();

  /// When the user was provisioned.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'users';

  @override
  Set<Column> get primaryKey => {id};
}
