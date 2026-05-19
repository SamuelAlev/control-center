import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcTabs] — the design system's horizontal tab strip.
///
/// [CcTabs] renders the navigation bar only; the caller owns the body for the
/// active [CcTabs.selectedIndex]. Selection is stateful, so each builder hands
/// back a small private [StatefulWidget] that tracks the index and rebuilds on
/// [CcTabs.onChanged]. The builders return the component directly — the
/// gallery's theme addon supplies the [CcTheme] + canvas.

const _path = '[Components]/Navigation & Overlays';

/// Text-only tabs — the common case. First tab selected by default; the
/// selected tab reads as a 2px accent underline plus stronger text colour.
@widgetbook.UseCase(name: 'Default', type: CcTabs, path: _path)
Widget ccTabsDefaultUseCase(BuildContext context) {
  return const Center(
    child: _TabsDemo(
      tabs: [
        CcTab('Overview'),
        CcTab('Checks'),
        CcTab('Files'),
        CcTab('Conversation'),
      ],
    ),
  );
}

/// Tabs with leading icons — status is carried by both the underline bar and
/// the colour, never colour alone, so the glyph is purely supplementary.
@widgetbook.UseCase(name: 'With icons', type: CcTabs, path: _path)
Widget ccTabsWithIconsUseCase(BuildContext context) {
  return const Center(
    child: _TabsDemo(
      initialIndex: 1,
      tabs: [
        CcTab('Pull requests', icon: LucideIcons.gitPullRequest),
        CcTab('Pipelines', icon: LucideIcons.workflow),
        CcTab('Agents', icon: LucideIcons.bot),
        CcTab('Workspaces', icon: LucideIcons.folderGit2),
      ],
    ),
  );
}

/// A two-tab strip — the minimum useful arrangement, e.g. a PR review pane
/// toggling between the conversation and the changed files.
@widgetbook.UseCase(name: 'Two tabs', type: CcTabs, path: _path)
Widget ccTabsTwoUseCase(BuildContext context) {
  return const Center(
    child: _TabsDemo(
      tabs: [
        CcTab('Diff', icon: LucideIcons.fileDiff),
        CcTab('Comments', icon: LucideIcons.messageSquare),
      ],
    ),
  );
}

/// Interactive playground — drive the tab count, leading icons, and which tab
/// starts active to see the full state space.
@widgetbook.UseCase(name: 'Playground', type: CcTabs, path: _path)
Widget ccTabsPlaygroundUseCase(BuildContext context) {
  final count = context.knobs.double
      .slider(label: 'Tab count', initialValue: 4, min: 2, max: 6, divisions: 4)
      .round();
  final withIcons = context.knobs.boolean(label: 'Leading icons');
  final initialIndex = context.knobs.double
      .slider(label: 'Initial index', initialValue: 0, min: 0, max: 5, divisions: 5)
      .round();
  const labels = <String>[
    'Overview',
    'Checks',
    'Files',
    'Conversation',
    'Timeline',
    'Settings',
  ];
  const icons = <IconData>[
    LucideIcons.layoutDashboard,
    LucideIcons.circleCheck,
    LucideIcons.fileCode,
    LucideIcons.messageSquare,
    LucideIcons.clock,
    LucideIcons.settings,
  ];
  final tabs = [
    for (var i = 0; i < count; i++)
      CcTab(labels[i], icon: withIcons ? icons[i] : null),
  ];
  return Center(
    child: _TabsDemo(
      key: ValueKey('$count-$withIcons-$initialIndex'),
      initialIndex: initialIndex.clamp(0, count - 1),
      tabs: tabs,
    ),
  );
}

/// Tracks the active tab so [CcTabs.onChanged] has somewhere to land. The body
/// below the strip names the active tab to make the selection legible.
class _TabsDemo extends StatefulWidget {
  const _TabsDemo({required this.tabs, this.initialIndex = 0, super.key});

  final List<CcTab> tabs;
  final int initialIndex;

  @override
  State<_TabsDemo> createState() => _TabsDemoState();
}

class _TabsDemoState extends State<_TabsDemo> {
  late int _index = widget.initialIndex;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem!;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CcTabs(
          tabs: widget.tabs,
          selectedIndex: _index,
          onChanged: (i) => setState(() => _index = i),
        ),
        AppSpacing.vGapMd,
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          child: Text(
            '${widget.tabs[_index].label} panel',
            style: CcTypography.bodySm.copyWith(color: tokens.textTertiary),
          ),
        ),
      ],
    );
  }
}
