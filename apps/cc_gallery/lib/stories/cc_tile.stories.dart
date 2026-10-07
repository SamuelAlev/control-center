import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_tile.stories.g.dart';

/// Stories for [CcTile] — the design system's flat list row (the cc_ui
/// replacement for Material's `ListTile`).
///
/// The stories below are listed under `Components → Containers → CcTile` (the
/// `ComponentMeta` name and bracketed `path` segments). The builders return the
/// component directly — the gallery's theme addon supplies the [CcTheme] +
/// canvas.

const _path = '[Components]/Containers';

const component = ComponentMeta(name: 'CcTile', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcTilePlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    title: StringArg('Open pull requests', name: 'Title'),
    subtitle: StringArg('12 awaiting review', name: 'Subtitle'),
    withIcon: BoolArg(true, name: 'Leading icon'),
    withTrailing: BoolArg(true, name: 'Trailing chevron'),
    selected: BoolArg(false, name: 'Selected'),
    interactive: BoolArg(true, name: 'Interactive'),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccTilePlaygroundStory(context, args)),
);

final $Anatomy = _Story(args: _Args.fixed(preview: ccTileAnatomyStory));

final $NavigationList = _Story(
  name: 'Navigation list',
  args: _Args.fixed(preview: ccTileNavigationListStory),
);

final $States = _Story(args: _Args.fixed(preview: ccTileStatesStory));

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcTilePlayground {
  CcTilePlayground({
    required this.title,
    required this.subtitle,
    required this.withIcon,
    required this.withTrailing,
    required this.selected,
    required this.interactive,
  });

  final String title;
  final String subtitle;
  final bool withIcon;
  final bool withTrailing;
  final bool selected;
  final bool interactive;
}

/// The anatomy of a tile: leading icon, title, optional subtitle and an
/// optional trailing widget. The last row is a static (non-interactive) tile.
Widget ccTileAnatomyStory(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcTile(
            leadingIcon: CcIcons.gitPullRequest,
            title: 'Open pull requests',
            subtitle: const Text('12 awaiting review'),
            trailing: const Icon(CcIcons.chevronRight, size: 16),
            onTap: () {},
          ),
          CcTile(
            leadingIcon: CcIcons.bot,
            title: 'Architect',
            subtitle: const Text('Claude Opus · running'),
            onTap: () {},
          ),
          const CcTile(
            leadingIcon: CcIcons.folderGit2,
            title: 'control-center',
            subtitle: Text('Static row — no tap handler'),
          ),
        ],
      ),
    ),
  );
}

/// The three resting states side by side: a plain interactive row, the selected
/// row (accent wash + accent title) and a static row with no tap handler.
Widget ccTileStatesStory(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcTile(
            leadingIcon: CcIcons.layoutDashboard,
            title: 'Dashboard',
            onTap: () {},
          ),
          CcTile(
            leadingIcon: CcIcons.users,
            title: 'Team',
            selected: true,
            onTap: () {},
          ),
          const CcTile(leadingIcon: CcIcons.boxes, title: 'Workspaces'),
        ],
      ),
    ),
  );
}

/// A navigable list where exactly one tile is selected — tap a row to move the
/// selection. Demonstrates the interactive selection treatment in context.
Widget ccTileNavigationListStory(BuildContext context) {
  return const Center(child: SizedBox(width: 360, child: _TileNavDemo()));
}

/// Interactive playground — drive every arg to see the full state space.
Widget ccTilePlaygroundStory(BuildContext context, CcTilePlaygroundArgs args) {
  final title = args.title;
  final subtitle = args.subtitle;
  final withIcon = args.withIcon;
  final withTrailing = args.withTrailing;
  final selected = args.selected;
  final interactive = args.interactive;
  return Center(
    child: SizedBox(
      width: 360,
      child: CcTile(
        leadingIcon: withIcon ? CcIcons.gitPullRequest : null,
        title: title,
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: withTrailing
            ? const Icon(CcIcons.chevronRight, size: 16)
            : null,
        selected: selected,
        onTap: interactive ? () {} : null,
      ),
    ),
  );
}

class _TileNavDemo extends StatefulWidget {
  const _TileNavDemo();

  @override
  State<_TileNavDemo> createState() => _TileNavDemoState();
}

class _TileNavDemoState extends State<_TileNavDemo> {
  static const _items = <(IconData, String, String)>[
    (CcIcons.layoutDashboard, 'Dashboard', 'System overview'),
    (CcIcons.gitPullRequest, 'Pull requests', '12 awaiting review'),
    (CcIcons.bot, 'Agents', '3 running'),
    (CcIcons.boxes, 'Workspaces', '5 worktrees'),
    (CcIcons.workflow, 'Pipelines', '1 queued'),
  ];

  int _selected = 1;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < _items.length; i++)
          CcTile(
            leadingIcon: _items[i].$1,
            title: _items[i].$2,
            subtitle: Text(_items[i].$3),
            selected: i == _selected,
            onTap: () => setState(() => _selected = i),
          ),
      ],
    );
  }
}
