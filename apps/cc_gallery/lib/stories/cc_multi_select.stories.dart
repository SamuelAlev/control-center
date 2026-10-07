import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_multi_select.stories.g.dart';

/// Stories for [CcMultiSelect] — a flat dropdown with per-row checkboxes that
/// summarises a [Set] of selected values as either a count or chips.
///
/// The stories below are listed under `Components → Inputs → CcMultiSelect`
/// (the `ComponentMeta` name and bracketed `path` segments). The builders
/// return the component directly — the gallery's theme addon supplies the
/// [CcTheme] + canvas. Selection is stateful, so the interactive cases live
/// inside a file-private [_MultiSelectDemo].

const _path = '[Components]/Inputs';

const component = ComponentMeta(name: 'CcMultiSelect', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcMultiSelectPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    showChips: BoolArg(false, name: 'Show chips'),
    enabled: BoolArg(true, name: 'Enabled'),
    hintText: StringArg('Pick reviewers', name: 'Hint text'),
  ),
  builder: (context, args) => Showcase.playground(
    (context) => ccMultiSelectPlaygroundStory(context, args),
  ),
);

final $ChipsSummary = _Story(
  name: 'Chips summary',
  args: _Args.fixed(preview: ccMultiSelectChipsStory),
);

final $CountSummary = _Story(
  name: 'Count summary',
  args: _Args.fixed(preview: ccMultiSelectCountStory),
);

final $Disabled = _Story(
  args: _Args.fixed(preview: ccMultiSelectDisabledStory),
);

final $Filterable = _Story(
  args: _Args.fixed(preview: ccMultiSelectFilterableStory),
);

final $SelectAll = _Story(
  name: 'Select all',
  args: _Args.fixed(preview: ccMultiSelectSelectAllStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcMultiSelectPlayground {
  CcMultiSelectPlayground({
    required this.showChips,
    required this.enabled,
    required this.hintText,
  });

  final bool showChips;
  final bool enabled;
  final String hintText;
}

const List<CcSelectOption<String>> _skillOptions = [
  CcSelectOption(value: 'architecture', label: 'Architecture'),
  CcSelectOption(value: 'design', label: 'Design'),
  CcSelectOption(value: 'review', label: 'Review'),
  CcSelectOption(value: 'testing', label: 'Testing'),
];

/// Eight roles — enough to demo both filtering and the six-option scroll cap.
const List<CcSelectOption<String>> _roleOptions = [
  CcSelectOption(value: 'admin', label: 'Admin'),
  CcSelectOption(value: 'billing', label: 'Billing'),
  CcSelectOption(value: 'editor', label: 'Editor'),
  CcSelectOption(value: 'moderator', label: 'Moderator'),
  CcSelectOption(value: 'owner', label: 'Owner'),
  CcSelectOption(value: 'support', label: 'Support'),
  CcSelectOption(value: 'uploader', label: 'Uploader'),
  CcSelectOption(value: 'viewer', label: 'Viewer'),
];

/// A self-contained selection harness so the panel can toggle values live.
class _MultiSelectDemo extends StatefulWidget {
  const _MultiSelectDemo({
    required this.options,
    this.initial = const {},
    this.hintText,
    this.enabled = true,
    this.showChips = false,
    this.filterable = false,
    this.countLabel,
    this.selectAllLabel,
  });

  final List<CcSelectOption<String>> options;
  final Set<String> initial;
  final String? hintText;
  final bool enabled;
  final bool showChips;
  final bool filterable;
  final String Function(int count)? countLabel;
  final String? selectAllLabel;

  @override
  State<_MultiSelectDemo> createState() => _MultiSelectDemoState();
}

class _MultiSelectDemoState extends State<_MultiSelectDemo> {
  late Set<String> _values = {...widget.initial};

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: CcMultiSelect<String>(
        options: widget.options,
        values: _values,
        hintText: widget.hintText,
        enabled: widget.enabled,
        showChips: widget.showChips,
        filterable: widget.filterable,
        countLabel: widget.countLabel,
        selectAllLabel: widget.selectAllLabel,
        onChanged: (next) => setState(() => _values = next),
      ),
    );
  }
}

/// Empty (placeholder) versus a filled selection summarised as a count.
Widget ccMultiSelectCountStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 24,
      runSpacing: 24,
      children: [
        _MultiSelectDemo(options: _skillOptions, hintText: 'Assign skills'),
        _MultiSelectDemo(
          options: _skillOptions,
          hintText: 'Assign skills',
          initial: {'review', 'architecture'},
        ),
      ],
    ),
  );
}

/// The chip summary — selected option labels render as small chips in the
/// trigger instead of a count.
Widget ccMultiSelectChipsStory(BuildContext context) {
  return const Center(
    child: _MultiSelectDemo(
      options: _skillOptions,
      hintText: 'Assign skills',
      showChips: true,
      initial: {'review', 'design', 'testing'},
    ),
  );
}

/// A parent select-all checkbox pinned at the top of the panel — unchecked
/// selects everything, checked or indeterminate clears the selection. The
/// label names the set ("All skills"), never an action.
Widget ccMultiSelectSelectAllStory(BuildContext context) {
  return const Center(
    child: _MultiSelectDemo(
      options: _skillOptions,
      hintText: 'Assign skills',
      selectAllLabel: 'All skills',
      initial: {'review'},
    ),
  );
}

/// Filterable: hovering the field shows a text cursor, the open field takes
/// typed input that narrows the list and a ✕ clears just the filter. Eight
/// options also cross the six-option scroll threshold, so the panel caps at
/// five and a half rows.
Widget ccMultiSelectFilterableStory(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 280,
      child: _MultiSelectDemo(
        options: _roleOptions,
        hintText: 'Choose options',
        filterable: true,
        initial: {'editor'},
      ),
    ),
  );
}

/// The disabled treatment — the trigger keeps its selection but reads as
/// non-interactive.
Widget ccMultiSelectDisabledStory(BuildContext context) {
  return const Center(
    child: _MultiSelectDemo(
      options: _skillOptions,
      hintText: 'Assign skills',
      enabled: false,
      initial: {'review', 'design'},
    ),
  );
}

/// Interactive playground — drive every arg to see the full state space.
Widget ccMultiSelectPlaygroundStory(
  BuildContext context,
  CcMultiSelectPlaygroundArgs args,
) {
  final showChips = args.showChips;
  final enabled = args.enabled;
  final hintText = args.hintText;
  return Center(
    child: _MultiSelectDemo(
      options: const [
        CcSelectOption(value: 'opus', label: 'Claude Opus'),
        CcSelectOption(value: 'sonnet', label: 'Claude Sonnet'),
        CcSelectOption(value: 'haiku', label: 'Claude Haiku'),
      ],
      hintText: hintText,
      enabled: enabled,
      showChips: showChips,
      initial: const {'sonnet'},
      countLabel: (count) => '$count agents',
    ),
  );
}
