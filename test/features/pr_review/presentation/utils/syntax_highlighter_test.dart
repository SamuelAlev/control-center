import 'package:control_center/features/pr_review/presentation/utils/syntax_highlighter.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('languageForExtension', () {
    test('returns dart for .dart', () {
      expect(languageForExtension('dart'), 'dart');
    });

    test('returns typescript for .ts and .tsx', () {
      expect(languageForExtension('ts'), 'typescript');
      expect(languageForExtension('tsx'), 'typescript');
    });

    test('returns javascript for .js, .jsx, .mjs, .cjs', () {
      expect(languageForExtension('js'), 'javascript');
      expect(languageForExtension('jsx'), 'javascript');
      expect(languageForExtension('mjs'), 'javascript');
      expect(languageForExtension('cjs'), 'javascript');
    });

    test('returns python for .py', () {
      expect(languageForExtension('py'), 'python');
    });

    test('returns ruby for .rb', () {
      expect(languageForExtension('rb'), 'ruby');
    });

    test('returns go for .go', () {
      expect(languageForExtension('go'), 'go');
    });

    test('returns rust for .rs', () {
      expect(languageForExtension('rs'), 'rust');
    });

    test('returns java for .java', () {
      expect(languageForExtension('java'), 'java');
    });

    test('returns kotlin for .kt and .kts', () {
      expect(languageForExtension('kt'), 'kotlin');
      expect(languageForExtension('kts'), 'kotlin');
    });

    test('returns swift for .swift', () {
      expect(languageForExtension('swift'), 'swift');
    });

    test('returns cs for .cs', () {
      expect(languageForExtension('cs'), 'cs');
    });

    test('returns cpp for .cpp, .cc, .cxx, .hpp, .hh', () {
      expect(languageForExtension('cpp'), 'cpp');
      expect(languageForExtension('cc'), 'cpp');
      expect(languageForExtension('cxx'), 'cpp');
      expect(languageForExtension('hpp'), 'cpp');
      expect(languageForExtension('hh'), 'cpp');
    });

    test('returns c for .c and .h', () {
      expect(languageForExtension('c'), 'c');
      expect(languageForExtension('h'), 'c');
    });

    test('returns json for .json', () {
      expect(languageForExtension('json'), 'json');
    });

    test('returns yaml for .yaml and .yml', () {
      expect(languageForExtension('yaml'), 'yaml');
      expect(languageForExtension('yml'), 'yaml');
    });

    test('returns toml for .toml', () {
      expect(languageForExtension('toml'), 'toml');
    });

    test('returns xml for .xml, .svg, .html, .htm', () {
      expect(languageForExtension('xml'), 'xml');
      expect(languageForExtension('svg'), 'xml');
      expect(languageForExtension('html'), 'xml');
      expect(languageForExtension('htm'), 'xml');
    });

    test('returns css for .css', () {
      expect(languageForExtension('css'), 'css');
    });

    test('returns scss for .scss and .sass', () {
      expect(languageForExtension('scss'), 'scss');
      expect(languageForExtension('sass'), 'scss');
    });

    test('returns bash for .sh, .bash, .zsh', () {
      expect(languageForExtension('sh'), 'bash');
      expect(languageForExtension('bash'), 'bash');
      expect(languageForExtension('zsh'), 'bash');
    });

    test('returns sql for .sql', () {
      expect(languageForExtension('sql'), 'sql');
    });

    test('returns markdown for .md and .mdx', () {
      expect(languageForExtension('md'), 'markdown');
      expect(languageForExtension('mdx'), 'markdown');
    });

    test('returns graphql for .graphql and .gql', () {
      expect(languageForExtension('graphql'), 'graphql');
      expect(languageForExtension('gql'), 'graphql');
    });

    test('returns php for .php', () {
      expect(languageForExtension('php'), 'php');
    });

    test('returns lua for .lua', () {
      expect(languageForExtension('lua'), 'lua');
    });

    test('returns r for .r', () {
      expect(languageForExtension('r'), 'r');
    });

    test('returns null for unknown extension', () {
      expect(languageForExtension('unknown'), isNull);
      expect(languageForExtension('xyz'), isNull);
    });

    test('returns null for empty string', () {
      expect(languageForExtension(''), isNull);
    });
  });
}
