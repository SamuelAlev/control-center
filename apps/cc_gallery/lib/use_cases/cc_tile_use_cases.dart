import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcTile] — the design system's flat list row (the cc_ui
/// replacement for Material's `ListTile`).
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Containers → CcTile` (from [CcTile] as the
/// `type` and the bracketed `path` segments). The builders return the component
/// directly — the gallery's theme addon supplies the [CcTheme] + canvas.

const _path = '[Components]/Containers';

/// The anatomy of a tile: leading icon, title, optional subtitle, and an
/// optional trailing widget. The last row is a static (non-interactive) tile.
@widgetbook.UseCase(name: 'Anatomy', type: CcTile, path: _path)
Widget ccTileAnatomyUseCase(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcTile(
            leadingIcon: LucideIcons.gitPullRequest,
            title: 'Open pull requests',
            subtitle: const Text('12 awaiting review'),
            trailing: const Icon(LucideIcons.chevronRight, size: 16),
            onTap: () {},
          ),
          CcTile(
            leadingIcon: LucideIcons.bot,
            title: 'Architect',
            subtitle: const Text('Claude Opus · running'),
            onTap: () {},
          ),
          const CcTile(
            leadingIcon: LucideIcons.folderGit2,
            title: 'control-center',
            subtitle: Text('Static row — no tap handler'),
          ),
        ],
      ),
    ),
  );
}

/// The three resting states side by side: a plain interactive row, the selected
/// row (accent wash + accent title), and a static row with no tap handler.
@widgetbook.UseCase(name: 'States', type: CcTile, path: _path)
Widget ccTileStatesUseCase(BuildContext context) {
  return Center(
    child: SizedBox(
      width: 360,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CcTile(
            leadingIcon: LucideIcons.layoutDashboard,
            title: 'Dashboard',
            onTap: () {},
          ),
          CcTile(
            leadingIcon: LucideIcons.users,
            title: 'Team',
            selected: true,
            onTap: () {},
          ),
          const CcTile(
            leadingIcon: LucideIcons.boxes,
            title: 'Workspaces',
          ),
        ],
      ),
    ),
  );
}

/// A navigable list where exactly one tile is selected — tap a row to move the
/// selection. Demonstrates the interactive selection treatment in context.
@widgetbook.UseCase(name: 'Navigation list', type: CcTile, path: _path)
Widget ccTileNavigationListUseCase(BuildContext context) {
  return const Center(
    child: SizedBox(width: 360, child: _TileNavDemo()),
  );
}

/// Interactive playground — drive every knob to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcTile, path: _path)
Widget ccTilePlaygroundUseCase(BuildContext context) {
  final title = context.knobs.string(
    label: 'Title',
    initialValue: 'Open pull requests',
  );
  final subtitle = context.knobs.string(
    label: 'Subtitle',
    initialValue: '12 awaiting review',
  );
  final withIcon = context.knobs.boolean(
    label: 'Leading icon',
    initialValue: true,
  );
  final withTrailing = context.knobs.boolean(
    label: 'Trailing chevron',
    initialValue: true,
  );
  final selected = context.knobs.boolean(label: 'Selected');
  final interactive = context.knobs.boolean(
    label: 'Interactive',
    initialValue: true,
  );
  return Center(
    child: SizedBox(
      width: 360,
      child: CcTile(
        leadingIcon: withIcon ? LucideIcons.gitPullRequest : null,
        title: title,
        subtitle: subtitle.isEmpty ? null : Text(subtitle),
        trailing: withTrailing
            ? const Icon(LucideIcons.chevronRight, size: 16)
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
    (LucideIcons.layoutDashboard, 'Dashboard', 'System overview'),
    (LucideIcons.gitPullRequest, 'Pull requests', '12 awaiting review'),
    (LucideIcons.bot, 'Agents', '3 running'),
    (LucideIcons.boxes, 'Workspaces', '5 worktrees'),
    (LucideIcons.workflow, 'Pipelines', '1 queued'),
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
