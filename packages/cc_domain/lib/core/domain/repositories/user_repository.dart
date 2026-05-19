import 'package:cc_domain/core/domain/entities/user.dart';

/// Persistence port for global user identities.
///
/// Users are global (identity is server-wide, membership is workspace-scoped)
/// so reads here legitimately span workspaces; access to *other* users'
/// details is limited to co-members at the query layer above.
abstract class UserRepository {
  /// All users on this server, oldest first.
  Future<List<User>> getAll();

  /// Live stream of all users.
  Stream<List<User>> watchAll();

  /// The user with [id], or null.
  Future<User?> getById(String id);

  /// The user with the unique [handle], or null.
  Future<User?> getByHandle(String handle);

  /// The user with [email], or null. Used for OIDC JIT matching.
  Future<User?> getByEmail(String email);

  /// The user whose SSO subject is ([issuer], [subject]), or null. The
  /// FIRST lookup of an SSO login (before email) so a reused or changed
  /// email cannot take over a pinned account.
  Future<User?> getBySsoSubject(String issuer, String subject);

  /// Inserts or updates [user].
  Future<void> upsert(User user);

  /// Number of users on this server (0 means the owner bootstrap must run).
  Future<int> count();
}
