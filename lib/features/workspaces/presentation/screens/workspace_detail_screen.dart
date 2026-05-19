import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_panel_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/workspace_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Workspace detail screen with a split-pane workspace view.
class WorkspaceDetailScreen extends ConsumerStatefulWidget {
  /// Creates a workspace detail screen.
  const WorkspaceDetailScreen({super.key, required this.workspaceId});

  /// The workspace to display.
  final String workspaceId;

  @override
  ConsumerState<WorkspaceDetailScreen> createState() =>
      _WorkspaceDetailScreenState();
}

class _WorkspaceDetailScreenState extends ConsumerState<WorkspaceDetailScreen> {
  int _tab = 0;
  bool _liveSync = true;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final workspaceAsync = ref.watch(
      workspaceDetailProvider(widget.workspaceId),
    );
    final panels = ref.watch(workspacePanelRegistryProvider);

    return workspaceAsync.when(
      data: (workspace) {
        if (workspace == null) {
          return Center(child: Text(l10n.workspaceNotFound));
        }
        return Column(
          children: [
            _WorkspaceHeader(
              title: l10n.workspaceTitle(workspace.name),
              liveSync: _liveSync,
              onToggleLiveSync: () => setState(() => _liveSync = !_liveSync),
              onLiveDiff: () => setState(() => _tab = 2),
              onForks: () => GoRouter.of(context).go(pullRequestsComposeRoute),
              onDelete: () => _confirmDelete(workspace),
            ),
            _WorkspaceTabBar(
              panels: panels,
              activeIndex: _tab,
              onChanged: (i) => setState(() => _tab = i),
            ),
            Expanded(
              child: IndexedStack(
                index: _tab,
                children: [
                  for (final panel in panels) panel.builder(widget.workspaceId),
                ],
              ),
            ),
          ],
        );
      },
      loading: () => const Scaffold(body: Center(child: CcSpinner())),
      error: (e, _) => Scaffold(body: Center(child: Text(l10n.failedWithError('$e')))),
    );
  }

  Future<void> _confirmDelete(Workspace workspace) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.deleteWorkspace,
        content: Text(l10n.deleteWorkspaceConfirm(workspace.name)),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(ctx, false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(ctx, true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.delete),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) {
      return;
    }
    try {
      await ref.read(workspaceRepositoryProvider).delete(workspace.id);
      if (!mounted) {
        return;
      }
      context.go(workspaceListRoute);
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      CcToastScope.of(context).show(
        l10n.errorDeletingWorkspace('$e'),
        variant: CcToastVariant.danger,
      );
    }
  }
}

// ─── Header (title + actions) ──────────────────────────────────────────────────

class _WorkspaceHeader extends StatelessWidget {
  const _WorkspaceHeader({
    required this.title,
    required this.liveSync,
    required this.onToggleLiveSync,
    required this.onLiveDiff,
    required this.onForks,
    required this.onDelete,
  });

  final String title;
  final bool liveSync;
  final VoidCallback onToggleLiveSync;
  final VoidCallback onLiveDiff;
  final VoidCallback onForks;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w700,
                color: (context.designSystem ?? DesignSystemTokens.light())
                    .textPrimary,
              ),
            ),
          ),
          CcButton(
            onPressed: onToggleLiveSync,
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            icon: liveSync ? LucideIcons.zap : LucideIcons.zapOff,
            child: Text(l10n.liveSync),
          ),
          const SizedBox(width: 8),
          CcButton(
            onPressed: onLiveDiff,
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            icon: LucideIcons.diff,
            child: Text(l10n.liveDiff),
          ),
          const SizedBox(width: 4),
          CcButton(
            onPressed: onForks,
            variant: CcButtonVariant.secondary,
            size: CcButtonSize.sm,
            icon: LucideIcons.gitFork,
            child: Text(l10n.forks),
          ),
          const SizedBox(width: 4),
          _WorkspaceMoreMenu(onDelete: onDelete),
        ],
      ),
    );
  }
}

/// The header's "More" button — a popover menu with workspace-level actions.
class _WorkspaceMoreMenu extends StatefulWidget {
  const _WorkspaceMoreMenu({required this.onDelete});

  final VoidCallback onDelete;

  @override
  State<_WorkspaceMoreMenu> createState() => _WorkspaceMoreMenuState();
}

class _WorkspaceMoreMenuState extends State<_WorkspaceMoreMenu> {
  final CcOverlayController _controller = CcOverlayController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return CcPopover(
      controller: _controller,
      toggleOnTargetTap: false,
      targetAnchor: Alignment.bottomRight,
      followerAnchor: Alignment.topRight,
      overlayBuilder: (context, _) => ConstrainedBox(
        constraints: const BoxConstraints(minWidth: 180),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: CcTile(
            leading: const Icon(LucideIcons.trash2, size: 16),
            title: Text(l10n.deleteWorkspace),
            onTap: () {
              _controller.hide();
              widget.onDelete();
            },
          ),
        ),
      ),
      target: CcIconButton(
        icon: LucideIcons.moreHorizontal,
        tooltip: l10n.more,
        onPressed: _controller.toggle,
      ),
    );
  }
}

// ─── Tab bar ───────────────────────────────────────────────────────────────────

class _WorkspaceTabBar extends StatelessWidget {
  const _WorkspaceTabBar({
    required this.panels,
    required this.activeIndex,
    required this.onChanged,
  });

  final List<WorkspacePanel> panels;
  final int activeIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: ds.borderSecondary)),
      ),
      child: Row(
        children: [
          for (var i = 0; i < panels.length; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            _TabChip(
              label: panels[i].label,
              icon: panels[i].icon,
              active: activeIndex == i,
              onTap: () => onChanged(i),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  const _TabChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final bg = active ? ds.bgSecondary : Colors.transparent;
    final fg = active ? ds.textPrimary : ds.textTertiary;
    return Material(
      color: bg,
      borderRadius: AppRadii.brSm,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadii.brSm,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 14, color: fg),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: fg,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
