import 'package:cc_domain/features/messaging/domain/entities/conversation.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/conversation_kind.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A slim strip of conversation chips above a chat pane: `main` + every open
/// parenthesis, plus a "new parenthesis" affordance. A parenthesis is a
/// parallel side conversation that shares the channel's worktree but keeps its
/// own history + agent sessions.
///
/// Renders nothing when the channel has only its `main` conversation (solo-
/// first: no chrome until a second conversation exists).
///
/// [onSelect] opens/focuses a conversation (the host maps it to an editor tab);
/// when null, selecting a chip is a no-op beyond visual state. Creating a
/// parenthesis calls the server, then selects it.
class ConversationSwitcher extends ConsumerWidget {
  /// Creates a [ConversationSwitcher].
  const ConversationSwitcher({
    super.key,
    required this.channelId,
    required this.activeConversationId,
    this.onSelect,
  });

  /// The channel whose conversations are shown.
  final String channelId;

  /// The currently-shown conversation id (highlighted).
  final String activeConversationId;

  /// Called when the user picks a conversation.
  final void Function(String conversationId)? onSelect;

  Future<void> _newParenthesis(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    final controller = TextEditingController();
    final title = await showCcDialog<String>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.newParenthesis,
        content: CcTextField(
          controller: controller,
          autofocus: true,
          hintText: l10n.parenthesisTitleHint,
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          CcButton(
            variant: CcButtonVariant.secondary,
            onPressed: () => Navigator.pop(ctx, null),
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: Text(l10n.create),
          ),
        ],
      ),
    );
    if (title == null || title.isEmpty) {
      return;
    }
    final conv = await ref
        .read(conversationRepositoryProvider)
        .create(
          workspaceId: workspaceId,
          channelId: channelId,
          title: title,
          // The server mints the id + kind (parenthesis); this is the seed.
          conversation: Conversation(
            id: '',
            workspaceId: workspaceId,
            channelId: channelId,
            title: title,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          ),
        );
    onSelect?.call(conv.id);
  }

  Future<void> _close(WidgetRef ref, Conversation conv) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    await ref
        .read(conversationRepositoryProvider)
        .setStatus(
          workspaceId: workspaceId,
          conversationId: conv.id,
          status: ConversationStatus.archived,
        );
    // If the closed conversation was active, fall back to main.
    if (conv.id == activeConversationId) {
      onSelect?.call(channelId);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final conversations =
        ref.watch(channelConversationsProvider(channelId)).value ??
        const <Conversation>[];
    // Active conversations only (archived ones are hidden until reopened).
    final active = conversations
        .where((c) => !c.isArchived)
        .toList(growable: false);
    // Solo-first: no chrome until a second conversation exists.
    if (active.length <= 1) {
      return const SizedBox.shrink();
    }
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
      decoration: BoxDecoration(color: ds.bgSecondary),
      child: Row(
        children: [
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                for (final conv in active)
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpacing.xxs),
                    child: _ConversationChip(
                      conversation: conv,
                      active: conv.id == activeConversationId,
                      onTap: () => onSelect?.call(conv.id),
                      onClose: conv.isParenthesis
                          ? () => _close(ref, conv)
                          : null,
                    ),
                  ),
              ],
            ),
          ),
          CcIconButton(
            icon: AppIcons.plus,
            size: CcButtonSize.sm,
            tooltip: l10n.newParenthesis,
            onPressed: () => _newParenthesis(context, ref),
          ),
        ],
      ),
    );
  }
}

class _ConversationChip extends StatelessWidget {
  const _ConversationChip({
    required this.conversation,
    required this.active,
    required this.onTap,
    this.onClose,
  });

  final Conversation conversation;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onTap,
      builder: (context, states) => Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        decoration: BoxDecoration(
          color: active ? ds.bgPrimary : Colors.transparent,
          borderRadius: AppRadii.brSm,
          border: Border.all(
            color: active ? ds.lineStrong : Colors.transparent,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              conversation.isMain
                  ? AppIcons.messageSquareText
                  : AppIcons.gitBranch,
              size: 13,
              color: active ? ds.fg : ds.fgTertiary,
            ),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              conversation.title,
              style: TextStyle(
                fontSize: 12,
                color: active ? ds.fg : ds.fgSecondary,
                fontWeight: active
                    ? FontWeight.w600
                    : CcTypography.regularWeight,
                decoration: TextDecoration.none,
              ),
            ),
            if (onClose != null) ...[
              const SizedBox(width: AppSpacing.xxs),
              CcTappable(
                onPressed: onClose,
                semanticLabel: 'Close',
                builder: (context, states) =>
                    Icon(AppIcons.x, size: 12, color: ds.fgTertiary),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
