import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_radio.stories.g.dart';

/// Stories for [CcRadio] — the design system's single-select radio control —
/// and [CcRadioGroup], which adds arrow-key navigation across a set of them.
///
/// The stories below are listed under `Components → Inputs → CcRadio` (the
/// `ComponentMeta` name and bracketed `path` segments). The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas. [CcRadio] is selected when its `value` equals `groupValue`; a null
/// `onChanged` disables the control.

const _path = '[Components]/Inputs';

const component = ComponentMeta(name: 'CcRadio', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcRadioPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    selected: BoolArg(true, name: 'Selected'),
    enabled: BoolArg(true, name: 'Enabled'),
    label: StringArg('Run in isolated worktree', name: 'Label'),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccRadioPlaygroundStory(context, args)),
);

final $Group = _Story(args: _Args.fixed(preview: ccRadioGroupStory));

final $KeyboardGroup = _Story(
  name: 'Keyboard group',
  args: _Args.fixed(preview: ccRadioKeyboardGroupStory),
);

final $States = _Story(args: _Args.fixed(preview: ccRadioStatesStory));

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcRadioPlayground {
  CcRadioPlayground({
    required this.selected,
    required this.enabled,
    required this.label,
  });

  final bool selected;
  final bool enabled;
  final String label;
}

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

/// The three resting states side by side: unselected, selected and disabled.
Widget ccRadioStatesStory(BuildContext context) {
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
Widget ccRadioGroupStory(BuildContext context) {
  return const Center(child: _RadioGroupDemo());
}

/// The same choice wrapped in a [CcRadioGroup]: `Tab` lands on the selected
/// radio and the arrow keys move the selection, wrapping at the ends and
/// skipping the disabled option.
Widget ccRadioKeyboardGroupStory(BuildContext context) {
  return const Center(child: _KeyboardGroupDemo());
}

/// Interactive playground — toggle selection and the disabled treatment.
Widget ccRadioPlaygroundStory(
  BuildContext context,
  CcRadioPlaygroundArgs args,
) {
  final selected = args.selected;
  final enabled = args.enabled;
  final label = args.label;
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

/// A [CcRadioGroup] with its labels in a column beside it. The group takes
/// bare [CcRadio]s, so each label row matches a radio's height.
class _KeyboardGroupDemo extends StatefulWidget {
  const _KeyboardGroupDemo();

  @override
  State<_KeyboardGroupDemo> createState() => _KeyboardGroupDemoState();
}

class _KeyboardGroupDemoState extends State<_KeyboardGroupDemo> {
  static const _options = [
    ('sonnet', 'Claude Sonnet', true),
    ('opus', 'Claude Opus', true),
    ('fable', 'Claude Fable (unavailable)', false),
    ('haiku', 'Claude Haiku', true),
  ];

  /// Matches [CcRadio]'s fixed diameter.
  static const double _rowExtent = 18;

  String _group = 'sonnet';

  void _select(String value) => setState(() => _group = value);

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CcRadioGroup<String>(
              groupValue: _group,
              onChanged: _select,
              children: [
                for (final (value, label, enabled) in _options)
                  CcRadio<String>(
                    value: value,
                    groupValue: _group,
                    onChanged: enabled ? _select : null,
                    semanticLabel: label,
                  ),
              ],
            ),
            const SizedBox(width: 10),
            Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final (_, label, enabled) in _options)
                  SizedBox(
                    height: _rowExtent,
                    child: Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: Text(
                        label,
                        style: CcTypography.bodySm.copyWith(
                          color: enabled ? t.textPrimary : t.textDisabled,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        Text(
          'Tab into the group, then use the arrow keys.',
          style: CcTypography.caption.copyWith(color: t.textTertiary),
        ),
      ],
    );
  }
}
