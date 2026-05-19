import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/calendar_day_icon.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child, {TextScaler textScaler = TextScaler.noScaling}) {
  return MediaQuery(
    data: MediaQueryData(textScaler: textScaler),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: DefaultTextStyle(
        style: const TextStyle(fontSize: 14),
        child: Center(child: child),
      ),
    ),
  );
}

void main() {
  group('CalendarDayIcon', () {
    testWidgets('renders the device-local day of month in the glyph body', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(const CalendarDayIcon(color: Color(0xff3c3c3c), size: 18)),
      );

      // The blank Phosphor outline (never the hardcoded-"12" glyph)…
      final icon = tester.widget<Icon>(find.byType(Icon));
      expect(icon.icon, AppIcons.calendarBlank);
      expect(icon.size, 18);

      // …with today's LOCAL day written into it.
      final text = tester.widget<Text>(
        find.text('${DateTime.now().day}'),
      );
      expect(text.style?.fontSize, 18 * 0.36);
      expect(text.style?.color, const Color(0xff3c3c3c));
    });

    testWidgets('the digit ignores the ambient text scale (icon chrome)', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const CalendarDayIcon(color: Color(0xff3c3c3c), size: 18),
          textScaler: const TextScaler.linear(2),
        ),
      );

      final text = tester.widget<Text>(find.text('${DateTime.now().day}'));
      expect(text.textScaler, TextScaler.noScaling);
    });
  });

  group('nextLocalMidnight', () {
    test('rolls to the next local civil midnight', () {
      final next = nextLocalMidnight(DateTime(2026, 8, 26, 13, 42));
      expect(next, DateTime(2026, 8, 27));
      expect(next.isUtc, isFalse);
    });

    test('crosses month and year boundaries', () {
      expect(nextLocalMidnight(DateTime(2026, 8, 31, 23, 59)), DateTime(2026, 9, 1));
      expect(nextLocalMidnight(DateTime(2026, 12, 31, 23, 59)), DateTime(2027));
    });
  });
}
