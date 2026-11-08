import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_menu.dart';
import 'package:control_center/features/desktop_app/presentation/tray/tray_panel_actions.dart';
import 'package:control_center/features/desktop_app/providers/tray_status_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/workspace_avatar.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Edge of the workspace's mark in the header: it spans the name and the
/// status line under it.
const double _avatarSize = 28;

/// Edge of a workspace's mark in the switcher's menu.
const double _menuAvatarSize = 20;

/// The panel's header: the workspace, its one line of status, and the
/// switcher behind both, as the title-bar chip is in the app.
///
/// A connection that is down replaces the status line with its tag: nothing
/// else in the panel is current until it is back.
class TrayPanelHeader extends ConsumerStatefulWidget {
  /// Creates a [TrayPanelHeader].
  const TrayPanelHeader({required this.status, super.key});

  /// What the header summarizes.
  final TrayStatus status;

  @override
  ConsumerState<TrayPanelHeader> createState() => _TrayPanelHeaderState();
}

class _TrayPanelHeaderState extends ConsumerState<TrayPanelHeader> {
  final CcOverlayController _menu = CcOverlayController();

  @override
  void dispose() {
    _menu.dispose();
    super.dispose();
  }

  void _switchTo(String id) {
    _menu.hide();
    if (id != ref.read(activeWorkspaceIdProvider)) {
      TrayPanelScope.of(context).switchWorkspace(id);
    }
  }

  void _manage() {
    _menu.hide();
    TrayPanelScope.of(context).openRoute(workspaceListRoute);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final display = ref.watch(activeWorkspaceDisplayProvider);
    final status = widget.status;
    final Widget mark = display == null
        ? SizedBox.square(
            dimension: _avatarSize,
            child: Center(
              child: Icon(AppIcons.menu, size: 18, color: t.textTertiary),
            ),
          )
        : WorkspaceAvatar(
            name: display.name,
            workspaceId: display.workspaceId,
            hasLogo: display.hasLogo,
            size: _avatarSize,
          );
    final identity = Row(
      children: [
        mark,
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                display?.name ?? l10n.selectWorkspace,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: display == null ? t.textTertiary : t.textPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              switch (status.connection) {
                TrayConnection.online => Text(
                  trayStatusSummary(status, l10n),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: t.textSecondary, fontSize: 12),
                ),
                TrayConnection.connecting => CcStatusTag(
                  label: l10n.trayStatusReconnecting,
                  tone: CcStatusTone.caution,
                ),
                TrayConnection.offline => CcStatusTag(
                  label: l10n.trayStatusOffline,
                  tone: CcStatusTone.negative,
                ),
              },
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Icon(AppIcons.chevronDown, size: 14, color: t.fgTertiary),
      ],
    );
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: CcPopover(
        controller: _menu,
        // The target is its own tappable (see the popover's note on it).
        toggleOnTargetTap: false,
        matchTargetWidth: true,
        targetAnchor: AlignmentDirectional.bottomStart,
        followerAnchor: AlignmentDirectional.topStart,
        offset: const Offset(0, AppSpacing.xs),
        semanticLabel: l10n.trayPanelSwitchWorkspace,
        overlayBuilder: (context, _) => _WorkspaceMenu(
          activeId: display?.workspaceId,
          onSwitch: _switchTo,
          onManage: _manage,
        ),
        target: CcTappable(
          onPressed: _menu.toggle,
          borderRadius: AppRadii.brSm,
          semanticLabel: l10n.trayPanelSwitchWorkspace,
          builder: (context, states) => DecoratedBox(
            decoration: BoxDecoration(
              color: states.contains(WidgetState.hovered)
                  ? t.hover
                  : t.hover.withValues(alpha: 0),
              borderRadius: AppRadii.brSm,
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.sm),
              child: identity,
            ),
          ),
        ),
      ),
    );
  }
}

/// The workspaces to switch to, then the way to the full list (where one is
/// added or edited) in the app. Scrolls when there are more than the panel
/// holds.
class _WorkspaceMenu extends ConsumerWidget {
  const _WorkspaceMenu({
    required this.activeId,
    required this.onSwitch,
    required this.onManage,
  });

  final String? activeId;
  final ValueChanged<String> onSwitch;
  final VoidCallback onManage;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final workspaces =
        ref.watch(workspacesProvider).value ?? const <Workspace>[];
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (workspaces.isNotEmpty) ...[
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final w in workspaces)
                    _WorkspaceTile(
                      key: ValueKey(w.id),
                      workspace: w,
                      active: w.id == activeId,
                      onTap: () => onSwitch(w.id),
                    ),
                ],
              ),
            ),
          ),
          const CcDivider(),
        ],
        CcTile(
          // In the avatars' column, so the label lines up with the names.
          leading: const SizedBox.square(
            dimension: _menuAvatarSize,
            child: Center(child: Icon(AppIcons.settings, size: 16)),
          ),
          title: l10n.manageWorkspaces,
          onTap: onManage,
        ),
      ],
    );
  }
}

/// One workspace; the active one in the chip's quiet neutral wash and check,
/// and choosing it again only closes the menu.
class _WorkspaceTile extends StatelessWidget {
  const _WorkspaceTile({
    required this.workspace,
    required this.active,
    required this.onTap,
    super.key,
  });

  final Workspace workspace;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final tile = CcTile(
      leading: WorkspaceAvatar(
        name: workspace.name,
        workspaceId: workspace.id,
        hasLogo: workspace.hasLogo,
        size: _menuAvatarSize,
      ),
      title: workspace.name,
      trailing: active ? const Icon(AppIcons.check, size: 14) : null,
      onTap: onTap,
    );
    if (!active) {
      return tile;
    }
    return DecoratedBox(
      decoration: BoxDecoration(color: t.hover, borderRadius: AppRadii.brSm),
      child: tile,
    );
  }
}
