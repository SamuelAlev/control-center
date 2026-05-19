// Add-repo dialog: a navigable, multi-select browser over the SERVER's
// filesystem — the single add-repo flow on every platform.
//
// The desktop app is a thin client: the checkout must resolve on the machine
// hosting cc_server, which is not necessarily the machine the UI runs on, so a
// native folder picker is the wrong tool (it would pick a folder on the
// client and on web there is no absolute path to pick at all). Instead this
// dialog walks the server's own folders over RPC (`fs.browseDirectory`,
// scoped to the host's configured roots), flags which are git checkouts and
// registers the selected ones via `repos.addFromPath`. The server inspects
// each path, creates the row inside the named workspace and fires `RepoAdded`
// so the code-indexing pipeline runs. Selection is multi: check any number of
// checkouts (across as many folders as you browse — the set persists while
// navigating) and register them all at once; one failed pick never drops the
// rest of the batch.

import 'dart:collection' show LinkedHashSet;

import 'package:cc_domain/core/domain/entities/directory_listing.dart';
import 'package:cc_domain/core/domain/ports/directory_browser_port.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The outcome of a batch registration: the repo ids that were created and
/// the per-path error for every pick that failed.
typedef RepoAddOutcome = ({List<String> added, Map<String, Object> failed});

/// Registers every folder in [paths] into [workspaceId], continuing past
/// individual failures so one invalid pick never drops the rest of the batch.
/// Registration order matches [paths] order.
Future<RepoAddOutcome> registerReposFromPaths(
  Future<String> Function(String workspaceId, String path) register,
  String workspaceId,
  List<String> paths,
) async {
  final added = <String>[];
  final failed = <String, Object>{};
  for (final path in paths) {
    try {
      added.add(await register(workspaceId, path));
    } catch (e) {
      failed[path] = e;
    }
  }
  return (added: added, failed: failed);
}

/// Dialog that registers repos by browsing the server's filesystem.
///
/// Takes its [browser] + [register] dependencies as parameters rather than
/// reading providers directly: the dialog is presented into the ROOT overlay,
/// which sits ABOVE the app's `ProviderScope`, so a `ref` here would throw
/// "No ProviderScope found". [addRepos] captures both from the caller's
/// `WidgetRef` (which is under the scope) and passes them in.
class AddRepoDialog extends StatefulWidget {
  /// Creates an [AddRepoDialog].
  const AddRepoDialog({
    super.key,
    required this.browser,
    required this.register,
    required this.workspaceId,
    required this.onDone,
    this.onCancel,
  });

  /// Browses the server's filesystem over RPC (captured from a provider).
  final DirectoryBrowserPort browser;

  /// Registers the repo at a server path, returning the new repo id (captured
  /// from a provider).
  final Future<String> Function(String workspaceId, String path) register;

  /// The workspace the repos are registered into. Repos are workspace-scoped,
  /// so this is threaded from the route rather than resolved implicitly.
  final String workspaceId;

  /// Called with the batch outcome once every selected path has settled.
  final void Function(RepoAddOutcome outcome) onDone;

  /// Optional cancel handler — when null, no cancel button is rendered.
  final VoidCallback? onCancel;

  @override
  State<AddRepoDialog> createState() => _AddRepoDialogState();
}

class _AddRepoDialogState extends State<AddRepoDialog> {
  DirectoryListing? _listing;
  bool _loading = true;
  String? _browseError;

  /// The picked checkout paths, in pick order (a Dart `Set` literal is a
  /// [LinkedHashSet], so iteration order is insertion order and the batch
  /// registers in the order the user selected). Selection persists while
  /// navigating, so a batch can span several browsed folders.
  final Set<String> _selected = <String>{};

