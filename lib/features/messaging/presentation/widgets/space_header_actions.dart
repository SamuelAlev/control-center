import 'dart:math' as math;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';

/// One header action, rendered inline as an icon button or folded into the
/// overflow menu when the pane is too narrow.
@immutable
class SpaceHeaderAction {
  /// Creates a [SpaceHeaderAction].
  const SpaceHeaderAction({
    required this.icon,
    required this.label,
    required this.foldRank,
    required this.onPressed,
    this.color,
    this.selected = false,
  });

  /// Glyph for the inline button and the menu row.
  final IconData icon;

  /// Tooltip, accessible name and menu row label.
  final String label;

  /// Lower ranks fold into the overflow menu first.
  final int foldRank;

  /// Runs the action.
  final VoidCallback onPressed;

  /// Active-state icon tint (inline only; the menu row uses [selected]).
  final Color? color;

  /// Whether the action is in its active state (checked in the menu row).
  final bool selected;

  /// Gap before each inline action and the "More" button.
  static const double gap = 4;

  /// Inline icon button plus its leading gap.
  static const double slotWidth = 40 + gap;

  /// Splits [actions] into what fits [budget] inline and what folds into the
  /// overflow menu, keeping visual order on both sides. Once anything folds,
  /// the "More" button itself takes a slot.
  static ({List<SpaceHeaderAction> inline, List<SpaceHeaderAction> folded})
  split(List<SpaceHeaderAction> actions, {required double budget}) {
    if (actions.length * slotWidth <= budget) {
      return (inline: actions, folded: const []);
    }
    final fit = math.max(0, (budget / slotWidth).floor() - 1);
    final byKeep = [...actions]
      ..sort((a, b) => b.foldRank.compareTo(a.foldRank));
    final kept = byKeep.take(fit).toSet();
    return (
      inline: [
        for (final a in actions)
          if (kept.contains(a)) a,
      ],
      folded: [
        for (final a in actions)
          if (!kept.contains(a)) a,
      ],
    );
  }
}

/// The "More" icon button holding the header actions that did not fit.
class SpaceHeaderMoreButton extends StatefulWidget {
  /// Creates a [SpaceHeaderMoreButton].
  const SpaceHeaderMoreButton({super.key, required this.actions});

  /// The folded actions, in visual order.
  final List<SpaceHeaderAction> actions;

  @override
  State<SpaceHeaderMoreButton> createState() => _SpaceHeaderMoreButtonState();
}

class _SpaceHeaderMoreButtonState extends State<SpaceHeaderMoreButton> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    // The trigger is a real button driving the controller, so the menu does
    // not wrap it in a second, competing tappable.
    return CcMenu(
      controller: _controller,
      toggleOnTargetTap: false,
      targetAnchor: AlignmentDirectional.bottomEnd,
      followerAnchor: AlignmentDirectional.topEnd,
      semanticLabel: l10n.moreLabel,
      items: [
        for (final a in widget.actions)
          CcMenuItem(
            label: a.label,
            icon: a.icon,
            selected: a.selected,
            onSelected: a.onPressed,
          ),
      ],
      target: CcTooltip(
        targetAnchor: Alignment.bottomCenter,
        followerAnchor: Alignment.topCenter,
        message: l10n.moreLabel,
        child: CcIconButton(
          icon: AppIcons.moreHorizontal,
          semanticLabel: l10n.moreLabel,
          onPressed: _controller.toggle,
        ),
      ),
    );
  }
}
