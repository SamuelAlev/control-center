import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/steering_queue_card.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart'
    show ConversationRef;
import 'package:control_center/features/messaging/providers/steering_queue_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/composer.dart'
    show composerHorizontalMargin;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The steering queue strip: the still-queued steering cards of one
/// conversation, rendered between the chat trail and the composer.
///
/// A card here is a persisted conversation row waiting for a run to inject
/// it (or, for external-CLI transports, waiting for run end to convert into a
/// normal message). Reordering drags with the grip handle; "Steer" jumps a
/// card to the front so the next turn boundary injects it first; edit and
/// delete act on the row server-side, so every device agrees.
///
/// The strip is drawn AS the top of the composer, not as a card floating above
/// it: it keeps the composer's own horizontal inset, no card carries a bottom
/// border, and the composer drops its top margin (`Composer.attachedTop`, set
/// by `SpaceInputBar` from this same queue) so the last card lands on its top
/// border. A queued card is the text the composer is about to send — a gap
/// between them read as an unrelated banner.
///
/// Renders nothing when the queue is empty — the strip is not chrome, it is
/// content.
class SteeringQueueList extends ConsumerStatefulWidget {
  /// Creates the strip for one conversation.
  const SteeringQueueList({
    super.key,
    required this.spaceId,
    required this.conversationId,
  });

  /// The space the conversation belongs to.
  final String spaceId;

  /// The conversation whose queued cards this strip shows.
  final String conversationId;

  @override
  ConsumerState<SteeringQueueList> createState() => _SteeringQueueListState();
}

class _SteeringQueueListState extends ConsumerState<SteeringQueueList> {
  /// Optimistic order while a drag settles: the server stamps `steerOrder`
  /// from the id list we send, and holding the moved list locally keeps the
  /// row from snapping back for the round-trip.
  List<Message>? _optimisticOrder;

  @override
  Widget build(BuildContext context) {
    final key = (
      spaceId: widget.spaceId,
      conversationId: widget.conversationId,
    );
    final List<Message> cards =
        _optimisticOrder ?? ref.watch(steeringQueueProvider(key));
    if (cards.isEmpty) {
      _optimisticOrder = null;
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);
    // Unknown (null) shows the button: a card that outlived the client which
    // typed it still belongs to a run that can very likely take it, and the
    // deliver call reports honestly when it cannot.
    final steerable = ref.watch(steeringSteerableProvider(key)) ?? true;

    return Semantics(
      label: l10n.steeringQueueLabel,
      child: Padding(
        // The composer's own inset, so the strip's sides continue its borders
        // rather than sitting on a different vertical. The top gap separates
        // the queue from the trail above it; there is deliberately no bottom
        // one — that edge belongs to the composer.
        padding: const EdgeInsets.only(
          left: composerHorizontalMargin,
          right: composerHorizontalMargin,
          top: AppSpacing.sm,
        ),
        child: ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          onReorderItem: (oldIndex, newIndex) =>
              _onReorder(key, cards, oldIndex, newIndex),
          itemCount: cards.length,
          itemBuilder: (context, index) {
            final card = cards[index];
            return SteeringQueueCard(
              key: ValueKey(card.id),
              card: card,
              steerable: steerable,
              dragHandle: _dragHandle(context, index),
              onEdit: (content) => _onEdit(key, card.id, content),
              onDelete: () => _onDelete(key, card.id),
              onDeliver: () => _onDeliver(key, card.id),
            );
          },
        ),
      ),
    );
  }

  /// The grip a card drags by.
  ///
  /// Built here rather than in [SteeringQueueCard] because
  /// `ReorderableDragStartListener` is Material, and this file is already on
  /// the de-Material allowlist while the card file is not.
  Widget _dragHandle(BuildContext context, int index) {
    final ds = context.ds;
    return ReorderableDragStartListener(
      index: index,
      child: Semantics(
        label: AppLocalizations.of(context).reorderSteeringCard,
        child: MouseRegion(
          cursor: SystemMouseCursors.grab,
          child: Icon(
            AppIcons.gripVertical,
            size: 14,
            color: ds.textQuaternary,
          ),
        ),
      ),
    );
  }

  void _onReorder(
    ConversationRef key,
    List<Message> cards,
    int oldIndex,
    int newIndex,
  ) {
    final ordered = List<Message>.of(cards);
    final moved = ordered.removeAt(oldIndex);
    ordered.insert(newIndex, moved);
    // Optimistic first; the server's steerOrder stamp arrives via the same
    // feed and replaces this.
    setState(() => _optimisticOrder = ordered);
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    reorderSteeringCards(
      ref,
      workspaceId: workspaceId,
      key: key,
      orderedIds: [for (final c in ordered) c.id],
    );
  }

  Future<void> _onEdit(
    ConversationRef key,
    String messageId,
    String content,
  ) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    await editSteeringCard(
      ref,
      workspaceId: workspaceId,
      key: key,
      messageId: messageId,
      content: content,
    );
  }

  Future<void> _onDelete(ConversationRef key, String messageId) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    await deleteSteeringCard(
      ref,
      workspaceId: workspaceId,
      key: key,
      messageId: messageId,
    );
  }

  Future<void> _onDeliver(ConversationRef key, String messageId) async {
    final workspaceId = ref.read(activeWorkspaceIdProvider);
    if (workspaceId == null) {
      return;
    }
    final delivered = await deliverSteeringCard(
      ref,
      workspaceId: workspaceId,
      key: key,
      messageId: messageId,
    );
    if (!delivered && mounted) {
      // The run ended (or was a CLI transport) between render and press. The
      // card stays queued and the run-end conversion is its delivery path —
      // say so rather than failing silently.
      CcToastScope.maybeOf(context)?.show(
        AppLocalizations.of(context).steeringDeliverUnavailable,
        variant: CcToastVariant.neutral,
      );
    }
  }
}
