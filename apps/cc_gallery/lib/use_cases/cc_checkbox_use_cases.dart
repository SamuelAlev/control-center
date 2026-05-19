import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcCheckbox] — the design system's flat 18x18 boolean control.
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Inputs → CcCheckbox` (from [CcCheckbox] as
/// the `type` and the bracketed `path` segments). The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas.

const _path = '[Components]/Inputs';

/// The four resting states side by side: unchecked, checked, and the disabled
/// treatment for both. Disabled checkboxes ignore taps and dim to 60% opacity.
@widgetbook.UseCase(name: 'States', type: CcCheckbox, path: _path)
Widget ccCheckboxStatesUseCase(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 24,
      runSpacing: 16,
      children: [
        _LabeledCheckbox(label: 'Unchecked', value: false),
        _LabeledCheckbox(label: 'Checked', value: true),
        _LabeledCheckbox(label: 'Disabled', value: false, enabled: false),
        _LabeledCheckbox(label: 'Disabled checked', value: true, enabled: false),
      ],
    ),
  );
}

/// A vertical list of interactive checkboxes — the way the control reads inside
/// a real settings panel, here scoping which checks a review agent runs.
@widgetbook.UseCase(name: 'Checklist', type: CcCheckbox, path: _path)
Widget ccCheckboxChecklistUseCase(BuildContext context) {
  return const Center(child: _ChecklistDemo());
}

/// Interactive playground — toggle the value and disabled state by hand.
@widgetbook.UseCase(name: 'Playground', type: CcCheckbox, path: _path)
Widget ccCheckboxPlaygroundUseCase(BuildContext context) {
  final enabled = context.knobs.boolean(label: 'Enabled', initialValue: true);
  final autofocus = context.knobs.boolean(label: 'Autofocus');
  return Center(child: _CheckboxDemo(enabled: enabled, autofocus: autofocus));
}

/// A single self-managing checkbox with an adjacent text label.
class _LabeledCheckbox extends StatefulWidget {
  const _LabeledCheckbox({
    required this.label,
    required this.value,
    this.enabled = true,
  });

  final String label;
  final bool value;
  final bool enabled;

  @override
  State<_LabeledCheckbox> createState() => _LabeledCheckboxState();
}

class _LabeledCheckboxState extends State<_LabeledCheckbox> {
  late bool _checked = widget.value;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        CcCheckbox(
          value: _checked,
          semanticLabel: widget.label,
          onChanged: widget.enabled
              ? (v) => setState(() => _checked = v)
              : null,
        ),
        const SizedBox(width: 8),
        Text(
          widget.label,
          style: CcTypography.bodySm.copyWith(color: t?.textPrimary),
        ),
      ],
    );
  }
}

/// A standalone toggleable checkbox used by the playground.
class _CheckboxDemo extends StatefulWidget {
  const _CheckboxDemo({this.enabled = true, this.autofocus = false});

  final bool enabled;
  final bool autofocus;

  @override
  State<_CheckboxDemo> createState() => _CheckboxDemoState();
}

class _CheckboxDemoState extends State<_CheckboxDemo> {
  bool _checked = true;

  @override
  Widget build(BuildContext context) {
    return CcCheckbox(
      value: _checked,
      autofocus: widget.autofocus,
      semanticLabel: 'Toggle',
      onChanged: widget.enabled
          ? (v) => setState(() => _checked = v)
          : null,
    );
  }
}

/// A checklist of review steps for an agent, each row independently togglable.
class _ChecklistDemo extends StatefulWidget {
  const _ChecklistDemo();

  @override
  State<_ChecklistDemo> createState() => _ChecklistDemoState();
}

class _ChecklistDemoState extends State<_ChecklistDemo> {
  final _items = <String, bool>{
    'Run static analysis': true,
    'Check pull request against repo conventions': true,
    'Summarize diff for the workspace channel': false,
    'Suggest inline fixes with Claude Opus': false,
  };

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in _items.entries)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CcCheckbox(
                  value: entry.value,
                  semanticLabel: entry.key,
                  onChanged: (v) => setState(() => _items[entry.key] = v),
                ),
                const SizedBox(width: 10),
                Text(
                  entry.key,
                  style: CcTypography.bodySm.copyWith(color: t?.textPrimary),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
