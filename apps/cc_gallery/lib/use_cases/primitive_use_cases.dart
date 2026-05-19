import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Foundation use-cases for the design system **primitives** — the low-level
/// building blocks the components are assembled from.
///
/// - [SegmentedToggle]: a connected segmented control (e.g. Write / Preview).
/// - [FocusRing]: the overlay focus ring that draws *outside* layout (no shift)
///   and only appears for keyboard focus (see `FocusModality`).

const _path = '[Foundations]/Primitives';

@widgetbook.UseCase(name: 'Write / Preview', type: SegmentedToggle, path: _path)
Widget segmentedToggleUseCase(BuildContext context) {
  return const Center(child: _SegmentedToggleDemo());
}

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

class _SegmentedToggleDemo extends StatefulWidget {
  const _SegmentedToggleDemo();

  @override
  State<_SegmentedToggleDemo> createState() => _SegmentedToggleDemoState();
}

class _SegmentedToggleDemoState extends State<_SegmentedToggleDemo> {
  String _value = 'write';

  @override
  Widget build(BuildContext context) {
    return SegmentedToggle<String>(
      value: _value,
      segments: const [
        (value: 'write', label: 'Write'),
        (value: 'preview', label: 'Preview'),
      ],
      onChanged: (v) => setState(() => _value = v),
    );
  }
}
