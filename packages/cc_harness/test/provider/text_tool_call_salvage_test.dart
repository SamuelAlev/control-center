import 'package:cc_harness/provider.dart';
import 'package:test/test.dart';

/// Recovering tool calls a model wrote as text.
///
/// The safety property under test is as important as the parsing: the declared
/// tool list is the boundary, so no input can produce a call for a tool the run
/// does not offer and prose that merely mentions a tool is never executed.
void main() {
  const salvage = TextToolCallSalvage();
  const known = {'search_memory', 'list_repos', 'read', 'submit_plan'};

  group('qwen3_xml / qwen3_coder (the documented dialect)', () {
    test('recovers a call with its parameters', () {
      final calls = salvage.parse(
        '<tool_call>\n<function=read>\n<parameter=path>\nlib/main.dart\n'
        '</parameter>\n</function>\n</tool_call>',
        knownToolNames: known,
      );
      expect(calls, hasLength(1));
      expect(calls.single.name, 'read');
      expect(calls.single.arguments, {'path': 'lib/main.dart'});
    });

    test('recovers several calls in source order', () {
      final calls = salvage.parse(
        '<function=search_memory><parameter=query>a</parameter></function>'
        '<function=list_repos><parameter=workspace_id>w1</parameter></function>',
        knownToolNames: known,
      );
      expect(calls.map((c) => c.name), ['search_memory', 'list_repos']);
    });
  });

  group('attribute variant (the corrupted dialect seen in production)', () {
    // The function name arrives in a `parameter` tag and the block is closed by
    // `</function>`. The tool list is what disambiguates name from argument.
    test('treats a known name in a parameter tag as the call', () {
      final calls = salvage.parse(
        '<parameter name="search_memory">\n'
        '<parameter name="query">\nmessaging features\n</parameter>\n'
        '<parameter name="workspace_id">\nws-1\n</parameter>\n'
        '</function>',
        knownToolNames: known,
      );
      expect(calls, hasLength(1));
      expect(calls.single.name, 'search_memory');
      expect(calls.single.arguments, {
        'query': 'messaging features',
        'workspace_id': 'ws-1',
      });
    });

    test('recovers the full five-call sequence from the failing run', () {
      // Verbatim shape of the transcript that was thrown away.
      final calls = salvage.parse(
        '<parameter name="search_memory">\n<parameter name="query">\nmessaging\n'
        '</parameter>\n</function>\n'
        '<parameter name="list_repos">\n<parameter name="workspace_id">\nws-1\n'
        '</parameter>\n</function>\n'
        '<parameter name="submit_plan">\n<parameter name="goal">\nImprove it\n'
        '</parameter>\n<parameter name="nodes">\n'
        '[{"key": "a", "title": "A", "dependsOn": []}]\n</parameter>\n</function>',
        knownToolNames: known,
      );
      expect(calls.map((c) => c.name), [
        'search_memory',
        'list_repos',
        'submit_plan',
      ]);
      final plan = calls.last;
      expect(plan.arguments['goal'], 'Improve it');
      // `nodes` must arrive as a List, not a String, or the tool rejects it.
      expect(plan.arguments['nodes'], isA<List<dynamic>>());
      expect((plan.arguments['nodes'] as List).single, isA<Map>());
    });

    test('keeps a call that was cut off mid-stream', () {
      // A truncated turn still carries usable intent; discarding it is the loss
      // this whole mechanism exists to prevent.
      final calls = salvage.parse(
        '<parameter name="read">\n<parameter name="path">\nlib/main.dart',
        knownToolNames: known,
      );
      expect(calls, hasLength(1));
      expect(calls.single.arguments['path'], 'lib/main.dart');
    });
  });

  group('JSON dialect', () {
    test('recovers a fenced object naming a tool', () {
      final calls = salvage.parse(
        'Let me look this up.\n\n```json\n'
        '{\n  "tool": "search_memory",\n  "query": "messaging",\n'
        '  "workspace_id": "ws-1"\n}\n```',
        knownToolNames: known,
      );
      expect(calls, hasLength(1));
      expect(calls.single.name, 'search_memory');
      expect(calls.single.arguments, {
        'query': 'messaging',
        'workspace_id': 'ws-1',
      });
    });

    test('recovers the name/arguments form', () {
      final calls = salvage.parse(
        '<tool_call>{"name": "read", "arguments": {"path": "a.txt"}}</tool_call>',
        knownToolNames: known,
      );
      expect(calls.single.name, 'read');
      expect(calls.single.arguments, {'path': 'a.txt'});
    });

    test('recovers double-encoded arguments', () {
      final calls = salvage.parse(
        '<tool_call>{"name": "read", "arguments": "{\\"path\\": \\"a.txt\\"}"}'
        '</tool_call>',
        knownToolNames: known,
      );
      expect(calls.single.arguments, {'path': 'a.txt'});
    });

    test('ignores an object that is not delimited', () {
      // Prose containing a JSON-ish object must not be executed.
      final calls = salvage.parse(
        'You could call it like {"tool": "read", "path": "a.txt"} if you wanted.',
        knownToolNames: known,
      );
      expect(calls, isEmpty);
    });
  });

  group('safety boundary', () {
    test('never returns a tool that was not declared', () {
      final calls = salvage.parse(
        '<function=rm_rf><parameter=path>/</parameter></function>',
        knownToolNames: known,
      );
      expect(calls, isEmpty);
    });

    test('ignores prose that merely names a tool', () {
      final calls = salvage.parse(
        'I will now call `submit_plan` with the nodes I gathered, then stop.',
        knownToolNames: known,
      );
      expect(calls, isEmpty);
    });

    test('a parameter whose name collides with a tool stays an argument', () {
      final calls = salvage.parse(
        '<function=search_memory><parameter=read>x</parameter></function>',
        knownToolNames: known,
      );
      expect(calls, hasLength(1));
      expect(calls.single.name, 'search_memory');
      expect(calls.single.arguments, {'read': 'x'});
    });

    test('does not retype scalar arguments', () {
      // A query of `true` or an all-digit id must survive as a string.
      final calls = salvage.parse(
        '<function=search_memory><parameter=query>true</parameter>'
        '<parameter=workspace_id>12345</parameter></function>',
        knownToolNames: known,
      );
      expect(calls.single.arguments['query'], 'true');
      expect(calls.single.arguments['workspace_id'], '12345');
    });

    test('empty input and empty tool list return nothing', () {
      expect(salvage.parse('', knownToolNames: known), isEmpty);
      expect(
        salvage.parse('<function=read></function>', knownToolNames: const {}),
        isEmpty,
      );
    });

    test('ordinary prose and markdown are untouched', () {
      const prose = '''
# Findings

The messaging feature lives in `lib/features/messaging/`. Here is a snippet:

```dart
final x = <int>{1, 2};
```

That is a set literal, not a tag.
''';
      expect(salvage.parse(prose, knownToolNames: known), isEmpty);
    });

    test('malformed XML never throws', () {
      for (final input in [
        '<function=',
        '<parameter name=>',
        '</function>',
        '<tool_call>',
        '<function=read><parameter=',
        '<<>><function=read>>',
      ]) {
        expect(
          () => salvage.parse(input, knownToolNames: known),
          returnsNormally,
          reason: input,
        );
      }
    });
  });
}
