import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';

/// Tracks whether the user is currently driving the UI by keyboard or by
/// pointer, so focus rings can mimic the browser's `:focus-visible` — visible
/// for keyboard traversal, hidden for a mouse/touch interaction.
///
/// Flutter's `FocusManager.highlightMode` is no help here: on desktop it lumps
/// mouse and keyboard together as `FocusHighlightMode.traditional`, so it can't
/// tell a click from a Tab. We replicate the well-known `focus-visible`
/// polyfill heuristic instead — any key-down (without a Cmd/Ctrl/Alt modifier,
/// so app shortcuts like Cmd+S don't arm the ring) means "keyboard", and any
/// pointer-down means "pointer". A `FocusRing` samples this at the instant a
/// node gains focus.
class FocusModality {
  FocusModality._() {
    GestureBinding.instance.pointerRouter.addGlobalRoute(_handlePointer);
    HardwareKeyboard.instance.addHandler(_handleKey);
  }

  /// The process-wide tracker. Registers its global listeners on first use.
  static final FocusModality instance = FocusModality._();

  bool _keyboard = false;

  /// Whether the most recent qualifying interaction came from the keyboard.
  bool get isKeyboard => _keyboard;

  void _handlePointer(PointerEvent event) {
    if (event is PointerDownEvent) {
      _keyboard = false;
    }
  }

  bool _handleKey(KeyEvent event) {
    if (event is! KeyDownEvent) {
      return false;
    }
    final keyboard = HardwareKeyboard.instance;
    // Cmd/Ctrl/Alt chords are app shortcuts, not focus traversal — pressing
    // Cmd+Enter to save shouldn't arm the focus ring. Shift is allowed so
    // Shift+Tab (reverse traversal) still counts as keyboard.
    if (keyboard.isMetaPressed ||
        keyboard.isControlPressed ||
        keyboard.isAltPressed) {
      return false;
    }
    _keyboard = true;
    return false; // Never consume the event.
  }
}
