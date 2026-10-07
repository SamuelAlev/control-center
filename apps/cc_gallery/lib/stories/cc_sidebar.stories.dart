import 'package:cc_gallery/showcase.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

part 'cc_sidebar.stories.g.dart';

/// Stories for [CcSidebar] — the app-shell navigation container.
///
/// The stories below are listed under `Components → Navigation & Overlays →
/// CcSidebar` (the `ComponentMeta` name and bracketed `path` segments).
/// Builders return the component directly inside a sized box — the gallery's
/// theme addon supplies the [CcTheme] + canvas.

const _path = '[Components]/Navigation & Overlays';

const component = ComponentMeta(name: 'CcSidebar', path: _path);

const meta = Meta(Showcase.new);
const playgroundMeta = Meta(
  Showcase.playground,
  argsType: CcSidebarPlayground.new,
);

final $Playground = _PlaygroundStory(
  args: _PlaygroundArgs(
    collapsed: BoolArg(false, name: 'Collapsed'),
    withHeader: BoolArg(true, name: 'Header'),
    withFooter: BoolArg(true, name: 'Footer'),
    width: DoubleArg(
      248,
      name: 'Expanded width',
      style: const SliderDoubleArgStyle(min: 180, max: 320, divisions: 70),
    ),
  ),
  builder: (context, args) =>
      Showcase.playground((context) => ccSidebarPlaygroundStory(context, args)),
);

final $CollapsedRail = _Story(
  name: 'Collapsed rail',
  args: _Args.fixed(preview: ccSidebarCollapsedStory),
);

final $CollapsibleGroups = _Story(
  name: 'Collapsible groups',
  args: _Args.fixed(preview: ccSidebarCollapsibleGroupsStory),
);

final $Expanded = _Story(args: _Args.fixed(preview: ccSidebarExpandedStory));

final $NestedBranch = _Story(
  name: 'Nested branch',
  args: _Args.fixed(preview: ccSidebarNestedBranchStory),
);

/// The controls of the interactive story, as constructor parameters
/// widgetbook turns into typed args.
class CcSidebarPlayground {
  CcSidebarPlayground({
    required this.collapsed,
    required this.withHeader,
    required this.withFooter,
    required this.width,
  });

  final bool collapsed;
  final bool withHeader;
  final bool withFooter;
  final double width;
}

/// The workspace header pinned above the scrolling body.
Widget _header(BuildContext context) => Padding(
  padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
  child: Row(
    children: [
      const CcAvatar(initials: 'CC', size: 28),
      const SizedBox(width: 8),
      Text(
        'Control Center',
        style: TextStyle(color: context.designSystem?.textPrimary),
      ),
    ],
  ),
);

/// The expanded sidebar with a header, grouped destinations, a count badge and
/// the current selection.
Widget ccSidebarExpandedStory(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: SizedBox(
      height: 460,
      child: CcSidebar(
        header: _header(context),
        footer: const CcSidebarItem(icon: CcIcons.settings, label: 'Settings'),
        children: const [
          CcSidebarGroup(
            label: 'Workspace',
            children: [
              CcSidebarItem(
                icon: CcIcons.layoutDashboard,
                label: 'Dashboard',
                selected: true,
              ),
              CcSidebarItem(
                icon: CcIcons.gitPullRequest,
                label: 'Pull requests',
                badge: Text('12'),
              ),
              CcSidebarItem(icon: CcIcons.users, label: 'Agents'),
              CcSidebarItem(icon: CcIcons.listTodo, label: 'Tickets'),
            ],
          ),
          CcSidebarGroup(
            label: 'Automation',
            children: [
              CcSidebarItem(icon: CcIcons.workflow, label: 'Pipelines'),
              CcSidebarItem(icon: CcIcons.folderGit2, label: 'Repos'),
            ],
          ),
        ],
      ),
    ),
  );
}

