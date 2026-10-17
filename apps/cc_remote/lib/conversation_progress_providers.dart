import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/dispatch/domain/context/context_inspection.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_token_totals.dart';
import 'package:cc_domain/features/todos/domain/entities/conversation_goal.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:cc_remote/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every progress subscription names all three identities; a route may not
/// substitute a space's standing conversation for the focused conversation.
typedef ProgressScope = ({
  String workspaceId,
  String spaceId,
  String conversationId,
});

final progressConversationProvider = FutureProvider.autoDispose
    .family<Conversation?, ProgressScope>((ref, scope) async {
      final active = ref.watch(activeWorkspaceIdProvider).value;
      final client = ref.watch(rpcClientProvider).value;
      if (active != scope.workspaceId || client == null) return null;
      final conversation = await RpcConversationRepository(client).getById(
        workspaceId: scope.workspaceId,
        conversationId: scope.conversationId,
      );
      return conversation?.spaceId == scope.spaceId &&
              (conversation?.workspaceId == null ||
                  conversation!.workspaceId == scope.workspaceId)
          ? conversation
          : null;
    });

final progressTodosProvider = StreamProvider.autoDispose
    .family<List<TodoItem>, ProgressScope>((ref, scope) async* {
      final conversation = await ref.watch(
        progressConversationProvider(scope).future,
      );
      final client = ref.watch(rpcClientProvider).value;
      if (conversation == null || client == null) return;
      yield* RpcTodoRepository(client)
          .watch(scope.workspaceId, scope.conversationId)
          .map(
            (items) => items
                .where(
                  (item) =>
                      item.workspaceId == scope.workspaceId &&
                      item.conversationId == scope.conversationId,
                )
                .toList(),
          );
    });

final progressGoalProvider = StreamProvider.autoDispose
    .family<ConversationGoal?, ProgressScope>((ref, scope) async* {
      final conversation = await ref.watch(
        progressConversationProvider(scope).future,
      );
      final client = ref.watch(rpcClientProvider).value;
      if (conversation == null || client == null) return;
      yield* RpcTodoRepository(client)
          .watchGoal(scope.workspaceId, scope.conversationId)
          .map(
            (goal) =>
                goal?.workspaceId == scope.workspaceId &&
                    goal?.conversationId == scope.conversationId
                ? goal
                : null,
          );
    });

final progressRunsProvider = StreamProvider.autoDispose
    .family<List<AgentRunLogDto>, ProgressScope>((ref, scope) async* {
      final conversation = await ref.watch(
        progressConversationProvider(scope).future,
      );
      final client = ref.watch(rpcClientProvider).value;
      if (conversation == null || client == null) return;
      yield* RemoteAgentRunLogRepository(client)
          .watchByConversation(scope.workspaceId, scope.conversationId)
          .map(
            (runs) => runs
                .where(
                  (run) =>
                      (run.conversationId == null ||
                          run.conversationId == scope.conversationId) &&
                      (run.workspaceId == null ||
                          run.workspaceId == scope.workspaceId) &&
                      (run.spaceId == null || run.spaceId == scope.spaceId),
                )
                .toList(),
          );
    });

final progressTokensProvider = StreamProvider.autoDispose
    .family<ConversationTokenTotals, ProgressScope>((ref, scope) async* {
      final conversation = await ref.watch(
        progressConversationProvider(scope).future,
      );
      final client = ref.watch(rpcClientProvider).value;
      if (conversation == null || client == null) return;
      yield* RpcMessagingRepository(client).watchConversationTokens(
        scope.workspaceId,
        scope.spaceId,
        scope.conversationId,
      );
    });

/// Summary-only inspection never transfers prompt bodies. Request verbatim
/// content separately and only when the operator opens a segment.
final progressInspectionProvider = FutureProvider.autoDispose
    .family<
      ContextInspection,
      ({ProgressScope scope, String agentId, bool includeContent})
    >((ref, args) async {
      final scope = args.scope;
      final conversation = await ref.watch(
        progressConversationProvider(scope).future,
      );
      final client = ref.watch(rpcClientProvider).value;
      if (conversation == null || client == null) {
        throw StateError('Conversation no longer available');
      }
      final result = await RemoteContextRepository(client).inspect(
        workspaceId: scope.workspaceId,
        spaceId: scope.spaceId,
        conversationId: scope.conversationId,
        agentId: args.agentId,
        includeContent: args.includeContent,
      );
      if (result.workspaceId != scope.workspaceId ||
          result.spaceId != scope.spaceId ||
          result.agentId != args.agentId) {
        throw StateError(
          'Context inspection belongs to another conversation scope',
        );
      }
      return result;
    });

/// Small server-side window for outputs; never subscribes to the full transcript.
final progressRecentMessagesProvider = StreamProvider.autoDispose
    .family<({List<MessageDto> messages, bool hasMore}), ProgressScope>((
      ref,
      scope,
    ) async* {
      final conversation = await ref.watch(
        progressConversationProvider(scope).future,
      );
      final client = ref.watch(rpcClientProvider).value;
      if (conversation == null || client == null) return;
      yield* RemoteMessagingRepository(client)
          .watchMessagesWindow(
            scope.workspaceId,
            scope.spaceId,
            scope.conversationId,
            limit: 40,
          )
          .map(
            (window) => (
              messages: window.messages
                  .where(
                    (m) =>
                        (m.conversationId == null ||
                            m.conversationId == scope.conversationId) &&
                        (m.spaceId == null || m.spaceId == scope.spaceId),
                  )
                  .toList(),
              hasMore: window.hasMore,
            ),
          );
    });
