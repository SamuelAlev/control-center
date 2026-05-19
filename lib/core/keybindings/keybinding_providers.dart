import 'package:control_center/core/keybindings/keybinding_dispatcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app-wide [KeybindingDispatcher].
///
/// Created once and kept alive for the app's lifetime. Reading it lazily
/// initialises the `hotkey_manager` hardware-keyboard handler and the
/// focus observer. Registration widgets (AppShortcuts, ScopedShortcuts,
/// SettingsShortcuts) read this provider to contribute command handlers, and
/// the shell feeds it the current route via [KeybindingDispatcher.setRoute].
///
/// On web the dispatcher cannot touch `hotkey_manager` at all — constructing
/// its singleton listens on a platform `EventChannel` that has no web
/// implementation and throws. So on web it skips OS registration and instead
/// feeds strokes from a `HardwareKeyboard` handler
/// (`listenToHardwareKeyboard`), which still resolves chords, routes commands,
/// and consumes only keys that match an active binding. On desktop it uses
/// `hotkey_manager` as before.
final keybindingDispatcherProvider = Provider<KeybindingDispatcher>((ref) {
  final dispatcher = KeybindingDispatcher(
    registerWithOs: !kIsWeb,
    listenToHardwareKeyboard: kIsWeb,
  );
  ref.onDispose(dispatcher.dispose);
  return dispatcher;
});
