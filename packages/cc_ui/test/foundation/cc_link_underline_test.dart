import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('withLinkUnderline', () {
    const link = Color(0xFF3366FF);

    test(
      'adds an underline softened to a translucent tone of the link colour',
      () {
        final style = const TextStyle(color: link).withLinkUnderline();

        expect(style.decoration, TextDecoration.underline);
        expect(style.decorationThickness, CcLinkStyle.underlineThickness);
        // The stroke is the link colour at the shared opacity — softer than the
        // full-strength text so descenders aren't cut hard.
        expect(style.decorationColor, link.withValues(alpha: 0.5));
        // The text colour itself is untouched.
        expect(style.color, link);
      },
    );

    test('an explicit colour overrides the style colour', () {
      const other = Color(0xFFFF0000);
      final style = const TextStyle(color: link).withLinkUnderline(other);
      expect(style.decorationColor, other.withValues(alpha: 0.5));
    });

    test('is softer than a full-strength underline', () {
      final soft = const TextStyle(color: link).withLinkUnderline();
      expect(soft.decorationColor!.a, lessThan(1.0));
    });
  });
}
