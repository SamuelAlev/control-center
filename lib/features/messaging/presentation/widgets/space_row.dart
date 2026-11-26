import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_adornments.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_layout.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

export 'package:control_center/features/messaging/presentation/widgets/space_row_adornments.dart'
    show AttentionDot;
export 'package:control_center/features/messaging/presentation/widgets/space_row_layout.dart'
    show
        kConversationLabelFontSize,
        kConversationRowExtent,
        kSpaceRowSignalSize,
        kSpaceSidebarCardInset,
        kSpaceSidebarPad,
        kSpaceSidebarMarkSlot,
        kSpaceSidebarMarkGap;

/// A space navigation row with [CcSidebarItem]'s selection fill, hover wash
/// and padding. It can't be a [CcSidebarItem] because that widget's icon-only
/// API hosts no [leading] widget. Implements [CcFluidHoverTarget] so a
/// [CcSidebarGroup] of space rows shares the travelling hover wash.
class SpaceRow extends StatelessWidget implements CcFluidHoverTarget {
  /// Creates a [SpaceRow].
  const SpaceRow({
    super.key,
    this.leading,
    this.signal,
    required this.label,
    this.labelScrambling = false,
    required this.selected,
    this.markSlot = kSpaceSidebarMarkSlot,
    this.markGap = kSpaceSidebarMarkGap,
    this.labelFontSize = 14,
    this.extent = kCcSidebarItemExtent,
    this.onPress,
    this.muted = false,
    this.quietSelection = false,
    this.indent = 0,
    this.cardInset = EdgeInsets.zero,
    this.subtitle,
    this.trailingLabel,
    this.count,
    this.menuItems,
    this.menuSemanticLabel,
    this.menuRevealed = false,
  });

  /// An icon column before the title (the tray's link rows). Null leaves
  /// no column, so the title starts at the row's inset.
  final Widget? leading;

  /// The running spinner or attention dot in front of a space's or
  /// conversation's title. Null shows nothing and leaves the title in place.
  final Widget? signal;

  /// The space display name.
  final String label;

  /// Whether [label] is still being worked out (a conversation title a model
  /// is generating): its letters churn until this clears.
  final bool labelScrambling;

  /// Whether this is the route's selected space.
  final bool selected;

  /// Width of the [leading] column.
  final double markSlot;

  /// Space between the leading column and the title.
  final double markGap;

  /// Primary-line size.
  final double labelFontSize;

  /// Single-line row height.
  final double extent;

  /// Whether this is a muted agent-DM row.
  final bool muted;

  /// Selected, but the parent paints the surface, so this row stays unfilled.
  final bool quietSelection;

  /// Extra start inset, so a nested row's mark lines up with a parent title.
  final double indent;

  /// Vertical air painted by this row's own fill. The sidebar card's inset
  /// lives here so a press recolors that air together with the title, instead
  /// of leaving a band of the panel color above and below.
  final EdgeInsets cardInset;

  /// Second line under [label], in the caption style: a space's pull
  /// requests in the sidebar.
  final Widget? subtitle;

  /// Short trailing caption, such as a relative time on an activity row.
  final String? trailingLabel;

  /// Optional conversation count chip. Null hides it.
  final int? count;

  /// Hover-revealed overflow actions. Null hides the trigger.
  final List<CcMenuItem>? menuItems;

  /// Accessible name for [menuItems]' icon-only trigger.
  final String? menuSemanticLabel;

  /// Tap handler. Null when a parent surface owns the press, so this row
  /// paints content only and does not take its own hover, focus or cursor.
  final VoidCallback? onPress;

  /// Shows the overflow trigger even when this row is not itself hovered.
  /// The enclosing card sets this while the pointer is on the card.
  final bool menuRevealed;

  @override
  bool get fluidHoverEnabled => true;

  bool get _filled => selected && !quietSelection;

  bool _overflowRevealed(Set<WidgetState> states) {
    if (states.contains(WidgetState.hovered)) {
      return true;
    }
    return states.contains(WidgetState.focused) &&
        FocusModality.instance.isKeyboard;
  }

