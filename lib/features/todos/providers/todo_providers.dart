import 'package:cc_domain/features/todos/domain/entities/conversation_goal.dart';
import 'package:cc_domain/features/todos/domain/entities/todo_item.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Watches the persisted todo list for a conversation (by channel id) in the
/// active workspace, streamed live over RPC (`todos.watch`).
///
/// Returns an empty stream until a workspace is active. `autoDispose` tears the
/// RPC subscription down when no widget is listening.
final conversationTodosProvider = StreamProvider.autoDispose
    .family<List<TodoItem>, String>((ref, channelId) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null || workspaceId.isEmpty) {
        return const Stream<List<TodoItem>>.empty();
      }
      return ref.watch(todoRepositoryProvider).watch(workspaceId, channelId);
    });

/// Watches the conversation's working goal (set via `/goal`), or null when none
/// is set. When present, the General pane renders the todos nested beneath it.
///
/// Returns an empty stream until a workspace is active. `autoDispose` tears the
/// RPC subscription down when no widget is listening.
final conversationGoalProvider = StreamProvider.autoDispose
    .family<ConversationGoal?, String>((ref, channelId) {
      final workspaceId = ref.watch(activeWorkspaceIdProvider);
      if (workspaceId == null || workspaceId.isEmpty) {
        return const Stream<ConversationGoal?>.empty();
      }
      return ref
          .watch(todoRepositoryProvider)
          .watchGoal(workspaceId, channelId);
    });
