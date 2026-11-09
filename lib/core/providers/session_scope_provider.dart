import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Whose device-local caches a connected session reads and writes: the
/// connected server's identity and the user signed in on it.
///
/// One device can be paired with several servers, and one server can be
/// reached by several accounts from the same device. A cache that only means
/// something for one of those pairs — "onboarding was complete here", "this
/// was the last workspace open", that workspace's name and logo — is keyed by
/// [key], so switching server or account never inherits another pair's answer.
/// A wiped server data dir mints a new server identity, so its old caches are
/// simply never read again.
class SessionScope {
  /// Creates the scope for [userId] on the server identified by [serverId].
  SessionScope({required this.serverId, required this.userId}) {
    if (serverId.isEmpty || userId.isEmpty) {
      throw ArgumentError('A session scope needs a server id and a user id.');
    }
  }

  /// The connected server's stable identity (its descriptor's server id).
  final String serverId;

  /// The signed-in user's id on that server.
  final String userId;

  /// [base] qualified by this scope, e.g. `active_workspace_id@srv/usr`.
  String key(String base) => '$base@$serverId/$userId';

  @override
  bool operator ==(Object other) =>
      other is SessionScope &&
      other.serverId == serverId &&
      other.userId == userId;

  @override
  int get hashCode => Object.hash(serverId, userId);

  @override
  String toString() => 'SessionScope($serverId, $userId)';
}

/// The connected session's [SessionScope], fixed when the session is built.
///
/// Overridden by the composition root (`sessionOverrides`) once the server's
/// identity and the signed-in user are known. Null when either could not be
/// resolved: per-session caches then neither read nor write, so the app
/// waits for the live answer instead of guessing from another session's data.
final sessionScopeProvider = Provider<SessionScope?>((ref) => null);
