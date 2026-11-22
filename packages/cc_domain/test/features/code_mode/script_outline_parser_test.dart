import 'dart:math';

import 'package:cc_domain/features/code_mode/domain/entities/script_outline.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_outline_parser.dart';
import 'package:test/test.dart';

/// One line per node, children indented by two spaces.
String render(ScriptOutline outline) {
  if (outline.failure case final failure?) {
    return 'unparsed: ${failure.name}';
  }
  final buffer = StringBuffer();
  void write(ScriptOutlineNode node, int depth) {
    buffer
      ..write('  ' * depth)
      ..write(switch (node) {
        ScriptCallNode() =>
          'call ${node.toolName ?? '?'}(${node.argumentText})',
        ScriptLoopNode() => 'loop ${node.kind.name} (${node.label})',
        ScriptEachNode() =>
          'each ${node.callee} (${node.parameters})'
              '${node.isAsync ? ' async' : ''}',
        ScriptParallelNode() => 'parallel ${node.kind.name}',
        ScriptBranchNode() => 'branch ${node.kind.name}',
        ScriptArmNode() =>
          'arm ${node.kind.name}'
              '${node.condition == null ? '' : ' (${node.condition})'}',
        ScriptFunctionNode() => 'function ${node.name} (${node.parameters})',
      })
      ..write('\n');
    for (final child in node.children) {
      write(child, depth + 1);
    }
  }

  for (final node in outline.nodes) {
    write(node, 0);
  }
  return buffer.toString().trimRight();
}

