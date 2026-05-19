import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// A popover-menu property picker shared by the ticket detail rail and the
/// new-ticket dialog: renders [trigger] and shows the [menu] tile groups in a
/// popover when tapped. The `toggle` callback passed to both closures
/// opens/closes the popover (call it after a selection to dismiss).
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

  /// Builds the popover's tile groups. The `toggle` callback closes the popover.
  final List<FTileGroup> Function(BuildContext context, VoidCallback toggle)
      menu;

  /// Maximum popover width.
  final double maxWidth;

  @override
  State<TicketPropertyPicker> createState() => _TicketPropertyPickerState();
}

class _TicketPropertyPickerState extends State<TicketPropertyPicker>
    with SingleTickerProviderStateMixin {
  late final FPopoverController _controller = FPopoverController(vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FPopoverMenu.tiles(
      control: FPopoverControl.managed(controller: _controller),
      style: FPopoverMenuStyleDelta.delta(maxWidth: widget.maxWidth),
      divider: FItemDivider.full,
      menu: widget.menu(context, _controller.toggle),
      child: widget.trigger(context, _controller.toggle),
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
    return FTappable(
      onPress: onTap,
      child: Container(
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
            Icon(LucideIcons.chevronDown, size: 14, color: t.fgQuaternary),
          ],
        ),
      ),
    );
  }
}
