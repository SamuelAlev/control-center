import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:control_center/features/messaging/presentation/utils/conversation_display_name.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

/// Searchable spaces and conversations in the current workspace.
class _SpaceCommandSource implements CommandSource {
  @override
  String get id => 'spaces';

  @override
  String get category => 'Spaces';

  @override
  bool get isDynamic => true;

  @override
  List<CommandItem> buildItems(BuildContext context, WidgetRef ref) {
    final workspaceId = ref.watch(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return const [];
    }

    final router = GoRouter.of(context);
    final l10n = AppLocalizations.of(context);
    final spaces = ref.watch(workspaceVisibleSpacesProvider(workspaceId));
    final items = <CommandItem>[];
    for (final space in spaces) {
      if (space.workspaceId != workspaceId ||
          space.isArchived ||
          space.pipelineRunId != null) {
        continue;
      }

      final spaceId = space.id;
      final destination = spaceRoute(workspaceId, spaceId);
      items.add(
        CommandItem(
          id: 'space:$workspaceId:$spaceId',
          label: space.name.isEmpty ? l10n.spaceLabel : space.name,
          icon: AppIcons.messagesSquare,
          category: l10n.spaces,
          onExecute: () => router.go(destination),
        ),
      );

      // Watch every eligible space, not only the selected one: conversations
      // added while the palette is open must become searchable immediately.
      final conversations =
          ref.watch(spaceConversationsProvider(spaceId)).value ??
          const <Conversation>[];
      for (final conversation in conversations) {
        if (conversation.workspaceId != workspaceId ||
            conversation.spaceId != spaceId ||
            conversation.isArchived) {
          continue;
        }
        final conversationId = conversation.id;
        final conversationDestination = spaceRoute(
          workspaceId,
          spaceId,
          tab: conversationTabKey(conversationId),
        );
        items.add(
          CommandItem(
            id: 'conversation:$workspaceId:$spaceId:$conversationId',
            label: conversationDisplayName(conversation, l10n),
            description: space.name.isEmpty ? l10n.spaceLabel : space.name,
            icon: AppIcons.messageSquareText,
            category: l10n.navConversations,
            onExecute: () => router.go(conversationDestination),
          ),
        );
      }
    }
    return items;
  }
}

/// Command palette source for workspace-visible spaces and their conversations.
final spaceCommandSourceProvider = Provider<CommandSource>(
  (_) => _SpaceCommandSource(),
);
