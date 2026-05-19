import 'package:control_center/features/calendar/presentation/utils/html_description.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('parseEventDescription', () {
    test('passes plain text through untouched', () {
      final parsed = parseEventDescription('Just a normal note.');
      expect(parsed.text, 'Just a normal note.');
      expect(parsed.links, isEmpty);
    });

    test('strips tags, turns <br> into newlines, decodes entities', () {
      final parsed = parseEventDescription(
        'Hello&nbsp;there<br><br>Second line &amp; more',
      );
      expect(parsed.text, 'Hello there\n\nSecond line & more');
    });

    test('extracts hyperlinks with their labels, deduplicated', () {
      final parsed = parseEventDescription(
        'Project board: <a href="https://app.clickup.com/x">ClickUp</a> '
        'and <a href="https://app.clickup.com/x">ClickUp again</a>',
      );
      expect(parsed.links, hasLength(1));
      expect(parsed.links.single.label, 'ClickUp');
      expect(parsed.links.single.url, 'https://app.clickup.com/x');
    });

    test('falls back to the URL when an anchor has no text', () {
      final parsed = parseEventDescription('<a href="https://x.test"></a>');
      expect(parsed.links.single.label, 'https://x.test');
    });

    test('collapses excessive blank lines', () {
      final parsed = parseEventDescription('A<br><br><br><br>B');
      expect(parsed.text, 'A\n\nB');
    });
  });
}
