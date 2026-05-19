import 'package:cc_harness/loop.dart';
import 'package:cc_harness/provider.dart';
import 'package:test/test.dart';

List<String> _words(String text) =>
    detectMagicKeywords(text).map((k) => k.word).toList();

void main() {
  group('detectMagicKeywords — triggers', () {
    test('fires on a standalone word', () {
      expect(_words('ultrathink about the failure modes'), ['ultrathink']);
      expect(_words('orchestrate the migration'), ['orchestrate']);
    });

    test('sentence punctuation may touch it', () {
      expect(_words('please orchestrate, then report'), ['orchestrate']);
      expect(_words('do it. ultrathink.'), ['ultrathink']);
    });

    test('several keywords in one prompt all fire', () {
      expect(
        _words('ultrathink then orchestrate the work'),
        containsAll(['ultrathink', 'orchestrate']),
      );
    });
  });

  group('detectMagicKeywords — does NOT fire', () {
    test('inflections and different casing', () {
      // Getting this wrong is worse than not having the feature.
      expect(_words('we orchestrated the release'), isEmpty);
      expect(_words('Orchestrate the migration'), isEmpty);
      expect(_words('orchestration is hard'), isEmpty);
    });

    test('paths, extensions and identifiers', () {
      expect(_words('see src/orchestrate/main.ts'), isEmpty);
      expect(_words('open orchestrate.ts'), isEmpty);
      expect(_words('call foo::orchestrate()'), isEmpty);
      expect(_words('the orchestrate_worker module'), isEmpty);
      expect(_words('run orchestrate()'), isEmpty);
      expect(_words(r'C:\tools\orchestrate\run'), isEmpty);
    });

    test('inside a fenced code block', () {
      expect(
        _words('look at this:\n```\norchestrate the thing\n```\nwhat is wrong?'),
        isEmpty,
      );
    });

    test('inside an inline code span', () {
      expect(_words('the `orchestrate` flag does nothing'), isEmpty);
    });

    test('inside an XML/HTML section', () {
      expect(_words('<note>orchestrate</note> is quoted'), isEmpty);
      expect(_words('a <orchestrate /> tag'), isEmpty);
    });

    test('a pasted stack trace does not change behaviour', () {
      // The failure this whole boundary exists to prevent.
      const trace = '''
Unhandled exception:
  at orchestrate.ts:14:9
  at packages/orchestrate/lib/run.dart:88
''';
      expect(_words(trace), isEmpty);
    });
  });

  group('effort and directive', () {
    test('ultrathink forces the ceiling', () {
      final keywords = detectMagicKeywords('ultrathink this');
      expect(magicKeywordEffort(keywords), ReasoningEffort.xhigh);
    });

    test('orchestrate forces no effort of its own', () {
      expect(
        magicKeywordEffort(detectMagicKeywords('orchestrate this')),
        isNull,
      );
    });

    test('the strongest effort wins across keywords', () {
      final keywords = detectMagicKeywords('ultrathink and orchestrate');
      expect(magicKeywordEffort(keywords), ReasoningEffort.xhigh);
    });

    test('the directive carries every instruction', () {
      final directive = magicKeywordDirective(
        detectMagicKeywords('ultrathink and orchestrate'),
      );
      expect(directive, contains('step by step'));
      expect(directive, contains('parallel'));
    });

    test('no keywords means no directive at all', () {
      expect(magicKeywordDirective(const []), isNull);
      expect(magicKeywordDirective(detectMagicKeywords('just do it')), isNull);
    });
  });

  group('configuration', () {
    test('a disabled keyword never fires', () {
      expect(
        detectMagicKeywords('ultrathink', disabled: {'ultrathink'}),
        isEmpty,
      );
    });
  });

  group('maskNonProse', () {
    test('preserves length so offsets stay valid', () {
      const text = 'before `code` after';
      expect(maskNonProse(text).length, text.length);
    });

    test('keeps newlines so line numbers survive', () {
      const text = '```\na\nb\n```';
      expect('\n'.allMatches(maskNonProse(text)).length, 3);
    });
  });
}
