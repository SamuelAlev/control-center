import 'package:cc_ui/src/foundation/cc_panel_search_field.dart';
import 'package:cc_ui/src/foundation/cc_submit_keeps_focus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('ccSubmitKeepsFocus', () {
    final controller = TextEditingController();
    tearDownAll(controller.dispose);

    test('desktop keeps focus unless the action moves it', () {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      try {
        expect(ccSubmitKeepsFocus(controller, null), isNotNull);
        expect(ccSubmitKeepsFocus(controller, TextInputAction.done), isNotNull);
        expect(ccSubmitKeepsFocus(controller, TextInputAction.next), isNull);
        expect(
          ccSubmitKeepsFocus(controller, TextInputAction.previous),
          isNull,
        );
      } finally {
        debugDefaultTargetPlatformOverride = null;
      }
    });

    test('touch platforms keep their own behaviour', () {
      for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
        debugDefaultTargetPlatformOverride = platform;
        try {
          expect(ccSubmitKeepsFocus(controller, null), isNull);
        } finally {
          debugDefaultTargetPlatformOverride = null;
        }
      }
    });
  });

  testWidgets('Enter in a panel search field keeps the caret on desktop', (
    tester,
  ) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.windows;
    try {
      final controller = TextEditingController();
      final focus = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        ccTestApp(
          CcPanelSearchField(
            controller: controller,
            focusNode: focus,
            autofocus: true,
          ),
        ),
      );
      await tester.pump();
      await tester.enterText(find.byType(EditableText), 'q');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump();
      expect(focus.hasPrimaryFocus, isTrue);
    } finally {
      debugDefaultTargetPlatformOverride = null;
    }
  });
}
