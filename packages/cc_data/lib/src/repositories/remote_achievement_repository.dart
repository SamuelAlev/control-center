import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads agent achievements (unlocked badges) over the RPC client instead of a
/// local database.
///
/// Backs the web build and the desktop in REMOTE mode. Achievements are
/// workspace-scoped, and the workspace is bound server-side, so the reads never
/// pass a `workspace_id` — the server injects the authoritative one and JOINs
/// Agents on it. Mirrors the `achievements.*` ops + the
/// `achievements.watchByAgent` query in the host catalog. Unlocking a badge is
/// driven server-side by the XpEngine (reacting to `PrMerged`) and has no RPC
/// surface.
class RemoteAchievementRepository {
  /// Creates a [RemoteAchievementRepository] over [_client].
  RemoteAchievementRepository(this._client);

  final RemoteRpcClient _client;

  /// Live achievements for [agentId] in the bound workspace.
  Stream<List<AchievementDto>> watchByAgent(String agentId) => _client
      .subscribe('achievements.watchByAgent', {'agent_id': agentId})
      .map(_achievements);

  /// Achievements for [agentId] in the bound workspace.
  Future<List<AchievementDto>> getByAgent(String agentId) async {
    final data = await _client.call('achievements.getByAgent', {
      'agent_id': agentId,
    });
    return _achievements(data);
  }

  /// Whether [agentId] has unlocked [badgeKey] in the bound workspace.
  Future<bool> isUnlocked(String agentId, String badgeKey) async {
    final data = await _client.call('achievements.isUnlocked', {
      'agent_id': agentId,
      'badge_key': badgeKey,
    });
    return data['unlocked'] as bool? ?? false;
  }

  List<AchievementDto> _achievements(Map<String, dynamic> data) =>
      ((data['achievements'] as List?) ?? const [])
          .whereType<Map>()
          .map((a) => AchievementDto.fromJson(a.cast<String, dynamic>()))
          .toList();
}