/// The shapes a model writes, each with the outline expected of it.
const Map<String, (String, String)> corpus = {
  'sequential calls': (
    '''
const a = await tools.read({ path: 'a.txt' });
const b = await tools.read({ path: 'b.txt' });
return a + b;
''',
    '''
call read({ path: 'a.txt' })
call read({ path: 'b.txt' })''',
  ),
  'Promise.all over a literal array': (
    '''
const [a, b] = await Promise.all([
  tools.read({ path: 'a' }),
  tools.read({ path: 'b' }),
]);
''',
    '''
parallel all
  call read({ path: 'a' })
  call read({ path: 'b' })''',
  ),
  'Promise.allSettled over files.map': (
    '''
const files = ['a', 'b'];
const results = await Promise.allSettled(files.map(async (f) => {
  const text = await tools.read({ path: f });
  return tools.write({ path: f + '.bak', content: text });
}));
''',
    '''
parallel allSettled
  each files.map (f) async
    call read({ path: f })
    call write({ path: f + '.bak', content: text })''',
  ),
  'for of with two calls': (
    '''
for (const f of files) {
  const t = await tools.read({ path: f });
  await tools.write({ path: f, content: t.toUpperCase() });
}
''',
    '''
loop forOf (const f of files)
  call read({ path: f })
  call write({ path: f, content: t.toUpperCase() })''',
  ),
  'if / else if / else on a result': (
    '''
const r = await tools.bash({ command: 'ls' });
if (r.exitCode === 0) {
  await tools.write({ path: 'ok', content: r.stdout });
} else if (r.exitCode === 2) {
  console.log('two');
} else {
  await tools.ask_user({ question: 'Retry?' });
}
''',
    '''
call bash({ command: 'ls' })
branch ifChain
  arm ifArm (r.exitCode === 0)
    call write({ path: 'ok', content: r.stdout })
  arm elseIfArm (r.exitCode === 2)
  arm elseArm
    call ask_user({ question: 'Retry?' })''',
  ),
  'try / catch / finally': (
    '''
try {
  await tools.read({ path: 'x' });
} catch (e) {
  await tools.write({ path: 'err', content: String(e) });
} finally {
  console.log('done');
}
''',
    '''
call read({ path: 'x' })
branch tryCatch
  arm catchArm (e)
    call write({ path: 'err', content: String(e) })
  arm finallyArm''',
  ),
  'a helper function called in a loop': (
    r'''
async function grab(path) {
  const r = await tools.read({ path });
  return r.length;
}
const fetchOne = async (id) => tools.get_issue({ id });
for (let i = 0; i < 3; i++) {
  await grab(`f${i}`);
  await fetchOne(i);
}
''',
    '''
function grab (path)
  call read({ path })
function fetchOne (id)
  call get_issue({ id })''',
  ),
  'nested loops': (
    r'''
for (const dir of dirs) {
  const list = await tools.ls({ path: dir });
  for (const name of list) {
    await tools.read({ path: `${dir}/${name}` });
  }
}
''',
    r'''
loop forOf (const dir of dirs)
  call ls({ path: dir })
  loop forOf (const name of list)
    call read({ path: `${dir}/${name}` })''',
  ),
  'a call in a template literal substitution': (
    r'''
return `found: ${(await tools.grep({ pattern: 'x' })).length} matches`;
''',
    '''
call grep({ pattern: 'x' })''',
  ),
  'calls after return in an arm': (
    '''
if (!ok) {
  return await tools.ask_user({ question: 'Stop?' });
}
await tools.write({ path: 'a', content: '' });
''',
    '''
branch ifChain
  arm ifArm (!ok)
    call ask_user({ question: 'Stop?' })
call write({ path: 'a', content: '' })''',
  ),
  'unbraced if / else bodies and ASI': (
    '''
if (x) await tools.a({})
else await tools.b({})
await tools.c({})
if (y) tools.d({}); tools.e({});
''',
    '''
branch ifChain
  arm ifArm (x)
    call a({})
  arm elseArm
    call b({})
call c({})
branch ifChain
  arm ifArm (y)
    call d({})
call e({})''',
  ),
  'while with a call in its test': (
    '''
let page = 1;
while ((await tools.list({ page })).more) {
  page++;
}
''',
    '''
loop whileLoop ((await tools.list({ page })).more)
  call list({ page })''',
  ),
  'do while': (
    '''
let r;
do {
  r = await tools.poll({});
} while (!r.done);
await tools.done({});
''',
    '''
loop doWhile (!r.done)
  call poll({})
call done({})''',
  ),
  'classic for: initialiser before, update in the loop': (
    '''
for (let c = await tools.first({}); c; c = await tools.next({ c })) {
  await tools.use({ c });
}
''',
    '''
call first({})
loop forClassic (let c = await tools.first({}); c; c = await tools.next({ c }))
  call next({ c })
  call use({ c })''',
  ),
  'for in, for await': (
    '''
for (const k in obj) await tools.set({ k });
for await (const x of stream) { await tools.put({ x }); }
''',
    '''
loop forIn (const k in obj)
  call set({ k })
loop forOf (const x of stream)
  call put({ x })''',
  ),
  'switch with fall through': (
    '''
switch (kind) {
  case 'a':
    await tools.a({});
    break;
  case 'b':
  default:
    await tools.b({});
}
''',
    '''
branch switchCases
  arm caseArm ('a')
    call a({})
  arm caseArm ('b')
  arm defaultArm
    call b({})''',
  ),
  'conditional expression': (
    '''
const r = ok ? await tools.a({}) : await tools.b({});
const s = cached ?? (fresh ? tools.c({}) : null);
''',
    '''
branch conditional
  arm conditionalThen (ok)
    call a({})
  arm conditionalElse
    call b({})
branch conditional
  arm conditionalThen (fresh)
    call c({})
  arm conditionalElse''',
  ),
  'computed, optional and parenthesised callees': (
    '''
await tools["read"]({ path: 'a' });
const name = 'write';
await tools[name]({ path: 'b' });
await tools?.read?.({ path: 'c' });
await (tools.read)({ path: 'd' });
await tools?.['grep']({ path: 'e' });
''',
    '''
call read({ path: 'a' })
call ?({ path: 'b' })
call read({ path: 'c' })
call read({ path: 'd' })
call grep({ path: 'e' })''',
  ),
  'a call in another call’s arguments comes first': (
    '''
await tools.write({ path: 'a', content: await tools.read({ path: 'b' }) });
''',
    '''
call read({ path: 'b' })
call write({ path: 'a', content: await tools.read({ path: 'b' }) })''',
  ),
  'then, forEach and a plain function argument': (
    '''
await tools.read({ path: 'a' }).then((r) => tools.write({ path: 'b', content: r }));
items.forEach((x) => tools.log({ x }));
retry(3, function () { return tools.flaky({}); });
''',
    '''
call read({ path: 'a' })
each tools.read({ path: 'a' }).then (r)
  call write({ path: 'b', content: r })
each items.forEach (x)
  call log({ x })
each retry ()
  call flaky({})''',
  ),
  'an IIFE and new Promise run inline': (
    '''
await (async () => {
  await tools.a({});
})();
await new Promise((resolve) => resolve(tools.b({})));
''',
    '''
call a({})
call b({})''',
  ),
  'statements without calls are left out': (
    '''
const x = 1;
for (const y of [1, 2]) { console.log(y); }
if (x) { x++; } else { x--; }
function helper() { return 2; }
await tools.only({});
''',
    '''
call only({})''',
  ),
  'object property functions and labels': (
    '''
const api = { load: async (p) => tools.read({ path: p }) };
outer: for (const a of as) {
  for (const b of bs) {
    if (b) continue outer;
    await tools.x({ a, b });
  }
}
''',
    '''
function load (p)
  call read({ path: p })
loop forOf (const a of as)
  loop forOf (const b of bs)
    call x({ a, b })''',
  ),
  // Token traps.
  'braces and calls inside strings': (
    '''
const s = "tools.read({ path: '}' })";
const t = 'if (x) { tools.write( }';
await tools.read({ path: '{' });
''',
    '''
call read({ path: '{' })''',
  ),
  'braces and calls inside templates': (
    r'''
const msg = `literal tools.fake() { ${ { a: 1 }.a } } and ${`inner ${tools.x({})}`}`;
''',
    r'''
call x({})''',
  ),
  'a regular expression with brackets': (
    r'''
const re = /tools\.read\(\{[}]/g;
if (re.test(s)) await tools.read({ path: 'r' });
''',
    '''
branch ifChain
  arm ifArm (re.test(s))
    call read({ path: 'r' })''',
  ),
  'calls and brackets in comments': (
    '''
// tools.read({ path: 'nope' }) {
/* tools.write( { */
await tools.read({ path: 'yes' }); // trailing }
''',
    '''
call read({ path: 'yes' })''',
  ),
  'division that looks like a regular expression': (
    '''
const half = total / 2; const r = (a + b) / 2 / c;
const z = arr[0] / 4 / (x);
await tools.read({ path: String(half / r) });
''',
    '''
call read({ path: String(half / r) })''',
  ),
  'regular expressions after return, ( and =>': (
    r'''
function check(s) { return /[}{)(]/.test(s); }
const ok = [1].some((x) => /\//.test(x)) && s.match(/\)/);
if (check('a')) { await tools.read({ path: 'z' }); }
''',
    '''
branch ifChain
  arm ifArm (check('a'))
    call read({ path: 'z' })''',
  ),
  'optional chaining, await and nullish': (
    '''
const r = (await tools?.read({ path: 'q' }))?.text;
const y = x ?? tools.y();
const z = a?.5:b;
''',
    '''
call read({ path: 'q' })
call y()''',
  ),
  'a property named tools is not the tools object': (
    '''
await this.tools.read({});
await tools.read;
await tools.real({});
''',
    '''
call real({})''',
  ),
};

