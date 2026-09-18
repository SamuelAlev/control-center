import 'package:cc_markdown/cc_markdown.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('findMarkdownTaskListItems', () {
    test('finds unchecked and checked items in document order', () {
      const src = '- [ ] one\n- [x] two\n- [X] three\n- not a task';
      final items = findMarkdownTaskListItems(src);
      expect(items, hasLength(3));
      expect(items.map((i) => i.checked).toList(), [false, true, true]);
    });

    test('counts nested list items and blockquoted tasks', () {
      const src = '''
- [ ] parent
  - [ ] child
> - [x] quoted
''';
      expect(findMarkdownTaskListItems(src), hasLength(3));
    });

    test('skips fenced examples (backtick and tilde)', () {
      const src = '''
```
- [ ] in backticks
```

~~~
- [ ] in tildes
~~~

- [ ] real
''';
      expect(findMarkdownTaskListItems(src), hasLength(1));
    });

    test('skips a task list wrapped in an HTML comment', () {
      const src = '''
<!--
- [ ] hidden
-->
- [ ] visible
''';
      expect(findMarkdownTaskListItems(src), hasLength(1));
    });

    test('still counts a checkbox that carries an HTML comment after the box', () {
      const src =
          ' - [ ] <!-- rebase-check -->If you want to rebase/retry this PR, '
          'check this box';
      expect(findMarkdownTaskListItems(src), hasLength(1));
      expect(findMarkdownTaskListItems(src).single.checked, isFalse);
    });
  });

  group('toggleMarkdownTaskListItem', () {
    test('ticks an empty box and unticks a filled one', () {
      const src = '- [ ] a\n- [x] b';
      expect(toggleMarkdownTaskListItem(src, 0), '- [x] a\n- [x] b');
      expect(toggleMarkdownTaskListItem(src, 1), '- [ ] a\n- [ ] b');
    });

    test('preserves a Renovate rebase-check HTML comment', () {
      const src =
          ' - [ ] <!-- rebase-check -->If you want to rebase/retry this PR, '
          'check this box';
      final next = toggleMarkdownTaskListItem(src, 0);
      expect(next, contains('[x]'));
      expect(next, contains('<!-- rebase-check -->'));
      expect(next, isNot(contains('[ ]')));
    });

    test('does not rewrite a checkbox inside a fence', () {
      const src = '```\n- [ ] sample\n```\n\n- [ ] real';
      final next = toggleMarkdownTaskListItem(src, 0)!;
      expect(next, contains('- [ ] sample'));
      expect(next, contains('- [x] real'));
    });

    test('returns null when the index is out of range', () {
      expect(toggleMarkdownTaskListItem('- [ ] a', 1), isNull);
      expect(toggleMarkdownTaskListItem('no boxes', 0), isNull);
    });

    test('matches the parser\'s task-item count on a Renovate-shaped body', () {
      const src = '''
This PR contains the following updates:

---

 - [ ] <!-- rebase-check -->If you want to rebase/retry this PR, check this box

---

<!--renovate-debug:eyJ9-->
''';
      expect(findMarkdownTaskListItems(src), hasLength(1));
      expect(_astTaskCount(src), 1);
    });
  });
}

int _astTaskCount(String source) {
  final blocks = const CcParser().parse(source);
  var n = 0;
  void walk(List<CcBlockNode> nodes) {
    for (final node in nodes) {
      if (node is CcList) {
        for (final item in node.items) {
          if (item.checked != null) {
            n++;
          }
          walk(item.children);
        }
      } else if (node is CcBlockquote) {
        walk(node.children);
      } else if (node is CcDetails) {
        walk(node.children);
      }
    }
  }

  walk(blocks);
  return n;
}
