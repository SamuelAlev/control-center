import 'package:cc_domain/features/pr_review/domain/entities/pr_file.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/source_control/scm_view.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

Widget _wrap(Widget child) {
  return MaterialApp(
    home: CcTheme(
      data: CcThemeData.light(),
      child: Scaffold(body: child),
    ),
  );
}

PrFile _file(String filename) => PrFile(
  filename: filename,
  status: PrFileStatus.modified,
  additions: 1,
  deletions: 1,
  patch: '',
);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // FocusModality is a process-wide singleton whose key handler only survives
  // the test that first registers it (the binding clears keyboard handlers
  // between tests), so the keyboard case runs first.
  group('ScmFileRow keyboard', () {
    testWidgets('Enter opens the row, and focus reveals its actions', (
      tester,
    ) async {
      var opened = 0;
      var staged = 0;
      await tester.pumpWidget(
        _wrap(
          SizedBox(
            width: 320,
            child: ScmFileRow(
              file: _file('lib/src/main.dart'),
              selected: false,
              onTap: () => opened++,
              actions: [
                (
                  icon: AppIcons.plus,
                  tooltip: 'Stage changes',
                  onPressed: () => staged++,
                ),
              ],
            ),
          ),
        ),
      );
      expect(find.byType(ScmIconAction), findsNothing);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(find.byType(ScmIconAction), findsOneWidget);

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(opened, 1);

      // Tab moves into the revealed action, which stays shown while focused.
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(find.byType(ScmIconAction), findsOneWidget);
      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      await tester.pump();
      expect(staged, 1);
      expect(opened, 1);
    });
  });

  group('ScmFileRow hover', () {
    for (final filename in ['package.json', 'lib/src/main.dart']) {
      testWidgets('revealing actions keeps the height of $filename', (
        tester,
      ) async {
        final actions = <ScmAction>[
          (icon: AppIcons.fileCode, tooltip: 'Open file', onPressed: () {}),
          (
            icon: AppIcons.rotateCcw,
            tooltip: 'Discard changes',
            onPressed: () {},
          ),
          (icon: AppIcons.plus, tooltip: 'Stage changes', onPressed: () {}),
        ];
        await tester.pumpWidget(
          _wrap(
            SizedBox(
              width: 320,
              child: Column(
                children: [
                  ScmFileRow(
                    key: const ValueKey('row'),
                    file: _file(filename),
                    selected: false,
                    onTap: () {},
                    actions: actions,
                  ),
                  const SizedBox(key: ValueKey('below'), height: 10),
                ],
              ),
            ),
          ),
        );
        final row = find.byKey(const ValueKey('row'));
        final below = find.byKey(const ValueKey('below'));
        final restingHeight = tester.getSize(row).height;
        final restingBelow = tester.getTopLeft(below).dy;
        expect(find.byType(ScmIconAction), findsNothing);

        final gesture = await tester.createGesture(
          kind: PointerDeviceKind.mouse,
        );
        await gesture.addPointer(location: Offset.zero);
        addTearDown(gesture.removePointer);
        await gesture.moveTo(tester.getTopLeft(row) + const Offset(8, 8));
        await tester.pump();

        expect(find.byType(ScmIconAction), findsNWidgets(actions.length));
        expect(tester.getSize(row).height, restingHeight);
        expect(tester.getTopLeft(below).dy, restingBelow);

        await gesture.moveTo(Offset.zero);
        await tester.pumpAndSettle();
      });
    }
  });
}