/// Text that cannot be followed.
const Map<String, String> broken = {
  'unbalanced brackets': "await tools.read({ path: 'a' ",
  'a stray closing brace': 'await tools.a({}); }',
  'mismatched brackets': 'await tools.a({ ]);',
  'an unterminated string': "const s = 'abc\nawait tools.a({});",
  'an unterminated template': r'const s = `abc ${x',
  'an unterminated block comment': '/* await tools.a({});',
};

void main() {
  group('parseScriptOutline corpus', () {
    for (final MapEntry(key: name, value: (source, expected))
        in corpus.entries) {
      test(name, () {
        expect(render(parseScriptOutline(source)), expected);
      });
    }
  });

  group('spans and ids', () {
    test('ids are preorder indices', () {
      final outline = parseScriptOutline(corpus['nested loops']!.$1);
      expect([for (final n in outline.all) n.id], [0, 1, 2, 3]);
      expect(outline.nodeCount, 4);
      expect(outline.calls.map((c) => c.toolName), ['ls', 'read']);
    });

    test('a call spans from its callee to its closing parenthesis', () {
      final outline = parseScriptOutline(
        'const x = 1;\n  const r = await tools.read({ path: "é" });\n',
      );
      final call = outline.calls.single;
      expect(call.span.start.line, 2);
      expect(call.span.start.column, 19);
      expect(call.span.start.offset, 13 + 18);
      expect(call.span.end.line, 2);
      // `tools.read({ path: "é" })` is 25 UTF-16 units long.
      expect(call.span.end.column, 19 + 25);
      expect(call.span.contains(2, 19), isTrue);
      expect(call.span.contains(2, 43), isTrue);
      expect(call.span.contains(2, 44), isFalse);
      expect(call.span.contains(2, 18), isFalse);
    });

    test('columns count UTF-16 units and every line terminator', () {
      final outline = parseScriptOutline('a\r\nb\rc d "😀"; tools.x()');
      final call = outline.calls.single;
      expect(call.span.start.line, 5);
      // `"😀"; ` is 6 UTF-16 units: the emoji is two.
      expect(call.span.start.column, 7);
    });

    test('a parenthesised callee starts at its parenthesis', () {
      final call = parseScriptOutline('await (tools.read)({})').calls.single;
      expect(call.span.start.column, 7);
    });

    test('a loop records where its body is', () {
      final loop =
          parseScriptOutline(
                'while (await tools.more({})) {\n  await tools.a({});\n}',
              ).nodes.single
              as ScriptLoopNode;
      expect(loop.bodySpan.start.line, 1);
      expect(loop.bodySpan.start.column, 30);
      expect(loop.bodySpan.end.line, 3);
      final [more, a] = loop.children.cast<ScriptCallNode>();
      expect(loop.bodySpan.containsSpan(more.span), isFalse);
      expect(loop.bodySpan.containsSpan(a.span), isTrue);
    });

    test('long text is cut with an ellipsis', () {
      final long = 'x' * 500;
      final call = parseScriptOutline(
        "await tools.write({ content: '$long' })",
      ).calls.single;
      expect(call.argumentText.length, ScriptOutline.maxTextLength);
      expect(call.argumentText, endsWith('…'));
      expect(call.argumentText, startsWith("{ content: 'xxx"));
    });

    test('whitespace and comments collapse to one space', () {
      final call = parseScriptOutline(
        'await tools.write({\n  path: "a", // the path\n\n  content:   "b"\n})',
      ).calls.single;
      expect(call.argumentText, '{ path: "a", content: "b" }');
    });

    test('equal texts give equal outlines', () {
      final source = corpus['if / else if / else on a result']!.$1;
      expect(parseScriptOutline(source), parseScriptOutline(source));
      expect(
        parseScriptOutline(source).hashCode,
        parseScriptOutline(source).hashCode,
      );
      expect(
        parseScriptOutline(source),
        isNot(parseScriptOutline('$source\nawait tools.z({});')),
      );
    });

    test('a script with no calls has an empty, parsed outline', () {
      final outline = parseScriptOutline('return 1 + 2;');
      expect(outline.unparsed, isFalse);
      expect(outline.nodes, isEmpty);
    });
  });

  group('call properties', () {
    List<(String, String, Object?)> props(String source) => [
      for (final p in parseScriptOutline(source).calls.single.properties)
        (p.key, p.source, p.value),
    ];

    test('literals carry their value, expressions their source', () {
      expect(
        props(
          'await tools.grep({ pattern: "FIX\\"ME", path: file.path, '
          "n: 3, all: true, 'quoted key': `tpl`, x: a ? b : c });",
        ),
        [
          ('pattern', '"FIX\\"ME"', 'FIX"ME'),
          ('path', 'file.path', null),
          ('n', '3', 3),
          ('all', 'true', true),
          ('quoted key', '`tpl`', 'tpl'),
          ('x', 'a ? b : c', null),
        ],
      );
    });

    test('a shorthand reads as key: key', () {
      expect(props('await tools.read({ file, path: p });'), [
        ('file', 'file', null),
        ('path', 'p', null),
      ]);
    });

    test('spread, computed and method properties are skipped', () {
      expect(
        props('await tools.a({ ...base, [k]: 1, f() { return 1; }, ok: 1 });'),
        [('ok', '1', 1)],
      );
    });

    test('no object literal, or more than one argument, has none', () {
      expect(props('await tools.a(args);'), isEmpty);
      expect(props('await tools.a({ x: 1 }, 2);'), isEmpty);
      expect(props('await tools.a();'), isEmpty);
    });

    test('a template with a substitution is an expression', () {
      expect(props(r'await tools.read({ path: `${dir}/a` });'), [
        ('path', r'`${dir}/a`', null),
      ]);
    });

    test('long values are cut, and at most 16 properties are kept', () {
      final long = 'x' * 400;
      final call = parseScriptOutline(
        'await tools.write({ content: "$long", '
        '${[for (var i = 0; i < 20; i++) 'k$i: $i'].join(', ')} });',
      ).calls.single;
      expect(call.properties, hasLength(ScriptCallNode.maxProperties));
      final content = call.properties.first;
      expect(content.value, isA<String>());
      expect(
        (content.value! as String).length,
        lessThanOrEqualTo(ScriptOutline.maxTextLength),
      );
    });
  });

  group('broken input', () {
    for (final MapEntry(key: name, value: source) in broken.entries) {
      test(name, () {
        expect(parseScriptOutline(source).unparsed, isTrue);
      });
    }

    test('200 nested brackets', () {
      final source = '${'(' * 200}tools.x({})${')' * 200}';
      expect(parseScriptOutline(source).failure, ScriptOutlineFailure.tooDeep);
    });

    test('200 nested unbraced ifs', () {
      final source = '${'if (a) ' * 300}tools.x({});';
      expect(parseScriptOutline(source).failure, ScriptOutlineFailure.tooDeep);
    });

    test('1 MiB of text', () {
      final source = 'await tools.a({});\n' * 55189;
      final watch = Stopwatch()..start();
      final outline = parseScriptOutline(source);
      expect(outline.failure, ScriptOutlineFailure.tooLong);
      expect(watch.elapsedMilliseconds, lessThan(50));
    });

    test('a run of question marks stays fast', () {
      final watch = Stopwatch()..start();
      parseScriptOutline('a ${'? ' * 100000}');
      expect(watch.elapsedMilliseconds, lessThan(500));
    });

    test('too many call sites', () {
      expect(
        parseScriptOutline('tools.a();' * 5000).failure,
        ScriptOutlineFailure.tooManyNodes,
      );
    });
  });

  group('time', () {
    test('a 64 KiB script parses in well under 50 ms', () {
      final buffer = StringBuffer();
      var i = 0;
      final sources = [for (final (source, _) in corpus.values) source];
      while (buffer.length < 64 * 1024) {
        buffer
          ..write('{\n')
          ..write(sources[i++ % sources.length])
          ..write('\n}\n');
      }
      final script = buffer.toString();
      expect(parseScriptOutline(script).unparsed, isFalse);
      var best = 1 << 30;
      for (var run = 0; run < 5; run++) {
        final watch = Stopwatch()..start();
        parseScriptOutline(script);
        best = min(best, watch.elapsedMicroseconds);
      }
      expect(best, lessThan(50 * 1000));
    });

    test('random byte soup and truncations never throw', () {
      final random = Random(20261119);
      const alphabet =
          'tools.read({["\'`\${}]})/\\*?:;,=>!&|\n\r\t abcxyz019'
          'ifforwhiledoswitchtrycatchasyncfunctionPromise.all';
      final inputs = <String>[];
      for (var n = 0; n < 400; n++) {
        final length = random.nextInt(600);
        inputs.add(
          String.fromCharCodes([
            for (var c = 0; c < length; c++)
              random.nextInt(8) == 0
                  ? random.nextInt(0x10000)
                  : alphabet.codeUnitAt(random.nextInt(alphabet.length)),
          ]),
        );
      }
      for (final (source, _) in corpus.values) {
        for (var cut = 0; cut <= source.length; cut++) {
          inputs.add(source.substring(0, cut));
        }
        for (var n = 0; n < 20; n++) {
          final a = random.nextInt(source.length);
          final b = a + random.nextInt(source.length - a);
          inputs.add(source.substring(0, a) + source.substring(b));
        }
      }
      var slowest = 0;
      for (final input in inputs) {
        final watch = Stopwatch()..start();
        final outline = parseScriptOutline(input);
        slowest = max(slowest, watch.elapsedMicroseconds);
        expect(outline.nodeCount, greaterThanOrEqualTo(0));
      }
      expect(slowest, lessThan(200 * 1000));
    });
  });

  group('work budget', () {
    String repeat(String unit, int length) =>
        List.filled(length ~/ unit.length, unit).join();

    // The reviewer's three shapes that used to grow with the square of the
    // text, and three more the work counter found.
    final shapes = <String, String Function(int)>{
      'division after a brace': (n) =>
          "await tools.read({});\nx = 0${repeat("+{}/'['", n - 40)};\n",
      'do as a property name': (n) =>
          'await tools.read({});\nconst o = {${repeat('do:1,', n - 40)}};\n',
      'async arrows': (n) =>
          'await tools.read({});\nconst f = ${repeat('async x => ', n - 40)}0;\n',
      'bound arrows': (n) =>
          'await tools.read({});\n${repeat('a = x => ', n - 40)}0;\n',
      'conditional chain': (n) =>
          'await tools.read({});\n${repeat('a ? b : ', n - 40)}c;\n',
      'bare conditionals': (n) =>
          'await tools.read({});\n${repeat('? : ', n - 40)}\n',
      'nests of 250 ifs': (n) =>
          'await tools.read({});\n'
          '${repeat('${repeat('if (a) ', 7 * 250)}x;\n', n - 40)}',
    };

    double ratio(String source) {
      final measured = measureScriptOutline(source);
      expect(measured.outline.failure, isNot(ScriptOutlineFailure.tooComplex));
      return measured.work / source.length;
    }

    test('honest scripts spend a small part of it', () {
      for (final (source, _) in corpus.values) {
        expect(ratio(source), lessThan(4), reason: source);
      }
      final buffer = StringBuffer();
      final sources = [for (final (source, _) in corpus.values) source];
      for (var i = 0; buffer.length < 255 * 1024; i++) {
        buffer
          ..write('{\n')
          ..write(sources[i % sources.length])
          ..write('\n}\n');
      }
      expect(ratio(buffer.toString()), lessThan(4));
    });

    test('hostile shapes at 255 KiB parse or give up in under 50 ms', () {
      for (final MapEntry(key: name, value: make) in shapes.entries) {
        final source = make(255 * 1024);
        parseScriptOutline(source);
        var best = 1 << 30;
        for (var run = 0; run < 3; run++) {
          final watch = Stopwatch()..start();
          parseScriptOutline(source);
          best = min(best, watch.elapsedMicroseconds);
        }
        expect(best, lessThan(50 * 1000), reason: name);
      }
    });

    test('work grows linearly with the text', () {
      for (final MapEntry(key: name, value: make) in shapes.entries) {
        final small = measureScriptOutline(make(64 * 1024)).work;
        final large = measureScriptOutline(make(255 * 1024)).work;
        // Four times the text: about four times the work, not sixteen.
        expect(large / small, lessThan(4.5), reason: name);
        expect(ratio(make(255 * 1024)), lessThan(4), reason: name);
      }
    });

    test('a parse past its budget gives up whole', () {
      const source = '''
const hits = await tools.search({ pattern: "TODO" });
for (const file of hits.files) {
  await tools.read({ path: file });
}''';
      final full = measureScriptOutline(source);
      expect(full.outline.unparsed, isFalse);
      final short = measureScriptOutline(source, budget: full.work - 1);
      expect(short.outline.failure, ScriptOutlineFailure.tooComplex);
      expect(short.outline.nodes, isEmpty);
      expect(scriptOutlineWorkBudget(0), scriptOutlineWorkFloor);
      expect(
        scriptOutlineWorkBudget(1000),
        scriptOutlineWorkFactor * 1000 + scriptOutlineWorkFloor,
      );
    });

    test('random soup never spends more than four units a character', () {
      final random = Random(20261119);
      const atoms = [
        'tools.a(',
        ')',
        '{',
        '}',
        '[',
        ']',
        '(',
        'if',
        'else',
        'do',
        'while',
        'for',
        'async',
        'function',
        '=>',
        '?',
        ':',
        ',',
        ';',
        '\n',
        '/',
        '"x"',
        '`',
        r'${',
        'x',
        '=',
        'Promise.all',
        '.',
        'case',
        'switch',
        'try',
        'catch',
        ' ',
        'a = x =>',
        'a ? b :',
        '/[',
        "'['",
      ];
      for (var n = 0; n < 2000; n++) {
        final buffer = StringBuffer();
        final length = random.nextInt(4000);
        while (buffer.length < length) {
          buffer
            ..write(atoms[random.nextInt(atoms.length)])
            ..write(' ');
        }
        final source = buffer.toString();
        final measured = measureScriptOutline(source);
        expect(measured.work, lessThanOrEqualTo(measured.budget));
        expect(
          measured.work,
          lessThanOrEqualTo(4 * source.length + 64),
          reason: source,
        );
      }
    });
  });
}
