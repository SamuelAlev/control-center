import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_height_reveal.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

const _panel = SizedBox(width: 120, height: 240);

Widget _reveal({required bool open, bool reduced = false}) {
  final reveal = SpaceHeightReveal(
    key: const ValueKey('reveal'),
    open: open,
    child: _panel,
  );
  return testWrap(
    Align(
      alignment: Alignment.topCenter,
      child: reduced
          ? CcTheme(data: CcThemeData.light(reducedMotion: true), child: reveal)
          : reveal,
    ),
  );
}

double _height(WidgetTester tester) =>
    tester.getSize(find.byKey(const ValueKey('reveal'))).height;

/// Steps [total] in 120Hz frames.
Future<void> _frames(WidgetTester tester, Duration total) async {
  const frame = Duration(microseconds: 8333);
  var left = total;
  while (left > Duration.zero) {
    final step = left < frame ? left : frame;
    await tester.pump(step);
    left -= step;
  }
}

void main() {
  testWidgets('a late frame pauses the close instead of jumping it', (
    tester,
  ) async {
    await tester.pumpWidget(_reveal(open: true));
    expect(_height(tester), 240);

    await tester.pumpWidget(_reveal(open: false));
    // The first tick only stamps the clock.
    await tester.pump(const Duration(milliseconds: 100));
    expect(_height(tester), 240);

    // A 100ms hitch advances the curve by one 60Hz slice, no more.
    await tester.pump(const Duration(milliseconds: 100));
    final afterHitch = _height(tester);
    final oneSlice = 240 * (1 - CcMotion.emphasized.transform(16.667 / 240));
    expect(afterHitch, closeTo(oneSlice, 0.5));

    await _frames(tester, kSpaceRevealDuration);
    expect(_height(tester), 0);
  });

  testWidgets('every 120Hz frame moves the clip', (tester) async {
    await tester.pumpWidget(_reveal(open: false));
    await tester.pumpWidget(_reveal(open: true));
    await tester.pump();

    var previous = _height(tester);
    var frames = 0;
    while (previous < 240) {
      await tester.pump(const Duration(microseconds: 8333));
      final next = _height(tester);
      expect(next, greaterThan(previous));
      previous = next;
      frames++;
    }
    // 240ms at 120Hz, give or take the rounding of the last frame.
    expect(frames, inInclusiveRange(28, 30));
  });

  testWidgets('open and close of different heights finish together', (
    tester,
  ) async {
    Widget pair({required bool firstOpen}) => testWrap(
      Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SpaceHeightReveal(
            key: const ValueKey('a'),
            open: firstOpen,
            child: const SizedBox(height: 60),
          ),
          SpaceHeightReveal(
            key: const ValueKey('b'),
            open: !firstOpen,
            child: const SizedBox(height: 200),
          ),
        ],
      ),
    );
    double h(String k) => tester.getSize(find.byKey(ValueKey(k))).height;

    await tester.pumpWidget(pair(firstOpen: true));
    await tester.pumpWidget(pair(firstOpen: false));
    await tester.pump();
    await _frames(tester, const Duration(milliseconds: 80));
    // Same progress on both: the shrinking and the growing card are one
    // gesture, not two animations of different lengths.
    expect(1 - h('a') / 60, closeTo(h('b') / 200, 0.02));

    await _frames(tester, kSpaceRevealDuration);
    expect(h('a'), 0);
    expect(h('b'), 200);
  });

  testWidgets('reversing mid-flight continues from the current height', (
    tester,
  ) async {
    await tester.pumpWidget(_reveal(open: true));
    await tester.pumpWidget(_reveal(open: false));
    await tester.pump();
    await _frames(tester, const Duration(milliseconds: 50));
    final mid = _height(tester);
    expect(mid, inExclusiveRange(0, 240));

    await tester.pumpWidget(_reveal(open: true));
    expect(_height(tester), closeTo(mid, 0.01));
    await tester.pump();
    await tester.pump(const Duration(microseconds: 8333));
    expect(_height(tester), greaterThan(mid));

    await _frames(tester, kSpaceRevealDuration);
    expect(_height(tester), 240);
  });

  testWidgets('reduced motion snaps the clip', (tester) async {
    await tester.pumpWidget(_reveal(open: true, reduced: true));
    expect(_height(tester), 240);
    await tester.pumpWidget(_reveal(open: false, reduced: true));
    expect(_height(tester), 0);
  });
}
