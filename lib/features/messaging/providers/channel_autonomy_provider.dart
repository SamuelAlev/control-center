import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Graduated per-channel, per-agent autonomy (PRD 16 §12): propose-only →
/// act-with-approval → act-freely. `null` (no row / explicit clear) means
/// "default" — the server's own fallback policy.
enum AutonomyLevel {
  /// Gated tools are denied; the agent can only propose actions.
  proposeOnly('proposeOnly'),

  /// The default: risky actions hit a fail-closed approval gate.
  actWithApproval('actWithApproval'),

  /// Actions are pre-approved.
  actFreely('actFreely');

  const AutonomyLevel(this.wire);

  /// Wire name sent to `autonomy.setForChannel` / received from
  /// `autonomy.watchForChannel`.
  final String wire;

  /// Parses a wire name; null for `null`/unknown (falls back to "default").
  static AutonomyLevel? fromWire(String? value) {
    for (final level in values) {
      if (level.wire == value) {
        return level;
      }
    }
    return null;
  }
}

/// Per-agent autonomy levels for a channel, keyed by agent id. An agent with
/// no entry (or an explicit `null` level) uses the server's default.
final channelAutonomyProvider = StreamProvider.autoDispose
    .family<Map<String, AutonomyLevel?>, String>((ref, channelId) {
      final client = ref.watch(rpcClientProvider);
      return client
          .subscribe('autonomy.watchForChannel', {'channel_id': channelId})
          .map((data) {
            final raw = data['autonomy'];
            if (raw is! List) {
              return const <String, AutonomyLevel?>{};
            }
            return {
              for (final e in raw)
                if (e is Map)
                  (e['agent_id'] as String? ?? ''): AutonomyLevel.fromWire(
                    e['level'] as String?,
                  ),
            };
          });
    });

/// Sets (or clears, when [level] is null) [agentId]'s autonomy level in
/// [channelId] via `autonomy.setForChannel`.
Future<void> setChannelAutonomy(
  RemoteRpcClient rpcClient, {
  required String channelId,
  required String agentId,
  required AutonomyLevel? level,
}) {
  return rpcClient.call('autonomy.setForChannel', {
    'channel_id': channelId,
    'agent_id': agentId,
    'level': level?.wire,
  });
}
