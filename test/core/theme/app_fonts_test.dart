
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

    group('uiDynamic', () {
      test('returns TextStyle for known Google font', () {
        final style = AppFonts.uiDynamic('Manrope');
        expect(style, isA<TextStyle>());
      });

      test('returns TextStyle for unknown font with fontFamily', () {
        final style = AppFonts.uiDynamic('SomeCustomFont');
        expect(style.fontFamily, 'SomeCustomFont');
      });

      test('merges with textStyle for known font', () {
        const baseStyle = TextStyle(fontSize: 24);
        final style = AppFonts.uiDynamic('Manrope', textStyle: baseStyle);
        expect(style.fontSize, 24);
      });

      test('returns TextStyle without textStyle override', () {
        final style = AppFonts.uiDynamic('Inter');
        expect(style, isA<TextStyle>());
      });
    });

    group('codeDynamic', () {
      test('returns TextStyle for known Google font', () {
        final style = AppFonts.codeDynamic('JetBrains Mono');
        expect(style, isA<TextStyle>());
      });

      test('returns TextStyle for unknown font with fontFamily', () {
        final style = AppFonts.codeDynamic('UnknownMono');
        expect(style.fontFamily, 'UnknownMono');
      });

      test('returns TextStyle with textStyle override', () {
        const baseStyle = TextStyle(fontSize: 16);
        final style = AppFonts.codeDynamic('JetBrains Mono', textStyle: baseStyle);
        expect(style.fontSize, 16);
      });
    });

    group('codeStyleDynamic', () {
      test('returns TextStyle for known Google font with params', () {
        final style = AppFonts.codeStyleDynamic(
          'JetBrains Mono',
          fontSize: 14,
          fontWeight: FontWeight.w700,
        );
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
        final style = AppFonts.codeStyleDynamic('JetBrains Mono');
        expect(style, isA<TextStyle>());
      });

      test('known font with all params', () {
        final style = AppFonts.codeStyleDynamic(
          'Manrope',
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.red,
          backgroundColor: Colors.black12,
          height: 1.4,
          fontStyle: FontStyle.italic,
          letterSpacing: 0.5,
        );
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

    group('manropeTextTheme', () {
      testWidgets('returns a TextTheme', (tester) async {
        final base = ThemeData.light().textTheme;
        final textTheme = AppFonts.manropeTextTheme(base);
        expect(textTheme, isA<TextTheme>());
      });
    });

    group('textThemeFor', () {
      testWidgets('returns a TextTheme for a font family', (tester) async {
        final base = ThemeData.light().textTheme;
        final textTheme = AppFonts.textThemeFor('Manrope', base);
        expect(textTheme, isA<TextTheme>());
      });

      testWidgets('returns TextTheme for a known Google font family', (tester) async {
        final base = ThemeData.light().textTheme;
        final textTheme = AppFonts.textThemeFor('Roboto', base);
        expect(textTheme, isA<TextTheme>());
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
