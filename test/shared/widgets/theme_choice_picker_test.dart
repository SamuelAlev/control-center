import 'package:control_center/core/theme/theme_choice.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/theme_choice_picker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

import '../../helpers/test_wrap.dart';

void main() {
  testWidgets('offers every choice and reports the one tapped', (tester) async {
    final chosen = <ThemeChoice>[];
    await tester.pumpWidget(
      testWrap(
        ThemeChoicePicker(theme: ThemeChoice.system, onChanged: chosen.add),
      ),
    );

    await tester.tap(find.text('Dark'));
    await tester.tap(find.text('Light'));
    await tester.tap(find.text('System'));
    expect(chosen, [ThemeChoice.dark, ThemeChoice.light, ThemeChoice.system]);
  });

  testWidgets('marks the selection with a glyph, not color alone', (
    tester,
  ) async {
    await tester.pumpWidget(
      testWrap(ThemeChoicePicker(theme: ThemeChoice.dark, onChanged: (_) {})),
    );

    expect(find.byIcon(AppIcons.check), findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(of: find.text('Dark'), matching: find.byType(Row)),
        matching: find.byIcon(AppIcons.check),
      ),
      findsOneWidget,
    );
  });

  testWidgets('every tile fits a phone-width column', (tester) async {
    await tester.binding.setSurfaceSize(const Size(320, 400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      testWrap(ThemeChoicePicker(theme: ThemeChoice.light, onChanged: (_) {})),
    );
    expect(tester.takeException(), isNull);
  });
}
