import 'package:flutter/services.dart';

/// Releases every key [HardwareKeyboard] still believes is pressed by synthesizing a
/// [KeyUpEvent] for it.
/// The macOS engine frequently loses a KeyUp (a key held across window focus loss, or a
/// non-modifier key released while ⌘ is held —
/// https://github.com/flutter/flutter/issues/136419).
/// The stale entry then corrupts every subsequent stroke ("j" reads as "⌘J") and makes text
/// fields see ghost repeats, so callers reset the pressed state at recovery points: window
/// deactivation, a text field gaining focus, or the framework flagging an inconsistent key
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
