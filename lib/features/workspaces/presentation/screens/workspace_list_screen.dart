import 'package:control_center/core/domain/entities/agent.dart';
import 'package:control_center/core/domain/entities/workspace.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/app_radii.dart';
import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/workspaces/presentation/widgets/add_workspace_form.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:control_center/shared/widgets/workspace_avatar.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:forui/forui.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Width below which the master/detail grid collapses to a single column.
const double _kWideBreakpoint = 900;

/// "Manage workspaces" — a master/detail settings surface.
///
/// The left rail lists every workspace; selecting one loads it into the
/// editor on the right (identity + danger zone). Edits are buffered as a
/// draft and committed through a sticky save bar, so the canvas rests calm
/// until there is something to save.
class WorkspaceListScreen extends ConsumerStatefulWidget {
  /// Creates the workspace management screen.
  const WorkspaceListScreen({super.key});

  @override
  ConsumerState<WorkspaceListScreen> createState() =>
      _WorkspaceListScreenState();
}

class _WorkspaceListScreenState extends ConsumerState<WorkspaceListScreen> {
  final _nameController = TextEditingController();

  /// Id of the workspace the user has selected to edit (selection intent).
  ///
  /// `_addWorkspace`/`_deleteWorkspace` set this ahead of the new workspace
  /// appearing in the stream, so it can point at a row whose data is not yet
  /// in the draft — [_loadedId] tracks what the draft actually holds.
  String? _editingId;

  /// Id of the workspace whose data currently populates the draft
  /// ([_nameController], [_originalName], [_originalLogoPath]).
  ///
  /// Kept distinct from [_editingId] so the build-time reconciler reloads the
  /// draft whenever the resolved workspace differs from what's loaded — even
  /// when [_editingId] was set directly (add/delete). Comparing against
  /// `_editingId` instead would skip the reload and leave the editing row
  /// rendering a stale draft name/logo over a different workspace.
  String? _loadedId;

  /// Snapshot of the loaded workspace, used for dirty-tracking + discard.
  String _originalName = '';
  String? _originalLogoPath;

  /// Newly-picked logo source path that hasn't been persisted yet.
  String? _pendingLogoSource;

  /// Whether the user cleared the logo in the current draft.
  bool _pendingLogoCleared = false;

  bool _saving = false;

