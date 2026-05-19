import 'package:cc_domain/core/domain/entities/message.dart';
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
  });

  /// The queued conversation row this card shows.
  final Message card;

  /// Whether a run can still take this card, which is what the "Steer" button
  /// acts on. False hides it.
  final bool steerable;

  /// The grip the list supplies, already wired to its reorder index.
  final Widget dragHandle;

  /// Commits an edited body.
  final ValueChanged<String> onEdit;

  /// Drops the card from the queue.
  final VoidCallback onDelete;

  /// Jumps the card to the front so the next turn boundary injects it first.
  final VoidCallback onDeliver;

  @override
  State<SteeringQueueCard> createState() => _SteeringQueueCardState();
}

class _SteeringQueueCardState extends State<SteeringQueueCard> {
  late final TextEditingController _editController;
  bool _editing = false;

  @override
  void initState() {
    super.initState();
    _editController = TextEditingController(text: widget.card.content);
  }

  @override
  void dispose() {
    _editController.dispose();
    super.dispose();
  }

  void _commitEdit() {
    final text = _editController.text.trim();
    setState(() => _editing = false);
    if (text.isNotEmpty && text != widget.card.content) {
      widget.onEdit(text);
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
                    autofocus: true,
                    onSubmitted: (_) => _commitEdit(),
                    hintText: l10n.editSteeringCard,
                  )
                : Text(
                    widget.card.content,
                    style: TextStyle(fontSize: 13, color: ds.textSecondary),
                  ),
          ),
          const SizedBox(width: AppSpacing.sm),
          if (widget.steerable && !_editing)
            CcButton(
              icon: AppIcons.arrowUp,
              variant: CcButtonVariant.secondary,
              size: CcButtonSize.sm,
              onPressed: widget.onDeliver,
              child: Text(l10n.steerNow),
            ),
          if (_editing)
            CcIconButton(
              icon: AppIcons.arrowUp,
              size: CcButtonSize.sm,
              tooltip: l10n.saveChanges,
              onPressed: _commitEdit,
            )
          else
            CcIconButton(
              icon: AppIcons.pencil,
              size: CcButtonSize.sm,
              tooltip: l10n.editSteeringCard,
              onPressed: () => setState(() => _editing = true),
            ),
          CcIconButton(
            icon: AppIcons.trash2,
            size: CcButtonSize.sm,
            tooltip: l10n.deleteSteeringCard,
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }
}
