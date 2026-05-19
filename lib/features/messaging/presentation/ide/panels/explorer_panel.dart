import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show FileSearchHit;
import 'package:cc_domain/core/domain/entities/repo.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/messaging/providers/repo_file_search_provider.dart';
import 'package:control_center/features/repos/providers/repo_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A scored file hit paired with the repo id it belongs to (the value type of
/// [repoFileSearchProvider]).
typedef ExplorerHit = ({FileSearchHit hit, String repoId});

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

/// Explorer panel: a per-repo file tree with a fuzzy filter.
///
/// Empty query → full per-repo tree (collapsible dirs). Typed query → flat
/// scored list (fff runs server-side via [repoFileSearchProvider]). Clicking a
/// file opens it in the editor; clicking a dir toggles its expansion.
class ExplorerPanel extends ConsumerStatefulWidget {
  /// Creates an [ExplorerPanel].
  const ExplorerPanel({
    super.key,
    required this.workspaceId,
    required this.onOpenFile,
  });

  /// The workspace whose linked repos the tree is scoped to.
  final String workspaceId;

  /// Called with `(repoId, path)` when a file is opened.
  final ValueChanged<({String repoId, String path})> onOpenFile;

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

  @override
  void dispose() {
    _debounce?.cancel();
    _filterController.dispose();
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

  String _nodeKey(RepoFileNode node) => '${node.repoId}:${node.fullRelativePath}';

  RepoFileNode _buildRepoRoot(Repo repo, List<ExplorerHit> hits) {
    final root = RepoFileNode(
      name: repo.fullName,
      repoId: repo.id,
      fullRelativePath: '',
      isDirectory: true,
    );
    for (final h in hits) {
      final segments =
          h.hit.relativePath.split('/').where((s) => s.isNotEmpty).toList();
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
    out.add(_TreeRow(node: node, depth: depth, expanded: expanded, repoName: repoName));
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

    final hitsAsync = ref.watch(
      repoFileSearchProvider(
        (workspaceId: widget.workspaceId, query: _debouncedQuery),
      ),
    );
    final repos =
        ref.watch(reposForWorkspaceProvider(widget.workspaceId)).value ??
        const <Repo>[];
    final repoById = {for (final r in repos) r.id: r};

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.sm,
            AppSpacing.xs,
          ),
          child: CcTextField(
            controller: _filterController,
            hintText: l10n.searchPlaceholder,
            size: CcTextFieldSize.sm,
            prefix: Icon(AppIcons.search, size: 14, color: t.textTertiary),
            onChanged: _onFilterChanged,
          ),
        ),
        Expanded(
          child: hitsAsync.when(
            loading: () => const Center(child: CcSpinner()),
            error: (_, _) => CcEmptyState(
              icon: AppIcons.searchX,
              message: l10n.ideFileSearchFailed,
            ),
            data: (hits) {
              if (hits.isEmpty) {
                return CcEmptyState(
                  icon: AppIcons.folderTree,
                  message: l10n.ideFileSearchFailed,
                );
              }
              if (_debouncedQuery.isEmpty) {
                return _buildTree(hits, repoById);
              }
              return _buildFilterList(hits, repoById);
            },
          ),
        ),
      ],
    );
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
        message: AppLocalizations.of(context).ideFileSearchFailed,
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      itemCount: rows.length,
      itemBuilder: (context, i) => _TreeRowTile(
        row: rows[i],
        onToggle: _toggleRow,
        onOpenFile: (node) => widget.onOpenFile(
          (repoId: node.repoId, path: node.fullRelativePath),
        ),
      ),
    );
  }

  Widget _buildFilterList(List<ExplorerHit> hits, Map<String, Repo> repoById) {
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
        final repo = repoById[h.repoId];
        return _FilterHitTile(
          hit: h,
          repoName: repo?.fullName ?? h.repoId,
          onOpenFile: h.hit.isDirectory
              ? null
              : () => widget.onOpenFile(
                  (repoId: h.repoId, path: h.hit.relativePath),
                ),
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
  });

  final _TreeRow row;
  final ValueChanged<_TreeRow> onToggle;
  final ValueChanged<RepoFileNode> onOpenFile;

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

    return InkWell(
      onTap: () {
        if (node.isDirectory) {
          onToggle(row);
        } else {
          onOpenFile(node);
        }
      },
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
                  fontWeight: isRepoRoot ? FontWeight.w600 : FontWeight.w400,
                  color: isRepoRoot ? t.textPrimary : t.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterHitTile extends StatelessWidget {
  const _FilterHitTile({
    required this.hit,
    required this.repoName,
    required this.onOpenFile,
  });

  final ExplorerHit hit;
  final String repoName;
  final VoidCallback? onOpenFile;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final isDir = hit.hit.isDirectory;

    return InkWell(
      onTap: onOpenFile,
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
            Expanded(
              child: RichText(
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 12,
                    color: t.textSecondary,
                  ),
                  children: [
                    TextSpan(
                      text: '$repoName ',
                      style: TextStyle(color: t.textTertiary),
                    ),
                    TextSpan(text: hit.hit.relativePath),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
