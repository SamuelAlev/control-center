import 'package:cc_harness/context.dart';
import 'package:cc_harness/messages.dart';
import 'package:test/test.dart';

/// Evidence derived from tool calls counts a script's nested calls, recorded
/// on its result block, exactly as it counts direct calls.
void main() {
  const ref = ToolOutputReference(
    handle: 'out_abcdefghijklmnopqrstuv',
    toolName: 'repl',
    byteLength: 40000,
    charLength: 40000,
  );
  final big = 'x' * 40000;

  List<HarnessMessage> scriptTurn(List<HarnessNestedToolCall> nested) => [
    HarnessMessage.user('q0'),
    const HarnessMessage(
      role: HarnessRole.assistant,
      content: [
        HarnessToolUseBlock(
          id: 'r0',
          name: 'repl',
          input: {'code': 'return 1', 'description': 'probe'},
        ),
      ],
    ),
    HarnessMessage.toolResults([
      HarnessToolResultBlock(
        toolUseId: 'r0',
        content: big,
        outputReference: ref,
        nestedCalls: nested,
      ),
    ]),
    HarnessMessage.user('q1'),
    HarnessMessage.user('q2'),
  ];

  test('identifying arguments keep paths and drop payloads', () {
    expect(
      identifyingToolArgs({
        'path': 'lib/a.dart',
        'old_text': 'x' * 5000,
        'new_text': 'y',
        'edits': [
          {'path': 'lib/b.dart', 'old_text': 'p', 'new_text': 'q'},
        ],
        'command': 'c' * 400,
      }),
      {
        'path': 'lib/a.dart',
        'edits': [
          {'path': 'lib/b.dart'},
        ],
        'command': '${'c' * 256}…',
      },
    );
  });

  test('a nested edit is an active edit target', () {
    final h = scriptTurn(const [
      HarnessNestedToolCall(name: 'edit', args: {'path': 'lib/live.dart'}),
      HarnessNestedToolCall(name: 'read', args: {'path': 'lib/other.dart'}),
    ]);
    expect(collectActiveEditTargets(h), {'lib/live.dart'});
  });

  test('a script result that edited the active file is not masked', () {
    final h = [
      ...scriptTurn(const [
        HarnessNestedToolCall(name: 'edit', args: {'path': 'lib/live.dart'}),
      ]),
    ];
    final result = maskStaleObservations(
      h,
      keepTurns: 1,
      minObservationTokens: 200,
    );
    expect(result.maskedCount, 0);
  });

  test('a script result that wrote the checklist is not masked or pruned', () {
    final h = scriptTurn(const [
      HarnessNestedToolCall(name: 'todo_write', args: {}),
    ]);
    final block = h[2].content.single as HarnessToolResultBlock;
    expect(nestedCallsProtected(block), isTrue);
    expect(
      maskStaleObservations(
        h,
        keepTurns: 1,
        minObservationTokens: 200,
      ).maskedCount,
      0,
    );
  });

  test('an uneventful script result is still masked', () {
    final h = scriptTurn(const [
      HarnessNestedToolCall(name: 'read', args: {'path': 'lib/a.dart'}),
    ]);
    expect(
      maskStaleObservations(
        h,
        keepTurns: 1,
        minObservationTokens: 200,
      ).maskedCount,
      1,
    );
  });

  test('the summarizer evidence names the nested calls', () {
    final h = scriptTurn(const [
      HarnessNestedToolCall(name: 'edit', args: {'path': 'lib/live.dart'}),
      HarnessNestedToolCall(
        name: 'bash',
        args: {'command': 'dart test'},
        isError: true,
      ),
    ]);
    final text = serializeHarnessHistory(
      h,
      activeEditTargets: const {'lib/live.dart'},
    );
    expect(text, contains('(nested call: edit {"path":"lib/live.dart"})'));
    expect(
      text,
      contains('(nested call: bash {"command":"dart test"}, error)'),
    );
    expect(text, contains('[active edit]'));
  });
}
