import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show FileSearchHit;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/repo_content_search_provider.dart';
import 'package:control_center/features/messaging/providers/repo_file_search_provider.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A scored file hit paired with the repo id it belongs to (the value type of
/// [repoFileSearchProvider]).
typedef ExplorerHit = ({FileSearchHit hit, String repoId});

/// Which axis the Explorer searches: file names/paths, or file contents.
enum ExplorerSearchMode {
  /// Fuzzy-match the query against file names/paths (the default; empty query
  /// shows the full tree).
  filename,

  /// Grep the query across file contents, grouping matching lines per file.
  content,
}

/// One node in the explorer's per-repo file tree, built from flat relative
/// paths. Pure data — no Flutter dependency — so it can be cached and rebuilt
/// cheaply.
class RepoFileNode {
  /// Creates a [RepoFileNode].
  RepoFileNode({
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

  /// Child segments, keyed by [name].
  final Map<String, RepoFileNode> children = {};
}

/// A flattened, visible tree row ready for a [ListView.builder].
class _TreeRow {
  const _TreeRow({
    required this.node,
    required this.depth,
    required this.expanded,
    required this.repoName,
  });

  final RepoFileNode node;

  /// Indentation depth; `0` is the per-repo root row.
  final int depth;

  /// Whether this (directory) row is currently expanded.
  final bool expanded;

  /// The repo's display name (used for the root row label).
  final String repoName;
}

/// Explorer panel: a per-repo file tree with two search surfaces, swapped by
/// the trailing toggle button (mirrors the PR diff sidebar's tree ⇄
/// search-in-files pattern).
///
/// Filename mode — empty query → full per-repo tree (collapsible dirs); typed
/// query → flat scored list (fff runs server-side via
/// [repoFileSearchProvider]). Content mode — `git grep` across the workspace's
/// linked repos ([repoContentSearchProvider]) with case/regex/whole-word
/// toggles and include/exclude glob filters. Clicking a file opens it in the
/// editor; clicking a dir toggles its expansion.
class ExplorerPanel extends ConsumerStatefulWidget {
  /// Creates an [ExplorerPanel].
  const ExplorerPanel({
    super.key,
    required this.workspaceId,
    required this.onOpenFile,
    this.onQuickViewFile,
  });

  /// The workspace whose linked repos the tree is scoped to.
  final String workspaceId;

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

  final TextEditingController _filterController = TextEditingController();
  Timer? _debounce;
  String _debouncedQuery = '';

  /// Expanded sub-directory keys (`'<repoId>:<relativePath>'`). Membership =
  /// expanded. Empty by default → all sub-dirs collapsed (VS Code-like).
  final Set<String> _expandedDirs = <String>{};

  /// Collapsed repo-root ids. Membership = collapsed. Empty by default → all
  /// repo roots expanded.
  final Set<String> _collapsedRepos = <String>{};

  // Memoized per-repo roots — rebuilt only when the watched hit list identity
  // changes (e.g. not on a pure expand/collapse rebuild).
  List<ExplorerHit>? _cachedHits;
  final Map<String, RepoFileNode> _repoRoots = {};

  // Last result we rendered, retained across query changes so typing (or
  // clearing) the filter keeps the current content on screen while the next
  // result loads — the spinner moves into the search field instead of blanking
  // the panel. `_everLoaded` gates the one-time initial spinner.
  List<ExplorerHit> _lastHits = const [];
  // The query `_lastHits` belongs to, so retained hits render in their own view
  // mode (tree for '', flat list otherwise) instead of the incoming query's.
  String _lastQuery = '';
  bool _everLoaded = false;

  /// Filename vs content search (the trailing toggle button swaps surfaces).
  ExplorerSearchMode _mode = ExplorerSearchMode.filename;

  // Content-mode counterpart of the filename retention above — keeps the last
  // grouped results on screen while the next query loads.
  List<FileContentMatch> _lastContent = const [];
  bool _contentEverLoaded = false;

  /// Content-search options (case/regex/whole-word + include/exclude globs).
  ContentSearchOptions _searchOptions = const ContentSearchOptions();

  /// Whether the include/exclude glob row is shown.
  bool _showFilters = false;

  /// Controllers for the include/exclude glob fields (kept across toggles so a
  /// user's typed globs survive a collapse/expand).
  final TextEditingController _includeController = TextEditingController();
  final TextEditingController _excludeController = TextEditingController();

  @override
  void dispose() {
    _debounce?.cancel();
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
      setState(() => _debouncedQuery = trimmed);
    });
  }

