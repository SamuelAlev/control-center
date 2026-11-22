import 'package:cc_domain/features/code_mode/domain/entities/script_outline.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_outline_parser.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view_text.dart';
import 'package:test/test.dart';

List<String> _codes(String source) => [
  for (final node in parseScriptOutline(source).all)
    switch (node) {
      ScriptArmNode() => scriptArmCode(node),
      ScriptCallNode() || ScriptBranchNode() => null,
      _ => scriptGroupCode(node),
    },
].whereType<String>().toList();

void main() {
  test('groups read as the code that opens them', () {
    expect(
      _codes(
        'for (const f of files) { await tools.a({}); }\n'
        'while (more) { await tools.b({}); }\n'
        'do { await tools.c({}); } while (!done);\n'
        'await Promise.allSettled(xs.map((x) => tools.d({ x })));\n'
        'async function load(p) { return tools.e({ p }); }',
      ),
      [
        'for (const f of files)',
        'while (more)',
        'do … while (!done)',
        'Promise.allSettled',
        'xs.map(x)',
        'load(p)',
      ],
    );
  });

  test('arms read as their keyword and condition', () {
    expect(
      _codes(
        'if (r.ok) { await tools.a({}); }\n'
        'else if (r.code === 2) { await tools.b({}); }\n'
        'else { await tools.c({}); }\n'
        'switch (k) { case "x": await tools.d({}); break; '
        'default: await tools.e({}); }\n'
        'try { await tools.f({}); } catch (e) { await tools.g({}); } '
        'finally { await tools.h({}); }\n'
        'const v = ok ? await tools.i({}) : await tools.j({});',
      ),
      [
        'if r.ok',
        'else if r.code === 2',
        'else',
        'case "x"',
        'default',
        'catch (e)',
        'finally',
        'if ok',
        'else',
      ],
    );
  });

  group('scriptToolLabel', () {
    test('a short clean name is kept as it is', () {
      expect(scriptToolLabel('Read'), 'Read');
      expect(scriptToolLabel('x' * scriptToolLabelLength), 'x' * 24);
    });

    test('control and format characters and separators are dropped', () {
      expect(scriptToolLabel('ev\u202Eil\u200D'), 'evil');
      expect(scriptToolLabel('a\u0000b\u007Fc\u0085d'), 'abcd');
      expect(scriptToolLabel('a\u2028b\u2029c'), 'abc');
      expect(scriptToolLabel('a\u2066b\u2069c\uFEFFd\u00ADe'), 'abcde');
      // A mark that is not a format character stays.
      expect(scriptToolLabel('e\u0301'), 'e\u0301');
    });

    test('a long name is cut to 24 characters ending in an ellipsis', () {
      final label = scriptToolLabel('x' * 64);
      expect(label, '${'x' * 23}…');
      expect(label.runes.length, scriptToolLabelLength);
    });

    test('a cut never splits a character outside the BMP', () {
      final label = scriptToolLabel('😀' * 30);
      expect(label, '${'😀' * 23}…');
    });

    test('characters are counted after the dropped ones are gone', () {
      expect(scriptToolLabel('${'x' * 24}\u200D' * 1), 'x' * 24);
    });
  });
}
