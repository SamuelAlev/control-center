import 'package:control_center/core/keybindings/keybinding_dispatcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app-wide [KeybindingDispatcher].
///
/// Created once and kept alive for the app's lifetime. Reading it lazily
/// initialises the `hotkey_manager` hardware-keyboard handler and the
/// focus observer. Registration widgets (AppShortcuts, ScopedShortcuts,
/// SettingsShortcuts) read this provider to contribute command handlers, and
/// the shell feeds it the current route via [KeybindingDispatcher.setRoute].
final keybindingDispatcherProvider = Provider<KeybindingDispatcher>((ref) {
  final dispatcher = KeybindingDispatcher();
  ref.onDispose(dispatcher.dispose);
  return dispatcher;
});
