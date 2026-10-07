import 'dart:async';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_file_tree.dart';
import 'package:control_center/features/pr_review/presentation/utils/diff_palette.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_sidebar_filter_controls.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/ready_auto_scroll.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';

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

  /// Row index by path in [_flatCache], for the keyboard model.
  Map<String, int> _flatIndexByPath = const {};

  // --- Keyboard model ----------------------------------------------------
  // A tree, not a list of Tab stops: ↑/↓ walk the visible rows, → opens a
  // folder or enters it, ← closes it or climbs to the parent, Home/End jump
  // to the ends. Only one row (the last one focused) is a Tab stop, so Tab
  // leaves the tree in one press instead of visiting thousands of rows.

  /// Focus node per row, keyed by path (a folder and a file never share one).
  final Map<String, FocusNode> _rowFocus = {};
  final Map<FocusNode, String> _rowFocusPath = {};

  /// The row Tab lands on. Null until a row is focused; then the selected
  /// file's row, else the first row, stands in.
  String? _tabStopPath;

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
    for (final node in _rowFocus.values) {
      node.dispose();
    }
    super.dispose();
  }

  FocusNode _rowNode(String path) => _rowFocus.putIfAbsent(path, () {
    final node = FocusNode(debugLabel: 'file tree row $path');
    _rowFocusPath[node] = path;
    node.addListener(() {
      if (node.hasPrimaryFocus && _tabStopPath != path && mounted) {
        setState(() => _tabStopPath = path);
      }
    });
    return node;
  });

  /// Path of the row that is the tree's single Tab stop.
  String? _effectiveTabStop(List<_FlatRowSpec> rows) {
    if (rows.isEmpty) {
      return null;
    }
    final stop = _tabStopPath;
    if (stop != null && _flatIndexByPath.containsKey(stop)) {
      return stop;
    }
    final selected = widget.selectedFileIndex;
    if (selected != null) {
      for (final row in rows) {
        if (row.node.fileIndex == selected) {
          return row.node.path;
        }
      }
    }
    return rows.first.node.path;
  }

  /// Disposes focus nodes of rows that are no longer listed and not mounted.
  void _pruneRowFocus() {
    final dead = [
      for (final MapEntry(:key, :value) in _rowFocus.entries)
        if (!_flatIndexByPath.containsKey(key) && value.context == null) key,
    ];
    for (final path in dead) {
      final node = _rowFocus.remove(path)!;
      _rowFocusPath.remove(node);
      node.dispose();
    }
  }

  KeyEventResult _onTreeKey(FocusNode _, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
      return KeyEventResult.ignored;
    }
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isMetaPressed ||
        keyboard.isControlPressed ||
        keyboard.isAltPressed ||
        keyboard.isShiftPressed) {
      return KeyEventResult.ignored;
    }
    final primary = FocusManager.instance.primaryFocus;
    final path = primary == null ? null : _rowFocusPath[primary];
    final rows = _flatCache;
    final index = path == null ? null : _flatIndexByPath[path];
    if (rows == null || index == null || index >= rows.length) {
      return KeyEventResult.ignored;
    }
    final row = rows[index];
    final rtl = Directionality.of(context) == TextDirection.rtl;
    final key = event.logicalKey;
    // ← / → follow the reading direction: "into" is → in LTR, ← in RTL.
    final into =
        key ==
        (rtl ? LogicalKeyboardKey.arrowLeft : LogicalKeyboardKey.arrowRight);
    final outOf =
        key ==
        (rtl ? LogicalKeyboardKey.arrowRight : LogicalKeyboardKey.arrowLeft);
    if (key == LogicalKeyboardKey.arrowDown) {
      _focusRow(index + 1);
    } else if (key == LogicalKeyboardKey.arrowUp) {
      _focusRow(index - 1, forward: false);
    } else if (key == LogicalKeyboardKey.home) {
      _focusRow(0, forward: false);
    } else if (key == LogicalKeyboardKey.end) {
      _focusRow(rows.length - 1);
    } else if (into) {
      if (row.node.isDirectory) {
        if (!_isOpen(row.node.path)) {
          _toggle(row.node.path);
        } else if (row.node.children.isNotEmpty) {
          _focusRow(index + 1);
        }
      }
    } else if (outOf) {
      if (row.node.isDirectory && _isOpen(row.node.path)) {
        _toggle(row.node.path);
      } else {
        for (var i = index - 1; i >= 0; i--) {
          if (rows[i].depth < row.depth) {
            _focusRow(i, forward: false);
            break;
          }
        }
      }
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  /// Focuses visible row [index], scrolling it in (and building it) first
  /// when it is outside the list's built range.
  void _focusRow(int index, {bool forward = true}) {
    final rows = _flatCache;
    if (rows == null || index < 0 || index >= rows.length) {
      return;
    }
    final path = rows[index].node.path;
    final node = _rowFocus[path];
    final context = node?.context;
    if (node != null && context != null) {
      node.requestFocus();
      unawaited(
        Scrollable.ensureVisible(
          context,
          alignmentPolicy: forward
              ? ScrollPositionAlignmentPolicy.keepVisibleAtEnd
              : ScrollPositionAlignmentPolicy.keepVisibleAtStart,
        ),
      );
      return;
    }
    if (!_scrollController.hasClients) {
      return;
    }
    // Fixed-extent rows (see the prototype item): the content height divided
    // by the row count is the exact row extent.
    final position = _scrollController.position;
    final extent =
        (position.maxScrollExtent + position.viewportDimension) / rows.length;
    position.jumpTo(
      (index * extent - (position.viewportDimension - extent) / 2).clamp(
        position.minScrollExtent,
        position.maxScrollExtent,
      ),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _rowFocus[path]?.requestFocus();
      }
    });
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
    final tabStop = _effectiveTabStop(flatRows);

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
                      // Arrow keys from a row bubble here (see _onTreeKey).
                      child: Focus(
                        canRequestFocus: false,
                        skipTraversal: true,
                        includeSemantics: false,
                        onKeyEvent: _onTreeKey,
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
                          // The prototype is laid out but never shown: keep it out of
                          // Tab order and the semantics tree.
                          prototypeItem: ExcludeFocus(
                            child: ExcludeSemantics(
                              child: _TreeRow(
                                node: flatRows.first.node,
                                depth: 0,
                                isOpen: _isOpen,
                                onToggle: _toggle,
                                onSelectFile: widget.onSelectFile,
                                selectedFileIndex: null,
                                viewedPaths: const <String>{},
                                palette: palette,
                              ),
                            ),
                          ),
                          itemBuilder: (context, i) {
                            final spec = flatRows[i];
                            final focusNode = _rowNode(spec.node.path)
                              ..skipTraversal = spec.node.path != tabStop;
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
                              focusNode: focusNode,
                            );
                          },
                        ),
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
    _flatIndexByPath = {
      for (var i = 0; i < out.length; i++) out[i].node.path: i,
    };
    _pruneRowFocus();
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
        return Semantics(
          selected: selected,
          child: Container(
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
                    decoration: BoxDecoration(
                      color: dot,
                      shape: BoxShape.circle,
                    ),
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
    this.focusNode,
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
  final FocusNode? focusNode;

  static const _indent = 12.0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
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
        focusNode: focusNode,
        semanticLabel: l10n.diffTreeFolderSemantics(node.name, node.fileCount),
        expanded: open,
      );
    }

    final accent = switch (node.status) {
      'added' => palette.additionAccent,
      'removed' => palette.deletionAccent,
      _ => palette.modifiedAccent,
    };
    final path = node.path;
    final viewed = viewedPaths.contains(node.path);
    final status = switch (node.status) {
      'added' => l10n.added,
      'removed' => l10n.removed,
      'renamed' => l10n.renamed,
      _ => l10n.modified,
    };
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
      viewed: viewed,
      statusAccent: accent,
      focusNode: focusNode,
      semanticLabel: viewed
          ? l10n.diffTreeFileSemanticsViewed(node.name, status)
          : l10n.diffTreeFileSemantics(node.name, status),
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
    required this.semanticLabel,
    this.onOpenInEditor,
    this.focusNode,
    this.expanded,
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

  /// What a screen reader announces for the row (name, kind, status).
  final String semanticLabel;

  /// Keyboard focus, owned by the tree's row model.
  final FocusNode? focusNode;

  /// A folder's open state; null for a file.
  final bool? expanded;

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
      focusNode: focusNode,
      mouseCursor: SystemMouseCursors.click,
      borderRadius: BorderRadius.circular(_rowRadius),
      semanticLabel: semanticLabel,
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
        // The label above names the row; the painted text, count pill and
        // hover-only editor button are excluded so they aren't read again.
        // The editor button is offered as a custom action instead, which a
        // screen reader can reach without hovering.
        return Semantics(
          expanded: expanded,
          selected: expanded == null ? selected : null,
          customSemanticsActions: onOpenInEditor == null
              ? null
              : {
                  CustomSemanticsAction(label: l10n.openInEditor):
                      onOpenInEditor!,
                },
          child: ExcludeSemantics(
            child: Stack(
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
                                      // Keep caption's 16/12 line box: at 1.2 the
                                      // box is shorter than Manrope's descenders,
                                      // and an ellipsized paragraph clips to its
                                      // box, cutting g/p/y on long names. Still no
                                      // taller than the folder rows' count pill,
                                      // so the list's row extent is unchanged.
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
                                  // Hover-only: never a Tab stop (it would vanish
                                  // as soon as the row lost hover).
                                  canRequestFocus: false,
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
                                  color: tokens.bgSecondary.withValues(
                                    alpha: 0.6,
                                  ),
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
            ),
          ),
        );
      },
    );
  }
}
