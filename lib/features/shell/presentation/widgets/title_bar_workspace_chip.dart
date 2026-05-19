import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/presentation/screens/workspace_list_screen.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/workspace_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Active title-bar chip controller, exposed so the `sys.workspace-switcher`
/// keybinding can toggle the popover from outside the widget tree.
CcOverlayController? _activeChipController;

/// Toggles the workspace switcher popover on the title-bar chip. No-op if
/// the chip isn't currently mounted.
void toggleWorkspaceSwitcher(BuildContext rootContext) {
  final controller = _activeChipController;
  if (controller == null) {
    return;
  }
  controller.toggle();
}

/// Compact workspace selector designed for the 40px title bar.
///
/// Renders the active workspace as a 22px avatar + name + chevron, opening
/// a [CcPopover] of workspaces (switch / add / manage).
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

class _TitleBarWorkspaceChipState extends ConsumerState<TitleBarWorkspaceChip> {
  late final CcOverlayController _controller;

  @override
  void initState() {
    super.initState();
    _controller = CcOverlayController();
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
    _controller.hide();
  }

  Future<void> _add() async {
    _controller.hide();
    if (!mounted) {
      return;
    }
    await showAddWorkspaceDialog(context);
  }

  void _manageAll() {
    _controller.hide();
    context.go(workspaceListRoute);
  }

  @override
  Widget build(BuildContext context) {
    final workspaces = ref.watch(workspacesProvider).value ?? const [];
    final active = ref.watch(activeWorkspaceProvider);
    // Display info resolves from a cold-start cache before the database stream
    // emits, so the chip shows the right workspace immediately instead of
    // flashing "no workspace" for the couple of seconds the DB takes to open.
    final display = ref.watch(activeWorkspaceDisplayProvider);
    final l10n = AppLocalizations.of(context);

    return CcPopover(
      controller: _controller,
      toggleOnTargetTap: false,
      overlayBuilder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260, minWidth: 220),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (workspaces.isNotEmpty) ...[
                for (final w in workspaces)
                  _buildWorkspaceTile(w, active?.id == w.id),
                const CcDivider(),
              ],
              CcTile(
                leading: const Icon(LucideIcons.plus, size: 16),
                title: Text(l10n.addWorkspaceEllipsis),
                onTap: _add,
              ),
              if (workspaces.isNotEmpty)
                CcTile(
                  leading: const Icon(LucideIcons.settings, size: 16),
                  title: Text(l10n.manageWorkspaces),
                  onTap: _manageAll,
                ),
            ],
          ),
        ),
      ),
      target: _ChipButton(
        display: display,
        onTap: () => _controller.toggle(),
        avatarSize: widget.avatarSize,
        fontSize: widget.fontSize,
      ),
    );
  }

  Widget _buildWorkspaceTile(Workspace w, bool isActive) {
    return CcTile(
      key: ValueKey(w.id),
      leading: WorkspaceAvatar(name: w.name, logoPath: w.logoPath, size: 24),
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
      trailing: isActive
          ? const Icon(LucideIcons.check, size: 14)
          : null,
      selected: isActive,
      onTap: () => _switchTo(w.id),
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.display,
    required this.onTap,
    this.avatarSize = 22,
    this.fontSize = 13,
  });

  final WorkspaceDisplay? display;
  final VoidCallback onTap;
  final double avatarSize;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    final fg = tokens?.textPrimary ?? DesignSystemPalette.gray900;
    final chevron = tokens?.fgTertiary ?? DesignSystemPalette.gray500;
    final hover = tokens?.hover ?? DesignSystemPalette.gray100;

    return _HoverSurface(
      hoverColor: hover,
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            WorkspaceAvatar(
              name: display?.name,
              logoPath: display?.logoPath,
              size: avatarSize,
            ),
            const SizedBox(width: 8),
            // Flexible so a long workspace name ellipsizes within the
            // available width (the chip now shares a row with the search and
            // new-ticket actions) rather than overflowing.
            Flexible(
              child: Text(
                display?.name ?? l10n.noWorkspace,
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