/// The collapsed icon-only rail — labels hide, items become fixed 32px
/// squares and the pull requests badge keeps its count straddling the
/// item's top-right corner.
Widget ccSidebarCollapsedStory(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(24),
    child: SizedBox(
      height: 460,
      child: CcSidebar(
        collapsed: true,
        footer: CcSidebarItem(icon: CcIcons.settings, label: 'Settings'),
        children: [
          CcSidebarGroup(
            label: 'Workspace',
            children: [
              CcSidebarItem(
                icon: CcIcons.layoutDashboard,
                label: 'Dashboard',
                selected: true,
              ),
              CcSidebarItem(
                icon: CcIcons.gitPullRequest,
                label: 'Pull requests',
                badge: Text('12'),
              ),
              CcSidebarItem(icon: CcIcons.users, label: 'Agents'),
              CcSidebarItem(icon: CcIcons.listTodo, label: 'Tickets'),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Collapsible groups — each section header is tappable with a rotating chevron
/// that expands or collapses its destinations.
Widget ccSidebarCollapsibleGroupsStory(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: SizedBox(
      height: 460,
      child: CcSidebar(
        header: _header(context),
        children: const [
          CcSidebarGroup(
            label: 'Workspace',
            collapsible: true,
            children: [
              CcSidebarItem(
                icon: CcIcons.layoutDashboard,
                label: 'Dashboard',
                selected: true,
              ),
              CcSidebarItem(icon: CcIcons.users, label: 'Agents'),
            ],
          ),
          CcSidebarGroup(
            label: 'Automation',
            collapsible: true,
            initiallyExpanded: false,
            children: [
              CcSidebarItem(icon: CcIcons.workflow, label: 'Pipelines'),
              CcSidebarItem(icon: CcIcons.folderGit2, label: 'Repos'),
            ],
          ),
        ],
      ),
    ),
  );
}

/// A nested accordion — children sit flush under the parent against a
/// vertical rail aligned to the parent icon, while selection and hover keep
/// the solid brand pill / travelling wash of a flat [CcSidebarItem].
Widget ccSidebarNestedBranchStory(BuildContext context) {
  final t = context.ds;
  Widget chevron({required bool expanded}) => Icon(
    expanded ? CcIcons.chevronDown : CcIcons.chevronRight,
    size: 14,
    color: t.textTertiary,
  );

  return Padding(
    padding: const EdgeInsets.all(24),
    child: SizedBox(
      height: 460,
      child: CcSidebar(
        children: [
          CcSidebarGroup(
            label: 'Workspace',
            children: [
              CcSidebarItem(
                icon: CcIcons.messageSquare,
                label: 'Chat',
                selected: true,
                onPressed: () {},
              ),
              CcSidebarItem(
                icon: CcIcons.bot,
                label: 'Agents',
                onPressed: () {},
              ),
              CcSidebarItem(
                icon: CcIcons.folder,
                label: 'Knowledge',
                onPressed: () {},
              ),
            ],
          ),
          CcSidebarGroup(
            label: 'Shared',
            children: [
              CcSidebarItem(
                icon: CcIcons.boxes,
                label: 'Engineering',
                badge: chevron(expanded: true),
                onPressed: () {},
              ),
              CcSidebarBranch(
                children: [
                  CcSidebarItem(
                    icon: CcIcons.fileCode,
                    label: 'API guidelines',
                    onPressed: () {},
                  ),
                  CcSidebarItem(
                    icon: CcIcons.play,
                    label: 'Release process',
                    onPressed: () {},
                  ),
                ],
              ),
              CcSidebarItem(
                icon: CcIcons.layers,
                label: 'Product hub',
                badge: chevron(expanded: false),
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Interactive playground — toggle the rail and the expanded width.
Widget ccSidebarPlaygroundStory(
  BuildContext context,
  CcSidebarPlaygroundArgs args,
) {
  final collapsed = args.collapsed;
  final withHeader = args.withHeader;
  final withFooter = args.withFooter;
  final width = args.width;

  return Padding(
    padding: const EdgeInsets.all(24),
    child: SizedBox(
      height: 460,
      child: CcSidebar(
        collapsed: collapsed,
        width: width,
        header: withHeader ? _header(context) : null,
        footer: withFooter
            ? const CcSidebarItem(icon: CcIcons.settings, label: 'Settings')
            : null,
        children: const [
          CcSidebarGroup(
            label: 'Workspace',
            children: [
              CcSidebarItem(
                icon: CcIcons.layoutDashboard,
                label: 'Dashboard',
                selected: true,
              ),
              CcSidebarItem(
                icon: CcIcons.gitPullRequest,
                label: 'Pull requests',
                badge: Text('12'),
              ),
              CcSidebarItem(icon: CcIcons.users, label: 'Agents'),
            ],
          ),
        ],
      ),
    ),
  );
}
