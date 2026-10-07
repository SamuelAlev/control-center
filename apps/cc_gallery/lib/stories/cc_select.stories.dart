import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_select.stories.g.dart';

/// Stories for [CcSelect] — the design system's flat single-select dropdown
/// (the cc_ui replacement for Material's `DropdownButton`).
///
/// The stories below are listed under `Components → Inputs → CcSelect` (the
/// `ComponentMeta` name and bracketed `path` segments). The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas. [CcSelect] is generic, so the bare class name is used as `type`.

const _path = '[Components]/Inputs';

const component = ComponentMeta(name: 'CcSelect', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcSelectPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    preselected: BoolArg(true, name: 'Has selection'),
    enabled: BoolArg(true, name: 'Enabled'),
    hint: StringArg('Pick a workspace', name: 'Hint text'),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccSelectPlaygroundStory(context, args)),
);

final $Default = _Story(args: _Args.fixed(preview: ccSelectDefaultStory));

final $EmptyDisabled = _Story(
  name: 'Empty & disabled',
  args: _Args.fixed(preview: ccSelectEmptyAndDisabledStory),
);

final $LongList = _Story(
  name: 'Long list',
  args: _Args.fixed(preview: ccSelectLongListStory),
);

final $Models = _Story(args: _Args.fixed(preview: ccSelectModelsStory));

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcSelectPlayground {
  CcSelectPlayground({
    required this.preselected,
    required this.enabled,
    required this.hint,
  });

  final bool preselected;
  final bool enabled;
  final String hint;
}

const List<CcSelectOption<String>> _sortOptions = [
  CcSelectOption(value: 'recent', label: 'Most recent'),
  CcSelectOption(value: 'oldest', label: 'Oldest'),
  CcSelectOption(value: 'largest', label: 'Largest diff'),
];

const List<CcSelectOption<String>> _modelOptions = [
  CcSelectOption(value: 'opus', label: 'Claude Opus 4.8'),
  CcSelectOption(value: 'sonnet', label: 'Claude Sonnet 4.5'),
  CcSelectOption(value: 'haiku', label: 'Claude Haiku 4'),
];

/// Eight options — past the six-option scroll threshold, so the panel caps at
/// five and a half rows and the half-cut last row signals more below.
const List<CcSelectOption<String>> _memberOptions = [
  CcSelectOption(value: 'amara', label: 'Amara Diallo'),
  CcSelectOption(value: 'bjoern', label: 'Björn Larsen'),
  CcSelectOption(value: 'chen', label: 'Chen Wei'),
  CcSelectOption(value: 'duna', label: 'Duna Haddad'),
  CcSelectOption(value: 'eli', label: 'Eli Moreau'),
  CcSelectOption(value: 'farah', label: 'Farah Naz'),
  CcSelectOption(value: 'gus', label: 'Gus Papadopoulos'),
  CcSelectOption(value: 'hina', label: 'Hina Sato'),
];

/// The default control with a value selected — open it to see the row check
/// and keyboard highlight.
Widget ccSelectDefaultStory(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 240,
      child: _SelectDemo(options: _sortOptions, initial: 'recent'),
    ),
  );
}

/// The model picker — three text-only options (dropdowns never carry icons).
Widget ccSelectModelsStory(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 240,
      child: _SelectDemo(options: _modelOptions, initial: 'opus'),
    ),
  );
}

/// A long option list scrolls from the sixth option: the panel stops at five
/// and a half rows so the half-visible row advertises the overflow.
Widget ccSelectLongListStory(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 240,
      child: _SelectDemo(options: _memberOptions, initial: 'amara'),
    ),
  );
}

/// Empty (placeholder hint, no selection) next to the disabled treatment.
Widget ccSelectEmptyAndDisabledStory(BuildContext context) {
  return const Center(
    child: SizedBox(
      width: 240,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SelectDemo(
            options: _sortOptions,
            initial: null,
            hintText: 'Sort pull requests',
          ),
          SizedBox(height: 16),
          CcSelect<String>(
            options: _sortOptions,
            value: null,
            enabled: false,
            hintText: 'Sort pull requests',
            onChanged: _ignore,
          ),
        ],
      ),
    ),
  );
}

/// Interactive playground — drive every arg to see the full state space.
Widget ccSelectPlaygroundStory(
  BuildContext context,
  CcSelectPlaygroundArgs args,
) {
  final preselected = args.preselected;
  final enabled = args.enabled;
  final hint = args.hint;

  const options = [
    CcSelectOption(value: 'control-center', label: 'control-center'),
    CcSelectOption(value: 'cc-ui', label: 'cc_ui'),
    CcSelectOption(value: 'rift', label: 'rift'),
  ];

  return Center(
    child: SizedBox(
      width: 260,
      child: _SelectDemo(
        key: ValueKey('$preselected-$enabled'),
        options: options,
        initial: preselected ? 'control-center' : null,
        hintText: hint,
        enabled: enabled,
      ),
    ),
  );
}

void _ignore(String _) {}

/// Stateful host that owns the selection, mirroring `_SelectDemo` in
/// `component_stories.dart`.
class _SelectDemo extends StatefulWidget {
  const _SelectDemo({
    required this.options,
    required this.initial,
    this.hintText,
    this.enabled = true,
    super.key,
  });

  final List<CcSelectOption<String>> options;
  final String? initial;
  final String? hintText;
  final bool enabled;

  @override
  State<_SelectDemo> createState() => _SelectDemoState();
}

class _SelectDemoState extends State<_SelectDemo> {
  late String? _value = widget.initial;

  @override
  Widget build(BuildContext context) {
    return CcSelect<String>(
      options: widget.options,
      value: _value,
      hintText: widget.hintText,
      enabled: widget.enabled,
      onChanged: (v) => setState(() => _value = v),
    );
  }
}
