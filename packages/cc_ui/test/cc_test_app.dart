import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Minimal ancestors cc_ui widgets need in tests, with no Material, Riverpod, or
/// l10n: a [CcTheme] for tokens, plus Directionality, MediaQuery, a default text
/// style, an [Overlay] so overlay-based components work, and the default
/// keyboard shortcuts and traversal policy of a `WidgetsApp`.
///
/// Pass [textDirection] as [TextDirection.rtl] to exercise a component's RTL
/// mirroring.
Widget ccTestApp(
  Widget child, {
  CcThemeData? theme,
  TextDirection textDirection = TextDirection.ltr,
}) {
  return CcTheme(
    data: theme ?? CcThemeData.light(),
    child: Directionality(
      textDirection: textDirection,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
          // The keyboard layer a WidgetsApp supplies: Tab and Shift+Tab
          // traverse, arrows move directionally, and one reading-order group
          // covers the tree. Without it no key moves focus in a test.
          child: Shortcuts(
            shortcuts: WidgetsApp.defaultShortcuts,
            child: Actions(
              actions: WidgetsApp.defaultActions,
              child: FocusTraversalGroup(
                policy: ReadingOrderTraversalPolicy(),
                child: Overlay(
                  initialEntries: [OverlayEntry(builder: (_) => child)],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
