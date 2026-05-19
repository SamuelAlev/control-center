import 'package:control_center/shared/widgets/composer/file_reference.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ellipsizeFileRefName', () {
    test('leaves a name that already fits', () {
      expect(ellipsizeFileRefName('composer.dart'), 'composer.dart');
    });

    test('keeps the extension when it shortens', () {
      final short = ellipsizeFileRefName('transcript_segment_row_widget.dart');
      expect(short.length, lessThanOrEqualTo(kFileRefMaxNameChars));
      expect(short, endsWith('.dart'));
      expect(short, contains('…'));
    });

    test('keeps a head AND a tail so sibling names stay distinguishable', () {
      final impl = ellipsizeFileRefName('agent_run_log_repository_impl.dart');
      final test = ellipsizeFileRefName('agent_run_log_repository_test.dart');
      expect(impl, isNot(test));
      expect(impl, startsWith('agent'));
      expect(test, startsWith('agent'));
    });

    test('degrades to a right trim when the extension eats the budget', () {
      final short = ellipsizeFileRefName('a-very-long-name.longextension');
      expect(short.length, lessThanOrEqualTo(kFileRefMaxNameChars));
    });

    test('strips characters that would break the token', () {
      expect(ellipsizeFileRefName('we]ird\nname.txt'), 'weirdname.txt');
    });

    test('never returns an empty name', () {
      expect(ellipsizeFileRefName(']]]'), 'file');
    });
  });

  group('uniqueFileRefName', () {
    test('uses the basename, not the path', () {
      expect(uniqueFileRefName('/a/b/c/main.dart', {}), 'main.dart');
    });

    test('disambiguates a collision instead of silently reusing', () {
      final taken = <String>{'index.ts'};
      final second = uniqueFileRefName('/pkg/b/index.ts', taken);
      expect(second, isNot('index.ts'));
      expect(second, startsWith('index.ts'));
    });

    test('handles a Windows-style path', () {
      expect(uniqueFileRefName(r'C:\Users\me\shot.png', {}), 'shot.png');
    });
  });

  group('findFileRefs', () {
    test('finds references and their ranges', () {
      const text = 'compare @[file:a.png] with @[file:b.png] please';
      final refs = findFileRefs(text);
      expect(refs.map((r) => r.name), ['a.png', 'b.png']);
      expect(text.substring(refs.first.start, refs.first.end), '@[file:a.png]');
    });

    test('does not run past a missing closing bracket', () {
      expect(findFileRefs('@[file:a.png and the rest of the prompt'), isEmpty);
    });

    test('does not span a newline', () {
      expect(findFileRefs('@[file:a\n.png]'), isEmpty);
    });

    test('containsOffset is strict at the boundaries', () {
      final ref = findFileRefs('@[file:a.png]').single;
      expect(ref.containsOffset(ref.start), isFalse);
      expect(ref.containsOffset(ref.end), isFalse);
      expect(ref.containsOffset(ref.start + 1), isTrue);
    });
  });

  group('fileRefSurvives', () {
    test('is true while the exact token is present', () {
      expect(
        fileRefSurvives('see @[file:a.dart] here', fileRefToken('a.dart')),
        isTrue,
      );
    });

    test('a longer name does not keep a shorter reference alive', () {
      expect(
        fileRefSurvives('see @[file:ab.dart]', fileRefToken('a.dart')),
        isFalse,
      );
    });
  });

  group('expandFileRefs', () {
    test('replaces in place, preserving position', () {
      final out = expandFileRefs(
        'compare @[file:a.png] with @[file:b.png]',
        (name) => '/abs/$name',
      );
      expect(out, 'compare /abs/a.png with /abs/b.png');
    });

    test('leaves a reference nothing resolves as the user wrote it', () {
      const text = 'read @[file:notes.md] first';
      expect(expandFileRefs(text, (_) => null), text);
    });

    test('is a no-op on text with no references', () {
      expect(expandFileRefs('plain words', (_) => 'X'), 'plain words');
    });
  });
}
