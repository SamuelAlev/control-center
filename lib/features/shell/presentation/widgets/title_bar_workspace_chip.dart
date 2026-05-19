import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/workspaces/presentation/screens/workspace_list_screen.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/workspace_avatar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

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
    this.fontSize = 14,
    this.forcePlaceholder = false,
    this.iconOnly = false,
  });

  /// Diameter of the workspace avatar.
  final double avatarSize;

  /// Font size of the workspace name.
  final double fontSize;

  /// Renders the "select a workspace" placeholder even when a workspace is
  /// resolvable. Workspace-agnostic surfaces (the "Manage workspaces" page)
  /// set this: the persisted last-active id still resolves a workspace there,
  /// but no workspace is selected *on that route*, so the chip stays an
  /// invitation instead of showing the previously chosen one.
  final bool forcePlaceholder;

  /// Avatar-only rendering (no name, no caret) for the sidebar's collapsed
  /// rail. The switcher popover is unchanged — the avatar stays the target.
  final bool iconOnly;

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

  void _switchTo(String id) {
    // The URL is the source of truth for the active workspace, so switching is
    // a navigation into the target workspace's inbox.
    _controller.hide();
    context.go(inboxRoute(id));
  }

  Future<void> _add() async {
    _controller.hide();
    if (!mounted) {
      return;
    }
    final id = await showAddWorkspaceDialog(context);
    // Creating from the switcher means "switch to it" — the create provider
    // deliberately does NOT navigate (onboarding creates mid-flow and must
    // keep its remaining steps), so the switch intent lives here.
    if (id != null && mounted) {
      context.go(inboxRoute(id));
    }
  }

  void _manageAll() {
    _controller.hide();
    context.go(workspaceListRoute);
  }

  @override
  Widget build(BuildContext context) {
    // Display info resolves from a cold-start cache before the database stream
    // emits, so the chip shows the right workspace immediately instead of
    // flashing "no workspace" for the couple of seconds the DB takes to open.
    // [TitleBarWorkspaceChip.forcePlaceholder] skips all of it: the chip is
    // then an invitation to select, never a resolved workspace.
    final display = widget.forcePlaceholder
        ? null
        : ref.watch(activeWorkspaceDisplayProvider);
    final l10n = AppLocalizations.of(context);

    return CcPopover(
      controller: _controller,
      toggleOnTargetTap: false,
      // The workspace list and the active row are watched *inside* the overlay,
      // not in the chip's own build: the chip renders nothing but the display
      // info, so watching them here would rebuild the whole title-bar chip on
      // every workspaces-stream emission and pull two more derived providers
      // into its build.
      overlayBuilder: (context, _) => Consumer(
        builder: (context, ref, _) {
          final workspaces = ref.watch(workspacesProvider).value ?? const [];
          final active = widget.forcePlaceholder
              ? null
              : ref.watch(activeWorkspaceProvider);
          return ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 260, minWidth: 220),
            // Carbon-style menu: rows sit flush against the panel's edges —
            // no vertical insets at the top/bottom and no breathing room
            // around the divider (the panel's ClipRRect clips the corners).
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
                  leading: const Icon(AppIcons.plus, size: 16),
                  title: l10n.addWorkspaceEllipsis,
                  onTap: _add,
                ),
                if (workspaces.isNotEmpty)
                  CcTile(
                    leading: const Icon(AppIcons.settings, size: 16),
                    title: l10n.manageWorkspaces,
                    onTap: _manageAll,
                  ),
              ],
            ),
          );
        },
      ),
      target: _ChipButton(
        display: display,
        onTap: () => _controller.toggle(),
        avatarSize: widget.avatarSize,
        fontSize: widget.fontSize,
        iconOnly: widget.iconOnly,
      ),
    );
  }

  Widget _buildWorkspaceTile(Workspace w, bool isActive) {
    final tile = CcTile(
      key: ValueKey(w.id),
      // Same logo size as the closed chip — the popover reads as the chip
      // expanded, not a second, smaller treatment of the same identity.
      leading: WorkspaceAvatar(
        name: w.name,
        workspaceId: w.id,
        hasLogo: w.hasLogo,
        size: widget.avatarSize,
      ),
      title: w.name,
      trailing: isActive ? const Icon(AppIcons.check, size: 14) : null,
      onTap: () => _switchTo(w.id),
    );
    if (!isActive) {
      return tile;
    }
    // The active workspace reads as a quiet neutral wash (Carbon's
    // layer-selected), not the accent tint `CcTile.selected` paints — the
    // trailing check already carries the "current" signal and an orange
    // wash would shout a state that is ambient. The radius matches the
    // tile's own so the wash aligns with its hover/press shape.
    final tokens = context.designSystem;
    return Container(
      decoration: BoxDecoration(
        color: tokens?.hover ?? DesignSystemPalette.gray100,
        borderRadius: AppRadii.brSm,
      ),
      child: tile,
    );
  }
}

