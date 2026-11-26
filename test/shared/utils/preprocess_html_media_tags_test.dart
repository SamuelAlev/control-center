import 'package:cc_markdown/parser.dart';
import 'package:control_center/shared/utils/github_markdown_preprocessor.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('preprocessHtmlMediaTags', () {
    test('sized images keep a table row at its column count', () {
      const row =
          '|Fonts|<img width="352" height="163" alt="image" src="https://example.com/a.png" />'
          '|<img width="341" height="194" alt="image" src="https://example.com/b.png" />|';

      final out = preprocessHtmlMediaTags(row);

      // A pipe inside the alt text would split the cell in two.
      expect('|'.allMatches(out).length, '|'.allMatches(row).length);
      expect(out, contains('](https://example.com/a.png)'));
      expect(out, contains('](https://example.com/b.png)'));
    });

    test('a pipe or bracket in the alt text survives inside a table', () {
      for (final sourceAlt in [
        'before | after [v2]',
        r'before \| after [v2]',
      ]) {
        final out = preprocessHtmlMediaTags(
          '|Page|Shot|\n|---|---|\n'
          '|Fonts|<img width="10" alt="$sourceAlt" src="https://example.com/a.png" />|',
        );

        final table = const CcParser().parse(out).single as CcTable;
        final row = table.rows.single;
        expect(row, hasLength(2));
        final image = row[1].children.single as CcImage;
        expect(image.url, 'https://example.com/a.png');
        expect(decodeAltWithDimensions(image.alt).alt, 'before | after [v2]');
      }
    });

    test('a pipe or bracket in the alt text survives outside a table', () {
      final out = preprocessHtmlMediaTags(
        '<img alt="before | after [v2]" src="https://example.com/a.png" />',
      );

      final paragraph = const CcParser().parse(out).single as CcParagraph;
      final image = paragraph.children.single as CcImage;
      expect(image.alt, 'before | after [v2]');
    });

    test('dimensions round-trip through the alt text', () {
      final out = preprocessHtmlMediaTags(
        '<img width="352" height="163" alt="a shot" src="https://example.com/a.png" />',
      );
      final alt = RegExp(r'!\[(.*?)\]').firstMatch(out)!.group(1);

      final decoded = decodeAltWithDimensions(alt);

      expect(decoded.alt, 'a shot');
      expect(decoded.hint.width, 352);
      expect(decoded.hint.height, 163);
    });
  });
}
