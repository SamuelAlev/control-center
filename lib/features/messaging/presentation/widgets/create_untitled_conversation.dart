import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Creates a conversation in [spaceId] with NO title and returns its id (null
/// when there is no active workspace).
///
/// Conversations live as editor tabs, so the editor's `[+]` new-tab menu is
/// where a new one is created; the caller opens the returned conversation as
/// a chat tab. There is deliberately no name prompt: the conversation shows
/// the untitled placeholder and the workspace's title model names it once its
/// first message lands — an empty title is what marks it as renameable by
/// that pass.
Future<String?> createUntitledConversation(
  WidgetRef ref,
  String spaceId,
) async {
  final workspaceId = ref.read(activeWorkspaceIdProvider);
  if (workspaceId == null) {
    return null;
  }
  final conv = await ref
      .read(conversationRepositoryProvider)
      .create(workspaceId: workspaceId, spaceId: spaceId, title: '');
  return conv.id;
}
