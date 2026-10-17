import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

class ConversationDirectoryResults extends StatelessWidget {
  const ConversationDirectoryResults({
    required this.matches,
    required this.conversations,
    required this.workspaceId,
    required this.spaceId,
    required this.archived,
    required this.canWrite,
    required this.busy,
    required this.onRename,
    required this.onToggleArchive,
    super.key,
  });
  final List<MessageDto>? matches;
  final AsyncValue<List<Conversation>> conversations;
  final String? workspaceId;
  final String spaceId;
  final bool archived;
  final bool canWrite;
  final bool busy;
  final ValueChanged<Conversation> onRename;
  final ValueChanged<Conversation> onToggleArchive;

  Future<void> _open(
    BuildContext context, {
    String? conversationId,
    String? messageId,
  }) async {
    final workspace = workspaceId;
    if (workspace == null) return;
    await context.push(
      remoteSpaceLocation(
        workspaceId: workspace,
        spaceId: spaceId,
        conversationId: conversationId,
        messageId: messageId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final results = matches;
    if (results != null) {
      return ListView(
        children: [
          for (final message in results)
            CcButton(
              size: CcButtonSize.lg,
              variant: CcButtonVariant.secondary,
              onPressed: workspaceId == null
                  ? null
                  : () => _open(
                      context,
                      conversationId: message.conversationId,
                      messageId: message.id,
                    ),
              child: Text(
                message.content,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (results.isEmpty) Center(child: Text(l.mobileNoResults)),
        ],
      );
    }
    return conversations.when(
      loading: () => const Center(child: CcSpinner()),
      error: (error, _) => CcEmptyState(
        icon: AppIcons.triangleAlert,
        message: l.messagesLoadFailed,
        description: '$error',
      ),
      data: (all) => ListView(
        children: [
          for (final conversation in all.where((c) => c.isArchived == archived))
            Padding(
              padding: const EdgeInsetsDirectional.fromSTEB(12, 0, 12, 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  CcButton(
                    size: CcButtonSize.lg,
                    variant: CcButtonVariant.secondary,
                    icon: conversation.isThread
                        ? AppIcons.messageSquare
                        : AppIcons.messageCircle,
                    onPressed: workspaceId == null
                        ? null
                        : () => _open(context, conversationId: conversation.id),
                    child: Text(
                      conversation.title.isEmpty
                          ? l.thread
                          : conversation.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (canWrite)
                    Wrap(
                      spacing: 8,
                      children: [
                        CcButton(
                          size: CcButtonSize.lg,
                          variant: CcButtonVariant.secondary,
                          onPressed: busy ? null : () => onRename(conversation),
                          child: Text(l.mobileRename),
                        ),
                        CcButton(
                          size: CcButtonSize.lg,
                          variant: CcButtonVariant.secondary,
                          onPressed: busy
                              ? null
                              : () => onToggleArchive(conversation),
                          child: Text(
                            conversation.isArchived
                                ? l.mobileReopen
                                : l.mobileArchive,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          if (!all.any((c) => c.isArchived == archived))
            Center(child: Text(l.mobileNoResults)),
        ],
      ),
    );
  }
}
