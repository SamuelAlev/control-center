import 'package:flutter/services.dart';

/// The cell a key moves focus to in a 7-column, 42-cell month grid, or null
/// when [event] is not a grid navigation key, so it reaches the app.
///
/// Left and Right move a day and follow the reading direction ([rtl] flips
/// them), Up and Down a week, Home and End to the ends of the week row. The
/// target stays inside the grid. A chord with a modifier belongs to the app.
int? monthGridKeyTarget(KeyEvent event, int current, {required bool rtl}) {
  final keys = HardwareKeyboard.instance;
  if (event is KeyUpEvent ||
      keys.isControlPressed ||
      keys.isAltPressed ||
      keys.isMetaPressed ||
      keys.isShiftPressed) {
    return null;
  }
  final ahead = rtl ? -1 : 1;
  final target = switch (event.logicalKey) {
    LogicalKeyboardKey.arrowRight => current + ahead,
    LogicalKeyboardKey.arrowLeft => current - ahead,
    LogicalKeyboardKey.arrowDown => current + 7,
    LogicalKeyboardKey.arrowUp => current - 7,
    LogicalKeyboardKey.home => current - current % 7,
    LogicalKeyboardKey.end => current - current % 7 + 6,
    _ => null,
  };
  return target?.clamp(0, 41);
}
