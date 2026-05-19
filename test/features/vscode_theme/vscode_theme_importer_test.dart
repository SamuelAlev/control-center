import 'package:control_center/features/vscode_theme/data/vscode_theme_importer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

const _darkTheme = '''
{
  "name": "Midnight",
  "type": "dark",
  "colors": {
    "editor.background": "#1e1e1e",
    "editor.foreground": "#d4d4d4",
    "editorLineNumber.foreground": "#858585",
    "diffEditor.insertedTextBackground": "#2ea04326",
    "diffEditor.removedTextBackground": "#f8514926"
  },
  "tokenColors": [
    { "scope": "keyword", "settings": { "foreground": "#c586c0" } },
    { "scope": ["string", "string.quoted"], "settings": { "foreground": "#ce9178" } },
    { "scope": "comment", "settings": { "foreground": "#6a9955" } }
  ]
}
''';

void main() {
  group('parseVsCodeTheme', () {
    test('parses colors, brightness and diff backgrounds', () {
      final theme = parseVsCodeTheme(_darkTheme);
      expect(theme.name, 'Midnight');
      expect(theme.brightness, Brightness.dark);
      expect(theme.background, const Color(0xFF1E1E1E));
      expect(theme.foreground, const Color(0xFFD4D4D4));
      expect(theme.lineNumber, const Color(0xFF858585));
      // #RRGGBBAA → 0xAARRGGBB: alpha 0x26 moves to the front.
      expect(theme.addedBackground, const Color(0x262EA043));
      expect(theme.removedBackground, const Color(0x26F85149));
    });

    test('folds tokenColors into a compact syntax map', () {
      final theme = parseVsCodeTheme(_darkTheme);
      expect(theme.syntaxColor('keyword'), const Color(0xFFC586C0));
      expect(theme.syntaxColor('string'), const Color(0xFFCE9178));
      expect(theme.syntaxColor('comment'), const Color(0xFF6A9955));
      // Unknown role falls back to the foreground.
      expect(theme.syntaxColor('whatever'), theme.foreground);
    });

    test('infers brightness from background luminance when type is absent', () {
      final light = parseVsCodeTheme(
        '{"colors":{"editor.background":"#ffffff","editor.foreground":"#222222"}}',
      );
      expect(light.brightness, Brightness.light);
    });

    test('expands #rgb shorthand', () {
      final theme = parseVsCodeTheme(
        '{"type":"dark","colors":{"editor.background":"#08f"}}',
      );
      expect(theme.background, const Color(0xFF0088FF));
    });

    test('falls back to defaults for a near-empty theme', () {
      final theme = parseVsCodeTheme('{}');
      expect(theme.name, 'Imported theme');
      expect(theme.background, const Color(0xFF1E1E1E));
      expect(theme.syntax, isEmpty);
    });

    test('throws on invalid JSON and non-object roots', () {
      expect(
        () => parseVsCodeTheme('not json'),
        throwsA(isA<VsCodeThemeFormatException>()),
      );
      expect(
        () => parseVsCodeTheme('[1,2,3]'),
        throwsA(isA<VsCodeThemeFormatException>()),
      );
    });
  });
}
