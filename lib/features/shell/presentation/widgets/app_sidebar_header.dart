import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/shell/presentation/widgets/notification_bell.dart';
import 'package:control_center/features/shell/presentation/widgets/sidebar_chrome.dart';
import 'package:control_center/features/shell/presentation/widgets/title_bar_workspace_chip.dart';
import 'package:control_center/features/shell/providers/command_palette_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/command_palette.dart';
import 'package:flutter/widgets.dart';

/// The global sidebar's header, shared by the app shell (`AppSidebar`) and
/// workspace-agnostic surfaces such as the "Manage workspaces" page: a single
/// row holding the workspace switcher and, optionally, the search
/// (command-palette) and notification affordances.
///
/// In [collapsed] (icon-only rail) mode the header stacks vertically instead:
/// workspace mark, search, then notifications.
///
/// On a workspace-agnostic route no workspace is active, so the switcher chip
/// renders its empty placeholder inviting the operator to select one.
class AppSidebarHeader extends StatelessWidget {
  /// Creates an [AppSidebarHeader].
  const AppSidebarHeader({
    super.key,
    this.workspaceAgnostic = false,
    this.collapsed = false,
  });

  /// Set on workspace-agnostic routes ("Manage workspaces"), where no
  /// workspace is selected: the workspace switcher renders its "select a
  /// workspace" placeholder (even though a last-active id persists) and the
  /// workspace-scoped command palette and notifications are left out.
  final bool workspaceAgnostic;

  /// Whether the sidebar is in its collapsed icon-only rail mode: the header
  /// stacks vertically (mark, search, notifications) instead of the expanded chip
  /// row. Inside a [CcSidebar] the (deferred, animation-aware) scope value
  /// wins over this flag.
  final bool collapsed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final effectiveCollapsed = CcSidebarScope.collapsedOf(context) ?? collapsed;
    final transitioning = CcSidebarScope.transitioningOf(context) ?? false;

    if (effectiveCollapsed) {
      // Rail mode: a centered vertical stack — workspace mark, search, then
      // notifications.
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          TitleBarWorkspaceChip(
            // The logo keeps its expanded 36px size in the rail; only the
            // name, caret and padding shrink away (iconOnly).
            avatarSize: 36,
            forcePlaceholder: workspaceAgnostic,
            iconOnly: true,
          ),
          if (!workspaceAgnostic) ...[
            const SizedBox(height: AppSpacing.xs),
            SidebarHeaderIconButton(
              icon: AppIcons.search,
              tooltip: l10n.commandPalette,
              onPressed: () => showCommandPalette(context, buildGlobalCommands),
            ),
            const NotificationBell(),
          ],
          // Matches the expanded header's bottom inset so the first nav group
          // starts at the same offset in both modes.
          const SizedBox(height: AppSpacing.xs),
        ],
      );
    }

    if (transitioning) {
      // Width animation in flight: just the mark, left-aligned. The iconOnly
      // chip's 1px horizontal padding puts the avatar at the x it occupies in
      // the settled RAIL (x=9 from the sidebar edge); the settled expanded
      // chip's 10px internal padding puts it 9px further right (its left edge
      // on the x=18 group-label line), so the mark glides those 9px as the
      // animation lands. Name and buttons stay out of the way (they would
      // overflow the narrowing row).
      return const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.xs),
        child: Align(
          alignment: AlignmentDirectional.centerStart,
          child: TitleBarWorkspaceChip(avatarSize: 36, iconOnly: true),
        ),
      );
    }

    // One row: workspace chip (left, ellipsizing), search, bell. The chip's
    // hover pill spans the full content width like the nav-item pills below;
    // the name lines up with those labels from the chip's own 10px internal
    // horizontal padding (see _ChipButton), not from an outer inset.
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        0,
        0,
        AppSpacing.xs,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          // The chooser stretches the row's free width (name ellipsizes, caret
          // pinned to the trailing edge); the square search and notification
          // buttons sit at its right.
          Expanded(
            child: TitleBarWorkspaceChip(
              // 36px logo + 4px vertical chip padding either side lands the
              // chooser on its 44px height.
              avatarSize: 36,
              forcePlaceholder: workspaceAgnostic,
            ),
          ),
          if (!workspaceAgnostic) ...[
            const SizedBox(width: AppSpacing.xs),
            SidebarHeaderIconButton(
              icon: AppIcons.search,
              tooltip: l10n.commandPalette,
              onPressed: () => showCommandPalette(context, buildGlobalCommands),
            ),
            const NotificationBell(),
          ],
        ],
      ),
    );
  }
}
