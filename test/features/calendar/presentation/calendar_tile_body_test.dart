import 'package:control_center/features/calendar/presentation/widgets/calendar_tile_body.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

// The test font draws every glyph as a square of the font size, so the title
// (11 px, plus the theme's letter spacing) fits roughly `(width - 10) / 11.25`
// characters on a line and a line is 13.2 px.
Widget _tile({
  required double width,
  required double height,
  String title = 'Monthly Office Hours',
  String? time = '12:00–13:00',
  TextDirection? textDirection,
}) {
  return testWrap(
    Align(
      alignment: Alignment.topLeft,
      child: SizedBox(
        width: width,
        height: height,
        child: CalendarTimedTileBody(
          title: title,
          timeLabel: time,
          titleColor: const Color(0xFF000000),
          timeColor: const Color(0xFF666666),
        ),
      ),
    ),
    textDirection: textDirection,
  );
}

Text _titleText(WidgetTester tester, String title) => tester.widget<Text>(
  find.byWidgetPredicate(
    (widget) =>
        widget is Text &&
        (widget.data ?? widget.textSpan?.toPlainText() ?? '').contains(title),
  ),
);

void main() {
  testWidgets('a short tile keeps one ellipsized line with the time inline', (
    tester,
  ) async {
    await tester.pumpWidget(_tile(width: 240, height: 17));

    final text = _titleText(tester, 'Monthly Office Hours');
    expect(text.maxLines, 1);
    expect(text.overflow, TextOverflow.ellipsis);
    expect(text.textSpan?.toPlainText(), 'Monthly Office Hours  12:00–13:00');
    expect(tester.takeException(), isNull);
  });

  testWidgets('the title gets the lines that fit above the time', (
    tester,
  ) async {
    // 6 px padding + 2 title lines (26.4) + the time line (13) = 45.4.
    await tester.pumpWidget(_tile(width: 120, height: 46));

    final text = _titleText(tester, 'Monthly Office Hours');
    expect(text.maxLines, 2);
    expect(text.overflow, TextOverflow.ellipsis);
    final time = tester.widget<Text>(find.text('12:00–13:00'));
    expect(time.maxLines, 1);
    expect(time.softWrap, isFalse);
  });

  testWidgets('a tall tile lets the title run as far as its height', (
    tester,
  ) async {
    await tester.pumpWidget(_tile(width: 120, height: 100));

    expect(_titleText(tester, 'Monthly Office Hours').maxLines, 6);
  });

  testWidgets('a title is ellipsized rather than broken inside a word', (
    tester,
  ) async {
    // Five characters per line: "Monthly" would wrap as "Month" / "ly".
    await tester.pumpWidget(_tile(width: 65, height: 100));

    expect(_titleText(tester, 'Monthly Office Hours').maxLines, 1);
  });

  testWidgets('a break between words keeps the following lines', (
    tester,
  ) async {
    // Seven characters per line: "Monthly" / "Office" / "Hours".
    await tester.pumpWidget(_tile(width: 95, height: 100));

    expect(_titleText(tester, 'Monthly Office Hours').maxLines, 6);
  });

  testWidgets('a tile without a time shows the title alone', (tester) async {
    await tester.pumpWidget(_tile(width: 120, height: 17, time: null));

    final text = _titleText(tester, 'Monthly Office Hours');
    expect(text.textSpan?.toPlainText(), 'Monthly Office Hours');
  });

  testWidgets('lays out under RTL and at zero height', (tester) async {
    await tester.pumpWidget(
      _tile(width: 65, height: 0, textDirection: TextDirection.rtl),
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(
      _tile(width: 65, height: 60, textDirection: TextDirection.rtl),
    );
    expect(tester.takeException(), isNull);
  });
}