  Color _hoverFill(
    DesignSystemTokens t,
    Set<WidgetState> states, {
    required bool fluidActive,
  }) {
    if (states.contains(WidgetState.pressed)) {
      return t.hoverStrong;
    }
    if (states.contains(WidgetState.hovered)) {
      return fluidActive ? t.hover.withValues(alpha: 0) : t.hover;
    }
    return t.hover.withValues(alpha: 0);
  }

  /// What [signal] says, carried by the row's own node: the spinner and dot
  /// are hidden from semantics where they are painted (SpaceRowLabel), so
  /// the spinner's generic "loading" and live region never reach the row.
  String? _signalValue(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return switch (signal) {
      CcSpinner() || SpaceLeadingIcon(running: true) => l10n.agentResponding,
      AttentionDot() || SpaceLeadingIcon() => l10n.inboxNeedsYourAttention,
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final fg = _filled
        ? t.accentOn
        : (muted ? t.textTertiary : t.textSecondary);
    // At 0.72 the caption fell to 3.9:1 on the brand fill.
    final caption = _filled
        ? t.accentOn.withValues(alpha: 0.9)
        : t.textTertiary;
    final transitioning = CcSidebarScope.transitioningOf(context) ?? false;
    final hasMenu =
        menuItems != null &&
        menuItems!.isNotEmpty &&
        menuSemanticLabel != null &&
        !transitioning;

    Widget painted(Set<WidgetState> states) {
      return TweenAnimationBuilder<Color?>(
        // Selecting snaps with the fill (see [SpaceRowLayout]); the row being
        // left fades back over CcMotion.fast.
        duration: _filled ? Duration.zero : CcMotion.fast,
        curve: CcMotion.standard,
        tween: ColorTween(end: fg),
        builder: (context, animatedFg, _) {
          return SpaceRowLayout(
            tokens: t,
            leading: leading,
            signal: signal,
            label: label,
            labelScrambling: labelScrambling,
            contentColor: animatedFg ?? fg,
            caption: caption,
            filled: _filled,
            indent: indent,
            cardInset: cardInset,
            transitioning: transitioning,
            titleNamesRow: onPress != null,
            hasMenu: hasMenu,
            showMenu: hasMenu && (menuRevealed || _overflowRevealed(states)),
            markSlot: markSlot,
            markGap: markGap,
            labelFontSize: labelFontSize,
            extent: extent,
            hoverColor: onPress == null
                ? t.hover.withValues(alpha: 0)
                : _hoverFill(
                    t,
                    states,
                    fluidActive:
                        CcFluidHover.controlsTappable(context) &&
                        CcFluidHover.isItemActive(context),
                  ),
            subtitle: subtitle,
            trailingLabel: trailingLabel,
            count: count,
            menuItems: menuItems,
            menuSemanticLabel: menuSemanticLabel,
          );
        },
      );
    }

    final signalValue = _signalValue(context);
    final press = onPress;
    if (press == null) {
      // The surface that owns the press takes the label; the signal's state
      // merges up into it the same way.
      return signalValue == null
          ? painted(const {})
          : Semantics(value: signalValue, child: painted(const {}));
    }
    return CcTappable(
      onPressed: press,
      borderRadius: AppRadii.brSm,
      semanticLabel: label,
      semanticValue: signalValue,
      semanticSelected: selected ? true : null,
      focusRingColor: _filled ? t.accentOn : null,
      builder: (context, states) => painted(states),
    );
  }
}

/// Signal for a conversation row: a spinner while an agent is working, the
/// attention dot when it has unseen messages or a question waiting on the
/// user, and null (nothing) otherwise.
Widget? conversationActivityMark({
  required bool running,
  required bool attention,
}) {
  if (running) {
    return const CcSpinner(size: kSpaceRowSignalSize, strokeWidth: 1.5);
  }
  if (attention) {
    return const AttentionDot(selected: false);
  }
  return null;
}
