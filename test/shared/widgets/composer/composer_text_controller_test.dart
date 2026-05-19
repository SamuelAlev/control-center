import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/composer/composer_text_controller.dart';
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
}
