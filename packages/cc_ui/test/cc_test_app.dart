import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';

/// Minimal ancestors cc_ui widgets need in tests, with no Material, Riverpod, or
/// l10n: a [CcTheme] for tokens, plus Directionality, MediaQuery, a default text
/// style, and an [Overlay] so overlay-based components work.
Widget ccTestApp(Widget child, {CcThemeData? theme}) {
  return CcTheme(
    data: theme ?? CcThemeData.light(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: MediaQuery(
        data: const MediaQueryData(),
        child: DefaultTextStyle(
          style: const TextStyle(fontSize: 14, color: Color(0xFF000000)),
          child: Overlay(
            initialEntries: [OverlayEntry(builder: (_) => child)],
          ),
        ),
      ),
    ),
  );
}
