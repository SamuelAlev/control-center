
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AppFonts', () {
    group('ui', () {
      test('returns a TextStyle', () {
        final style = AppFonts.ui();
        expect(style, isA<TextStyle>());
      });

      test('merges with provided textStyle', () {
        const baseStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
        final style = AppFonts.ui(textStyle: baseStyle);
        expect(style.fontSize, 18);
        expect(style.fontWeight, FontWeight.bold);
      });
    });

    group('code', () {
      test('returns a TextStyle', () {
        final style = AppFonts.code();
        expect(style, isA<TextStyle>());
      });

      test('merges with provided textStyle', () {
        const baseStyle = TextStyle(fontSize: 14, color: Colors.blue);
        final style = AppFonts.code(textStyle: baseStyle);
        expect(style.fontSize, 14);
        expect(style.color, Colors.blue);
      });
    });

    group('codeStyle', () {
      test('applies direct style parameters', () {
        final style = AppFonts.codeStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.green,
        );
        expect(style.fontSize, 12);
        expect(style.fontWeight, FontWeight.w600);
        expect(style.color, Colors.green);
      });

      test('returns TextStyle with no parameters', () {
        final style = AppFonts.codeStyle();
        expect(style, isA<TextStyle>());
      });

      test('applies backgroundColor parameter', () {
        final style = AppFonts.codeStyle(backgroundColor: Colors.yellow);
        expect(style.backgroundColor, Colors.yellow);
      });

      test('applies height parameter', () {
        final style = AppFonts.codeStyle(height: 1.5);
        expect(style.height, 1.5);
      });
    });

    // NOTE: the genuine google_fonts fetch path (a non-bundled Google family)
    // cannot be unit-tested offline — it makes a network request that the test
    // harness blocks. These tests therefore cover the deterministic, network-
    // free outcomes: bundled families and custom/system families resolve
    // verbatim. The bundled-family short-circuit is asserted in 'bundled
    // defaults' below.
    group('uiDynamic', () {
      test('applies the bundled UI family verbatim (no network)', () {
        final style = AppFonts.uiDynamic(AppFonts.uiFamily);
        expect(style.fontFamily, AppFonts.uiFamily);
      });

      test('returns TextStyle for unknown font with fontFamily', () {
        final style = AppFonts.uiDynamic('SomeCustomFont');
        expect(style.fontFamily, 'SomeCustomFont');
      });

      test('merges with the provided textStyle', () {
        const baseStyle = TextStyle(fontSize: 24);
        final style = AppFonts.uiDynamic('SomeCustomFont', textStyle: baseStyle);
        expect(style.fontSize, 24);
        expect(style.fontFamily, 'SomeCustomFont');
      });
    });

    group('codeDynamic', () {
      test('applies the bundled code family verbatim (no network)', () {
        final style = AppFonts.codeDynamic(AppFonts.codeFamily);
        expect(style.fontFamily, AppFonts.codeFamily);
      });

      test('returns TextStyle for unknown font with fontFamily', () {
        final style = AppFonts.codeDynamic('UnknownMono');
        expect(style.fontFamily, 'UnknownMono');
      });

      test('returns TextStyle with textStyle override', () {
        const baseStyle = TextStyle(fontSize: 16);
        final style = AppFonts.codeDynamic('UnknownMono', textStyle: baseStyle);
        expect(style.fontSize, 16);
      });
    });

    group('codeStyleDynamic', () {
      test('applies params for the bundled code family', () {
        final style = AppFonts.codeStyleDynamic(
          AppFonts.codeFamily,
          fontSize: 14,
          fontWeight: FontWeight.w700,
        );
        expect(style.fontFamily, AppFonts.codeFamily);
        expect(style.fontSize, 14);
        expect(style.fontWeight, FontWeight.w700);
      });

      test('returns TextStyle for unknown font with params', () {
        final style = AppFonts.codeStyleDynamic(
          'CustomCode',
          fontSize: 12,
          color: Colors.amber,
        );
        expect(style.fontFamily, 'CustomCode');
        expect(style.fontSize, 12);
        expect(style.color, Colors.amber);
      });

      test('returns TextStyle with no params', () {
        final style = AppFonts.codeStyleDynamic(AppFonts.codeFamily);
        expect(style, isA<TextStyle>());
      });

      test('bundled font with all params', () {
        final style = AppFonts.codeStyleDynamic(
          AppFonts.codeFamily,
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.red,
          backgroundColor: Colors.black12,
          height: 1.4,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.5,
        );
        expect(style.fontFamily, AppFonts.codeFamily);
        expect(style.fontSize, 14);
        expect(style.fontWeight, FontWeight.w500);
        expect(style.color, Colors.red);
        expect(style.backgroundColor, Colors.black12);
        expect(style.height, 1.4);
        expect(style.fontStyle, FontStyle.italic);
        expect(style.letterSpacing, 0.5);
      });

      test('unknown font with all params', () {
        final style = AppFonts.codeStyleDynamic(
          'CustomFont',
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: Colors.teal,
          backgroundColor: Colors.grey,
          height: 1.2,
          fontStyle: FontStyle.normal,
          letterSpacing: -0.5,
        );
        expect(style.fontFamily, 'CustomFont');
        expect(style.fontSize, 16);
        expect(style.fontWeight, FontWeight.w600);
        expect(style.color, Colors.teal);
      });
    });

    group('uiTextTheme', () {
      testWidgets('returns a TextTheme', (tester) async {
        final base = ThemeData.light().textTheme;
        final textTheme = AppFonts.uiTextTheme(base);
        expect(textTheme, isA<TextTheme>());
      });

      testWidgets('applies the bundled UI family', (tester) async {
        final base = ThemeData.light().textTheme;
        final textTheme = AppFonts.uiTextTheme(base);
        expect(textTheme.bodyMedium?.fontFamily, AppFonts.uiFamily);
      });
    });

    group('bundled defaults', () {
      test('ui() applies the bundled UI family (Manrope)', () {
        expect(AppFonts.uiFamily, 'packages/cc_ui/Manrope');
        expect(AppFonts.ui().fontFamily, AppFonts.uiFamily);
      });

      test('code() / codeStyle() apply the bundled code family (Fira Code)', () {
        expect(AppFonts.codeFamily, 'packages/cc_ui/Fira Code');
        expect(AppFonts.code().fontFamily, AppFonts.codeFamily);
        expect(AppFonts.codeStyle().fontFamily, AppFonts.codeFamily);
      });

      test('bundled families are applied verbatim, never via google_fonts', () {
        // The bundled families must resolve to the exact host-asset family name
        // (no google_fonts mangling) so default text never hits the network.
        expect(AppFonts.codeDynamic(AppFonts.codeFamily).fontFamily,
            AppFonts.codeFamily);
        expect(AppFonts.uiDynamic(AppFonts.uiFamily).fontFamily,
            AppFonts.uiFamily);
        expect(AppFonts.codeStyleDynamic(AppFonts.codeFamily).fontFamily,
            AppFonts.codeFamily);
      });
    });

    group('textThemeFor', () {
      testWidgets('applies the bundled family by name (no network)', (
        tester,
      ) async {
        final base = ThemeData.light().textTheme;
        final textTheme = AppFonts.textThemeFor(AppFonts.uiFamily, base);
        expect(textTheme.bodyMedium?.fontFamily, AppFonts.uiFamily);
      });

      testWidgets('applies a custom family by name', (tester) async {
        final base = ThemeData.light().textTheme;
        final textTheme = AppFonts.textThemeFor('SomeCustomFont', base);
        expect(textTheme.bodyMedium?.fontFamily, 'SomeCustomFont');
      });
    });

    group('loadSystemFont', () {
      test('returns false for non-existent file', () async {
        final result = await AppFonts.loadSystemFont('TestFont', '/non/existent/path.ttf');
        expect(result, isFalse);
      });
    });
  });
}
