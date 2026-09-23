import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_layout.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter/widgets.dart';

export 'package:control_center/features/messaging/presentation/widgets/space_row_layout.dart'
    show
        kConversationLabelFontSize,
        kConversationMarkGap,
        kConversationMarkSlot,
        kConversationRowExtent,
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
    required this.leading,
    required this.label,
    required this.selected,
    required this.status,
    required this.unread,
    required this.leadingHandlesRunning,
    this.markSlot = kSpaceSidebarMarkSlot,
    this.markGap = kSpaceSidebarMarkGap,
    this.labelFontSize = 14,
    this.extent = kCcSidebarItemExtent,
    required this.onPress,
    this.muted = false,
    this.quietSelection = false,
    this.indent = 0,
    this.cardInset = EdgeInsets.zero,
    this.subtitle,
    this.trailingLabel,
    this.count,
    this.menuItems,
    this.menuSemanticLabel,
  });

  /// The leading slot: a status mark, spinner, PR badge or pencil.
  final Widget leading;

  /// The space display name.
  final String label;

  /// Whether this is the route's selected space.
  final bool selected;

  /// The space's live status (drives the trailing indicator).
  final SpaceStatus status;

  /// Whether the space has unseen agent messages.
  final bool unread;

  /// Whether the leading slot already shows the running signal.
  final bool leadingHandlesRunning;

  /// Width of the leading column. Conversations use a narrower slot.
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

  /// Second line under [label]. A branch name in the global sidebar.
  final String? subtitle;

  /// Short trailing caption, such as a relative time on an activity row.
  final String? trailingLabel;

  /// Optional conversation count chip. Null hides it.
  final int? count;

  /// Hover-revealed overflow actions. Null hides the trigger.
  final List<CcMenuItem>? menuItems;

  /// Accessible name for [menuItems]' icon-only trigger.
  final String? menuSemanticLabel;

  /// Tap handler.
  final VoidCallback onPress;

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

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final fg = _filled
        ? t.accentOn
        : (muted ? t.textTertiary : t.textSecondary);
    final caption = _filled
        ? t.accentOn.withValues(alpha: 0.72)
        : t.textTertiary;
    final transitioning = CcSidebarScope.transitioningOf(context) ?? false;
    final hasMenu =
        menuItems != null &&
        menuItems!.isNotEmpty &&
        menuSemanticLabel != null &&
        !transitioning;

    return CcTappable(
      onPressed: onPress,
      borderRadius: AppRadii.brSm,
      semanticLabel: label,
      focusRingColor: _filled ? t.accentOn : null,
      builder: (context, states) {
        return TweenAnimationBuilder<Color?>(
          duration: CcMotion.fast,
          curve: CcMotion.standard,
          tween: ColorTween(end: fg),
          builder: (context, animatedFg, _) {
            return SpaceRowLayout(
              tokens: t,
              leading: leading,
              label: label,
              contentColor: animatedFg ?? fg,
              caption: caption,
              filled: _filled,
              indent: indent,
              cardInset: cardInset,
              transitioning: transitioning,
              hasMenu: hasMenu,
              showMenu: hasMenu && _overflowRevealed(states),
              status: status,
              unread: unread,
              leadingHandlesRunning: leadingHandlesRunning,
              markSlot: markSlot,
              markGap: markGap,
              labelFontSize: labelFontSize,
              extent: extent,
              muted: muted,
              hoverColor: _hoverFill(
                t,
                states,
                fluidActive: CcFluidHover.isItemActive(context),
              ),
              subtitle: subtitle,
              trailingLabel: trailingLabel,
              count: count,
              menuItems: menuItems,
              menuSemanticLabel: menuSemanticLabel,
            );
          },
        );
      },
    );
  }
}

/// Leading mark for a conversation row.
///
/// A spinner while an agent is working, a filled accent dot when the
/// conversation has unseen messages, and a hollow dot when it is idle.
Widget conversationActivityMark({required bool running, required bool unread}) {
  if (running) {
    return const CcSpinner(size: kConversationMarkSlot, strokeWidth: 1.5);
  }
  if (unread) {
    return const ConversationUnreadMark();
  }
  return const SpaceStatusMark();
}

/// Filled accent dot: this conversation has unseen messages.
class ConversationUnreadMark extends StatelessWidget {
  /// Creates a [ConversationUnreadMark].
  const ConversationUnreadMark({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: t.accent, shape: BoxShape.circle),
    );
  }
}

/// Hollow mark for a space that has no pull request yet.
class SpaceStatusMark extends StatelessWidget {
  /// Creates a [SpaceStatusMark].
  const SpaceStatusMark({super.key});

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: t.textTertiary, width: 1.5),
      ),
    );
  }
}
