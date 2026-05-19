import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The space's checker-agent id (PRD 16 §13 — a "second pair of eyes" that
/// reviews other agents' completed runs), or null when unset. There is no
/// server subscription for this; callers `ref.invalidate` after
/// [setSpaceChecker] to refresh.
final spaceCheckerProvider = FutureProvider.autoDispose.family<String?, String>(
  (ref, spaceId) async {
    final client = ref.watch(rpcClientProvider);
    final data = await client.call('checker.get', {'space_id': spaceId});
    return data['agent_id'] as String?;
  },
);

/// Sets (or clears, when [agentId] is null) the checker agent for [spaceId]
/// via `checker.setForSpace`.
Future<void> setSpaceChecker(
  RemoteRpcClient rpcClient, {
  required String spaceId,
  required String? agentId,
}) {
  return rpcClient.call('checker.setForSpace', {
    'space_id': spaceId,
    'agent_id': ?agentId,
  });
}