  /// Whether the batch registration is in flight (locks the dialog).
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _open(null);
  }

  Future<void> _open(String? path) async {
    setState(() {
      _loading = true;
      _browseError = null;
    });
    try {
      final listing = await widget.browser.browse(path: path);
      if (!mounted) {
        return;
      }
      setState(() {
        _listing = listing;
        _loading = false;
      });
    } on RemoteRpcException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _browseError = e.message;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _loading = false;
        _browseError = 'Failed to open folder: $e';
      });
    }
  }

  void _toggle(String path) {
    setState(() {
      if (!_selected.remove(path)) {
        _selected.add(path);
      }
    });
  }

  Future<void> _addSelected() async {
    if (_saving || _selected.isEmpty) {
      return;
    }
    setState(() => _saving = true);
    final outcome = await registerReposFromPaths(
      widget.register,
      widget.workspaceId,
      _selected.toList(),
    );
    if (!mounted) {
      return;
    }
    widget.onDone(outcome);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final listing = _listing;
    final currentIsRepo = listing?.isGitRepo ?? false;
    final currentSelected = listing != null && _selected.contains(listing.path);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 8),
        Text(
          l10n.addRepoBrowseIntro,
          style: TextStyle(color: tokens?.textTertiary, height: 1.4),
        ),
        const SizedBox(height: 12),
        _PathBar(
          listing: listing,
          onUp: listing?.parent != null && !_saving
              ? () => _open(listing!.parent)
              : null,
          upLabel: l10n.goUp,
        ),
        if (listing != null && listing.roots.length > 1) ...[
          const SizedBox(height: 8),
          _RootChips(
            roots: listing.roots,
            current: listing.path,
            onSelect: _saving ? null : _open,
          ),
        ],
        const SizedBox(height: 8),
        _FolderList(
          loading: _loading,
          error: _browseError,
          listing: listing,
          selected: _selected,
          enabled: !_saving,
          emptyLabel: l10n.noSubfoldersHere,
          onOpen: _saving ? null : _open,
          onToggle: _saving ? null : _toggle,
        ),
        if (listing != null && !currentIsRepo && _browseError == null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.notAGitRepository,
            style: TextStyle(color: tokens?.textTertiary, fontSize: 12),
          ),
        ],
        const SizedBox(height: 16),
        Row(
          children: [
            if (currentIsRepo && listing != null)
              CcButton(
                onPressed: _saving ? null : () => _toggle(listing.path),
                variant: currentSelected
                    ? CcButtonVariant.line
                    : CcButtonVariant.secondary,
                icon: currentSelected ? CcIcons.check : null,
                child: Text(
                  currentSelected
                      ? l10n.deselectThisFolder
                      : l10n.selectThisFolder,
                ),
              ),
            const Spacer(),
            if (widget.onCancel != null) ...[
              CcButton(
                onPressed: _saving ? null : widget.onCancel,
                variant: CcButtonVariant.ghost,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 12),
            ],
            CcButton(
              onPressed: _selected.isEmpty || _saving ? null : _addSelected,
              loading: _saving,
              child: Text(
                _selected.isEmpty
                    ? l10n.addRepository
                    : l10n.addSelectedRepositories(_selected.length),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

/// The current path with a button to navigate to the parent directory.
class _PathBar extends StatelessWidget {
  const _PathBar({
    required this.listing,
    required this.onUp,
    required this.upLabel,
  });

  final DirectoryListing? listing;
  final VoidCallback? onUp;
  final String upLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    return Row(
      children: [
        CcButton(
          onPressed: onUp,
          variant: CcButtonVariant.secondary,
          size: CcButtonSize.sm,
          icon: CcIcons.cornerLeftUp,
          child: Text(upLabel),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            listing?.path ?? '…',
            style: CcFonts.code(
              textStyle: TextStyle(color: tokens?.textSecondary, fontSize: 13),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textDirection: TextDirection.ltr,
          ),
        ),
      ],
    );
  }
}

/// Quick-jump chips for the configured browse roots (shown when there is more
/// than one).
class _RootChips extends StatelessWidget {
  const _RootChips({
    required this.roots,
    required this.current,
    required this.onSelect,
  });

  final List<String> roots;
  final String current;
  final void Function(String path)? onSelect;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final root in roots)
          CcButton(
            onPressed: root == current || onSelect == null
                ? null
                : () => onSelect!(root),
            variant: root == current
                ? CcButtonVariant.line
                : CcButtonVariant.ghost,
            size: CcButtonSize.sm,
            icon: CcIcons.house,
            child: Text(_lastSegment(root)),
          ),
      ],
    );
  }

  static String _lastSegment(String path) {
    final trimmed = path.replaceAll(RegExp(r'[\\/]+$'), '');
    final parts = trimmed.split(RegExp(r'[\\/]'));
    final last = parts.isEmpty ? '' : parts.last;
    return last.isEmpty ? path : last;
  }
}

