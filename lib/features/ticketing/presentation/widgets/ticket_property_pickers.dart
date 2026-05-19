import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// A popover-menu property picker shared by the ticket detail rail and the
/// new-ticket dialog: renders [trigger] and shows the [menu] body in a
/// popover when tapped. The `toggle` callback passed to [trigger] opens/closes
/// the popover; the `toggle` callback passed to [menu] closes it (call it after
/// a selection to dismiss).
class TicketPropertyPicker extends StatefulWidget {
  /// Creates a [TicketPropertyPicker].
  const TicketPropertyPicker({
    super.key,
    required this.trigger,
    required this.menu,
    this.maxWidth = 240,
  });

  /// Builds the always-visible trigger. The `toggle` callback opens/closes the
  /// popover.
  final Widget Function(BuildContext context, VoidCallback toggle) trigger;

  /// Builds the popover's body widget. The `toggle` callback closes the
  /// popover.
  final Widget Function(BuildContext context, VoidCallback toggle) menu;

  /// Maximum popover width.
  final double maxWidth;

  @override
  State<TicketPropertyPicker> createState() => _TicketPropertyPickerState();
}

class _TicketPropertyPickerState extends State<TicketPropertyPicker> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final card = CcCardTokens.panel(t);

    return CcPopover(
      controller: _controller,
      toggleOnTargetTap: false,
      target: widget.trigger(context, _controller.toggle),
      overlayBuilder: (context, _) => ConstrainedBox(
        constraints: BoxConstraints(maxWidth: widget.maxWidth),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: card.bg,
            borderRadius: AppRadii.brLg,
            border: Border.all(color: card.border),
            boxShadow: CcElevation.floating,
          ),
          child: ClipRRect(
            borderRadius: AppRadii.brLg,
            child: widget.menu(context, _controller.hide),
          ),
        ),
      ),
    );
  }
}

/// A compact "chip" trigger for a [TicketPropertyPicker]: the given [child]
/// followed by a chevron. With [bordered] it gains a rounded outline and
/// background, matching the property pills in the new-ticket dialog; without
/// it, it stays borderless for the detail rail.
class TicketTriggerChip extends StatelessWidget {
  /// Creates a [TicketTriggerChip].
  const TicketTriggerChip({
    super.key,
    required this.child,
    required this.onTap,
    this.bordered = false,
  });

  /// The chip's leading content (an icon + label, a status dot, etc.).
  final Widget child;

  /// Tapped to toggle the popover.
  final VoidCallback onTap;

  /// Whether to draw a rounded outline + background.
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcTappable(
      onPressed: onTap,
      builder: (context, states) => Container(
        padding: EdgeInsets.symmetric(horizontal: bordered ? 10 : 8, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: AppRadii.brSm,
          color: bordered ? t.bgPrimary : null,
          border: bordered ? Border.all(color: t.borderPrimary) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(child: child),
            const SizedBox(width: 4),
            Icon(AppIcons.chevronDown, size: 14, color: t.fgQuaternary),
          ],
        ),
      ),
    );
  }
}
