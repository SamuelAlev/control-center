import 'package:cc_ui/src/components/cc_text_form_field.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  group('CcTextFormField', () {
    testWidgets('seeds its value from initialValue and forwards onChanged', (
      tester,
    ) async {
      final changes = <String>[];
      final key = GlobalKey<FormState>();
      await tester.pumpWidget(
        ccTestApp(
          Form(
            key: key,
            child: CcTextFormField(
              initialValue: 'hello',
              onChanged: changes.add,
            ),
          ),
        ),
      );

      expect(find.byType(CcTextFormField), findsOneWidget);
      // Enter more text; onChanged must fire with the full value.
      await tester.enterText(find.byType(CcTextFormField), 'hello!');
      expect(changes, contains('hello!'));
    });

    testWidgets('validator error surfaces as errorText after Form.validate()', (
      tester,
    ) async {
      final key = GlobalKey<FormState>();
      await tester.pumpWidget(
        ccTestApp(
          Form(
            key: key,
            child: CcTextFormField(
              initialValue: '',
              validator: (v) => (v == null || v.isEmpty) ? 'required' : null,
            ),
          ),
        ),
      );

      expect(key.currentState!.validate(), isFalse);
      await tester.pump();
      expect(find.text('required'), findsOneWidget);
    });

    testWidgets('a passing validator renders no error text', (tester) async {
      final key = GlobalKey<FormState>();
      await tester.pumpWidget(
        ccTestApp(
          Form(
            key: key,
            child: CcTextFormField(
              initialValue: 'ok',
              validator: (v) => (v == null || v.isEmpty) ? 'bad' : null,
            ),
          ),
        ),
      );

      expect(key.currentState!.validate(), isTrue);
      await tester.pump();
      expect(find.text('bad'), findsNothing);
    });

    testWidgets('renders label and helper text when provided', (tester) async {
      await tester.pumpWidget(
        ccTestApp(
          const CcTextFormField(
            label: 'Display name',
            helperText: 'Shown on your profile',
            hintText: 'Jane Doe',
          ),
        ),
      );

      expect(find.text('Display name'), findsOneWidget);
      expect(find.text('Shown on your profile'), findsOneWidget);
      expect(find.text('Jane Doe'), findsOneWidget);
    });

    testWidgets('a controller seeds the form value from its text', (
      tester,
    ) async {
      final controller = TextEditingController(text: 'seeded');
      addTearDown(controller.dispose);
      final key = GlobalKey<FormState>();
      await tester.pumpWidget(
        ccTestApp(
          Form(
            key: key,
            child: CcTextFormField(
              controller: controller,
              validator: (v) => (v == null || v.isEmpty) ? 'empty' : null,
            ),
          ),
        ),
      );

      // The controller's text seeded the field, so the non-empty validator
      // passes without any user input.
      expect(key.currentState!.validate(), isTrue);
    });
  });
}
