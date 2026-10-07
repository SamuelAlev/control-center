import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_tabs.stories.g.dart';

/// Stories for [CcTabs] — the design system's horizontal tab strip.
///
/// [CcTabs] renders the navigation bar only; the caller owns the body for the
/// active [CcTabs.selectedIndex]. Selection is stateful, so each builder hands
/// back a small private [StatefulWidget] that tracks the index and rebuilds on
/// [CcTabs.onChanged]. The builders return the component directly — the
/// gallery's theme addon supplies the [CcTheme] + canvas.

const _path = '[Components]/Navigation & Overlays';

const component = ComponentMeta(name: 'CcTabs', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcTabsPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    count: IntArg(
      4,
      name: 'Tab count',
      style: const SliderIntArgStyle(min: 2, max: 6, divisions: 4),
    ),
    withIcons: BoolArg(false, name: 'Leading icons'),
    initialIndex: IntArg(
      0,
      name: 'Initial index',
      style: const SliderIntArgStyle(min: 0, max: 5, divisions: 5),
    ),
    // Fixed height's control; the playground sizes itself.
    height: Arg.fixed(35),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccTabsPlaygroundStory(context, args)),
);

final $Default = _Story(args: _Args.fixed(preview: ccTabsDefaultStory));

final $FixedHeight = _PlaygroundStory(
  name: 'Fixed height',
  args: _PlaygroundArgs(
    height: DoubleArg(
      35,
      name: 'Strip height',
      style: const SliderDoubleArgStyle(min: 28, max: 56, divisions: 28),
    ),
    // The playground's controls; this story only varies the height.
    count: Arg.fixed(4),
    withIcons: Arg.fixed(false),
    initialIndex: Arg.fixed(0),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccTabsFixedHeightStory(context, args)),
);

final $TwoTabs = _Story(
  name: 'Two tabs',
  args: _Args.fixed(preview: ccTabsTwoStory),
);

final $WithIcons = _Story(
  name: 'With icons',
  args: _Args.fixed(preview: ccTabsWithIconsStory),
);

/// The controls of the interactive stories (Playground and Fixed height), as
/// constructor parameters widgetbook turns into typed args. Each story pins
/// the other's controls with `Arg.fixed`.
class CcTabsPlayground {
  CcTabsPlayground({
    required this.height,
    required this.count,
    required this.withIcons,
    required this.initialIndex,
  });

  final double height;
  final int count;
  final bool withIcons;
  final int initialIndex;
}

/// Text-only tabs — the common case. First tab selected by default; the
/// selected tab reads as a 2px accent underline plus stronger text colour.
Widget ccTabsDefaultStory(BuildContext context) {
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
Widget ccTabsWithIconsStory(BuildContext context) {
  return const Center(
    child: _TabsDemo(
      initialIndex: 1,
      tabs: [
        CcTab('Pull requests', icon: CcIcons.gitPullRequest),
        CcTab('Pipelines', icon: CcIcons.workflow),
        CcTab('Agents', icon: CcIcons.bot),
        CcTab('Workspaces', icon: CcIcons.folderGit2),
      ],
    ),
  );
}

/// A two-tab strip — the minimum useful arrangement, e.g. a PR review pane
/// toggling between the conversation and the changed files.
Widget ccTabsTwoStory(BuildContext context) {
  return const Center(
    child: _TabsDemo(
      tabs: [
        CcTab('Diff', icon: CcIcons.fileDiff),
        CcTab('Comments', icon: CcIcons.messageSquare),
      ],
    ),
  );
}

/// A strip pinned to an exact height (bottom rule included) via
/// [CcTabs.height]. Set it when the strip abuts another strip of a known
/// height — the messaging IDE sidebar next to the editor tab bar — since the
/// self-sized height is fractional and would leave a visible jog in the rule
/// where the two meet. The tabs stretch to fill it, so the underline stays on
/// the rule.
Widget ccTabsFixedHeightStory(BuildContext context, CcTabsPlaygroundArgs args) {
  final height = args.height;
  return Center(
    child: _TabsDemo(
      key: ValueKey(height),
      height: height,
      tabs: const [
        CcTab('General', icon: CcIcons.layoutDashboard),
        CcTab('Explorer', icon: CcIcons.folderTree),
        CcTab('Source control', icon: CcIcons.gitBranch),
      ],
    ),
  );
}

/// Interactive playground — drive the tab count, leading icons and which tab
/// starts active to see the full state space.
Widget ccTabsPlaygroundStory(BuildContext context, CcTabsPlaygroundArgs args) {
  final count = args.count;
  final withIcons = args.withIcons;
  final initialIndex = args.initialIndex;
  const labels = <String>[
    'Overview',
    'Checks',
    'Files',
    'Conversation',
    'Timeline',
    'Settings',
  ];
  const icons = <IconData>[
    CcIcons.layoutDashboard,
    CcIcons.circleCheck,
    CcIcons.fileCode,
    CcIcons.messageSquare,
    CcIcons.clock,
    CcIcons.settings,
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
  const _TabsDemo({
    required this.tabs,
    this.initialIndex = 0,
    this.height,
    super.key,
  });

  final List<CcTab> tabs;
  final int initialIndex;

  /// Forwarded to [CcTabs.height]; null keeps the self-sized strip.
  final double? height;

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
          height: widget.height,
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
