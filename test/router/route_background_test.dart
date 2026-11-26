import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/router/route_background.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late FocusNode field;
  late FocusNode button;
  late FocusNode surface;
  late TextEditingController text;

  setUp(() {
    field = FocusNode(debugLabel: 'field');
    button = FocusNode(debugLabel: 'button');
    surface = FocusNode(debugLabel: 'surface');
    text = TextEditingController();
  });

  tearDown(() {
    field.dispose();
    button.dispose();
    surface.dispose();
    text.dispose();
  });

  /// A page with a text field, a button and a keeper surface (with padding
  /// of its own around the focusable part) over an empty background.
  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      WidgetsApp(
        color: const Color(0xFF000000),
        builder: (context, _) => CcTheme(
          data: CcThemeData.light(),
          child: RouteBackground(
            child: Align(
              alignment: AlignmentDirectional.topStart,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 200,
                    child: EditableText(
                      controller: text,
                      focusNode: field,
                      style: const TextStyle(fontSize: 14),
                      cursorColor: const Color(0xFF000000),
                      backgroundCursorColor: const Color(0xFF888888),
                    ),
                  ),
                  CcTappable(
                    focusNode: button,
                    onPressed: () {},
                    builder: (_, _) => const SizedBox(width: 40, height: 40),
                  ),
                  CcFocusKeeper(
                    child: Padding(
                      key: const ValueKey('keeper'),
                      padding: const EdgeInsets.all(20),
                      child: Focus(
                        focusNode: surface,
                        child: const SizedBox(width: 100, height: 100),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// A point on the empty background, clear of every control.
  const background = Offset(600, 500);

  testWidgets('a background click ends editing in a text field', (
    tester,
  ) async {
    await pump(tester);
    field.requestFocus();
    await tester.pump();

    await tester.tapAt(background);
    await tester.pump();
    expect(field.hasFocus, isFalse);
  });

  testWidgets('a background click leaves a focused control focused', (
    tester,
  ) async {
    await pump(tester);
    button.requestFocus();
    await tester.pump();

    await tester.tapAt(background);
    await tester.pump();
    expect(button.hasPrimaryFocus, isTrue);
  });

  testWidgets('a keeper surface keeps focus on a click on its own padding, '
      'and gives it up on a click outside it', (tester) async {
    await pump(tester);
    surface.requestFocus();
    await tester.pump();

    final keeper = tester.getRect(find.byKey(const ValueKey('keeper')));
    await tester.tapAt(keeper.topLeft + const Offset(5, 5));
    await tester.pump();
    expect(surface.hasPrimaryFocus, isTrue);

    await tester.tapAt(background);
    await tester.pump();
    expect(surface.hasFocus, isFalse);
  });
}
