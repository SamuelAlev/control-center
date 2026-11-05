import 'package:control_center/shared/widgets/markdown/markdown_links.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('isOpenableMarkdownLink', () {
    test('accepts web and mail links', () {
      expect(isOpenableMarkdownLink('https://example.com/a?b=1#c'), isTrue);
      expect(isOpenableMarkdownLink('http://localhost:3000'), isTrue);
      expect(isOpenableMarkdownLink('HTTPS://Example.com'), isTrue);
      expect(isOpenableMarkdownLink('  https://example.com  '), isTrue);
      expect(isOpenableMarkdownLink('mailto:someone@example.com'), isTrue);
    });

    test('rejects schemes that could launch local software', () {
      expect(isOpenableMarkdownLink('file:///etc/passwd'), isFalse);
      expect(isOpenableMarkdownLink('javascript:alert(1)'), isFalse);
      expect(isOpenableMarkdownLink('vscode://file/tmp/x'), isFalse);
      expect(isOpenableMarkdownLink('smb://host/share'), isFalse);
    });

    test('rejects targets with nothing to resolve against', () {
      expect(isOpenableMarkdownLink('#section'), isFalse);
      expect(isOpenableMarkdownLink('docs/README.md'), isFalse);
      expect(isOpenableMarkdownLink('https://'), isFalse);
      expect(isOpenableMarkdownLink('mailto:'), isFalse);
      expect(isOpenableMarkdownLink(''), isFalse);
      expect(isOpenableMarkdownLink('http://[::1'), isFalse);
    });
  });
}
