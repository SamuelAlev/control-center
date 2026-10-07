import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_menu.stories.g.dart';

/// Stories for [CcMenu] — the design system's flat dropdown menu, the cc_ui
/// replacement for Material's `PopupMenuButton`.
///
/// The stories below are listed under `Components → Navigation & Overlays →
/// CcMenu` (the `ComponentMeta` name and bracketed `path` segments). The
/// builders return the component directly — the gallery's theme addon supplies
/// the [CcTheme] + canvas. Tap the trigger in the canvas to open the panel.

const _path = '[Components]/Navigation & Overlays';

const component = ComponentMeta(name: 'CcMenu', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcMenuPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    triggerLabel: StringArg('PR actions', name: 'Trigger label'),
    variant: EnumArg<CcButtonVariant>(
      CcButtonVariant.values.first,
      name: 'Trigger variant',
      values: CcButtonVariant.values,
    ),
    minWidth: DoubleArg(
      200,
      name: 'Min width',
      style: const SliderDoubleArgStyle(min: 140, max: 320, divisions: 90),
    ),
    withIcons: BoolArg(true, name: 'Leading icons'),
    destructiveLast: BoolArg(true, name: 'Last row destructive'),
    disableLast: BoolArg(false, name: 'Last row disabled'),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccMenuPlaygroundStory(context, args)),
);

final $ContextMenuRightClick = _Story(
  name: 'Context menu (right-click)',
  args: _Args.fixed(preview: ccMenuContextStory),
);

final $GroupedAndSearchable = _Story(
  name: 'Grouped and searchable',
  args: _Args.fixed(preview: ccMenuSearchableStory),
);

final $PlainAndDisabled = _Story(
  name: 'Plain and disabled',
  args: _Args.fixed(preview: ccMenuPlainStory),
);

final $SingleSelect = _Story(
  name: 'Single-select',
  args: _Args.fixed(preview: ccMenuSelectableStory),
);

