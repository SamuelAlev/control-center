import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcKbd] — the design system's keyboard key-cap chip.
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Containers → CcKbd` (from [CcKbd] as the
/// `type` and the bracketed `path` segments). The builders return the component
/// directly — the gallery's theme addon supplies the [CcTheme] + canvas.

const _path = '[Components]/Containers';

/// A single key-cap and a multi-key shortcut rendered side by side, the way
/// callers stitch them together for command-palette hints.
@widgetbook.UseCase(name: 'Default', type: CcKbd, path: _path)
Widget ccKbdDefaultUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 6,
      runSpacing: 6,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CcKbd(keyLabel: '⌘'),
        CcKbd(keyLabel: 'K'),
        SizedBox(width: 16),
        CcKbd(keyLabel: 'Esc'),
        CcKbd(keyLabel: 'Ctrl+S'),
      ],
    ),
  );
}

/// The shortcut vocabulary across Control Center surfaces — open the command
/// palette, dispatch an agent, review the next pull request, dismiss a dialog.
@widgetbook.UseCase(name: 'Shortcut vocabulary', type: CcKbd, path: _path)
Widget ccKbdVocabularyUseCase(BuildContext context) {
  const labels = ['⌘K', '⌘↵', '⇧⌘P', '⌥W', 'Esc', 'Tab', '⌘.', '⌘/'];
  return Center(
    child: Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final label in labels) CcKbd(keyLabel: label),
      ],
    ),
  );
}

/// The font-size ramp — the same key-cap rendered from compact inline hints up
/// to a prominent onboarding callout.
@widgetbook.UseCase(name: 'Sizes', type: CcKbd, path: _path)
Widget ccKbdSizesUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        CcKbd(keyLabel: '⌘K', fontSize: 9),
        CcKbd(keyLabel: '⌘K'),
        CcKbd(keyLabel: '⌘K', fontSize: 14),
        CcKbd(keyLabel: '⌘K', fontSize: 18),
      ],
    ),
  );
}

/// Interactive playground — drive the label and size knobs to preview any
/// key-cap.
@widgetbook.UseCase(name: 'Playground', type: CcKbd, path: _path)
Widget ccKbdPlaygroundUseCase(BuildContext context) {
  final label = context.knobs.string(
    label: 'Key label',
    initialValue: '⌘K',
  );
  final fontSize = context.knobs.double.slider(
    label: 'Font size',
    initialValue: 11,
    min: 8,
    max: 24,
  );
  return Center(
    child: CcKbd(keyLabel: label, fontSize: fontSize),
  );
}
