import 'package:control_center/shared/syntax/grammar_registry_io.dart'
    as registry;
import 'package:control_center/shared/syntax/syntax_languages.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('registry resolution guard', () {
    test('every id the tables can return resolves in the desktop bundle', () {
      for (final id in allMappedLanguageIds) {
        expect(
          registry.codeLanguageForId(id),
          isNotNull,
          reason:
              'syntax_languages maps to "$id" but the shiki bundle has '
              'no such grammar — typo, or a shiki upgrade renamed it',
        );
      }
    });
  });

  group('shikiLangForFence', () {
    test('restores real TypeScript-family grammars', () {
      expect(shikiLangForFence('ts'), 'typescript');
      expect(shikiLangForFence('typescript'), 'typescript');
      expect(shikiLangForFence('tsx'), 'tsx');
      expect(shikiLangForFence('jsx'), 'jsx');
      expect(shikiLangForFence('js'), 'javascript');
    });

    test('canonical names and common aliases', () {
      expect(shikiLangForFence('dart'), 'dart');
      expect(shikiLangForFence('py'), 'python');
      expect(shikiLangForFence('rs'), 'rust');
      expect(shikiLangForFence('sh'), 'shellscript');
      expect(shikiLangForFence('zsh'), 'shellscript');
      expect(shikiLangForFence('yml'), 'yaml');
      expect(shikiLangForFence('toml'), 'toml');
      expect(shikiLangForFence('c++'), 'cpp');
      expect(shikiLangForFence('c#'), 'csharp');
      expect(shikiLangForFence('html'), 'html');
      expect(shikiLangForFence('dockerfile'), 'docker');
      expect(shikiLangForFence('makefile'), 'make');
      expect(shikiLangForFence('mermaid'), 'mermaid');
    });

    test('is case-insensitive and strips fence attributes', () {
      expect(shikiLangForFence('Dart'), 'dart');
      expect(shikiLangForFence('js title="example.js"'), 'javascript');
      expect(shikiLangForFence('dart {1,3}'), 'dart');
    });

    test('unknown/empty hints resolve to null (plain text)', () {
      expect(shikiLangForFence(null), isNull);
      expect(shikiLangForFence(''), isNull);
      expect(shikiLangForFence('   '), isNull);
      expect(shikiLangForFence('notalanguage'), isNull);
      expect(shikiLangForFence('plaintext'), isNull);
    });
  });

  group('shikiLangForPath', () {
    test('well-known filenames beat extensions', () {
      expect(shikiLangForPath('Dockerfile'), 'docker');
      expect(shikiLangForPath('services/api/Dockerfile'), 'docker');
      expect(shikiLangForPath('Makefile'), 'make');
      expect(shikiLangForPath('CMakeLists.txt'), 'cmake');
      expect(shikiLangForPath('Gemfile'), 'ruby');
      expect(shikiLangForPath('CODEOWNERS'), 'codeowners');
      expect(shikiLangForPath('.gitignore'), 'ini');
      expect(shikiLangForPath('go.mod'), 'go');
    });

    test('extensions resolve case-insensitively', () {
      expect(shikiLangForPath('lib/main.dart'), 'dart');
      expect(shikiLangForPath('src/App.TSX'), 'tsx');
      expect(shikiLangForPath('config.toml'), 'toml');
      expect(shikiLangForPath(r'windows\path\file.cpp'), 'cpp');
    });

    test('dotfiles resolve by name', () {
      expect(shikiLangForPath('.zshrc'), 'shellscript');
      expect(shikiLangForPath('home/.vimrc'), 'viml');
      expect(shikiLangForPath('.env'), 'dotenv');
      expect(shikiLangForPath('.env.production'), 'dotenv');
    });

    test('unknowns resolve to null', () {
      expect(shikiLangForPath('src/utils'), isNull);
      expect(shikiLangForPath('LICENSE'), isNull);
      expect(shikiLangForPath(''), isNull);
      expect(shikiLangForPath('archive.tar.gz'), isNull);
    });
  });

  group('syntaxWeightFor / syncLineBudget', () {
    test('measured weight classes', () {
      expect(syntaxWeightFor('dart'), SyntaxWeight.light);
      expect(syntaxWeightFor('json'), SyntaxWeight.light);
      expect(syntaxWeightFor('python'), SyntaxWeight.medium);
      expect(syntaxWeightFor('typescript'), SyntaxWeight.heavy);
      expect(syntaxWeightFor('tsx'), SyntaxWeight.heavy);
      expect(syntaxWeightFor('cpp'), SyntaxWeight.extreme);
      expect(syntaxWeightFor('sql'), SyntaxWeight.extreme);
    });

    test('null is free, unknown grammars default to heavy', () {
      expect(syntaxWeightFor(null), SyntaxWeight.light);
      expect(syntaxWeightFor('zenscript'), SyntaxWeight.heavy);
    });

    test('budgets are monotonically stricter with weight', () {
      expect(
        syncLineBudget(SyntaxWeight.light),
        greaterThan(syncLineBudget(SyntaxWeight.medium)),
      );
      expect(
        syncLineBudget(SyntaxWeight.medium),
        greaterThan(syncLineBudget(SyntaxWeight.heavy)),
      );
      expect(
        syncLineBudget(SyntaxWeight.heavy),
        greaterThan(syncLineBudget(SyntaxWeight.extreme)),
      );
    });
  });
}
