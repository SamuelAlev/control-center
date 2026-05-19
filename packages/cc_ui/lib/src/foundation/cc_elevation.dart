import 'package:cc_ui/src/tokens/app_shadows.dart';
import 'package:flutter/widgets.dart';

/// Elevation tokens — the design system's two real shadow levels plus a
/// relative z-order scale for stacked overlays.
///
/// Per DESIGN.md depth is rare and warm: in-flow surfaces are flat with a
/// hairline border; only genuinely floating surfaces (popovers, drawers,
/// dialogs, toasts, hover cards) carry the golden shadow. The integer
/// priorities document the intended stacking order of overlay entries.
abstract final class CcElevation {
  const CcElevation._();

  /// Z-order: tooltips sit just above content.
  static const int tooltip = 100;

  /// Z-order: popovers / dropdowns.
  static const int popover = 200;

  /// Z-order: popovers / dropdowns (alias).
  static const int dropdown = 200;

  /// Z-order: context menus.
  static const int menu = 300;

  /// Z-order: toasts.
  static const int toast = 400;

  /// Z-order: modal dialogs (scrim + content).
  static const int dialog = 500;

  /// The signature warm "golden float" — popovers, dialogs, drawers, toasts.
  static const List<BoxShadow> floating = AppShadows.golden;

  /// A subtler lift — hover cards, sticky chrome.
  static const List<BoxShadow> raised = AppShadows.soft;
}
