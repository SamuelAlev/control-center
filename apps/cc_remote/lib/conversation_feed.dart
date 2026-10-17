import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_remote/conversation_drafts.dart';
import 'package:cc_remote/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

export 'package:cc_remote/conversation_drafts.dart' show RemoteConversationKey;

typedef ConversationRoute = ({
  String spaceId,
  String? conversationId,
  String? messageId,
});

/// Resolves old space links, explicit conversations and message-only deep links.
/// A conflicting identity is an error, never a fallback to a different stream.
final remoteConversationProvider = FutureProvider.autoDispose
    .family<Conversation?, ConversationRoute>((ref, route) async {
      final client = ref.watch(rpcClientProvider).value;
      final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
      if (client == null || workspaceId == null) return null;
      var conversationId = route.conversationId;
      if (route.messageId case final messageId?) {
        final message = await RemoteMessagingRepository(
          client,
        ).getMessageById(workspaceId, messageId);
        if (message == null ||
            message.spaceId != route.spaceId ||
            message.conversationId == null ||
            message.conversationId!.isEmpty ||
            (conversationId != null &&
                message.conversationId != conversationId)) {
          throw StateError('Message does not belong to this conversation');
        }
        conversationId = message.conversationId;
      }
      final repository = RpcConversationRepository(client);
      if (conversationId != null) {
        final conversation = await repository.getById(
          workspaceId: workspaceId,
          conversationId: conversationId,
        );
        if (conversation == null ||
            conversation.spaceId != route.spaceId ||
            (conversation.workspaceId != null &&
                conversation.workspaceId != workspaceId)) {
          throw StateError('Conversation does not belong to this space');
        }
        return conversation;
      }
      // Read-only members can open an existing stream without a mutating ensure.
      final conversations = await repository.listForSpace(
        workspaceId: workspaceId,
        spaceId: route.spaceId,
      );
      final open = conversations
          .where((c) => !c.isThread && !c.isArchived)
          .firstOrNull;
      if (open != null) return open;
      return repository.ensure(
        workspaceId: workspaceId,
        spaceId: route.spaceId,
      );
    });

String conversationFeedKey(RemoteConversationKey key) =>
    '${key.workspaceId}/${key.spaceId}/${key.conversationId}';

final conversationFeedProvider = StreamProvider.autoDispose
    .family<({List<MessageDto> messages, bool hasMore}), RemoteConversationKey>(
      (ref, key) {
        final client = ref.watch(rpcClientProvider).value;
        final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
        final limit = ref.watch(
          remoteFeedWindowProvider(conversationFeedKey(key)),
        );
        if (client == null || workspaceId != key.workspaceId) {
          return const Stream.empty();
        }
        return RemoteMessagingRepository(client)
            .watchMessagesWindow(
              key.workspaceId,
              key.spaceId,
              key.conversationId,
              limit: limit,
            )
            .map(
              (window) => (
                messages: window.messages,
                hasMore: window.hasMore && limit < kRemoteFeedMaxWindow,
              ),
            );
      },
    );

final remoteConversationsProvider = StreamProvider.autoDispose
    .family<List<Conversation>, String>((ref, spaceId) {
      final client = ref.watch(rpcClientProvider).value;
      final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
      if (client == null || workspaceId == null) return const Stream.empty();
      return RpcConversationRepository(
        client,
      ).watchForSpace(workspaceId: workspaceId, spaceId: spaceId);
    });

final linkedMessageProvider = FutureProvider.autoDispose
    .family<MessageDto?, ({RemoteConversationKey scope, String messageId})>((
      ref,
      key,
    ) async {
      final client = ref.watch(rpcClientProvider).value;
      final workspaceId = ref.watch(activeWorkspaceIdProvider).value;
      if (client == null || workspaceId != key.scope.workspaceId) return null;
      final message = await RemoteMessagingRepository(
        client,
      ).getMessageById(key.scope.workspaceId, key.messageId);
      if (message == null ||
          message.spaceId != key.scope.spaceId ||
          message.conversationId != key.scope.conversationId) {
        throw StateError('Message does not belong to this conversation');
      }
      return message;
    });
