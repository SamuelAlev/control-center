import 'package:cc_domain/core/domain/value_objects/commit_signing_key.dart';

/// The signed-in person's own commit signing key.
///
/// Self-service: every call is about the caller and nobody else, so there is
/// no workspace or user argument. One key per person per server, used for
/// every workspace and forge that supports signed commits.
abstract interface class CommitSigningKeyRepository {
  /// The caller's key, or null when they have not created one.
  Future<CommitSigningKey?> get();

  /// Creates the caller's key and returns it. The server refuses when one
  /// already exists, and refuses a companion (phone) session.
  Future<CommitSigningKey> create();

  /// Deletes the caller's key; whether there was one. Commits are unsigned
  /// from then on.
  Future<bool> delete();
}
