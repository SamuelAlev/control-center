import 'package:flutter/widgets.dart';

/// Marks a subtree as a custom text-input surface for the keybinding dispatcher.
/// Surfaces that implement `TextInputClient` themselves (the xterm terminal's
/// `TerminalView`) contain no [EditableText], so without this marker the dispatcher treats
/// them as "not typing": every `!textInputFocus` binding stays active and on macOS desktop
/// unmatched keys are consumed just to silence the system alert — which reports them
/// handled, so AppKit never forwards them to the IME and the surface's input connection
/// never receives a character (a terminal you cannot type into).
class TextInputSurface extends StatelessWidget {
  /// Creates a [TextInputSurface] marker around [child].
  const TextInputSurface({super.key, required this.child});

  /// The custom input surface (must contain the focused node while typing).
  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}
