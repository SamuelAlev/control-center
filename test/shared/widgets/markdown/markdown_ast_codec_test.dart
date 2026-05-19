import 'package:cc_markdown/parser.dart';
import 'package:flutter_test/flutter_test.dart';

/// The markdown offload's correctness gate: the AST↔primitive codec must
/// round-trip a parsed document to a VALUE-EQUAL document. If it does, seeding
/// `CcMarkdownCache` with the worker's reconstructed nodes is indistinguishable
/// from a synchronous parse, so the offload can never change what renders.
void main() {
  const parser = CcParser(
    plugins: CcPluginSet.empty,
    options: CcParseOptions(),
  );

  void expectRoundTrips(String source) {
    final original = parser.parseDocument(source);
    final restored = decodeCcDocument(encodeCcDocument(original));

    expect(
      restored.blocks.length,
      original.blocks.length,
      reason: 'block count',
    );
    for (var i = 0; i < original.blocks.length; i++) {
      expect(
        restored.blocks[i],
        original.blocks[i],
        reason: 'block $i value-equal',
      );
    }
    expect(
      restored.footnotes.length,
      original.footnotes.length,
      reason: 'footnote count',
    );
    for (var i = 0; i < original.footnotes.length; i++) {
      expect(
        restored.footnotes[i],
        original.footnotes[i],
        reason: 'footnote $i value-equal',
      );
    }
    expect(
      restored.linkRefs.length,
      original.linkRefs.length,
      reason: 'linkRef count',
    );
    for (final key in original.linkRefs.keys) {
      expect(
        restored.linkRefs[key],
        original.linkRefs[key],
        reason: 'linkRef $key',
      );
    }
  }

  test(
    'round-trips a rich GitHub-flavored document (every core node type)',
    () {
      const source = '''
# Heading 1

## Heading 2

Some **bold**, *italic*, ~~strike~~, `code` and [a link](https://example.com "title").

An autolink: <https://auto.example.com>

![alt text](https://img.example.com/x.png "caption")

- bullet one
- [x] done task
- [ ] pending task

1. first
2. second

> a blockquote
> spanning lines

```dart
final int x = 1;
print(x);
```

| Left | Center | Right |
|:-----|:------:|------:|
| a    | b      | c     |

<details><summary>Details summary</summary>

hidden body paragraph

</details>

A paragraph referencing a footnote[^note].

[^note]: The footnote definition.

[ref]: https://ref.example.com "ref title"

Using a [reference link][ref].

***
''';
      expectRoundTrips(source);
    },
  );

  test('round-trips an empty and a plain document', () {
    expectRoundTrips('');
    expectRoundTrips('just a single plain paragraph with no markup');
  });

  test('round-trips nested emphasis and links inside lists and quotes', () {
    const source = '''
> outer quote with **bold [link](https://a.com)** inside

- item with `inline code` and *em with __strong__ nested*
  - nested bullet
''';
    expectRoundTrips(source);
  });
}
