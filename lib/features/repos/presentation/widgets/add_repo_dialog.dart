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
import 'package:cc_domain/core/domain/value_objects/repo_access.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/repos/presentation/widgets/repo_folder_browser.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart'
    show RepoRegistration;
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// The outcome of a batch registration: the repo ids that were created, the
/// per-path error for every pick that failed, and what automation cannot
/// reach in the repos that were added.
typedef RepoAddOutcome = ({
  List<String> added,
  Map<String, Object> failed,
  List<RepoAccessIssue> issues,
});

/// Registers every folder in [paths] into [workspaceId], continuing past
/// individual failures so one invalid pick never drops the rest of the batch.
/// Registration order matches [paths] order.
Future<RepoAddOutcome> registerReposFromPaths(
  Future<RepoRegistration> Function(String workspaceId, String path) register,
  String workspaceId,
  List<String> paths,
) async {
  final added = <String>[];
  final failed = <String, Object>{};
  final issues = <RepoAccessIssue>[];
  for (final path in paths) {
    try {
      final registration = await register(workspaceId, path);
      added.add(registration.repoId);
      issues.addAll(registration.issues);
    } catch (e) {
      failed[path] = e;
    }
  }
  return (added: added, failed: failed, issues: issues);
}

/// Dialog that registers repos by browsing the server's filesystem.
///
/// Takes its [browser] + [register] dependencies as parameters rather than
/// reading providers directly: the dialog is presented into the ROOT overlay,
/// which sits ABOVE the app's `ProviderScope`, so a `ref` here would throw
/// "No ProviderScope found". `addRepos` captures both from the caller's
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
    this.intro,
  });

  /// Browses the server's filesystem over RPC (captured from a provider).
  final DirectoryBrowserPort browser;

  /// Registers the repo at a server path, returning the new repo id (captured
  /// from a provider).
  final Future<RepoRegistration> Function(String workspaceId, String path)
  register;

  /// The workspace the repos are registered into. Repos are workspace-scoped,
  /// so this is threaded from the route rather than resolved implicitly.
  final String workspaceId;

  /// Called with the batch outcome once every selected path has settled.
  final void Function(RepoAddOutcome outcome) onDone;

  /// Optional cancel handler — when null, no cancel button is rendered.
  final VoidCallback? onCancel;

  /// The line above the browser, when the caller knows what to look for;
  /// defaults to the generic instructions.
  final String? intro;

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
          widget.intro ?? l10n.addRepoBrowseIntro,
          style: TextStyle(color: tokens?.textTertiary, height: 1.4),
        ),
        const SizedBox(height: 12),
        RepoBrowserPathBar(
          listing: listing,
          onUp: listing?.parent != null && !_saving
              ? () => _open(listing!.parent)
              : null,
          upLabel: l10n.goUp,
        ),
        if (listing != null && listing.roots.length > 1) ...[
          const SizedBox(height: 8),
          RepoBrowserRootChips(
            roots: listing.roots,
            current: listing.path,
            onSelect: _saving ? null : _open,
          ),
        ],
        const SizedBox(height: 8),
        RepoFolderList(
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
