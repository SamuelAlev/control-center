import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show FileSearchHit;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_domain/features/messaging/domain/value_objects/space_provisioning_status.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/presentation/utils/provisioning_step_label.dart';
import 'package:control_center/features/messaging/providers/explorer_view_state_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/messaging/providers/repo_content_search_provider.dart';
import 'package:control_center/features/messaging/providers/repo_directory_listing_provider.dart';
import 'package:control_center/features/messaging/providers/repo_file_search_provider.dart';
import 'package:control_center/features/messaging/providers/space_worktrees_provider.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// The panel's two surfaces are still named from here, so callers (and the
// widget tests) keep one import. The enum itself lives with the view state it
// is part of, which outlives this widget.
export 'package:control_center/features/messaging/providers/explorer_view_state_provider.dart'
    show ExplorerSearchMode;

/// A scored file hit paired with the repo id it belongs to (the value type of
/// [repoFileSearchProvider]).
typedef ExplorerHit = ({FileSearchHit hit, String repoId});

/// One node in the explorer's per-repo file tree. Pure data — no Flutter
/// dependency — so it can be cached and rebuilt cheaply. Children are NOT
/// held here: the tree is lazy, each expanded directory's children come from
/// [repoDirectoryListingProvider] (keyed by the node's repo + path).
class RepoFileNode {
  /// Creates a [RepoFileNode].
  const RepoFileNode({
    required this.name,
    required this.repoId,
    required this.fullRelativePath,
    required this.isDirectory,
  });

  /// Display name (the path segment, or the repo's full name for the root).
  final String name;

  /// Owning repo id.
  final String repoId;

  /// Path relative to the repo root (`''` for the root node itself).
  final String fullRelativePath;

  /// Whether this node represents a directory.
  final bool isDirectory;
}

/// What a visible tree row is: a real entry, a directory still loading its
/// first page, the trailing "fetching more" row of a multi-page directory, or
/// a failed page with a retry affordance.
enum _TreeRowKind { node, loading, loadingMore, error }

/// A flattened, visible tree row ready for a [ListView.builder].
class _TreeRow {
  /// An entry row for [node].
  const _TreeRow.node(
    this.node, {
    required this.depth,
    required this.expanded,
    required this.repoName,
    required this.showChevron,
  }) : kind = _TreeRowKind.node,
       listingArgs = null;

  /// A placeholder row (loading / loading-more / error) at [depth].
  const _TreeRow.placeholder(this.kind, {required this.depth, this.listingArgs})
    : node = null,
      expanded = false,
      repoName = '',
      showChevron = false;

  final _TreeRowKind kind;
  final RepoFileNode? node;

  /// Indentation depth; `0` is the per-repo root row.
  final int depth;

  /// Whether this (directory) row is currently expanded.
  final bool expanded;

  /// The repo's display name (used for the root row label).
  final String repoName;

  /// For [kind] == error: the listing to re-fetch on retry.
  final RepoDirectoryListingArgs? listingArgs;

  /// Whether a directory row shows its disclosure chevron. Hidden only when
  /// the directory is expanded AND fully loaded AND empty — before that we
  /// cannot know it has no children, and a missing chevron would make an
  /// unloadable directory look like a file.
  final bool showChevron;
}

/// Explorer panel: a lazy per-repo file tree with two search surfaces, swapped
/// by the trailing toggle button (mirrors the PR diff sidebar's tree ⇄
/// search-in-files pattern).
///
/// Filename mode — empty query → lazy per-repo tree (collapsible dirs, each
/// directory's children fetched page-by-page from `repos.listDirectory` as it
/// is expanded, so no single response scales with repo size); typed query →
/// flat scored list paged from `repos.searchFiles` (fff runs server-side via
/// [repoFileSearchProvider], loading more as the list nears its end). Content
/// mode — `git grep` across the same roots ([repoContentSearchProvider]) with
/// case/regex/whole-word toggles and include/exclude glob filters. Clicking a
/// file opens it in the editor; clicking a dir toggles its expansion.
///
/// Every one of those reads is scoped to the conversation: the panel lists only
/// the repos the space CLONED ([spaceWorktreesProvider]) and every tree, search
/// and grep runs against that repo's ISOLATED CoW WORKTREE — the tree agents
/// and code-server actually write to. Listing the shared linked checkout
/// instead would show a file the conversation never touched, and hand the
/// editor a path whose contents disagree with the diff beside it.
class ExplorerPanel extends ConsumerStatefulWidget {
  /// Creates an [ExplorerPanel].
  const ExplorerPanel({
    super.key,
    required this.workspaceId,
    this.spaceId,
    required this.onOpenFile,
    this.onQuickViewFile,
  });

  /// The workspace whose linked repos the tree is scoped to.
  final String workspaceId;

  /// The active conversation. Its isolated CoW worktrees are both the repo set
  /// the tree shows and the trees every read runs against. Null (no
  /// conversation open) falls back to the workspace's linked checkouts.
  final String? spaceId;

  /// Called with `(repoId, path)` when a file is opened (the default — opens
  /// the code-server editor).
  final ValueChanged<({String repoId, String path})> onOpenFile;

  /// Optional read-only "Quick view" (a secondary action: right-click /
  /// long-press a file row). Null disables it.
  final ValueChanged<({String repoId, String path})>? onQuickViewFile;

  @override
  ConsumerState<ExplorerPanel> createState() => _ExplorerPanelState();
}

class _ExplorerPanelState extends ConsumerState<ExplorerPanel> {
  static const _debounceDelay = Duration(milliseconds: 150);

  /// How close to the end (logical pixels) the flat results list must scroll
  /// before the next page loads — mirrors the message feed's load-more.
  static const double _loadMoreThreshold = 400;

  final TextEditingController _filterController = TextEditingController();
  Timer? _debounce;

  /// Everything the operator set up in this panel — expansion, query, mode,
  /// content-search options — lives outside the widget so switching sidebar
  /// views (which unmounts this element) does not throw it away. See
  /// [ExplorerViewState]. Resolved per read through the widget's workspace id,
  /// so a workspace switch lands on that workspace's own tree rather than the
  /// previous one's.
  ExplorerViewState get _view =>
      ref.read(explorerViewStateProvider(widget.workspaceId));

  /// Set for the first build after mount: the listings restored from cache are
  /// revalidated once, in the background, so returning to the tab paints the
  /// tree it had immediately and still corrects anything that changed on disk
  /// while it was closed. Cleared by the first post-frame pass.
  bool _revalidateOnMount = true;

  /// Drives load-more for the flat results list. Created lazily and kept for
  /// the panel's lifetime — a controller rebuilt per page would be disposed
  /// while still attached and reset the scroll position on every append.
  ScrollController? _resultsController;

  /// The search the scroll listener currently pages (updated each build so
  /// the listener never acts on a stale closure's query or `hasMore`).
  RepoFileSearchArgs? _activeSearchArgs;
  bool _activeSearchHasMore = false;

  // Last result we rendered, retained across query changes so typing (or
  // clearing) the filter keeps the current content on screen while the next
  // result loads — the spinner moves into the search field instead of blanking
  // the panel. `_everLoaded` gates the one-time initial spinner.
  RepoFileSearchState? _lastSearch;
  bool _everLoaded = false;

  // Content-mode counterpart of the filename retention above — keeps the last
  // grouped results on screen while the next query loads.
  List<FileContentMatch> _lastContent = const [];
  bool _contentEverLoaded = false;

  /// Controllers for the include/exclude glob fields (kept across toggles so
  /// a user's typed globs survive a collapse/expand).
  final TextEditingController _includeController = TextEditingController();
  final TextEditingController _excludeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Seed the fields from the retained view state, so a restored query and
    // the box the operator reads it in cannot disagree.
    final view = _view;
    _filterController.text = view.query;
    _includeController.text = view.options.include;
    _excludeController.text = view.options.exclude;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _resultsController?.dispose();
    _filterController.dispose();
    _includeController.dispose();
    _excludeController.dispose();
    super.dispose();
  }

  void _onFilterChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    _debounce = Timer(_debounceDelay, () {
      if (!mounted) {
        return;
      }
      setState(() => _view.query = trimmed);
    });
  }

  /// Replaces the content-search options, re-triggering the debounced search.
  void _setSearchOptions(ContentSearchOptions options) {
    setState(() => _view.options = options);
    // Re-run the search immediately (a no-op when the query is empty).
    _onFilterChanged(_filterController.text);
  }

  /// Mirrors the include/exclude fields into the view state's options and
  /// re-runs the search. Debounced via [_onFilterChanged].
  void _syncFilters(String _) {
    setState(() {
      _view.options = _view.options.copyWith(
        include: _includeController.text,
        exclude: _excludeController.text,
      );
    });
    _onFilterChanged(_filterController.text);
  }

  String _dirKey(String repoId, String relativePath) => '$repoId:$relativePath';

  void _toggleRow(_TreeRow row) {
    setState(() {
      final view = _view;
      if (row.depth == 0) {
        final id = row.node!.repoId;
        view.collapsedRepos.contains(id)
            ? view.collapsedRepos.remove(id)
            : view.collapsedRepos.add(id);
      } else {
        final key = _dirKey(row.node!.repoId, row.node!.fullRelativePath);
        view.expandedDirs.contains(key)
            ? view.expandedDirs.remove(key)
            : view.expandedDirs.add(key);
      }
    });
  }

  /// Whether the directory at [relativePath] is known (from its completed
  /// listing) to be empty. Only meaningful for EXPANDED directories — a
  /// collapsed one has no live listing to ask.
  bool _dirKnownEmpty(String repoId, String relativePath) {
    final value = ref
        .watch(
          repoDirectoryListingProvider((
            workspaceId: widget.workspaceId,
            repoId: repoId,
            path: relativePath,
            spaceId: widget.spaceId,
          )),
        )
        .value;
    return value != null && !value.hasMore && value.entries.isEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    final spaceId = widget.spaceId;
    final allRepos =
        ref.watch(reposForWorkspaceProvider(widget.workspaceId)).value ??
        const <Repo>[];
    // Only the repos this conversation CLONED. A workspace can link a dozen
    // while a space checks out one, and a repo with no worktree here has no
    // tree to list, nothing to search and no file the editor could open.
    final Set<String>? clonedRepoIds = spaceId == null
        ? null
        : ref
              .watch(
                spaceWorktreesProvider((
                  workspaceId: widget.workspaceId,
                  spaceId: spaceId,
                )),
              )
              .value
              ?.map((w) => w.repoId)
              .toSet();
    // Hold rather than guess: rendering the unfiltered list for the frame
    // before the worktree rows arrive would flash repos this conversation
    // cannot open, and each root row would fire a listing for them.
    if (spaceId != null && clonedRepoIds == null) {
      return const Center(child: CcSpinner());
    }
    final repos = clonedRepoIds == null
        ? allRepos
        : [
            for (final r in allRepos)
              if (clonedRepoIds.contains(r.id)) r,
          ];
    final repoById = {for (final r in repos) r.id: r};
    // A space still cloning owns no worktrees yet, and "no repositories" would
    // blame the setup for work that is in flight. Only while there is nothing
    // to show: a partially-provisioned space keeps listing what it has.
    if (repoById.isEmpty &&
        spaceId != null &&
        ref.watch(spaceProvisioningStatusProvider(spaceId)) ==
            SpaceProvisioningStatus.provisioning) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CcSpinner(),
            const SizedBox(height: AppSpacing.sm),
            Text(
              provisioningStepLabel(
                l10n,
                ref.watch(spaceProvisioningStepProvider(spaceId)),
              ),
              style: TextStyle(fontSize: 12, color: t.textTertiary),
            ),
          ],
        ),
      );
    }
    final isContent = _view.mode == ExplorerSearchMode.content;

    // Each mode owns its provider + retention; both surface a (loading, body).
    final (loading, body) = isContent
        ? _contentView(l10n, repoById)
        : _filenameView(l10n, repoById);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: CcTextField(
                      controller: _filterController,
                      hintText: isContent
                          ? l10n.ideSearchInFiles
                          : l10n.searchPlaceholder,
                      size: CcTextFieldSize.sm,
                      // Filter (filename) vs search (content) — the prefix
                      // mirrors the PR sidebar's two surfaces so the active
                      // mode is legible at a glance.
                      prefix: Icon(
                        isContent ? AppIcons.search : AppIcons.listFilter,
                        size: 14,
                        color: t.textTertiary,
                      ),
                      // Loading lives in the field, not over the content, so
                      // results don't flicker away while a query is in flight.
                      // In content mode the suffix also carries the
                      // regex/word/case toggles.
                      suffix: isContent
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _OptionToggle(
                                  icon: AppIcons.caseSensitive,
                                  tooltip: l10n.ideSearchMatchCase,
                                  active: _view.options.caseSensitive,
                                  onChanged: (v) => _setSearchOptions(
                                    _view.options.copyWith(caseSensitive: v),
                                  ),
                                ),
                                _OptionToggle(
                                  icon: AppIcons.regex,
                                  tooltip: l10n.ideSearchRegex,
                                  active: _view.options.regex,
                                  onChanged: (v) => _setSearchOptions(
                                    _view.options.copyWith(regex: v),
                                  ),
                                ),
                                _OptionToggle(
                                  icon: AppIcons.quote,
                                  tooltip: l10n.ideSearchWholeWord,
                                  active: _view.options.wholeWord,
                                  onChanged: (v) => _setSearchOptions(
                                    _view.options.copyWith(wholeWord: v),
                                  ),
                                ),
                                if (loading)
                                  const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: CcSpinner(size: 14, strokeWidth: 2),
                                  ),
                              ],
                            )
                          : (loading
                                ? const Padding(
                                    padding: EdgeInsets.all(6),
                                    child: CcSpinner(size: 14, strokeWidth: 2),
                                  )
                                : null),
                      onChanged: _onFilterChanged,
                    ),
                  ),
                  const SizedBox(width: 4),
                  // Toggle between the two surfaces (mirrors the PR diff
                  // sidebar's tree ⇄ search-in-files switch). In filename
                  // mode the button opens content search; in content mode it
                  // returns to the file tree.
                  CcIconButton(
                    size: CcButtonSize.sm,
                    icon: isContent ? AppIcons.list : AppIcons.search,
                    tooltip: isContent ? l10n.showFileList : l10n.searchInFiles,
                    onPressed: () => setState(() {
                      _view.mode = isContent
                          ? ExplorerSearchMode.filename
                          : ExplorerSearchMode.content;
                    }),
                  ),
                ],
              ),
              if (isContent) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: _FiltersButton(
                        expanded: _view.showFilters,
                        onPressed: () => setState(
                          () => _view.showFilters = !_view.showFilters,
                        ),
                      ),
                    ),
                  ],
                ),
                if (_view.showFilters) ...[
                  const SizedBox(height: AppSpacing.xs),
                  CcTextField(
                    controller: _includeController,
                    hintText: l10n.ideSearchFilesToInclude,
                    size: CcTextFieldSize.sm,
                    prefix: Icon(
                      AppIcons.listFilter,
                      size: 14,
                      color: t.textTertiary,
                    ),
                    onChanged: _syncFilters,
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  CcTextField(
                    controller: _excludeController,
                    hintText: l10n.ideSearchFilesToExclude,
                    size: CcTextFieldSize.sm,
                    prefix: Icon(
                      AppIcons.filterX,
                      size: 14,
                      color: t.textTertiary,
                    ),
                    onChanged: _syncFilters,
                  ),
                ],
              ],
            ],
          ),
        ),
        Expanded(child: body),
      ],
    );
  }

  /// Filename mode: the lazy file tree / paged flat list, with no-flicker
  /// retention. Returns `(loading, body)`.
  (bool, Widget) _filenameView(
    AppLocalizations l10n,
    Map<String, Repo> repoById,
  ) {
    final query = _view.query;
    if (query.isEmpty) {
      // Tree mode: rows are walked from the repo list + the watched
      // per-directory listings (each visible directory watches exactly one
      // provider instance, so Riverpod rebuilds the panel as pages arrive).
      final rows = <_TreeRow>[];
      final drain = <RepoDirectoryListingArgs>[];
      final stale = <RepoDirectoryListingArgs>[];
      final collapsedRepos = _view.collapsedRepos;
      for (final repo in repoById.values) {
        rows.add(
          _TreeRow.node(
            RepoFileNode(
              name: repo.fullName,
              repoId: repo.id,
              fullRelativePath: '',
              isDirectory: true,
            ),
            depth: 0,
            expanded: !collapsedRepos.contains(repo.id),
            repoName: repo.fullName,
            showChevron: true,
          ),
        );
        if (!collapsedRepos.contains(repo.id)) {
          _appendDirectoryRows(
            rows,
            drain,
            stale,
            repoId: repo.id,
            repoName: repo.fullName,
            path: '',
            depth: 1,
          );
        }
      }
      _scheduleDrain(drain);
      // Only once the repo list has actually arrived: an empty first build
      // (the workspace-repos stream has not answered yet) has walked nothing,
      // so consuming the one-shot there would skip the revalidation entirely.
      if (repoById.isNotEmpty) {
        _scheduleRevalidate(stale);
      }
      return (false, _buildTreeBody(rows, repoById, l10n));
    }

    final args = (
      workspaceId: widget.workspaceId,
      query: query,
      spaceId: widget.spaceId,
    );
    final searchAsync = ref.watch(repoFileSearchProvider(args));
    ref.listen(repoFileSearchProvider(args), (_, next) {
      final data = next.value;
      if (data != null && mounted) {
        setState(() {
          _lastSearch = data;
          _everLoaded = true;
        });
      }
    });
    final fresh = searchAsync.value;
    // Fresh result if present, else the last one we showed.
    final search = fresh ?? _lastSearch;
    final hasFresh = fresh != null;
    // Publish to the scroll listener BEFORE building the list, so a scroll
    // event during this frame pages the query it sees rendered.
    _activeSearchArgs = args;
    _activeSearchHasMore = search?.hasMore ?? false;
    return (
      searchAsync.isLoading,
      _buildSearchBody(
        search,
        repoById,
        firstPageLoading: searchAsync.isLoading && !hasFresh,
        hasError: searchAsync.hasError && !hasFresh,
        l10n: l10n,
      ),
    );
  }

  /// Appends the visible rows of one directory's listing (and, recursively,
  /// its expanded sub-directories'). Directories whose listing still has pages
  /// to fetch accumulate into [drain] for the post-frame auto-drain pass;
  /// complete listings restored from cache on this mount accumulate into
  /// [stale] for the one-shot background revalidation.
  void _appendDirectoryRows(
    List<_TreeRow> rows,
    List<RepoDirectoryListingArgs> drain,
    List<RepoDirectoryListingArgs> stale, {
    required String repoId,
    required String repoName,
    required String path,
    required int depth,
  }) {
    final args = (
      workspaceId: widget.workspaceId,
      repoId: repoId,
      path: path,
      spaceId: widget.spaceId,
    );
    final async = ref.watch(repoDirectoryListingProvider(args));
    final listing = async.value;
    if (listing == null) {
      rows.add(
        _TreeRow.placeholder(
          async.hasError ? _TreeRowKind.error : _TreeRowKind.loading,
          depth: depth,
          listingArgs: async.hasError ? args : null,
        ),
      );
      return;
    }
    // A complete listing that already had data on this mount's first build
    // came from the held cache, so re-check it against disk once. Anything
    // mid-drain is left alone: re-running it would restart the paging it is
    // halfway through.
    if (_revalidateOnMount &&
        !async.isLoading &&
        !listing.hasMore &&
        !listing.loadingMore &&
        !listing.failed) {
      stale.add(args);
    }
    // `listing.entries` arrives in display order (directories first, then
    // files, case-insensitive) — sorted once per page by the notifier, not
    // per build here.
    final expandedDirs = _view.expandedDirs;
    for (final entry in listing.entries) {
      final slash = entry.relativePath.lastIndexOf('/');
      final name = slash < 0
          ? entry.relativePath
          : entry.relativePath.substring(slash + 1);
      final expanded = expandedDirs.contains(
        _dirKey(repoId, entry.relativePath),
      );
      final showChevron = !entry.isDirectory
          ? false
          : expanded && _dirKnownEmpty(repoId, entry.relativePath)
          ? false
          : true;
      rows.add(
        _TreeRow.node(
          RepoFileNode(
            name: name,
            repoId: repoId,
            fullRelativePath: entry.relativePath,
            isDirectory: entry.isDirectory,
          ),
          depth: depth,
          expanded: expanded,
          repoName: repoName,
          showChevron: showChevron,
        ),
      );
      if (entry.isDirectory && expanded) {
        _appendDirectoryRows(
          rows,
          drain,
          stale,
          repoId: repoId,
          repoName: repoName,
          path: entry.relativePath,
          depth: depth + 1,
        );
      }
    }
    if (listing.loadingMore) {
      rows.add(_TreeRow.placeholder(_TreeRowKind.loadingMore, depth: depth));
    } else if (listing.failed) {
      rows.add(
        _TreeRow.placeholder(
          _TreeRowKind.error,
          depth: depth,
          listingArgs: args,
        ),
      );
    } else if (listing.hasMore) {
      drain.add(args);
    }
  }

  /// Pulls the next cursor page of every directory that still has one, one
  /// frame later — mutating provider state during build is not allowed, and
  /// deferring to post-frame lets the notifier's synchronous `loadingMore`
  /// write stop the next pass from double-scheduling.
  void _scheduleDrain(List<RepoDirectoryListingArgs> drain) {
    if (drain.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      for (final args in drain) {
        final provider = repoDirectoryListingProvider(args);
        // Never resurrect a listing this frame dropped — read the notifier
        // only where one already exists. A directory collapsed between the
        // build and this callback is held (not disposed) by the listing
        // cache, so it takes ONE more page and then falls out of the walk,
        // which is where the drain gets its next list from.
        if (ref.exists(provider)) {
          ref.read(provider.notifier).loadMore();
        }
      }
    });
  }

  /// Re-fetches, once per mount and one frame later, the complete listings the
  /// tree painted from cache.
  ///
  /// A held listing is what makes returning to the Explorer instant, but it is
  /// a snapshot of a directory an agent may have written to since. Refreshing
  /// keeps the previous value on screen (Riverpod carries it through the
  /// reload), so this corrects the tree without ever blanking it.
  void _scheduleRevalidate(List<RepoDirectoryListingArgs> stale) {
    if (!_revalidateOnMount) {
      return;
    }
    _revalidateOnMount = false;
    if (stale.isEmpty) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      for (final args in stale) {
        final provider = repoDirectoryListingProvider(args);
        if (ref.exists(provider)) {
          ref.invalidate(provider);
        }
      }
    });
  }

  /// Renders the tree (or its empty states). Only the very first load shows a
  /// centered spinner; directories carry their own inline placeholder rows.
  Widget _buildTreeBody(
    List<_TreeRow> rows,
    Map<String, Repo> repoById,
    AppLocalizations l10n,
  ) {
    if (repoById.isEmpty) {
      return CcEmptyState(
        icon: AppIcons.folderTree,
        // A conversation with no checkout is a different fact from a workspace
        // with no repos, and only one of them is fixed in settings.
        message: widget.spaceId == null
            ? l10n.noReposInWorkspaceYet
            : l10n.noReposInConversation,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: rows.length,
      itemBuilder: (context, i) => _TreeRowTile(
        row: rows[i],
        onToggle: _toggleRow,
        onOpenFile: (node) => widget.onOpenFile((
          repoId: node.repoId,
          path: node.fullRelativePath,
        )),
        onQuickViewFile: widget.onQuickViewFile == null
            ? null
            : (node) => widget.onQuickViewFile!((
                repoId: node.repoId,
                path: node.fullRelativePath,
              )),
        onRetry: _retryRow,
      ),
    );
  }

  /// Retries a failed directory listing: a failed LATER page continues from
  /// the entries already fetched (the next `loadMore` clears `failed`); a
  /// failed FIRST page re-runs the provider from scratch.
  void _retryRow(_TreeRow row) {
    final args = row.listingArgs;
    if (args == null) {
      return;
    }
    final provider = repoDirectoryListingProvider(args);
    if (ref.read(provider).hasValue) {
      ref.read(provider.notifier).loadMore();
    } else {
      ref.invalidate(provider);
    }
  }

  /// Renders the paged flat results (fresh or retained) plus the empty /
  /// error states.
  Widget _buildSearchBody(
    RepoFileSearchState? search,
    Map<String, Repo> repoById, {
    required bool firstPageLoading,
    required bool hasError,
    required AppLocalizations l10n,
  }) {
    final hits = search?.hits ?? const <ExplorerHit>[];
    if (hits.isNotEmpty) {
      return _buildFilterList(hits, hasMore: search!.hasMore);
    }
    if (!_everLoaded) {
      if (firstPageLoading) {
        return const Center(child: CcSpinner());
      }
      if (hasError) {
        return CcEmptyState(
          icon: AppIcons.searchX,
          message: l10n.ideFileSearchFailed,
        );
      }
    }
    // Loaded (or previously loaded) and genuinely empty.
    return CcEmptyState(icon: AppIcons.searchX, message: l10n.noMatchingFiles);
  }

  /// Scroll listener for the flat results list: near the end (or already at
  /// an end shorter than the threshold — a short list has more pages), pull
  /// the next ranked page.
  void _onResultsScroll() {
    final args = _activeSearchArgs;
    final controller = _resultsController;
    if (args == null || controller == null || !controller.hasClients) {
      return;
    }
    if (!_activeSearchHasMore) {
      return;
    }
    final pos = controller.position;
    if (pos.maxScrollExtent - pos.pixels < _loadMoreThreshold) {
      ref.read(repoFileSearchProvider(args).notifier).loadMore();
    }
  }

  /// Content mode: grouped grep matches with highlighted lines. Returns
  /// `(loading, body)`.
  (bool, Widget) _contentView(
    AppLocalizations l10n,
    Map<String, Repo> repoById,
  ) {
    final query = _view.query;
    final args = (
      workspaceId: widget.workspaceId,
      query: query,
      options: _view.options,
      spaceId: widget.spaceId,
    );
    final async = ref.watch(repoContentSearchProvider(args));
    ref.listen(repoContentSearchProvider(args), (_, next) {
      final data = next.value;
      if (data != null && mounted) {
        setState(() {
          _lastContent = data;
          _contentEverLoaded = true;
        });
      }
    });
    final fresh = async.value;
    final results = fresh ?? _lastContent;
    final loading = async.isLoading;

    final Widget body;
    if (query.isEmpty) {
      body = CcEmptyState(
        icon: AppIcons.search,
        message: l10n.ideSearchInFiles,
      );
    } else if (results.isNotEmpty) {
      body = _ContentResults(
        results: results,
        query: query,
        repoById: repoById,
        onOpenFile: widget.onOpenFile,
      );
    } else if (loading && !_contentEverLoaded) {
      body = const Center(child: CcSpinner());
    } else {
      body = CcEmptyState(
        icon: AppIcons.searchX,
        message: l10n.ideNoContentMatches,
      );
    }
    return (loading, body);
  }

  /// The flat scored list, with a trailing spinner while another page loads
  /// and load-more armed by scroll position. Ranked (score desc, then path) by
  /// the search notifier as pages append, not here — the order of a page
  /// cannot change between rebuilds.
  Widget _buildFilterList(List<ExplorerHit> hits, {required bool hasMore}) {
    final sorted = hits;
    // One controller for the panel's lifetime (see its field doc); it
    // attaches while the flat list is on screen and detaches when the tree
    // or content mode replaces it.
    final controller = _resultsController ??= ScrollController()
      ..addListener(_onResultsScroll);
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: sorted.length + (hasMore ? 1 : 0),
      itemBuilder: (context, i) {
        if (i >= sorted.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
            child: Center(child: CcSpinner(size: 14, strokeWidth: 2)),
          );
        }
        final h = sorted[i];
        return _FilterHitTile(
          hit: h,
          onOpenFile: h.hit.isDirectory
              ? null
              : () => widget.onOpenFile((
                  repoId: h.repoId,
                  path: h.hit.relativePath,
                )),
          onQuickViewFile: (widget.onQuickViewFile == null || h.hit.isDirectory)
              ? null
              : () => widget.onQuickViewFile!((
                  repoId: h.repoId,
                  path: h.hit.relativePath,
                )),
        );
      },
    );
  }
}

