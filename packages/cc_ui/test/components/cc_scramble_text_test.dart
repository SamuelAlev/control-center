import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  const label = 'Untitled conversation';

  /// The overlay keeps its first entry, so later states go through [state]
  /// rather than a fresh `pumpWidget`.
  Widget scramble(
    ValueNotifier<(String, bool)> state, {
    bool reduced = false,
  }) => ccTestApp(
    MediaQuery(
      data: MediaQueryData(disableAnimations: reduced),
      child: Center(
        child: ValueListenableBuilder(
          valueListenable: state,
          builder: (context, value, _) =>
              CcScrambleText(value.$1, scrambling: value.$2),
        ),
      ),
    ),
  );

  /// The churning line: the visible (non-sizer) [Text] while scrambling.
  String visible(WidgetTester tester, [String text = label]) => tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data!)
      .firstWhere((data) => data != text);

  group('CcScrambleText', () {
    testWidgets('renders plain text when not scrambling', (tester) async {
      await tester.pumpWidget(scramble(ValueNotifier((label, false))));

      expect(find.text(label), findsOneWidget);
      expect(find.byType(Stack), findsNothing);
    });

    testWidgets('churns letters, keeping spaces and the box size', (
      tester,
    ) async {
      final state = ValueNotifier((label, false));
      await tester.pumpWidget(scramble(state));
      final size = tester.getSize(find.byType(CcScrambleText));

      state.value = (label, true);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      final first = visible(tester);
      await tester.pump(const Duration(milliseconds: 200));
      final second = visible(tester);

      expect(first.length, label.length);
      expect(first.indexOf(' '), label.indexOf(' '));
      expect(first, isNot(second));
      expect(tester.getSize(find.byType(CcScrambleText)), size);
      state.value = (label, false);
      await tester.pumpAndSettle();
    });

    testWidgets('settles into the new text once scrambling stops', (
      tester,
    ) async {
      final state = ValueNotifier((label, true));
      await tester.pumpWidget(scramble(state));
      await tester.pump(const Duration(milliseconds: 200));

      state.value = ('Git rebase question', false);
      await tester.pumpAndSettle();

      expect(find.text('Git rebase question'), findsOneWidget);
      expect(find.byType(Stack), findsNothing);
    });

    testWidgets('reveals the text character by character, then reports', (
      tester,
    ) async {
      const title = 'Git rebase question';
      var completed = 0;
      final state = ValueNotifier((label, true));
      await tester.pumpWidget(
        ccTestApp(
          Center(
            child: ValueListenableBuilder(
              valueListenable: state,
              builder: (context, value, _) => CcScrambleText(
                value.$1,
                scrambling: value.$2,
                onScrambleComplete: () => completed++,
              ),
            ),
          ),
        ),
      );
      // Generation can run for seconds: the churn holds until it stops.
      await tester.pump(const Duration(seconds: 3));
      expect(completed, 0);

      state.value = (title, false);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 40));
      await tester.pump(const Duration(milliseconds: 400));
      final midway = visible(tester, title);
      // Half the reveal: the front is spelled out, the tail still churns.
      expect(midway.substring(0, 6), title.substring(0, 6));
      expect(midway.length, title.length);
      expect(completed, 0);

      await tester.pumpAndSettle();
      expect(find.text(title), findsOneWidget);
      expect(completed, 1);
    });

    testWidgets('reduced motion shows the text with no churn', (tester) async {
      await tester.pumpWidget(
        scramble(ValueNotifier((label, true)), reduced: true),
      );

      expect(find.text(label), findsOneWidget);
      expect(find.byType(Stack), findsNothing);
      expect(tester.hasRunningAnimations, isFalse);
    });

    testWidgets('assistive technology reads the real text', (tester) async {
      final handle = tester.ensureSemantics();
      final state = ValueNotifier((label, true));
      await tester.pumpWidget(scramble(state));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.bySemanticsLabel(label), findsOneWidget);
      state.value = (label, false);
      await tester.pumpAndSettle();
      handle.dispose();
    });
  });
}