  /// Replaces the content-search options, re-triggering the debounced search.
  void _setSearchOptions(ContentSearchOptions options) {
    setState(() => _searchOptions = options);
    // Re-run the search immediately (a no-op when the query is empty).
    _onFilterChanged(_filterController.text);
  }

  /// Mirrors the include/exclude fields into [_searchOptions] and re-runs the
  /// search. Debounced via [_onFilterChanged].
  void _syncFilters(String _) {
    setState(() {
      _searchOptions = _searchOptions.copyWith(
        include: _includeController.text,
        exclude: _excludeController.text,
      );
    });
    _onFilterChanged(_filterController.text);
  }

  String _nodeKey(RepoFileNode node) =>
      '${node.repoId}:${node.fullRelativePath}';

  RepoFileNode _buildRepoRoot(Repo repo, List<ExplorerHit> hits) {
    final root = RepoFileNode(
      name: repo.fullName,
      repoId: repo.id,
      fullRelativePath: '',
      isDirectory: true,
    );
    for (final h in hits) {
      final segments = h.hit.relativePath
          .split('/')
          .where((s) => s.isNotEmpty)
          .toList();
      if (segments.isEmpty) {
        continue;
      }
      var current = root;
      for (var i = 0; i < segments.length; i++) {
        final segment = segments[i];
        final isLast = i == segments.length - 1;
        final childPath = segments.sublist(0, i + 1).join('/');
        var child = current.children[segment];
        if (child == null) {
          child = RepoFileNode(
            name: segment,
            repoId: repo.id,
            fullRelativePath: childPath,
            isDirectory: isLast ? h.hit.isDirectory : true,
          );
          current.children[segment] = child;
        }
        current = child;
      }
    }
    _sortNode(root);
    return root;
  }