class _TreeRowTile extends StatelessWidget {
  const _TreeRowTile({
    required this.row,
    required this.onToggle,
    required this.onOpenFile,
    required this.onRetry,
    this.onQuickViewFile,
  });

  final _TreeRow row;
  final ValueChanged<_TreeRow> onToggle;
  final ValueChanged<RepoFileNode> onOpenFile;
  final ValueChanged<_TreeRow> onRetry;
  final ValueChanged<RepoFileNode>? onQuickViewFile;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    if (row.kind != _TreeRowKind.node) {
      final indent = AppSpacing.sm + row.depth * 12.0;
      switch (row.kind) {
        case _TreeRowKind.loading:
        case _TreeRowKind.loadingMore:
          return Padding(
            padding: EdgeInsets.fromLTRB(indent + 14, 4, AppSpacing.sm, 4),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: CcSpinner(size: 12, strokeWidth: 2),
            ),
          );
        case _TreeRowKind.error:
          return CcTappable(
            // Tap retries the failed page (see the panel's _retryRow).
            onPressed: () => onRetry(row),
            borderRadius: BorderRadius.zero,
            builder: (context, states) => Padding(
              padding: EdgeInsets.fromLTRB(indent + 14, 4, AppSpacing.sm, 4),
              child: Row(
                children: [
                  Icon(AppIcons.triangleAlert, size: 14, color: t.textTertiary),
                  const SizedBox(width: AppSpacing.xs),
                  Flexible(
                    child: Text(
                      l10n.ideFolderLoadFailed,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(fontSize: 12, color: t.textTertiary),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    l10n.retry,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        case _TreeRowKind.node:
          break; // Unreachable; handled below.
      }
    }

    final node = row.node!;
    final isRepoRoot = row.depth == 0;
    final indent = AppSpacing.sm + row.depth * 12.0;

    final Widget leading = node.isDirectory
        ? Icon(
            row.expanded ? AppIcons.chevronDown : AppIcons.chevronRight,
            size: 14,
            color: t.textTertiary,
          )
        : const SizedBox(width: 14);

    final icon = node.isDirectory
        ? (isRepoRoot ? AppIcons.folderGit : AppIcons.folder)
        : AppIcons.fileCode;

    // Files support the read-only Quick view via long-press (touch) / secondary
    // click (desktop right-click); the editor stays the primary tap.
    final canQuickView = onQuickViewFile != null && !node.isDirectory;

    Widget tile = CcTappable(
      onPressed: () {
        if (node.isDirectory) {
          onToggle(row);
        } else {
          onOpenFile(node);
        }
      },
      onLongPress: canQuickView ? () => onQuickViewFile!(node) : null,
      borderRadius: BorderRadius.zero,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: hovered ? t.hover : const Color(0x00000000),
          ),
          child: Padding(
            padding: EdgeInsets.fromLTRB(indent, 4, AppSpacing.sm, 4),
            child: Row(
              children: [
                // A directory with no chevron keeps the row aligned with its
                // siblings (the file rows reserve the same 14px).
                row.showChevron ? leading : const SizedBox(width: 14),
                const SizedBox(width: AppSpacing.xs),
                Icon(icon, size: 14, color: t.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    node.name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: isRepoRoot ? 13 : 12,
                      fontWeight: isRepoRoot
                          ? FontWeight.w600
                          : CcTypography.regularWeight,
                      color: isRepoRoot ? t.textPrimary : t.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (canQuickView) {
      tile = GestureDetector(
        onSecondaryTap: () => onQuickViewFile!(node),
        child: tile,
      );
    }
    return tile;
  }
}

class _FilterHitTile extends StatelessWidget {
  const _FilterHitTile({
    required this.hit,
    required this.onOpenFile,
    this.onQuickViewFile,
  });

  final ExplorerHit hit;
  final VoidCallback? onOpenFile;
  final VoidCallback? onQuickViewFile;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final isDir = hit.hit.isDirectory;
    // VS Code-style: `<basename>` prominent + `<dirname>` (the folder path) in
    // smaller dimmed text on the same row — mirrors the content-search file
    // headers and the Source Control rows.
    final path = hit.hit.relativePath;
    final slash = path.lastIndexOf('/');
    final name = slash < 0 ? path : path.substring(slash + 1);
    final dir = slash < 0 ? '' : path.substring(0, slash);

    Widget tile = CcTappable(
      onPressed: onOpenFile,
      // Long-press (touch) opens the read-only Quick view.
      onLongPress: onQuickViewFile,
      borderRadius: BorderRadius.zero,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: hovered ? t.hover : const Color(0x00000000),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: 4,
            ),
            child: Row(
              children: [
                Icon(
                  isDir ? AppIcons.folder : AppIcons.fileCode,
                  size: 14,
                  color: t.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                ),
                if (dir.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      dir,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(fontSize: 11, color: t.textTertiary),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );

    // Secondary click (desktop right-click) opens the read-only Quick view.
    if (onQuickViewFile != null) {
      tile = GestureDetector(onSecondaryTap: onQuickViewFile, child: tile);
    }
    return tile;
  }
}

/// One flattened row in the content-results list: a file header or a match line.
class _ContentRow {
  const _ContentRow.header(this.group) : match = null, isHeader = true;
  const _ContentRow.match(this.group, this.match) : isHeader = false;

  final FileContentMatch group;
  final ContentMatchLine? match;
  final bool isHeader;
}

/// VS Code-style content results: each file is a collapsible header (path +
/// match count) over its matching lines, the query highlighted in each.
class _ContentResults extends StatefulWidget {
  const _ContentResults({
    required this.results,
    required this.query,
    required this.repoById,
    required this.onOpenFile,
  });

  final List<FileContentMatch> results;
  final String query;
  final Map<String, Repo> repoById;
  final ValueChanged<({String repoId, String path})> onOpenFile;

  @override
  State<_ContentResults> createState() => _ContentResultsState();
}

class _ContentResultsState extends State<_ContentResults> {
  /// Collapsed file keys (`'<repoId>:<relativePath>'`). Empty = all expanded.
  final Set<String> _collapsed = <String>{};

  String _key(FileContentMatch g) => '${g.repoId}:${g.relativePath}';

  @override
  Widget build(BuildContext context) {
    final rows = <_ContentRow>[];
    for (final g in widget.results) {
      rows.add(_ContentRow.header(g));
      if (!_collapsed.contains(_key(g))) {
        for (final m in g.lines) {
          rows.add(_ContentRow.match(g, m));
        }
      }
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: rows.length,
      itemBuilder: (context, i) {
        final row = rows[i];
        if (row.isHeader) {
          final g = row.group;
          return _ContentFileHeader(
            group: g,
            collapsed: _collapsed.contains(_key(g)),
            onToggle: () => setState(() {
              final k = _key(g);
              _collapsed.contains(k) ? _collapsed.remove(k) : _collapsed.add(k);
            }),
          );
        }
        final g = row.group;
        return _ContentMatchRow(
          match: row.match!,
          query: widget.query,
          onTap: () =>
              widget.onOpenFile((repoId: g.repoId, path: g.relativePath)),
        );
      },
    );
  }
}

class _ContentFileHeader extends StatelessWidget {
  const _ContentFileHeader({
    required this.group,
    required this.collapsed,
    required this.onToggle,
  });

  final FileContentMatch group;
  final bool collapsed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final path = group.relativePath;
    final slash = path.lastIndexOf('/');
    final name = slash < 0 ? path : path.substring(slash + 1);
    final dir = slash < 0 ? '' : path.substring(0, slash);

    return CcTappable(
      onPressed: onToggle,
      borderRadius: BorderRadius.zero,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: hovered ? t.hover : const Color(0x00000000),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.sm,
              4,
              AppSpacing.sm,
              4,
            ),
            child: Row(
              children: [
                Icon(
                  collapsed ? AppIcons.chevronRight : AppIcons.chevronDown,
                  size: 14,
                  color: t.textTertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Icon(AppIcons.fileCode, size: 14, color: t.textSecondary),
                const SizedBox(width: AppSpacing.xs),
                Flexible(
                  child: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: t.textPrimary,
                    ),
                  ),
                ),
                if (dir.isNotEmpty) ...[
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: Text(
                      dir,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(fontSize: 11, color: t.textTertiary),
                    ),
                  ),
                ] else
                  const Spacer(),
                const SizedBox(width: AppSpacing.xs),
                _CountBadge(count: group.lines.length),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContentMatchRow extends StatelessWidget {
  const _ContentMatchRow({
    required this.match,
    required this.query,
    required this.onTap,
  });

  final ContentMatchLine match;
  final String query;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final display = match.text.trimLeft();
    final base = CcFonts.code(
      textStyle: TextStyle(fontSize: 12, color: t.textSecondary),
    );
    return CcTappable(
      onPressed: onTap,
      borderRadius: BorderRadius.zero,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return DecoratedBox(
          decoration: BoxDecoration(
            color: hovered ? t.hover : const Color(0x00000000),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(34, 3, AppSpacing.sm, 3),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 34,
                  child: Text(
                    '${match.line}',
                    textAlign: TextAlign.right,
                    style: TextStyle(fontSize: 11, color: t.textTertiary),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: RichText(
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    text: TextSpan(
                      style: base,
                      children: _highlightSpans(
                        display,
                        query,
                        highlight: TextStyle(
                          backgroundColor: t.bgWarningSecondary,
                          color: t.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// Small pill showing a file's match count (VS Code-style right badge).
class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: t.bgSecondary,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        '$count',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: t.textSecondary,
        ),
      ),
    );
  }
}

/// Splits [text] into spans, wrapping each case-insensitive occurrence of
/// [query] in [highlight]. Non-matching runs inherit the ambient style.
List<InlineSpan> _highlightSpans(
  String text,
  String query, {
  required TextStyle highlight,
}) {
  if (query.isEmpty) {
    return [TextSpan(text: text)];
  }
  final lower = text.toLowerCase();
  final q = query.toLowerCase();
  final spans = <InlineSpan>[];
  var i = 0;
  while (i < text.length) {
    final idx = lower.indexOf(q, i);
    if (idx < 0) {
      spans.add(TextSpan(text: text.substring(i)));
      break;
    }
    if (idx > i) {
      spans.add(TextSpan(text: text.substring(i, idx)));
    }
    spans.add(
      TextSpan(text: text.substring(idx, idx + q.length), style: highlight),
    );
    i = idx + q.length;
  }
  return spans;
}

/// A small toggle icon-button for a content-search option (case/regex/word).
/// Shows a pressed/selected visual when [active].
class _OptionToggle extends StatelessWidget {
  const _OptionToggle({
    required this.icon,
    required this.tooltip,
    required this.active,
    required this.onChanged,
  });

  final IconData icon;
  final String tooltip;
  final bool active;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    return CcTooltip(
      message: tooltip,
      showDelay: const Duration(milliseconds: 400),
      child: CcTappable(
        onPressed: () => onChanged(!active),
        semanticLabel: tooltip,
        borderRadius: BorderRadius.circular(3),
        builder:
            (context, states) => Container(
              width: 20,
              height: 20,
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color:
                    (active || states.contains(WidgetState.hovered))
                        ? t.hover
                        : const Color(0x00000000),
                borderRadius: BorderRadius.circular(3),
              ),
              child: Icon(
                icon,
                size: 13,
                color: active
                    ? t.fg
                    : (states.contains(WidgetState.hovered)
                          ? t.textSecondary
                          : t.textTertiary),
              ),
            ),
      ),
    );
  }
}

/// A compact button that expands/collapses the include/exclude glob fields.
class _FiltersButton extends StatelessWidget {
  const _FiltersButton({required this.expanded, required this.onPressed});

  final bool expanded;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onPressed,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                AppIcons.slidersHorizontal,
                size: 13,
                color: expanded ? t.fg : t.textTertiary,
              ),
              const SizedBox(width: 4),
              Text(
                l10n.ideSearchFilters,
                style: TextStyle(
                  fontSize: 11,
                  color: expanded ? t.fg : t.textTertiary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
