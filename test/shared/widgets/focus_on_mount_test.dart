import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/shared/widgets/focus_on_mount.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../helpers/test_wrap.dart';

bool _focusInField() =>
    FocusManager.instance.primaryFocus?.context
        ?.findAncestorWidgetOfExactType<EditableText>() !=
    null;

String? _focusedButton() {
  final button = FocusManager.instance.primaryFocus?.context
      ?.findAncestorWidgetOfExactType<CcButton>();
  final label = button?.child;
  return label is Text ? label.data : null;
}

/// An "Edit" button that stays beside the editor it opens, and an unrelated
/// field outside the editor.
Widget _harness(ValueNotifier<bool> open, TextEditingController controller) {
  return ValueListenableBuilder<bool>(
    valueListenable: open,
    builder: (context, editing, _) => Column(
      children: [
        CcButton(onPressed: () => open.value = true, child: const Text('Edit')),
        const CcTextField(key: ValueKey('elsewhere')),
        if (editing)
          FocusOnMount(
            builder: (context, node) => Row(
              children: [
                Expanded(
                  child: CcTextField(controller: controller, focusNode: node),
                ),
                CcButton(
                  onPressed: () => open.value = false,
                  child: const Text('Cancel'),
                ),
              ],
            ),
          ),
      ],
    ),
  );
}

void main() {
  testWidgets('the field takes focus although the button that opened it is '
      'still focused', (tester) async {
    final open = ValueNotifier(false);
    final controller = TextEditingController();
    addTearDown(open.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(testWrap(_harness(open, controller)));

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();

    expect(_focusInField(), isTrue);
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<CcTextField>()
          ?.controller,
      same(controller),
    );
    tester.testTextInput.enterText('typed');
    await tester.pump();
    expect(controller.text, 'typed');
  });

  testWidgets('closing from inside the editor hands focus back to the '
      'button that opened it', (tester) async {
    final open = ValueNotifier(false);
    final controller = TextEditingController();
    addTearDown(open.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(testWrap(_harness(open, controller)));

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.byType(CcTextField), findsOneWidget);
    expect(_focusedButton(), 'Edit');
  });

  testWidgets('a close caused by focus moving elsewhere leaves it there', (
    tester,
  ) async {
    final open = ValueNotifier(false);
    final controller = TextEditingController();
    addTearDown(open.dispose);
    addTearDown(controller.dispose);
    await tester.pumpWidget(testWrap(_harness(open, controller)));

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('elsewhere')));
    await tester.pumpAndSettle();
    open.value = false;
    await tester.pumpAndSettle();

    expect(find.byType(CcTextField), findsOneWidget);
    expect(
      FocusManager.instance.primaryFocus?.context
          ?.findAncestorWidgetOfExactType<CcTextField>()
          ?.key,
      const ValueKey('elsewhere'),
    );
  });

  testWidgets('uses a caller-owned node and leaves it undisposed', (
    tester,
  ) async {
    final open = ValueNotifier(true);
    final node = FocusNode();
    addTearDown(open.dispose);
    addTearDown(node.dispose);
    await tester.pumpWidget(
      testWrap(
        ValueListenableBuilder<bool>(
          valueListenable: open,
          builder: (context, editing, _) => editing
              ? FocusOnMount(
                  focusNode: node,
                  builder: (context, node) => CcTextField(focusNode: node),
                )
              : const SizedBox.shrink(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(node.hasPrimaryFocus, isTrue);

    open.value = false;
    await tester.pumpAndSettle();
    // Still usable: a disposed node throws when a listener is added.
    node.addListener(() {});
  });
}
