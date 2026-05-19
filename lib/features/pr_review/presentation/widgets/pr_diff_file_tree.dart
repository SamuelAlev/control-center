import 'dart:async';

import 'package:control_center/core/theme/design_system_tokens.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_file_tree.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_palette.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/widgets/ready_auto_scroll.dart';
import 'package:flutter/material.dart';
import 'package:forui/forui.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

/// Collapsible left sidebar listing changed files in a directory tree.
/// Clicking a file leaf invokes [onSelectFile] with the file's index in the
/// parent diff's `files` list — the parent uses this to scroll the
/// [CustomScrollView] to that file.
class PrDiffFileTree extends StatefulWidget {
  /// PrDiffFileTree({.
  const PrDiffFileTree({
    super.key,
    required this.roots,
    required this.onSelectFile,
    this.selectedFileIndex,
    this.viewedPaths = const <String>{},
  });

  /// Root-level tree nodes built via [buildDiffFileTree].
  final List<DiffTreeNode> roots;

  /// Invoked with the file's index when a file leaf is tapped.
  final ValueChanged<int> onSelectFile;

  /// Currently-selected file index. Highlighted in the tree.
  final int? selectedFileIndex;

  /// Paths the user has marked viewed. Rendered with a subtle "viewed" dot.
  final Set<String> viewedPaths;

  @override
  State<PrDiffFileTree> createState() => _PrDiffFileTreeState();
}

class _PrDiffFileTreeState extends State<PrDiffFileTree> {
  /// Per-directory open state. Defaults to "open" (true) — keying off the
  /// directory path so adding/removing files doesn't reset the user's
  /// chosen layout.
  final Map<String, bool> _open = {};

  /// Free-text filter; case-insensitive substring match on full path.
  String _filter = '';

  /// Status filter — null = "show all". Otherwise filter to files with this
  /// status (added / modified / removed / renamed).
  String? _statusFilter;

  /// Local scroll controller so the tree's [ListView] doesn't inherit the
  /// page's [PrimaryScrollController] — scrolling the diff and scrolling
  /// the tree must be independent.
  final ScrollController _scrollController = ScrollController();

  /// Bumped on every [_toggle] so the flatten cache knows to invalidate.
  int _openVersion = 0;

  /// Debounces filter input so typing doesn't re-flatten 3000 nodes per
  /// keystroke.
  Timer? _filterDebounce;

  // --- Memoised filter + flatten ---------------------------------------
  // Cache the filtered roots (since `_applyFilters` allocates new
  // [DiffTreeNode.dir] instances) and the flattened row list, invalidated
  // only when the relevant inputs actually change. Re-flattening 3000 nodes
  // on every unrelated rebuild was the source of sidebar jank.
  List<DiffTreeNode>? _filteredCache;
  List<DiffTreeNode>? _filteredCacheRoots;
  String? _filteredCacheFilter;
  String? _filteredCacheStatus;

  List<_FlatRowSpec>? _flatCache;
  List<DiffTreeNode>? _flatCacheFiltered;
  int _flatCacheOpenVersion = -1;

