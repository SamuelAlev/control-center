import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_inline_comments/comment_composer_widget.dart';
import 'package:control_center/features/pr_review/providers/comment_composer_mode_provider.dart';
import 'package:control_center/features/pr_review/providers/pr_review_providers.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../../../helpers/test_wrap.dart';

/// The design system draws its own tooltip, so match the send button by the
/// label it carries.
Finder _send(String label) =>
    find.byWidgetPredicate((w) => w is CcIconButton && w.tooltip == label);

Finder get _segments => find.byType(CcSegmentedToggle<CommentComposerMode>);

Widget _host(
  Widget child, {
  required AppPreferences prefs,
  double width = 700,
  TextDirection? textDirection,
}) => ProviderScope(
  overrides: [
    appPreferencesProvider.overrideWithValue(prefs),
    assignableUsersProvider.overrideWith((ref) => Future.value(const [])),
  ],
  child: testWrap(
    Align(
      alignment: AlignmentDirectional.topStart,
      child: SizedBox(width: width, child: child),
    ),
    textDirection: textDirection,
  ),
);

class _Calls {
  final comments = <String>[];
  final batched = <String>[];
  final agent = <String>[];
  Completer<void>? agentReply;

  PrCommentComposer composer({Key? key}) => PrCommentComposer(
    key: key,
    prRef: null,
    autofocus: false,
    onSubmit: comments.add,
    onSubmitBatched: batched.add,
    onSendToAgent: (body) {
      agent.add(body);
      return agentReply?.future ?? Future.value();
    },
    onCancel: () {},
  );
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(CcTextField), text);
  await tester.pump();
}

