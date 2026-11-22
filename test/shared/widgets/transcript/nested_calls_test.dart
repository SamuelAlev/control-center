import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_result_formatter.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_outcome.dart';
import 'package:control_center/shared/widgets/transcript/util/nested_calls.dart';
import 'package:control_center/shared/widgets/transcript/util/script_status_line.dart';
import 'package:flutter_test/flutter_test.dart';

final _ts = DateTime.fromMillisecondsSinceEpoch(1700000000000);

ToolSegment _tool(
  String id, {
  String name = 'read',
  String? parent,
  ToolSegmentStatus status = ToolSegmentStatus.ok,
  String outputs = '',
  String? outcome,
}) => ToolSegment(
  toolName: name,
  toolCallId: id,
  startedAt: _ts,
  status: status,
  outputs: outputs,
  parentToolCallId: parent,
  outcome: outcome,
);

void main() {
  group('foldNestedCalls', () {
    test('folds a script\'s calls under it, in list order', () {
      final segments = <TranscriptSegment>[
        TextSegment(text: 'hi', startedAt: _ts),
        _tool('r1', name: 'repl'),
        _tool('r1/1', parent: 'r1'),
        _tool('r1/2', name: 'edit', parent: 'r1'),
        _tool('d1', name: 'bash'),
        _tool('r1/3', parent: 'r1'),
      ];
      expect(foldNestedCalls(segments), {
        1: [2, 3, 5],
      });
    });

    test('a call whose parent is missing is not folded', () {
      final segments = <TranscriptSegment>[
        _tool('r1/1', parent: 'r1'),
        _tool('d1', name: 'bash'),
      ];
      expect(foldNestedCalls(segments), isEmpty);
    });

    test('calls fold under the MCP repl as under the built-in one, and '
        'never under eval', () {
      final segments = <TranscriptSegment>[
        _tool('e1', name: 'eval'),
        _tool('e1/1', parent: 'e1'),
        _tool('m1', name: 'mcp__control-center__repl'),
        _tool('m1/1', parent: 'm1'),
      ];
      expect(foldNestedCalls(segments), {
        2: [3],
      });
    });

    test('two scripts sharing an id each keep their own calls', () {
      // Local models reuse `call_0` on every turn; the second script's
      // calls, a destructive one among them, must not hide under the first.
      final segments = <TranscriptSegment>[
        _tool('call_0', name: 'repl'),
        _tool('call_0/1', parent: 'call_0'),
        _tool('call_0', name: 'repl'),
        _tool('call_0/1', name: 'bash', parent: 'call_0'),
        _tool('call_0/2', name: 'edit', parent: 'call_0'),
      ];
      expect(foldNestedCalls(segments), {
        0: [1],
        2: [3, 4],
      });
    });

    test('a call whose parent is not a script stays a row of its own', () {
      // The nearest earlier row with the id is a plain tool, even though an
      // older script shares it: the call is never hidden under either.
      final segments = <TranscriptSegment>[
        _tool('call_0', name: 'repl'),
        _tool('call_0', name: 'read'),
        _tool('call_0/1', name: 'bash', parent: 'call_0'),
        _tool('t1', name: 'task'),
        _tool('t1/1', parent: 't1'),
      ];
      expect(foldNestedCalls(segments), isEmpty);
    });

    test('a script that names another call\'s id folds nothing under it', () {
      // On MCP the caller chooses the id a script's calls name. Naming an
      // earlier `Bash` row's id must not hide the script's calls under that
      // innocuous command; they stay rows of their own.
      final segments = <TranscriptSegment>[
        _tool('toolu_1', name: 'Bash'),
        _tool('toolu_2', name: 'mcp__cc__repl'),
        _tool('toolu_1/1', name: 'edit', parent: 'toolu_1'),
        _tool('toolu_1/2', name: 'bash', parent: 'toolu_1'),
      ];
      expect(foldNestedCalls(segments), isEmpty);
    });

    test('a call whose parent comes after it stays a row of its own', () {
      final segments = <TranscriptSegment>[
        _tool('r1/1', parent: 'r1'),
        _tool('r1', name: 'repl'),
        _tool('a', parent: 'b'),
        _tool('b', name: 'repl', parent: 'a'),
      ];
      expect(foldNestedCalls(segments), isEmpty);
    });
  });

  group('nestedCallStateOf', () {
    test('tells a denial from a failure by its outcome, never its text', () {
      // Real refusals that do not start with "Denied".
      for (final text in [
        'User denied: not now',
        'Requires approval but no approver is connected: write',
        'Command denied by sandbox policy: rm',
      ]) {
        expect(
          nestedCallStateOf(
            _tool(
              'x',
              status: ToolSegmentStatus.error,
              outputs: text,
              outcome: 'denied',
            ),
          ),
          NestedCallState.denied,
          reason: text,
        );
      }
      // Text that looks like a refusal is a failure without the outcome.
      expect(
        nestedCallStateOf(
          _tool('x', status: ToolSegmentStatus.error, outputs: 'Denied: no'),
        ),
        NestedCallState.failed,
      );
      expect(
        nestedCallStateOf(
          _tool('x', status: ToolSegmentStatus.error, outputs: 'boom'),
        ),
        NestedCallState.failed,
      );
      expect(
        nestedCallStateOf(_tool('x', status: ToolSegmentStatus.interrupted)),
        NestedCallState.cancelled,
      );
    });

    test('a cancelled or timed-out call is cancelled; other outcomes '
        'follow the status', () {
      for (final outcome in ['cancelled', 'timed_out']) {
        expect(
          nestedCallStateOf(
            _tool('x', status: ToolSegmentStatus.error, outcome: outcome),
          ),
          NestedCallState.cancelled,
          reason: outcome,
        );
      }
      for (final outcome in ['failed', 'unknown_tool', 'invalid_args']) {
        expect(
          nestedCallStateOf(
            _tool('x', status: ToolSegmentStatus.error, outcome: outcome),
          ),
          NestedCallState.failed,
          reason: outcome,
        );
      }
    });

    test('tally counts every outcome', () {
      final tally = NestedCallTally.of([
        _tool('a'),
        _tool('b'),
        _tool('c', status: ToolSegmentStatus.running),
        _tool('d', status: ToolSegmentStatus.error, outcome: 'denied'),
        _tool('e', status: ToolSegmentStatus.error),
        _tool('f', status: ToolSegmentStatus.error, outcome: 'timed_out'),
      ]);
      expect(
        (
          tally.ok,
          tally.running,
          tally.denied,
          tally.failed,
          tally.cancelled,
          tally.total,
        ),
        (2, 1, 1, 1, 1, 6),
      );
    });
  });

  group('script status line', () {
    const formatter = ScriptResultFormatter();
    const expected = {
      CodeExecutionStatus.completed: ScriptRunState.completed,
      CodeExecutionStatus.failed: ScriptRunState.failed,
      CodeExecutionStatus.timedOut: ScriptRunState.timedOut,
      CodeExecutionStatus.cancelled: ScriptRunState.cancelled,
      CodeExecutionStatus.memoryExceeded: ScriptRunState.memoryExceeded,
      CodeExecutionStatus.outputExceeded: ScriptRunState.outputExceeded,
      CodeExecutionStatus.sandboxError: ScriptRunState.sandboxError,
      CodeExecutionStatus.refused: ScriptRunState.refused,
    };

    test('reads back every first line the server writes', () {
      // Guards the one place the client depends on the server's English: a
      // change to `ScriptResultFormatter.firstLine` fails here.
      // A running script has no result, so no first line.
      for (final status in CodeExecutionStatus.values.where(
        (s) => s.isTerminal,
      )) {
        final refused = status == CodeExecutionStatus.refused;
        final outcome = CodeExecutionOutcome(
          status: status,
          durationMs: 2400,
          calls: refused
              ? const []
              : const [
                  ScriptCallSummary(
                    name: 'read',
                    status: NestedCallStatus.completed,
                  ),
                ],
          detail: refused ? 'code mode is off' : null,
        );
        final line = formatter.firstLine(outcome);
        final parsed = parseScriptStatusLine(line);
        expect(parsed?.state, expected[status], reason: line);
        if (refused) {
          expect(parsed?.detail, 'code mode is off');
        }
      }
    });

    test('splits the status from the output', () {
      final status = readScriptStatus(
        _tool(
          'r',
          name: 'repl',
          outputs:
              'Script completed in 2.4 s · 1 tool call (1 ok)\n{"files": 3}',
        ),
      );
      expect(status.state, ScriptRunState.completed);
      expect(status.rest, '{"files": 3}');
    });

    test('keeps unknown text whole and falls back to the segment status', () {
      final status = readScriptStatus(
        _tool('r', name: 'repl', status: ToolSegmentStatus.error, outputs: 'x'),
      );
      expect(status.state, ScriptRunState.failed);
      expect(status.rest, 'x');
    });

    test('the recorded outcome outranks the sentence', () {
      // The harness records how the script ended on the segment; a first
      // line that says otherwise is not believed.
      final recorded = readScriptStatus(
        _tool(
          'r',
          name: 'repl',
          status: ToolSegmentStatus.error,
          outputs: 'Script failed after 1.0 s · 0 tool calls\npartial',
          outcome: CodeExecutionStatus.memoryExceeded.wire,
        ),
      );
      expect(recorded.state, ScriptRunState.memoryExceeded);
      expect(recorded.rest, 'partial');

      // Every status the server records maps to its state with no status
      // line at all, and the whole output is kept.
      for (final status in CodeExecutionStatus.values) {
        final read = readScriptStatus(
          _tool(
            'r',
            name: 'repl',
            status: status == CodeExecutionStatus.completed
                ? ToolSegmentStatus.ok
                : ToolSegmentStatus.error,
            outputs: 'no status line',
            outcome: status.wire,
          ),
        );
        // The two enums share their names, value for value.
        expect(read.state.name, status.name, reason: status.wire);
        expect(read.rest, 'no status line', reason: status.wire);
      }

      // An outcome that is not an execution status (an external adapter's
      // row has none) leaves the sentence in charge.
      final external = readScriptStatus(
        _tool(
          'r',
          name: 'mcp__control-center__repl',
          status: ToolSegmentStatus.error,
          outputs: 'Script timed out after 30.0 s · 2 tool calls\nlate',
        ),
      );
      expect(external.state, ScriptRunState.timedOut);
      expect(external.rest, 'late');
    });
  });
}
