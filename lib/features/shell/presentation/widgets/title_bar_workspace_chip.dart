import 'dart:async';

import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/presentation/screens/workspace_list_screen.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/workspace_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Active title-bar chip controller, exposed so the `sys.workspace-switcher`
/// keybinding can toggle the popover from outside the widget tree.
FPopoverController? _activeChipController;

/// Toggles the workspace switcher popover on the title-bar chip. No-op if
/// the chip isn't currently mounted.
void toggleWorkspaceSwitcher(BuildContext rootContext) {
  final controller = _activeChipController;
  if (controller == null) {
    return;
  }
  unawaited(controller.toggle());
}

/// Compact workspace selector designed for the 40px title bar.
///
/// Renders the active workspace as a 22px avatar + name + chevron, opening
/// an [FPopoverMenu] of workspaces (switch / add / manage).
class TitleBarWorkspaceChip extends ConsumerStatefulWidget {
  /// Creates a [TitleBarWorkspaceChip].
  const TitleBarWorkspaceChip({
    super.key,
    this.avatarSize = 22,
    this.fontSize = 13,
  });

  /// Diameter of the workspace avatar.
  final double avatarSize;

  /// Font size of the workspace name.
  final double fontSize;

  @override
  ConsumerState<TitleBarWorkspaceChip> createState() =>
      _TitleBarWorkspaceChipState();
}

class _TitleBarWorkspaceChipState extends ConsumerState<TitleBarWorkspaceChip>
    with SingleTickerProviderStateMixin {
  late final FPopoverController _controller;

  @override
  void initState() {
    super.initState();
    _controller = FPopoverController(vsync: this);
    _activeChipController = _controller;
  }

  @override
  void dispose() {
    if (identical(_activeChipController, _controller)) {
      _activeChipController = null;
    }
    _controller.dispose();
    super.dispose();
  }

  Future<void> _switchTo(String id) async {
    await ref.read(activeWorkspaceIdProvider.notifier).setActive(id);
    await _controller.hide();
  }

  Future<void> _add() async {
    await _controller.hide();
    if (!mounted) {
      return;
    }
    await showAddWorkspaceDialog(context);
  }

  Future<void> _manageAll() async {
    await _controller.hide();
    if (!mounted) {
      return;
    }
    context.go(workspaceListRoute);
  }

  @override
  Widget build(BuildContext context) {
    final workspaces = ref.watch(workspacesProvider).value ?? const [];
    final active = ref.watch(activeWorkspaceProvider);
    final l10n = AppLocalizations.of(context);

    return FPopoverMenu.tiles(
      control: FPopoverControl.managed(controller: _controller),
      style: const FPopoverMenuStyleDelta.delta(maxWidth: 260),
      divider: FItemDivider.none,
      menu: [
        if (workspaces.isNotEmpty)
          FTileGroup(
            children: [
              for (final w in workspaces)
                _buildWorkspaceTile(w, active?.id == w.id),
            ],
          ),
        FTileGroup(
          children: [
            FTile(
              prefix: const Icon(LucideIcons.plus, size: 16),
              title: Text(l10n.addWorkspaceEllipsis),
              onPress: _add,
            ),
            if (workspaces.isNotEmpty)
              FTile(
                prefix: const Icon(LucideIcons.settings, size: 16),
                title: Text(l10n.manageWorkspaces),
                onPress: _manageAll,
              ),
          ],
        ),
      ],
      child: _ChipButton(
        active: active,
        onTap: () => _controller.toggle(),
        avatarSize: widget.avatarSize,
        fontSize: widget.fontSize,
      ),
    );
  }

  FTile _buildWorkspaceTile(Workspace w, bool isActive) {
    return FTile(
      key: ValueKey(w.id),
      prefix: WorkspaceAvatar(name: w.name, logoPath: w.logoPath, size: 24),
      title: Text(w.name),
      subtitle: Consumer(
        builder: (context, ref, _) {
          final repos = ref.watch(reposForWorkspaceProvider(w.id)).value ?? const [];
          if (repos.isEmpty) {
            return const SizedBox.shrink();
          }
          return Text(
            repos.length == 1 ? repos.first.name : '${repos.length} repos',
          );
        },
      ),
      suffix: isActive
          ? const Icon(LucideIcons.check, size: 14)
          : null,
      selected: isActive,
      onPress: () => _switchTo(w.id),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.active,
    required this.onTap,
    this.avatarSize = 22,
    this.fontSize = 13,
  });

  final Workspace? active;
  final VoidCallback onTap;
  final double avatarSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final fTheme = FTheme.of(context);
    final l10n = AppLocalizations.of(context);
    final fg = tokens?.textPrimary ?? fTheme.colors.foreground;
    final chevron = tokens?.fgTertiary ?? fTheme.colors.mutedForeground;
    final hover = tokens?.bgSecondary ?? fTheme.colors.secondary;

    return _HoverSurface(
      hoverColor: hover,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WorkspaceAvatar(
              name: active?.name,
              logoPath: active?.logoPath,
              size: avatarSize,
            ),
            const SizedBox(width: 8),
            // Flexible so a long workspace name ellipsizes within the
            // available width (the chip now shares a row with the search and
            // new-ticket actions) rather than overflowing.
            Flexible(
              child: Text(
                active?.name ?? l10n.noWorkspace,
                style: TextStyle(
                  fontSize: fontSize,
                  height: 1.2,
                  fontWeight: FontWeight.w600,
                  color: fg,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: 4),
            Icon(LucideIcons.chevronDown, size: 13, color: chevron),
          ],
        ),
      ),
    );
  }
}

class _HoverSurface extends StatefulWidget {
  const _HoverSurface({
    required this.hoverColor,
    required this.onTap,
    required this.child,
  });

  final Color hoverColor;
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_HoverSurface> createState() => _HoverSurfaceState();
}

class _HoverSurfaceState extends State<_HoverSurface> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
          decoration: ShapeDecoration(
            color: _hover
                ? widget.hoverColor
                : widget.hoverColor.withValues(alpha: 0),
            shape: const RoundedSuperellipseBorder(
              borderRadius: AppRadii.brSm,
            ),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}

