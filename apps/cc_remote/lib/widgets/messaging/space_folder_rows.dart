import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/format.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
import 'package:cc_remote/operation_scope.dart';
import 'package:cc_remote/space_folders.dart';
import 'package:cc_remote/widgets/touch_target.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// A collapsible folder header with an always-visible, touch-sized actions button.
class RemoteSpaceFolderRow extends StatelessWidget {
  /// Creates the folder header.
  const RemoteSpaceFolderRow({
    required this.folder,
    required this.expanded,
    required this.onToggle,
    required this.onActions,
    super.key,
  });

  /// Personal folder displayed in the current workspace.
  final SpaceFolder folder;

  /// Whether its visible spaces are listed below.
  final bool expanded;

  /// Toggles its expansion.
  final VoidCallback onToggle;

  /// Opens the folder actions.
  final VoidCallback onActions;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: CcTappable(
              onPressed: onToggle,
              semanticLabel: folder.name,
              builder: (context, _) => ConstrainedBox(
                constraints: const BoxConstraints(minHeight: kMinTouchTarget),
                child: Row(
                  children: [
                    Icon(AppIcons.folder, size: 18, color: t.fgSecondary),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        folder.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: t.textPrimary,
                        ),
                      ),
                    ),
                    Icon(
                      expanded ? AppIcons.chevronDown : AppIcons.chevronRight,
                      size: 16,
                      color: t.fgTertiary,
                    ),
                  ],
                ),
              ),
            ),
          ),
          PhoneIconButton(
            icon: AppIcons.moreHorizontal,
            semanticLabel: AppLocalizations.of(context).spaceFolderActions,
            onPressed: onActions,
          ),
        ],
      ),
    );
  }
}

/// A space card with a separate move control for touch and assistive input.
class RemoteSpaceCard extends StatelessWidget {
  /// Creates a linked space row.
  const RemoteSpaceCard({
    required this.space,
    required this.workspaceId,
    required this.inFolder,
    required this.onMove,
    this.showMove = true,
    this.unread = false,
    this.needsInput = false,
    this.running = false,
    this.lastActivityAt,
    super.key,
  });

  /// The visible active space.
  final SpaceDto space;

  /// Explicit route scope; never infer it from the next active workspace.
  final String workspaceId;

  /// Indents the row when inside a folder.
  final bool inFolder;

  /// Opens the destination picker.
  final VoidCallback onMove;
  final bool showMove;
  final bool unread;
  final bool needsInput;
  final bool running;

  /// Server-computed newest message time, absent for an empty space.
  final DateTime? lastActivityAt;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CcCard(
        interactive: true,
        semanticLabel: space.name,
        onPressed: () => context.push(
          space.archivedAt == null
              ? remoteSpaceLocation(workspaceId: workspaceId, spaceId: space.id)
              : remoteWorkspaceLocation(
                  '/spaces/${Uri.encodeComponent(space.id)}/manage',
                  workspaceId,
                ),
        ),
        child: Row(
          children: [
            if (inFolder) const SizedBox(width: 12),
            Icon(AppIcons.hash, size: 18, color: t.fgSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    space.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: t.textPrimary,
                    ),
                  ),
                  if (lastActivityAt != null)
                    Text(
                      shortAgo(context, lastActivityAt),
                      style: TextStyle(fontSize: 12, color: t.textSecondary),
                    ),
                ],
              ),
            ),
            if (running)
              _SpaceSignal(
                icon: AppIcons.circleDot,
                label: AppLocalizations.of(context).mobileSpacesRunning,
                color: t.accent,
              ),
            if (needsInput)
              _SpaceSignal(
                icon: AppIcons.triangleAlert,
                label: AppLocalizations.of(context).mobileSpacesNeedsInput,
                color: t.fgSecondary,
              ),
            if (unread)
              _SpaceSignal(
                icon: AppIcons.circleDot,
                label: AppLocalizations.of(context).mobileSpacesUnread,
                color: t.fgSecondary,
              ),
            if (showMove)
              PhoneIconButton(
                icon: AppIcons.moreHorizontal,
                semanticLabel: AppLocalizations.of(context).moveSpaceToFolder,
                onPressed: onMove,
              ),
          ],
        ),
      ),
    );
  }
}

class _SpaceSignal extends StatelessWidget {
  const _SpaceSignal({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    child: Padding(
      padding: const EdgeInsetsDirectional.only(end: 8),
      child: Icon(icon, size: 16, color: color),
    ),
  );
}