  /// Guards programmatic [_nameController] writes so [_loadInto] (which can run
  /// during build) never triggers a `setState` mid-build.
  bool _suppressNameListener = false;

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_handleNameChanged);
  }

  void _handleNameChanged() {
    if (_suppressNameListener || !mounted) {
      return;
    }
    setState(() {});
  }

  @override
  void dispose() {
    _nameController.removeListener(_handleNameChanged);
    _nameController.dispose();
    super.dispose();
  }

  // ── draft helpers ─────────────────────────────────────────────────────

  /// Loads [w] into the editor draft. Safe to call during build (it never
  /// triggers `setState`); the name field rebuilds via the field's `onChange`.
  void _loadInto(Workspace w) {
    _editingId = w.id;
    _loadedId = w.id;
    _originalName = w.name;
    _originalLogoPath = w.logoPath;
    if (_nameController.text != w.name) {
      _suppressNameListener = true;
      _nameController.text = w.name;
      _suppressNameListener = false;
    }
    _pendingLogoSource = null;
    _pendingLogoCleared = false;
  }

  bool get _dirty {
    final name = _nameController.text.trim();
    final nameChanged = name.isNotEmpty && name != _originalName;
    final logoChanged = _pendingLogoSource != null ||
        (_pendingLogoCleared && (_originalLogoPath?.isNotEmpty ?? false));
    return nameChanged || logoChanged;
  }

  /// The logo path that should be previewed for the current draft.
  String? get _effectiveLogoPath {
    if (_pendingLogoCleared) {
      return null;
    }
    return _pendingLogoSource ?? _originalLogoPath;
  }

  Workspace? _resolve(List<Workspace> list, String? activeId) {
    if (list.isEmpty) {
      return null;
    }
    if (_editingId != null) {
      final found = _firstOrNull(list, (w) => w.id == _editingId);
      if (found != null) {
        return found;
      }
    }
    if (activeId != null) {
      final active = _firstOrNull(list, (w) => w.id == activeId);
      if (active != null) {
        return active;
      }
    }
    return list.first;
  }

  // ── actions ───────────────────────────────────────────────────────────

  Future<void> _selectWorkspace(Workspace w) async {
    if (w.id == _editingId) {
      return;
    }
    if (_dirty) {
      final ok = await _confirmDiscard(_originalName);
      if (ok != true || !mounted) {
        return;
      }
    }
    setState(() => _loadInto(w));
  }

  void _cycle(List<Workspace> list, int delta) {
    if (list.isEmpty) {
      return;
    }
    final idx = list.indexWhere((w) => w.id == _editingId);
    final base = idx < 0 ? 0 : idx;
    final raw = (base + delta) % list.length;
    _selectWorkspace(list[raw < 0 ? raw + list.length : raw]);
  }

  Future<void> _addWorkspace() async {
    final id = await showAddWorkspaceDialog(context);
    if (id != null && mounted) {
      setState(() => _editingId = id);
    }
  }

  Future<void> _pickLogo() async {
    final l10n = AppLocalizations.of(context);
    final typeGroup = XTypeGroup(
      label: l10n.images,
      extensions: const ['png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp'],
    );
    final file = await openFile(acceptedTypeGroups: [typeGroup]);
    if (file == null || !mounted) {
      return;
    }
    setState(() {
      _pendingLogoSource = file.path;
      _pendingLogoCleared = false;
    });
  }

  void _removeLogo() {
    setState(() {
      _pendingLogoSource = null;
      _pendingLogoCleared = true;
    });
  }

  void _discard(Workspace w) {
    setState(() => _loadInto(w));
  }

  Future<void> _save(Workspace w) async {
    final name = _nameController.text.trim();
    if (name.isEmpty || _saving) {
      return;
    }
    setState(() => _saving = true);
    final l10n = AppLocalizations.of(context);
    try {
      var removeLogo = false;
      String? logoPath = _originalLogoPath;
      if (_pendingLogoCleared) {
        removeLogo = true;
        logoPath = null;
      } else if (_pendingLogoSource != null) {
        logoPath = await ref
            .read(workspaceFilesystemPortProvider)
            .persistLogo(w.id, _pendingLogoSource!);
      }

      final updated = w.copyWith(
        name: name,
        logoPath: logoPath,
        removeLogoPath: removeLogo,
        updatedAt: DateTime.now(),
      );
      await ref.read(workspaceRepositoryProvider).upsert(updated);

      if (!mounted) {
        return;
      }
      setState(() {
        _saving = false;
        _loadInto(updated);
      });
      _toast(l10n.workspaceUpdated);
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      _toast(kDebugMode ? '$e' : l10n.failedToLoadWorkspaces);
    }
  }

  Future<bool?> _confirmDiscard(String name) {
    final l10n = AppLocalizations.of(context);
    return showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(l10n.unsavedChanges),
        body: Text(l10n.discardChangesQuestion(name)),
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
                  child: Text(l10n.discard),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWorkspace(Workspace w, List<Workspace> list) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showFDialog<bool>(
      context: context,
      builder: (ctx, style, animation) => FDialog(
        style: style,
        animation: animation,
        title: Text(l10n.deleteWorkspace),
        body: Text(l10n.deleteWorkspaceConfirm(w.name)),
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
      await ref.read(workspaceRepositoryProvider).delete(w.id);
      if (!mounted) {
        return;
      }
      // Move the editor to the next surviving workspace, if any.
      final next = _firstOrNull(list, (x) => x.id != w.id);
      setState(() => _editingId = next?.id);
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      _toast(l10n.errorDeletingWorkspace('$e'));
    }
  }

  void _toast(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger
      ?..clearSnackBars()
      ..showSnackBar(
        SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
      );
  }

  // ── build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final workspaces = ref.watch(workspacesProvider);
    final activeId = ref.watch(activeWorkspaceIdProvider);
    final l10n = AppLocalizations.of(context);
    final list = workspaces.value ?? const <Workspace>[];

    final editing = _resolve(list, activeId);
    // Reload the draft whenever the resolved workspace differs from what the
    // draft currently holds. Comparing against `_loadedId` (not `_editingId`)
    // is what makes add/delete refresh: those set `_editingId` directly, so an
    // `editing.id != _editingId` guard would wrongly skip the reload and leave
    // the editing row showing the previous workspace's name/logo.
    if (editing != null && editing.id != _loadedId) {
      _loadInto(editing);
    } else if (editing == null) {
      _editingId = null;
      _loadedId = null;
    }

    return ScopedShortcuts(
      scope: workspaceListRoute,
      bindings: {
        'ws.new': _addWorkspace,
        if (editing != null) ...{
          'ws.open': () => context.go(workspaceRoute(editing.id)),
          'ws.delete': () => _deleteWorkspace(editing, list),
        },
      },
      child: workspaces.when(
        data: (ws) {
          if (ws.isEmpty) {
            return EmptyState(
              message: l10n.noWorkspace,
              primaryAction: _addWorkspace,
              actionLabel: l10n.addWorkspace,
            );
          }
          final current = editing!;
          return CallbackShortcuts(
            bindings: {
              const SingleActivator(LogicalKeyboardKey.keyJ): () =>
                  _cycle(ws, 1),
              const SingleActivator(LogicalKeyboardKey.keyK): () =>
                  _cycle(ws, -1),
            },
            child: _Canvas(
              workspaces: ws,
              editing: current,
              activeId: activeId,
              onSelect: _selectWorkspace,
              onAdd: _addWorkspace,
              onDelete: (w) => _deleteWorkspace(w, ws),
              onPickLogo: _pickLogo,
              onRemoveLogo: _removeLogo,
              onDiscard: () => _discard(current),
              onSave: () => _save(current),
              nameController: _nameController,
              dirty: _dirty,
              saving: _saving,
              effectiveLogoPath: _effectiveLogoPath,
              draftName: _nameController.text,
            ),
          );
        },
        loading: () => const Center(child: FCircularProgress()),
        error: (e, _) => Center(
          child: Text(
            kDebugMode
                ? '${l10n.failedToLoadWorkspaces}: $e'
                : l10n.failedToLoadWorkspaces,
          ),
        ),
      ),
    );
  }
}

