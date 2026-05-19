import 'package:control_center/shared/utils/github_markdown_preprocessor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isMarkdownBodyEffectivelyEmpty', () {
    test('treats an empty string as empty', () {
      expect(isMarkdownBodyEffectivelyEmpty(''), isTrue);
    });

    test('treats whitespace-only as empty', () {
      expect(isMarkdownBodyEffectivelyEmpty('   \n\t  \n'), isTrue);
    });

    test('treats a single HTML comment as empty', () {
      // The exact shape that triggered the blank-gap bug: a PR whose body is
      // only an HTML comment renders to nothing, so it must read as "no
      // description".
      expect(
        isMarkdownBodyEffectivelyEmpty(
          '<!-- If you can read this, reply with a cute cat -->\n',
        ),
        isTrue,
      );
    });

    test('treats an all-comments PR template as empty', () {
      expect(
        isMarkdownBodyEffectivelyEmpty(
          '<!-- Describe your change -->\n\n'
          '<!-- Link the ticket -->\n',
        ),
        isTrue,
      );
    });

    test('treats a multi-line HTML comment as empty', () {
      expect(
        isMarkdownBodyEffectivelyEmpty('<!--\nline one\nline two\n-->'),
        isTrue,
      );
    });

    test('keeps real prose as non-empty', () {
      expect(isMarkdownBodyEffectivelyEmpty('Fixes the login bug.'), isFalse);
    });

    test('keeps prose alongside a comment as non-empty', () {
      expect(
        isMarkdownBodyEffectivelyEmpty(
          '<!-- template -->\nFixes the login bug.',
        ),
        isFalse,
      );
    });

    test('a comment inside a fenced code block is visible content', () {
      // stripHtmlComments preserves comments inside fences, so a body that is a
      // code block showing comment syntax is NOT empty.
      expect(
        isMarkdownBodyEffectivelyEmpty('```html\n<!-- shown verbatim -->\n```'),
        isFalse,
      );
    });
  });
}
