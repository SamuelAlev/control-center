import 'package:cc_natives/cc_natives.dart';
import 'package:test/test.dart';

void main() {
  group('code language registry', () {
    test('maps common extensions to language ids', () {
      expect(languageIdForPath('lib/a.dart'), 'dart');
      expect(languageIdForPath('src/app.js'), 'javascript');
      expect(languageIdForPath('src/app.jsx'), 'javascript');
      expect(languageIdForPath('src/app.mjs'), 'javascript');
      expect(languageIdForPath('src/app.ts'), 'typescript');
      expect(languageIdForPath('src/App.tsx'), 'tsx');
      expect(languageIdForPath('src/Foo.php'), 'php');
    });

    test('returns null for unsupported / extensionless paths', () {
      expect(languageIdForPath('README.md'), isNull);
      expect(languageIdForPath('Makefile'), isNull);
      expect(languageIdForPath('trailing.'), isNull);
    });

    test('is case-insensitive on extension', () {
      expect(languageIdForPath('SRC/APP.TS'), 'typescript');
    });

    test('tsx reuses the typescript query; others map to themselves', () {
      expect(queryIdFor('tsx'), 'typescript');
      expect(queryIdFor('typescript'), 'typescript');
      expect(queryIdFor('javascript'), 'javascript');
      expect(queryIdFor('php'), 'php');
      expect(queryIdFor('dart'), 'dart');
    });
  });
}
