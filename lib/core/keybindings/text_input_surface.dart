import 'package:flutter/widgets.dart';

/// Marks a subtree as a custom text-input surface for the keybinding
/// dispatcher.
///
/// The dispatcher derives its `textInputFocus` context by walking the focused
/// node's ancestors for an [EditableText] — the widget every Flutter text
/// field is built on. Surfaces that implement `TextInputClient` themselves
/// (the xterm terminal's `TerminalView`) contain no [EditableText], so without
/// this marker the dispatcher treats them as "not typing": every
/// `!textInputFocus` binding stays active, and on macOS desktop unmatched keys
/// are consumed just to silence the system alert — which reports them handled,
/// so AppKit never forwards them to the IME and the surface's input connection
/// never receives a character (a terminal you cannot type into).
///
/// Wrap the focusable input surface in a [TextInputSurface] and the dispatcher
/// treats it exactly like a focused text field: `!textInputFocus` bindings
/// deactivate and unmatched keys fall through to the IME.
class TextInputSurface extends StatelessWidget {
  /// Creates a [TextInputSurface] marker around [child].
  const TextInputSurface({super.key, required this.child});

  /// The custom input surface (must contain the focused node while typing).
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
