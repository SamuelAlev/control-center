import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcRadio] — the design system's single-select radio control.
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Inputs → CcRadio`. The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas. [CcRadio] is selected when its `value` equals `groupValue`; a null
/// `onChanged` disables the control.

const _path = '[Components]/Inputs';

/// A labelled radio row, matching the demo layout in `component_stories.dart`.
Widget _row(
  BuildContext context, {
  required String value,
  required String? groupValue,
  required String label,
  ValueChanged<String>? onChanged,
}) {
  final t = context.designSystem!;
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CcRadio<String>(
          value: value,
          groupValue: groupValue,
          onChanged: onChanged,
          semanticLabel: label,
        ),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: t.textPrimary)),
      ],
    ),
  );
}

/// The three resting states side by side: unselected, selected, and disabled.
@widgetbook.UseCase(name: 'States', type: CcRadio, path: _path)
Widget ccRadioStatesUseCase(BuildContext context) {
  void noop(String _) {}
  return Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _row(
          context,
          value: 'opus',
          groupValue: 'sonnet',
          label: 'Unselected',
          onChanged: noop,
        ),
        _row(
          context,
          value: 'sonnet',
          groupValue: 'sonnet',
          label: 'Selected',
          onChanged: noop,
        ),
        _row(
          context,
          value: 'haiku',
          groupValue: 'sonnet',
          label: 'Disabled (unselected)',
        ),
        _row(
          context,
          value: 'sonnet',
          groupValue: 'sonnet',
          label: 'Disabled (selected)',
        ),
      ],
    ),
  );
}

/// An interactive group — pick the model an agent runs on. Demonstrates the
/// canonical single-select behaviour where one choice deselects the rest.
@widgetbook.UseCase(name: 'Group', type: CcRadio, path: _path)
Widget ccRadioGroupUseCase(BuildContext context) {
  return const Center(child: _RadioGroupDemo());
}

/// Interactive playground — toggle selection and the disabled treatment.
@widgetbook.UseCase(name: 'Playground', type: CcRadio, path: _path)
Widget ccRadioPlaygroundUseCase(BuildContext context) {
  final selected = context.knobs.boolean(label: 'Selected', initialValue: true);
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);
  final label = context.knobs.string(
    label: 'Label',
    initialValue: 'Run in isolated worktree',
  );
  final t = context.designSystem!;
  void noop(String _) {}
  return Center(
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CcRadio<String>(
          value: 'option',
          groupValue: selected ? 'option' : 'other',
          onChanged: enabled ? noop : null,
          semanticLabel: label,
        ),
        const SizedBox(width: 10),
        Text(label, style: TextStyle(color: t.textPrimary)),
      ],
    ),
  );
}

/// A stateful single-select group that flips selection on tap, mirroring the
/// `_RadioDemo` helper in `component_stories.dart`.
class _RadioGroupDemo extends StatefulWidget {
  const _RadioGroupDemo();

  @override
  State<_RadioGroupDemo> createState() => _RadioGroupDemoState();
}

class _RadioGroupDemoState extends State<_RadioGroupDemo> {
  String _group = 'sonnet';

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in const [
          ('sonnet', 'Claude Sonnet'),
          ('opus', 'Claude Opus'),
          ('haiku', 'Claude Haiku'),
        ])
          _row(
            context,
            value: entry.$1,
            groupValue: _group,
            label: entry.$2,
            onChanged: (v) => setState(() => _group = v),
          ),
      ],
    );
  }
}