/// Scrolling canvas: page head + master/detail grid.
class _Canvas extends StatelessWidget {
  const _Canvas({
    required this.workspaces,
    required this.editing,
    required this.activeId,
    required this.onSelect,
    required this.onAdd,
    required this.onDelete,
    required this.onPickLogo,
    required this.onRemoveLogo,
    required this.onDiscard,
    required this.onSave,
    required this.nameController,
    required this.dirty,
    required this.saving,
    required this.effectiveLogoPath,
    required this.draftName,
  });

  final List<Workspace> workspaces;
  final Workspace editing;
  final String? activeId;
  final ValueChanged<Workspace> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<Workspace> onDelete;
  final VoidCallback onPickLogo;
  final VoidCallback onRemoveLogo;
  final VoidCallback onDiscard;
  final VoidCallback onSave;
  final TextEditingController nameController;
  final bool dirty;
  final bool saving;
  final String? effectiveLogoPath;
  final String draftName;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _kWideBreakpoint;
        final listPanel = _WorkspaceListPanel(
          workspaces: workspaces,
          editingId: editing.id,
          draftName: draftName,
          draftLogoPath: effectiveLogoPath,
          onSelect: onSelect,
          onAdd: onAdd,
        );
        final detail = _DetailColumn(
          editing: editing,
          onDelete: onDelete,
          onPickLogo: onPickLogo,
          onRemoveLogo: onRemoveLogo,
          onDiscard: onDiscard,
          onSave: onSave,
          nameController: nameController,
          dirty: dirty,
          saving: saving,
          effectiveLogoPath: effectiveLogoPath,
          draftName: draftName,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 80),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _PageHead(count: workspaces.length),
                  const SizedBox(height: 28),
                  if (wide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(width: 296, child: listPanel),
                        const SizedBox(width: 20),
                        Expanded(child: detail),
                      ],
                    )
                  else ...[
                    listPanel,
                    const SizedBox(height: 20),
                    detail,
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _PageHead extends StatelessWidget {
  const _PageHead({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem;
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final fg = ds?.fg ?? theme.colors.foreground;
    final muted = ds?.muted ?? theme.colors.mutedForeground;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _Eyebrow(label: l10n.workspaceSettings),
            const SizedBox(width: 12),
            Text(
              l10n.workspaceCount(count),
              style: AppFonts.code(
                textStyle: TextStyle(
                  fontSize: 12,
                  height: 1.4,
                  letterSpacing: 1.2,
                  color: muted.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          l10n.manageWorkspaces,
          style: TextStyle(
            fontSize: 40,
            height: 1.05,
            letterSpacing: -0.8,
            fontWeight: FontWeight.w600,
            color: fg,
          ),
        ),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Text(
            l10n.manageWorkspacesSubtitle,
            style: TextStyle(fontSize: 15, height: 1.5, color: muted),
          ),
        ),
      ],
    );
  }
}

class _Eyebrow extends StatelessWidget {
  const _Eyebrow({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem;
    final theme = context.theme;
    final accent = ds?.accent ?? theme.colors.primary;
    final muted = ds?.muted ?? theme.colors.mutedForeground;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 2,
          decoration: BoxDecoration(
            color: accent,
            borderRadius:
                const BorderRadius.all(Radius.circular(AppRadii.pill)),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          label.toUpperCase(),
          style: AppFonts.code(
            textStyle: TextStyle(
              fontSize: 12,
              height: 1.4,
              letterSpacing: 1.2,
              color: muted,
            ),
          ),
        ),
      ],
    );
  }
}

