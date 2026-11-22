import 'package:cc_domain/features/code_mode/domain/services/script_result_formatter.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_outcome.dart';
import 'package:cc_harness/context.dart';
import 'package:test/test.dart';

const _formatter = ScriptResultFormatter();

ScriptCallSummary _c(String name, NestedCallStatus status) =>
    ScriptCallSummary(name: name, status: status);

List<ScriptCallSummary> _sevenCalls() => [
  for (var i = 0; i < 6; i++) _c('search', NestedCallStatus.completed),
  _c('bash', NestedCallStatus.failed),
];

void main() {
  group('first line', () {
    test('completed, with counts by outcome', () {
      final r = _formatter.format(
        CodeExecutionOutcome(
          status: CodeExecutionStatus.completed,
          durationMs: 2400,
          calls: _sevenCalls(),
          output: const [ScriptTextOutput('3 files match')],
        ),
        budgetTokens: 10000,
      );
      expect(
        r.text,
        'Script completed in 2.4 s · 7 tool calls (6 ok, 1 failed)\n'
        '3 files match',
      );
      expect(r.isError, isFalse);
      expect(r.truncated, isFalse);
    });

    test('no calls and one call', () {
      expect(
        _formatter.firstLine(
          CodeExecutionOutcome(
            status: CodeExecutionStatus.completed,
            durationMs: 300,
          ),
        ),
        'Script completed in 0.3 s · no tool calls',
      );
      expect(
        _formatter.firstLine(
          CodeExecutionOutcome(
            status: CodeExecutionStatus.completed,
            durationMs: 12400,
            calls: [_c('read', NestedCallStatus.denied)],
          ),
        ),
        'Script completed in 12 s · 1 tool call (1 denied)',
      );
    });

    test('every status has its own first line', () {
      final lines = <CodeExecutionStatus, String>{};
      // A running script has no outcome yet.
      final ended = [
        for (final status in CodeExecutionStatus.values)
          if (status.isTerminal) status,
      ];
      for (final status in ended) {
        lines[status] = _formatter.firstLine(
          CodeExecutionOutcome(
            status: status,
            durationMs: 1000,
            detail: status == CodeExecutionStatus.refused
                ? 'the script is larger than 256 KiB'
                : null,
          ),
        );
      }
      expect(lines.values.toSet(), hasLength(ended.length));
      expect(
        () => CodeExecutionOutcome(
          status: CodeExecutionStatus.running,
          durationMs: 0,
        ),
        throwsArgumentError,
      );
      expect(
        lines[CodeExecutionStatus.failed],
        'Script failed after 1.0 s · no tool calls',
      );
      expect(
        lines[CodeExecutionStatus.timedOut],
        'Script timed out after 1.0 s · no tool calls',
      );
      expect(
        lines[CodeExecutionStatus.cancelled],
        'Script cancelled after 1.0 s · no tool calls',
      );
      expect(
        lines[CodeExecutionStatus.memoryExceeded],
        'Script ran out of memory after 1.0 s · no tool calls',
      );
      expect(
        lines[CodeExecutionStatus.outputExceeded],
        'Script stopped after 1.0 s: too much output · no tool calls',
      );
      expect(
        lines[CodeExecutionStatus.sandboxError],
        'Script sandbox failed after 1.0 s · no tool calls',
      );
      expect(
        lines[CodeExecutionStatus.refused],
        'Script refused: the script is larger than 256 KiB',
      );
    });

    test('long durations read in minutes', () {
      expect(
        _formatter.firstLine(
          CodeExecutionOutcome(
            status: CodeExecutionStatus.timedOut,
            durationMs: 300000,
          ),
        ),
        'Script timed out after 5 min · no tool calls',
      );
      expect(
        _formatter.firstLine(
          CodeExecutionOutcome(
            status: CodeExecutionStatus.timedOut,
            durationMs: 303000,
          ),
        ),
        'Script timed out after 5 min 3 s · no tool calls',
      );
    });
  });

  group('failure', () {
    test('keeps partial output, the error and the calls already made', () {
      final r = _formatter.format(
        CodeExecutionOutcome(
          status: CodeExecutionStatus.failed,
          durationMs: 1200,
          output: const [ScriptTextOutput('partial')],
          error: const ScriptError(
            name: 'TypeError',
            message: "Cannot read properties of undefined (reading 'path')",
            line: 14,
            column: 22,
          ),
          calls: [
            _c('search', NestedCallStatus.completed),
            _c('edit', NestedCallStatus.completed),
            _c('bash', NestedCallStatus.failed),
          ],
        ),
        budgetTokens: 10000,
      );
      expect(
        r.text,
        'Script failed after 1.2 s · 3 tool calls (2 ok, 1 failed)\n'
        'partial\n'
        '\n'
        'Script error:\n'
        "TypeError: Cannot read properties of undefined (reading 'path')\n"
        '    at repl.js:14:22\n'
        '\n'
        'Tool calls made before the failure (they are not undone): '
        'search (ok), edit (ok), bash (failed)',
      );
      expect(r.isError, isTrue);
    });

    test('a stack from the runner is used as given', () {
      final r = _formatter.format(
        CodeExecutionOutcome(
          status: CodeExecutionStatus.failed,
          durationMs: 10,
          error: const ScriptError(
            name: 'Error',
            message: 'nope',
            line: 3,
            stack: '    at helper (repl.js:3:9)\n    at repl.js:7:1\n',
          ),
        ),
        budgetTokens: 10000,
      );
      expect(
        r.text,
        endsWith(
          'Script error:\nError: nope\n    at helper (repl.js:3:9)\n'
          '    at repl.js:7:1',
        ),
      );
    });

    test('abnormal ends carry their detail and say the calls stand', () {
      final r = _formatter.format(
        CodeExecutionOutcome(
          status: CodeExecutionStatus.timedOut,
          durationMs: 300000,
          detail: 'The wall-clock limit is 300 s.',
          calls: [_c('bash', NestedCallStatus.cancelled)],
        ),
        budgetTokens: 10000,
      );
      expect(
        r.text,
        'Script timed out after 5 min · 1 tool call (1 cancelled)\n'
        'The wall-clock limit is 300 s.\n'
        '\n'
        'Tool calls made before the script stopped (they are not undone): '
        'bash (cancelled)',
      );
    });

    test('long call lists group repeats and keep both ends', () {
      final calls = <ScriptCallSummary>[
        for (var i = 0; i < 40; i++) ...[
          _c('read_$i', NestedCallStatus.completed),
          _c('read_$i', NestedCallStatus.completed),
        ],
      ];
      final r = _formatter.format(
        CodeExecutionOutcome(
          status: CodeExecutionStatus.cancelled,
          durationMs: 10,
          calls: calls,
        ),
        budgetTokens: 10000,
      );
      expect(r.text, contains('read_0 (ok) ×2'));
      expect(r.text, contains('… 22 more …'));
      expect(r.text, contains('read_39 (ok) ×2'));
      expect(r.text, isNot(contains('read_25 (ok)')));
    });
  });

  group('syntax hints', () {
    CodeExecutionOutcome syntax(String source) => CodeExecutionOutcome(
      status: CodeExecutionStatus.failed,
      durationMs: 5,
      error: const ScriptError(
        name: 'SyntaxError',
        message: 'unexpected token',
        line: 1,
        column: 7,
      ),
      source: source,
    );

    test('an import gets the module hint', () {
      final r = _formatter.format(
        syntax("import fs from 'fs';\nreturn 1"),
        budgetTokens: 10000,
      );
      expect(r.text, contains('Hint: scripts cannot `import`'));
      expect(
        _formatter
            .format(syntax("const x = require('fs')"), budgetTokens: 10000)
            .text,
        contains('Hint: scripts cannot `import`'),
      );
    });

    test('a type annotation gets the TypeScript hint', () {
      for (final source in [
        'const x: string = "a"',
        'function f(a: number) { return a }',
        'interface Foo { a: string }',
        'type X = { a: string }',
        'const y = (await tools.read({})) as Result',
        'async function g(): Promise<void> {}',
      ]) {
        expect(
          _formatter.format(syntax(source), budgetTokens: 10000).text,
          contains('Hint: this looks like TypeScript.'),
          reason: source,
        );
      }
    });

    test('no hint for plain JavaScript or other errors', () {
      expect(
        _formatter
            .format(syntax('const x = {a: 1}; return x'), budgetTokens: 10000)
            .text,
        isNot(contains('Hint:')),
      );
      final typeError = CodeExecutionOutcome(
        status: CodeExecutionStatus.failed,
        durationMs: 5,
        error: const ScriptError(name: 'TypeError', message: 'x'),
        source: 'const x: string = 1',
      );
      expect(
        _formatter.format(typeError, budgetTokens: 10000).text,
        isNot(contains('Hint:')),
      );
    });
  });

  group('output', () {
    test('items in order, console levels, images and the return value', () {
      final r = _formatter.format(
        CodeExecutionOutcome(
          status: CodeExecutionStatus.completed,
          durationMs: 100,
          output: const [
            ScriptConsoleOutput(level: ScriptConsoleLevel.log, text: 'start'),
            ScriptTextOutput('middle'),
            ScriptConsoleOutput(
              level: ScriptConsoleLevel.warn,
              text: 'careful',
            ),
            ScriptImageOutput(mediaType: 'image/png', data: 'AAAAAAAA'),
            ScriptConsoleOutput(level: ScriptConsoleLevel.error, text: 'bad'),
          ],
          returnValue: const ScriptTextOutput('{"done": true}'),
        ),
        budgetTokens: 10000,
      );
      expect(
        r.text,
        'Script completed in 0.1 s · no tool calls\n'
        'start\n'
        'middle\n'
        '[warn] careful\n'
        '[image: image/png, 6 B]\n'
        '[error] bad\n'
        '{"done": true}',
      );
      expect(r.images, hasLength(1));
    });

    test('at most four images reach the model', () {
      final r = _formatter.format(
        CodeExecutionOutcome(
          status: CodeExecutionStatus.completed,
          durationMs: 1,
          output: [
            for (var i = 0; i < 6; i++)
              ScriptImageOutput(mediaType: 'image/png', data: 'img$i'),
          ],
        ),
        budgetTokens: 10000,
      );
      expect(r.images.map((i) => i.data), ['img0', 'img1', 'img2', 'img3']);
    });

    test('over the budget keeps head and tail and names the reference', () {
      final lines = [for (var i = 0; i < 2000; i++) 'line $i of the output'];
      final outcome = CodeExecutionOutcome(
        status: CodeExecutionStatus.completed,
        durationMs: 1,
        output: [ScriptTextOutput(lines.join('\n'))],
      );
      final full = _formatter.renderOutput(outcome);
      expect(_formatter.exceedsBudget(full, 1000), isTrue);
      const reference = ToolOutputReference(
        handle: 'out_123',
        toolName: 'repl',
        byteLength: 1,
        charLength: 1,
      );
      final r = _formatter.format(
        outcome,
        budgetTokens: 1000,
        fullOutput: reference,
      );
      expect(r.truncated, isTrue);
      expect(r.outputChars, full.length);
      expect(r.text, contains('line 0 of the output'));
      expect(r.text, contains('line 1999 of the output'));
      expect(r.text, isNot(contains('line 1000 of the output')));
      final marker = RegExp(
        r'\[output omitted: (\d+) chars; resume with '
        r'read_output\(handle: "out_123", offset: (\d+)\)\]',
      ).firstMatch(r.text)!;
      final offset = int.parse(marker.group(2)!);
      final omitted = int.parse(marker.group(1)!);
      // The offset points at the first omitted character of the stored text.
      final head = r.text.substring(
        r.text.indexOf('\n') + 1,
        r.text.indexOf('\n[output omitted'),
      );
      expect(full.substring(0, offset), head);
      expect(full.substring(offset + omitted), r.text.split(']\n').last);
      final outputTokens = TokenEstimator.instance.estimate(
        r.text.substring(r.text.indexOf('\n') + 1),
      );
      expect(outputTokens, lessThanOrEqualTo(1000));
      // The head and tail both end on whole lines.
      expect(head, endsWith('of the output'));
    });

    test('without a stored copy the marker says so', () {
      final r = _formatter.format(
        CodeExecutionOutcome(
          status: CodeExecutionStatus.completed,
          durationMs: 1,
          output: [ScriptTextOutput('x' * 100000)],
        ),
        budgetTokens: 200,
      );
      expect(r.text, contains('(original not stored)]'));
    });
  });

  group('questions', () {
    test('every question and answer is appended verbatim', () {
      final r = _formatter.format(
        CodeExecutionOutcome(
          status: CodeExecutionStatus.completed,
          durationMs: 60000,
          calls: [
            _c('ask_user', NestedCallStatus.completed),
            _c('ask_user', NestedCallStatus.completed),
            _c('ask_user', NestedCallStatus.timedOut),
          ],
          questions: const [
            ScriptQuestionRecord(
              question: 'Which database?',
              options: ['Postgres', 'SQLite'],
              selected: ['Postgres'],
              text: 'Use the managed one,\nnot a container.',
            ),
            ScriptQuestionRecord(question: 'Ship today?', skipped: true),
            ScriptQuestionRecord(question: 'Anything else?', answered: false),
          ],
        ),
        budgetTokens: 10000,
      );
      expect(
        r.text,
        'Script completed in 60 s · 3 tool calls (2 ok, 1 timed out)\n'
        '\n'
        'The script asked the person 3 questions. Their answers, verbatim:\n'
        '\n'
        'Question 1: Which database?\n'
        'Options: Postgres, SQLite\n'
        'Selected: Postgres\n'
        'Wrote: Use the managed one,\nnot a container.\n'
        '\n'
        'Question 2: Ship today?\n'
        'Skipped: they left the choice to you.\n'
        '\n'
        'Question 3: Anything else?\n'
        'No answer: the question timed out or was dismissed.',
      );
    });

    test('questions come last, after an error and the call list', () {
      final r = _formatter.format(
        CodeExecutionOutcome(
          status: CodeExecutionStatus.failed,
          durationMs: 5,
          error: const ScriptError(name: 'Error', message: 'x'),
          calls: [_c('ask_user', NestedCallStatus.completed)],
          questions: const [
            ScriptQuestionRecord(question: 'Go?', selected: ['Yes']),
          ],
        ),
        budgetTokens: 10000,
      );
      expect(r.text, endsWith('Question 1: Go?\nSelected: Yes'));
      expect(
        r.text.indexOf('Tool calls made'),
        lessThan(r.text.indexOf('asked the person')),
      );
    });

    test('questions are never cut by the output budget', () {
      final r = _formatter.format(
        CodeExecutionOutcome(
          status: CodeExecutionStatus.completed,
          durationMs: 5,
          output: [ScriptTextOutput('y' * 50000)],
          questions: [ScriptQuestionRecord(question: 'Q', text: 'z' * 3000)],
        ),
        budgetTokens: 100,
      );
      expect(r.text, contains('z' * 3000));
    });
  });

  test('a refused outcome cannot carry calls', () {
    expect(
      () => CodeExecutionOutcome(
        status: CodeExecutionStatus.refused,
        durationMs: 0,
        calls: [_c('read', NestedCallStatus.completed)],
      ),
      throwsArgumentError,
    );
  });

  test('notes are bounded and share the budget with the output', () {
    final outcome = CodeExecutionOutcome(
      status: CodeExecutionStatus.completed,
      durationMs: 10,
      notes: [
        for (var i = 0; i < 1000; i++) 'note $i: ${'n' * 1000}\nsecond line',
      ],
    );
    expect(
      outcome.notes,
      hasLength(CodeExecutionOutcome.maxNotes),
      reason: 'four notes and the line saying how many were left out',
    );
    for (final note in outcome.notes) {
      expect(note.length, lessThanOrEqualTo(CodeExecutionOutcome.maxNoteChars));
      expect(note, isNot(contains('\n')));
    }
    expect(outcome.notes.last, contains('996 more notes'));
    final result = _formatter.format(outcome, budgetTokens: 100);
    expect(result.text.length, lessThan(1000));
    expect(result.truncated, isTrue);
  });
}
