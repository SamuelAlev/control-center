import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/presentation/screens/pr_preview_modal.dart';
import 'package:control_center/features/workspaces/providers/workspace_panel_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/workspace_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
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
              onForks: () => _showPrModal(context),
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
      loading: () => const Scaffold(body: Center(child: FCircularProgress())),
      error: (e, _) => Scaffold(body: Center(child: Text(l10n.failedWithError('$e')))),
    );
  }

  void _showPrModal(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (_) => PrPreviewModal(workspaceId: widget.workspaceId),
    );
  }

  Future<void> _confirmDelete(Workspace workspace) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(l10n.deleteWorkspace),
        body: Text(l10n.deleteWorkspaceConfirm(workspace.name)),
        actions: [
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                FButton(
                  onPress: () => Navigator.pop(ctx, false),
                  variant: FButtonVariant.outline,
                  mainAxisSize: MainAxisSize.min,
                  child: Text(l10n.cancel),
                ),
                const SizedBox(width: 8),
                FButton(
                  onPress: () => Navigator.pop(ctx, true),
                  variant: FButtonVariant.destructive,
                  mainAxisSize: MainAxisSize.min,
                  child: Text(l10n.delete),
                ),
              ],
            ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.errorDeletingWorkspace('$e'))),
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
                color: context.theme.colors.foreground,
              ),
            ),
          ),
          FButton(
            onPress: onToggleLiveSync,
            variant: liveSync
                ? FButtonVariant.secondary
                : FButtonVariant.outline,
            size: FButtonSizeVariant.sm,
            mainAxisSize: MainAxisSize.min,
            prefix: Icon(liveSync ? LucideIcons.zap : LucideIcons.zapOff),
            child: Text(l10n.liveSync),
          ),
          const SizedBox(width: 8),
          FButton(
            onPress: onLiveDiff,
            variant: FButtonVariant.outline,
            size: FButtonSizeVariant.sm,
            mainAxisSize: MainAxisSize.min,
            prefix: const Icon(LucideIcons.diff),
            child: Text(l10n.liveDiff),
          ),
          const SizedBox(width: 4),
          FButton(
            onPress: onForks,
            variant: FButtonVariant.outline,
            size: FButtonSizeVariant.sm,
            mainAxisSize: MainAxisSize.min,
            prefix: const Icon(LucideIcons.gitFork),
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

class _WorkspaceMoreMenuState extends State<_WorkspaceMoreMenu>
    with SingleTickerProviderStateMixin {
  late final FPopoverController _controller = FPopoverController(vsync: this);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return FPopoverMenu.tiles(
      control: FPopoverControl.managed(controller: _controller),
      menu: [
        FTileGroup(
          children: [
            FTile(
              prefix: const Icon(LucideIcons.trash2, size: 16),
              title: Text(l10n.deleteWorkspace),
              onPress: () {
                _controller.toggle();
                widget.onDelete();
              },
            ),
          ],
        ),
      ],
      child: FTooltip(
        tipBuilder: (_, _) => Text(l10n.more),
        child: FButton.icon(
          onPress: _controller.toggle,
          child: const Icon(LucideIcons.moreHorizontal, size: 16),
        ),
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
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: context.theme.colors.border)),
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
    final colors = context.theme.colors;
    final bg = active ? colors.secondary : Colors.transparent;
    final fg = active ? colors.foreground : colors.mutedForeground;
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
