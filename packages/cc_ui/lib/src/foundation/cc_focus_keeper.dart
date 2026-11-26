import 'package:flutter/widgets.dart';

/// Marks a surface that keeps keyboard focus while the person clicks controls
/// around it: a terminal, a canvas that types into a guest, an embedded
/// editor.
///
/// A [CcTappable] normally takes focus when it is clicked, so the next Tab
/// starts from the control the person just used. A surface under a
/// [CcFocusKeeper] is the exception: while focus sits inside it, clicking a
/// button elsewhere activates the button and leaves focus where it was. Text
/// inputs ([EditableText]) behave this way without a marker, since their caret
/// already shows where typing goes.
class CcFocusKeeper extends StatelessWidget {
  /// Marks [child] as a surface that keeps focus.
  const CcFocusKeeper({super.key, required this.child});

  /// The surface.
  final Widget child;

  /// Whether [node] sits in a text input or under a [CcFocusKeeper], and so
  /// keeps focus when a control elsewhere is clicked.
  static bool holds(FocusNode? node) {
    final context = node?.context;
    if (context == null) {
      return false;
    }
    if (context.widget is EditableText || context.widget is CcFocusKeeper) {
      return true;
    }
    var held = false;
    context.visitAncestorElements((element) {
      final widget = element.widget;
      if (widget is EditableText || widget is CcFocusKeeper) {
        held = true;
        return false;
      }
      return true;
    });
    return held;
  }

  @override
  Widget build(BuildContext context) => child;
}
