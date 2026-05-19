import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/markdown/markdown_editor.dart';
import 'package:control_center/shared/widgets/markdown/markdown_text_field.dart';
import 'package:control_center/shared/widgets/markdown/markdown_toolbar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(Widget child) => MaterialApp(
  localizationsDelegates: AppLocalizations.localizationsDelegates,
  supportedLocales: AppLocalizations.supportedLocales,
  home: CcTheme(
    data: CcThemeData.light(),
    child: Scaffold(body: Center(child: SizedBox(width: 560, child: child))),
  ),
);

MarkdownEditor _editor(TextEditingController controller) => MarkdownEditor(
  controller: controller,
  focusNode: FocusNode(),
  fieldBuilder: (context) => MarkdownTextField(
    controller: controller,
    focusNode: FocusNode(),
    hintText: 'Leave a comment',
    minLines: 4,
    bare: true,
  ),
  previewBuilder: (context) => const Text('rendered preview'),
);

void main() {
  testWidgets('switching between Write and Preview does not move the box', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'a short draft');
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(_editor(controller)));
    // Let the size reporter deliver the write body's height.
    await tester.pumpAndSettle();

    final writeHeight = tester.getSize(find.byType(MarkdownEditor)).height;

    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    final previewHeight = tester.getSize(find.byType(MarkdownEditor)).height;

    await tester.tap(find.text('Write'));
    await tester.pumpAndSettle();
    final backToWriteHeight = tester
        .getSize(find.byType(MarkdownEditor))
        .height;

    // Header, body and footer all hold their height across the flip — the
    // regression this guards was a visible jump when the toolbar, hints and
    // field each collapsed out of the preview.
    expect(previewHeight, writeHeight);
    expect(backToWriteHeight, writeHeight);
  });

  testWidgets('preview still grows for content taller than the draft', (
    tester,
  ) async {
    final controller = TextEditingController(text: 'short');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      _host(
        MarkdownEditor(
          controller: controller,
          focusNode: FocusNode(),
          fieldBuilder: (context) => MarkdownTextField(
            controller: controller,
            focusNode: FocusNode(),
            hintText: 'hint',
            minLines: 2,
            bare: true,
          ),
          previewBuilder: (context) => const SizedBox(height: 300),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final writeHeight = tester.getSize(find.byType(MarkdownEditor)).height;

    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();
    final previewHeight = tester.getSize(find.byType(MarkdownEditor)).height;

    expect(previewHeight, greaterThan(writeHeight));
  });

  testWidgets('preview hides the toolbar and hints without dropping them', (
    tester,
  ) async {
    final controller = TextEditingController();
    addTearDown(controller.dispose);

    await tester.pumpWidget(_host(_editor(controller)));
    await tester.pumpAndSettle();
    expect(find.text('Markdown is supported'), findsOneWidget);

    await tester.tap(find.text('Preview'));
    await tester.pumpAndSettle();

    // Still in the tree (their size is reserved, see above) but inert: the
    // reader sees GitHub's quiet preview while the box holds its shape.
    for (final target in [
      find.byType(MarkdownToolbar),
      find.text('Markdown is supported'),
    ]) {
      expect(target, findsOneWidget);
      final guard = tester.widget<IgnorePointer>(
        find
            .ancestor(of: target, matching: find.byType(IgnorePointer))
            .first,
      );
      expect(guard.ignoring, isTrue);
    }
  });
}
