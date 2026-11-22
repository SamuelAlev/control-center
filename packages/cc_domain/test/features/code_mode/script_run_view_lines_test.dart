import 'package:cc_domain/features/code_mode/domain/services/script_outline_parser.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view_lines.dart';
import 'package:test/test.dart';

const _source = '''
const hits = await tools.search({ pattern: "TODO" });
for (const file of hits.files) {
  await tools.read({ path: file });
  await tools.grep({ pattern: "FIXME", path: file });
}
if (hits.files.length > 0) {
  await tools.edit({ path: "TODO.md" });
} else {
  await tools.write({ path: "TODO.md" });
}''';

/// A made call: `ok`, `failed` or `running`, tagged with its index.
typedef _Call = ({int index, String tool, String state});

ScriptRunCall<_Call> _at(String tool, int index, {String state = 'ok'}) {
  final lines = _source.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final at = lines[i].indexOf('tools.$tool(');
    if (at >= 0) {
      return ScriptRunCall(
        payload: (index: index, tool: tool, state: state),
        toolName: tool,
        line: i + 1,
        column: at + 7,
        running: state == 'running',
        failed: state == 'failed',
        startMs: null,
        endMs: null,
      );
    }
  }
  throw ArgumentError(tool);
}

/// The search, [iterations] loop iterations of two calls, then the edit.
List<ScriptRunCall<_Call>> _calls(int iterations, {int? failAt}) {
  var i = 0;
  return [
    _at('search', i++),
    for (var k = 0; k < iterations; k++) ...[
      _at('read', i++),
      _at('grep', i++, state: k == failAt ? 'failed' : 'ok'),
    ],
    _at('edit', i++),
  ];
}

List<ScriptTreeLine<_Call>> _lines(
  List<ScriptRunCall<_Call>> calls, {
  Map<String, int> revealed = const {},
  bool ended = true,
}) => scriptTreeLines(
  view: buildScriptRunView(
    outline: parseScriptOutline(_source),
    calls: calls,
    ended: ended,
  ),
  mustShow: (call) => call.state != 'ok',
  toolOf: (call) => call.tool,
  revealed: revealed,
);

String _describe(ScriptTreeLine<_Call> line) => switch (line) {
  ScriptTreeMadeLine(:final call) => '${line.depth} ${call.tool}#${call.index}',
  ScriptTreePendingLine(:final site, :final row) =>
    '${line.depth} ${site.toolName} ${row.state.name}',
  ScriptTreeHeaderLine(:final group) =>
    '${line.depth} [${group.node.runtimeType}]',
  ScriptTreeHiddenLine(:final count) => '${line.depth} +$count',
  ScriptTreeRuleLine() => '${line.depth} ---',
  ScriptTreeUnplacedLine() => '${line.depth} unplaced',
};

