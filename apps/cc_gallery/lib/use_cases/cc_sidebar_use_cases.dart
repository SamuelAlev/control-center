import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:widgetbook/widgetbook.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

/// Use-cases for [CcSidebar] — the app-shell navigation container.
///
/// Each builder is annotated with `@widgetbook.UseCase`; widgetbook_generator
/// groups them under `Components → Navigation & Overlays → CcSidebar`. Builders
/// return the component directly inside a sized box — the gallery's theme addon
/// supplies the [CcTheme] + canvas.

const _path = '[Components]/Navigation & Overlays';

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

/// The expanded sidebar with a header, grouped destinations, a count badge, and
/// the current selection.
@widgetbook.UseCase(name: 'Expanded', type: CcSidebar, path: _path)
Widget ccSidebarExpandedUseCase(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.all(24),
    child: SizedBox(
      height: 460,
      child: CcSidebar(
        header: _header(context),
        footer: const CcSidebarItem(
          icon: LucideIcons.settings,
          label: 'Settings',
        ),
        children: const [
          CcSidebarGroup(
            label: 'Workspace',
            children: [
              CcSidebarItem(
                icon: LucideIcons.layoutDashboard,
                label: 'Dashboard',
                selected: true,
              ),
              CcSidebarItem(
                icon: LucideIcons.gitPullRequest,
                label: 'Pull requests',
                badge: Text('12'),
              ),
              CcSidebarItem(icon: LucideIcons.users, label: 'Agents'),
              CcSidebarItem(icon: LucideIcons.listTodo, label: 'Tickets'),
            ],
          ),
          CcSidebarGroup(
            label: 'Automation',
            children: [
              CcSidebarItem(icon: LucideIcons.workflow, label: 'Pipelines'),
              CcSidebarItem(icon: LucideIcons.folderGit2, label: 'Repos'),
            ],
          ),
        ],
      ),
    ),
  );
}

/// The collapsed icon-only rail — labels hide, icons center, and the pull
/// requests badge reduces to an accent dot.
@widgetbook.UseCase(name: 'Collapsed rail', type: CcSidebar, path: _path)
Widget ccSidebarCollapsedUseCase(BuildContext context) {
  return const Padding(
    padding: EdgeInsets.all(24),
    child: SizedBox(
      height: 460,
      child: CcSidebar(
        collapsed: true,
        footer: CcSidebarItem(
          icon: LucideIcons.settings,
          label: 'Settings',
        ),
        children: [
          CcSidebarGroup(
            label: 'Workspace',
            children: [
              CcSidebarItem(
                icon: LucideIcons.layoutDashboard,
                label: 'Dashboard',
                selected: true,
              ),
              CcSidebarItem(
                icon: LucideIcons.gitPullRequest,
                label: 'Pull requests',
                badge: Text('12'),
              ),
              CcSidebarItem(icon: LucideIcons.users, label: 'Agents'),
              CcSidebarItem(icon: LucideIcons.listTodo, label: 'Tickets'),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Collapsible groups — each section header is tappable with a rotating chevron
/// that expands or collapses its destinations.
@widgetbook.UseCase(name: 'Collapsible groups', type: CcSidebar, path: _path)
Widget ccSidebarCollapsibleGroupsUseCase(BuildContext context) {
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
                icon: LucideIcons.layoutDashboard,
                label: 'Dashboard',
                selected: true,
              ),
              CcSidebarItem(icon: LucideIcons.users, label: 'Agents'),
            ],
          ),
          CcSidebarGroup(
            label: 'Automation',
            collapsible: true,
            initiallyExpanded: false,
            children: [
              CcSidebarItem(icon: LucideIcons.workflow, label: 'Pipelines'),
              CcSidebarItem(icon: LucideIcons.folderGit2, label: 'Repos'),
            ],
          ),
        ],
      ),
    ),
  );
}

/// Interactive playground — toggle the rail, the trailing border, and the
/// expanded width.
@widgetbook.UseCase(name: 'Playground', type: CcSidebar, path: _path)
Widget ccSidebarPlaygroundUseCase(BuildContext context) {
  final t = context.designSystem;
  final collapsed = context.knobs.boolean(label: 'Collapsed');
  final withHeader = context.knobs.boolean(
    label: 'Header',
    initialValue: true,
  );
  final withFooter = context.knobs.boolean(
    label: 'Footer',
    initialValue: true,
  );
  final withBorder = context.knobs.boolean(label: 'Trailing border');
  final width = context.knobs.double.slider(
    label: 'Expanded width',
    initialValue: 248,
    min: 180,
    max: 320,
  );

  return Padding(
    padding: const EdgeInsets.all(24),
    child: SizedBox(
      height: 460,
      child: CcSidebar(
        collapsed: collapsed,
        width: width,
        trailingBorder: withBorder && t != null
            ? BorderSide(color: t.borderPrimary)
            : null,
        header: withHeader ? _header(context) : null,
        footer: withFooter
            ? const CcSidebarItem(
                icon: LucideIcons.settings,
                label: 'Settings',
              )
            : null,
        children: const [
          CcSidebarGroup(
            label: 'Workspace',
            children: [
              CcSidebarItem(
                icon: LucideIcons.layoutDashboard,
                label: 'Dashboard',
                selected: true,
              ),
              CcSidebarItem(
                icon: LucideIcons.gitPullRequest,
                label: 'Pull requests',
                badge: Text('12'),
              ),
              CcSidebarItem(icon: LucideIcons.users, label: 'Agents'),
            ],
          ),
        ],
      ),
    ),
  );
}
