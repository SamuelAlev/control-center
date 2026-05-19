import 'package:cc_domain/features/presence/domain/value_objects/participant_presence.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Client adapter for the ephemeral presence lane (PRD 16 §1).
///
/// Publishes this user's own awareness (via `presence.update` — the server
/// binds it to the session identity) and watches the workspace roster
/// (via `presence.watch`). Nothing here touches storage: presence is
/// in-memory on the server and expires ~30s after the last update.
class RpcPresenceRepository {
  /// Creates a repository over the given RPC client.
  RpcPresenceRepository(this._client);

  final RemoteRpcClient _client;

  /// Publishes this user's presence for [workspaceId]. [presence] is the
  /// compact wire map (`a`/`l`/`ty`/`sp`/`cl` keys — see
  /// [ParticipantPresence]).
  Future<void> publish({
    required String workspaceId,
    required Map<String, dynamic> presence,
  }) => _client.call('presence.update', {
    'workspace_id': workspaceId,
    'presence': presence,
  });

  /// The live roster for [workspaceId]. [tier] `'summary'` asks the server
  /// for the phone-grade coalescing budget.
  Stream<List<ParticipantPresence>> watchRoster({
    required String workspaceId,
    String tier = 'full',
  }) => _client
      .subscribe('presence.watch', {'workspace_id': workspaceId, 'tier': tier})
      .map((snapshot) {
        final raw = snapshot['participants'];
        if (raw is! List) {
          return const <ParticipantPresence>[];
        }
        final roster = <ParticipantPresence>[];
        for (final entry in raw) {
          if (entry is! Map) {
            continue;
          }
          try {
            roster.add(
              ParticipantPresence.fromWire(entry.cast<String, dynamic>()),
            );
          } on FormatException {
            // Skip malformed entries rather than dropping the roster.
          }
        }
        return roster;
      });
}
