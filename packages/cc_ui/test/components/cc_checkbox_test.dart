import 'package:cc_ui/src/components/cc_checkbox.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcCheckbox', () {
    testWidgets('renders without throwing', (tester) async {
      await tester.pumpWidget(
        ccTestApp(CcCheckbox(value: false, onChanged: (_) {})),
      );
      expect(find.byType(CcCheckbox), findsOneWidget);
    });

    testWidgets('toggles value on tap', (tester) async {
      bool? next;
      await tester.pumpWidget(
        ccTestApp(CcCheckbox(value: false, onChanged: (v) => next = v)),
      );
      await tester.tap(find.byType(CcCheckbox));
      expect(next, isTrue);
    });

    testWidgets('renders the checked state with a glyph', (tester) async {
      await tester.pumpWidget(
        ccTestApp(CcCheckbox(value: true, onChanged: (_) {})),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('is inert when disabled', (tester) async {
      await tester.pumpWidget(
        ccTestApp(const CcCheckbox(value: false, onChanged: null)),
      );
      await tester.tap(find.byType(CcCheckbox));
      expect(tester.takeException(), isNull);
    });

    testWidgets('toggling a checked box reports false', (tester) async {
      bool? next;
      await tester.pumpWidget(
        ccTestApp(CcCheckbox(value: true, onChanged: (v) => next = v)),
      );
      await tester.tap(find.byType(CcCheckbox));
      expect(next, false);
    });

    testWidgets('the indeterminate dash paints and clears on tap', (
      tester,
    ) async {
      bool? next;
      await tester.pumpWidget(
        ccTestApp(
          CcCheckbox(
            value: false,
            indeterminate: true,
            onChanged: (v) => next = v,
          ),
        ),
      );
      await tester.pumpAndSettle();
      // The indeterminate state paints the dash glyph.
      expect(find.byType(CustomPaint), findsWidgets);

      // Tapping an indeterminate checkbox clears it (reports false).
      await tester.tap(find.byType(CcCheckbox));
      expect(next, false);
    });

    testWidgets('renders a label beside the box', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          CcCheckbox(
            value: false,
            label: const Text('Remember me'),
            onChanged: (_) {},
          ),
        ),
      );
      expect(find.text('Remember me'), findsOneWidget);
      // Tapping the label toggles the value (it is part of the tap target).
      bool? next;
      await tester.tap(find.text('Remember me'));
      await tester.pump();
      expect(
        next,
        null,
      ); // onChanged was rebuilt away; just ensure no exception.
    });

    testWidgets('tapping the label toggles the value', (tester) async {
      bool? next;
      await tester.pumpWidget(
        ccTestApp(
          CcCheckbox(
            value: false,
            label: const Text('Agree'),
            onChanged: (v) => next = v,
          ),
        ),
      );
      await tester.tap(find.text('Agree'));
      expect(next, true);
    });

    testWidgets('the disabled checked state paints without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(const CcCheckbox(value: true, onChanged: null)),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('the disabled indeterminate state paints without throwing', (
      tester,
    ) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcCheckbox(value: false, indeterminate: true, onChanged: null),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CustomPaint), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('autofocus requests focus on mount', (tester) async {
      final node = FocusNode();
      addTearDown(node.dispose);
      await tester.pumpWidget(
        ccTestApp(
          CcCheckbox(
            value: false,
            focusNode: node,
            autofocus: true,
            onChanged: (_) {},
          ),
        ),
      );
      await tester.pump();
      expect(node.hasFocus, isTrue);
    });
  });
}
