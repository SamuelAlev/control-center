import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_native_text_menu.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_fonts.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/widgets.dart';

const Color _transparent = Color(0x00000000);

/// The labels a [CcTextContextMenu] renders.
///
/// English by default, like the rest of cc_ui's built-in copy. This is the
/// FALLBACK menu's vocabulary only — on a host that presents the real OS menu
/// the titles come from the platform, already localised.
@immutable
class CcTextContextMenuLabels {
  /// Creates a [CcTextContextMenuLabels].
  const CcTextContextMenuLabels({
    this.cut = 'Cut',
    this.copy = 'Copy',
    this.paste = 'Paste',
    this.selectAll = 'Select all',
  });

  /// Removes the selection and puts it on the clipboard.
  final String cut;

  /// Puts the selection on the clipboard.
  final String copy;

  /// Inserts the clipboard at the caret.
  final String paste;

  /// Selects the whole field.
  final String selectAll;

  /// The label for [action].
  String of(CcTextMenuAction action) => switch (action) {
    CcTextMenuAction.cut => cut,
    CcTextMenuAction.copy => copy,
    CcTextMenuAction.paste => paste,
    CcTextMenuAction.selectAll => selectAll,
  };
}

/// The drawn right-click menu for an editable field — the FALLBACK for hosts
/// that cannot present the operating system's own.
///
/// Every cc_ui text field routes right-click through
/// [CcTextSelectionGestureDetectorBuilder], which asks the host for its real
/// menu first ([CcNativeTextMenu] on macOS; the browser's own on web). This is
/// what remains for Windows, Linux, the widget catalogue's runner and tests —
/// hosts where the alternative is no menu at all.
///
/// It is deliberately NOT Material's `AdaptiveTextSelectionToolbar`, which
/// cc_ui cannot use (a Material component, dragging in ink and a Material
/// `Theme`).
class CcTextContextMenu extends StatelessWidget {
  /// Creates a [CcTextContextMenu] for [editableTextState].
  const CcTextContextMenu({
    super.key,
    required this.editableTextState,
    this.labels = const CcTextContextMenuLabels(),
  });

  /// The field the menu acts on.
  final EditableTextState editableTextState;

  /// The entry labels.
  final CcTextContextMenuLabels labels;

  /// Inset kept between the menu and the edges of the overlay.
  static const double _inset = 8;

  /// Minimum width, so a one-entry menu is not a sliver.
  static const double _minWidth = 168;

  @override
  Widget build(BuildContext context) {
    final theme = context.ccTheme;
    final t = theme?.tokens ?? DesignSystemTokens.light();
    final card = CcCardTokens.panel(t);
    final state = editableTextState;
    final actions = ccTextMenuActionsFor(state);
    if (actions.isEmpty) {
      return const SizedBox.shrink();
    }

    return CustomSingleChildLayout(
      delegate: _CcTextContextMenuLayout(
        state.contextMenuAnchors.primaryAnchor,
      ),
      // A selection toolbar is presented into the ROOT overlay, above any
      // route's `Material` — so the only ambient `DefaultTextStyle` is
      // `WidgetsApp`'s error fallback: 48px text with a double yellow
      // underline, which every row would otherwise inherit (and bleed the
      // underline through, since copyWith leaves `decoration` unset). Supply a
      // complete style here, the same way `showCcDialog` does.
      child: DefaultTextStyle(
        style: CcFonts.ui(
          family: theme?.fontFamily,
          textStyle: CcTypography.bodySm.copyWith(
            color: t.textPrimary,
            decoration: TextDecoration.none,
          ),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minWidth: _minWidth),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: card.bg,
              borderRadius: AppRadii.brLg,
              border: Border.all(color: card.border),
              boxShadow: CcElevation.floating,
            ),
            child: ClipRRect(
              borderRadius: AppRadii.brLg,
              // Edge-to-edge rows: no panel padding, so the hover wash spans
              // the full width of the menu (the CcMenu panel treatment).
              child: IntrinsicWidth(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (final action in actions)
                      _CcTextMenuRow(
                        label: labels.of(action),
                        onPressed: () {
                          performCcTextMenuAction(state, action);
                          // The delegate methods hide the toolbar themselves
                          // for a toolbar-caused change; this covers the ones
                          // that only do so on some platforms.
                          state.hideToolbar();
                        },
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// The fallback [EditableText.contextMenuBuilder] for cc_ui fields.
Widget ccTextContextMenuBuilder(
  BuildContext context,
  EditableTextState editableTextState,
) => CcTextContextMenu(editableTextState: editableTextState);

class _CcTextMenuRow extends StatelessWidget {
  const _CcTextMenuRow({required this.label, required this.onPressed});

  final String label;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;

    return CcTappable(
      onPressed: onPressed,
      borderRadius: AppRadii.brSm,
      showFocusRing: false,
      canRequestFocus: false,
      semanticLabel: label,
      builder: (context, states) {
        final pressed = states.contains(WidgetState.pressed);
        final wash = pressed
            ? t.hoverStrong
            : states.contains(WidgetState.hovered)
            ? t.hover
            : _transparent;

        return Container(
          constraints: const BoxConstraints(minHeight: 32),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(color: wash),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.xs,
          ),
          child: Text(label, maxLines: 1, overflow: TextOverflow.ellipsis),
        );
      },
    );
  }
}

/// Places the menu at the pointer, clamped inside the overlay with an 8px
/// inset — the same treatment `showCcMenuAt` gives a right-click menu.
class _CcTextContextMenuLayout extends SingleChildLayoutDelegate {
  const _CcTextContextMenuLayout(this.anchor);

  final Offset anchor;

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      constraints
          .deflate(const EdgeInsets.all(CcTextContextMenu._inset))
          .loosen();

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    const inset = CcTextContextMenu._inset;
    final dx = anchor.dx.clamp(
      inset,
      (size.width - childSize.width - inset).clamp(inset, size.width),
    );
    final dy = anchor.dy.clamp(
      inset,
      (size.height - childSize.height - inset).clamp(inset, size.height),
    );
    return Offset(dx, dy);
  }

  @override
  bool shouldRelayout(_CcTextContextMenuLayout oldDelegate) =>
      oldDelegate.anchor != anchor;
}
