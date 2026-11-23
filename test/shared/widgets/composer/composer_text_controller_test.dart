import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/syntax/shiki_tokenizers.dart';
import 'package:control_center/shared/widgets/composer/composer_text_controller.dart';
import 'package:control_center/shared/widgets/markdown/code_highlighter.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late ComposerTextController controller;

  setUp(() {
    controller = ComposerTextController()..tokens = DesignSystemTokens.light();
  });

  tearDown(() => controller.dispose());

  /// Pumps a trivial tree and returns the span the field would paint.
  ///
  /// A real element is needed because `buildTextSpan` takes a `BuildContext` —
  /// even though this controller only falls back to it when no tokens are set.
  Future<TextSpan> spanOf(
    WidgetTester tester, {
    bool withComposing = false,
  }) async {
    late BuildContext ctx;
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          ctx = context;
          return const SizedBox();
        },
      ),
    );
    return controller.buildTextSpan(
      context: ctx,
      style: const TextStyle(fontSize: 14),
      withComposing: withComposing,
    );
  }

  // The invariant everything else rests on: the painted characters must be
  // EXACTLY the controller's text. A span that adds, drops or reorders a
  // character puts every caret offset after it in the wrong place.
  testWidgets('paints the same characters it was given', (tester) async {
    controller.text = 'compare @[file:a.png] with @[file:b.png] please';
    final span = await spanOf(tester);
    expect(span.toPlainText(), controller.text);
  });

  testWidgets('styles a resolved reference and leaves the rest alone', (
    tester,
  ) async {
    controller
      ..text = 'see @[file:a.png] now'
      ..isResolved = (name) => name == 'a.png';
    final span = await spanOf(tester);
    final children = span.children!.cast<TextSpan>();
    expect(children.map((c) => c.text), ['see ', '@[file:a.png]', ' now']);
    expect(children[0].style, isNull);
    expect(children[1].style?.color, DesignSystemTokens.light().accent);
    expect(children[2].style, isNull);
    expect(span.toPlainText(), controller.text);
  });

  testWidgets('a reference nothing resolves stays plain text', (tester) async {
    controller
      ..text = 'see @[file:typed-by-hand.md] now'
      ..isResolved = (_) => false;
    final span = await spanOf(tester);
    expect(span.toPlainText(), controller.text);
    expect(
      span.children!.cast<TextSpan>().every((c) => c.style == null),
      isTrue,
    );
  });

  testWidgets('text with no reference is one plain run', (tester) async {
    controller.text = 'just a message';
    final span = await spanOf(tester);
    expect(span.children, isNull);
    expect(span.text, 'just a message');
  });

  testWidgets('an in-flight IME composition keeps its own underline', (
    tester,
  ) async {
    controller
      ..value = const TextEditingValue(
        text: 'see @[file:a.png] abc',
        composing: TextRange(start: 18, end: 21),
        selection: TextSelection.collapsed(offset: 21),
      )
      ..isResolved = (_) => true;
    final span = await spanOf(tester, withComposing: true);
    // Deferred to the base implementation, which marks the composing range —
    // and, either way, still paints exactly the text it was given.
    expect(span.toPlainText(), controller.text);
    expect(
      span.children!.cast<TextSpan>().any(
        (c) => c.style?.decoration == TextDecoration.underline,
      ),
      isTrue,
    );
  });

  testWidgets('paints Markdown in place and keeps every character', (
    tester,
  ) async {
    final ds = DesignSystemTokens.light();
    controller.text = 'rename `Foo` and make it **bold**';
    final span = await spanOf(tester);
    expect(span.toPlainText(), controller.text);
    final children = span.children!.cast<TextSpan>();
    expect(children.map((c) => c.text), [
      'rename ',
      '`',
      'Foo',
      '`',
      ' and make it ',
      '**',
      'bold',
      '**',
    ]);
    final code = children[2].style!;
    expect(code.fontFamily, CcFonts.code().fontFamily);
    expect(code.backgroundColor, ds.hoverStrong);
    // Delimiters stay in the text, dimmed, inside the same code chip.
    expect(children[1].style!.color, ds.textPlaceholder);
    expect(children[1].style!.backgroundColor, ds.hoverStrong);
    expect(children[6].style!.fontWeight, FontWeight.w600);
    expect(children[5].style!.color, ds.textPlaceholder);
    expect(children[0].style, isNull);
  });

  testWidgets('a pill keeps its own style inside emphasis', (tester) async {
    controller
      ..text = '*see @[file:a_b.png] now*'
      ..isResolved = (_) => true;
    final span = await spanOf(tester);
    expect(span.toPlainText(), controller.text);
    final pill = span.children!.cast<TextSpan>().firstWhere(
      (c) => c.text == '@[file:a_b.png]',
    );
    expect(pill.style?.color, DesignSystemTokens.light().accent);
    expect(pill.style?.fontStyle, isNull);
  });

  testWidgets('markdownOnly paints Markdown but never a file pill', (
    tester,
  ) async {
    controller.dispose();
    controller = ComposerTextController.markdownOnly(
      text: 'read @[file:a.png] **now**',
    )..tokens = DesignSystemTokens.light();
    final span = await spanOf(tester);
    expect(span.toPlainText(), controller.text);
    final children = span.children!.cast<TextSpan>();
    final reference = children.firstWhere((c) => c.text == '@[file:a.png]');
    expect(reference.style, isNull);
    final bold = children.firstWhere((c) => c.text == 'now');
    expect(bold.style?.fontWeight, FontWeight.w600);
  });

  group('leading slash command', () {
    /// The text of every run painted in the accent, in order.
    List<String> accentRuns(TextSpan span) {
      final accent = DesignSystemTokens.light().accent;
      final out = <String>[];
      span.visitChildren((child) {
        if (child is TextSpan &&
            child.text != null &&
            child.style?.color == accent &&
            child.style?.backgroundColor == null) {
          out.add(child.text!);
        }
        return true;
      });
      return out;
    }

    testWidgets('is plain unless the host takes slash commands', (
      tester,
    ) async {
      controller.text = '/plan the migration';
      final span = await spanOf(tester);
      expect(span.toPlainText(), controller.text);
      expect(accentRuns(span), isEmpty);
    });

    testWidgets('paints the command, and only the command, in the accent', (
      tester,
    ) async {
      controller
        ..paintsCommand = true
        ..text = '/plan the migration';
      final span = await spanOf(tester);
      expect(span.toPlainText(), controller.text);
      expect(accentRuns(span), ['/plan']);
    });

    testWidgets('paints a command still being typed, and a skill by name', (
      tester,
    ) async {
      controller
        ..paintsCommand = true
        ..text = '/sch';
      expect(accentRuns(await spanOf(tester)), ['/sch']);

      // One token: the underscores are not emphasis delimiters.
      controller.text = '/skill:shop-ui:release_notes_draft for v2';
      final span = await spanOf(tester);
      expect(span.toPlainText(), controller.text);
      expect(accentRuns(span), ['/skill:shop-ui:release_notes_draft']);
    });

    testWidgets('leaves a path, a mid-line slash and a bare slash plain', (
      tester,
    ) async {
      controller.paintsCommand = true;
      for (final text in [
        '/usr/bin/env node',
        'run /plan later',
        '/',
        '/ plan',
        'first line\n/plan',
      ]) {
        controller.text = text;
        final span = await spanOf(tester);
        expect(span.toPlainText(), text);
        expect(accentRuns(span), isEmpty, reason: text);
      }
    });

    testWidgets('follows the switch without a text change', (tester) async {
      controller
        ..paintsCommand = true
        ..text = '/goal ship it';
      expect(accentRuns(await spanOf(tester)), ['/goal']);
      controller.paintsCommand = false;
      expect(accentRuns(await spanOf(tester)), isEmpty);
    });

    test('commandRange finds the token after leading whitespace', () {
      expect(ComposerTextController.commandRange('  /loop 5m x'), (
        start: 2,
        end: 7,
      ));
      expect(ComposerTextController.commandRange('/todo append x'), (
        start: 0,
        end: 5,
      ));
      expect(ComposerTextController.commandRange('hello'), isNull);
    });
  });

  group('fenced code', () {
    setUp(() => debugDisableShikiAsync = true);
    tearDown(() => debugDisableShikiAsync = false);

    bool colored(TextSpan span, String text) => span.children!
        .cast<TextSpan>()
        .any((c) => c.text == text && c.style?.color != null);

    TextSpan childWith(TextSpan span, String text) =>
        span.children!.cast<TextSpan>().firstWhere((c) => c.text == text);

    // Past the 16-line synchronous budget of the TypeScript grammar, so the
    // block always tokenizes in the background, however warm the grammar.
    String tsFence(String value) => [
      'look:',
      '```ts',
      'const a = "$value";',
      for (var i = 0; i < 20; i++) 'let v$i = $i;',
      '```',
    ].join('\n');

    testWidgets('a fence that names its language paints in syntax colors', (
      tester,
    ) async {
      final ds = DesignSystemTokens.light();
      controller.text = tsFence('hi');
      var notified = 0;
      controller.addListener(() => notified++);

      // Plain for the frame the background tokenize takes, then a repaint.
      var span = await spanOf(tester);
      expect(span.toPlainText(), controller.text);
      expect(colored(span, 'const'), isFalse);
      await tester.pump();
      expect(notified, 1);

      span = await spanOf(tester);
      expect(span.toPlainText(), controller.text);
      expect(colored(span, 'const'), isTrue);
      expect(
        childWith(span, 'const').style!.fontFamily,
        CcFonts.code().fontFamily,
      );
      // The fence lines stay dimmed scaffolding, not code.
      expect(childWith(span, '```ts').style!.color, ds.textPlaceholder);
      expect(childWith(span, 'look:\n').style, isNull);
    });

    testWidgets('typing in a fence keeps the last colors until new ones land', (
      tester,
    ) async {
      controller.text = tsFence('hi');
      await spanOf(tester);
      await tester.pump();
      expect(colored(await spanOf(tester), 'const'), isTrue);

      // A keystroke: no plain flash while the new text tokenizes.
      controller.text = tsFence('hiya');
      var span = await spanOf(tester);
      expect(span.toPlainText(), controller.text);
      expect(colored(span, 'const'), isTrue);
      await tester.pump();
      span = await spanOf(tester);
      expect(span.toPlainText(), controller.text);
      expect(colored(span, '"hiya"'), isTrue);
    });

    testWidgets('typing outside a fence does not tokenize it again', (
      tester,
    ) async {
      controller.text = 'intro\n```dart\nfinal a = 1;\n```';
      await spanOf(tester);
      await tester.pump();
      expect(colored(await spanOf(tester), 'final'), isTrue);

      final before = debugHighlightParseCount;
      controller.text = 'intro, edited\n```dart\nfinal a = 1;\n```';
      final span = await spanOf(tester);
      await tester.pump();
      expect(colored(span, 'final'), isTrue);
      expect(debugHighlightParseCount, before);
    });

    testWidgets('a fence without a language stays one plain run', (
      tester,
    ) async {
      controller.text = '```\nconst a = "hi";\n```';
      final span = await spanOf(tester);
      await tester.pump();
      expect(span.toPlainText(), controller.text);
      final body = childWith(span, 'const a = "hi";');
      expect(body.style?.color, isNull);
    });
  });
}
