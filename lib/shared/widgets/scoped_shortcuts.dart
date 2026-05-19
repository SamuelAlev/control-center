import 'package:control_center/core/constants/keybindings.dart';
import 'package:control_center/core/keybindings/keybinding_dispatcher.dart';
import 'package:control_center/core/keybindings/keybinding_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Contributes a screen's command handlers to the central
/// [KeybindingDispatcher] while this widget is mounted.
///
/// Each entry in [bindings] maps a [Keybinding.id] (defined in
/// [KeybindingRegistry]) to the callback to run when the shortcut fires. The
/// dispatcher owns the actual key combination, the `when` clause, and conflict
/// resolution — this widget only declares *which commands are available right
/// now*, registering on mount and unregistering on dispose. Unlike the old
/// focus-based approach, dispatch no longer depends on this subtree holding
/// keyboard focus, so shortcuts fire reliably regardless of where focus sits.
///
/// Conditional availability still works the natural way: include a binding in
/// [bindings] only when its action is valid (e.g. spread `if (data != null)`),
/// and the dispatcher treats a command with no handler as inactive.
class ScopedShortcuts extends ConsumerStatefulWidget {
  /// Creates a [ScopedShortcuts].
  const ScopedShortcuts({
    super.key,
    required this.scope,
    required this.bindings,
    required this.child,
  });

  /// The keybinding scope this screen owns (e.g. `/newsfeed`). Informational —
  /// the dispatcher derives scope/priority from the registry — but kept so call
  /// sites read clearly and so debug builds can flag stray binding ids.
  final String scope;

  /// Maps [Keybinding.id] to the callback executed when the shortcut fires.
  final Map<String, VoidCallback> bindings;

  /// The child subtree to wrap.
  final Widget child;

  @override
  ConsumerState<ScopedShortcuts> createState() => _ScopedShortcutsState();
}

class _ScopedShortcutsState extends ConsumerState<ScopedShortcuts> {
  /// Binding ids already flagged as unknown, so the debug warning fires once
  /// per id per session rather than on every screen mount.
  static final Set<String> _warnedUnknownIds = {};

  KeybindingScopeHandle? _handle;

  @override
  void initState() {
    super.initState();
    _assertKnownBindings();
    final dispatcher = ref.read(keybindingDispatcherProvider);
    _handle = dispatcher.registerScope(widget.bindings);
  }

  @override
  void didUpdateWidget(covariant ScopedShortcuts oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Callbacks are rebuilt as fresh closures each build, so always push the
    // latest map. The dispatcher only touches the OS hotkey set when the
    // active combinations actually change, so steady-state rebuilds are cheap.
    _handle?.update(widget.bindings);
  }

  @override
  void dispose() {
    _handle?.dispose();
    _handle = null;
    super.dispose();
  }

  void _assertKnownBindings() {
    assert(() {
      for (final id in widget.bindings.keys) {
        if (KeybindingRegistry.find(id) == null && _warnedUnknownIds.add(id)) {
          debugPrint(
            'ScopedShortcuts(${widget.scope}): no Keybinding registered for '
            '"$id" — it will never fire. Add it to KeybindingRegistry.',
          );
        }
      }
      return true;
    }());
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