  @override
  void dispose() {
    _filterDebounce?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  bool _isOpen(String path) => _open[path] ?? true;

  void _toggle(String path) {
    setState(() {
      _open[path] = !_isOpen(path);
      _openVersion++;
    });
  }

  void _onFilterChanged(String v) {
    _filterDebounce?.cancel();
    _filterDebounce = Timer(const Duration(milliseconds: 150), () {
      if (!mounted || _filter == v) {
        return;
      }
      setState(() => _filter = v);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final palette = DiffPalette.of(context);
    final filteredRoots = _memoFilteredRoots(widget.roots);
    final flatRows = _memoFlattenedSpecs(filteredRoots);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FilterBar(
          onChanged: _onFilterChanged,
          statusFilter: _statusFilter,
          onStatusFilterChanged: (s) => setState(() => _statusFilter = s),
        ),
        const Divider(height: 1),
        if (flatRows.isEmpty)
          Expanded(
            child: Align(
              alignment: Alignment.topCenter,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  AppLocalizations.of(context).noMatchingFiles,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: theme.colors.mutedForeground,
                  ),
                ),
              ),
            ),
          )
        else
          Expanded(
            child: Scrollbar(
              controller: _scrollController,
              thumbVisibility: true,
              child: ReadyAutoScroll(
                controller: _scrollController,
                child: ListView.builder(
                  controller: _scrollController,
                  primary: false,
                  padding: EdgeInsets.zero,
                  itemCount: flatRows.length,
                  // Every row is the same fixed height (single line + constant
                  // padding); handing the list a prototype switches it to
                  // fixed-extent scrolling (O(1) index math, no per-row
                  // measurement) so 3000 files scroll smoothly. Zero visual
                  // change — the prototype's height is a real row's height.
                  prototypeItem: _TreeRow(
                    node: flatRows.first.node,
                    depth: 0,
                    isOpen: _isOpen,
                    onToggle: _toggle,
                    onSelectFile: widget.onSelectFile,
                    selectedFileIndex: null,
                    viewedPaths: const <String>{},
                    palette: palette,
                  ),
                  itemBuilder: (context, i) {
                    final spec = flatRows[i];
                    return _TreeRow(
                      node: spec.node,
                      depth: spec.depth,
                      isOpen: _isOpen,
                      onToggle: _toggle,
                      onSelectFile: widget.onSelectFile,
                      selectedFileIndex: widget.selectedFileIndex,
                      viewedPaths: widget.viewedPaths,
                      palette: palette,
                    );
                  },
                ),
              ),
            ),
          ),
      ],
    );
  }

  List<DiffTreeNode> _memoFilteredRoots(List<DiffTreeNode> roots) {
    if (identical(_filteredCacheRoots, roots) &&
        _filteredCacheFilter == _filter &&
        _filteredCacheStatus == _statusFilter &&
        _filteredCache != null) {
      return _filteredCache!;
    }
    final out = _applyFilters(roots);
    _filteredCache = out;
    _filteredCacheRoots = roots;
    _filteredCacheFilter = _filter;
    _filteredCacheStatus = _statusFilter;
    return out;
  }

  List<_FlatRowSpec> _memoFlattenedSpecs(List<DiffTreeNode> filtered) {
    if (identical(_flatCacheFiltered, filtered) &&
        _flatCacheOpenVersion == _openVersion &&
        _flatCache != null) {
      return _flatCache!;
    }
    final out = <_FlatRowSpec>[];
    _flattenInto(out, filtered, 0);
    _flatCache = out;
    _flatCacheFiltered = filtered;
    _flatCacheOpenVersion = _openVersion;
    return out;
  }

  void _flattenInto(
    List<_FlatRowSpec> out,
    List<DiffTreeNode> nodes,
    int depth,
  ) {
    for (final node in nodes) {
      out.add(_FlatRowSpec(node: node, depth: depth));
      if (node.isDirectory && _isOpen(node.path)) {
        _flattenInto(out, node.children, depth + 1);
      }
    }
  }

  /// Returns roots with non-matching leaves pruned. Empty directories are
  /// dropped. Single-child collapse already happens in [buildDiffFileTree],
  /// so this just filters and propagates counts.
  List<DiffTreeNode> _applyFilters(List<DiffTreeNode> roots) {
    if (_filter.isEmpty && _statusFilter == null) {
      return roots;
    }

    final out = <DiffTreeNode>[];
    for (final node in roots) {
      final filtered = _filterNode(node);
      if (filtered != null) {
        out.add(filtered);
      }
    }
    return out;
  }

  DiffTreeNode? _filterNode(DiffTreeNode node) {
    if (!node.isDirectory) {
      // Leaf — keep if it matches both filters.
      final matchesText =
          _filter.isEmpty ||
          node.path.toLowerCase().contains(_filter.toLowerCase());
      final matchesStatus =
          _statusFilter == null || node.status == _statusFilter;
      return (matchesText && matchesStatus) ? node : null;
    }
    final keptChildren = <DiffTreeNode>[];
    for (final c in node.children) {
      final filtered = _filterNode(c);
      if (filtered != null) {
        keptChildren.add(filtered);
      }
    }
    if (keptChildren.isEmpty) {
      return null;
    }

    var additions = 0;
    var deletions = 0;
    var fileCount = 0;
    for (final c in keptChildren) {
      additions += c.additions;
      deletions += c.deletions;
      fileCount += c.fileCount;
    }
    return DiffTreeNode.dir(
      name: node.name,
      path: node.path,
      children: keptChildren,
      additions: additions,
      deletions: deletions,
      fileCount: fileCount,
    );
  }
}

/// One row in the flattened tree — paired with its visual depth so the
/// list builder can hand it to [_TreeRow] without re-walking the tree.
class _FlatRowSpec {
  const _FlatRowSpec({required this.node, required this.depth});
  final DiffTreeNode node;
  final int depth;
}

class _FilterBar extends StatefulWidget {
  const _FilterBar({
    required this.onChanged,
    required this.statusFilter,
    required this.onStatusFilterChanged,
  });

