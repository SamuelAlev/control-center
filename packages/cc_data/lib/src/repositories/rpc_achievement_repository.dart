import 'package:cc_data/src/repositories/remote_achievement_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/analytics/domain/entities/achievement.dart';
import 'package:cc_domain/features/analytics/domain/repositories/achievement_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// An [AchievementRepository] backed by the RPC client — the thin-client data
/// path.
///
/// Implements the domain interface over the host's `achievements.*` ops + the
/// `achievements.watchByAgent` subscription, mapping the [AchievementDto] wire
/// shape back to [Achievement]. The host is the single source of truth and owns
/// all persistence; this client never touches a database.
///
/// The interface method takes a leading `workspaceId`, but it is NOT sent over
/// the wire: the host injects the authoritative bound workspace per session and
/// JOINs Agents on it, so the client's `workspaceId` arg is validated
/// server-side via the session binding. [unlock] is driven server-side by the
/// XpEngine (reacting to `PrMerged`) and throws [UnsupportedError] (never
/// reached from the UI).
class RpcAchievementRepository implements AchievementRepository {
  /// Creates an [RpcAchievementRepository] over [client].
  RpcAchievementRepository(RemoteRpcClient client)
    : _remote = RemoteAchievementRepository(client);

  final RemoteAchievementRepository _remote;

  static DateTime _parse(String? iso) => iso == null
      ? DateTime.fromMillisecondsSinceEpoch(0)
      : DateTime.parse(iso);

  static Achievement _fromDto(AchievementDto d) => Achievement(
    id: d.id,
    agentId: d.agentId,
    badgeKey: d.badgeKey,
    unlockedAt: _parse(d.unlockedAt),
    metadata: d.metadata,
  );

  @override
  Stream<List<Achievement>> watchByAgent(String workspaceId, String agentId) =>
      _remote.watchByAgent(agentId).map((list) => list.map(_fromDto).toList());

  @override
  Future<List<Achievement>> getByAgent(
    String workspaceId,
    String agentId,
  ) async {
    final dtos = await _remote.getByAgent(agentId);
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<bool> isUnlocked(
    String workspaceId,
    String agentId,
    String badgeKey,
  ) => _remote.isUnlocked(agentId, badgeKey);

  // ---- Write: driven server-side by the XpEngine, never reached from the UI.
  @override
  Future<void> unlock(
    String workspaceId,
    String agentId,
    String badgeKey, {
    String? metadata,
  }) => throw UnsupportedError(
    'analytics writes happen server-side via the XpEngine',
  );
}
