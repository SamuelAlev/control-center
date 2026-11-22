import 'package:cc_infra/src/newsfeed/summary_text.dart';
import 'package:test/test.dart';

void main() {
  group('summaryTextFromHtml', () {
    test('drops a trailing link-only block and its blank lines', () {
      // Product Hunt's item description, indentation included.
      const html = '''
<p>
          Motion design in your browser
        </p>
        <p>
          <a href="https://www.producthunt.com/products/nuko">Discussion</a>
          |
          <a href="https://www.producthunt.com/r/p/1">Link</a>
        </p>
''';
      expect(summaryTextFromHtml(html), 'Motion design in your browser');
    });

    test('separates block text with a single space', () {
      expect(
        summaryTextFromHtml('<p>First line.</p><p>Second\n\n  line.</p>'),
        'First line. Second line.',
      );
    });

    test('keeps inline formatting joined', () {
      expect(summaryTextFromHtml('foo<b>bar</b> baz'), 'foobar baz');
    });

    test('keeps links that sit inside prose', () {
      expect(
        summaryTextFromHtml('<p>Read <a href="x">the post</a> today.</p>'),
        'Read the post today.',
      );
    });

    test('keeps a summary that is only a link', () {
      expect(
        summaryTextFromHtml('<p><a href="x">The whole summary</a></p>'),
        'The whole summary',
      );
    });

    test('returns empty for blank input', () {
      expect(summaryTextFromHtml('  \n '), isEmpty);
    });
  });
}
