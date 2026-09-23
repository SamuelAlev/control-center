import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_sidebar_filter_controls.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  testWidgets('clear is a suffix icon button while the field has text', (
    tester,
  ) async {
    final controller = TextEditingController(text: '(deps)');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      testWrap(
        SizedBox(
          width: 320,
          child: CcTextField(
            controller: controller,
            size: CcTextFieldSize.sm,
            suffix: PrFieldClearButton(
              controller: controller,
              onCleared: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PrSuffixIconButton), findsOneWidget);
    expect(find.byIcon(AppIcons.x), findsOneWidget);
    // 20px target plus the 2px margin shared with the suffix toggles.
    expect(tester.getSize(find.byType(PrSuffixIconButton)), const Size(24, 24));
  });

  testWidgets('clear empties the field and hides itself', (tester) async {
    final controller = TextEditingController(text: '(deps)');
    addTearDown(controller.dispose);
    var cleared = 0;

    await tester.pumpWidget(
      testWrap(
        SizedBox(
          width: 320,
          child: CcTextField(
            controller: controller,
            size: CcTextFieldSize.sm,
            suffix: PrFieldClearButton(
              controller: controller,
              onCleared: () => cleared++,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.byType(PrSuffixIconButton));
    await tester.pump();

    expect(controller.text, isEmpty);
    expect(cleared, 1);
    expect(find.byType(PrSuffixIconButton), findsNothing);
  });

  testWidgets('clear is absent while the field is empty', (tester) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      testWrap(
        SizedBox(
          width: 320,
          child: CcTextField(
            controller: controller,
            size: CcTextFieldSize.sm,
            suffix: PrFieldClearButton(
              controller: controller,
              onCleared: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(PrSuffixIconButton), findsNothing);
    expect(find.byIcon(AppIcons.x), findsNothing);
  });
}