// ── left rail ────────────────────────────────────────────────────────────

class _WorkspaceListPanel extends StatelessWidget {
  const _WorkspaceListPanel({
    required this.workspaces,
    required this.editingId,
    required this.draftName,
    required this.draftLogoPath,
    required this.onSelect,
    required this.onAdd,
  });

  final List<Workspace> workspaces;
  final String editingId;
  final String draftName;
  final String? draftLogoPath;
  final ValueChanged<Workspace> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem;
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final panel = ds?.panel ?? theme.colors.card;
    final border = ds?.borderSecondary ?? theme.colors.border;
    final muted = ds?.muted ?? theme.colors.mutedForeground;
    final accent = ds?.accent ?? theme.colors.primary;

    return Container(
      decoration: ShapeDecoration(
        color: panel,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: border),
          borderRadius: AppRadii.brLg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(title: l10n.workspaces, count: '${workspaces.length}'),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                for (final w in workspaces)
                  _WorkspaceRow(
                    key: ValueKey(w.id),
                    workspace: w,
                    active: w.id == editingId,
                    displayName: w.id == editingId ? draftName : w.name,
                    displayLogoPath:
                        w.id == editingId ? draftLogoPath : w.logoPath,
                    onTap: () => onSelect(w),
                  ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: border)),
            ),
            padding: const EdgeInsets.all(8),
            child: FTappable.static(
              onPress: onAdd,
              focusedOutlineStyle: const FFocusedOutlineStyleDelta.context(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                child: Row(
                  children: [
                    Icon(LucideIcons.plus, size: 15, color: muted),
                    const SizedBox(width: 12),
                    Text(
                      l10n.addWorkspace,
                      style: TextStyle(fontSize: 13, color: muted),
                    ),
                    const Spacer(),
                    Icon(LucideIcons.cornerDownLeft, size: 13, color: accent
                        .withValues(alpha: 0)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WorkspaceRow extends ConsumerWidget {
  const _WorkspaceRow({
    super.key,
    required this.workspace,
    required this.active,
    required this.displayName,
    required this.displayLogoPath,
    required this.onTap,
  });

  final Workspace workspace;
  final bool active;
  final String displayName;
  final String? displayLogoPath;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.designSystem;
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final fg = ds?.fg ?? theme.colors.foreground;
    final muted = ds?.muted ?? theme.colors.mutedForeground;
    final surface = ds?.surface ?? theme.colors.secondary;

    final repos =
        ref.watch(reposForWorkspaceProvider(workspace.id)).value?.length ?? 0;
    final agents =
        ref.watch(workspaceAgentsProvider(workspace.id)).value?.length ?? 0;
    final name = displayName.trim().isEmpty ? l10n.noWorkspace : displayName;

    return FTappable.static(
      onPress: onTap,
      focusedOutlineStyle: const FFocusedOutlineStyleDelta.context(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        decoration: ShapeDecoration(
          color: active ? surface : Colors.transparent,
          shape: const RoundedSuperellipseBorder(
            borderRadius: AppRadii.brMd,
          ),
        ),
        padding: const EdgeInsets.fromLTRB(12, 9, 12, 9),
        child: Row(
          children: [
            WorkspaceAvatar(
              name: name,
              logoPath: displayLogoPath,
              size: 34,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 14, color: fg),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    l10n.workspaceReposAgents(repos, agents),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppFonts.code(
                      textStyle: TextStyle(
                        fontSize: 11,
                        height: 1.3,
                        color: muted,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── detail column ──────────────────────────────────────────────────────────

class _DetailColumn extends StatelessWidget {
  const _DetailColumn({
    required this.editing,
    required this.onDelete,
    required this.onPickLogo,
    required this.onRemoveLogo,
    required this.onDiscard,
    required this.onSave,
    required this.nameController,
    required this.dirty,
    required this.saving,
    required this.effectiveLogoPath,
    required this.draftName,
  });

  final Workspace editing;
  final ValueChanged<Workspace> onDelete;
  final VoidCallback onPickLogo;
  final VoidCallback onRemoveLogo;
  final VoidCallback onDiscard;
  final VoidCallback onSave;
  final TextEditingController nameController;
  final bool dirty;
  final bool saving;
  final String? effectiveLogoPath;
  final String draftName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _IdentityPanel(
          editing: editing,
          onPickLogo: onPickLogo,
          onRemoveLogo: onRemoveLogo,
          nameController: nameController,
          effectiveLogoPath: effectiveLogoPath,
          draftName: draftName,
        ),
        const SizedBox(height: 20),
        _DangerPanel(
          editing: editing,
          onDelete: () => onDelete(editing),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: dirty
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: _SaveBar(
                    saving: saving,
                    onDiscard: onDiscard,
                    onSave: nameController.text.trim().isEmpty ? null : onSave,
                    message: l10n.unsavedChanges,
                  ),
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

class _IdentityPanel extends StatelessWidget {
  const _IdentityPanel({
    required this.editing,
    required this.onPickLogo,
    required this.onRemoveLogo,
    required this.nameController,
    required this.effectiveLogoPath,
    required this.draftName,
  });

  final Workspace editing;
  final VoidCallback onPickLogo;
  final VoidCallback onRemoveLogo;
  final TextEditingController nameController;
  final String? effectiveLogoPath;
  final String draftName;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem;
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final panel = ds?.panel ?? theme.colors.card;
    final border = ds?.borderSecondary ?? theme.colors.border;
    final muted = ds?.muted ?? theme.colors.mutedForeground;
    final hasLogo = effectiveLogoPath != null && effectiveLogoPath!.isNotEmpty;

    return Container(
      decoration: ShapeDecoration(
        color: panel,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: border),
          borderRadius: AppRadii.brLg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            title: l10n.identity,
            trailing: FButton(
              onPress: () => context.go(workspaceRoute(editing.id)),
              variant: FButtonVariant.outline,
              mainAxisSize: MainAxisSize.min,
              prefix: const Icon(LucideIcons.externalLink, size: 14),
              child: Text(l10n.openLabel),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // logo editor
                Wrap(
                  spacing: 20,
                  runSpacing: 16,
                  crossAxisAlignment: WrapCrossAlignment.start,
                  children: [
                    WorkspaceAvatar(
                      name: draftName,
                      logoPath: effectiveLogoPath,
                      size: 88,
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(minWidth: 220),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              FButton(
                                onPress: onPickLogo,
                                variant: FButtonVariant.secondary,
                                mainAxisSize: MainAxisSize.min,
                                prefix:
                                    const Icon(LucideIcons.upload, size: 14),
                                child: Text(l10n.uploadImage),
                              ),
                              const SizedBox(width: 8),
                              FButton(
                                onPress: hasLogo ? onRemoveLogo : null,
                                variant: FButtonVariant.outline,
                                mainAxisSize: MainAxisSize.min,
                                child: Text(l10n.remove),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 320),
                            child: Text(
                              l10n.workspaceLogoHint,
                              style: TextStyle(
                                fontSize: 12,
                                height: 1.5,
                                color: muted,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                // name field
                FTextField(
                  control:
                      FTextFieldControl.managed(controller: nameController),
                  label: Text(l10n.workspaceName),
                  hint: l10n.egPlatform,
                  maxLength: 32,
                ),
                const SizedBox(height: 4),
                Text(
                  l10n.workspaceNameFieldHelp,
                  style: TextStyle(fontSize: 12, height: 1.5, color: muted),
                ),
                const SizedBox(height: 20),
                _FactsStrip(workspaceId: editing.id),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FactsStrip extends ConsumerWidget {
  const _FactsStrip({required this.workspaceId});

  final String workspaceId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.designSystem;
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final border = ds?.borderSecondary ?? theme.colors.border;

    final repos =
        ref.watch(reposForWorkspaceProvider(workspaceId)).value?.length ?? 0;
    final agents =
        ref.watch(workspaceAgentsProvider(workspaceId)).value ??
            const <Agent>[];
    final skills = agents
        .expand((a) => a.skills.toList().map((s) => s.toLowerCase()))
        .toSet()
        .length;

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: ShapeDecoration(
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: border),
          borderRadius: AppRadii.brMd,
        ),
      ),
      child: IntrinsicHeight(
        child: Row(
          children: [
            Expanded(
              child: _FactCell(value: '$repos', label: l10n.repositories),
            ),
            _FactDivider(color: border),
            Expanded(
              child: _FactCell(value: '${agents.length}', label: l10n.agents),
            ),
            _FactDivider(color: border),
            Expanded(child: _FactCell(value: '$skills', label: l10n.skills)),
          ],
        ),
      ),
    );
  }
}

class _FactDivider extends StatelessWidget {
  const _FactDivider({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) => Container(width: 1, color: color);
}

class _FactCell extends StatelessWidget {
  const _FactCell({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem;
    final theme = context.theme;
    final panel = ds?.panel ?? theme.colors.card;
    final fg = ds?.fg ?? theme.colors.foreground;
    final muted = ds?.muted ?? theme.colors.mutedForeground;

    return Container(
      color: panel,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            value,
            style: AppFonts.code(
              textStyle: TextStyle(fontSize: 22, height: 1, color: fg),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label.toUpperCase(),
            style: AppFonts.code(
              textStyle: TextStyle(
                fontSize: 11,
                height: 1.2,
                letterSpacing: 0.5,
                color: muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DangerPanel extends StatelessWidget {
  const _DangerPanel({required this.editing, required this.onDelete});

  final Workspace editing;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem;
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final panel = ds?.panel ?? theme.colors.card;
    final baseBorder = ds?.borderSecondary ?? theme.colors.border;
    final danger = ds?.danger ?? theme.colors.error;
    final muted = ds?.muted ?? theme.colors.mutedForeground;
    final border = Color.lerp(baseBorder, danger, 0.45) ?? baseBorder;

    return Container(
      decoration: ShapeDecoration(
        color: panel,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: border),
          borderRadius: AppRadii.brLg,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _PanelHeader(
            title: l10n.dangerZone,
            titleColor: danger,
            borderColor: border,
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Wrap(
              spacing: 16,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        l10n.deleteThisWorkspace,
                        style: TextStyle(
                          fontSize: 14,
                          color: ds?.fg ?? theme.colors.foreground,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        l10n.deleteWorkspaceLongDescription(editing.name),
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.5,
                          color: muted,
                        ),
                      ),
                    ],
                  ),
                ),
                FButton(
                  onPress: onDelete,
                  variant: FButtonVariant.destructive,
                  mainAxisSize: MainAxisSize.min,
                  prefix: const Icon(LucideIcons.trash2, size: 14),
                  child: Text(l10n.deleteWorkspace),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SaveBar extends StatelessWidget {
  const _SaveBar({
    required this.saving,
    required this.onDiscard,
    required this.onSave,
    required this.message,
  });

  final bool saving;
  final VoidCallback onDiscard;
  final VoidCallback? onSave;
  final String message;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem;
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    final panel = ds?.panel ?? theme.colors.card;
    final border = ds?.borderSecondary ?? theme.colors.border;
    final fg = ds?.fg ?? theme.colors.foreground;
    final accent = ds?.accent ?? theme.colors.primary;

    return Container(
      decoration: ShapeDecoration(
        color: panel,
        shape: RoundedSuperellipseBorder(
          side: BorderSide(color: border),
          borderRadius: AppRadii.brLg,
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Text(message, style: TextStyle(fontSize: 13, color: fg)),
          const Spacer(),
          FButton(
            onPress: saving ? null : onDiscard,
            variant: FButtonVariant.outline,
            mainAxisSize: MainAxisSize.min,
            child: Text(l10n.discard),
          ),
          const SizedBox(width: 8),
          FButton(
            onPress: saving ? null : onSave,
            mainAxisSize: MainAxisSize.min,
            child: Text(saving ? '${l10n.saveChanges}…' : l10n.saveChanges),
          ),
        ],
      ),
    );
  }
}

// ── shared bits ────────────────────────────────────────────────────────────

/// Header row for a panel: title on the left, an optional mono [count] and/or
/// [trailing] widget on the right, with a bottom hairline.
class _PanelHeader extends StatelessWidget {
  const _PanelHeader({
    required this.title,
    this.count,
    this.trailing,
    this.titleColor,
    this.borderColor,
  });

  final String title;
  final String? count;
  final Widget? trailing;
  final Color? titleColor;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem;
    final theme = context.theme;
    final fg = titleColor ?? ds?.fg ?? theme.colors.foreground;
    final muted = ds?.muted ?? theme.colors.mutedForeground;
    final border = borderColor ?? ds?.borderSecondary ?? theme.colors.border;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 12, 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                fontSize: 16,
                height: 1.4,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
            ),
          ),
          if (count != null)
            Text(
              count!,
              style: AppFonts.code(
                textStyle: TextStyle(fontSize: 12, color: muted),
              ),
            ),
          ?trailing,
        ],
      ),
    );
  }
}

/// Shows the add-workspace dialog.
///
/// Returns the new workspace id when one is created, or null when cancelled.
Future<String?> showAddWorkspaceDialog(BuildContext context) {
  final l10n = AppLocalizations.of(context);
  return showFDialog<String?>(
    context: context,
    builder: (dialogContext, style, animation) => FDialog(
      style: style,
      animation: animation,
      title: Text(l10n.addWorkspace),
      body: SizedBox(
        width: 420,
        child: AddWorkspaceForm(
          onCreated: (id) => Navigator.pop(dialogContext, id),
          onCancel: () => Navigator.pop(dialogContext),
        ),
      ),
      actions: const [],
    ),
  );
}

T? _firstOrNull<T>(List<T> list, bool Function(T) test) {
  for (final item in list) {
    if (test(item)) {
      return item;
    }
  }
  return null;
}
