import 'package:cc_domain/core/domain/entities/message.dart';
import 'package:cc_domain/core/domain/value_objects/file_reference.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// One queued steering card: the drag handle, the text, and the card's actions.
///
/// Split out of `steering_queue_list.dart` so that file stays inside the
/// presentation size budget. The [dragHandle] is built by the list rather than
/// here: it is a `ReorderableDragStartListener`, the one Material widget in the
/// strip, and keeping it on the list's side lets this file stay on
/// `flutter/widgets.dart` instead of joining the de-Material allowlist.
class SteeringQueueCard extends StatefulWidget {
  /// Creates a card row.
  const SteeringQueueCard({
    super.key,
    required this.card,
    required this.steerable,
    required this.dragHandle,
    required this.onEdit,
    required this.onDelete,
    required this.onDeliver,
    required this.author,
  });

  /// The queued conversation row this card shows.
  final Message card;

  /// Whether a run can still take this card without being interrupted. Picks
  /// what the button promises: "Steer", or "Stop and send" when getting the
  /// card in now means ending the run.
  final bool steerable;

  /// The grip the list supplies, already wired to its reorder index.
  final Widget dragHandle;

  /// Commits an edited body. Null hides the pencil: only a card's writer
  /// may edit it.
  final ValueChanged<String>? onEdit;

  /// Drops the card from the queue.
  final VoidCallback onDelete;

  /// Gets the card in: ahead of the rest of a live lane, or, when [steerable]
  /// is false, by stopping the run. Null hides the button: only a card's
  /// writer may stop the runs to send it.
  final VoidCallback? onDeliver;

  /// Whose card this is when it is someone else's ("From Ada"), or null for
  /// the viewer's own.
  final String? author;

  @override
  State<SteeringQueueCard> createState() => _SteeringQueueCardState();
}

class _SteeringQueueCardState extends State<SteeringQueueCard> {
  late final TextEditingController _editController;
  final FocusNode _editFocus = FocusNode(debugLabel: 'steering card edit');
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.card.content);
  }

  @override
  void dispose() {
    _editController.dispose();
    _editFocus.dispose();
    super.dispose();
  }

  /// Opens the card for typing. The pencil that was pressed stays mounted
  /// (its slot becomes the save button) and keeps focus, so the field's own
  /// autofocus would be ignored; the field asks for focus once it is built.
  void _startEdit() {
    setState(() => _editing = true);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _editing) {
        _editFocus.requestFocus();
      }
    });
  }

  void _commitEdit() {
    final text = _editController.text.trim();
    setState(() => _editing = false);
    if (text.isNotEmpty && text != widget.card.content) {
      widget.onEdit?.call(text);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    final l10n = AppLocalizations.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        // Fills with the recessed surface rather than the composer's own
        // background: queued, not yet said.
        color: ds.surface,
        // No bottom border, on any card. Between two cards the next one's top
        // border is the separator; under the last one the composer's top
        // border is — either way the strip is one continuous edge instead of
        // a stack of outlined boxes.
        border: Border(
          top: BorderSide(color: ds.borderPrimary),
          left: BorderSide(color: ds.borderPrimary),
          right: BorderSide(color: ds.borderPrimary),
        ),
      ),
      child: Row(
        children: [
          widget.dragHandle,
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: _editing
                ? CcTextField(
                    controller: _editController,
                    focusNode: _editFocus,
                    onSubmitted: (_) => _commitEdit(),
                    hintText: l10n.editSteeringCard,
                  )
                : Row(
                    children: [
                      if (widget.card.attachments.isNotEmpty) ...[
                        Icon(AppIcons.image, size: 14, color: ds.textTertiary),
                        const SizedBox(width: AppSpacing.xs),
                      ],
                      Expanded(
                        child: Text(
                          _displayText(widget.card),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: ds.textSecondary,
                          ),
                        ),
                      ),
                      if (widget.author case final author?) ...[
                        const SizedBox(width: AppSpacing.sm),
                        Text(
                          author,
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 12,
                            color: ds.textTertiary,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (!_editing && widget.onDeliver != null)
            CcButton(
              icon: AppIcons.arrowUp,
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              onPressed: widget.onDeliver,
              child: Text(widget.steerable ? l10n.steerNow : l10n.steerForce),
            ),
          if (_editing)
            CcIconButton(
              icon: AppIcons.arrowUp,
              size: CcButtonSize.sm,
              tooltip: l10n.saveChanges,
              onPressed: _commitEdit,
            )
          else if (widget.onEdit != null)
            CcIconButton(
              icon: AppIcons.pencil,
              size: CcButtonSize.sm,
              tooltip: l10n.editSteeringCard,
              onPressed: _startEdit,
            ),
          CcIconButton(
            variant: CcButtonVariant.destructive,
            icon: AppIcons.trash2,
            size: CcButtonSize.sm,
            tooltip: l10n.deleteSteeringCard,
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }

  /// The card's text as it reads: attachment references by name, and the
  /// names alone for a card that is only attachments.
  static String _displayText(Message card) {
    final text = expandFileRefs(card.content, (name) => name).trim();
    if (text.isNotEmpty) {
      return text;
    }
    return [for (final a in card.attachments) a.name].join(', ');
  }
}
