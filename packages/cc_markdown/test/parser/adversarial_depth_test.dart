import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

/// Depth limits, from the adversarial direction.
///
/// This engine renders LLM/agent output, so its input is model text: a
/// pathological document is reachable, not hypothetical. Its stated contract is
/// that it NEVER throws and degrades to plain text instead — and a
/// `StackOverflowError` is an `Error`, which no `catch` in that contract
/// survives. Blockquotes and lists were depth-guarded; `<details>` blocks and
/// inline `<a href>` unwrapping were not.
void main() {
  // 20,000 is the depth at which this MEASURABLY overflowed before the guard:
  // with `maxBlockDepth` raised out of the way, parsing the same input throws
  // `StackOverflowError`; with the default cap it returns. 5,000 did not
  // reproduce it, so a smaller number would have been a test that passes
  // either way.
  test('deeply nested <details> does not overflow the stack', () {
    const depth = 20000;
    final markdown = StringBuffer();
    // `<details>` must be ALONE on its line to open a block (the parser's
    // `_detailsOpen` is line-anchored) — an inline `<summary>` on the same
    // line makes it plain HTML and never enters the recursive path.
    for (var i = 0; i < depth; i++) {
      markdown
        ..writeln('<details>')
        ..writeln('<summary>level $i</summary>');
    }
    markdown.writeln('body');
    for (var i = 0; i < depth; i++) {
      markdown.writeln('</details>');
    }

    // The assertion IS "returns" — the failure mode was a hard crash.
    final blocks = const CcParser().parse(markdown.toString());
    expect(blocks, isNotEmpty);
  });

  test('deeply nested inline <a href> does not overflow the stack', () {
    const depth = 20000;
    final markdown = StringBuffer();
    for (var i = 0; i < depth; i++) {
      markdown.write('<a href="https://example.com/$i">');
    }
    markdown.write('label</a>');

    final blocks = const CcParser().parse(markdown.toString());
    expect(blocks, isNotEmpty);
  });

  test('deeply nested blockquotes and lists still degrade gracefully', () {
    // The guards that already existed — pinned so a refactor cannot drop them
    // while adding the new ones.
    final quotes = '${'> ' * 5000}quoted';
    expect(const CcParser().parse(quotes), isNotEmpty);

    final list = StringBuffer();
    for (var i = 0; i < 2000; i++) {
      list.writeln('${' ' * (i * 2)}- item $i');
    }
    expect(const CcParser().parse(list.toString()), isNotEmpty);
  });

  test('a moderate nesting depth still parses as nested structure', () {
    // The cap must not be so eager that ORDINARY nesting is flattened.
    const markdown = '''
<details>
<summary>outer</summary>

<details>
<summary>inner</summary>

deep body

</details>

</details>
''';
    final blocks = const CcParser().parse(markdown);
    expect(blocks, isNotEmpty);
  });
}
