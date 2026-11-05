import 'dart:async';
import 'dart:convert';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/attachment_upload_controller.dart';
import 'package:control_center/shared/widgets/composer/composer.dart';
import 'package:control_center/shared/widgets/composer/composer_models.dart';
import 'package:control_center/shared/widgets/composer/composer_text_controller.dart';
import 'package:control_center/shared/widgets/composer/long_paste.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

Finder get _send => find.ancestor(
  of: find.byIcon(AppIcons.arrowUp),
  matching: find.byType(CcButton),
);

double _fieldHeight(WidgetTester tester) => tester
    .state<EditableTextState>(find.byType(EditableText))
    .renderEditable
    .size
    .height;

String _lines(int count) => List.generate(count, (i) => 'line $i').join('\n');

void main() {
  late ComposerTextController controller;

  setUp(() => controller = ComposerTextController());
  tearDown(() => controller.dispose());

  Future<void> pump(
    WidgetTester tester, {
    double? maxInputHeight,
    bool expanded = false,
    ValueChanged<bool>? onExpandedChanged,
    double? hostHeight,
    bool unboundedHost = false,
    UploadComposerAttachment? upload,
  }) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    addTearDown(() => debugDefaultTargetPlatformOverride = null);
    final composer = Composer(
      controller: controller,
      autofocus: true,
      sources: const [],
      maxInputHeight: maxInputHeight,
      expanded: expanded,
      onExpandedChanged: onExpandedChanged,
      attachmentScope: upload == null ? null : 'scope',
      attachmentUpload: upload,
      attachmentDiscard: upload == null ? null : (_) async {},
      onSubmit: (_) async {},
    );
    await tester.pumpWidget(
      testWrap(
        Align(
          alignment: Alignment.bottomCenter,
          child: unboundedHost
              // A column hands its children an unbounded height.
              ? Column(mainAxisSize: MainAxisSize.min, children: [composer])
              : hostHeight == null
              ? composer
              : SizedBox(height: hostHeight, child: composer),
        ),
      ),
    );
    await tester.pump();
  }

  group('height', () {
    testWidgets('starts at one line and grows past six', (tester) async {
      await pump(tester, maxInputHeight: 400);
      final oneLine = _fieldHeight(tester);

      controller.text = _lines(10);
      await tester.pump();

      // Ten lines are on screen at once: the old six-line cap is gone.
      expect(_fieldHeight(tester), greaterThan(oneLine * 9));
      expect(_fieldHeight(tester), lessThan(400));
    });

    testWidgets('stops at the cap and scrolls past it', (tester) async {
      await pump(tester, maxInputHeight: 200);
      controller.text = _lines(60);
      await tester.pump();
      // The cap bounds the text area, top inset included.
      expect(_fieldHeight(tester), moreOrLessEquals(198, epsilon: 0.5));
    });
  });

  testWidgets('send rests disabled until there is something to send', (
    tester,
  ) async {
    await pump(tester);
    expect(tester.widget<CcButton>(_send).onPressed, isNull);

    controller.text = '   ';
    await tester.pump();
    expect(tester.widget<CcButton>(_send).onPressed, isNull);

    controller.text = 'ship it';
    await tester.pump();
    expect(tester.widget<CcButton>(_send).onPressed, isNotNull);
  });

  group('expand', () {
    testWidgets('the toggle appears once the draft runs long', (tester) async {
      final requests = <bool>[];
      await pump(tester, onExpandedChanged: requests.add);
      controller.text = 'short';
      await tester.pump();
      expect(find.byIcon(AppIcons.maximize2), findsNothing);

      controller.text = _lines(4);
      await tester.pump();
      await tester.tap(find.byIcon(AppIcons.maximize2));
      await tester.pump();
      expect(requests, [true]);
    });

    testWidgets('no host support, no toggle', (tester) async {
      await pump(tester);
      controller.text = _lines(8);
      await tester.pump();
      expect(find.byIcon(AppIcons.maximize2), findsNothing);
    });

    testWidgets('⌘⇧E asks to expand; Escape asks to collapse', (tester) async {
      final requests = <bool>[];
      await pump(tester, onExpandedChanged: requests.add);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyE);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
      expect(requests, [true]);

      await pump(
        tester,
        expanded: true,
        hostHeight: 500,
        onExpandedChanged: requests.add,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      expect(requests, [true, false]);
    });

    testWidgets('fills its host and keeps the same field across the toggle', (
      tester,
    ) async {
      await pump(tester, hostHeight: 500, onExpandedChanged: (_) {});
      final editable = tester.state<EditableTextState>(
        find.byType(EditableText),
      );
      final collapsed = _fieldHeight(tester);

      await pump(
        tester,
        hostHeight: 500,
        expanded: true,
        onExpandedChanged: (_) {},
      );

      expect(_fieldHeight(tester), greaterThan(collapsed * 10));
      expect(
        tester.state<EditableTextState>(find.byType(EditableText)),
        same(editable),
      );
    });

    testWidgets('a host without a bounded height keeps it collapsed', (
      tester,
    ) async {
      await pump(
        tester,
        expanded: true,
        unboundedHost: true,
        onExpandedChanged: (_) {},
      );
      expect(tester.takeException(), isNull);
      expect(_fieldHeight(tester), lessThan(40));
    });
  });

  group('long paste', () {
    testWidgets('lands as a text attachment referenced at the caret', (
      tester,
    ) async {
      final uploads = <ComposerAttachment>[];
      await pump(
        tester,
        upload: (attachment) {
          uploads.add(attachment);
          return Completer<UploadedAttachment>().future;
        },
      );
      final pasted = 'trace\n' * (kLongPasteMinLines + 1);
      await tester.enterText(find.byType(EditableText), pasted);
      await tester.pump();

      expect(controller.text, contains('@[file:$kLongPasteFileName]'));
      expect(controller.text, isNot(contains('trace')));
      expect(uploads, hasLength(1));
      expect(uploads.single.mimeType, 'text/plain');
      expect(utf8.decode(uploads.single.bytes!), pasted);
    });

    testWidgets('stays inline in a composer that cannot upload', (
      tester,
    ) async {
      await pump(tester);
      final pasted = 'x' * kLongPasteMinChars;
      await tester.enterText(find.byType(EditableText), pasted);
      await tester.pump();
      expect(controller.text, pasted);
    });
  });
}
