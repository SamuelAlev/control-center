import 'package:control_center/shared/syntax/syntax_languages.dart';
import 'package:flutter_test/flutter_test.dart';

/// Language resolution for PR diffs now goes through the unified table in
/// `shared/syntax/syntax_languages.dart` (see its own exhaustive test suite,
/// including the registry-resolution guard). This file pins the DIFF-facing
/// intent: the mappings that were silently broken under highlight 0.7.0.
void main() {
  group('diff language resolution (shikiLangForPath)', () {
    test('TS/TSX/TOML diffs resolve to real grammars '
        '(they rendered plain under highlight 0.7.0)', () {
      expect(shikiLangForPath('src/app.ts'), 'typescript');
      expect(shikiLangForPath('src/App.tsx'), 'tsx');
      expect(shikiLangForPath('config/settings.toml'), 'toml');
    });

    test('the everyday spread resolves', () {
      expect(shikiLangForPath('lib/main.dart'), 'dart');
      expect(shikiLangForPath('scripts/run.sh'), 'shellscript');
      expect(shikiLangForPath('pkg/mod.go'), 'go');
      expect(shikiLangForPath('src/lib.rs'), 'rust');
      expect(shikiLangForPath('index.html'), 'html');
      expect(shikiLangForPath('style.scss'), 'scss');
      expect(shikiLangForPath('schema.sql'), 'sql');
      expect(shikiLangForPath('README.md'), 'markdown');
    });

    test('filename-only detection works (no extension)', () {
      expect(shikiLangForPath('Dockerfile'), 'docker');
      expect(shikiLangForPath('Makefile'), 'make');
      expect(shikiLangForPath('CODEOWNERS'), 'codeowners');
    });

    test('unknown files resolve to null (plain text)', () {
      expect(shikiLangForPath('LICENSE'), isNull);
      expect(shikiLangForPath('assets/img.png'), isNull);
    });
  });
}