final $WorkspaceActions = _Story(
  name: 'Workspace actions',
  args: _Args.fixed(preview: ccMenuActionsStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcMenuPlayground {
  CcMenuPlayground({
    required this.triggerLabel,
    required this.variant,
    required this.minWidth,
    required this.withIcons,
    required this.destructiveLast,
    required this.disableLast,
  });

  final String triggerLabel;
  final CcButtonVariant variant;
  final double minWidth;
  final bool withIcons;
  final bool destructiveLast;
  final bool disableLast;
}

void _noop() {}

/// A typical row set: leading icons plus a trailing destructive action that
/// renders in the danger color.
Widget ccMenuActionsStory(BuildContext context) {
  return const Center(
    child: CcMenu(
      target: CcButton(onPressed: _noop, child: Text('Actions')),
      items: [
        CcMenuItem(
          label: 'Rename workspace',
          icon: CcIcons.pencil,
          onSelected: _noop,
        ),
        CcMenuItem(
          label: 'Duplicate workspace',
          icon: CcIcons.copy,
          onSelected: _noop,
        ),
        CcMenuItem(
          label: 'Open in finder',
          icon: CcIcons.folderOpen,
          onSelected: _noop,
        ),
        // The destructive group sits last, set apart by a divider.
        CcMenuItem.divider(),
        CcMenuItem(
          label: 'Delete workspace',
          icon: CcIcons.trash2,
          destructive: true,
          onSelected: _noop,
        ),
      ],
    ),
  );
}

/// Single-select rows: the chosen option carries a leading check mark and the
/// whole column reserves the check gutter so selected and unselected rows stay aligned.
Widget ccMenuSelectableStory(BuildContext context) {
  return const Center(
    child: CcMenu(
      target: CcButton(
        variant: CcButtonVariant.secondary,
        onPressed: _noop,
        child: Text('Sort by'),
      ),
      items: [
        CcMenuItem(label: 'Name', selected: true, onSelected: _noop),
        CcMenuItem(label: 'Date added', onSelected: _noop),
        CcMenuItem(label: 'Date modified', onSelected: _noop),
        CcMenuItem(label: 'Size', onSelected: _noop),
      ],
    ),
  );
}

/// Rows without leading icons and a disabled row that cannot be selected.
Widget ccMenuPlainStory(BuildContext context) {
  return const Center(
    child: CcMenu(
      target: CcButton(
        variant: CcButtonVariant.secondary,
        onPressed: _noop,
        child: Text('Switch model'),
      ),
      items: [
        CcMenuItem(label: 'Claude Opus 4.8', onSelected: _noop),
        CcMenuItem(label: 'Claude Sonnet 4.5', onSelected: _noop),
        CcMenuItem(label: 'Claude Haiku 4.5', onSelected: _noop),
        CcMenuItem(
          label: 'Claude 3 (deprecated)',
          enabled: false,
          onSelected: _noop,
        ),
      ],
    ),
  );
}

/// Grouped + searchable — the editor's `[+]` new-tab menu, the shape this
/// component grew sections and search for.
///
/// Two things to try. Open it and read the empty-query state: the VIRTUAL
/// MACHINE heading is what lets five rows drop the "(VM)" they used to end
/// with, so the word that tells them apart arrives before the group instead of
/// at the end of every line. Then type — the query ranks across the whole menu
/// and drops the headings wholesale, so no heading is ever left standing over
/// an emptied group. Typing "vm" still finds the machines: their
/// [CcMenuItem.searchText] carries the word their labels shed.
///
/// Up/Down skip headings and dividers, Enter takes the top result, and Escape
/// clears the query before it closes the menu.
Widget ccMenuSearchableStory(BuildContext context) {
  const vm = 'Virtual machine vm';
  return const Center(
    child: CcMenu(
      target: CcButton(
        variant: CcButtonVariant.secondary,
        onPressed: _noop,
        child: Text('New tab'),
      ),
      searchable: true,
      searchHint: 'Search',
      emptySearchLabel: 'No matches',
      maxWidth: 280,
      items: [
        CcMenuItem.section('Tools'),
        CcMenuItem(label: 'Terminal', icon: CcIcons.code, onSelected: _noop),
        CcMenuItem(label: 'Editor', icon: CcIcons.fileCode, onSelected: _noop),
        CcMenuItem(
          label: 'Web browser',
          icon: CcIcons.layers,
          onSelected: _noop,
        ),
        CcMenuItem.divider(),
        CcMenuItem.section('Virtual machine'),
        CcMenuItem(
          label: 'Terminal',
          icon: CcIcons.code,
          searchText: vm,
          onSelected: _noop,
        ),
        CcMenuItem(
          label: 'Chromium',
          icon: CcIcons.layers,
          searchText: vm,
          onSelected: _noop,
        ),
        CcMenuItem(
          label: 'Firefox',
          icon: CcIcons.layers,
          searchText: vm,
          onSelected: _noop,
        ),
        CcMenuItem(
          label: 'WebKit',
          icon: CcIcons.layers,
          searchText: vm,
          onSelected: _noop,
        ),
        CcMenuItem(
          label: 'Phone',
          icon: CcIcons.boxes,
          searchText: vm,
          onSelected: _noop,
        ),
        CcMenuItem(
          label: 'Computer',
          icon: CcIcons.layoutDashboard,
          searchText: vm,
          onSelected: _noop,
        ),
        // The variable-length group goes LAST so nothing above it shifts
        // between two openings of the same menu.
        CcMenuItem.divider(),
        CcMenuItem.section('Reopen'),
        CcMenuItem(label: 'Diff', icon: CcIcons.fileDiff, onSelected: _noop),
        CcMenuItem(label: 'Review', icon: CcIcons.sparkles, onSelected: _noop),
      ],
    ),
  );
}

/// Interactive playground — drive the args to vary the trigger, the panel
/// width and the destructive / disabled treatment of the last row.
Widget ccMenuPlaygroundStory(BuildContext context, CcMenuPlaygroundArgs args) {
  final triggerLabel = args.triggerLabel;
  final variant = args.variant;
  final minWidth = args.minWidth;
  final withIcons = args.withIcons;
  final destructiveLast = args.destructiveLast;
  final disableLast = args.disableLast;

  return Center(
    child: CcMenu(
      minWidth: minWidth,
      target: CcButton(
        variant: variant,
        onPressed: _noop,
        child: Text(triggerLabel),
      ),
      items: [
        CcMenuItem(
          label: 'Approve pull request',
          icon: withIcons ? CcIcons.check : null,
          onSelected: _noop,
        ),
        CcMenuItem(
          label: 'Request changes',
          icon: withIcons ? CcIcons.messageSquare : null,
          onSelected: _noop,
        ),
        CcMenuItem(
          label: 'Close without merging',
          icon: withIcons ? CcIcons.x : null,
          destructive: destructiveLast,
          enabled: !disableLast,
          onSelected: _noop,
        ),
      ],
    ),
  );
}

/// The cascading right-click context menu ([showCcMenuAt]): submenu flyouts,
/// shortcut hints, single-select check marks and grouping dividers. Right-click
/// (or tap) the surface to open it at the pointer; arrow keys navigate, right
/// opens a submenu, Escape steps back out.
Widget ccMenuContextStory(BuildContext context) {
  return const Center(child: _ContextMenuDemo());
}

class _ContextMenuDemo extends StatelessWidget {
  const _ContextMenuDemo();

  void _open(BuildContext context, Offset position) {
    showCcMenuAt(
      context: context,
      position: position,
      items: [
        const CcMenuItem(label: 'Close', trailing: '⌘W', onSelected: _noop),
        const CcMenuItem(label: 'Close others', onSelected: _noop),
        const CcMenuItem(label: 'Close all', onSelected: _noop),
        const CcMenuItem.divider(),
        const CcMenuItem(label: 'Copy path', onSelected: _noop),
        const CcMenuItem(label: 'Copy relative path', onSelected: _noop),
        const CcMenuItem.divider(),
        const CcMenuItem.submenu(
          label: 'Split',
          children: [
            CcMenuItem(label: 'Up', onSelected: _noop),
            CcMenuItem(label: 'Down', onSelected: _noop),
            CcMenuItem(label: 'Left', onSelected: _noop),
            CcMenuItem(label: 'Right', onSelected: _noop),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return GestureDetector(
      onSecondaryTapUp: (d) => _open(context, d.globalPosition),
      onTapUp: (d) => _open(context, d.globalPosition),
      child: Container(
        width: 280,
        height: 140,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: t.bgSecondary,
          borderRadius: AppRadii.brLg,
          border: Border.all(color: t.borderSecondary),
        ),
        child: Text(
          'Right-click here',
          style: CcTypography.bodySm.copyWith(color: t.textTertiary),
        ),
      ),
    );
  }
}
