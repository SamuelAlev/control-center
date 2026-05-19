import 'package:control_center/shared/syntax/cc_shiki_theme.dart';
import 'package:control_center/shared/syntax/cc_shiki_theme_json.dart';
import 'package:control_center/shared/syntax/shiki_tokenizers.dart';
import 'package:control_center/shared/utils/syntax_palette.dart';
import 'package:flutter_test/flutter_test.dart';

/// `0xFFCF222E` → `#CF222E`.
String _hexOf(int argb) =>
    '#${(argb & 0xFFFFFF).toRadixString(16).padLeft(6, '0').toUpperCase()}';

void main() {
  group('palette ↔ theme JSON drift', () {
    test('every light palette color appears in the light theme JSON', () {
      final json = ccLightThemeJson.toUpperCase();
      for (final entry in lightSyntaxPalette.entries) {
        expect(
          json.contains(_hexOf(entry.value)),
          isTrue,
          reason:
              'light palette "${entry.key}" (${_hexOf(entry.value)}) '
              'is missing from ccLightThemeJson — the theme and '
              'syntax_palette.dart drifted',
        );
      }
    });

    test('every dark palette color appears in the dark theme JSON', () {
      final json = ccDarkThemeJson.toUpperCase();
      for (final entry in darkSyntaxPalette.entries) {
        expect(
          json.contains(_hexOf(entry.value)),
          isTrue,
          reason:
              'dark palette "${entry.key}" (${_hexOf(entry.value)}) '
              'is missing from ccDarkThemeJson',
        );
      }
    });

    test('both themes declare the neutral sentinel as editor.foreground', () {
      expect(ccLightThemeJson, contains(kCcNeutralForegroundHex));
      expect(ccDarkThemeJson, contains(kCcNeutralForegroundHex));
    });

    test('no fontStyle anywhere — italics/bold are not part of the design', () {
      expect(ccLightThemeJson.contains('fontStyle'), isFalse);
      expect(ccDarkThemeJson.contains('fontStyle'), isFalse);
    });
  });

  group('ccArgbForTokenColor', () {
    test('maps the sentinel and null to null (inherit base style)', () {
      expect(ccArgbForTokenColor(kCcNeutralForegroundHex), isNull);
      expect(ccArgbForTokenColor('#010203'), isNull);
      expect(ccArgbForTokenColor(null), isNull);
    });

    test('parses 6-digit hex to opaque ARGB', () {
      expect(ccArgbForTokenColor('#CF222E'), 0xFFCF222E);
      expect(ccArgbForTokenColor('#ff7b72'), 0xFFFF7B72);
    });

    test('parses 8-digit hex as RRGGBBAA', () {
      expect(ccArgbForTokenColor('#CF222E80'), 0x80CF222E);
    });

    test('parses 3-digit shorthand', () {
      expect(ccArgbForTokenColor('#abc'), 0xFFAABBCC);
    });

    test('unparseable input degrades to null, never throws', () {
      expect(ccArgbForTokenColor('#nope99'), isNull);
      expect(ccArgbForTokenColor('red'), isNull);
      expect(ccArgbForTokenColor(''), isNull);
    });
  });

  group('theme identity', () {
    test('ids and cache ids are brightness-keyed and revisioned', () {
      expect(ccThemeId(dark: false), kCcLightThemeId);
      expect(ccThemeId(dark: true), kCcDarkThemeId);
      expect(ccThemeCacheId(dark: true), 'cc-dark@$kCcThemeRevision');
      expect(ccThemeCacheId(dark: false), 'cc-light@$kCcThemeRevision');
    });
  });

  group('end-to-end token colors (real tokenize through the CC theme)', () {
    const dartSnippet = '''
// a comment
final greeting = 'hello';
class Widget {}
''';

    test('dark theme colors keyword/string/comment with the exact palette', () {
      final lines = CcShikiTokenizer.instance.tokenizeSync(
        dartSnippet,
        langId: 'dart',
        dark: true,
      );
      expect(lines, isNotNull);
      final byText = <String, int?>{};
      for (final line in lines!) {
        for (final t in line) {
          byText[t.content.trim()] = ccArgbForTokenColor(t.color);
        }
      }
      expect(
        byText['// a comment'],
        darkSyntaxPalette['comment'],
        reason: 'comment color',
      );
      expect(
        byText['final'],
        darkSyntaxPalette['keyword'],
        reason: 'keyword color',
      );
      expect(
        byText['class'],
        darkSyntaxPalette['keyword'],
        reason: 'keyword color',
      );
      // The Dart grammar scopes type names as `support.class` everywhere
      // (declaration and use alike) — they take the `class` palette color.
      // TypeScript declarations emit `entity.name.type.class` and land on
      // `title` purple instead; both are palette colors and per-token role
      // shifts between engines are accepted (see the migration plan).
      expect(
        byText['Widget'],
        darkSyntaxPalette['class'],
        reason: 'dart type names take the class color',
      );
      // The string body (quotes carry the same color via
      // punctuation.definition.string).
      expect(
        byText.entries.any(
          (e) =>
              e.key.contains('hello') && e.value == darkSyntaxPalette['string'],
        ),
        isTrue,
        reason: 'string color',
      );
    });

    test('light theme resolves the light palette', () {
      final lines = CcShikiTokenizer.instance.tokenizeSync(
        dartSnippet,
        langId: 'dart',
        dark: false,
      );
      final colors = lines!
          .expand((l) => l)
          .map((t) => ccArgbForTokenColor(t.color))
          .whereType<int>()
          .toSet();
      expect(colors, contains(lightSyntaxPalette['keyword']));
      expect(colors, contains(lightSyntaxPalette['comment']));
      // Nothing outside the palette (no colors invented by the theme).
      final palette = lightSyntaxPalette.values.toSet();
      expect(
        colors.difference(palette),
        isEmpty,
        reason: 'the theme must not introduce colors beyond the palette',
      );
    });

    test('ordinary identifiers inherit the base style (sentinel → null)', () {
      final lines = CcShikiTokenizer.instance.tokenizeSync(
        'final x = compute(someArgument);',
        langId: 'dart',
        dark: true,
      );
      final identifier = lines!
          .expand((l) => l)
          .where((t) => t.content.contains('someArgument'))
          .toList();
      expect(identifier, isNotEmpty);
      for (final t in identifier) {
        expect(
          ccArgbForTokenColor(t.color),
          isNull,
          reason:
              'plain identifiers must not be colored '
              '(got ${t.color} for "${t.content}")',
        );
      }
    });
  });
}
