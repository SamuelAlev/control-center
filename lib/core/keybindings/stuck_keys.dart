import 'package:flutter/services.dart';

/// Releases every key [HardwareKeyboard] still believes is pressed by
/// synthesizing a [KeyUpEvent] for it.
///
/// The macOS engine frequently loses a KeyUp (a key held across window focus
/// loss, or a non-modifier key released while ⌘ is held —
/// https://github.com/flutter/flutter/issues/136419). The stale entry then
/// corrupts every subsequent stroke ("j" reads as "⌘J") and makes text fields
/// see ghost repeats, so callers reset the pressed state at recovery points:
/// window deactivation, a text field gaining focus, or the framework flagging
/// an inconsistent key event.
///
/// This helper exists because the obvious reset — `HardwareKeyboard.clearState()`
/// — is a **test-hermeticity API that also detaches every registered key
/// handler**: the keybinding dispatcher, the diff view's search keys,
/// push-to-talk, focus-ring modality tracking, Material's menu shortcuts.
/// One production call permanently killed every shortcut in the app — each
/// later press fell through unhandled and rang the macOS system alert.
/// Synthesizing key-ups clears the same stuck state through the public event
/// path and leaves handlers attached; modifier flags resync from the OS bits
/// of the next real event. The ban on `clearState()` in production code is
/// enforced by `test/core/keybindings/hardware_keyboard_hygiene_test.dart`.
void releaseStuckKeys() {
  final keyboard = HardwareKeyboard.instance;
  // `physicalKeysPressed` returns a fresh copy, so releasing while iterating
  // is safe.
  for (final physicalKey in keyboard.physicalKeysPressed) {
    final logicalKey = keyboard.lookUpLayout(physicalKey);
    if (logicalKey == null) {
      continue;
    }
    keyboard.handleKeyEvent(
      KeyUpEvent(
        physicalKey: physicalKey,
        logicalKey: logicalKey,
        timeStamp: Duration.zero,
        synthesized: true,
      ),
    );
  }
}
