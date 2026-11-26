import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_hover_reveal.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/section_card.dart';
import 'package:flutter/widgets.dart';

/// The footer of the action-item and decision lists: a quiet ghost button that
/// adds an item by hand.
class MeetingAddRow extends StatelessWidget {
  /// Creates a [MeetingAddRow].
  const MeetingAddRow({super.key, required this.label, required this.onTap});

  /// The button label (e.g. "Add action item").
  final String label;

  /// Called when pressed.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      // The button's own 12px inset lands its glyph on the rows' 16px edge.
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      child: Align(
        alignment: AlignmentDirectional.centerStart,
        child: CcButton(
          variant: CcButtonVariant.ghost,
          size: CcButtonSize.sm,
          icon: AppIcons.plus,
          onPressed: onTap,
          child: Text(label),
        ),
      ),
    );
  }
}

/// A list row whose actions appear while the pointer is over it.
///
/// The row is not itself a button, so it gets no pointer cursor; the wash only
/// ties the revealed actions to the line they act on. [actions] stay in the
/// tree while hidden (keyboard focus reveals them, a screen reader always finds
/// them) and stay visible on a client with no pointer to hover with.
class MeetingHoverActionsRow extends StatefulWidget {
  /// Creates a [MeetingHoverActionsRow].
  const MeetingHoverActionsRow({
    super.key,
    required this.padding,
    required this.children,
    required this.actions,
  });

  /// Inset around the row's content.
  final EdgeInsetsGeometry padding;

  /// The row's always-visible content, laid out from the start.
  final List<Widget> children;

  /// The trailing actions revealed on hover or focus.
  final List<Widget> actions;

  @override
  State<MeetingHoverActionsRow> createState() => _MeetingHoverActionsRowState();
}

class _MeetingHoverActionsRowState extends State<MeetingHoverActionsRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final ds = context.ds;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: CcMotion.resolveFade(context, CcMotion.fast),
        curve: CcMotion.standard,
        color: _hovered ? ds.hover : ds.hover.withValues(alpha: 0),
        padding: widget.padding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ...widget.children,
            const SizedBox(width: AppSpacing.md),
            SettingsHoverReveal(
              active: _hovered,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: widget.actions,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The empty state for a detail tab whose list the agent extracts: what is
/// missing, and the affordance to add one by hand.
///
/// Shared by the action-item and decision tabs so both read as the same
/// surface — they each used to hand-roll a bare centered `Text` plus a button,
/// which is the one empty-state treatment the design system already owns.
class MeetingTabEmptyState extends StatelessWidget {
  /// Creates a [MeetingTabEmptyState].
  const MeetingTabEmptyState({
    super.key,
    required this.icon,
    required this.message,
    required this.actionLabel,
    required this.onAdd,
  });

  /// The glyph standing in for the missing content.
  final IconData icon;

  /// What is not here yet.
  final String message;

  /// Label for the add affordance.
  final String actionLabel;

  /// Called when the add affordance is pressed.
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.xxl,
      ),
      child: CcEmptyState(
        icon: icon,
        iconSize: 28,
        message: message,
        action: CcButton(
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          onPressed: onAdd,
          icon: AppIcons.plus,
          child: Text(actionLabel),
        ),
      ),
    );
  }
}
