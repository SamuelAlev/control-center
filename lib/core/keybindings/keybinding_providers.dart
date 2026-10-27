import 'package:cc_domain/features/telemetry/telemetry.dart';
import 'package:control_center/core/keybindings/keybinding_dispatcher.dart';
import 'package:control_center/core/providers/analytics_providers.dart';
import 'package:flutter/services.dart' show HardwareKeyboard;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The app-wide [KeybindingDispatcher].
///
/// Created once and kept alive for the app's lifetime. Reading it lazily
/// attaches the `HardwareKeyboard` handler, the focus observer and the
/// app-lifecycle observer. Registration widgets (AppShortcuts,
/// ScopedShortcuts, SettingsShortcuts) read this provider to contribute
/// command handlers and the shell feeds it the current route via
/// [KeybindingDispatcher.setRoute].
///
/// Desktop and web share the same dispatch path: the dispatcher observes
/// [HardwareKeyboard] directly and consumes only keys that match a currently
/// active binding, so typing, focus-tree shortcuts and (on web) browser
/// accelerators are untouched.
final keybindingDispatcherProvider = Provider<KeybindingDispatcher>((ref) {
  final dispatcher = KeybindingDispatcher()
    // Binding IDs are static command names, never entity-bearing.
    ..onFired = (command) => ref.track(
      AnalyticsEvents.commandExecuted(source: 'keybinding', command: command),
    );
  ref.onDispose(dispatcher.dispose);
  return dispatcher;
});
