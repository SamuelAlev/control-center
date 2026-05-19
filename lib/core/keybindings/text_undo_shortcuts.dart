import 'package:flutter/services.dart' show LogicalKeyboardKey;
import 'package:flutter/widgets.dart';

/// Marks a keystroke as owned by the keybinding dispatcher's text-undo bridge
/// (see `KeybindingDispatcher._bridgeTextUndoRedo`).
///
/// Installed by [installTextUndoShadow] as a `Shortcuts` map INSIDE
/// `WidgetsApp`'s `DefaultTextEditingShortcuts` (i.e. via `MaterialApp.builder`,
/// which wraps the router). The nearest matching `Shortcuts` wins, so the
/// framework's own ⌘Z → `UndoTextIntent` mapping is never consulted — the
/// dispatcher, whose hardware-keyboard handlers run before the focus tree,
/// performs the actual undo/redo by invoking the intents against the focused
/// field. Without this shadow, one keypress in a runtime where both paths work
/// would undo twice.
class ShadowTextUndoIntent extends Intent {
  /// Creates the shadow intent.
  const ShadowTextUndoIntent();
}

class _ShadowTextUndoAction extends Action<ShadowTextUndoIntent> {
  // The real undo/redo was already performed by the dispatcher's bridge (a
  // HardwareKeyboard handler, which runs before focus-tree dispatch). This
  // action only decides what the focus tree reports for the keystroke.
  @override
  Object? invoke(ShadowTextUndoIntent intent) => null;

  @override
  bool isEnabled(ShadowTextUndoIntent intent) => true;

  @override
  KeyEventResult toKeyEventResult(
    ShadowTextUndoIntent intent, [
    Object? invokeResult,
  ]) {
    final ctx = FocusManager.instance.primaryFocus?.context;
    final overEditableText =
        ctx?.findAncestorWidgetOfExactType<EditableText>() != null;
    // Over a real field the stroke is fully accounted for — claim it, which
    // stops the walk (no second undo from DefaultTextEditingShortcuts) AND
    // reports the key handled so the engine never redispatches it into AppKit
    // (the redispatch is what rings the macOS system alert). Over a custom
    // input surface (the xterm terminal) the bridge declines to act, so stay
    // out of the way: report not-handled and let the event reach the surface's
    // input connection.
    return overEditableText
        ? KeyEventResult.handled
        : KeyEventResult.skipRemainingHandlers;
  }
}

/// Wraps [child] with the undo/redo stroke shadow (see [ShadowTextUndoIntent]).
///
/// Covers every platform's text undo/redo combination: ⌘Z/⇧⌘Z (Apple),
/// Ctrl+Z/Ctrl+Shift+Z/Ctrl+Y (Windows/Linux).
Widget installTextUndoShadow(Widget child) {
  return Actions(
    actions: {ShadowTextUndoIntent: _ShadowTextUndoAction()},
    child: Shortcuts(
      shortcuts: const <ShortcutActivator, Intent>{
        // Apple platforms.
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true):
            ShadowTextUndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true):
            ShadowTextUndoIntent(),
        // Windows / Linux / web on non-Apple hosts.
        SingleActivator(LogicalKeyboardKey.keyZ, control: true):
            ShadowTextUndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true):
            ShadowTextUndoIntent(),
        SingleActivator(LogicalKeyboardKey.keyY, control: true):
            ShadowTextUndoIntent(),
      },
      child: child,
    ),
  );
}
