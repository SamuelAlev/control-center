import 'package:cc_domain/core/domain/entities/channel_message.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/bubble_body.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/channel_bubble_shared.dart';
import 'package:control_center/features/messaging/presentation/widgets/channel_bubble/focusable_bubble.dart';
import 'package:control_center/features/messaging/providers/message_edit_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Renders a user message as a right-aligned bubble, capped at ~75% of the
/// centered content column. Your OWN messages stay implicit ("You" lives only
/// in the semantics label); another member's message carries their display
/// name above the bubble so multi-human rooms keep attribution legible. The
/// column width — not the viewport — bounds the cap, so the bubble shrinks on
/// narrow panes and stays composed on wide ones.
///
/// The hover toolbar offers edit + soft-delete for a user's own text messages
/// (§8.3); an edited message shows an "(edited)" marker and a deleted one is
/// replaced by a muted placeholder.
class UserBubble extends ConsumerWidget {
  /// Creates a [UserBubble].
  const UserBubble({
    super.key,
    required this.message,
    required this.codeFont,
    this.collapseHeader = false,
  });

  /// The user message.
  final ChannelMessage message;

  /// Font family for code blocks.
  final String codeFont;

  /// When true (consecutive same-sender turn), top padding tightens so grouped
  /// user messages read as one run.
  final bool collapseHeader;

  /// Opens an edit dialog seeded with the current content; on save, writes the
  /// edit over RPC (stamps `editedAt`).
  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final controller = TextEditingController(text: message.content);
    final next = await showCcDialog<String>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.editMessage,
        content: CcTextField(
          controller: controller,
          autofocus: true,
          onSubmitted: (_) => Navigator.pop(ctx, controller.text),
        ),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(ctx),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(ctx, controller.text),
            child: Text(l10n.save),
          ),
        ],
      ),
    );
    controller.dispose();
    if (next == null) {
      return;
    }
    await ref
        .read(messageEditControllerProvider)
        .edit(message, next, undoLabel: l10n.undoLabelMessageEdit);
  }

  /// Confirms, then soft-deletes the message over RPC.
  Future<void> _delete(BuildContext context, WidgetRef ref) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.deleteMessage,
        content: Text(l10n.deleteMessageConfirm),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(ctx, false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(ctx, true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true) {
      return;
    }
    await ref.read(messageEditControllerProvider).softDelete(message);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final tokens = resolveTokens(context);
    final topPad = collapseHeader ? AppSpacing.xxs : AppSpacing.xl;
    final deleted = message.isDeleted;
    final l10n = AppLocalizations.of(context);
    // Attribution: the author is a real user id. A message from ANOTHER
    // member shows their name; your own stays implicit. While identity is
    // still loading, treat the message as your own (solo-first default).
    final currentUserId = ref.watch(currentUserIdProvider);
    final isOwn = currentUserId == null || message.senderId == currentUserId;
    final authorName = isOwn
        ? null
        : ref.watch(usersByIdProvider).value?[message.senderId]?.displayName ??
              (message.senderId.length > 8
                  ? message.senderId.substring(0, 8)
                  : message.senderId);

    return Padding(
      padding: EdgeInsets.only(top: topPad),
      child: Semantics(
        label: deleted
            ? l10n.messageDeleted
            : '${authorName ?? 'You'}: ${message.content}',
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Cap the bubble at ~75% of the (already-centered, ≤760px) column
            // it sits in, not the viewport.
            final maxWidth = constraints.maxWidth * maxBubbleFraction;
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Flexible(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: IntrinsicWidth(
                      child: FocusableBubble(
                        messageId: message.id,
                        channelId: message.channelId,
                        alignRight: true,
                        copyText: deleted ? null : message.content,
                        canRevert: !deleted,
                        // Edit/delete only for your OWN live message — another
                        // member's words are not yours to rewrite.
                        onEdit: deleted || !isOwn
                            ? null
                            : () => _edit(context, ref),
                        onDelete: deleted || !isOwn
                            ? null
                            : () => _delete(context, ref),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (authorName != null && !collapseHeader)
                              Padding(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.xxs,
                                ),
                                child: Text(
                                  authorName,
                                  style: CcTypography.caption.copyWith(
                                    color: tokens.fgTertiary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            Container(
                              padding: bubblePadding,
                              decoration: BoxDecoration(
                                color: tokens.bgSecondary,
                                borderRadius: AppRadii.brMd,
                                border: Border.all(
                                  color: tokens.borderSecondary,
                                ),
                              ),
                              child: deleted
                                  ? Text(
                                      l10n.messageDeleted,
                                      style: CcTypography.body
                                          .copyWith(color: tokens.textTertiary)
                                          .copyWith(
                                            color: tokens.fgTertiary,
                                            fontStyle: FontStyle.italic,
                                          ),
                                    )
                                  : BubbleBody(
                                      content: message.content,
                                      createdAt: message.createdAt,
                                      codeFont: codeFont,
                                      tokens: tokens,
                                      theme: theme,
                                      isEdited: message.isEdited,
                                    ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