class _ChipButton extends StatelessWidget {
  const _ChipButton({
    required this.display,
    required this.onTap,
    this.avatarSize = 22,
    this.fontSize = 13,
    this.iconOnly = false,
  });

  final WorkspaceDisplay? display;
  final VoidCallback onTap;
  final double avatarSize;
  final double fontSize;

  /// Avatar-only rendering for the collapsed rail (see
  /// [TitleBarWorkspaceChip.iconOnly]).
  final bool iconOnly;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    final l10n = AppLocalizations.of(context);
    final fg = tokens?.textPrimary ?? DesignSystemPalette.gray900;
    final chevron = tokens?.fgTertiary ?? DesignSystemPalette.gray500;
    final hover = tokens?.hover ?? DesignSystemPalette.gray100;
    // With no active workspace (workspace-agnostic routes like "Manage
    // workspaces") the chip is an invitation, so it renders in the
    // placeholder tier instead of the primary ink a real workspace name gets.
    final placeholder = tokens?.textTertiary ?? DesignSystemPalette.gray500;

    // Placeholder state carries a 3-lines menu glyph instead of the dummy
    // avatar: there is no workspace to picture, only a list to open. The box
    // is pinned to the avatar's square: a height-only SizedBox would let the
    // Center child expand to the parent's full width and float the glyph.
    final Widget mark = display == null
        ? SizedBox(
            width: avatarSize,
            height: avatarSize,
            child: Center(
              child: Icon(
                AppIcons.menu,
                size: avatarSize * 0.64,
                color: placeholder,
              ),
            ),
          )
        : WorkspaceAvatar(
            name: display!.name,
            workspaceId: display!.workspaceId,
            hasLogo: display!.hasLogo,
            size: avatarSize,
          );

    if (iconOnly) {
      // The rail keeps the avatar at its full expanded size: its 4px
      // vertical / 1px horizontal padding puts the avatar at x=9/y=4 from
      // the header's content edge (the 38px-wide result fills the rail
      // content exactly, so centering changes nothing); the expanded chip
      // uses a 10px horizontal padding instead, so the mark glides 9px when
      // the sidebar toggles. The workspace name moves to a tooltip.
      return CcTooltip(
        message: display?.name ?? l10n.selectWorkspace,
        child: _HoverSurface(
          hoverColor: hover,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 1),
            child: mark,
          ),
        ),
      );
    }

    return _HoverSurface(
      hoverColor: hover,
      onTap: onTap,
      child: Padding(
        // 10px horizontal: the hover pill stays flush with the nav-item pills
        // below (both span the sidebar's content width), while the avatar's
        // left edge lands on the x=18 line the nav icons and the group-label
        // text ("WORKSPACE") share (8 sidebar inset + 10). The caret mirrors
        // the nav items' 10px trailing inset. The rail's iconOnly chip keeps
        // its own 1px padding (avatar center x=27), so the mark glides 9px
        // when the sidebar toggles.
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 10),
        // Full-width row (the chip fills the header's free width): the name
        // claims the space between logo and caret (Expanded ≈ the reference's
        // `ms-auto`), so the caret always lands at the trailing edge and a
        // long name ellipsizes instead of overflowing.
        child: Row(
          children: [
            mark,
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                display?.name ?? l10n.selectWorkspace,
                style: TextStyle(
                  fontSize: fontSize,
                  height: 1.2,
                  color: display == null ? placeholder : fg,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(AppIcons.chevronDown, size: 13, color: chevron),
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
            shape: const RoundedSuperellipseBorder(borderRadius: AppRadii.brSm),
          ),
          child: widget.child,
        ),
      ),
    );
  }
}
