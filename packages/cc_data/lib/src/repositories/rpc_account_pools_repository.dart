import 'package:cc_data/src/absent_op.dart';
import 'package:cc_domain/core/domain/value_objects/account_pool.dart';
import 'package:cc_rpc/cc_rpc.dart';

/// Reads and writes account pools — which credentials a workspace (or one of
/// its agents) may spend, in what order, and how to choose between them.
///
/// One repository for both lanes. `claude-code` names the CLI adapter's account
/// directories and `harness:<providerId>` names one harness provider's stored
/// credentials; the thing being edited is identical, so the surface is too.
class RpcAccountPoolsRepository {
  /// Creates an [RpcAccountPoolsRepository] over [_client].
  RpcAccountPoolsRepository(this._client);

  final RemoteRpcClient _client;

  /// The `claude-code` lane.
  static const String claudeLane = 'claude-code';

  /// The lane for a harness provider's stored credentials.
  static String harnessLane(String providerId) => 'harness:$providerId';

  /// The pool for [lane], plus what an agent would inherit when unset.
  Future<({AccountPool pool, AccountPool? inherited})> get(
    String lane, {
    String? agentId,
  }) async {
    final data = await _client.readOr('account_pools.get', {
      'lane': lane,
      'agent_id': ?agentId,
    }, const {});
    final pool = data['pool'];
    final inherited = data['inherited'];
    return (
      pool: pool is Map<String, dynamic>
          ? AccountPool.fromJson(pool)
          : const AccountPool(),
      inherited: inherited is Map<String, dynamic>
          ? AccountPool.fromJson(inherited)
          : null,
    );
  }

  /// Writes [pool] for [lane]. A null pool clears it, which is how an agent
  /// goes back to inheriting the workspace's.
  Future<void> set(String lane, AccountPool? pool, {String? agentId}) =>
      _client.call('account_pools.set', {
        'lane': lane,
        'agent_id': ?agentId,
        'pool': ?pool?.toJson(),
      });
}
