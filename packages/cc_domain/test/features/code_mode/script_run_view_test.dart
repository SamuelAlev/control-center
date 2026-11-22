import 'dart:math';

import 'package:cc_domain/features/code_mode/domain/entities/script_outline.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_outline_parser.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view.dart';
import 'package:test/test.dart';

import 'script_outline_parser_test.dart' show corpus;

/// A call made from the [nth] call node named [tool], at its start.
ScriptRunCall<String> at(
  ScriptOutline outline,
  String tool,
  String payload, {
  int nth = 0,
  bool running = false,
  bool failed = false,
  int shift = 0,
}) {
  final node = outline.calls.where((c) => c.toolName == tool).elementAt(nth);
  return ScriptRunCall(
    payload: payload,
    toolName: tool,
    line: node.span.start.line,
    column: node.span.start.column + shift,
    running: running,
    failed: failed,
    startMs: null,
    endMs: null,
  );
}

String _counts(ScriptRunCounts c) =>
    '[${c.queued}/${c.running}/${c.done}/${c.skipped}]';

/// One line per row or group: `state payload-or-tool @arm *` for a row
/// (`*` starts an iteration), `kind state [queued/running/done/skipped]`
/// for a group.
String renderView(ScriptRunView<String> view) {
  final buffer = StringBuffer();
  void write(ScriptRunNode<String> node, int depth) {
    buffer.write('  ' * depth);
    switch (node) {
      case ScriptRunRow<String>():
        buffer
          ..write(node.state.name)
          ..write(' ')
          ..write(node.made ? node.payload : node.site?.toolName ?? '?');
        if (node.arm case final arm?) {
          buffer.write(' @${arm.kind.name}');
        }
        if (node.startsIteration) {
          buffer.write(' *');
        }
      case ScriptRunGroup<String>():
        buffer
          ..write(switch (node.node) {
            ScriptLoopNode() => 'loop',
            ScriptEachNode() => 'each',
            ScriptParallelNode() => 'parallel',
            ScriptFunctionNode() => 'function',
            ScriptBranchNode() => 'branch',
            final ScriptArmNode arm => arm.kind.name,
            ScriptCallNode() => 'call',
          })
          ..write(' ${node.state.name} ${_counts(node.counts)}');
        if (node.marksIterations) {
          buffer.write(' iterations=${node.iterations}');
        }
    }
    buffer.write('\n');
    if (node is ScriptRunGroup<String>) {
      for (final child in node.children) {
        write(child, depth + 1);
      }
    }
  }

  for (final node in view.nodes) {
    write(node, 0);
  }
  if (view.unattached.isNotEmpty) {
    buffer.write('unattached:\n');
    for (final row in view.unattached) {
      write(row, 1);
    }
  }
  return buffer.toString().trimRight();
}

String viewOf(
  ScriptOutline outline,
  List<ScriptRunCall<String>> calls, {
  bool ended = false,
}) => renderView(
  buildScriptRunView(outline: outline, calls: calls, ended: ended),
);

