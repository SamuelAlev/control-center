import 'package:flutter/services.dart';

/// Releases pressed keys by synthesizing [KeyUpEvent]s without detaching
/// [HardwareKeyboard] handlers.
///
/// macOS can lose key-ups across window focus loss or for a non-modifier
/// released while ⌘ is held: https://github.com/flutter/flutter/issues/136419.
/// In-app focus changes preserve modifiers because they can still be held
/// for the next shortcut. Window deactivation and inconsistent-key recovery
/// leave [preserveModifiers] false to reset all pressed keys.
void releaseStuckKeys({bool preserveModifiers = false}) {
  final keyboard = HardwareKeyboard.instance;
  // `physicalKeysPressed` returns a fresh copy, so releasing while iterating
  // is safe.
  for (final physicalKey in keyboard.physicalKeysPressed) {
    if (preserveModifiers && _modifierKeys.contains(physicalKey)) {
      continue;
    }
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

const _modifierKeys = <PhysicalKeyboardKey>[
  PhysicalKeyboardKey.metaLeft,
  PhysicalKeyboardKey.metaRight,
  PhysicalKeyboardKey.controlLeft,
  PhysicalKeyboardKey.controlRight,
  PhysicalKeyboardKey.shiftLeft,
  PhysicalKeyboardKey.shiftRight,
  PhysicalKeyboardKey.altLeft,
  PhysicalKeyboardKey.altRight,
];
