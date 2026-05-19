import 'package:cc_domain/cc_domain.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads agent analytics — daily stats, scorecards, the leaderboard, and
/// workspace health — over the RPC client instead of a local database.
///
/// Backs the web build and the desktop in REMOTE mode. The analytics surface is
/// workspace-scoped, and the workspace is bound server-side (via
/// `session/set_workspace`), so the agent-keyed/leaderboard/health reads never
/// pass a `workspace_id` — the server injects the authoritative one and JOINs
/// Agents on it. Mirrors the `analytics.*` ops + the `analytics.watch*` queries
/// in the host catalog. The WRITE path (rebuild/backfill maintenance
/// reconcilers) is host-side only and has no RPC surface.
class RemoteAnalyticsRepository {
  /// Creates a [RemoteAnalyticsRepository] over [_client].
  RemoteAnalyticsRepository(this._client);

  final RemoteRpcClient _client;

  /// Live daily stats for [agentId] in the bound workspace.
  Stream<List<AgentDailyStatsDto>> watchByAgent(String agentId) => _client
      .subscribe('analytics.watchByAgent', {'agent_id': agentId})
      .map(_stats);

  /// Live daily stats for [agentId] within the [start]–[end] window.
  Stream<List<AgentDailyStatsDto>> watchByAgentDateRange(
    String agentId,
    DateTime start,
    DateTime end,
  ) => _client
      .subscribe('analytics.watchByAgentDateRange', {
        'agent_id': agentId,
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      })
      .map(_stats);

  /// Live daily stats for all agents in the bound workspace within [start]–[end].
  Stream<List<AgentDailyStatsDto>> watchAllByDateRange(
    DateTime start,
    DateTime end,
  ) => _client
      .subscribe('analytics.watchAllByDateRange', {
        'start': start.toIso8601String(),
        'end': end.toIso8601String(),
      })
      .map(_stats);

  /// The scorecard for [agentId], or null when the agent has none.
  Future<AgentScorecardDto?> getAgentScorecard(String agentId) async {
    final data = await _client.call('analytics.agentScorecard', {
      'agent_id': agentId,
    });
    final card = data['scorecard'];
    return card is Map
        ? AgentScorecardDto.fromJson(card.cast<String, dynamic>())
        : null;
  }

  /// Scorecards for all agents in the bound workspace.
  Future<List<AgentScorecardDto>> getAllAgentScorecards() async {
    final data = await _client.call('analytics.allAgentScorecards', const {});
    return ((data['scorecards'] as List?) ?? const [])
        .whereType<Map>()
        .map((c) => AgentScorecardDto.fromJson(c.cast<String, dynamic>()))
        .toList();
  }

  /// The leaderboard for the bound workspace within [start]–[end].
  Future<List<LeaderboardEntryDto>> getLeaderboard(
    DateTime start,
    DateTime end,
  ) async {
    final data = await _client.call('analytics.leaderboard', {
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    });
    return ((data['entries'] as List?) ?? const [])
        .whereType<Map>()
        .map((e) => LeaderboardEntryDto.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  /// Health for the BOUND workspace (the server ignores any client arg), or null.
  Future<WorkspaceHealthDto?> getWorkspaceHealth() async {
    final data = await _client.call('analytics.workspaceHealth', const {});
    final health = data['health'];
    return health is Map
        ? WorkspaceHealthDto.fromJson(health.cast<String, dynamic>())
        : null;
  }

  /// Health for every workspace (the cross-org dashboard pulse view).
  Future<List<WorkspaceHealthDto>> getAllWorkspaceHealth() async {
    final data = await _client.call('analytics.allWorkspaceHealth', const {});
    return ((data['health'] as List?) ?? const [])
        .whereType<Map>()
        .map((h) => WorkspaceHealthDto.fromJson(h.cast<String, dynamic>()))
        .toList();
  }

  List<AgentDailyStatsDto> _stats(Map<String, dynamic> data) =>
      ((data['stats'] as List?) ?? const [])
          .whereType<Map>()
          .map((s) => AgentDailyStatsDto.fromJson(s.cast<String, dynamic>()))
          .toList();
}
