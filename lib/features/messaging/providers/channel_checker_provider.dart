import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The channel's checker-agent id (PRD 16 §13 — a "second pair of eyes" that
/// reviews other agents' completed runs), or null when unset. There is no
/// server subscription for this; callers `ref.invalidate` after
/// [setChannelChecker] to refresh.
final channelCheckerProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, channelId) async {
      final client = ref.watch(rpcClientProvider);
      final data = await client.call('checker.get', {'channel_id': channelId});
      return data['agent_id'] as String?;
    });

/// Sets (or clears, when [agentId] is null) the checker agent for [channelId]
/// via `checker.setForChannel`.
Future<void> setChannelChecker(
  RemoteRpcClient rpcClient, {
  required String channelId,
  required String? agentId,
}) {
  return rpcClient.call('checker.setForChannel', {
    'channel_id': channelId,
    'agent_id': ?agentId,
  });
}
