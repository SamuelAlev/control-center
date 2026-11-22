import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_result_formatter.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/code_execution_status.dart';
import 'package:cc_domain/features/code_mode/domain/value_objects/script_outcome.dart';
import 'package:cc_remote/script_calls.dart';
import 'package:flutter_test/flutter_test.dart';

ToolSegment _seg(
  String id, {
  String name = 'read',
  String? parent,
  ToolSegmentStatus status = ToolSegmentStatus.ok,
  String outputs = '',
  String? outcome,
}) => ToolSegment(
  toolName: name,
  toolCallId: id,
  outputs: outputs,
  status: status,
  startedAt: DateTime.utc(2026),
  parentToolCallId: parent,
  outcome: outcome,
);

void main() {
  test('a script result reads back every first line the server writes', () {
    // The phone's copy of the desktop rule: a change to
    // `ScriptResultFormatter.firstLine` fails here too.
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
    // A running script has no result, so no first line.
    for (final status in CodeExecutionStatus.values.where(
      (s) => s.isTerminal,
    )) {
      final refused = status == CodeExecutionStatus.refused;
      final line = formatter.firstLine(
        CodeExecutionOutcome(
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
        ),
      );
      final read = readScriptStatus(
        _seg(
          'r',
          name: 'repl',
          status: ToolSegmentStatus.error,
          outputs: '$line\nrest',
        ),
      );
      expect(read.state, expected[status], reason: line);
      expect(read.rest, 'rest', reason: line);
      if (refused) {
        expect(read.detail, 'code mode is off');
      }
    }
  });

  test('unknown text stays whole and falls back to the segment status', () {
    final read = readScriptStatus(
      _seg('r', name: 'repl', status: ToolSegmentStatus.error, outputs: 'x'),
    );
    expect(read.state, ScriptRunState.failed);
    expect(read.rest, 'x');
  });

  test('calls fold under their script; orphans stay put, and nothing folds '
      'under eval', () {
    final folded = foldNestedCalls([
      _seg('r1', name: 'repl'),
      _seg('r1/1', parent: 'r1'),
      _seg('gone/1', parent: 'gone'),
      _seg('e1', name: 'eval'),
      _seg('e1/1', parent: 'e1'),
    ]);
    expect(folded, {
      0: [1],
    });
  });

  test('two scripts sharing an id each keep their own calls', () {
    final folded = foldNestedCalls([
      _seg('call_0', name: 'repl'),
      _seg('call_0/1', parent: 'call_0'),
      _seg('call_0', name: 'repl'),
      _seg('call_0/1', name: 'bash', parent: 'call_0'),
    ]);
    expect(folded, {
      0: [1],
      2: [3],
    });
  });

  test('a call under a non-script or a later row stays a row of its own', () {
    final folded = foldNestedCalls([
      _seg('call_0', name: 'repl'),
      _seg('call_0', name: 'read'),
      _seg('call_0/1', name: 'bash', parent: 'call_0'),
      _seg('r1/1', parent: 'r1'),
      _seg('r1', name: 'repl'),
    ]);
    expect(folded, isEmpty);
  });

  test('a script that names another call\'s id folds nothing under it', () {
    // On MCP the caller chooses the id a script's calls name: naming an
    // earlier `Bash` row's id must not hide them under that command.
    final folded = foldNestedCalls([
      _seg('toolu_1', name: 'Bash'),
      _seg('toolu_2', name: 'mcp__cc__repl'),
      _seg('toolu_1/1', name: 'edit', parent: 'toolu_1'),
      _seg('toolu_1/2', name: 'bash', parent: 'toolu_1'),
    ]);
    expect(folded, isEmpty);
  });

  test('a refused call is denied by its outcome, never its text', () {
    expect(
      nestedCallStateOf(
        _seg(
          'a',
          status: ToolSegmentStatus.error,
          outputs: 'Requires approval but no approver is connected: write',
          outcome: 'denied',
        ),
      ),
      NestedCallState.denied,
    );
    expect(
      nestedCallStateOf(
        _seg('b', status: ToolSegmentStatus.error, outputs: 'Denied by user.'),
      ),
      NestedCallState.failed,
    );
    expect(
      nestedCallStateOf(
        _seg('c', status: ToolSegmentStatus.error, outputs: 'boom'),
      ),
      NestedCallState.failed,
    );
    expect(isReplTool('mcp__control-center__repl'), isTrue);
  });

  test('a cancelled or timed-out call is cancelled; other outcomes follow '
      'the status', () {
    for (final outcome in ['cancelled', 'timed_out']) {
      expect(
        nestedCallStateOf(
          _seg('x', status: ToolSegmentStatus.error, outcome: outcome),
        ),
        NestedCallState.cancelled,
        reason: outcome,
      );
    }
    expect(
      nestedCallStateOf(
        _seg('y', status: ToolSegmentStatus.error, outcome: 'unknown_tool'),
      ),
      NestedCallState.failed,
    );
    final tally = NestedCallTally.of([
      _seg('a'),
      _seg('b', status: ToolSegmentStatus.error, outcome: 'denied'),
      _seg('c', status: ToolSegmentStatus.error, outcome: 'timed_out'),
      _seg('d', status: ToolSegmentStatus.error),
    ]);
    expect(
      (tally.ok, tally.denied, tally.cancelled, tally.failed, tally.total),
      (1, 1, 1, 1, 4),
    );
  });

  test('a repl row reads its state from the recorded outcome first', () {
    // The outcome wins over a first line that says otherwise.
    final recorded = readScriptStatus(
      _seg(
        'r',
        name: 'repl',
        status: ToolSegmentStatus.error,
        outputs: 'Script failed after 1.0 s · 0 tool calls\npartial',
        outcome: CodeExecutionStatus.memoryExceeded.wire,
      ),
    );
    expect(recorded.state, ScriptRunState.memoryExceeded);
    expect(recorded.rest, 'partial');

    // Every status the server records maps to its state, text or not.
    for (final status in CodeExecutionStatus.values) {
      final state = readScriptStatus(
        _seg(
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
      expect(state.state.name, status.name, reason: status.wire);
      expect(state.rest, 'no status line', reason: status.wire);
    }
    expect(
      readScriptStatus(
        _seg(
          'r',
          name: 'repl',
          status: ToolSegmentStatus.error,
          outputs: 'Script refused: code mode is off',
          outcome: CodeExecutionStatus.refused.wire,
        ),
      ),
      (state: ScriptRunState.refused, detail: 'code mode is off', rest: ''),
    );

    // An external adapter's transcript has no outcome: the line decides.
    expect(
      readScriptStatus(
        _seg(
          'r',
          name: 'repl',
          status: ToolSegmentStatus.error,
          outputs: 'Script timed out after 30.0 s · 0 tool calls',
        ),
      ).state,
      ScriptRunState.timedOut,
    );
  });
}
