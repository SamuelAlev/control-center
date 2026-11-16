import 'package:cc_domain/core/domain/value_objects/mode.dart';
import 'package:control_center/features/messaging/presentation/widgets/mode_dropdown.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/composer/composer_toolbar.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/test_wrap.dart';

void main() {
  Future<void> pump(WidgetTester tester, {required double width}) async {
    await tester.pumpWidget(
      testWrap(
        Center(
          child: SizedBox(
            width: width,
            child: ComposerToolbar(
              leading: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: ModeDropdown(
                      currentMode: Mode.plan,
                      onChanged: (_) {},
                    ),
                  ),
                ],
              ),
              trailing: null,
              sending: false,
              canSend: true,
              showStop: false,
              onStop: null,
              enableFilePicker: true,
              onPickFiles: () {},
              onSubmit: () {},
              blockedMessage: null,
              composerFocused: false,
              onDictationPartial: (_, {required isFinal}) {},
              expanded: false,
              onToggleExpanded: () {},
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  Finder chevron() => find.descendant(
    of: find.byType(ModeDropdown),
    matching: find.byIcon(AppIcons.chevronDown),
  );

  RenderParagraph label(WidgetTester tester) => tester.renderObject(
    find.descendant(
      of: find.descendant(
        of: find.byType(ModeDropdown),
        matching: find.byType(Text),
      ),
      matching: find.byType(RichText),
    ),
  );

  // A narrow pane used to overflow the row: the mode picker kept its natural
  // width beside every built-in action.
  for (final width in [226.4, 180.0]) {
    testWidgets('a $width px pane shrinks the picker to its icon', (
      tester,
    ) async {
      await pump(tester, width: width);
      expect(tester.takeException(), isNull);
      expect(find.byType(ModeDropdown), findsOneWidget);
      expect(chevron(), findsNothing);
    });
  }

  testWidgets('a pane a little short of room ellipsizes the label', (
    tester,
  ) async {
    // The built-in actions take 176 px under the test font; the labelled chip
    // needs 86 px at least, and the full label more than the 94 left here.
    await pump(tester, width: 270);
    expect(tester.takeException(), isNull);
    expect(chevron(), findsOneWidget);
    expect(label(tester).didExceedMaxLines, isTrue);
  });

  testWidgets('a roomy pane keeps the label whole', (tester) async {
    await pump(tester, width: 600);
    expect(tester.takeException(), isNull);
    expect(chevron(), findsOneWidget);
    expect(label(tester).didExceedMaxLines, isFalse);
  });
}
