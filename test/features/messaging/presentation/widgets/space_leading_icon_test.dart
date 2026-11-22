import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row_adornments.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  BoxDecoration dotDecoration(WidgetTester tester) =>
      tester
              .widget<Container>(
                find.descendant(
                  of: find.byType(AttentionDot),
                  matching: find.byType(Container),
                ),
              )
              .decoration!
          as BoxDecoration;

  test('a quiet space has no signal, so its title keeps the inset', () {
    expect(
      spaceRowSignal(running: false, attention: false, selected: false),
      isNull,
    );
  });

  testWidgets('an unread or waiting space shows the accent dot', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        Center(
          child: spaceRowSignal(
            running: false,
            attention: true,
            selected: false,
          ),
        ),
      ),
    );

    final dot = find.byType(AttentionDot);
    expect(dot, findsOneWidget);
    expect(tester.getSize(dot), const Size.square(6));
    expect(dotDecoration(tester).color, DesignSystemTokens.light().accent);
  });

  testWidgets('on the selected fill the dot takes accentOn', (tester) async {
    await tester.pumpWidget(
      testWrap(
        Center(
          child: spaceRowSignal(
            running: false,
            attention: true,
            selected: true,
          ),
        ),
      ),
    );

    expect(dotDecoration(tester).color, DesignSystemTokens.light().accentOn);
  });

  testWidgets('a running space spins instead of the dot', (tester) async {
    await tester.pumpWidget(
      testWrap(
        Center(
          child: spaceRowSignal(
            running: true,
            attention: true,
            selected: false,
          ),
        ),
      ),
    );

    expect(find.byType(CcSpinner), findsOneWidget);
    expect(find.byType(AttentionDot), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());
  });
}
