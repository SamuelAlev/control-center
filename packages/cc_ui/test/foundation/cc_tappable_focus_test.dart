import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  Widget box(BuildContext context, Set<WidgetState> states) =>
      const SizedBox(width: 60, height: 40);

  testWidgets('a tap moves focus to the tappable, so Tab continues from it', (
    tester,
  ) async {
    final first = FocusNode();
    final second = FocusNode();
    final third = FocusNode();
    addTearDown(first.dispose);
    addTearDown(second.dispose);
    addTearDown(third.dispose);
    await tester.pumpWidget(
      ccTestApp(
        Row(
          children: [
            CcTappable(focusNode: first, onPressed: () {}, builder: box),
            CcTappable(
              key: const ValueKey('second'),
              focusNode: second,
              onPressed: () {},
              builder: box,
            ),
            CcTappable(focusNode: third, onPressed: () {}, builder: box),
          ],
        ),
      ),
    );
    first.requestFocus();
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('second')));
    await tester.pump();
    expect(second.hasPrimaryFocus, isTrue);

    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(third.hasPrimaryFocus, isTrue);
  });

  testWidgets('a tap leaves focus in a text input', (tester) async {
    final field = FocusNode();
    final button = FocusNode();
    final text = TextEditingController();
    addTearDown(field.dispose);
    addTearDown(button.dispose);
    addTearDown(text.dispose);
    var taps = 0;
    await tester.pumpWidget(
      ccTestApp(
        Column(
          children: [
            EditableText(
              controller: text,
              focusNode: field,
              style: const TextStyle(fontSize: 14),
              cursorColor: const Color(0xFF000000),
              backgroundCursorColor: const Color(0xFF000000),
            ),
            CcTappable(focusNode: button, onPressed: () => taps++, builder: box),
          ],
        ),
      ),
    );
    field.requestFocus();
    await tester.pump();

    await tester.tap(find.byType(CcTappable));
    await tester.pump();
    expect(taps, 1);
    expect(field.hasPrimaryFocus, isTrue);
  });

  testWidgets('a tap leaves focus under a CcFocusKeeper', (tester) async {
    final surface = FocusNode();
    final button = FocusNode();
    addTearDown(surface.dispose);
    addTearDown(button.dispose);
    await tester.pumpWidget(
      ccTestApp(
        Column(
          children: [
            CcFocusKeeper(
              child: Focus(
                focusNode: surface,
                child: const SizedBox(width: 60, height: 40),
              ),
            ),
            CcTappable(focusNode: button, onPressed: () {}, builder: box),
          ],
        ),
      ),
    );
    surface.requestFocus();
    await tester.pump();

    await tester.tap(find.byType(CcTappable));
    await tester.pump();
    expect(surface.hasPrimaryFocus, isTrue);
  });

  testWidgets('requestFocusOnTap: false keeps focus where it was', (
    tester,
  ) async {
    final other = FocusNode();
    final button = FocusNode();
    addTearDown(other.dispose);
    addTearDown(button.dispose);
    await tester.pumpWidget(
      ccTestApp(
        Column(
          children: [
            Focus(
              focusNode: other,
              child: const SizedBox(width: 60, height: 40),
            ),
            CcTappable(
              focusNode: button,
              requestFocusOnTap: false,
              onPressed: () {},
              builder: box,
            ),
          ],
        ),
      ),
    );
    other.requestFocus();
    await tester.pump();
    await tester.tap(find.byType(CcTappable));
    await tester.pump();
    expect(other.hasPrimaryFocus, isTrue);
  });

  testWidgets('a busy tappable keeps focus and refuses activation', (
    tester,
  ) async {
    final node = FocusNode();
    addTearDown(node.dispose);
    var taps = 0;
    final busy = ValueNotifier(false);
    addTearDown(busy.dispose);
    await tester.pumpWidget(
      ccTestApp(
        ValueListenableBuilder<bool>(
          valueListenable: busy,
          builder: (context, isBusy, _) => CcTappable(
            focusNode: node,
            focusableWhenDisabled: true,
            onPressed: isBusy ? null : () => taps++,
            builder: box,
          ),
        ),
      ),
    );
    node.requestFocus();
    await tester.pump();

    busy.value = true;
    await tester.pump();
    await tester.pump();
    expect(node.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 0);
  });

  testWidgets('a held Enter activates once', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      ccTestApp(
        CcTappable(autofocus: true, onPressed: () => taps++, builder: box),
      ),
    );
    await tester.pump();
    await tester.sendKeyDownEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyRepeatEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
  });

  testWidgets('a caller shortcut replaces the default on the same key', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      ccTestApp(
        CcTappable(
          autofocus: true,
          onPressed: () => taps++,
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.space): DoNothingIntent(),
          },
          builder: box,
        ),
      ),
    );
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(taps, 0);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    expect(taps, 1);
  });

  testWidgets('state flags land on the tappable\'s own semantics node', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      ccTestApp(
        CcTappable(
          onPressed: () {},
          semanticLabel: 'Inbox',
          semanticSelected: true,
          semanticExpanded: false,
          builder: box,
        ),
      ),
    );
    expect(
      tester.getSemantics(find.byType(CcTappable)),
      matchesSemantics(
        label: 'Inbox',
        isButton: true,
        isEnabled: true,
        hasEnabledState: true,
        isFocusable: true,
        hasSelectedState: true,
        isSelected: true,
        hasExpandedState: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    handle.dispose();
  });
}
