import 'package:cc_domain/features/code_mode/domain/services/script_run_view.dart';
import 'package:cc_domain/features/code_mode/domain/services/script_run_view_source.dart';
import 'package:test/test.dart';

ScriptRunCall<String> _call({int? line}) => ScriptRunCall(
  payload: 'p',
  toolName: 'a',
  line: line,
  column: line == null ? null : 7,
  running: false,
  failed: false,
  startMs: null,
  endMs: null,
);

void main() {
  test('the same text is parsed once', () {
    const source = 'await tools.a({});';
    expect(
      identical(cachedScriptOutline(source), cachedScriptOutline(source)),
      isTrue,
    );
  });

  test('the cache keeps only the most recent texts', () {
    final first = cachedScriptOutline('await tools.first({});');
    for (var i = 0; i < scriptOutlineCacheSize; i++) {
      cachedScriptOutline('await tools.x$i({});');
    }
    expect(
      identical(first, cachedScriptOutline('await tools.first({});')),
      isFalse,
    );
  });

  group('cachedScriptRunView', () {
    const source = 'await tools.a({});\nawait tools.a({});';
    List<ScriptRunCall<String>> calls({bool failed = false}) => [
      ScriptRunCall(
        payload: 'first',
        toolName: 'a',
        line: 1,
        column: 7,
        running: false,
        failed: failed,
        startMs: null,
        endMs: null,
      ),
    ];

    test('a rebuild with equal calls gets the same view', () {
      final outline = cachedScriptOutline(source);
      final view = cachedScriptRunView(
        outline: outline,
        calls: calls(),
        ended: false,
      );
      expect(
        identical(
          view,
          cachedScriptRunView(outline: outline, calls: calls(), ended: false),
        ),
        isTrue,
      );
    });

    test('a call that changed, or the end, builds a new view', () {
      final outline = cachedScriptOutline(source);
      final view = cachedScriptRunView(
        outline: outline,
        calls: calls(),
        ended: false,
      );
      final failed = cachedScriptRunView(
        outline: outline,
        calls: calls(failed: true),
        ended: false,
      );
      expect(identical(view, failed), isFalse);
      final ended = cachedScriptRunView(
        outline: outline,
        calls: calls(),
        ended: true,
      );
      expect(identical(view, ended), isFalse);
      expect(ended.counts.skipped, 1);
      expect(view.counts.queued, 1);
    });

    test('a different payload builds a new view', () {
      final outline = cachedScriptOutline(source);
      final view = cachedScriptRunView(
        outline: outline,
        calls: calls(),
        ended: false,
      );
      final other = cachedScriptRunView(
        outline: outline,
        calls: const [
          ScriptRunCall(
            payload: 'second',
            toolName: 'a',
            line: 1,
            column: 7,
            running: false,
            failed: false,
            startMs: null,
            endMs: null,
          ),
        ],
        ended: false,
      );
      expect(identical(view, other), isFalse);
    });
  });

  group('scriptRunViewOrFlat', () {
    test('flat with no script text', () {
      expect(
        scriptRunViewOrFlat(source: null, calls: [_call()], ended: false),
        isNull,
      );
      expect(
        scriptRunViewOrFlat(source: '  ', calls: [_call()], ended: false),
        isNull,
      );
    });

    test('flat when the outline is unparsed', () {
      expect(
        scriptRunViewOrFlat(
          source: 'await tools.a({',
          calls: [_call(line: 1)],
          ended: false,
        ),
        isNull,
      );
    });

    test('flat when calls were made and none has a site', () {
      expect(
        scriptRunViewOrFlat(
          source: 'await tools.a({});',
          calls: [_call(), _call()],
          ended: false,
        ),
        isNull,
      );
    });

    test('flat when calls were made from a script with no call node', () {
      expect(
        scriptRunViewOrFlat(
          source: 'const r = tools.a; await r({});',
          calls: [_call(line: 1)],
          ended: false,
        ),
        isNull,
      );
    });

    test('empty for a script with no calls at all', () {
      final view = scriptRunViewOrFlat<String>(
        source: 'return 1;',
        calls: [],
        ended: true,
      );
      expect(view, isNotNull);
      expect(view!.nodes, isEmpty);
      expect(view.unattached, isEmpty);
    });

    test('a tree before the first call and once calls have sites', () {
      const source = 'await tools.a({});';
      expect(
        scriptRunViewOrFlat<String>(
          source: source,
          calls: [],
          ended: false,
        )!.counts.queued,
        1,
      );
      expect(
        scriptRunViewOrFlat(
          source: source,
          calls: [_call(line: 1)],
          ended: false,
        )!.counts.done,
        1,
      );
    });
  });
}
