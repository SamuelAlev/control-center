import 'dart:collection';

import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/conversation_peer_asks_repository.dart';
import 'package:cc_domain/features/dispatch/domain/repositories/conversation_wakes_repository.dart';
import 'package:collection/collection.dart' show ListEquality;
import 'package:control_center/di/conversation_work_providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A conversation in a workspace: the key of the per-conversation watches.
typedef WorkConversationKey = ({String workspaceId, String conversationId});

/// The conversation's pending and held wakes, earliest due first
/// (`wakes.watchForConversation`).
final conversationWakesProvider = StreamProvider.autoDispose
    .family<List<WakeView>, WorkConversationKey>(
      (ref, key) => ref
          .watch(conversationWakesRepositoryProvider)
          .watchForConversation(key.workspaceId, key.conversationId),
    );

/// The conversation's questions to other agents, newest first
/// (`peerAsks.watchForConversation`).
final conversationPeerAsksProvider = StreamProvider.autoDispose
    .family<List<PeerAskView>, WorkConversationKey>(
      (ref, key) => ref
          .watch(conversationPeerAsksRepositoryProvider)
          .watchForConversation(key.workspaceId, key.conversationId),
    );

/// The steering cards a person's Stop held in the conversation, in their
/// queue order. Derived from the feed window the trail renders, like the
/// queued strip, so the two never disagree; equal snapshots compare equal.
final heldSteeringProvider = Provider.autoDispose
    .family<List<Message>, ConversationRef>((ref, key) {
      final window = ref.watch(spaceFeedWindowedProvider(key)).asData?.value;
      final held =
          window?.messages.where((m) => m.isSteeringHeld).toList() ??
          const <Message>[];
      if (held.isEmpty) {
        return const <Message>[];
      }
      held.sort((a, b) => a.steerOrder.compareTo(b.steerOrder));
      return _MessageList(held);
    });

/// An agent's display name in a workspace, or null while the roster loads
/// or when the agent is gone. Names are data: render them as plain text.
final workAgentNameProvider = Provider.autoDispose
    .family<String?, ({String workspaceId, String agentId})>((ref, key) {
      final agents = ref
          .watch(workspaceAgentsProvider(key.workspaceId))
          .asData
          ?.value;
      for (final a in agents ?? const <Agent>[]) {
        if (a.id == key.agentId) {
          return a.name;
        }
      }
      return null;
    });

final class _MessageList extends UnmodifiableListView<Message> {
  _MessageList(List<Message> super.source) : _messages = source;

  final List<Message> _messages;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _MessageList &&
          const ListEquality<Message>().equals(_messages, other._messages);

  @override
  int get hashCode => const ListEquality<Message>().hash(_messages);
}
