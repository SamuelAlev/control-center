import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// The empty background of a routed page.
///
/// It is an opaque tap target so taps in transparent areas don't fall through
/// to the route's underlying [ModalBarrier], which plays the macOS alert
/// sound on every tap (Flutter's MaterialPageRoute defaults to
/// barrierDismissible: false). It must live inside the inner navigator's
/// modal scope to win the gesture arena against the barrier; wrapping at the
/// shell level isn't sufficient because ShellRoute creates an inner Navigator
/// whose barrier sits below this layer.
///
/// A click on the background ends typing, matching macOS click-outside: a
/// text field, or a surface under a [CcFocusKeeper] (a terminal, a rig
/// canvas), gives up focus when the click lands outside it. A focused button
/// or row keeps its focus, so the next Tab continues from it instead of from
/// the top of the page.
class RouteBackground extends StatelessWidget {
  /// Wraps a route's [child].
  const RouteBackground({super.key, required this.child});

  /// The page.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapUp: (details) => _endTypingOutside(details.globalPosition),
      child: child,
    );
  }

  static void _endTypingOutside(Offset position) {
    final focused = FocusManager.instance.primaryFocus;
    if (focused == null || !CcFocusKeeper.holds(focused)) {
      return;
    }
    final surface = _surfaceRect(focused);
    if (surface != null && surface.contains(position)) {
      return;
    }
    focused.unfocus();
  }

  /// The global bounds of the text field or keeper that holds [node].
  static Rect? _surfaceRect(FocusNode node) {
    final context = node.context;
    if (context == null) {
      return null;
    }
    Element? surface;
    bool isSurface(Widget widget) =>
        widget is EditableText || widget is CcFocusKeeper;
    if (isSurface(context.widget)) {
      surface = context as Element;
    } else {
      context.visitAncestorElements((element) {
        if (isSurface(element.widget)) {
          surface = element;
          return false;
        }
        return true;
      });
    }
    final box = surface?.findRenderObject();
    if (box is! RenderBox || !box.hasSize || !box.attached) {
      return null;
    }
    return MatrixUtils.transformRect(
      box.getTransformTo(null),
      Offset.zero & box.size,
    );
  }
}
