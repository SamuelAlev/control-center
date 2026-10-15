part of 'space_row_adornments.dart';

/// Vertical overflow trigger for a space/conversation sidebar row.
///
/// Hidden at rest so the label can use the full row. On hover (or while its
/// menu is open) it takes trailing space and the label ellipsizes — no fade,
/// no reserved slot. The open-menu latch is required because the panel's
/// dismiss barrier ends the row's hover the instant the trigger is used.
class SpaceRowOverflowMenu extends StatefulWidget {
  /// Creates the hover-revealed overflow trigger.
  const SpaceRowOverflowMenu({
    super.key,
    required this.items,
    required this.semanticLabel,
    required this.color,
    required this.revealed,
    required this.selected,
  });

  /// Actions listed in the dropdown (the former right-click menu).
  final List<CcMenuItem> items;

  /// Accessible name for the icon-only trigger.
  final String semanticLabel;

  /// Icon (and selected-row hover wash) colour — follows the row's content.
  final Color color;

  /// Whether the pointer or keyboard focus is on the enclosing row.
  final bool revealed;

  /// Whether the row is the route's selected space/conversation.
  final bool selected;

  @override
  State<SpaceRowOverflowMenu> createState() => _SpaceRowOverflowMenuState();
}

class _SpaceRowOverflowMenuState extends State<SpaceRowOverflowMenu> {
  final CcOverlayController _menu = CcOverlayController();
  final FocusNode _triggerFocus = FocusNode(
    debugLabel: 'SpaceRowOverflow.trigger',
  );

  @override
  void initState() {
    super.initState();
    _menu.addListener(_onMenuChanged);
  }

  @override
  void dispose() {
    _menu
      ..removeListener(_onMenuChanged)
      ..dispose();
    _triggerFocus.dispose();
    super.dispose();
  }

  void _onMenuChanged() {
    setState(() {});
    if (_menu.isOpen) {
      return;
    }
    // The panel's FocusScope restores to this trigger after dismiss. Drop
    // that leftover pointer-focus on the next frame (restoration runs as
    // the overlay unmounts, after this listener) so the parent row does
    // not keep treating the trigger as revealed.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _menu.isOpen || FocusModality.instance.isKeyboard) {
        return;
      }
      _triggerFocus.unfocus();
    });
  }

  @override
  Widget build(BuildContext context) {
    final show = widget.revealed || _menu.isOpen;
    if (!show) {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: AppSpacing.xs),
      child: CcMenu(
        controller: _menu,
        toggleOnTargetTap: false,
        semanticLabel: widget.semanticLabel,
        targetAnchor: AlignmentDirectional.bottomEnd,
        followerAnchor: AlignmentDirectional.topEnd,
        minWidth: 180,
        items: widget.items,
        target: CcTappable(
          onPressed: _menu.toggle,
          focusNode: _triggerFocus,
          semanticLabel: widget.semanticLabel,
          borderRadius: AppRadii.brSm,
          focusRingColor: widget.selected ? widget.color : null,
          builder: (context, states) {
            final active =
                _menu.isOpen ||
                states.contains(WidgetState.hovered) ||
                states.contains(WidgetState.pressed);
            return SizedBox(
              width: kSpaceSidebarTrailingControl,
              height: kSpaceSidebarTrailingControl,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: active
                      ? widget.color.withValues(alpha: 0.16)
                      : widget.color.withValues(alpha: 0),
                  borderRadius: AppRadii.brSm,
                ),
                child: CcIcon(
                  AppIcons.moreVertical,
                  size: 16,
                  color: widget.color,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
