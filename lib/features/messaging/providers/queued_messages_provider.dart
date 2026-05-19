import 'dart:async';

import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// In-memory, per-conversation queue of user messages typed while an agent is
/// busy in that conversation.
///
/// When the user sends a message while an agent is still working, the message
/// is parked here instead of being dispatched immediately. As the conversation
/// returns to idle (the [conversationBusyProvider] flips busy → idle), the
/// oldest queued message is dispatched. That dispatch makes the conversation
/// busy again, so the remaining queue drains one message per agent turn — each
/// queued message gets its own turn rather than being merged.
///
/// The notifier is kept alive (not auto-disposed) so a queued message still
/// sends even if the user navigates away from the ticket before the agent
/// finishes.
class QueuedMessagesNotifier extends Notifier<List<String>> {
  /// Creates a queue bound to [key] (the workspace + conversation it serves).
  QueuedMessagesNotifier(this.key);

  /// The conversation this queue belongs to.
  final ConversationRunsKey key;

  @override
  List<String> build() {
    ref.listen<bool>(conversationBusyProvider(key), (prev, next) {
      if (prev == true && next == false) {
        _flushNext();
      }
    });
    return const [];
  }

  /// Queues [content] to be dispatched when the conversation next goes idle.
  void enqueue(String content) {
    final trimmed = content.trim();
    if (trimmed.isEmpty) {
      return;
    }
    state = [...state, trimmed];
  }

  /// Removes the queued message at [index] (e.g. the user cancels it).
  void removeAt(int index) {
    if (index < 0 || index >= state.length) {
      return;
    }
    state = [...state]..removeAt(index);
  }

  void _flushNext() {
    if (state.isEmpty) {
      return;
    }
    final next = state.first;
    state = state.sublist(1);
    unawaited(
      ref.read(messagingServiceProvider).sendAndDispatch(
            key.conversationId,
            next,
            workspaceId: key.workspaceId,
          ),
    );
  }
}

/// Per-conversation queued-message state (see [QueuedMessagesNotifier]).
final queuedMessagesProvider = NotifierProvider.family<QueuedMessagesNotifier,
    List<String>, ConversationRunsKey>(
  QueuedMessagesNotifier.new,
);
