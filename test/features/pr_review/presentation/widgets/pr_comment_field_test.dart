import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_comment_field.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/comment_composer_widget.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

/// The design system draws its own tooltip, so `find.byTooltip` (which looks
/// for Material's `Tooltip`) finds nothing — match the button's label instead.
Finder _action(String label) =>
    find.byWidgetPredicate((w) => w is CcIconButton && w.tooltip == label);

/// The rich-comment vocabulary every PR comment surface must offer. Named here
/// rather than inline so the "the diff composer has the same affordances as the
/// review body" test can assert against the same list.
const _affordances = ['Bold', 'Add emoji', 'Add GIF'];

Widget _host(Widget child) => ProviderScope(
  overrides: [
    assignableUsersProvider.overrideWith((ref) => Future.value(const [])),
  ],
  child: testWrap(SizedBox(width: 700, child: child)),
);

void main() {
  late TextEditingController controller;
  late FocusNode focusNode;

  setUp(() {
    controller = TextEditingController();
    focusNode = FocusNode(debugLabel: 'commentField');
  });

  tearDown(() {
    controller.dispose();
    focusNode.dispose();
  });

  Future<void> pumpField(
    WidgetTester tester, {
    Future<void> Function()? onAttachImage,
    WidgetBuilder? footer,
  }) async {
    await tester.pumpWidget(
      _host(
        PrCommentField(
          controller: controller,
          focusNode: focusNode,
          hintText: 'Leave a comment…',
          owner: 'octocat',
          repo: 'hello-world',
          onAttachImage: onAttachImage,
          footer: footer,
        ),
      ),
    );
    await tester.pump();
  }

  group('PrCommentField', () {
    testWidgets('offers formatting, emoji and GIF alongside the field', (
      tester,
    ) async {
      await pumpField(tester);

      for (final tooltip in _affordances) {
        expect(
          _action(tooltip),
          findsOneWidget,
          reason: 'missing the "$tooltip" affordance',
        );
      }
      expect(find.byType(CcTextField), findsOneWidget);
    });

    testWidgets('the image button appears only when the host can upload', (
      tester,
    ) async {
      await pumpField(tester);
      expect(_action('Attach image'), findsNothing);

      await pumpField(tester, onAttachImage: () async {});
      expect(_action('Attach image'), findsOneWidget);
    });

    testWidgets('Preview renders the markdown and keeps the footer', (
      tester,
    ) async {
      await pumpField(tester, footer: (context) => const Text('SUBMIT ROW'));
      controller.text = '**bold body**';
      await tester.pump();

      expect(find.text('SUBMIT ROW'), findsOneWidget);

      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      // The write-mode field is gone, the rendered body is there, and the
      // host's submit row survived the switch — flipping to Preview must not
      // take away the button that posts the comment.
      expect(find.byType(CcTextField), findsNothing);
      expect(find.textContaining('bold body'), findsWidgets);
      expect(find.text('SUBMIT ROW'), findsOneWidget);
    });

    testWidgets('an empty body previews as a stated empty state', (
      tester,
    ) async {
      await pumpField(tester);
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      expect(find.text('Nothing to preview'), findsOneWidget);
    });

    testWidgets('a completed :shortcode: becomes its emoji as you type', (
      tester,
    ) async {
      await pumpField(tester);

      controller.text = 'ship it :rocket:';
      await tester.pump();

      expect(controller.text, 'ship it 🚀');
      // …and the caret lands after the emoji, not back at the start.
      expect(controller.selection.baseOffset, 'ship it 🚀'.length);
    });

    testWidgets('an unknown :shortcode: is left alone', (tester) async {
      await pumpField(tester);

      controller.text = 'see :not_an_emoji_name:';
      await tester.pump();

      expect(controller.text, 'see :not_an_emoji_name:');
    });
  });

  group('PrCommentComposer', () {
    // The point of the unification: a comment written on the diff gets the same
    // vocabulary as one written in the review body. It used to be a bare text
    // field with a send button.
    testWidgets('the diff composer carries the same affordances', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          PrCommentComposer(
            prRef: null,
            autofocus: false,
            onSubmit: (_) {},
            onCancel: () {},
          ),
        ),
      );
      await tester.pump();

      for (final tooltip in _affordances) {
        expect(
          _action(tooltip),
          findsOneWidget,
          reason: 'the diff composer is missing "$tooltip"',
        );
      }
      expect(find.text('Preview'), findsOneWidget);
    });

    testWidgets('the submit row stays reachable from Preview', (tester) async {
      var submitted = '';
      await tester.pumpWidget(
        _host(
          PrCommentComposer(
            prRef: null,
            autofocus: false,
            onSubmit: (body) => submitted = body,
            onCancel: () {},
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(CcTextField), 'Great work!');
      await tester.tap(find.text('Preview'));
      await tester.pumpAndSettle();

      await tester.tap(_action('Send'));
      await tester.pump();
      expect(submitted, 'Great work!');
    });
  });
}
