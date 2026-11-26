import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  Widget box(BuildContext context, Set<WidgetState> states) =>
      const SizedBox(width: 60, height: 40);

  // ccTestApp's Overlay keeps its first entry, so open/close is driven by a
  // notifier inside it and not by pumping a new tree.
  late ValueNotifier<Widget?> panel;
  setUp(() => panel = ValueNotifier<Widget?>(null));
  tearDown(() => panel.dispose());

  Widget host({required FocusNode trigger, FocusNode? after}) {
    return ccTestApp(
      ValueListenableBuilder<Widget?>(
        valueListenable: panel,
        builder: (context, content, _) => Column(
          children: [
            CcTappable(focusNode: trigger, onPressed: () {}, builder: box),
            if (content != null) CcFocusTrap(child: content),
            CcTappable(focusNode: after, onPressed: () {}, builder: box),
          ],
        ),
      ),
    );
  }

  testWidgets('takes focus on open even while the opener holds it', (
    tester,
  ) async {
    final trigger = FocusNode();
    final a = FocusNode();
    final b = FocusNode();
    addTearDown(trigger.dispose);
    addTearDown(a.dispose);
    addTearDown(b.dispose);
    await tester.pumpWidget(host(trigger: trigger));
    trigger.requestFocus();
    await tester.pump();

    panel.value = Row(
      children: [
        CcTappable(focusNode: a, onPressed: () {}, builder: box),
        CcTappable(focusNode: b, onPressed: () {}, builder: box),
      ],
    );
    await tester.pump();
    await tester.pump();
    expect(trigger.hasFocus, isFalse);

    // Tab stays inside the trap.
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(a.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(b.hasPrimaryFocus, isTrue);
    await tester.sendKeyEvent(LogicalKeyboardKey.tab);
    await tester.pump();
    expect(a.hasPrimaryFocus, isTrue);

    // Closing hands focus back to the opener.
    panel.value = null;
    await tester.pump();
    await tester.pump();
    expect(trigger.hasPrimaryFocus, isTrue);
  });

  testWidgets('a descendant autofocus wins over the scope', (tester) async {
    final trigger = FocusNode();
    final inner = FocusNode();
    addTearDown(trigger.dispose);
    addTearDown(inner.dispose);
    await tester.pumpWidget(host(trigger: trigger));
    trigger.requestFocus();
    await tester.pump();
    panel.value = CcTappable(
      focusNode: inner,
      autofocus: true,
      onPressed: () {},
      builder: box,
    );
    await tester.pump();
    await tester.pump();
    expect(inner.hasPrimaryFocus, isTrue);
  });

  testWidgets('does not pull focus back when it already moved elsewhere', (
    tester,
  ) async {
    final trigger = FocusNode();
    final inner = FocusNode();
    final outside = FocusNode();
    addTearDown(trigger.dispose);
    addTearDown(inner.dispose);
    addTearDown(outside.dispose);
    await tester.pumpWidget(host(trigger: trigger, after: outside));
    trigger.requestFocus();
    await tester.pump();
    panel.value = CcTappable(focusNode: inner, onPressed: () {}, builder: box);
    await tester.pump();
    await tester.pump();
    expect(trigger.hasFocus, isFalse);
    outside.requestFocus();
    await tester.pump();
    panel.value = null;
    await tester.pump();
    await tester.pump();
    expect(outside.hasPrimaryFocus, isTrue);
  });
}
