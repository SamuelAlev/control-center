import 'package:cc_domain/core/domain/entities/sso_connection.dart';

/// Persistence port for the server-wide SSO connection rows.
///
/// CROSS-WORKSPACE BY DESIGN: authentication is a server-level concern —
/// one IdP authenticates every workspace's humans; *membership* stays
/// workspace-scoped behind the connection's auto-member policy.
abstract class SsoConnectionRepository {
  /// The saved connection for [kind], or null when never configured.
  Future<SsoConnection?> getByKind(SsoProviderKind kind);

  /// Every saved connection.
  Future<List<SsoConnection>> getAll();

  /// Live stream of every saved connection.
  Stream<List<SsoConnection>> watchAll();

  /// Inserts or updates the connection for its kind.
  Future<void> upsert(SsoConnection connection);
}
