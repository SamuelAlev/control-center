import 'package:cc_domain/features/pipelines/domain/services/template_renderer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TemplateRenderer', () {
    const renderer = TemplateRenderer();

    // ── render ──────────────────────────────────────────────────────────

    test('render substitutes bare key from state',
        timeout: const Timeout.factor(2), () {
      final result = renderer.render('Hello {{name}}', state: {'name': 'world'});
      expect(result.text, 'Hello world');
      expect(result.unresolved, isEmpty);
      expect(result.isComplete, isTrue);
    });

    test('render substitutes bare key from trigger when not in state',
        timeout: const Timeout.factor(2), () {
      final result = renderer.render(
        '{{author}}',
        state: {},
        trigger: {'author': 'octocat'},
      );
      expect(result.text, 'octocat');
      expect(result.isComplete, isTrue);
    });

    test('state takes precedence over trigger for bare keys',
        timeout: const Timeout.factor(2), () {
      final result = renderer.render(
        '{{k}}',
        state: {'k': 'from_state'},
        trigger: {'k': 'from_trigger'},
      );
      expect(result.text, 'from_state');
    });

    test(r'render substitutes $state.key', timeout: const Timeout.factor(2), () {
      final result = renderer.render(
        r'{{$state.path}}',
        state: {'path': '/repo'},
      );
      expect(result.text, '/repo');
    });

    test(r'render substitutes $trigger.key',
        timeout: const Timeout.factor(2), () {
      final result = renderer.render(
        r'{{$trigger.author}}',
        state: {},
        trigger: {'author': 'octocat'},
      );
      expect(result.text, 'octocat');
    });

    test('unresolved placeholders render as empty string',
        timeout: const Timeout.factor(2), () {
      final result = renderer.render(
        'a={{a}} b={{b}}',
        state: {'a': 1},
      );
      expect(result.text, 'a=1 b=');
      expect(result.unresolved, {'b'});
      expect(result.isComplete, isFalse);
    });

    test('multiple unresolved placeholders tracked',
        timeout: const Timeout.factor(2), () {
      final result = renderer.render(
        '{{x}} {{y}} {{z}}',
        state: {},
      );
      expect(result.unresolved, {'x', 'y', 'z'});
    });

    test('placeholders with whitespace inside braces',
        timeout: const Timeout.factor(2), () {
      final result = renderer.render(
        '{{ name }}',
        state: {'name': 'Alice'},
      );
      expect(result.text, 'Alice');
    });

    test('no placeholders returns original text',
        timeout: const Timeout.factor(2), () {
      final result = renderer.render(
        'no placeholders here',
        state: {},
      );
      expect(result.text, 'no placeholders here');
      expect(result.isComplete, isTrue);
    });

    test('empty template returns empty', timeout: const Timeout.factor(2), () {
      final result = renderer.render('', state: {});
      expect(result.text, '');
      expect(result.isComplete, isTrue);
    });

    test(r'$state. prefix with missing key produces unresolved',
        timeout: const Timeout.factor(2), () {
      final result = renderer.render(
        r'Value: {{$state.missing}}',
        state: {},
      );
      expect(result.text, 'Value: ');
      expect(result.unresolved, {r'$state.missing'});
      expect(result.isComplete, isFalse);
    });

    test(r'$trigger. prefix with trigger=null produces unresolved',
        timeout: const Timeout.factor(2), () {
      final result = renderer.render(
        r'Trigger: {{$trigger.author}}',
        state: {},
      );
      expect(result.text, 'Trigger: ');
      expect(result.unresolved, {r'$trigger.author'});
      expect(result.isComplete, isFalse);
    });

    test('dotted bare key treated as flat lookup (not nested)',
        timeout: const Timeout.factor(2), () {
      // The regex captures "a.b" as one token; resolve does flat map lookup.
      final result = renderer.render(
        '{{a.b}}',
        state: {'a': {'b': 42}},
      );
      // Flat lookup: state['a.b'] is null
      expect(result.text, '');
      expect(result.unresolved, {'a.b'});
    });

    test('renders numeric and boolean values',
        timeout: const Timeout.factor(2), () {
      final result = renderer.render(
        'count={{count}} active={{active}}',
        state: {'count': 5, 'active': true},
      );
      expect(result.text, 'count=5 active=true');
    });

    test('renders special characters in values',
        timeout: const Timeout.factor(2), () {
      final result = renderer.render(
        'msg={{msg}}',
        state: {'msg': 'a "quoted" string\nwith newlines'},
      );
      expect(result.text, 'msg=a "quoted" string\nwith newlines');
    });

    test('complex template with mixed refs',
        timeout: const Timeout.factor(2), () {
      final result = renderer.render(
        r'PR #{{prNumber}} by {{$trigger.author}} at {{$state.path}}',
        state: {'prNumber': 42, 'path': '/repo'},
        trigger: {'author': 'octocat'},
      );
      expect(result.text, 'PR #42 by octocat at /repo');
      expect(result.isComplete, isTrue);
    });

    test('isComplete true only when no unresolved',
        timeout: const Timeout.factor(2), () {
      final complete = renderer.render('ok', state: {'ok': 'done'});
      expect(complete.isComplete, isTrue);

      final incomplete = renderer.render('{{missing}}', state: {});
      expect(incomplete.isComplete, isFalse);
    });

    test('escape is applied to every resolved value (shell-injection guard)',
        timeout: const Timeout.factor(2), () {
      // VULN-007: the bash-script renderer passes a shell-escape so an
      // untrusted trigger value (e.g. an external ticket title) spliced into a
      // `"{{x}}"` context can't break out into arbitrary commands.
      String shellEscape(String v) => v
          .replaceAll('\\', r'\\')
          .replaceAll(r'"', r'\"')
          .replaceAll(r'$', r'\$')
          .replaceAll(r'`', r'\`');
      const title = 'a"; rm -rf ~; echo "';
      final result = renderer.render(
        'gh pr create --title "{{title}}"',
        state: const {'title': title},
        escape: shellEscape,
      );
      // Both `"` from the value are backslash-escaped, so bash reads the whole
      // title as ONE literal double-quoted argument — the embedded `;` never
      // becomes a command separator (no injection).
      expect(result.text, contains(r'a\"'));
      expect(result.text, contains(r'echo \"'));
      // No UNescaped value `"` reaches the script (an unescaped `a";` would
      // close the surrounding quotes and let `; rm` execute).
      expect(result.text, isNot(contains('a";')));
    });

    // ── placeholders ────────────────────────────────────────────────────

    test('placeholders() extracts all refs', timeout: const Timeout.factor(2), () {
      final refs = renderer.placeholders(
        r'{{a}} and {{$state.b}} and {{$trigger.c}}',
      );
      expect(refs, {'a', r'$state.b', r'$trigger.c'});
    });

    test('placeholders() deduplicates', timeout: const Timeout.factor(2), () {
      final refs = renderer.placeholders('{{a}} {{a}} {{b}}');
      expect(refs, {'a', 'b'});
    });

    test('placeholders() with no placeholders returns empty',
        timeout: const Timeout.factor(2), () {
      expect(renderer.placeholders('no refs'), isEmpty);
    });

    // ── resolve ─────────────────────────────────────────────────────────

    test('resolve returns null for missing keys',
        timeout: const Timeout.factor(2), () {
      expect(
        renderer.resolve('missing', state: {}, trigger: {}),
        isNull,
      );
    });

    test(r'resolve handles $state prefix', timeout: const Timeout.factor(2), () {
      expect(
        renderer.resolve(r'$state.key', state: {'key': 'val'}),
        'val',
      );
    });

    test(r'resolve handles $trigger prefix',
        timeout: const Timeout.factor(2), () {
      expect(
        renderer.resolve(r'$trigger.key', state: {}, trigger: {'key': 'val'}),
        'val',
      );
    });

    test(r'$state. prefix with missing key returns null',
        timeout: const Timeout.factor(2), () {
      expect(
        renderer.resolve(r'$state.nope', state: {}),
        isNull,
      );
    });

    test(r'$trigger. prefix with trigger=null returns null',
        timeout: const Timeout.factor(2), () {
      expect(
        renderer.resolve(r'$trigger.nope', state: {}),
        isNull,
      );
    });

    test('bare key resolves from trigger when state absent',
        timeout: const Timeout.factor(2), () {
      expect(
        renderer.resolve('key', state: {}, trigger: {'key': 'fromTrigger'}),
        'fromTrigger',
      );
    });

    // ── isTriggerScoped ─────────────────────────────────────────────────

    test(r'isTriggerScoped identifies $trigger refs',
        timeout: const Timeout.factor(2), () {
      expect(renderer.isTriggerScoped(r'$trigger.x'), isTrue);
      expect(renderer.isTriggerScoped(r'$state.x'), isFalse);
      expect(renderer.isTriggerScoped('bare'), isFalse);
      expect(renderer.isTriggerScoped(r'$state.trigger'), isFalse);
    });

    // ── stateKeyOf ──────────────────────────────────────────────────────

    test('stateKeyOf extracts state key',
        timeout: const Timeout.factor(2), () {
      expect(renderer.stateKeyOf(r'$state.path'), 'path');
      expect(renderer.stateKeyOf('bare'), 'bare');
      expect(renderer.stateKeyOf(r'$trigger.x'), isNull);
    });

    test('stateKeyOf returns bare key unchanged', () {
      expect(renderer.stateKeyOf('key'), 'key');
    });
  });

  group('RenderResult', () {
    test('isComplete is true when unresolved is empty',
        timeout: const Timeout.factor(2), () {
      const result = RenderResult(text: 'ok', unresolved: {});
      expect(result.isComplete, isTrue);
    });

    test('isComplete is false when unresolved has entries',
        timeout: const Timeout.factor(2), () {
      const result = RenderResult(text: '', unresolved: {'x'});
      expect(result.isComplete, isFalse);
    });

    test('text and unresolved fields are accessible',
        timeout: const Timeout.factor(2), () {
      const result = RenderResult(
        text: 'Hello world',
        unresolved: {'a', 'b'},
      );
      expect(result.text, 'Hello world');
      expect(result.unresolved, {'a', 'b'});
    });
  });
}
