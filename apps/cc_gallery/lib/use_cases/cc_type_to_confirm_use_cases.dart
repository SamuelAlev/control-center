import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcTypeToConfirmPrompt] — the sentence a destructive dialog
/// asks the operator to type back, with the value set in a copyable chip.
///
/// The chip is the value, not a separate control beside the sentence: a
/// translation can place it anywhere by keeping the placeholder the labels
/// are called with. Tap the chip to copy; the glyph swaps to a check until
/// the copied state resets.

const _path = '[Components]/Navigation & Overlays';

/// The prompt as a confirm dialog shows it, against a width close to the
/// dialog's own.
@widgetbook.UseCase(name: 'Default', type: CcTypeToConfirmPrompt, path: _path)
Widget ccTypeToConfirmDefaultUseCase(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 420,
      child: CcTypeToConfirmPrompt(value: 'acme-prod'),
    ),
  );
}

/// The value sitting somewhere other than the end of the sentence, which is
/// what a translation that leads with the name has to do.
@widgetbook.UseCase(
  name: 'Value mid-sentence',
  type: CcTypeToConfirmPrompt,
  path: _path,
)
Widget ccTypeToConfirmMidSentenceUseCase(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 420,
      child: CcTypeToConfirmPrompt(
        value: 'acme-prod',
        labels: CcTypeToConfirmLabels(
          prompt: (value) => '「$value」と入力して確定します。',
          copy: 'コピー',
          copied: 'コピーしました',
        ),
      ),
    ),
  );
}

/// Interactive playground — drive the value the chip copies.
@widgetbook.UseCase(
  name: 'Playground',
  type: CcTypeToConfirmPrompt,
  path: _path,
)
Widget ccTypeToConfirmPlaygroundUseCase(BuildContext context) {
  final value = context.knobs.string(label: 'Value', initialValue: 'acme-prod');
  return Center(
    child: SizedBox(width: 420, child: CcTypeToConfirmPrompt(value: value)),
  );
}
