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

  /// Returns a user by [email], or null. Used for OIDC JIT matching.
  Future<UsersTableData?> getByEmail(String email) => (select(
    usersTable,
  )..where((t) => t.email.equals(email))).getSingleOrNull();

  /// Inserts or updates a user row.
  Future<void> upsert(UsersTableCompanion entry) =>
      into(usersTable).insertOnConflictUpdate(entry);

  /// Number of users on this server (0 → the owner bootstrap must run).
  Future<int> count() async {
    final c = countAll();
    final row = await (selectOnly(usersTable)..addColumns([c])).getSingle();
    return row.read(c) ?? 0;
  }
}
