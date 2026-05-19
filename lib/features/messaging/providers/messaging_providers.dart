import 'package:control_center/core/domain/entities/channel_message.dart';
import 'package:control_center/core/domain/value_objects/conversation_mode.dart';
import 'package:control_center/core/infrastructure/embedding/embedding_providers.dart';
import 'package:control_center/core/providers/provider.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/data/services/active_stream_registry.dart';
import 'package:control_center/features/messaging/data/services/agent_question_service.dart';
import 'package:control_center/features/messaging/data/services/agent_stream_processor.dart';
import 'package:control_center/features/messaging/data/services/messaging_service.dart';
import 'package:control_center/features/messaging/domain/entities/channel.dart';
import 'package:control_center/features/messaging/domain/entities/channel_participant.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final activeStreamRegistryProvider = Provider<ActiveStreamRegistry>((_) {
  return ActiveStreamRegistry();
});

/// Shared, singleton service backing agent "ask the user a question" forms.
/// The in-process MCP server and the UI resolve the same instance, so a
/// blocked agent's question and the user's answer meet on one pending map.
final agentQuestionServiceProvider = Provider<AgentQuestionService>((ref) {
  return AgentQuestionService(ref.watch(messagingRepositoryProvider));
});

class SelectedChannelNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? id) => state = id;
}

final selectedChannelIdProvider =
    NotifierProvider<SelectedChannelNotifier, String?>(
      SelectedChannelNotifier.new,
    );

final agentStreamProcessorProvider = Provider<AgentStreamProcessor>((ref) {
  return AgentStreamProcessor(
    agentDispatchService: ref.watch(agentDispatchServiceProvider),
    repo: ref.watch(messagingRepositoryProvider),
    streamRegistry: ref.watch(activeStreamRegistryProvider),
    embeddingPort: ref.watch(embeddingServiceProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
});

final messagingServiceProvider = Provider<MessagingService>((ref) {
  return MessagingService(
    ref.watch(messagingRepositoryProvider),
    agentRepo: ref.watch(agentRepositoryProvider),
    agentDispatchService: ref.watch(agentDispatchServiceProvider),
    streamRegistry: ref.watch(activeStreamRegistryProvider),
    streamProcessor: ref.watch(agentStreamProcessorProvider),
    embeddingPort: ref.watch(embeddingServiceProvider),
    eventBus: ref.watch(domainEventBusProvider),
  );
});

final channelsProvider = StreamProvider<List<Channel>>((ref) {
  return ref.watch(messagingRepositoryProvider).watchChannels();
});

/// Workspace-scoped channel stream.
final workspaceChannelsProvider =
    StreamProvider.family<List<Channel>, String>((ref, workspaceId) {
  return ref
      .watch(messagingRepositoryProvider)
      .watchChannelsByWorkspace(workspaceId);
});

final channelMessagesProvider =
    StreamProvider.autoDispose.family<List<ChannelMessage>, String>((ref, channelId) {
      return ref.watch(messagingRepositoryProvider).watchMessages(channelId);
    });

final channelTopLevelMessagesProvider =
    StreamProvider.autoDispose.family<List<ChannelMessage>, String>((ref, channelId) {
      return ref.watch(messagingRepositoryProvider).watchTopLevelMessages(channelId);
    });

final channelParticipantsProvider =
    StreamProvider.autoDispose.family<List<ChannelParticipant>, String>((ref, channelId) {
      return ref
          .watch(messagingRepositoryProvider)
          .watchParticipants(channelId);
    });

final dmChannelsProvider = Provider<List<Channel>>((ref) {
  return ref.watch(channelsProvider).maybeWhen(
    data: (channels) => channels.where((c) => c.isDm).toList(),
    orElse: () => const [],
  );
});

final groupChannelsProvider = Provider<List<Channel>>((ref) {
  return ref.watch(channelsProvider).maybeWhen(
    data: (channels) => channels.where((c) => !c.isDm).toList(),
    orElse: () => const [],
  );
});

/// Workspace-scoped DM channels.
final workspaceDmChannelsProvider =
    Provider.family<List<Channel>, String>((ref, workspaceId) {
  return ref.watch(workspaceChannelsProvider(workspaceId)).maybeWhen(
    data: (channels) => channels.where((c) => c.isDm).toList(),
    orElse: () => const [],
  );
});

/// Workspace-scoped group channels.
final workspaceGroupChannelsProvider =
    Provider.family<List<Channel>, String>((ref, workspaceId) {
  return ref.watch(workspaceChannelsProvider(workspaceId)).maybeWhen(
    data: (channels) => channels.where((c) => !c.isDm).toList(),
    orElse: () => const [],
  );
});

/// Notifier that exposes the [ConversationMode] of the currently selected
/// channel and lets the UI mutate it via [setMode].
///
/// Reactive: changing the mode in the DB triggers a re-emission from
/// [channelsProvider], which causes [build] to re-evaluate and the UI
/// to rebuild with the new mode.
class ActiveChannelModeNotifier extends Notifier<ConversationMode> {
  @override
  ConversationMode build() {
    final channelId = ref.watch(selectedChannelIdProvider);
    if (channelId == null) {
      return ConversationMode.chat;
    }
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    final channels = workspaceId != null
        ? ref.watch(workspaceChannelsProvider(workspaceId)).value ?? const []
        : ref.watch(channelsProvider).value ?? const [];
    final ch = channels.where((c) => c.id == channelId).firstOrNull;
    return ch?.mode ?? ConversationMode.chat;
  }

  /// Switches the active channel to the given [mode].
  Future<void> setMode(ConversationMode mode) async {
    final channelId = ref.read(selectedChannelIdProvider);
    if (channelId == null) {
      return;
    }
    await ref.read(messagingRepositoryProvider).setChannelMode(channelId, mode);
  }
}

/// Provides the [ActiveChannelModeNotifier] instance.
final activeChannelModeProvider =
    NotifierProvider<ActiveChannelModeNotifier, ConversationMode>(
      ActiveChannelModeNotifier.new,
    );
/// Notifier for the currently-open thread's parent message ID.
class SelectedThreadNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  /// Open a thread for the given [messageId], or close by passing null.
  @override
  set state(String? id) => super.state = id;
}

/// Currently-open thread's parent message ID (null = no thread open).
final selectedThreadMessageIdProvider =
    NotifierProvider<SelectedThreadNotifier, String?>(
      SelectedThreadNotifier.new,
    );

/// Watches thread replies for a specific parent message.
final threadMessagesProvider =
    StreamProvider.autoDispose.family<List<ChannelMessage>, String>(
      (ref, parentMessageId) =>
          ref.watch(messagingRepositoryProvider).watchThread(parentMessageId),
    );

/// Derived map: parentMessageId → {count, lastReply} for the active channel.
/// Computed from all messages so thread preview bars can show reply metadata.
typedef ThreadPreviewData = ({int count, ChannelMessage lastReply});

final threadReplyMapProvider = Provider.autoDispose
    .family<Map<String, ThreadPreviewData>, String>((ref, channelId) {
  final messages = ref.watch(channelMessagesProvider(channelId)).value ?? [];
  final map = <String, List<ChannelMessage>>{};
  for (final m in messages) {
    if (m.parentMessageId != null) {
      map.putIfAbsent(m.parentMessageId!, () => []).add(m);
    }
  }
  return {
    for (final e in map.entries)
      e.key: (
        count: e.value.length,
        lastReply: e.value.last,
      ),
  };
});
