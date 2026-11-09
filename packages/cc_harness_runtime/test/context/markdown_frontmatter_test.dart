import 'package:cc_harness_runtime/src/context/markdown_frontmatter.dart';
import 'package:test/test.dart';

void main() {
  test('splits fields and body; keys are case-insensitive', () {
    final f = MarkdownFrontmatter.parse(
      '---\nName: deploy\ndescription: "Ship it"\n---\nBody line\n',
    );
    expect(f.hasHeader, isTrue);
    expect(f['name'], 'deploy');
    expect(f['NAME'], 'deploy');
    expect(f['description'], 'Ship it');
    expect(f.body, 'Body line\n');
  });

  test('strips only a MATCHED pair of quotes', () {
    // The old command/agent copies stripped any leading or trailing quote.
    final f = MarkdownFrontmatter.parse(
      '---\ndescription: Say "hi"\nmodel: \'x\'\n---\n',
    );
    expect(f['description'], 'Say "hi"');
    expect(f['model'], 'x');
  });

  test('ignores leading whitespace before the fence', () {
    final f = MarkdownFrontmatter.parse('\n\n---\nname: a\n---\nb');
    expect(f['name'], 'a');
    expect(f.body, 'b');
  });

  test('an unclosed fence is no frontmatter: the whole text is body', () {
    const raw = '---\nname: a\nno close';
    final f = MarkdownFrontmatter.parse(raw);
    expect(f.hasHeader, isFalse);
    expect(f.fields, isEmpty);
    expect(f.body, raw);
  });

  test('lines without a key are skipped; the last duplicate wins', () {
    final f = MarkdownFrontmatter.parse(
      '---\n: nokey\njust text\nmodel: a\nmodel: b\n---',
    );
    expect(f.fields, {'model': 'b'});
    expect(f.body, '');
  });
}
