import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/widgets/space_row.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  const inset = EdgeInsets.symmetric(vertical: AppSpacing.sm);

  Future<void> pump(
    WidgetTester tester, {
    String? subtitle,
  }) async {
    await tester.pumpWidget(
      testWrap(
        Align(
          alignment: Alignment.topCenter,
          child: SpaceRow(
            leading: const SpaceStatusMark(),
            label: 'test',
            subtitle: subtitle,
            selected: false,
            status: SpaceStatus.idle,
            unread: false,
            leadingHandlesRunning: true,
            cardInset: inset,
            onPress: () {},
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('a space without a branch centers the mark with the title', (
    tester,
  ) async {
    await pump(tester);

    final row = tester.getRect(find.byType(SpaceRow));
    expect(row.height, kCcSidebarItemExtent + inset.vertical);

    final mark = tester.getCenter(find.byType(SpaceStatusMark));
    final title = tester.getCenter(find.text('test'));
    expect(mark.dy, closeTo(title.dy, 0.5));
    expect(mark.dy, closeTo(row.center.dy, 0.5));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });

  testWidgets('a branch keeps the mark centered on the two-line block', (
    tester,
  ) async {
    await pump(tester, subtitle: 'feat/checks');

    final row = tester.getRect(find.byType(SpaceRow));
    expect(row.height, greaterThan(kCcSidebarItemExtent + inset.vertical));

    final mark = tester.getCenter(find.byType(SpaceStatusMark)).dy;
    final title = tester.getCenter(find.text('test')).dy;
    final branch = tester.getCenter(find.text('feat/checks')).dy;
    expect(mark, greaterThan(title));
    expect(mark, lessThan(branch));
    expect(mark, closeTo((title + branch) / 2, 1));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
