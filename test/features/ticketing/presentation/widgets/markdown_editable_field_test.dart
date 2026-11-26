import 'package:control_center/features/ticketing/presentation/widgets/markdown_editable_field.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/markdown/markdown_editor.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../helpers/test_wrap.dart';

void main() {
  testWidgets('a written description can be edited from the keyboard', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    await tester.pumpWidget(
      testWrap(
        MarkdownEditableField(
          text: 'Ship the thing',
          hint: 'Add a description',
          onSave: (_) {},
        ),
      ),
    );
    await tester.pump();

    double pencilOpacity() => tester
        .widget<Opacity>(
          find
              .ancestor(
                of: find.byIcon(AppIcons.pencil),
                matching: find.byType(Opacity),
              )
              .first,
        )
        .opacity;

    // Mounted at rest, only faded, and named for a screen reader.
    expect(find.byIcon(AppIcons.pencil), findsOneWidget);
    expect(pencilOpacity(), 0);
    expect(find.bySemanticsLabel('Edit description'), findsWidgets);

    // Tab reaches it (the body may hold a selection stop first) and shows it.
    final pencilFocus = Focus.of(tester.element(find.byIcon(AppIcons.pencil)));
    for (var i = 0; i < 4 && !pencilFocus.hasPrimaryFocus; i++) {
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
    }
    expect(pencilFocus.hasPrimaryFocus, isTrue);
    expect(pencilOpacity(), 1);

    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    await tester.pump();
    expect(find.byType(MarkdownEditor), findsOneWidget);
    semantics.dispose();
  });
}
