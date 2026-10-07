import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_checkbox.stories.g.dart';

/// Stories for [CcCheckbox] — the design system's flat 18x18 boolean control.
///
/// The stories below are listed under `Components → Inputs → CcCheckbox` (the
/// `ComponentMeta` name and bracketed `path` segments). The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas.

const _path = '[Components]/Inputs';

const component = ComponentMeta(name: 'CcCheckbox', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcCheckboxPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    enabled: BoolArg(true, name: 'Enabled'),
    autofocus: BoolArg(false, name: 'Autofocus'),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccCheckboxPlaygroundStory(context, args),
  ),
);

final $Checklist = _Story(args: _Args.fixed(preview: ccCheckboxChecklistStory));

final $States = _Story(args: _Args.fixed(preview: ccCheckboxStatesStory));

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcCheckboxPlayground {
  CcCheckboxPlayground({required this.enabled, required this.autofocus});

  final bool enabled;
  final bool autofocus;
}

/// The four resting states side by side: unchecked, checked and the disabled
/// treatment for both. Disabled checkboxes ignore taps and dim to 60% opacity.
Widget ccCheckboxStatesStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 24,
      runSpacing: 16,
      children: [
        _LabeledCheckbox(label: 'Unchecked', value: false),
        _LabeledCheckbox(label: 'Checked', value: true),
        _LabeledCheckbox(label: 'Disabled', value: false, enabled: false),
        _LabeledCheckbox(
          label: 'Disabled checked',
          value: true,
          enabled: false,
        ),
      ],
    ),
  );
}

/// A vertical list of interactive checkboxes — the way the control reads inside
/// a real settings panel, here scoping which checks a review agent runs.
Widget ccCheckboxChecklistStory(BuildContext context) {
  return const Center(child: _ChecklistDemo());
}

/// Interactive playground — toggle the value and disabled state by hand.
Widget ccCheckboxPlaygroundStory(
  BuildContext context,
  CcCheckboxPlaygroundArgs args,
) {
  final enabled = args.enabled;
  final autofocus = args.autofocus;
  return Center(
    child: _CheckboxDemo(enabled: enabled, autofocus: autofocus),
  );
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
      onChanged: widget.enabled ? (v) => setState(() => _checked = v) : null,
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
    'Summarize diff for the workspace space': false,
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