/// The scrollable list of subdirectories — folders navigate in, git checkouts
/// carry a selection checkbox.
class _FolderList extends StatelessWidget {
  const _FolderList({
    required this.loading,
    required this.error,
    required this.listing,
    required this.selected,
    required this.enabled,
    required this.emptyLabel,
    required this.onOpen,
    required this.onToggle,
  });

  final bool loading;
  final String? error;
  final DirectoryListing? listing;
  final Set<String> selected;
  final bool enabled;
  final String emptyLabel;
  final void Function(String path)? onOpen;
  final void Function(String path)? onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    return Container(
      height: 260,
      decoration: BoxDecoration(
        color: tokens?.panel,
        borderRadius: AppRadii.brLg,
        border: Border.all(
          color: tokens?.borderSecondary ?? const Color(0x1A000000),
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: _buildBody(context, tokens),
    );
  }

  Widget _buildBody(BuildContext context, DesignSystemTokens? tokens) {
    if (loading) {
      return const Center(child: CcSpinner());
    }
    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            error!,
            textAlign: TextAlign.center,
            style: TextStyle(color: tokens?.danger),
          ),
        ),
      );
    }
    final entries = listing?.entries ?? const <DirectoryEntry>[];
    if (entries.isEmpty) {
      return Center(
        child: Text(emptyLabel, style: TextStyle(color: tokens?.textTertiary)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 4),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final entry = entries[index];
        return _FolderRow(
          entry: entry,
          selected: selected.contains(entry.path),
          onOpen: onOpen == null ? null : () => onOpen!(entry.path),
          onToggle: entry.isGitRepo && onToggle != null
              ? () => onToggle!(entry.path)
              : null,
        );
      },
    );
  }
}

/// A single folder row: tap the body to navigate in; git checkouts carry a
/// selection checkbox with its own tap target (checking never navigates).
class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.entry,
    required this.selected,
    required this.onOpen,
    required this.onToggle,
  });

  final DirectoryEntry entry;
  final bool selected;
  final VoidCallback? onOpen;
  final VoidCallback? onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem;
    return CcTappable(
      onPressed: onOpen,
      semanticLabel: entry.name,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          color: hovered ? tokens?.hover : null,
          child: Row(
            children: [
              Icon(
                entry.isGitRepo ? CcIcons.folderGit : CcIcons.folder,
                size: 16,
                color: entry.isGitRepo
                    ? (tokens?.accent ?? const Color(0xFFE2570F))
                    : (tokens?.muted ?? const Color(0xFF6B7280)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  entry.name,
                  style: TextStyle(color: tokens?.textPrimary, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onToggle != null)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onToggle,
                  child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: IgnorePointer(
                      child: CcCheckbox(value: selected, onChanged: (_) {}),
                    ),
                  ),
                )
              else
                Icon(
                  CcIcons.chevronRight,
                  size: 16,
                  color: tokens?.idle ?? const Color(0xFF9CA3AF),
                ),
            ],
          ),
        );
      },
    );
  }
}

/// The add-repo entry point on every platform: shows the server-filesystem
/// browser dialog and returns the batch outcome, or null when cancelled.
///
/// The browse + register dependencies are read from [ref] HERE (under the app's
/// `ProviderScope`) and handed to the dialog, because the dialog itself is
/// mounted in the root overlay above that scope and so cannot read providers.
/// [workspaceId] names the workspace the repos are registered into — repos are
/// workspace-scoped, so it is threaded all the way to the register call rather
/// than resolved from an ambient "active workspace".
Future<RepoAddOutcome?> addRepos(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
) {
  final l10n = AppLocalizations.of(context);
  final browser = ref.read(directoryBrowserProvider);
  final register = ref.read(addRepoFromServerPathProvider);
  return showCcDialog<RepoAddOutcome?>(
    context: context,
    builder: (dialogContext) => CcDialog(
      title: l10n.addRepository,
      content: SizedBox(
        width: 460,
        child: AddRepoDialog(
          browser: browser,
          register: register,
          workspaceId: workspaceId,
          onDone: (outcome) => Navigator.pop(dialogContext, outcome),
          onCancel: () => Navigator.pop(dialogContext),
        ),
      ),
      actions: const [],
    ),
  );
}
