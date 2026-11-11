import 'package:cc_domain/core/domain/entities/user.dart';
import 'package:cc_domain/core/domain/value_objects/username.dart';

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

  /// The user whose username is [handle] (a stored, lowercase username), or
  /// null.
  Future<User?> getByHandle(String handle);

  /// The oldest user whose VOUCHED address ([User.emailVerified]) is
  /// [email], or null. The only email lookup that may identify someone: an
  /// SSO login or a SCIM push matches by email through this alone.
  Future<User?> getByVerifiedEmail(String email);

  /// Every user holding [email], vouched or not, oldest first.
  Future<List<User>> getAllByEmail(String email);

  /// The user whose SSO subject is ([issuer], [subject]), or null. The
  /// FIRST lookup of an SSO login (before email) so a reused or changed
  /// email cannot take over a pinned account.
  Future<User?> getBySsoSubject(String issuer, String subject);

  /// Inserts or updates [user].
  ///
  /// Usernames are unique: the check and the write are one transaction,
  /// backed by a unique index, and a name another user holds throws
  /// [UsernameRefusedException] with [UsernameRefusal.taken].
  Future<void> upsert(User user);

  /// Inserts the new [user] under the first free name of
  /// [Username.candidates] starting at its handle, in one transaction, and
  /// returns the stored row. The one allocator for derived names (first
  /// owner, invite, SSO, SCIM); a name a person chose goes through [upsert]
  /// and is refused instead.
  Future<User> insertWithFreeHandle(User user);

  /// Number of users on this server (0 means the owner bootstrap must run).
  Future<int> count();
}
