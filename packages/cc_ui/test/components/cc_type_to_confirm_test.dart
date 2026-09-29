import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_type_to_confirm.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../cc_test_app.dart';

void main() {
  /// The sentence as the paragraph holds it, the chip standing in as U+FFFC.
  String sentence(WidgetTester tester) => tester
      .widget<RichText>(
        find.byWidgetPredicate(
          (w) => w is RichText && w.text.toPlainText().contains('\uFFFC'),
        ),
      )
      .text
      .toPlainText();

  Future<void> pumpPrompt(
    WidgetTester tester, {
    CcTypeToConfirmLabels labels = const CcTypeToConfirmLabels(),
    TextDirection textDirection = TextDirection.ltr,
  }) => tester.pumpWidget(
    ccTestApp(
      Center(
        child: CcTypeToConfirmPrompt(value: 'acme-prod', labels: labels),
      ),
      textDirection: textDirection,
    ),
  );

  testWidgets('sets the value inside the sentence as a chip', (tester) async {
    await pumpPrompt(tester);

    expect(sentence(tester), 'Type \uFFFC to confirm.');
    expect(find.text('acme-prod'), findsOneWidget);
    expect(find.byIcon(CcIcons.copy), findsOneWidget);
  });

  testWidgets('a translation places the value where its sentence needs it', (
    tester,
  ) async {
    await pumpPrompt(
      tester,
      labels: CcTypeToConfirmLabels(prompt: (v) => '確認するには$vと入力してください。'),
    );

    expect(sentence(tester), '確認するには\uFFFCと入力してください。');
    expect(find.text('acme-prod'), findsOneWidget);
  });

  testWidgets(
    'a translation that drops the placeholder still shows the value',
    (tester) async {
      await pumpPrompt(
        tester,
        labels: CcTypeToConfirmLabels(prompt: (_) => 'Type the name.'),
      );

      expect(sentence(tester), 'Type the name. \uFFFC');
      expect(find.text('acme-prod'), findsOneWidget);
    },
  );

  testWidgets('activating the chip copies the value and confirms it', (
    tester,
  ) async {
    String? copied;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'Clipboard.setData') {
          copied = (call.arguments as Map)['text'] as String?;
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    final semantics = tester.ensureSemantics();

    await pumpPrompt(
      tester,
      labels: const CcTypeToConfirmLabels(copy: 'Kopieren', copied: 'Kopiert'),
    );
    expect(find.bySemanticsLabel(RegExp('^Kopieren')), findsOneWidget);

    await tester.tap(find.text('acme-prod'));
    await tester.pumpAndSettle();

    expect(copied, 'acme-prod');
    expect(find.byIcon(CcIcons.check), findsOneWidget);
    expect(find.bySemanticsLabel(RegExp('^Kopiert')), findsOneWidget);

    // The check is a confirmation, not a new resting state.
    await tester.pump(const Duration(seconds: 2));
    await tester.pumpAndSettle();
    expect(find.byIcon(CcIcons.copy), findsOneWidget);
    expect(find.byIcon(CcIcons.check), findsNothing);
    semantics.dispose();
  });

  testWidgets('the copy glyph trails the value in RTL', (tester) async {
    await pumpPrompt(tester, textDirection: TextDirection.rtl);

    final value = tester.getRect(find.text('acme-prod'));
    final glyph = tester.getRect(find.byIcon(CcIcons.copy));
    expect(glyph.right, lessThanOrEqualTo(value.left));
  });
}