void main() {
  group('call nodes outside repeating nodes', () {
    final outline = parseScriptOutline(
      'await tools.a({});\nawait tools.b({});\nawait tools.c({});',
    );

    test('nothing made yet: every row is queued', () {
      expect(viewOf(outline, []), 'queued a\nqueued b\nqueued c');
    });

    test('rows in the order made, the rest queued', () {
      final calls = [
        at(outline, 'a', 'a1'),
        at(outline, 'b', 'b1', running: true),
      ];
      expect(viewOf(outline, calls), 'done a1\nrunning b1\nqueued c');
      final view = buildScriptRunView(
        outline: outline,
        calls: calls,
        ended: false,
      );
      expect(
        view.counts,
        const ScriptRunCounts(queued: 1, running: 1, done: 1),
      );
    });

    test('a script that ended early: nothing is queued', () {
      final calls = [at(outline, 'a', 'a1')];
      expect(
        viewOf(outline, calls, ended: true),
        'done a1\nskipped b\nskipped c',
      );
    });

    test('a call passed over is skipped once code after it ran', () {
      final outline = parseScriptOutline(
        'const v = x && await tools.a({});\nawait tools.b({});',
      );
      expect(viewOf(outline, [at(outline, 'b', 'b1')]), 'skipped a\ndone b1');
    });

    test('a call in another call’s arguments does not skip it', () {
      final outline = parseScriptOutline(
        'await tools.write({ content: await tools.read({}) });',
      );
      expect(
        viewOf(outline, [at(outline, 'read', 'r1')]),
        'done r1\nqueued write',
      );
    });
  });

  group('branches', () {
    const script = '''
const r = await tools.check({});
if (r.ok) {
  await tools.write({});
} else if (r.retry) {
  console.log('x');
} else {
  await tools.ask({});
}
await tools.end({});
''';
    final outline = parseScriptOutline(script);

    test('before any arm ran, every arm is queued', () {
      expect(viewOf(outline, [at(outline, 'check', 'c1')]), '''
done c1
branch queued [2/0/0/0]
  ifArm queued [1/0/0/0]
    queued write
  elseIfArm queued [0/0/0/0]
  elseArm queued [1/0/0/0]
    queued ask
queued end''');
    });

    test('one arm ran: the others are skipped', () {
      expect(
        viewOf(outline, [
          at(outline, 'check', 'c1'),
          at(outline, 'write', 'w1', running: true),
        ]),
        '''
done c1
branch running [0/1/0/1]
  ifArm running [0/1/0/0]
    running w1
  elseIfArm skipped [0/0/0/0]
  elseArm skipped [0/0/0/1]
    skipped ask
queued end''',
      );
    });

    test('code after the branch ran: arms not reached are skipped', () {
      expect(
        viewOf(outline, [at(outline, 'check', 'c1'), at(outline, 'end', 'e1')]),
        '''
done c1
branch skipped [0/0/0/2]
  ifArm skipped [0/0/0/1]
    skipped write
  elseIfArm skipped [0/0/0/0]
  elseArm skipped [0/0/0/1]
    skipped ask
done e1''',
      );
    });

    test('an arm with no call stays queued until code after it ran', () {
      final outline = parseScriptOutline('''
if (a) {
  log();
} else {
  await tools.b({});
}
await tools.c({});
''');
      expect(viewOf(outline, []), '''
branch queued [1/0/0/0]
  ifArm queued [0/0/0/0]
  elseArm queued [1/0/0/0]
    queued b
queued c''');
      expect(viewOf(outline, [at(outline, 'c', 'c1')]), '''
branch skipped [0/0/0/1]
  ifArm skipped [0/0/0/0]
  elseArm skipped [0/0/0/1]
    skipped b
done c1''');
    });

    test('catch and finally are not exclusive', () {
      final outline = parseScriptOutline('''
try {
  await tools.a({});
} catch (e) {
  await tools.b({});
} finally {
  await tools.c({});
}
''');
      expect(
        viewOf(outline, [at(outline, 'a', 'a1'), at(outline, 'c', 'c1')]),
        '''
done a1
branch done [0/0/1/1]
  catchArm skipped [0/0/0/1]
    skipped b
  finallyArm done [0/0/1/0]
    done c1''',
      );
    });
  });

  group('loops', () {
    const script = '''
for (const f of files) {
  const t = await tools.read({ path: f });
  await tools.write({ path: f, content: t });
}
await tools.done({});
''';
    final outline = parseScriptOutline(script);

    test('before its first call, a loop shows its static contents', () {
      expect(viewOf(outline, []), '''
loop queued [2/0/0/0]
  queued read
  queued write
queued done''');
    });

    test('from its first call on, its calls with iteration marks', () {
      expect(
        viewOf(outline, [
          at(outline, 'read', 'r1'),
          at(outline, 'write', 'w1'),
          at(outline, 'read', 'r2', running: true),
        ]),
        '''
loop running [0/1/2/0] iterations=2
  done r1 *
  done w1
  running r2 *
queued done''',
      );
    });

    test('a loop that never ran is skipped once the script ended', () {
      expect(viewOf(outline, [], ended: true), '''
loop skipped [0/0/0/2]
  skipped read
  skipped write
skipped done''');
    });

    test('a loop with no iteration is skipped once code after it ran', () {
      expect(viewOf(outline, [at(outline, 'done', 'd1')]), '''
loop skipped [0/0/0/2]
  skipped read
  skipped write
done d1''');
    });

    test('calls in an arm carry the arm; uncertain starts get no mark', () {
      final outline = parseScriptOutline('''
for (const f of files) {
  if (f.big) await tools.big({ f }); else await tools.small({ f });
}
''');
      expect(
        viewOf(outline, [
          at(outline, 'small', 's1'),
          at(outline, 'big', 'b1'),
          at(outline, 'small', 's2'),
        ]),
        '''
loop done [0/0/3/0] iterations=2
  done s1 @elseArm *
  done b1 @ifArm *
  done s2 @elseArm''',
      );
    });

    test('a body that is only a nested loop gets no marks', () {
      final outline = parseScriptOutline('''
for (const d of dirs) {
  for (const f of d.files) {
    await tools.read({ f });
  }
}
''');
      expect(
        viewOf(outline, [at(outline, 'read', 'r1'), at(outline, 'read', 'r2')]),
        '''
loop done [0/0/2/0]
  done r1
  done r2''',
      );
    });

    test('a loop inside a Promise combinator gets no marks', () {
      final outline = parseScriptOutline('''
await Promise.all([
  (async () => { for (const x of xs) await tools.a({ x }); })(),
  tools.b({}),
]);
''');
      expect(
        viewOf(outline, [
          at(outline, 'a', 'a1'),
          at(outline, 'b', 'b1'),
          at(outline, 'a', 'a2'),
        ]),
        '''
parallel done [0/0/3/0]
  loop done [0/0/2/0]
    done a1
    done a2
  done b1''',
      );
    });

    test('calls in the header are listed but not marked', () {
      final outline = parseScriptOutline('''
while (await tools.more({})) {
  await tools.a({});
}
''');
      expect(
        viewOf(outline, [
          at(outline, 'more', 'm1'),
          at(outline, 'a', 'a1'),
          at(outline, 'more', 'm2'),
          at(outline, 'a', 'a2'),
          at(outline, 'more', 'm3'),
        ]),
        '''
loop done [0/0/5/0] iterations=2
  done m1
  done a1 *
  done m2
  done a2 *
  done m3''',
      );
    });

    test('a call in another call’s arguments does not start an iteration', () {
      final outline = parseScriptOutline('''
for (const f of fs) {
  await tools.write({ content: await tools.read({ f }) });
}
''');
      expect(
        viewOf(outline, [
          at(outline, 'read', 'r1'),
          at(outline, 'write', 'w1'),
          at(outline, 'read', 'r2'),
          at(outline, 'write', 'w2'),
        ]),
        '''
loop done [0/0/4/0] iterations=2
  done r1 *
  done w1
  done r2 *
  done w2''',
      );
    });
  });

  group('eaches, parallels and functions', () {
    test('an interleaved parallel each with two calls in its body', () {
      final outline = parseScriptOutline('''
await Promise.allSettled(files.map(async (f) => {
  const t = await tools.read({ f });
  await tools.write({ f, t });
}));
''');
      final calls = [
        at(outline, 'read', 'r1'),
        at(outline, 'read', 'r2'),
        at(outline, 'write', 'w1', running: true),
        at(outline, 'write', 'w2'),
      ];
      expect(viewOf(outline, calls), '''
parallel running [0/1/3/0]
  each running [0/1/3/0]
    done r1
    done r2
    running w1
    done w2''');
      final view = buildScriptRunView(
        outline: outline,
        calls: calls,
        ended: false,
      );
      final parallel = view.nodes.single as ScriptRunGroup<String>;
      final each = parallel.children.single as ScriptRunGroup<String>;
      final readId = outline.calls.first.id;
      final writeId = outline.calls.last.id;
      expect(
        [for (final row in each.children) row.key],
        ['n$readId', 'c1', 'n$writeId', 'c3'],
      );
      expect(each.payloads, ['r1', 'r2', 'w1', 'w2']);
    });

    test('a parallel over a literal array', () {
      final outline = parseScriptOutline(
        'await Promise.all([tools.a({}), tools.b({})]);',
      );
      expect(viewOf(outline, [at(outline, 'a', 'a1', running: true)]), '''
parallel running [1/1/0/0]
  running a1
  queued b''');
    });

    test('a sync each outside a combinator is marked', () {
      final outline = parseScriptOutline(
        'items.forEach((x) => { tools.a({ x }); tools.b({ x }); });',
      );
      expect(
        viewOf(outline, [
          at(outline, 'a', 'a1'),
          at(outline, 'b', 'b1'),
          at(outline, 'a', 'a2'),
          at(outline, 'b', 'b2'),
        ]),
        '''
each done [0/0/4/0] iterations=2
  done a1 *
  done b1
  done a2 *
  done b2''',
      );
    });

    test('an async each is never marked', () {
      final outline = parseScriptOutline(
        'items.forEach(async (x) => { await tools.a({ x }); });',
      );
      expect(
        viewOf(outline, [at(outline, 'a', 'a1'), at(outline, 'a', 'a2')]),
        '''
each done [0/0/2/0]
  done a1
  done a2''',
      );
    });

    test('a function stays queued until the script ends', () {
      final outline = parseScriptOutline('''
async function grab(p) { return tools.read({ p }); }
await tools.first({});
await grab(1);
''');
      expect(viewOf(outline, [at(outline, 'first', 'f1')]), '''
function queued [1/0/0/0]
  queued read
done f1''');
      expect(
        viewOf(outline, [
          at(outline, 'first', 'f1'),
          at(outline, 'read', 'r1'),
          at(outline, 'read', 'r2'),
        ]),
        '''
function done [0/0/2/0]
  done r1
  done r2
done f1''',
      );
      expect(viewOf(outline, [at(outline, 'first', 'f1')], ended: true), '''
function skipped [0/0/0/1]
  skipped read
done f1''');
    });
  });

  group('placing calls', () {
    final outline = parseScriptOutline('''
await tools.a({}); await tools.b({});
await tools.write({ content: await tools.read({}) });
await tools.solo({});
''');

    test('a call with no site is unattached', () {
      const call = ScriptRunCall(
        payload: 'x',
        toolName: null,
        line: null,
        column: null,
        running: false,
        failed: false,
        startMs: null,
        endMs: null,
      );
      expect(viewOf(outline, [call]), contains('unattached:\n  done x'));
    });

    test('a site on a line with no call node is unattached', () {
      const call = ScriptRunCall(
        payload: 'x',
        toolName: null,
        line: 99,
        column: 1,
        running: true,
        failed: false,
        startMs: null,
        endMs: null,
      );
      expect(viewOf(outline, [call]), endsWith('unattached:\n  running x'));
    });

    test(
      'two call nodes on one line: the containing one, else the nearest',
      () {
        final b = outline.calls.firstWhere((c) => c.toolName == 'b');
        expect(
          viewOf(outline, [at(outline, 'b', 'inside', shift: 3)]),
          startsWith('skipped a\ndone inside'),
        );
        expect(
          viewOf(outline, [
            ScriptRunCall(
              payload: 'past',
              toolName: 'b',
              line: b.span.start.line,
              column: b.span.end.column + 20,
              running: false,
              failed: false,
              startMs: null,
              endMs: null,
            ),
          ]),
          startsWith('skipped a\ndone past'),
        );
        expect(
          viewOf(outline, [
            const ScriptRunCall(
              payload: 'before',
              toolName: null,
              line: 1,
              column: 1,
              running: false,
              failed: false,
              startMs: null,
              endMs: null,
            ),
          ]),
          startsWith('done before\nqueued b'),
        );
      },
    );

    test('the innermost call node containing the site wins', () {
      expect(
        viewOf(outline, [at(outline, 'read', 'r1')]),
        contains('done r1\nqueued write'),
      );
    });

    test('a site inside a nested call goes to the call of that name', () {
      final outline = parseScriptOutline(
        'await tools.a({ v: await tools.b({ q: x }) });\n'
        'await tools.c({ v: await tools.d({ q: x }) });',
      );
      final b = outline.calls.firstWhere((c) => c.toolName == 'b');
      final d = outline.calls.firstWhere((c) => c.toolName == 'd');
      ScriptRunCall<String> inside(ScriptCallNode node, String tool) =>
          ScriptRunCall(
            payload: '$tool@${node.toolName}',
            toolName: tool,
            line: node.span.start.line,
            column: node.span.start.column + 9,
            running: false,
            failed: false,
            startMs: null,
            endMs: null,
          );
      // b made first, then a reporting a point inside b; and the other order.
      expect(
        viewOf(outline, [inside(b, 'b'), inside(b, 'a')]),
        startsWith('done b@b\ndone a@b'),
      );
      expect(
        viewOf(outline, [inside(d, 'c'), inside(d, 'd')]),
        endsWith('done d@d\ndone c@d'),
      );
      // Alone, a is still placed at a.
      expect(
        viewOf(outline, [inside(b, 'a')]),
        startsWith('queued b\ndone a@b'),
      );
    });

    test('a same-name nesting stays ambiguous: the innermost wins', () {
      final outline = parseScriptOutline(
        'await tools.a({ v: await tools.a({ q: x }) });',
      );
      final inner = outline.calls.first;
      final view = buildScriptRunView(
        outline: outline,
        calls: [
          ScriptRunCall(
            payload: 'x',
            toolName: 'a',
            line: 1,
            column: inner.span.start.column + 9,
            running: false,
            failed: false,
            startMs: null,
            endMs: null,
          ),
        ],
        ended: false,
      );
      expect((view.nodes.first as ScriptRunRow<String>).site, inner);
    });

    test('a raw tool name matches its identifier form', () {
      final outline = parseScriptOutline(
        'await tools.list_prs({ v: await tools.b({ q: x }) });',
      );
      final b = outline.calls.first;
      expect(
        viewOf(outline, [
          ScriptRunCall(
            payload: 'p1',
            toolName: 'list-prs',
            line: 1,
            column: b.span.start.column + 9,
            running: false,
            failed: false,
            startMs: null,
            endMs: null,
          ),
        ]),
        'queued b\ndone p1',
      );
    });

    test('the only call node on a line takes a site with any column', () {
      expect(
        viewOf(outline, [at(outline, 'solo', 's1', shift: 400)]),
        endsWith('done s1'),
      );
    });

    test('an unparsed outline lists every call flat', () {
      final view = buildScriptRunView(
        outline: parseScriptOutline('await tools.a({'),
        calls: [at(outline, 'a', 'a1'), at(outline, 'b', 'b1', running: true)],
        ended: false,
      );
      expect(view.parsed, isFalse);
      expect(view.nodes, isEmpty);
      expect(renderView(view), 'unattached:\n  done a1\n  running b1');
      expect([for (final row in view.unattached) row.key], ['c0', 'c1']);
    });
  });

  test('random calls over the corpus: each call listed once, keys unique', () {
    final random = Random(20261119);
    for (final (source, _) in corpus.values) {
      final outline = parseScriptOutline(source);
      final lines = source.split('\n').length;
      for (var round = 0; round < 50; round++) {
        final calls = [
          for (var i = random.nextInt(12); i > 0; i--)
            ScriptRunCall(
              payload: 'p$i',
              toolName: null,
              line: random.nextInt(10) == 0 ? null : 1 + random.nextInt(lines),
              column: 1 + random.nextInt(60),
              running: random.nextBool(),
              failed: false,
              startMs: null,
              endMs: null,
            ),
        ];
        final ended = random.nextBool();
        final view = buildScriptRunView(
          outline: outline,
          calls: calls,
          ended: ended,
        );
        final rows = <ScriptRunRow<String>>[...view.unattached];
        final keys = <String>[];
        void collect(List<ScriptRunNode<String>> nodes) {
          for (final node in nodes) {
            keys.add(node.key);
            switch (node) {
              case ScriptRunRow<String>():
                rows.add(node);
              case ScriptRunGroup<String>():
                expect(node.counts.total, greaterThanOrEqualTo(0));
                collect(node.children);
            }
          }
        }

        collect(view.nodes);
        keys.addAll(view.unattached.map((row) => row.key));
        expect(keys.toSet().length, keys.length, reason: source);
        final made = [
          for (final row in rows)
            if (row.made) row.callIndex,
        ]..sort();
        expect(made, [for (var i = 0; i < calls.length; i++) i]);
        expect(view.counts.made, calls.length);
        if (ended) {
          expect(view.counts.queued, 0);
        }
      }
    }
  });

  group('keys', () {
    test('a queued row keeps its key once its call is made', () {
      final outline = parseScriptOutline('await tools.a({});');
      final before = buildScriptRunView<String>(
        outline: outline,
        calls: [],
        ended: false,
      );
      final after = buildScriptRunView(
        outline: outline,
        calls: [at(outline, 'a', 'a1')],
        ended: false,
      );
      expect(before.nodes.single.key, after.nodes.single.key);
      expect(before, isNot(after));
      expect(
        after,
        buildScriptRunView(
          outline: outline,
          calls: [at(outline, 'a', 'a1')],
          ended: false,
        ),
      );
    });
  });

  group('calls of one tool nested in each other\'s arguments', () {
    // The runner reports one site for both calls: the last token evaluated
    // before each, which is `x` inside the inner call.
    const source =
        'const x = 1;\n'
        'await tools.bash({ command: "rm", v: await tools.bash({ q: x }) });\n'
        'await tools.read({});';
    final outline = parseScriptOutline(source);
    final column = source.split('\n')[1].indexOf('q: x') + 4;

    ScriptRunCall<String> bash(String payload, {bool failed = false}) =>
        ScriptRunCall(
          payload: payload,
          toolName: 'bash',
          line: 2,
          column: column,
          running: false,
          failed: failed,
          startMs: null,
          endMs: null,
        );

    test('the inner call goes to the inner node, the outer to the outer', () {
      expect(
        viewOf(outline, [
          bash('echo'),
          bash('rm'),
          at(outline, 'read', 'read'),
        ], ended: true),
        // Outline order: the inner call first, then the call around it.
        'done echo\ndone rm\ndone read',
      );
    });

    test('in the other order they still fill both nodes', () {
      final view = buildScriptRunView(
        outline: outline,
        calls: [bash('rm'), bash('echo')],
        ended: true,
      );
      expect(view.counts, const ScriptRunCounts(done: 2, skipped: 1));
      expect(renderView(view), 'done rm\ndone echo\nskipped read');
    });

    test('after a failed inner call the outer one cannot be told', () {
      final view = buildScriptRunView(
        outline: outline,
        calls: [bash('echo', failed: true)],
        ended: true,
      );
      expect(renderView(view), 'done echo\nunknown bash\nskipped read');
      expect(
        view.counts,
        const ScriptRunCounts(done: 1, skipped: 1, unknown: 1),
      );
      // While the script runs it cannot be told either; the read is queued.
      expect(
        viewOf(outline, [bash('echo', failed: true)]),
        'done echo\nunknown bash\nqueued read',
      );
    });

    test('in a loop, a failed inner call starts the next pass inside', () {
      const loop =
          'for (const f of fs) {\n'
          '  await tools.bash({ c: f, v: await tools.bash({ q: f }) });\n'
          '}';
      final loopOutline = parseScriptOutline(loop);
      final col = loop.split('\n')[1].indexOf('q: f') + 4;
      ScriptRunCall<String> call(String payload, {bool failed = false}) =>
          ScriptRunCall(
            payload: payload,
            toolName: 'bash',
            line: 2,
            column: col,
            running: false,
            failed: failed,
            startMs: null,
            endMs: null,
          );
      final view = buildScriptRunView(
        outline: loopOutline,
        calls: [
          call('in1'),
          call('out1'),
          call('in2', failed: true),
          call('in3'),
          call('out3'),
        ],
        ended: true,
      );
      final inner = loopOutline.calls.firstWhere(
        (c) => c.argumentText.startsWith('{ q'),
      );
      final rows = (view.nodes.single as ScriptRunGroup<String>).children
          .cast<ScriptRunRow<String>>();
      expect(
        [for (final r in rows) r.payload],
        ['in1', 'out1', 'in2', 'in3', 'out3'],
      );
      expect(
        [for (final r in rows) r.site == inner],
        [true, false, true, true, false],
      );
    });

    test('three levels fill from the inside out', () {
      const three =
          'await tools.a({ v: await tools.a({ v: await tools.a({ q: x }) }) });';
      final threeOutline = parseScriptOutline(three);
      final col = three.indexOf('q: x') + 4;
      ScriptRunCall<String> call(String payload) => ScriptRunCall(
        payload: payload,
        toolName: 'a',
        line: 1,
        column: col,
        running: false,
        failed: false,
        startMs: null,
        endMs: null,
      );
      final view = buildScriptRunView(
        outline: threeOutline,
        calls: [call('inner'), call('middle'), call('outer')],
        ended: true,
      );
      expect(view.counts, const ScriptRunCounts(done: 3));
      final sites = [
        for (final row in view.nodes.cast<ScriptRunRow<String>>())
          (row.payload, row.site!.span.start.column),
      ];
      expect(sites, [
        ('inner', three.lastIndexOf('tools.a') + 1),
        ('middle', three.indexOf('tools.a', 10) + 1),
        ('outer', 7),
      ]);
    });
  });

  group('calls nested in each other at one site, with real sites', () {
    // Sites as the runner reports them (the closure review's cases).
    ScriptRunCall<String> call(
      String payload,
      String tool,
      int line,
      int column, {
      bool running = false,
      bool failed = false,
      int? startMs,
      int? endMs,
    }) => ScriptRunCall(
      payload: payload,
      toolName: tool,
      line: line,
      column: column,
      running: running,
      failed: failed,
      startMs: startMs,
      endMs: endMs,
    );

    String rows(String source, List<ScriptRunCall<String>> calls, bool ended) {
      final view = buildScriptRunView(
        outline: parseScriptOutline(source),
        calls: calls,
        ended: ended,
      );
      String row(ScriptRunNode<String> node) => switch (node) {
        ScriptRunRow<String>(made: true) =>
          '${node.state.name} ${node.payload} at '
              '${node.site?.toolName ?? '[computed]'}'
              '(${node.site?.argumentText})',
        ScriptRunRow<String>() =>
          '${node.state.name} ${node.site?.toolName ?? '[computed]'}'
              '(${node.site?.argumentText})',
        ScriptRunGroup<String>() => [
          '${node.state.name} group',
          for (final child in node.children) '  ${row(child)}',
        ].join('\n'),
      };
      return [for (final node in view.nodes) row(node)].join('\n');
    }

    test('s11: a computed inner call of the same tool gets its own row', () {
      const source =
          'const tool = "read";\n'
          'const notes = await tools.read({ path: "NOTES.md", context: '
          'await tools[tool]({ path: "CONTEXT.md" }) });\n';
      expect(
        rows(source, [
          call('inner', 'read', 2, 73),
          call('outer', 'read', 2, 73),
        ], true),
        'done inner at [computed]({ path: "CONTEXT.md" })\n'
        'done outer at read({ path: "NOTES.md", context: await '
        'tools[tool]({ path: "CONTEXT.md" }) })',
      );
    });

    test('s10: an outer call never made shows no state, not a done row', () {
      const source =
          'const n = "a";\n'
          'try { await tools.a({ v: await tools[n]({ q: 1 }), w: nope() }); '
          '} catch (e) {}\n'
          'await tools.b({});\n';
      final out = rows(source, [
        call('inner', 'a', 2, 38),
        call('b', 'b', 3, 13),
      ], true);
      // The try block's calls are the script's own; the empty catch arm
      // leaves no branch.
      expect(
        out,
        'done inner at [computed]({ q: 1 })\n'
        'unknown a({ v: await tools[n]({ q: 1 }), w: nope() })\n'
        'done b at b({})',
      );
      expect(out, isNot(contains('skipped [computed]')));
    });

    test('s7: an outer call made while its argument runs has its own row', () {
      const source = 'await tools.a({ v: tools.a({ q: 1 }) });\n';
      const live =
          'running inner at a({ q: 1 })\n'
          'running outer at a({ v: tools.a({ q: 1 }) })';
      expect(
        rows(source, [
          call('inner', 'a', 1, 26, running: true, startMs: 0),
          call('outer', 'a', 1, 26, running: true, startMs: 1),
        ], false),
        live,
      );
      // The same attribution once both ended: rows do not move.
      expect(
        rows(source, [
          call('inner', 'a', 1, 26, startMs: 0, endMs: 5),
          call('outer', 'a', 1, 26, startMs: 1, endMs: 6),
        ], true),
        live.replaceAll('running', 'done'),
      );
      // A failure of the inner call that came after the outer started does
      // not move the outer call's row either.
      expect(
        rows(source, [
          call('inner', 'a', 1, 26, failed: true, startMs: 0, endMs: 5),
          call('outer', 'a', 1, 26, startMs: 1, endMs: 6),
        ], true),
        live.replaceAll('running', 'done'),
      );
    });

    test('s3: in a loop, a pass whose outer call was never made', () {
      const source =
          'for (let i = 0; i < 3; i++) {\n'
          '  try { await tools.a({ v: await tools.a({ q: i }), '
          'w: i === 1 ? nope() : 0 }); } catch (e) {}\n'
          '}\n';
      const outer =
          'a({ v: await tools.a({ q: i }), w: i === 1 ? nope() : 0 })';
      // Accepted: the second pass's inner call sits on the outer node of
      // the same line, the one place the records cannot tell apart.
      expect(
        rows(source, [
          call('in0', 'a', 2, 47),
          call('out0', 'a', 2, 66),
          call('in1', 'a', 2, 47),
          call('in2', 'a', 2, 47),
          call('out2', 'a', 2, 66),
        ], true),
        'done group\n'
        '  done in0 at a({ q: i })\n'
        '  done out0 at $outer\n'
        '  done in1 at $outer\n'
        '  done in2 at a({ q: i })\n'
        '  done out2 at $outer',
      );
    });

    test('calls of different static names keep matching by name', () {
      const source = 'await tools.a({ v: await tools.b({ q: 1 }) });\n';
      final column = source.indexOf('q: 1') + 4;
      // Only the inner call made: the outer one is skipped, as before.
      expect(
        rows(source, [call('b', 'b', 1, column)], true),
        'done b at b({ q: 1 })\nskipped a({ v: await tools.b({ q: 1 }) })',
      );
    });
  });
}
