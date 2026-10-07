import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_chip.stories.g.dart';

/// Stories for [CcChip] — the design system's compact bordered tag.
///
/// The stories below are listed under `Components → Containers → CcChip` (the
/// `ComponentMeta` name and bracketed `path` segments). The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas.

const _path = '[Components]/Containers';

const component = ComponentMeta(name: 'CcChip', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcChipPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    label: StringArg('workspace', name: 'Label'),
    selected: BoolArg(false, name: 'Selected'),
    withIcon: BoolArg(true, name: 'Leading icon'),
    tappable: BoolArg(true, name: 'Tappable'),
    deletable: BoolArg(false, name: 'Deletable'),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccChipPlaygroundStory(context, args)),
);

final $Deletable = _Story(args: _Args.fixed(preview: ccChipDeletableStory));

final $States = _Story(args: _Args.fixed(preview: ccChipStatesStory));

final $WithIcon = _Story(
  name: 'With icon',
  args: _Args.fixed(preview: ccChipWithIconStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcChipPlayground {
  CcChipPlayground({
    required this.label,
    required this.selected,
    required this.withIcon,
    required this.tappable,
    required this.deletable,
  });

  final String label;
  final bool selected;
  final bool withIcon;
  final bool tappable;
  final bool deletable;
}

void _noop() {}

/// Resting, selected and disabled-looking chips side by side. A chip with no
/// [CcChip.onTap] is non-interactive — that's the right-most "read only" tag.
Widget ccChipStatesStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        CcChip(label: 'opus-4', onPressed: _noop),
        CcChip(label: 'sonnet-4', selected: true, onPressed: _noop),
        CcChip(label: 'haiku-4'),
      ],
    ),
  );
}

/// Chips with a leading icon — handy for typed filters like repos, agents and
/// pull-request labels.
Widget ccChipWithIconStory(BuildContext context) {
  return const Center(
    child: Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        CcChip(
          label: 'control-center',
          leadingIcon: CcIcons.gitBranch,
          onPressed: _noop,
        ),
        CcChip(
          label: 'needs review',
          leadingIcon: CcIcons.gitPullRequest,
          selected: true,
          onPressed: _noop,
        ),
        CcChip(label: 'architect', leadingIcon: CcIcons.bot),
      ],
    ),
  );
}

/// Deletable chips — setting [CcChip.onDeleted] adds a trailing `x`. This demo
/// is stateful so the tags actually leave the row when removed.
Widget ccChipDeletableStory(BuildContext context) {
  return const Center(child: _DeletableChips());
}

class _DeletableChips extends StatefulWidget {
  const _DeletableChips();

  @override
  State<_DeletableChips> createState() => _DeletableChipsState();
}

class _DeletableChipsState extends State<_DeletableChips> {
  final List<String> _labels = <String>[
    'frontend',
    'backend',
    'flaky-test',
    'infra',
  ];

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    if (_labels.isEmpty) {
      return Text(
        'All filters cleared',
        style: CcTypography.bodySm.copyWith(color: tokens?.textTertiary),
      );
    }
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        for (final label in _labels)
          CcChip(
            label: label,
            leadingIcon: CcIcons.tag,
            onDeleted: () => setState(() => _labels.remove(label)),
          ),
      ],
    );
  }
}

/// Interactive playground — drive every arg to see the full state space.
Widget ccChipPlaygroundStory(BuildContext context, CcChipPlaygroundArgs args) {
  final label = args.label;
  final selected = args.selected;
  final withIcon = args.withIcon;
  final tappable = args.tappable;
  final deletable = args.deletable;
  return Center(
    child: CcChip(
      label: label,
      selected: selected,
      leadingIcon: withIcon ? CcIcons.tag : null,
      onPressed: tappable ? _noop : null,
      onDeleted: deletable ? _noop : null,
    ),
  );
}
