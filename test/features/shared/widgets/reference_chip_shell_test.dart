import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/reference_chip_shell.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

void main() {
  group('ReferenceChipShell', () {
    testWidgets('renders child content', (tester) async {
      await tester.pumpWidget(
        testWrap(ReferenceChipShell(child: const Text('#42'), onTap: () {})),
      );

      expect(find.text('#42'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        testWrap(
          ReferenceChipShell(
            child: const Text('click me'),
            onTap: () => tapped = true,
          ),
        ),
      );

      await tester.tap(find.text('click me'));
      expect(tapped, isTrue);
    });

    testWidgets('uses a click cursor and is not selectable', (tester) async {
      await tester.pumpWidget(
        testWrap(
          SelectionArea(
            child: ReferenceChipShell(child: const Text('#42'), onTap: () {}),
          ),
        ),
      );

      final cursors = tester
          .widgetList<MouseRegion>(find.byType(MouseRegion))
          .map((region) => region.cursor);
      expect(cursors, contains(SystemMouseCursors.click));
      expect(cursors, isNot(contains(SystemMouseCursors.text)));

      final disabled = tester
          .widgetList<SelectionContainer>(find.byType(SelectionContainer))
          .where((container) => container.delegate == null);
      expect(disabled, isNotEmpty);
    });

    testWidgets('washes the fill on hover', (tester) async {
      await tester.pumpWidget(
        testWrap(ReferenceChipShell(child: const Text('#42'), onTap: () {})),
      );

      final tokens = DesignSystemTokens.light();
      BoxDecoration decoration() =>
          tester
                  .widget<AnimatedContainer>(find.byType(AnimatedContainer))
                  .decoration!
              as BoxDecoration;

      expect(decoration().color, tokens.bgSecondary);

      final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await gesture.addPointer(location: Offset.zero);
      addTearDown(gesture.removePointer);
      await tester.pump();
      await gesture.moveTo(tester.getCenter(find.text('#42')));
      await tester.pump(const Duration(milliseconds: 120));

      expect(decoration().color, tokens.bgTertiary);
    });

    testWidgets('renders complex child widget', (tester) async {
      await tester.pumpWidget(
        testWrap(
          ReferenceChipShell(
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.code, size: 14),
                SizedBox(width: 4),
                Text('abc123'),
              ],
            ),
            onTap: () {},
          ),
        ),
      );

      expect(find.text('abc123'), findsOneWidget);
      expect(find.byIcon(Icons.code), findsOneWidget);
    });
  });

  group('ReferenceFallbackLink', () {
    testWidgets('renders label', (tester) async {
      await tester.pumpWidget(
        testWrap(
          ReferenceFallbackLink(label: 'github.com/org/repo#42', onTap: () {}),
        ),
      );

      expect(find.text('github.com/org/repo#42'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        testWrap(
          ReferenceFallbackLink(label: 'tap link', onTap: () => tapped = true),
        ),
      );

      await tester.tap(find.text('tap link'));
      expect(tapped, isTrue);
    });
  });
}
