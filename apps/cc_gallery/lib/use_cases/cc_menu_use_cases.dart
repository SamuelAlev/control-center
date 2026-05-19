import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcMenu] — the design system's flat dropdown menu, the cc_ui
/// replacement for Material's `PopupMenuButton`.
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Navigation & Overlays → CcMenu`. The
/// builders return the component directly — the gallery's theme addon supplies
/// the [CcTheme] + canvas. Tap the trigger in the canvas to open the panel.

const _path = '[Components]/Navigation & Overlays';

void _noop() {}

/// A typical row set: leading icons plus a trailing destructive action that
/// renders in the danger color.
@widgetbook.UseCase(name: 'Workspace actions', type: CcMenu, path: _path)
Widget ccMenuActionsUseCase(BuildContext context) {
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
@widgetbook.UseCase(name: 'Single-select', type: CcMenu, path: _path)
Widget ccMenuSelectableUseCase(BuildContext context) {
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
@widgetbook.UseCase(name: 'Plain and disabled', type: CcMenu, path: _path)
Widget ccMenuPlainUseCase(BuildContext context) {
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
@widgetbook.UseCase(name: 'Grouped and searchable', type: CcMenu, path: _path)
Widget ccMenuSearchableUseCase(BuildContext context) {
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

/// Interactive playground — drive the knobs to vary the trigger, the panel
/// width and the destructive / disabled treatment of the last row.
@widgetbook.UseCase(name: 'Playground', type: CcMenu, path: _path)
Widget ccMenuPlaygroundUseCase(BuildContext context) {
  final triggerLabel = context.knobs.string(
    label: 'Trigger label',
    initialValue: 'PR actions',
  );
  final variant = context.knobs.object.dropdown(
    label: 'Trigger variant',
    options: CcButtonVariant.values,
    labelBuilder: (v) => v.name,
  );
  final minWidth = context.knobs.double.slider(
    label: 'Min width',
    initialValue: 200,
    min: 140,
    max: 320,
  );
  final withIcons = context.knobs.boolean(
    label: 'Leading icons',
    initialValue: true,
  );
  final destructiveLast = context.knobs.boolean(
    label: 'Last row destructive',
    initialValue: true,
  );
  final disableLast = context.knobs.boolean(label: 'Last row disabled');

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
@widgetbook.UseCase(
  name: 'Context menu (right-click)',
  type: CcMenu,
  path: _path,
)
Widget ccMenuContextUseCase(BuildContext context) {
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