void main() {
  group('Diff comment destination', () {
    testWidgets('offers agent, comment and review, starting on review', (
      tester,
    ) async {
      final calls = _Calls();
      await tester.pumpWidget(
        _host(calls.composer(), prefs: AppPreferences.inMemory()),
      );
      await tester.pump();

      expect(_segments, findsOneWidget);
      for (final label in ['Agent', 'Comment', 'Review']) {
        expect(
          find.descendant(of: _segments, matching: find.text(label)),
          findsOneWidget,
        );
      }
      expect(
        tester.widget<CcSegmentedToggle<CommentComposerMode>>(_segments).value,
        CommentComposerMode.review,
      );

      await _type(tester, 'nit: rename this');
      await tester.tap(_send('Start a review'));
      await tester.pump();

      expect(calls.batched, ['nit: rename this']);
      expect(calls.comments, isEmpty);
      expect(calls.agent, isEmpty);
    });

    testWidgets('the send label follows the picked destination', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(_Calls().composer(), prefs: AppPreferences.inMemory()),
      );
      await tester.pump();

      await tester.tap(find.text('Comment'));
      await tester.pump();
      expect(_send('Add single comment'), findsOneWidget);

      await tester.tap(find.text('Agent'));
      await tester.pump();
      expect(_send('Send to agent'), findsOneWidget);
    });

    testWidgets('the placeholder names where the comment goes', (tester) async {
      await tester.pumpWidget(
        _host(_Calls().composer(), prefs: AppPreferences.inMemory()),
      );
      await tester.pump();
      expect(find.text('Add to review…'), findsOneWidget);

      await tester.tap(find.text('Agent'));
      await tester.pump();
      expect(find.text('Send to agent…'), findsOneWidget);
      expect(find.text('Add to review…'), findsNothing);

      await tester.tap(find.text('Comment'));
      await tester.pump();
      expect(find.text('Leave a comment…'), findsOneWidget);
    });

    testWidgets('remembers the last pick in the user preferences', (
      tester,
    ) async {
      final prefs = AppPreferences.inMemory();
      final calls = _Calls();
      await tester.pumpWidget(
        _host(calls.composer(key: const ValueKey(1)), prefs: prefs),
      );
      await tester.pump();

      await tester.tap(find.text('Comment'));
      await tester.pump();
      await _type(tester, 'Looks good');
      await tester.tap(_send('Add single comment'));
      await tester.pump();

      expect(calls.comments, ['Looks good']);
      expect(prefs.getString(prCommentComposerModeKey), 'comment');

      // A composer opened later, anywhere, starts where the user left off.
      await tester.pumpWidget(
        _host(calls.composer(key: const ValueKey(2)), prefs: prefs),
      );
      await tester.pump();
      expect(
        tester.widget<CcSegmentedToggle<CommentComposerMode>>(_segments).value,
        CommentComposerMode.comment,
      );
    });

    testWidgets('an agent send keeps the draft until it lands', (tester) async {
      final calls = _Calls()..agentReply = Completer<void>();
      await tester.pumpWidget(
        _host(calls.composer(), prefs: AppPreferences.inMemory()),
      );
      await tester.pump();

      await tester.tap(find.text('Agent'));
      await tester.pump();
      await _type(tester, 'Please add a test for the empty case');
      await tester.tap(_send('Send to agent'));
      await tester.pump();

      expect(calls.agent, ['Please add a test for the empty case']);
      final button = tester.widget<CcIconButton>(_send('Send to agent'));
      expect(button.loading, isTrue);
      expect(button.onPressed, isNull, reason: 'no double send in flight');
      expect(
        tester.widget<CcTextField>(find.byType(CcTextField)).controller?.text,
        'Please add a test for the empty case',
      );

      calls.agentReply!.complete();
      await tester.pump();
      expect(
        tester.widget<CcIconButton>(_send('Send to agent')).loading,
        isFalse,
      );
      expect(calls.comments, isEmpty);
      expect(calls.batched, isEmpty);
    });

    testWidgets('an empty draft sends nothing', (tester) async {
      final calls = _Calls();
      await tester.pumpWidget(
        _host(calls.composer(), prefs: AppPreferences.inMemory()),
      );
      await tester.pump();

      await tester.tap(_send('Start a review'));
      await tester.pump();

      expect(calls.batched, isEmpty);
    });

    testWidgets('without alternatives there is only a send button', (
      tester,
    ) async {
      final sent = <String>[];
      await tester.pumpWidget(
        _host(
          PrCommentComposer(
            prRef: null,
            autofocus: false,
            onSubmit: sent.add,
            onCancel: () {},
          ),
          prefs: AppPreferences.inMemory(),
        ),
      );
      await tester.pump();

      expect(_segments, findsNothing);
      await _type(tester, 'Thanks!');
      await tester.tap(_send('Send'));
      await tester.pump();
      expect(sent, ['Thanks!']);
    });

    testWidgets('a narrow composer keeps the destinations as icons', (
      tester,
    ) async {
      await tester.pumpWidget(
        _host(
          _Calls().composer(),
          prefs: AppPreferences.inMemory(),
          width: 360,
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(
        find.descendant(of: _segments, matching: find.text('Comment')),
        findsNothing,
      );
      expect(
        find.descendant(of: _segments, matching: find.byIcon(AppIcons.bot)),
        findsOneWidget,
      );
    });

    for (final direction in TextDirection.values) {
      testWidgets(
        'cancel, destination, then send at the trailing end (${direction.name})',
        (tester) async {
          await tester.pumpWidget(
            _host(
              _Calls().composer(),
              prefs: AppPreferences.inMemory(),
              textDirection: direction,
            ),
          );
          await tester.pump();

          final cancel = tester.getRect(find.text('Cancel'));
          final segments = tester.getRect(_segments);
          final send = tester.getRect(_send('Start a review'));
          final composer = tester.getRect(find.byType(PrCommentComposer));
          if (direction == TextDirection.ltr) {
            expect(cancel.right, lessThan(segments.left));
            expect(segments.right, lessThan(send.left));
            expect(composer.right - send.right, lessThan(40));
          } else {
            expect(cancel.left, greaterThan(segments.right));
            expect(segments.left, greaterThan(send.right));
            expect(send.left - composer.left, lessThan(40));
          }
        },
      );
    }
  });
}