void main() {
  test('a short loop lists every call with a rule per iteration', () {
    expect(_lines(_calls(2)).map(_describe), [
      '0 search#0',
      '0 [ScriptLoopNode]',
      '1 read#1',
      '1 grep#2',
      '1 ---',
      '1 read#3',
      '1 grep#4',
      '0 [ScriptArmNode]',
      '1 edit#5',
      '0 [ScriptArmNode]',
      '1 write skipped',
    ]);
  });

  test('a long loop keeps the first two and the last three', () {
    final lines = _lines(_calls(12)).map(_describe).toList();
    expect(lines.sublist(1, 7), [
      '0 [ScriptLoopNode]',
      '1 read#1',
      '1 grep#2',
      '1 +19',
      '1 grep#22',
      '1 ---',
    ]);
  });

  test('a failure in the folded middle brings its iteration\'s first call', () {
    // Iteration 6 of 12: read#11 starts it, grep#12 fails.
    final lines = _lines(_calls(12, failAt: 5)).map(_describe).toList();
    expect(lines.sublist(1, 12), [
      '0 [ScriptLoopNode]',
      '1 read#1',
      '1 grep#2',
      '1 +8',
      '1 ---',
      '1 read#11',
      '1 grep#12',
      '1 +9',
      '1 grep#22',
      '1 ---',
      '1 read#23',
    ]);
    // Every made call is shown or counted once.
    final hidden = _lines(
      _calls(12, failAt: 5),
    ).whereType<ScriptTreeHiddenLine<_Call>>().fold(0, (n, l) => n + l.count);
    final shown = _lines(
      _calls(12, failAt: 5),
    ).whereType<ScriptTreeMadeLine<_Call>>().length;
    expect(hidden + shown, 26);
  });

  test('a failure that starts its iteration brings nothing else', () {
    final calls = _calls(12);
    calls[11] = _at('read', 11, state: 'failed');
    final lines = _lines(calls).map(_describe).toList();
    expect(lines.sublist(3, 8), [
      '1 grep#2',
      '1 +8',
      '1 ---',
      '1 read#11',
      '1 +10',
    ]);
  });

  test('an opened group does not fold', () {
    final first = _lines(_calls(12));
    final loop = first.whereType<ScriptTreeHeaderLine<_Call>>().first.group.key;
    final opened = _lines(_calls(12), revealed: {loop: scriptFoldStep});
    expect(opened.whereType<ScriptTreeHiddenLine<_Call>>(), isEmpty);
    expect(opened.whereType<ScriptTreeMadeLine<_Call>>(), hasLength(26));
  });

  test('a huge group opens a step at a time from the top', () {
    final calls = _calls(2500);
    final loop = _lines(
      calls,
    ).whereType<ScriptTreeHeaderLine<_Call>>().first.group.key;
    final once = _lines(calls, revealed: {loop: scriptFoldStep});
    expect(once.whereType<ScriptTreeMadeLine<_Call>>(), hasLength(107));
    final hidden = once.whereType<ScriptTreeHiddenLine<_Call>>().single;
    expect(hidden.count, 5000 - 5 - 100);
    final described = once.map(_describe).toList();
    // The revealed calls follow the first two; the control stays under them.
    expect(described.sublist(2, 5), ['1 read#1', '1 grep#2', '1 ---']);
    expect(described.indexOf('1 +4895'), described.indexOf('1 grep#102') + 1);
    final twice = _lines(calls, revealed: {loop: 2 * scriptFoldStep});
    expect(
      twice.whereType<ScriptTreeHiddenLine<_Call>>().single.count,
      5000 - 5 - 200,
    );
  });

  test('keys are stable while the script runs', () {
    final before = _lines([_at('search', 0)], ended: false);
    final after = _lines([_at('search', 0), _at('read', 1)], ended: false);
    final pendingRead = before
        .whereType<ScriptTreePendingLine<_Call>>()
        .firstWhere((l) => l.site.toolName == 'read');
    final madeRead = after.whereType<ScriptTreeMadeLine<_Call>>().firstWhere(
      (l) => l.call.tool == 'read',
    );
    expect(madeRead.key, pendingRead.key);
  });

  test('calls with no place come last, under a caption', () {
    final lines = _lines([
      _at('search', 0),
      const ScriptRunCall(
        payload: (index: 1, tool: 'bash', state: 'ok'),
        toolName: 'bash',
        line: null,
        column: null,
        running: false,
        failed: false,
        startMs: null,
        endMs: null,
      ),
    ]);
    expect(lines.map(_describe).skip(lines.length - 2), [
      '0 unplaced',
      '0 bash#1',
    ]);
  });

  test('a fold says what it hides, the rarest tool first', () {
    // The reviewer's case: a call of the same tool in another call's
    // arguments, among reads, folded in an arm. Both calls share a site.
    const source =
        'const x = 1;\n'
        'if (x) {\n'
        '  await tools.read({ path: "a" }); await tools.read({ path: "b" }); await tools.read({ path: "c" });\n'
        '  await tools.bash({ command: "rm -rf ./data", v: await tools.bash({ command: "echo hi", q: x }) });\n'
        '  await tools.read({ path: "d" }); await tools.read({ path: "e" }); await tools.read({ path: "f" });\n'
        '  await tools.read({ path: "g" }); await tools.read({ path: "h" }); await tools.read({ path: "i" });\n'
        '}';
    // Sites as the runner reported them.
    const sites = [
      ('read', 'a', 3, 15),
      ('read', 'b', 3, 48),
      ('read', 'c', 3, 81),
      ('bash', 'echo hi', 4, 93),
      ('bash', 'rm -rf ./data', 4, 93),
      ('read', 'd', 5, 15),
      ('read', 'e', 5, 48),
      ('read', 'f', 5, 81),
      ('read', 'g', 6, 15),
      ('read', 'h', 6, 48),
      ('read', 'i', 6, 81),
    ];
    final view = buildScriptRunView(
      outline: parseScriptOutline(source),
      calls: [
        for (final (i, (tool, what, line, column)) in sites.indexed)
          ScriptRunCall<_Call>(
            payload: (index: i, tool: '$tool $what', state: 'ok'),
            toolName: tool,
            line: line,
            column: column,
            running: false,
            failed: false,
            startMs: null,
            endMs: null,
          ),
      ],
      ended: true,
    );
    // Nothing reads as skipped: the call that ran has its own row.
    expect(view.counts.skipped, 0);
    expect(view.counts.done, 11);
    final lines = scriptTreeLines<_Call>(
      view: view,
      mustShow: (_) => false,
      toolOf: (call) => call.tool.split(' ').first,
      revealed: const {},
    );
    expect(lines.whereType<ScriptTreePendingLine<_Call>>(), isEmpty);
    final hidden = lines.whereType<ScriptTreeHiddenLine<_Call>>().single;
    expect(hidden.count, 6);
    expect(hidden.byTool, [(tool: 'bash', count: 2), (tool: 'read', count: 4)]);
  });
}
