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

  /// When this user finished first-run setup (null = never has).
  ///
  /// A column on the IDENTITY rather than a row in `user_preferences`, because
  /// the preference lane carries a one-time promotion pass that seeds the
  /// server from whatever the first device happens to hold locally. This flag
  /// used to ride that lane, and a stale device-local `true` was promoted onto
  /// a brand-new account: the onboarding gate then read "has been set up
  /// before", so a person who had never onboarded was sent to the re-auth
  /// screen — which offers a sign-in and none of the setup they actually
  /// needed. Nothing can promote a column.
  ///
  /// Monotonic by convention: it records that setup happened, never whether
  /// the setup is currently intact (a lapsed forge credential is a different
  /// question, and the one this flag exists to disambiguate).
  DateTimeColumn get onboardingFinishedAt => dateTime().nullable()();

  /// When the user was provisioned.
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();

  @override
  String get tableName => 'users';

  @override
  Set<Column> get primaryKey => {id};
}
