import 'package:control_center/features/memory/presentation/widgets/memory_list_panel.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_scope_widgets.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  testWidgets('a rail keeps its repo chip at the end of the row', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(
        const SizedBox(
          width: 800,
          child: MemoryGroupRail(
            label: 'conventions',
            count: 1,
            domainSlug: 'repo:acme-shop-ui/conventions',
          ),
        ),
      ),
    );

    final rail = tester.getRect(find.byType(MemoryGroupRail));
    final chip = tester.getRect(find.byType(MemoryScopeChip));
    expect(chip.right, moreOrLessEquals(rail.right - 16, epsilon: 1));
  });
}
