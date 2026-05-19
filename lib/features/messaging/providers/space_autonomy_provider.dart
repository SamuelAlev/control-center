import 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:cc_domain/features/messaging/domain/value_objects/autonomy_level.dart'
    show AutonomyLevel;

/// Per-agent autonomy levels for a space, keyed by agent id. An agent with
/// no entry (or an explicit `null` level) uses the server's default.
final spaceAutonomyProvider = StreamProvider.autoDispose
    .family<Map<String, AutonomyLevel?>, String>((ref, spaceId) {
      final client = ref.watch(rpcClientProvider);
      return client
          .subscribe('autonomy.watchForSpace', {'space_id': spaceId})
          .map((data) {
            final raw = data['autonomy'];
            if (raw is! List) {
              return const <String, AutonomyLevel?>{};
            }
            return {
              for (final e in raw)
                if (e is Map)
                  (e['agent_id'] as String? ?? ''): AutonomyLevel.tryFromWire(
                    e['level'] as String?,
                  ),
            };
          });
    });

/// Sets (or clears, when [level] is null) [agentId]'s autonomy level in
/// [spaceId] via `autonomy.setForSpace`.
Future<void> setSpaceAutonomy(
  RemoteRpcClient rpcClient, {
  required String spaceId,
  required String agentId,
  required AutonomyLevel? level,
}) {
  return rpcClient.call('autonomy.setForSpace', {
    'space_id': spaceId,
    'agent_id': agentId,
    'level': level?.wire,
  });
}
