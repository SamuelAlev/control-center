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

void main() {
  testWidgets('a late frame does not drop a whole row of the close', (
    tester,
  ) async {
    await tester.pumpWidget(_reveal(open: true));
    expect(_height(tester), 240);

    await tester.pumpWidget(_reveal(open: false));
    // The frame that starts the close, including a hitch, does not spend
    // that stall on the clip.
    await tester.pump(const Duration(milliseconds: 100));
    expect(_height(tester), 240);

    await tester.pump(const Duration(milliseconds: 16));
    expect(_height(tester), closeTo(224, 0.5));

    await tester.pump(const Duration(milliseconds: 100));
    expect(_height(tester), closeTo(208, 0.5));

    for (var i = 0; i < 20; i++) {
      await tester.pump(const Duration(milliseconds: 16));
    }
    expect(_height(tester), 0);
  });

  testWidgets('opening advances by the same pixel slice', (tester) async {
    await tester.pumpWidget(_reveal(open: false));
    expect(_height(tester), 0);

    await tester.pumpWidget(_reveal(open: true));
    await tester.pump(const Duration(milliseconds: 100));
    expect(_height(tester), 0);

    await tester.pump(const Duration(milliseconds: 16));
    expect(_height(tester), closeTo(16, 0.5));
  });

  testWidgets('reduced motion snaps the clip', (tester) async {
    await tester.pumpWidget(_reveal(open: true, reduced: true));
    expect(_height(tester), 240);
    await tester.pumpWidget(_reveal(open: false, reduced: true));
    expect(_height(tester), 0);
  });
}
