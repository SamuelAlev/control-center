import 'package:cc_data/cc_data.dart' show RigImageView;
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/rigs/presentation/settings/rig_image_row.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

void main() {
  testWidgets('installed image can be imported again or deleted', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);
    var imports = 0;
    var deletes = 0;

    await tester.pumpWidget(
      testWrap(
        RigImageRow(
          image: const RigImageView(
            id: 'cc-desktop-linux',
            surface: 'computer',
            role: 'interactive',
            description: 'Desktop image',
            sizeBytes: 1024,
            present: true,
            published: false,
          ),
          busy: false,
          downloading: false,
          importing: false,
          pathController: controller,
          onDownload: null,
          onStartImport: () => imports++,
          onCancelImport: () {},
          onConfirmImport: () {},
          onDelete: () => deletes++,
        ),
      ),
    );

    expect(find.text('Import'), findsOneWidget);
    expect(find.text('Delete'), findsOneWidget);

    await tester.tap(find.text('Import'));
    await tester.tap(find.text('Delete'));

    expect(imports, 1);
    expect(deletes, 1);
  });

  testWidgets('Import puts the cursor in the path field even when something '
      'else on the page had focus first', (tester) async {
    final controller = TextEditingController();
    final importing = ValueNotifier(false);
    addTearDown(controller.dispose);
    addTearDown(importing.dispose);

    await tester.pumpWidget(
      testWrap(
        Column(
          children: [
            CcButton(onPressed: () {}, child: const Text('Elsewhere')),
            ValueListenableBuilder<bool>(
              valueListenable: importing,
              builder: (context, open, _) => RigImageRow(
                image: const RigImageView(
                  id: 'cc-desktop-linux',
                  surface: 'computer',
                  role: 'interactive',
                  description: 'Desktop image',
                  sizeBytes: 1024,
                  present: true,
                  published: false,
                ),
                busy: false,
                downloading: false,
                importing: open,
                pathController: controller,
                onDownload: null,
                onStartImport: () => importing.value = true,
                onCancelImport: () => importing.value = false,
                onConfirmImport: () {},
                onDelete: null,
              ),
            ),
          ],
        ),
      ),
    );

    // An earlier focus is where the Import button hands focus as it goes.
    await tester.tap(find.text('Elsewhere'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Import'));
    await tester.pumpAndSettle();

    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<EditableText>()
          ?.controller,
      same(controller),
    );
    tester.testTextInput.enterText('/images/disk.qcow2');
    await tester.pump();
    expect(controller.text, '/images/disk.qcow2');
  });
}
