import 'package:cc_domain/core/domain/entities/user.dart' show normalizeEmail;
import 'package:cc_persistence/database/global/global_database.dart';
import 'package:cc_persistence/database/tables/users_table.dart';
import 'package:drift/drift.dart';

part 'user_dao.g.dart';

/// Data access object for [UsersTable].
///
/// Users are global identities — CROSS-WORKSPACE BY DESIGN. Workspace access
/// is decided by `workspace_members`, never by these rows; the queries here
/// exist for identity resolution (sessions, authorship display) and the
/// bootstrap.
@DriftAccessor(tables: [UsersTable])
class UserDao extends DatabaseAccessor<GlobalDatabase> with _$UserDaoMixin {
  /// Creates a [UserDao] for the given database.
  UserDao(super.attachedDatabase);

  /// Every user, oldest first.
  ///
  /// CROSS-WORKSPACE BY DESIGN — identity is server-wide; membership is the
  /// workspace boundary.
  Future<List<UsersTableData>> getAll() => (select(
    usersTable,
  )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).get();

  /// Watches every user, oldest first.
  ///
  /// CROSS-WORKSPACE BY DESIGN — see [getAll].
  Stream<List<UsersTableData>> watchAll() => (select(
    usersTable,
  )..orderBy([(t) => OrderingTerm.asc(t.createdAt)])).watch();

  /// Returns a user by [id], or null.
  Future<UsersTableData?> getById(String id) =>
      (select(usersTable)..where((t) => t.id.equals(id))).getSingleOrNull();

  /// Returns a user by unique [handle], or null.
  Future<UsersTableData?> getByHandle(String handle) => (select(
    usersTable,
  )..where((t) => t.handle.equals(handle))).getSingleOrNull();

  /// Every user whose VOUCHED address is [email] in any case, oldest first.
  /// One account, or none, is the answer an identity lookup may act on.
  Future<List<UsersTableData>> getAllByVerifiedEmail(String email) =>
      (select(usersTable)
            ..where(
              (t) => _sameAddress(t, email) & t.emailVerified.equals(true),
            )
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  /// Every user holding [email] in any case, vouched or not, oldest first.
  Future<List<UsersTableData>> getAllByEmail(String email) =>
      (select(usersTable)
            ..where((t) => _sameAddress(t, email))
            ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
          .get();

  // The stored side is normalized on write (`User`), so only the query side
  // needs it.
  Expression<bool> _sameAddress($UsersTableTable t, String email) =>
      t.email.equals(normalizeEmail(email));

  /// Returns the user whose SSO subject is ([issuer], [subject]), or null.
  ///
  /// CROSS-WORKSPACE BY DESIGN — SSO subjects are server-wide identity.
  /// This is the FIRST lookup of SSO login (before email): a match pins the
  /// account to the provider's immutable id, so a reused or changed email
  /// cannot take it over.
  Future<UsersTableData?> getBySsoSubject(String issuer, String subject) =>
      (select(usersTable)..where(
            (t) => t.ssoIssuer.equals(issuer) & t.ssoSubject.equals(subject),
          ))
          .getSingleOrNull();

  /// Inserts or updates a user row unless another row holds its handle.
  ///
  /// The check and the write are one transaction on this connection, so two
  /// writers cannot both pass the check; the unique index on `handle` is the
  /// backstop (a write that slips past it fails loudly). Returns false when
  /// the handle is taken, with nothing written.
  Future<bool> upsert(UsersTableCompanion entry) => transaction(() async {
    final holder = await getByHandle(entry.handle.value);
    if (holder != null && holder.id != entry.id.value) {
      return false;
    }
    await into(usersTable).insertOnConflictUpdate(entry);
    return true;
  });

  /// Inserts a NEW user row under the first free handle of [candidates], in
  /// one transaction, and returns the handle used. [entry]'s own handle is
  /// ignored; [candidates] must be endless or end with a free name.
  Future<String> insertWithFreeHandle(
    UsersTableCompanion entry,
    Iterable<String> candidates,
  ) => transaction(() async {
    for (final candidate in candidates) {
      if (await getByHandle(candidate) == null) {
        await into(usersTable).insert(entry.copyWith(handle: Value(candidate)));
        return candidate;
      }
    }
    throw StateError('no free handle among the candidates');
  });

  /// Number of users on this server (0 → the owner bootstrap must run).
  Future<int> count() async {
    final c = countAll();
    final row = await (selectOnly(usersTable)..addColumns([c])).getSingle();
    return row.read(c) ?? 0;
  }
}
