import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Foundation use-cases for the design system **primitives** — the low-level
/// building blocks the components are assembled from.
///
/// - [FocusRing]: the overlay focus ring that draws *outside* layout (no shift)
///   and only appears for keyboard focus (see `FocusModality`).
///
/// `CcSegmentedToggle` used to live here; it is a component like any other
/// (`Components → Inputs`), not a primitive the components are built from.

const _path = '[Foundations]/Primitives';

@widgetbook.UseCase(name: 'Focused field', type: FocusRing, path: _path)
Widget focusRingUseCase(BuildContext context) {
  final t = context.designSystem!;
  // requestFocus so the ring is visible the moment the preview renders.
  final node = FocusNode(debugLabel: 'gallery-focus-ring')..requestFocus();
  return Center(
    child: FocusRing(
      focusNode: node,
      color: t.accent,
      child: Container(
        width: 240,
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.surface,
          borderRadius: AppRadii.brSm,
          border: Border.all(color: t.borderPrimary),
        ),
        child: Text('Focused field', style: TextStyle(color: t.textPrimary)),
      ),
    ),
  );
}
