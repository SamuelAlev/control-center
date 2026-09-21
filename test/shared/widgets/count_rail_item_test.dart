import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/count_rail_item.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _wrap(Widget child) {
  return CcTheme(
    data: CcThemeData.light(),
    child: Directionality(
      textDirection: TextDirection.ltr,
      child: Center(child: child),
    ),
  );
}

void main() {
  testWidgets('ellipsized label keeps the caption line so descenders fit', (
    tester,
  ) async {
    const label = 'Frontify/testing-suite-playwright';
    await tester.pumpWidget(
      _wrap(
        const SizedBox(
          width: 180,
          child: CountRailItem(
            label: label,
            count: 16,
            selected: false,
            onPressed: _noop,
          ),
        ),
      ),
    );

    final text = tester.widget<Text>(find.text(label));
    // Caption is 12px on a 16px line. A height of 1 collapses that to the
    // em square; the ellipsis clip then cuts g and y.
    expect(text.style?.height, 16 / 12);
    expect(text.overflow, TextOverflow.ellipsis);

    final paragraph = tester.renderObject<RenderParagraph>(find.text(label));
    expect(paragraph.size.height, 16);
    expect(paragraph.didExceedMaxLines, isTrue);

    final row = find.ancestor(
      of: find.text(label),
      matching: find.byType(AnimatedContainer),
    );
    expect(tester.getSize(row.first).height, kCcSidebarItemExtent);
  });
}

void _noop() {}
