import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/value_objects/principal.dart';
import 'package:cc_domain/features/settings/domain/entities/adapter.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/settings/providers/adapter_preferences_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The adapter a channel's agents will actually run on, plus what Control
/// Center can enforce for it.
class ChannelAdapterEnforcement {
  /// Creates a [ChannelAdapterEnforcement].
  const ChannelAdapterEnforcement({
    required this.adapter,
    required this.enforcement,
  });

  /// The resolved adapter. When a channel's agents disagree, this is the one
  /// whose enforcement is weakest — see [channelAdapterEnforcementProvider].
  final Adapter adapter;

  /// What Control Center enforces on [adapter]'s transport.
  final AdapterEnforcement enforcement;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ChannelAdapterEnforcement &&
          adapter == other.adapter &&
          enforcement == other.enforcement;

  @override
  int get hashCode => Object.hash(adapter, enforcement);
}

/// The adapter enforcement in force for `channelId`, or null while the answer is
/// still unknown (participants or agents not loaded, no workspace, no adapter
/// resolvable).
///
/// ## How the adapter is resolved
///
/// Deliberately the same chain `DispatchAgentUseCase` walks, so the badge cannot
/// claim one thing while dispatch does another: the agent's own `adapterId`
/// first, then the configured default-chat adapter, then a lookup in
/// [predefinedAdapters]. A channel with no agent participant yet falls back to
/// the default too — that is the adapter the next hire will run on.
///
/// ## Why the weakest wins
///
/// A channel can hold several agents on different adapters, and a mode guarantee
/// is only as good as the runner most able to break it. Reporting the strongest
/// (or the first) would let one sandbox-only agent hide behind a fully-enforced
/// peer, which is exactly the dishonesty this whole surface exists to remove.
/// Returning null on an unresolved chain is likewise deliberate: an absent badge
/// says "unknown", never "fine".
final channelAdapterEnforcementProvider = Provider.autoDispose
    .family<ChannelAdapterEnforcement?, String>((ref, channelId) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null) {
        return null;
      }

      final participants =
          ref.watch(channelParticipantsProvider(channelId)).value ?? const [];
      final agents =
          ref.watch(workspaceAgentsProvider(workspaceId)).value ??
          const <Agent>[];
      final defaultAdapterId = ref.watch(defaultChatAdapterProvider);

      final agentIds = participants
          .where((p) => p.participantType == PrincipalType.agent)
          .map((p) => p.principalId)
          .toSet();
      final byId = {for (final a in agents) a.id: a};

      final adapterIds = <String>{
        for (final id in agentIds) ?(byId[id]?.adapterId ?? defaultAdapterId),
      };
      if (adapterIds.isEmpty && defaultAdapterId != null) {
        adapterIds.add(defaultAdapterId);
      }

      final resolved = [
        for (final id in adapterIds)
          ?predefinedAdapters.where((a) => a.id == id).firstOrNull,
      ];
      if (resolved.isEmpty) {
        return null;
      }

      resolved.sort(
        (a, b) => _enforcementRank(a).compareTo(_enforcementRank(b)),
      );
      final weakest = resolved.first;
      return ChannelAdapterEnforcement(
        adapter: weakest,
        enforcement: enforcementForAdapter(weakest),
      );
    });

/// How much of a mode guarantee an adapter can keep, as a sortable score. Lower
/// is weaker, so a plain ascending sort puts the adapter to warn about first.
int _enforcementRank(Adapter adapter) {
  final e = enforcementForAdapter(adapter);
  return (e.filtersToolSurface ? 1 : 0) +
      (e.interceptsToolCalls ? 1 : 0) +
      (e.nativeToolsInterceptable ? 1 : 0) +
      (e.observesCompletionContract ? 1 : 0);
}
