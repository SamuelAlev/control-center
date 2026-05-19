import 'package:cc_data/src/repositories/remote_streak_repository.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/analytics/domain/entities/streak.dart';
import 'package:cc_domain/features/analytics/domain/repositories/streak_repository.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// A [StreakRepository] backed by the RPC client — the thin-client data path.
///
/// Implements the domain interface over the host's `streaks.*` ops + the
/// `streaks.watchByAgent` subscription, mapping the [StreakDto] wire shape back
/// to [Streak]. The host is the single source of truth and owns all
/// persistence; this client never touches a database.
///
/// Each interface method takes a leading `workspaceId`, but it is NOT sent over
/// the wire: the host injects the authoritative bound workspace per session and
/// JOINs Agents on it, so the client's `workspaceId` arg is validated
/// server-side via the session binding. [updateStreak] is driven server-side by
/// the XpEngine (reacting to `PrMerged`) and throws [UnsupportedError] (never
/// reached from the UI).
class RpcStreakRepository implements StreakRepository {
  /// Creates an [RpcStreakRepository] over [client].
  RpcStreakRepository(RemoteRpcClient client)
    : _remote = RemoteStreakRepository(client);

  final RemoteStreakRepository _remote;

  static DateTime _parse(String? iso) => iso == null
      ? DateTime.fromMillisecondsSinceEpoch(0)
      : DateTime.parse(iso);

  static Streak _fromDto(StreakDto d) => Streak(
    id: d.id,
    agentId: d.agentId,
    streakType: d.streakType,
    currentCount: d.currentCount,
    bestCount: d.bestCount,
    lastDate: d.lastDate == null ? null : DateTime.parse(d.lastDate!),
    updatedAt: _parse(d.updatedAt),
  );

  @override
  Stream<List<Streak>> watchByAgent(String workspaceId, String agentId) =>
      _remote.watchByAgent(agentId).map((list) => list.map(_fromDto).toList());

  @override
  Future<List<Streak>> getByAgent(String workspaceId, String agentId) async {
    final dtos = await _remote.getByAgent(agentId);
    return dtos.map(_fromDto).toList();
  }

  @override
  Future<int> getCurrentStreak(
    String workspaceId,
    String agentId,
    String streakType,
  ) => _remote.getCurrentStreak(agentId, streakType);

  // ---- Write: driven server-side by the XpEngine, never reached from the UI.
  @override
  Future<void> updateStreak(
    String workspaceId,
    String agentId,
    String streakType, {
    required bool increment,
  }) => throw UnsupportedError(
    'analytics writes happen server-side via the XpEngine',
  );
}
