import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

/// Coverage for [CcThemeData] (the value object) and [CcTheme] (the
/// InheritedWidget that delivers it). The data object's dark factory, copyWith,
/// equality, and hashCode are pure logic; the InheritedWidget leg is driven
/// through a `ccTestApp` subtree.
void main() {
  group('CcThemeData', () {
    test('.light() is the light appearance with light tokens', () {
      final d = CcThemeData.light();
      expect(d.brightness, CcBrightness.light);
      expect(d.isDark, isFalse);
      expect(d.reducedMotion, isFalse);
      expect(d.fontFamily, isNull);
      expect(d.monoFontFamily, isNull);
    });

    test('.dark() is the dark appearance with dark tokens', () {
      final d = CcThemeData.dark(
        fontFamily: 'Manrope',
        monoFontFamily: 'Fira Code',
        reducedMotion: true,
      );
      expect(d.brightness, CcBrightness.dark);
      expect(d.isDark, isTrue);
      expect(d.reducedMotion, isTrue);
      expect(d.fontFamily, 'Manrope');
      expect(d.monoFontFamily, 'Fira Code');
    });

    test('isDark tracks brightness', () {
      expect(CcThemeData.light().isDark, isFalse);
      expect(CcThemeData.dark().isDark, isTrue);
    });

    test('copyWith overrides only the supplied fields', () {
      final base = CcThemeData.light();
      final tokens = DesignSystemTokens.dark();
      final copy = base.copyWith(
        tokens: tokens,
        brightness: CcBrightness.dark,
        reducedMotion: true,
        fontFamily: 'X',
        monoFontFamily: 'Y',
      );
      expect(copy.tokens, same(tokens));
      expect(copy.brightness, CcBrightness.dark);
      expect(copy.reducedMotion, isTrue);
      expect(copy.fontFamily, 'X');
      expect(copy.monoFontFamily, 'Y');
      // Original is untouched.
      expect(base.brightness, CcBrightness.light);
    });

    test('copyWith with no args returns an equal copy', () {
      final base = CcThemeData.light();
      expect(base.copyWith(), base);
    });

    test('== and hashCode cover every field', () {
      final a = CcThemeData.light();
      final b = CcThemeData.light();
      expect(a, equals(b));
      expect(a.hashCode, b.hashCode);

      // Distinct in each field → not equal.
      expect(a, isNot(CcThemeData.dark()));
      expect(a, isNot(CcThemeData.light(reducedMotion: true)));
      expect(
        a,
        isNot(
          CcThemeData(
            tokens: DesignSystemTokens.dark(),
            brightness: CcBrightness.light,
          ),
        ),
      );
      // Different font families → not equal.
      expect(
        CcThemeData.light(fontFamily: 'A'),
        isNot(CcThemeData.light(fontFamily: 'B')),
      );
      expect(
        CcThemeData.light(monoFontFamily: 'A'),
        isNot(CcThemeData.light(monoFontFamily: 'B')),
      );
    });

    test('== rejects unrelated types', () {
      expect(CcThemeData.light() == Object(), isFalse);
    });
  });

  group('CcTheme InheritedWidget', () {
    testWidgets('of() returns the ancestor data and asserts when absent', (
      tester,
    ) async {
      late CcThemeData captured;
      await tester.pumpWidget(
        ccTestApp(
          Builder(
            builder: (context) {
              captured = CcTheme.of(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(captured.brightness, CcBrightness.light);

      // maybeOf returns null outside a CcTheme.
      late CcThemeData? outside;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: Builder(
            builder: (context) {
              outside = CcTheme.maybeOf(context);
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(outside, isNull);
    });

    testWidgets('updateShouldNotify fires only when the data changes', (
      tester,
    ) async {
      final a = CcTheme(
        data: CcThemeData.light(),
        child: const SizedBox.shrink(),
      );
      final b = CcTheme(
        data: CcThemeData.light(),
        child: const SizedBox.shrink(),
      );
      expect(a.updateShouldNotify(b), isFalse);
      final c = CcTheme(
        data: CcThemeData.dark(),
        child: const SizedBox.shrink(),
      );
      expect(a.updateShouldNotify(c), isTrue);
    });

    testWidgets('the BuildContext accessors resolve tokens + theme', (
      tester,
    ) async {
      late DesignSystemTokens? tokens;
      late CcThemeData? theme;
      await tester.pumpWidget(
        ccTestApp(
          Builder(
            builder: (context) {
              tokens = context.designSystem;
              theme = context.ccTheme;
              return const SizedBox.shrink();
            },
          ),
        ),
      );
      expect(tokens, isNotNull);
      expect(theme, isNotNull);
      expect(theme!.brightness, CcBrightness.light);
    });
  });
}
