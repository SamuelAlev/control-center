import 'package:control_center/features/messaging/providers/editing_message_provider.dart';
import 'package:control_center/shared/widgets/composer/composer_draft.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The exact destination of an unsent conversation message.
typedef SpaceComposerDraftKey = ({
  String workspaceId,
  String spaceId,
  String conversationId,
});

/// Retains text, mentions and uploads while the conversation is not mounted.
final spaceComposerDraftProvider =
    Provider.family<ComposerDraft, SpaceComposerDraftKey>((ref, key) {
      final draft = ComposerDraft();
      ref.onDispose(draft.dispose);
      String? beforeEdit;
      ref.listen(
        editingMessageProvider((
          spaceId: key.spaceId,
          conversationId: key.conversationId,
        )),
        (previous, next) {
          if (next != null) {
            // Switching edited messages must not replace the parked draft.
            if (previous == null) {
              beforeEdit = draft.controller.text;
            }
            draft.controller.replaceAll(next.message.content);
          } else if (previous != null) {
            draft.controller.replaceAll(beforeEdit ?? '');
            beforeEdit = null;
          }
        },
        fireImmediately: true,
      );
      return draft;
    });