  /// Directories first, then files, each alphabetical (case-insensitive).
  void _sortNode(RepoFileNode node) {
    if (node.children.isEmpty) {
      return;
    }
    final sorted = node.children.values.toList()
      ..sort((a, b) {
        if (a.isDirectory != b.isDirectory) {
          return a.isDirectory ? -1 : 1;
        }
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
    node.children
      ..clear()
      ..addEntries(sorted.map((e) => MapEntry(e.name, e)));
    for (final child in node.children.values) {
      _sortNode(child);
    }
  }

  /// Returns the cached per-repo root map, rebuilding it iff [hits] changed.
  Map<String, RepoFileNode> _rootsFor(
    List<ExplorerHit> hits,
    Map<String, Repo> repoById,
  ) {
    if (!identical(hits, _cachedHits)) {
      _repoRoots.clear();
      final byRepo = <String, List<ExplorerHit>>{};
      for (final h in hits) {
        byRepo.putIfAbsent(h.repoId, () => []).add(h);
      }
      for (final entry in byRepo.entries) {
        final repo = repoById[entry.key];
        if (repo == null) {
          continue;
        }
        _repoRoots[entry.key] = _buildRepoRoot(repo, entry.value);
      }
      _cachedHits = hits;
    }
    return _repoRoots;
  }

  void _flatten(
    RepoFileNode node,
    int depth,
    String repoName,
    List<_TreeRow> out,
  ) {
    final expanded = depth == 0
        ? !_collapsedRepos.contains(node.repoId)
        : _expandedDirs.contains(_nodeKey(node));
    out.add(
      _TreeRow(
        node: node,
        depth: depth,
        expanded: expanded,
        repoName: repoName,
      ),
    );
    if (node.isDirectory && expanded) {
      for (final child in node.children.values) {
        _flatten(child, depth + 1, repoName, out);
      }
    }
  }

  void _toggleRow(_TreeRow row) {
    setState(() {
      if (row.depth == 0) {
        final id = row.node.repoId;
        _collapsedRepos.contains(id)
            ? _collapsedRepos.remove(id)
            : _collapsedRepos.add(id);
      } else {
        final key = _nodeKey(row.node);
        _expandedDirs.contains(key)
            ? _expandedDirs.remove(key)
            : _expandedDirs.add(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final t = context.designSystem ?? DesignSystemTokens.light();

    final repos =
        ref.watch(reposForWorkspaceProvider(widget.workspaceId)).value ??
        const <Repo>[];
    final repoById = {for (final r in repos) r.id: r};

    // Each mode owns its provider + retention; both surface a (loading, body).
    final (loading, body) = _mode == ExplorerSearchMode.content
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
                      hintText: _mode == ExplorerSearchMode.content
                          ? l10n.ideSearchInFiles
                          : l10n.searchPlaceholder,
                      size: CcTextFieldSize.sm,
                      // Filter (filename) vs search (content) — the prefix
                      // mirrors the PR sidebar's two surfaces so the active
                      // mode is legible at a glance.
                      prefix: Icon(
                        _mode == ExplorerSearchMode.content
                            ? AppIcons.search
                            : AppIcons.listFilter,
                        size: 14,
                        color: t.textTertiary,
                      ),
                      // Loading lives in the field, not over the content, so
                      // results don't flicker away while a query is in flight.
                      // In content mode the suffix also carries the
                      // regex/word/case toggles.
                      suffix: _mode == ExplorerSearchMode.content
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _OptionToggle(
                                  icon: AppIcons.caseSensitive,
                                  tooltip: l10n.ideSearchMatchCase,
                                  active: _searchOptions.caseSensitive,
                                  onChanged: (v) => _setSearchOptions(
                                    _searchOptions.copyWith(caseSensitive: v),
                                  ),
                                ),
                                _OptionToggle(
                                  icon: AppIcons.regex,
                                  tooltip: l10n.ideSearchRegex,
                                  active: _searchOptions.regex,
                                  onChanged: (v) => _setSearchOptions(
                                    _searchOptions.copyWith(regex: v),
                                  ),
                                ),
                                _OptionToggle(
                                  icon: AppIcons.quote,
                                  tooltip: l10n.ideSearchWholeWord,
                                  active: _searchOptions.wholeWord,
                                  onChanged: (v) => _setSearchOptions(
                                    _searchOptions.copyWith(wholeWord: v),
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
                    icon: _mode == ExplorerSearchMode.content
                        ? AppIcons.list
                        : AppIcons.search,
                    tooltip: _mode == ExplorerSearchMode.content
                        ? l10n.showFileList
                        : l10n.searchInFiles,
                    onPressed: () => setState(() {
                      _mode = _mode == ExplorerSearchMode.content
                          ? ExplorerSearchMode.filename
                          : ExplorerSearchMode.content;
                    }),
                  ),
                ],
              ),
              if (_mode == ExplorerSearchMode.content) ...[
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Expanded(
                      child: _FiltersButton(
                        expanded: _showFilters,
                        onPressed: () =>
                            setState(() => _showFilters = !_showFilters),
                      ),
                    ),
                  ],
                ),
                if (_showFilters) ...[
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

  /// Filename mode: the fuzzy file tree / flat scored list, with no-flicker
  /// retention. Returns `(loading, body)`.
  (bool, Widget) _filenameView(
    AppLocalizations l10n,
    Map<String, Repo> repoById,
  ) {
    final args = (workspaceId: widget.workspaceId, query: _debouncedQuery);
    final hitsAsync = ref.watch(repoFileSearchProvider(args));
    ref.listen(repoFileSearchProvider(args), (_, next) {
      final data = next.asData;
      if (data != null && mounted) {
        setState(() {
          _lastHits = data.value;
          _lastQuery = args.query;
          _everLoaded = true;
        });
      }
    });
    final freshData = hitsAsync.asData;
    // Fresh result if present, else the last one we showed — with the query it
    // belongs to, so a retained tree never renders as a flat search list.
    final hits = freshData?.value ?? _lastHits;
    final effectiveQuery = freshData != null ? _debouncedQuery : _lastQuery;
    return (
      hitsAsync.isLoading,
      _buildBody(
        hits,
        repoById,
        query: effectiveQuery,
        loading: hitsAsync.isLoading,
        hasError: hitsAsync.hasError,
        l10n: l10n,
      ),
    );
  }

  /// Content mode: grouped grep matches with highlighted lines. Returns
  /// `(loading, body)`.
  (bool, Widget) _contentView(
    AppLocalizations l10n,
    Map<String, Repo> repoById,
  ) {
    final query = _debouncedQuery;
    final args = (
      workspaceId: widget.workspaceId,
      query: query,
      options: _searchOptions,
    );
    final async = ref.watch(repoContentSearchProvider(args));
    ref.listen(repoContentSearchProvider(args), (_, next) {
      final data = next.asData;
      if (data != null && mounted) {
        setState(() {
          _lastContent = data.value;
          _contentEverLoaded = true;
        });
      }
    });
    final fresh = async.asData;
    final results = fresh?.value ?? _lastContent;
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

  /// Renders the current [hits] (fresh or retained). Only the very first load
  /// (nothing cached yet) shows a centered spinner; afterwards the content
  /// stays put and loading is signalled in the search field.
  Widget _buildBody(
    List<ExplorerHit> hits,
    Map<String, Repo> repoById, {
    required String query,
    required bool loading,
    required bool hasError,
    required AppLocalizations l10n,
  }) {
    if (hits.isNotEmpty) {
      return query.isEmpty
          ? _buildTree(hits, repoById)
          : _buildFilterList(hits);
    }
    if (!_everLoaded) {
      if (loading) {
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
    return query.isEmpty
        ? CcEmptyState(
            icon: AppIcons.folderTree,
            message: l10n.noReposInWorkspaceYet,
          )
        : CcEmptyState(icon: AppIcons.searchX, message: l10n.noMatchingFiles);
  }

  Widget _buildTree(List<ExplorerHit> hits, Map<String, Repo> repoById) {
    final roots = _rootsFor(hits, repoById);
    final rows = <_TreeRow>[];
    // Follow the workspace's repo order for stable section ordering.
    for (final repo in repoById.values) {
      final root = roots[repo.id];
      if (root != null) {
        _flatten(root, 0, repo.fullName, rows);
      }
    }
    if (rows.isEmpty) {
      return CcEmptyState(
        icon: AppIcons.folderTree,
        message: AppLocalizations.of(context).noReposInWorkspaceYet,
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
      ),
    );
  }

  Widget _buildFilterList(List<ExplorerHit> hits) {
    final sorted = [...hits]
      ..sort((a, b) {
        final byScore = b.hit.score.compareTo(a.hit.score);
        if (byScore != 0) {
          return byScore;
        }
        return a.hit.relativePath.compareTo(b.hit.relativePath);
      });
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: sorted.length,
      itemBuilder: (context, i) {
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
    this.onQuickViewFile,
  });

  final _TreeRow row;
  final ValueChanged<_TreeRow> onToggle;
  final ValueChanged<RepoFileNode> onOpenFile;
  final ValueChanged<RepoFileNode>? onQuickViewFile;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final node = row.node;
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
                leading,
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
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => onChanged(!active),
          behavior: HitTestBehavior.opaque,
          child: Container(
            width: 20,
            height: 20,
            margin: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: active ? t.hover : const Color(0x00000000),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Icon(icon, size: 13, color: active ? t.fg : t.textTertiary),
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
