import 'package:cc_domain/core/domain/entities/agent.dart';
import 'package:cc_domain/core/domain/entities/workspace.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/agents/providers/agent_providers.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/features/shell/presentation/layout/shell_title_bar.dart';
import 'package:control_center/features/shell/presentation/widgets/app_sidebar_header.dart';
import 'package:control_center/features/workspaces/presentation/widgets/add_workspace_form.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/router/routes.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/empty_state.dart';
import 'package:control_center/shared/widgets/mouse_navigation_handler.dart';
import 'package:control_center/shared/widgets/page_wrapper.dart';
import 'package:control_center/shared/widgets/scoped_shortcuts.dart';
import 'package:control_center/shared/widgets/workspace_avatar.dart';
import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:path/path.dart' as p;

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

  /// Newly-picked logo bytes that haven't been persisted yet. Bytes (not a
  /// path) so the same flow works on web, where the picked file has no
  /// readable local path.
  Uint8List? _pendingLogoBytes;

  /// Extension (with leading dot, e.g. `.png`) of [_pendingLogoBytes].
  String _pendingLogoExt = '';

  /// Whether the user cleared the logo in the current draft.
  bool _pendingLogoCleared = false;

  bool _saving = false;

  /// Optimistic workspace order (ids) from the last local reorder, so the
  /// dragged row stays put while the write lands. Null until the user reorders.
  List<String>? _pendingOrder;

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
    _pendingLogoBytes = null;
    _pendingLogoExt = '';
    _pendingLogoCleared = false;
  }

  bool get _dirty {
    final name = _nameController.text.trim();
    final nameChanged = name.isNotEmpty && name != _originalName;
    final logoChanged =
        _pendingLogoBytes != null ||
        (_pendingLogoCleared && (_originalLogoPath?.isNotEmpty ?? false));
    return nameChanged || logoChanged;
  }

  /// The committed logo path that should be previewed for the current draft
  /// (null when the user cleared the logo).
  String? get _committedLogoPath =>
      _pendingLogoCleared ? null : _originalLogoPath;

  /// The freshly-picked logo bytes to preview before save, if any.
  Uint8List? get _previewLogoBytes =>
      _pendingLogoCleared ? null : _pendingLogoBytes;

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

  // ── ordering ──────────────────────────────────────────────────────────

  /// The order to render: the optimistic local order from the last drag,
  /// reconciled against the server list.
  ///
  /// Falls back to the server order whenever the SET of workspaces changed (one
  /// added or deleted, here or on another client) — the pending ids no longer
  /// describe this list, so honoring them would drop or duplicate a row. After
  /// a reorder round-trips, the two agree and this is a no-op.
  List<Workspace> _ordered(List<Workspace> list) {
    final pending = _pendingOrder;
    if (pending == null || pending.length != list.length) {
      return list;
    }
    final byId = {for (final w in list) w.id: w};
    final ordered = <Workspace>[];
    for (final id in pending) {
      final w = byId.remove(id);
      if (w == null) {
        return list;
      }
      ordered.add(w);
    }
    return ordered;
  }

  /// Persists a move within [ordered]. [newIndex] follows
  /// [ReorderableListView.onReorderItem]'s convention: it is already adjusted
  /// for the item removed at [oldIndex], so there is no `newIndex -= 1` dance.
  /// The written sequence is the app-wide workspace order (switcher popover,
  /// phone picker, every list) — the server owns it, like repo positions.
  void _reorder(List<Workspace> ordered, int oldIndex, int newIndex) {
    if (oldIndex == newIndex) {
      return;
    }
    final ids = [for (final w in ordered) w.id];
    final moved = ids.removeAt(oldIndex);
    ids.insert(newIndex, moved);
    setState(() => _pendingOrder = ids);
    ref.read(workspaceRepositoryProvider).reorderWorkspaces(ids);
  }

  /// Moves the selected workspace by [delta] (⌥↑ / ⌥↓). The drag handle is
  /// pointer-only, so this keeps the manual order reachable from the keyboard.
  void _moveSelected(List<Workspace> ordered, int delta) {
    final from = ordered.indexWhere((w) => w.id == _editingId);
    if (from < 0) {
      return;
    }
    final to = from + delta;
    if (to < 0 || to >= ordered.length) {
      return;
    }
    _reorder(ordered, from, to);
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
      // Stay in the picker and open the new workspace for editing (name,
      // logo, repo links) — creating must not navigate (the create provider
      // is shared with onboarding, which still has steps after the
      // workspace one).
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
    // Read bytes + derive the extension from the file NAME (not its path): on
    // web the picked file has no usable path, but it always has a name.
    final bytes = await file.readAsBytes();
    final ext = p.extension(file.name).toLowerCase();
    setState(() {
      _pendingLogoBytes = bytes;
      _pendingLogoExt = ext;
      _pendingLogoCleared = false;
    });
  }

  void _removeLogo() {
    setState(() {
      _pendingLogoBytes = null;
      _pendingLogoExt = '';
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
      } else if (_pendingLogoBytes != null) {
        logoPath = await ref
            .read(workspaceFilesystemPortProvider)
            .persistLogoBytes(w.id, _pendingLogoBytes!, _pendingLogoExt);
        if (logoPath == null) {
          // persistLogoBytes returns null only when given empty bytes — i.e.
          // the picked image could not be read. Surface it instead of silently
          // saving with no logo.
          throw StateError('Could not read the selected logo image.');
        }
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
      _toast(l10n.workspaceUpdated, variant: CcToastVariant.success);
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      setState(() => _saving = false);
      _toast(
        kDebugMode ? '$e' : l10n.failedToSaveLogo,
        variant: CcToastVariant.danger,
      );
    }
  }

  Future<bool?> _confirmDiscard(String name) {
    final l10n = AppLocalizations.of(context);
    return showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.unsavedChanges,
        content: Text(l10n.discardChangesQuestion(name)),
        actions: [
          CcButton(
            onPressed: () => Navigator.pop(ctx, false),
            variant: CcButtonVariant.secondary,
            child: Text(l10n.cancel),
          ),
          CcButton(
            onPressed: () => Navigator.pop(ctx, true),
            variant: CcButtonVariant.destructive,
            child: Text(l10n.discard),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteWorkspace(Workspace w, List<Workspace> list) async {
    final l10n = AppLocalizations.of(context);
    final confirmed = await showCcDialog<bool>(
      context: context,
      builder: (ctx) => CcDialog(
        title: l10n.deleteWorkspace,
        content: Text(l10n.deleteWorkspaceConfirm(w.name)),
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
      _toast(l10n.errorDeletingWorkspace('$e'), variant: CcToastVariant.danger);
    }
  }

  void _toast(
    String message, {
    CcToastVariant variant = CcToastVariant.neutral,
  }) {
    CcToastScope.of(context).show(message, variant: variant);
  }

  // ── build ─────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final workspaces = ref.watch(workspacesProvider);
    final activeId = ref.watch(activeWorkspaceIdProvider);
    final l10n = AppLocalizations.of(context);
    // The stream already carries the persisted manual order; `_ordered` only
    // layers the in-flight drag on top of it.
    final list = _ordered(workspaces.value ?? const <Workspace>[]);

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

    // This is a pre-context route, rendered OUTSIDE the workspace shell, so —
    // unlike in-shell screens — there is no `ControlCenterLayout` Scaffold above
    // it to install a usable `DefaultTextStyle`. Wrap in our own Scaffold (as
    // the other off-shell routes, onboarding and splash, do) so raw `Text`
    // descendants don't fall back to WidgetsApp's error style (the giant
    // double-yellow-underlined text).
    // Workspace-agnostic surface: render the global sidebar with no nav items
    // inside. Its header's workspace switcher has no active workspace here, so
    // it shows the "select a workspace" placeholder invitation.
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final historyNotifier = ref.read(navigationHistoryProvider.notifier);
    final navState = ref.watch(navigationHistoryProvider);
    return Scaffold(
      backgroundColor: tokens.bgPrimary,
      body: ScopedShortcuts(
        scope: workspaceListRoute,
        bindings: {
          'ws.new': _addWorkspace,
          if (editing != null) ...{
            'ws.open': () => context.go(inboxRoute(editing.id)),
            'ws.delete': () => _deleteWorkspace(editing, list),
          },
        },
        child: Column(
          children: [
            // The same full-width 40px top bar the workspace shell carries
            // (its bottom hairline spans the window and on macOS its content
            // clears the traffic lights): back/forward, breadcrumb, GitHub
            // status, presence, notifications, soundscape, focus.
            // Workspace-scoped controls resolve against the persisted
            // last-active workspace, as everywhere outside the shell.
            ShellTitleBar(
              canGoBack: navState.canGoBack,
              canGoForward: navState.canGoForward,
              onGoBack: historyNotifier.goBack,
              onGoForward: historyNotifier.goForward,
            ),
            Expanded(
              child: Row(
                children: [
                  CcSidebar(
                    header: const AppSidebarHeader(workspaceAgnostic: true),
                    headerGap: AppSpacing.xs,
                    trailingBorder: BorderSide(color: tokens.borderPrimary),
                    children: const [],
                  ),
                  Expanded(
                    child: workspaces.when(
                      // `list` is this same data in the operator's manual order (plus any
                      // in-flight drag), so the ordered projection is what renders.
                      data: (_) {
                        if (list.isEmpty) {
                          return EmptyState(
                            message: l10n.noWorkspace,
                            primaryAction: _addWorkspace,
                            actionLabel: l10n.addWorkspace,
                          );
                        }
                        final current = editing!;
                        return CallbackShortcuts(
                          bindings: {
                            const SingleActivator(
                              LogicalKeyboardKey.keyJ,
                            ): () =>
                                _cycle(list, 1),
                            const SingleActivator(
                              LogicalKeyboardKey.keyK,
                            ): () =>
                                _cycle(list, -1),
                            const SingleActivator(
                              LogicalKeyboardKey.arrowUp,
                              alt: true,
                            ): () =>
                                _moveSelected(list, -1),
                            const SingleActivator(
                              LogicalKeyboardKey.arrowDown,
                              alt: true,
                            ): () =>
                                _moveSelected(list, 1),
                          },
                          child: _Canvas(
                            workspaces: list,
                            editing: current,
                            activeId: activeId,
                            onSelect: _selectWorkspace,
                            onAdd: _addWorkspace,
                            onDelete: (w) => _deleteWorkspace(w, list),
                            onReorder: (oldIndex, newIndex) =>
                                _reorder(list, oldIndex, newIndex),
                            onPickLogo: _pickLogo,
                            onRemoveLogo: _removeLogo,
                            onDiscard: () => _discard(current),
                            onSave: () => _save(current),
                            nameController: _nameController,
                            dirty: _dirty,
                            saving: _saving,
                            logoPath: _committedLogoPath,
                            logoBytes: _previewLogoBytes,
                            draftName: _nameController.text,
                          ),
                        );
                      },
                      loading: () => const Center(child: CcSpinner()),
                      error: (e, _) => Center(
                        child: Text(
                          kDebugMode
                              ? '${l10n.failedToLoadWorkspaces}: $e'
                              : l10n.failedToLoadWorkspaces,
                        ),
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

/// Scrolling canvas: page head + master/detail grid.
class _Canvas extends StatelessWidget {
  const _Canvas({
    required this.workspaces,
    required this.editing,
    required this.activeId,
    required this.onSelect,
    required this.onAdd,
    required this.onDelete,
    required this.onReorder,
    required this.onPickLogo,
    required this.onRemoveLogo,
    required this.onDiscard,
    required this.onSave,
    required this.nameController,
    required this.dirty,
    required this.saving,
    required this.logoPath,
    required this.logoBytes,
    required this.draftName,
  });

  final List<Workspace> workspaces;
  final Workspace editing;
  final String? activeId;
  final ValueChanged<Workspace> onSelect;
  final VoidCallback onAdd;
  final ValueChanged<Workspace> onDelete;
  final ReorderCallback onReorder;
  final VoidCallback onPickLogo;
  final VoidCallback onRemoveLogo;
  final VoidCallback onDiscard;
  final VoidCallback onSave;
  final TextEditingController nameController;
  final bool dirty;
  final bool saving;
  final String? logoPath;
  final Uint8List? logoBytes;
  final String draftName;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= _kWideBreakpoint;
        final listPanel = _WorkspaceListPanel(
          workspaces: workspaces,
          editingId: editing.id,
          draftName: draftName,
          draftLogoPath: logoPath,
          draftLogoBytes: logoBytes,
          onSelect: onSelect,
          onReorder: onReorder,
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
          logoPath: logoPath,
          logoBytes: logoBytes,
          draftName: draftName,
        );

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 80),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1080),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Same header anatomy as the in-shell list pages (pipelines,
                  // PR list, inbox): PageHeaderText on the left, the primary
                  // action top-right.
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: PageHeaderText(
                          title: l10n.manageWorkspaces,
                          subtitle: l10n.manageWorkspacesSubtitle,
                        ),
                      ),
                      const SizedBox(width: 16),
                      CcButton(
                        onPressed: onAdd,
                        icon: AppIcons.plus,
                        size: CcButtonSize.sm,
                        child: Text(l10n.addWorkspace),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
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

// ── left rail ────────────────────────────────────────────────────────────

/// The left rail: every workspace, drag-to-reorder.
///
/// The sequence written here is the app-wide workspace order — the title-bar
/// switcher popover, the phone picker and every other workspace list read the
/// same server-owned order (mirroring how repositories are ordered).
class _WorkspaceListPanel extends StatelessWidget {
  const _WorkspaceListPanel({
    required this.workspaces,
    required this.editingId,
    required this.draftName,
    required this.draftLogoPath,
    required this.draftLogoBytes,
    required this.onSelect,
    required this.onReorder,
  });

  final List<Workspace> workspaces;
  final String editingId;
  final String draftName;
  final String? draftLogoPath;
  final Uint8List? draftLogoBytes;
  final ValueChanged<Workspace> onSelect;
  final ReorderCallback onReorder;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final panel = ds.panel;
    final border = ds.borderSecondary;

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
            child: ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              // Rows carry their own grip handle so the whole row stays
              // tappable for selection.
              buildDefaultDragHandles: false,
              itemCount: workspaces.length,
              onReorderItem: onReorder,
              itemBuilder: (context, i) {
                final w = workspaces[i];
                return _WorkspaceRow(
                  key: ValueKey(w.id),
                  workspace: w,
                  active: w.id == editingId,
                  displayName: w.id == editingId ? draftName : w.name,
                  displayHasLogo: w.id == editingId
                      ? (draftLogoPath != null && draftLogoPath!.isNotEmpty)
                      : w.hasLogo,
                  displayLogoBytes: w.id == editingId ? draftLogoBytes : null,
                  onTap: () => onSelect(w),
                  dragIndex: i,
                );
              },
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
    required this.displayHasLogo,
    required this.displayLogoBytes,
    required this.onTap,
    required this.dragIndex,
  });

  final Workspace workspace;
  final bool active;
  final String displayName;
  final bool displayHasLogo;
  final Uint8List? displayLogoBytes;
  final VoidCallback onTap;

  /// This row's index in the reorderable rail; the leading grip handle starts a
  /// drag for it.
  final int dragIndex;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final fg = ds.fg;
    final muted = ds.muted;
    final surface = ds.surface;

    final repos =
        ref.watch(reposForWorkspaceProvider(workspace.id)).value?.length ?? 0;
    final agents =
        ref.watch(workspaceAgentsProvider(workspace.id)).value?.length ?? 0;
    final name = displayName.trim().isEmpty ? l10n.noWorkspace : displayName;

    return CcTappable(
      onPressed: onTap,
      builder: (context, states) => AnimatedContainer(
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        decoration: ShapeDecoration(
          color: active ? surface : Colors.transparent,
          shape: const RoundedSuperellipseBorder(borderRadius: AppRadii.brMd),
        ),
        padding: const EdgeInsets.fromLTRB(8, 9, 12, 9),
        child: Row(
          children: [
            ReorderableDragStartListener(
              index: dragIndex,
              child: MouseRegion(
                cursor: SystemMouseCursors.grab,
                child: Semantics(
                  label: l10n.reorderWorkspace,
                  child: Icon(
                    AppIcons.gripVertical,
                    size: 16,
                    color: ds.fgTertiary,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 6),
            WorkspaceAvatar(
              name: name,
              workspaceId: workspace.id,
              hasLogo: displayHasLogo,
              logoBytes: displayLogoBytes,
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
    required this.logoPath,
    required this.logoBytes,
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
  final String? logoPath;
  final Uint8List? logoBytes;
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
          logoPath: logoPath,
          logoBytes: logoBytes,
          draftName: draftName,
        ),
        const SizedBox(height: 20),
        _DangerPanel(editing: editing, onDelete: () => onDelete(editing)),
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
    required this.logoPath,
    required this.logoBytes,
    required this.draftName,
  });

  final Workspace editing;
  final VoidCallback onPickLogo;
  final VoidCallback onRemoveLogo;
  final TextEditingController nameController;
  final String? logoPath;
  final Uint8List? logoBytes;
  final String draftName;

  @override
  Widget build(BuildContext context) {
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final panel = ds.panel;
    final border = ds.borderSecondary;
    final muted = ds.muted;
    final hasLogo =
        (logoBytes != null && logoBytes!.isNotEmpty) ||
        (logoPath != null && logoPath!.isNotEmpty);

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
            trailing: CcButton(
              onPressed: () => context.go(inboxRoute(editing.id)),
              variant: CcButtonVariant.secondary,
              icon: AppIcons.externalLink,
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
                      workspaceId: editing.id,
                      hasLogo: logoPath != null && logoPath!.isNotEmpty,
                      logoBytes: logoBytes,
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
                              CcButton(
                                onPressed: onPickLogo,
                                variant: CcButtonVariant.secondary,
                                icon: AppIcons.upload,
                                child: Text(l10n.uploadImage),
                              ),
                              const SizedBox(width: 8),
                              CcButton(
                                onPressed: hasLogo ? onRemoveLogo : null,
                                variant: CcButtonVariant.secondary,
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.workspaceName),
                    const SizedBox(height: 6),
                    CcTextField(
                      controller: nameController,
                      hintText: l10n.egPlatform,
                      maxLength: 32,
                    ),
                  ],
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
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final border = ds.borderSecondary;

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
            Expanded(
              child: _FactCell(value: '$skills', label: l10n.skills),
            ),
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
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final panel = ds.panel;
    final fg = ds.fg;
    final muted = ds.muted;

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
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final panel = ds.panel;
    final baseBorder = ds.borderSecondary;
    final danger = ds.danger;
    final muted = ds.muted;
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
                        style: TextStyle(fontSize: 14, color: ds.fg),
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
                CcButton(
                  onPressed: onDelete,
                  variant: CcButtonVariant.destructive,
                  icon: AppIcons.trash2,
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
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    final panel = ds.panel;
    final border = ds.borderSecondary;
    final fg = ds.fg;
    final accent = ds.accent;

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
          CcButton(
            onPressed: saving ? null : onDiscard,
            variant: CcButtonVariant.secondary,
            child: Text(l10n.discard),
          ),
          const SizedBox(width: 8),
          CcButton(
            onPressed: saving ? null : onSave,
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
    final ds = context.designSystem ?? DesignSystemTokens.light();
    final fg = titleColor ?? ds.fg;
    final muted = ds.muted;
    final border = borderColor ?? ds.borderSecondary;

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
  return showCcDialog<String?>(
    context: context,
    builder: (dialogContext) => CcDialog(
      title: l10n.addWorkspace,
      content: SizedBox(
        width: 420,
        child: AddWorkspaceForm(
          onCreated: (id) => Navigator.pop(dialogContext, id),
          onCancel: () => Navigator.pop(dialogContext),
        ),
      ),
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
