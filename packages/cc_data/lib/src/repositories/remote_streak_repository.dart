import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads agent streaks (consecutive-activity counters) over the RPC client
/// instead of a local database.
///
/// Backs the web build and the desktop in REMOTE mode. Streaks are
/// workspace-scoped, and the workspace is bound server-side, so the reads never
/// pass a `workspace_id` — the server injects the authoritative one and JOINs
/// Agents on it. Mirrors the `streaks.*` ops + the `streaks.watchByAgent` query
/// in the host catalog. Updating a streak is driven server-side by the XpEngine
/// (reacting to `PrMerged`) and has no RPC surface.
class RemoteStreakRepository {
  /// Creates a [RemoteStreakRepository] over [_client].
  RemoteStreakRepository(this._client);

  final RemoteRpcClient _client;

  /// Live streaks for [agentId] in the bound workspace.
  Stream<List<StreakDto>> watchByAgent(String agentId) => _client
      .subscribe('streaks.watchByAgent', {'agent_id': agentId})
      .map(_streaks);

  /// Streaks for [agentId] in the bound workspace.
  Future<List<StreakDto>> getByAgent(String agentId) async {
    final data = await _client.call('streaks.getByAgent', {
      'agent_id': agentId,
    });
    return _streaks(data);
  }

  /// The current count of [streakType] for [agentId] in the bound workspace.
  Future<int> getCurrentStreak(String agentId, String streakType) async {
    final data = await _client.call('streaks.getCurrent', {
      'agent_id': agentId,
      'streak_type': streakType,
    });
    return (data['count'] as num?)?.toInt() ?? 0;
  }

  List<StreakDto> _streaks(Map<String, dynamic> data) =>
      ((data['streaks'] as List?) ?? const [])
          .whereType<Map>()
          .map((s) => StreakDto.fromJson(s.cast<String, dynamic>()))
          .toList();
}
