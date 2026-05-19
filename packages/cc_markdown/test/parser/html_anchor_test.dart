import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

/// Regression coverage for HTML anchors in GitHub-flavored bodies — the
/// Linear linkback shape: an `<a href>` inside `<details><summary>` and a
/// standalone `<p><a href>…</a></p>` block. Both links must survive as
/// tappable [CcLink]s instead of being stripped to plain text.
void main() {
  const parser = CcParser();

  const linearLinkback = '''
<!-- linear-linkback -->
<details>
<summary><a href="https://linear.app/usectrl/issue/FOO-309/appserver">FOO-309 TEST-APP - Handle deletion</a></summary>
<p>

When an asset has been deleted, if this asset is being used in `mdl_resource_locator`

puis lancer la syncho avec masterApi
</p>
</details>
<!-- linear-review-link -->
<p><a href="https://linear.app/usectrl/review/feat-test-app">Review in Linear</a></p>
''';

  test('details summary anchor parses into a CcLink', () {
    final doc = parser.parse(linearLinkback);
    final details = doc.whereType<CcDetails>().single;
    final link = details.summary.whereType<CcLink>().single;
    expect(link.url, 'https://linear.app/usectrl/issue/FOO-309/appserver');
    expect(
      link.children.whereType<CcText>().map((t) => t.text).join(),
      'FOO-309 TEST-APP - Handle deletion',
    );
  });

  test(
    'a <p><a href>…</a></p> block parses into a paragraph with a CcLink',
    () {
      final doc = parser.parse(linearLinkback);
      final withAnchor = doc.whereType<CcParagraph>().firstWhere(
        (p) => p.children.whereType<CcLink>().isNotEmpty,
      );
      final link = withAnchor.children.whereType<CcLink>().single;
      expect(link.url, 'https://linear.app/usectrl/review/feat-test-app');
      expect(
        link.children.whereType<CcText>().map((t) => t.text).join(),
        'Review in Linear',
      );
    },
  );

  test('htmlBlockInlineNodes strips non-anchor tags and keeps surrounding '
      'text', () {
    final nodes = htmlBlockInlineNodes(
      '<p>before <a href="https://a.b">link</a> after</p>',
    );
    expect(nodes, hasLength(3));
    expect((nodes[0] as CcText).text.trim(), 'before');
    expect((nodes[1] as CcLink).url, 'https://a.b');
    expect((nodes[2] as CcText).text.trim(), 'after');
  });

  test('htmlBlockInlineNodes with no anchors degrades to stripped text', () {
    final nodes = htmlBlockInlineNodes('<p>plain</p>');
    expect(nodes, hasLength(1));
    expect((nodes.single as CcText).text, 'plain');
    expect(htmlBlockInlineNodes('<p></p>'), isEmpty);
  });
}
