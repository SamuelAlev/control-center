// Web add-repo form: a navigable browser over the SERVER's filesystem.
//
// On web the browser has no local filesystem, and the repo must resolve on the
// machine hosting cc_server — so a native folder picker is the wrong tool (it
// would pick a folder on the client, and the File System Access API never even
// exposes an absolute path). Instead this form walks the server's own folders
// over RPC (`fs.browseDirectory`, scoped to the host's configured roots),
// flags which are git checkouts, and registers the chosen one via
// `repos.addFromPath`. The parent screen then links it to the active workspace,
// exactly like the desktop path. This keeps the VM-only repo providers
// (cc_natives / cc_persistence / server_providers) off the web compile graph
// while still reaching real functionality through the server.
library;

import 'package:cc_domain/core/domain/entities/directory_listing.dart';
import 'package:cc_domain/core/domain/ports/directory_browser_port.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Web form that registers a repo by browsing the server's filesystem.
///
/// Takes its [browser] + [register] dependencies as parameters rather than
/// reading providers directly: the dialog is presented into the ROOT overlay,
/// which on web sits ABOVE the app's `ProviderScope`, so a `ref` here would
/// throw "No ProviderScope found". `showAddRepoDialog` captures both from the
/// caller's `WidgetRef` (which is under the scope) and passes them in.
class AddRepoForm extends StatefulWidget {
  /// Creates an [AddRepoForm].
  const AddRepoForm({
    super.key,
    required this.browser,
    required this.register,
    required this.onCreated,
    this.onCancel,
  });

  /// Browses the server's filesystem over RPC (captured from a provider).
  final DirectoryBrowserPort browser;

  /// Registers the repo at a server path, returning the new repo id (captured
  /// from a provider).
  final Future<String> Function(String path) register;

  /// Called after the repo row is inserted, with the new repo id.
  final void Function(String repoId) onCreated;

  /// Optional cancel handler — when null, no cancel button is rendered.
  final VoidCallback? onCancel;

  @override
  State<AddRepoForm> createState() => _AddRepoFormState();
}

class _AddRepoFormState extends State<AddRepoForm> {
  DirectoryListing? _listing;
  bool _loading = true;
  String? _browseError;
  String? _savingPath;
  String? _saveError;

  @override
  void initState() {
    super.initState();
    _open(null);
  }

  Future<void> _open(String? path) async {
    setState(() {
      _loading = true;
      _browseError = null;
      _saveError = null;
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

  Future<void> _register(String path) async {
    if (_savingPath != null) {
      return;
    }
    setState(() {
      _savingPath = path;
      _saveError = null;
    });
    try {
      final repoId = await widget.register(path);
      if (!mounted) {
        return;
      }
      widget.onCreated(repoId);
    } on RemoteRpcException catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _savingPath = null;
        _saveError = e.message;
      });
    } catch (e) {
      if (!mounted) {
        return;
      }
      setState(() {
        _savingPath = null;
        _saveError = 'Failed to register repository: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem;
    final listing = _listing;
    final saving = _savingPath != null;
    final currentIsRepo = listing?.isGitRepo ?? false;

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
          onUp: listing?.parent != null && !saving
              ? () => _open(listing!.parent)
              : null,
          upLabel: l10n.goUp,
        ),
        if (listing != null && listing.roots.length > 1) ...[
          const SizedBox(height: 8),
          _RootChips(
            roots: listing.roots,
            current: listing.path,
            onSelect: saving ? null : _open,
          ),
        ],
        const SizedBox(height: 8),
        _FolderList(
          loading: _loading,
          error: _browseError,
          listing: listing,
          savingPath: _savingPath,
          emptyLabel: l10n.noSubfoldersHere,
          addLabel: l10n.add,
          onOpen: saving ? null : _open,
          onAdd: saving ? null : _register,
        ),
        if (listing != null && !currentIsRepo && _browseError == null) ...[
          const SizedBox(height: 8),
          Text(
            l10n.notAGitRepository,
            style: TextStyle(color: tokens?.textTertiary, fontSize: 12),
          ),
        ],
        if (_saveError != null) ...[
          const SizedBox(height: 10),
          Text(_saveError!, style: TextStyle(color: tokens?.danger)),
        ],
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (widget.onCancel != null) ...[
              CcButton(
                onPressed: saving ? null : widget.onCancel,
                variant: CcButtonVariant.ghost,
                child: Text(l10n.cancel),
              ),
              const SizedBox(width: 12),
            ],
            CcButton(
              onPressed: currentIsRepo && !saving && listing != null
                  ? () => _register(listing.path)
                  : null,
              loading: _savingPath != null && _savingPath == listing?.path,
              child: Text(l10n.addThisFolder),
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
/// can be registered directly.
class _FolderList extends StatelessWidget {
  const _FolderList({
    required this.loading,
    required this.error,
    required this.listing,
    required this.savingPath,
    required this.emptyLabel,
    required this.addLabel,
    required this.onOpen,
    required this.onAdd,
  });

  final bool loading;
  final String? error;
  final DirectoryListing? listing;
  final String? savingPath;
  final String emptyLabel;
  final String addLabel;
  final void Function(String path)? onOpen;
  final void Function(String path)? onAdd;

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
          adding: savingPath == entry.path,
          addLabel: addLabel,
          onOpen: onOpen == null ? null : () => onOpen!(entry.path),
          onAdd:
              entry.isGitRepo && onAdd != null ? () => onAdd!(entry.path) : null,
        );
      },
    );
  }
}

/// A single folder row: tap the body to navigate in; git checkouts expose an
/// "Add" action.
class _FolderRow extends StatelessWidget {
  const _FolderRow({
    required this.entry,
    required this.adding,
    required this.addLabel,
    required this.onOpen,
    required this.onAdd,
  });

  final DirectoryEntry entry;
  final bool adding;
  final String addLabel;
  final VoidCallback? onOpen;
  final VoidCallback? onAdd;

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
              if (onAdd != null) ...[
                const SizedBox(width: 8),
                CcButton(
                  onPressed: adding ? null : onAdd,
                  variant: CcButtonVariant.accent,
                  size: CcButtonSize.sm,
                  loading: adding,
                  child: Text(addLabel),
                ),
              ] else
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

/// Shows the add-repo dialog. Returns the new repo id, or null when cancelled.
///
/// The browse + register dependencies are read from [ref] HERE (under the app's
/// `ProviderScope`) and handed to the form, because the dialog itself is mounted
/// in the root overlay above that scope and so cannot read providers.
// [workspaceId] is accepted for signature parity with the desktop variant and
// the shared call site; on web the parent screen performs the workspace link
// (the form only registers the repo on the server), so it isn't threaded into
// the form here.
Future<String?> showAddRepoDialog(
  BuildContext context,
  WidgetRef ref,
  String workspaceId,
) {
  final l10n = AppLocalizations.of(context);
  final browser = ref.read(directoryBrowserProvider);
  final register = ref.read(addRepoFromServerPathProvider);
  return showCcDialog<String?>(
    context: context,
    builder: (dialogContext) => CcDialog(
      title: l10n.addRepository,
      content: SizedBox(
        width: 460,
        child: AddRepoForm(
          browser: browser,
          register: register,
          onCreated: (id) => Navigator.pop(dialogContext, id),
          onCancel: () => Navigator.pop(dialogContext),
        ),
      ),
      actions: const [],
    ),
  );
}
