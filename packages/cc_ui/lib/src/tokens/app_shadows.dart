import 'package:flutter/widgets.dart';

/// Warm "golden-hour" elevation.
///
/// Depth is rare and warm. Shadows are always amber-tinted
/// (`rgba(127, 99, 21, …)` — amber-black, never cool gray) and offset to the
/// lower-LEFT (negative X), as if lit by late-afternoon sun from the right.
/// Reserved for genuinely floating surfaces: popovers, drawers, toasts, hover
/// cards, product windows. In-flow panels separate with a hairline border, not
/// a shadow.
abstract final class AppShadows {
  const AppShadows._();

  /// Golden float — the signature multi-layer floating elevation
  /// (`--shadow-golden`). Use for drawers, popovers, dialogs, toasts.
  static const List<BoxShadow> golden = [
    BoxShadow(color: Color(0x1F7F6315), offset: Offset(-8, 16), blurRadius: 39),
    BoxShadow(color: Color(0x147F6315), offset: Offset(-28, 56), blurRadius: 64),
    BoxShadow(color: Color(0x0A7F6315), offset: Offset(-64, 120), blurRadius: 88),
  ];

  /// Soft — a subtle warm lift (`--shadow-soft`) for cards on hover and for
  /// sticky chrome that must read as slightly raised.
  static const List<BoxShadow> soft = [
    BoxShadow(color: Color(0x0D7F6315), offset: Offset(0, 1), blurRadius: 2),
    BoxShadow(color: Color(0x0D7F6315), offset: Offset(-2, 6), blurRadius: 18),
  ];
}
