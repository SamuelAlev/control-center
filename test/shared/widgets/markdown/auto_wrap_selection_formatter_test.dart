import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/l10n/localizations_loader.dart';
import 'package:control_center/shared/widgets/composer/composer.dart';
import 'package:control_center/shared/widgets/markdown/auto_wrap_selection_formatter.dart';
import 'package:control_center/shared/widgets/markdown/markdown_text_field.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';

TextEditingValue _simulateType(TextEditingValue oldValue, String char) {
  final start = oldValue.selection.start;
  final end = oldValue.selection.end;
  final nextText =
      oldValue.text.substring(0, start) + char + oldValue.text.substring(end);
  return TextEditingValue(
    text: nextText,
    selection: TextSelection.collapsed(offset: start + char.length),
  );
}

void main() {
  const formatter = AutoWrapSelectionFormatter();

  group('AutoWrapSelectionFormatter', () {
    final cases = <String, (String left, String right)>{
      '`': ('`', '`'),
      '(': ('(', ')'),
      '[': ('[', ']'),
      '{': ('{', '}'),
      '*': ('*', '*'),
      '_': ('_', '_'),
      '"': ('"', '"'),
      "'": ("'", "'"),
      '~': ('~', '~'),
    };

    for (final entry in cases.entries) {
      test('wraps selection when typing "${entry.key}"', () {
        const oldValue = TextEditingValue(
          text: 'use brandCheckerGuidelineStatus to',
          selection: TextSelection(baseOffset: 4, extentOffset: 31),
        );
        final typed = _simulateType(oldValue, entry.key);
        final result = formatter.formatEditUpdate(oldValue, typed);

        final (left, right) = entry.value;
        expect(
          result.text,
          'use ${left}brandCheckerGuidelineStatus$right to',
        );
        expect(
          result.selection,
          const TextSelection(baseOffset: 5, extentOffset: 32),
        );
      });
    }

    test('repeated presses nest delimiters while keeping inner selection', () {
      const initial = TextEditingValue(
        text: 'hello world',
        selection: TextSelection(baseOffset: 0, extentOffset: 5),
      );
      final once = formatter.formatEditUpdate(
        initial,
        _simulateType(initial, '*'),
      );
      expect(once.text, '*hello* world');
      expect(once.selection, const TextSelection(baseOffset: 1, extentOffset: 6));

      final twice = formatter.formatEditUpdate(
        once,
        _simulateType(once, '*'),
      );
      expect(twice.text, '**hello** world');
      expect(
        twice.selection,
        const TextSelection(baseOffset: 2, extentOffset: 7),
      );
    });

    test('preserves reversed selection direction', () {
      const oldValue = TextEditingValue(
        text: 'hello world',
        selection: TextSelection(baseOffset: 5, extentOffset: 0),
      );
      final result = formatter.formatEditUpdate(
        oldValue,
        _simulateType(oldValue, '('),
      );
      expect(result.text, '(hello) world');
      expect(
        result.selection,
        const TextSelection(baseOffset: 6, extentOffset: 1),
      );
    });

    test('replaces selection for non-wrap characters', () {
      const oldValue = TextEditingValue(
        text: 'hello world',
        selection: TextSelection(baseOffset: 0, extentOffset: 5),
      );
      final typed = _simulateType(oldValue, 'x');
      final result = formatter.formatEditUpdate(oldValue, typed);
      expect(result, typed);
    });

    test('does not wrap when selection is collapsed', () {
      const oldValue = TextEditingValue(
        text: 'hello',
        selection: TextSelection.collapsed(offset: 5),
      );
      final typed = _simulateType(oldValue, '`');
      final result = formatter.formatEditUpdate(oldValue, typed);
      expect(result, typed);
    });

    test('does not wrap multi-character pastes', () {
      const oldValue = TextEditingValue(
        text: 'hello world',
        selection: TextSelection(baseOffset: 0, extentOffset: 5),
      );
      final pasted = _simulateType(oldValue, '``');
      final result = formatter.formatEditUpdate(oldValue, pasted);
      expect(result, pasted);
    });

    test('leaves active IME composition untouched', () {
      const oldValue = TextEditingValue(
        text: 'hello world',
        selection: TextSelection(baseOffset: 0, extentOffset: 5),
      );
      const composing = TextEditingValue(
        text: '` world',
        selection: TextSelection.collapsed(offset: 1),
        composing: TextRange(start: 0, end: 1),
      );
      final result = formatter.formatEditUpdate(oldValue, composing);
      expect(result, composing);
    });
  });

  group('editor integration', () {
    Widget host(Widget child) => ProviderScope(
      child: MaterialApp(
        localizationsDelegates: appLocalizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: CcTheme(
          data: CcThemeData.light(),
          child: Scaffold(body: Center(child: SizedBox(width: 560, child: child))),
        ),
      ),
    );

    testWidgets('MarkdownTextField auto-wraps selected text', (tester) async {
      final controller = TextEditingController(text: 'use foo bar');
      final focusNode = FocusNode();
      addTearDown(controller.dispose);
      addTearDown(focusNode.dispose);

      await tester.pumpWidget(
        host(
          MarkdownTextField(
            controller: controller,
            focusNode: focusNode,
            hintText: 'Comment',
          ),
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pump();
      controller.selection = const TextSelection(baseOffset: 4, extentOffset: 7);
      await tester.pump();

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'use ` bar',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      await tester.pump();

      expect(controller.text, 'use `foo` bar');
      expect(
        controller.selection,
        const TextSelection(baseOffset: 5, extentOffset: 8),
      );
    });

    testWidgets('Composer auto-wraps selected text', (tester) async {
      final controller = TextEditingController(
        text: 'use brandCheckerGuidelineStatus to',
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        host(
          Composer(
            sources: const [],
            controller: controller,
            onSubmit: (_) async {},
          ),
        ),
      );

      await tester.tap(find.byType(EditableText));
      await tester.pump();
      controller.selection = const TextSelection(
        baseOffset: 4,
        extentOffset: 31,
      );
      await tester.pump();

      tester.testTextInput.updateEditingValue(
        const TextEditingValue(
          text: 'use ` to',
          selection: TextSelection.collapsed(offset: 5),
        ),
      );
      await tester.pump();

      expect(controller.text, 'use `brandCheckerGuidelineStatus` to');
      expect(
        controller.selection,
        const TextSelection(baseOffset: 5, extentOffset: 32),
      );
    });
  });
}
