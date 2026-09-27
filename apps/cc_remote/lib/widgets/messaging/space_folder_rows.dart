import 'package:cc_domain/cc_domain.dart';
import 'package:cc_remote/app_icons.dart';
import 'package:cc_remote/l10n/app_localizations.dart';
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
    required this.inFolder,
    required this.onMove,
    super.key,
  });

  /// The visible active space.
  final SpaceDto space;

  /// Indents the row when inside a folder.
  final bool inFolder;

  /// Opens the destination picker.
  final VoidCallback onMove;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: CcCard(
        interactive: true,
        semanticLabel: space.name,
        onPressed: () => context.push('/spaces/${space.id}'),
        child: Row(
          children: [
            if (inFolder) const SizedBox(width: 12),
            Icon(AppIcons.hash, size: 18, color: t.fgSecondary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                space.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: t.textPrimary,
                ),
              ),
            ),
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
