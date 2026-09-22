import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/composer/edit_message_choice_dialog.dart';
import 'package:control_center/features/messaging/providers/conversation_checkpoint_providers.dart';
import 'package:control_center/features/messaging/providers/editing_message_provider.dart';
import 'package:control_center/features/messaging/providers/message_edit_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/composer.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/composer_text_controller.dart';
import 'package:control_center/shared/widgets/composer/mention/mention_source.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The space composer, including the "edit a sent message" session.
///
/// Edit loads the message into this field so it can be changed with the same
/// mentions, history and keyboard the draft already has. Sending asks whether
/// to revert the conversation to that message or to send the text as a new
/// one. Escape or the banner's cancel puts the parked draft back.
class SpaceMessageComposer extends ConsumerStatefulWidget {
  /// Creates a composer bound to one conversation.
  const SpaceMessageComposer({
    super.key,
    required this.spaceId,
    required this.conversationId,
    required this.controller,
    required this.sources,
    required this.onSubmit,
    required this.hint,
    required this.historyKey,
    this.history,
    this.minLines = 1,
    this.leading,
    this.isBusy = false,
    this.onStop,
    this.onPlanToggle,
    this.attachedTop = false,
  });

  /// Space the edited message belongs to.
  final String spaceId;

  /// Conversation whose composer this is.
  final String conversationId;

  /// The field. Owned by the host so typing presence survives this widget.
  final ComposerTextController controller;

  /// Mention sources forwarded to the field.
  final List<MentionSource> sources;

  /// Called for a normal send. An in-progress edit never reaches this — it
  /// updates the loaded message instead.
  final Future<void> Function(ComposerSubmission submission) onSubmit;

  /// Placeholder shown while the field is empty.
  final String hint;

  /// What [history] belongs to. Changing it resets recall.
  final String historyKey;

  /// Previously sent texts, oldest first. Suppressed while editing so ArrowUp
  /// moves the caret through the message instead of replacing it.
  final List<String>? history;

  /// Minimum lines the field keeps open.
  final int minLines;

  /// Toolbar content before the built-in actions.
  final Widget? leading;

  /// Whether an agent is working, which turns an empty field's button into stop.
  final bool isBusy;

  /// Stops the live runs. Null hides the stop button.
  final Future<void> Function()? onStop;

  /// Shift+Tab. Left alone while editing — it flips the conversation mode,
  /// not the draft.
  final VoidCallback? onPlanToggle;

  /// Drops the box's top margin so a strip stacked above sits on the border.
  final bool attachedTop;

  @override
  ConsumerState<SpaceMessageComposer> createState() =>
      _SpaceMessageComposerState();
}

class _SpaceMessageComposerState extends ConsumerState<SpaceMessageComposer> {
  late final FocusNode _focus;

  /// Text that was in the field before this edit session started. Restored
  /// when the session ends. Null while no edit is open.
  String? _draftBeforeEdit;

  EditingConversation get _key =>
      (spaceId: widget.spaceId, conversationId: widget.conversationId);

  @override
  void initState() {
    super.initState();
    _focus = FocusNode();
    final pending = ref.read(editingMessageProvider(_key));
    if (pending != null) {
      _draftBeforeEdit = '';
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        _show(pending.message.content);
      });
    }
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _onEditChanged(EditingMessage? previous, EditingMessage? next) {
    if (next != null) {
      // Only the first message of a session parks the draft. Switching to
      // another message must not park the half-written edit over it.
      if (previous == null) {
        _draftBeforeEdit = widget.controller.text;
      }
      _show(next.message.content);
      return;
    }
    if (previous == null) {
      return;
    }
    final draft = _draftBeforeEdit ?? '';
    _draftBeforeEdit = null;
    _show(draft, focus: false);
  }

  void _show(String text, {bool focus = true}) {
    widget.controller.replaceAll(text);
    if (focus) {
      _focus.requestFocus();
    }
  }

  void _cancel() {
    ref.read(editingMessageProvider(_key).notifier).end();
  }

  Future<void> _submitEdit(
    EditingMessage editing,
    ComposerSubmission submission,
  ) async {
    final choice = await showEditMessageChoice(context);
    if (!mounted || choice == null) {
      if (mounted) {
        _focus.requestFocus();
      }
      return;
    }
    switch (choice) {
      case EditMessageChoice.revert:
        await _revertToEdited(editing, submission.text);
      case EditMessageChoice.sendNew:
        // End first so the parked draft is back in the field. The submission
        // was snapshotted before that, so the send still carries the edit.
        ref.read(editingMessageProvider(_key).notifier).end();
        await widget.onSubmit(submission);
    }
  }

  Future<void> _revertToEdited(EditingMessage editing, String content) async {
    final l10n = AppLocalizations.of(context);
    final message = editing.message;
    await ref
        .read(messageEditControllerProvider)
        .edit(message, content, undoLabel: l10n.undoLabelMessageEdit);
    if (!mounted) {
      return;
    }
    final hidden = await ref
        .read(conversationCheckpointControllerProvider)
        .revertTo(message.spaceId, message.id);
    if (!mounted) {
      return;
    }
    ref.read(editingMessageProvider(_key).notifier).end();
    final toast = CcToastScope.maybeOf(context);
    if (toast != null && hidden > 0) {
      toast.show(l10n.revertedToHere, variant: CcToastVariant.success);
    }
  }

  @override
  Widget build(BuildContext context) {
    final editing = ref.watch(editingMessageProvider(_key));
    ref.listen<EditingMessage?>(editingMessageProvider(_key), _onEditChanged);
    final isEditing = editing != null;
    return Composer(
      attachedTop: widget.attachedTop,
      controller: widget.controller,
      focusNode: _focus,
      sources: widget.sources,
      hint: widget.hint,
      minLines: widget.minLines,
      // Recall would swap the message out from under the edit. The caret
      // keeps the arrow keys while the session is open.
      history: isEditing ? null : widget.history,
      historyKey: widget.historyKey,
      onPlanToggle: widget.onPlanToggle,
      isBusy: widget.isBusy,
      onStop: widget.onStop,
      leading: widget.leading,
      banner: isEditing ? _EditingMessageBanner(onCancel: _cancel) : null,
      // The field stays put until the session ends, which restores the parked
      // draft. Clearing here would drop that draft and any attachments that
      // belonged to it.
      clearOnSubmit: !isEditing,
      onEscape: isEditing ? _cancel : null,
      onSubmit: (submission) async {
        final current = ref.read(editingMessageProvider(_key));
        if (current != null) {
          await _submitEdit(current, submission);
          return;
        }
        await widget.onSubmit(submission);
      },
    );
  }
}

/// The strip at the top of the composer while a sent message is loaded in it.
class _EditingMessageBanner extends StatelessWidget {
  const _EditingMessageBanner({required this.onCancel});

  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Icon(AppIcons.pencil, size: 14, color: ds.fgSecondary),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                l10n.editMessage,
                style: CcTypography.caption.copyWith(
                  color: ds.fgSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            CcIconButton(
              icon: AppIcons.x,
              size: CcButtonSize.sm,
              tooltip: l10n.cancelEdit,
              onPressed: onCancel,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        const CcDivider(),
      ],
    );
  }
}