  final ValueChanged<String> onChanged;
  final String? statusFilter;
  final ValueChanged<String?> onStatusFilterChanged;

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  final _ctrl = TextEditingController();
  final _chipScrollCtrl = ScrollController();

  @override
  void dispose() {
    _ctrl.dispose();
    _chipScrollCtrl.dispose();
    super.dispose();
  }

  void _scrollChips(double delta) {
    _chipScrollCtrl.animateTo(
      (_chipScrollCtrl.offset + delta).clamp(
        _chipScrollCtrl.position.minScrollExtent,
        _chipScrollCtrl.position.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: _ctrl,
            style: Theme.of(context).textTheme.bodySmall,
            onChanged: widget.onChanged,
            decoration: InputDecoration(
              hintText: AppLocalizations.of(context).filterFilesHint,
              isDense: true,
              prefixIcon: Icon(
                LucideIcons.search,
                size: 14,
                color: theme.colors.mutedForeground,
              ),
              prefixIconConstraints: const BoxConstraints(
                minWidth: 28,
                minHeight: 28,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: theme.colors.border),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 8,
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            height: 24,
            child: Row(
              children: [
                FButton.icon(
                  size: FButtonSizeVariant.xs,
                  variant: FButtonVariant.ghost,
                  onPress: () => _scrollChips(-80),
                  child: const Icon(LucideIcons.chevronLeft, size: 14),
                ),
                Expanded(
                  child: ListView(
                    controller: _chipScrollCtrl,
                    scrollDirection: Axis.horizontal,
                    children: [
                      _StatusChip(
                        label: l10n.all,
                        selected: widget.statusFilter == null,
                        onTap: () => widget.onStatusFilterChanged(null),
                      ),
                      _StatusChip(
                        label: l10n.added,
                        selected: widget.statusFilter == 'added',
                        onTap: () => widget.onStatusFilterChanged('added'),
                      ),
                      _StatusChip(
                        label: l10n.modified,
                        selected: widget.statusFilter == 'modified',
                        onTap: () => widget.onStatusFilterChanged('modified'),
                      ),
                      _StatusChip(
                        label: l10n.removed,
                        selected: widget.statusFilter == 'removed',
                        onTap: () => widget.onStatusFilterChanged('removed'),
                      ),
                      _StatusChip(
                        label: l10n.renamed,
                        selected: widget.statusFilter == 'renamed',
                        onTap: () => widget.onStatusFilterChanged('renamed'),
                      ),
                    ],
                  ),
                ),
                FButton.icon(
                  size: FButtonSizeVariant.xs,
                  variant: FButtonVariant.ghost,
                  onPress: () => _scrollChips(80),
                  child: const Icon(LucideIcons.chevronRight, size: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: FTappable.static(
        onPress: onTap,
        focusedOutlineStyle: const FFocusedOutlineStyleDelta.context(),
        child: Container(
            height: 22,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: selected
                  ? theme.colors.foreground
                  : theme.colors.secondary.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected
                    ? theme.colors.background
                    : theme.colors.mutedForeground,
                fontWeight: FontWeight.w600,
                height: 1.0,
            ),
          ),
        ),
      ),
    );
  }
}

class _TreeRow extends StatelessWidget {
  const _TreeRow({
    required this.node,
    required this.depth,
    required this.isOpen,
    required this.onToggle,
    required this.onSelectFile,
    required this.selectedFileIndex,
    required this.viewedPaths,
    required this.palette,
  });

  final DiffTreeNode node;
  final int depth;
  final bool Function(String path) isOpen;
  final void Function(String path) onToggle;
  final ValueChanged<int> onSelectFile;
  final int? selectedFileIndex;
  final Set<String> viewedPaths;
  final DiffPalette palette;

  static const _indent = 16.0;

  @override
  Widget build(BuildContext context) {
    if (node.isDirectory) {
      final open = isOpen(node.path);
      return _Row(
        depth: depth,
        leading: Icon(
          open ? LucideIcons.chevronDown : LucideIcons.chevronRight,
          size: 12,
          color: context.theme.colors.mutedForeground,
        ),
        name: node.name,
        additions: node.additions,
        deletions: node.deletions,
        secondaryLabel: '${node.fileCount}',
        onTap: () => onToggle(node.path),
        selected: false,
        viewed: false,
        statusAccent: null,
      );
    }

    final accent = switch (node.status) {
      'added' => palette.additionAccent,
      'removed' => palette.deletionAccent,
      _ => palette.modifiedAccent,
    };
    return _Row(
      depth: depth,
      leading: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
      ),
      name: node.name,
      additions: node.additions,
      deletions: node.deletions,
      secondaryLabel: null,
      onTap: () => onSelectFile(node.fileIndex!),
      selected: selectedFileIndex == node.fileIndex,
      viewed: viewedPaths.contains(node.path),
      statusAccent: accent,
    );
  }
}

class _Row extends StatefulWidget {
  const _Row({
    required this.depth,
    required this.leading,
    required this.name,
    required this.additions,
    required this.deletions,
    required this.secondaryLabel,
    required this.onTap,
    required this.selected,
    required this.viewed,
    required this.statusAccent,
  });

  final int depth;
  final Widget leading;
  final String name;
  final int additions;
  final int deletions;
  final String? secondaryLabel;
  final VoidCallback onTap;
  final bool selected;
  final bool viewed;
  final Color? statusAccent;

  @override
  State<_Row> createState() => _RowState();
}

class _RowState extends State<_Row> {
  bool _hovered = false;

  static const double _rowRadius = 6;
  static const EdgeInsets _rowMargin = EdgeInsets.symmetric(
    horizontal: 6,
    vertical: 1,
  );

  @override
  Widget build(BuildContext context) {
    final theme = context.theme;
    final tokens = context.designSystem;
    final palette = DiffPalette.of(context);

    final Color background;
    if (widget.selected) {
      background = theme.colors.secondary;
    } else if (_hovered) {
      background = tokens?.bgPrimaryHover ?? theme.colors.secondary;
    } else {
      background = Colors.transparent;
    }

    // Tree guide-line color — subtle, just enough to read the structure
    // without competing with file names. Sits behind the hover/selected fill.
    final guideColor = tokens?.borderSecondary ?? theme.colors.border;

    return FTappable.static(
      onPress: widget.onTap,
      focusedOutlineStyle: const FFocusedOutlineStyleDelta.context(),
      onHoverChange: (hovered) {
        if (hovered != _hovered) {
          setState(() => _hovered = hovered);
        }
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Stack(
          children: [
            // Vertical guide lines, one per ancestor depth. Drawn at the
            // top level (outside the row's vertical margin) so consecutive
            // rows render a continuous line through their shared ancestor's
            // children — the line visually starts at the caret of that
            // ancestor and stops when the next equal- or shallower-depth
            // row breaks the chain.
            for (var a = 0; a < widget.depth; a++)
              Positioned(
                // 6 = horizontal row margin; 8 = container left padding;
                // 7 = half of the 14-wide caret box → caret centre.
                left: 6 + 8 + a * _TreeRow._indent + 7 - 0.5,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: SizedBox(
                    width: 1,
                    child: ColoredBox(color: guideColor),
                  ),
                ),
              ),
            Padding(
              padding: _rowMargin,
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: background,
                      borderRadius: BorderRadius.circular(_rowRadius),
                    ),
                    padding: EdgeInsets.fromLTRB(
                      8 + widget.depth * _TreeRow._indent,
                      7,
                      10,
                      7,
                    ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 14,
                      child: Center(child: widget.leading),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        widget.name,
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: widget.viewed
                              ? theme.colors.mutedForeground
                              : theme.colors.foreground,
                          fontWeight: widget.selected
                              ? FontWeight.w600
                              : FontWeight.w500,
                          decoration: widget.viewed
                              ? TextDecoration.lineThrough
                              : null,
                          decorationColor: theme.colors.mutedForeground,
                          height: 1.25,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (widget.additions > 0)
                      Text(
                        '+${widget.additions}',
                        style: TextStyle(
                          color: palette.additionAccent,
                          fontSize: 12,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    if (widget.additions > 0 && widget.deletions > 0)
                      const SizedBox(width: 6),
                    if (widget.deletions > 0)
                      Text(
                        '−${widget.deletions}',
                        style: TextStyle(
                          color: palette.deletionAccent,
                          fontSize: 12,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                          fontFeatures: const [FontFeature.tabularFigures()],
                        ),
                      ),
                    if (widget.secondaryLabel != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 1,
                        ),
                        decoration: BoxDecoration(
                          color: theme.colors.secondary.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          widget.secondaryLabel!,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: theme.colors.mutedForeground,
                                fontWeight: FontWeight.w600,
                                height: 1.2,
                                fontFeatures: const [
                                  FontFeature.tabularFigures(),
                                ],
                              ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
                  // Left accent rule for the selected file — tucked just inside
                  // the rounded fill so the rounding stays clean.
                  if (widget.selected && widget.statusAccent != null)
                    Positioned(
                      left: 0,
                      top: 4,
                      bottom: 4,
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: widget.statusAccent,
                          borderRadius: BorderRadius.circular(2),
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

