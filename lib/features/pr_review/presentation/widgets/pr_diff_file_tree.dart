import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_file_tree.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_palette.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_sidebar_filter_controls.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/ready_auto_scroll.dart';
import 'package:flutter/material.dart';

/// Horizontal inset of the file-tree filter field. The Diff toolbar uses the
/// same value so the Tree chip left-aligns with the input below it.
const double kPrDiffTreeFilterInset = 6;

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
    this.onOpenSearch,
    this.onOpenFileInEditor,
  });

  /// Root-level tree nodes built via [buildDiffFileTree].
  final List<DiffTreeNode> roots;

  /// Invoked with the file's index when a file leaf is tapped.
  final ValueChanged<int> onSelectFile;

  /// Currently-selected file index. Highlighted in the tree.
  final int? selectedFileIndex;

  /// Paths the user has marked viewed. Rendered with a subtle "viewed" dot.
  final Set<String> viewedPaths;

  /// Switches the sidebar into "search in files" mode (the filter bar's search
  /// button, mirrored by ⌘F). Null hides the affordance.
  final VoidCallback? onOpenSearch;

  /// Opens a file (repo-relative path) in an editable code-server tab — the
  /// hover affordance on each file row. Null hides it.
  final ValueChanged<String>? onOpenFileInEditor;

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

  /// Below this panel height the fixed-height filter bar + divider cannot fit,
  /// so [build] renders only the background instead of letting the Column
  /// overflow. The tree is only ever this short during transient layout frames
  /// (e.g. while the PR header measures its async sidebar), so nothing usable
  /// is hidden.
  static const double _minPanelHeight = 96;

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
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    final palette = DiffPalette.of(context);
    final filteredRoots = _memoFilteredRoots(widget.roots);
    final flatRows = _memoFlattenedSpecs(filteredRoots);

    // The tree panel sits on the same white surface as the diff (see the
    // DecoratedSliver in pull_request_detail_screen.dart), not the warm
    // off-white page canvas it would otherwise show through to.
    return ColoredBox(
      color: tokens.bgPrimary,
      child: LayoutBuilder(
        builder: (context, constraints) {
          // During transient layout passes — e.g. while the PR header is still
          // measuring its async-loaded sidebar — the tree panel can briefly be
          // allotted a near-zero height. The filter bar + divider have a fixed
          // natural height, so a bare Column would overflow and spam a
          // "RenderFlex overflowed" error. Below a usable height there is
          // nothing worth showing, so render only the background until the next
          // frame restores a real height.
          if (constraints.maxHeight < _minPanelHeight) {
            return const SizedBox.expand();
          }
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _FilterBar(
                onChanged: _onFilterChanged,
                statusFilter: _statusFilter,
                onStatusFilterChanged: (s) => setState(() => _statusFilter = s),
                onOpenSearch: widget.onOpenSearch,
              ),
              const CcDivider(),
              if (flatRows.isEmpty)
                Expanded(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        AppLocalizations.of(context).noMatchingFiles,
                        style: CcTypography.caption.copyWith(
                          color: tokens.textTertiary,
                        ),
                      ),
                    ),
                  ),
                )
              else
                Expanded(
                  child: CcScrollbar(
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
                            onOpenFileInEditor: widget.onOpenFileInEditor,
                          );
                        },
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
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
    this.onOpenSearch,
  });

  final ValueChanged<String> onChanged;
  final String? statusFilter;
  final ValueChanged<String?> onStatusFilterChanged;
  final VoidCallback? onOpenSearch;

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  final _ctrl = TextEditingController();

  /// Whether the status-filter chips are shown. Hidden by default so the bar
  /// stays a single line; revealed by the "Search filters" disclosure under
  /// the field (same affordance as the content-search panel).
  bool _showChips = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    final l10n = AppLocalizations.of(context);
    final palette = DiffPalette.of(context);
    // The disclosure reads "active" when a status filter is applied (so a
    // hidden filter still signals it's on) or the chip row is open.
    final filtersActive = widget.statusFilter != null || _showChips;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            kPrDiffTreeFilterInset,
            6,
            kPrDiffTreeFilterInset,
            5,
          ),
          child: Row(
            children: [
              Expanded(
                child: CcTextField(
                  controller: _ctrl,
                  size: CcTextFieldSize.sm,
                  hintText: l10n.filterFilesHint,
                  onChanged: widget.onChanged,
                  prefix: Icon(
                    AppIcons.listFilter,
                    size: 13,
                    color: tokens.textTertiary,
                  ),
                  suffix: PrFieldClearButton(
                    controller: _ctrl,
                    onCleared: () => widget.onChanged(''),
                  ),
                ),
              ),
              if (widget.onOpenSearch != null) ...[
                const SizedBox(width: 4),
                CcIconButton(
                  size: CcButtonSize.sm,
                  icon: AppIcons.search,
                  tooltip: l10n.searchInFiles,
                  onPressed: widget.onOpenSearch,
                ),
              ],
            ],
          ),
        ),
        PrSidebarFilterToggle(
          label: l10n.ideSearchFilters,
          active: filtersActive,
          onToggle: () => setState(() => _showChips = !_showChips),
        ),
        if (_showChips)
          Padding(
            padding: const EdgeInsets.fromLTRB(
              kPrDiffTreeFilterInset,
              0,
              kPrDiffTreeFilterInset,
              6,
            ),
            child: Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _StatusChip(
                  label: l10n.all,
                  dot: null,
                  selected: widget.statusFilter == null,
                  onTap: () => widget.onStatusFilterChanged(null),
                ),
                _StatusChip(
                  label: l10n.added,
                  dot: palette.additionAccent,
                  selected: widget.statusFilter == 'added',
                  onTap: () => widget.onStatusFilterChanged('added'),
                ),
                _StatusChip(
                  label: l10n.modified,
                  dot: palette.modifiedAccent,
                  selected: widget.statusFilter == 'modified',
                  onTap: () => widget.onStatusFilterChanged('modified'),
                ),
                _StatusChip(
                  label: l10n.removed,
                  dot: palette.deletionAccent,
                  selected: widget.statusFilter == 'removed',
                  onTap: () => widget.onStatusFilterChanged('removed'),
                ),
                _StatusChip(
                  label: l10n.renamed,
                  dot: tokens.textTertiary,
                  selected: widget.statusFilter == 'renamed',
                  onTap: () => widget.onStatusFilterChanged('renamed'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// One status-filter pill — a small status dot (matching the tree rows' dot
/// colors) plus the label, filled when selected.
class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.dot,
    required this.selected,
    required this.onTap,
  });

  final String label;

  /// The status accent dot; null renders a dot-less chip ("All").
  final Color? dot;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    return CcTappable(
      onPressed: onTap,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final Color background;
        if (selected) {
          background = tokens.textPrimary;
        } else if (hovered) {
          background = tokens.bgSecondary;
        } else {
          background = tokens.bgSecondary.withValues(alpha: 0.5);
        }
        return Container(
          height: 22,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(999),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dot != null) ...[
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 5),
              ],
              Text(
                label,
                style: CcTypography.caption.copyWith(
                  color: selected ? tokens.bgPrimary : tokens.textTertiary,
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ],
          ),
        );
      },
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
    this.onOpenFileInEditor,
  });

  final DiffTreeNode node;
  final int depth;
  final bool Function(String path) isOpen;
  final void Function(String path) onToggle;
  final ValueChanged<int> onSelectFile;
  final int? selectedFileIndex;
  final Set<String> viewedPaths;
  final DiffPalette palette;
  final ValueChanged<String>? onOpenFileInEditor;

  static const _indent = 12.0;

  @override
  Widget build(BuildContext context) {
    if (node.isDirectory) {
      final open = isOpen(node.path);
      final tokens =
          context.designSystem ??
          (Theme.of(context).brightness == Brightness.dark
              ? DesignSystemTokens.dark()
              : DesignSystemTokens.light());
      return _Row(
        depth: depth,
        leading: Icon(
          open ? AppIcons.chevronDown : AppIcons.chevronRight,
          size: 12,
          color: tokens.textTertiary,
        ),
        name: node.name,
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
    final path = node.path;
    return _Row(
      depth: depth,
      leading: Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
      ),
      name: node.name,
      secondaryLabel: null,
      onTap: () => onSelectFile(node.fileIndex!),
      onOpenInEditor: onOpenFileInEditor == null
          ? null
          : () => onOpenFileInEditor!(path),
      selected: selectedFileIndex == node.fileIndex,
      viewed: viewedPaths.contains(node.path),
      statusAccent: accent,
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.depth,
    required this.leading,
    required this.name,
    required this.secondaryLabel,
    required this.onTap,
    required this.selected,
    required this.viewed,
    required this.statusAccent,
    this.onOpenInEditor,
  });

  final int depth;
  final Widget leading;
  final String name;
  final String? secondaryLabel;
  final VoidCallback onTap;

  /// Opens this file in an editable tab — shown as a hover affordance at the
  /// row's trailing edge (file rows only). Null for directory rows.
  final VoidCallback? onOpenInEditor;
  final bool selected;
  final bool viewed;
  final Color? statusAccent;

  static const double _rowRadius = 6;
  static const EdgeInsets _rowMargin = EdgeInsets.symmetric(
    horizontal: 4,
    vertical: 1,
  );

  @override
  Widget build(BuildContext context) {
    final tokens =
        context.designSystem ??
        (Theme.of(context).brightness == Brightness.dark
            ? DesignSystemTokens.dark()
            : DesignSystemTokens.light());
    final l10n = AppLocalizations.of(context);

    // Tree guide-line color — subtle, just enough to read the structure
    // without competing with file names. Sits behind the hover/selected fill.
    final guideColor = tokens.borderSecondary;

    return CcTappable(
      onPressed: onTap,
      mouseCursor: SystemMouseCursors.click,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final Color background;
        if (selected) {
          background = tokens.bgSecondary;
        } else if (hovered) {
          background = tokens.bgPrimaryHover;
        } else {
          background = Colors.transparent;
        }
        return Stack(
          children: [
            // Vertical guide lines, one per ancestor depth. Drawn at the
            // top level (outside the row's vertical margin) so consecutive
            // rows render a continuous line through their shared ancestor's
            // children — the line visually starts at the caret of that
            // ancestor and stops when the next equal- or shallower-depth
            // row breaks the chain.
            for (var a = 0; a < depth; a++)
              Positioned(
                // 4 = horizontal row margin; 6 = container left padding;
                // 6 = half of the 12-wide caret box → caret centre.
                left: 4 + 6 + a * _TreeRow._indent + 6 - 0.5,
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
                      6 + depth * _TreeRow._indent,
                      3,
                      6,
                      3,
                    ),
                    child: Row(
                      children: [
                        SizedBox(width: 12, child: Center(child: leading)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            name,
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: CcTypography.caption
                                .copyWith(color: context.ds.textTertiary)
                                .copyWith(
                                  color: viewed
                                      ? tokens.textTertiary
                                      : tokens.textPrimary,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.w500,
                                  decoration: viewed
                                      ? TextDecoration.lineThrough
                                      : null,
                                  decorationColor: tokens.textTertiary,
                                  height: 1.2,
                                ),
                          ),
                        ),
                        // Hover affordance: open this file in an editable tab.
                        // Only on file rows (onOpenInEditor != null); shown on
                        // hover so it doesn't compete with the folder count. A
                        // lightweight control (not CcIconButton) so it doesn't
                        // inflate the compact row height.
                        if (onOpenInEditor != null && hovered) ...[
                          const SizedBox(width: 4),
                          CcTooltip(
                            message: l10n.openInEditor,
                            child: CcTappable(
                              onPressed: onOpenInEditor,
                              mouseCursor: SystemMouseCursors.click,
                              builder: (context, states) => Icon(
                                AppIcons.fileCode,
                                size: 14,
                                color: states.contains(WidgetState.hovered)
                                    ? tokens.textPrimary
                                    : tokens.textTertiary,
                              ),
                            ),
                          ),
                        ] else if (secondaryLabel != null) ...[
                          const SizedBox(width: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 1,
                            ),
                            decoration: BoxDecoration(
                              color: tokens.bgSecondary.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              secondaryLabel!,
                              style: CcTypography.caption
                                  .copyWith(color: context.ds.textTertiary)
                                  .copyWith(
                                    color: tokens.textTertiary,
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
                  if (selected && statusAccent != null)
                    Positioned(
                      left: 0,
                      top: 3,
                      bottom: 3,
                      child: Container(
                        width: 2,
                        decoration: BoxDecoration(
                          color: statusAccent,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
