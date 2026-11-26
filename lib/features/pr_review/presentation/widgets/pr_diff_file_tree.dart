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
import 'package:intl/intl.dart' show NumberFormat;
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
    this.unresolvedByPath = const <String, int>{},
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

  /// Open review conversations per file path. A file with any shows the count
  /// on its row, so a thread in a collapsed or off-screen file is findable
  /// from the tree.
  final Map<String, int> unresolvedByPath;

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
                roots: widget.roots,
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
                              unresolved:
                                  widget.unresolvedByPath[spec.node.path] ?? 0,
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
    required this.roots,
    required this.onChanged,
    required this.statusFilter,
    required this.onStatusFilterChanged,
    this.onOpenSearch,
  });

  /// The unfiltered tree, counted per status for the menu rows.
  final List<DiffTreeNode> roots;
  final ValueChanged<String> onChanged;
  final String? statusFilter;
  final ValueChanged<String?> onStatusFilterChanged;
  final VoidCallback? onOpenSearch;

  @override
  State<_FilterBar> createState() => _FilterBarState();
}

class _FilterBarState extends State<_FilterBar> {
  final _ctrl = TextEditingController();

  /// Drives the status menu from the in-field trigger (itself a button, so
  /// the menu must not wrap it in a second tappable).
  final _statusMenu = CcOverlayController();

  /// File count per status, recounted only when the tree itself changes.
  Map<String, int>? _statusCounts;
  List<DiffTreeNode>? _statusCountsRoots;

  @override
  void dispose() {
    _statusMenu.dispose();
    _ctrl.dispose();
    super.dispose();
  }

  Map<String, int> _countsFor(List<DiffTreeNode> roots) {
    final cached = _statusCounts;
    if (cached != null && identical(_statusCountsRoots, roots)) {
      return cached;
    }
    final counts = <String, int>{};
    void walk(List<DiffTreeNode> nodes) {
      for (final node in nodes) {
        if (node.isDirectory) {
          walk(node.children);
        } else {
          counts[node.status] = (counts[node.status] ?? 0) + 1;
        }
      }
    }

    walk(roots);
    _statusCountsRoots = roots;
    return _statusCounts = counts;
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
    final counts = _countsFor(widget.roots);
    final number = NumberFormat.decimalPattern(l10n.localeName);
    final selected = widget.statusFilter;

    CcMenuItem statusItem(String status, String label, Color dot) {
      final count = counts[status] ?? 0;
      // A status with no files filters to nothing; it stays reachable only
      // while it is the applied one, so it can still be seen and cleared.
      final enabled = count > 0 || selected == status;
      return CcMenuItem(
        label: label,
        selected: selected == status,
        enabled: enabled,
        trailing: number.format(count),
        leading: (_) =>
            _StatusDot(color: enabled ? dot : dot.withValues(alpha: 0.38)),
        onSelected: () => widget.onStatusFilterChanged(status),
      );
    }

    return Padding(
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
              suffix: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrFieldClearButton(
                    controller: _ctrl,
                    onCleared: () => widget.onChanged(''),
                  ),
                  CcMenu(
                    controller: _statusMenu,
                    toggleOnTargetTap: false,
                    targetAnchor: AlignmentDirectional.bottomEnd,
                    followerAnchor: AlignmentDirectional.topEnd,
                    minWidth: 200,
                    semanticLabel: l10n.prFilterCategoryStatus,
                    items: [
                      CcMenuItem(
                        label: l10n.all,
                        selected: selected == null,
                        trailing: number.format(
                          counts.values.fold<int>(0, (a, b) => a + b),
                        ),
                        // Empty slot so "All" lines up with the dotted rows.
                        leading: (_) => const SizedBox(width: 16),
                        onSelected: () => widget.onStatusFilterChanged(null),
                      ),
                      const CcMenuItem.divider(),
                      statusItem('added', l10n.added, palette.additionAccent),
                      statusItem(
                        'modified',
                        l10n.modified,
                        palette.modifiedAccent,
                      ),
                      statusItem(
                        'removed',
                        l10n.removed,
                        palette.deletionAccent,
                      ),
                      statusItem('renamed', l10n.renamed, tokens.textTertiary),
                    ],
                    target: ListenableBuilder(
                      listenable: _statusMenu,
                      builder: (context, _) => PrSuffixIconButton(
                        icon: AppIcons.slidersHorizontal,
                        tooltip: l10n.prFilterCategoryStatus,
                        // Lit while a status is applied, so a filter hidden
                        // behind the closed menu still shows it is on.
                        active: selected != null || _statusMenu.isOpen,
                        onPressed: _statusMenu.toggle,
                      ),
                    ),
                  ),
                ],
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
    );
  }
}

/// The status dot leading a status-menu row: the same accent as the tree
/// rows' dots, centred in the 16px icon slot.
class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 16,
      height: 16,
      child: Center(
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
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
    this.unresolved = 0,
    this.onOpenFileInEditor,
    this.focusNode,
  });

  final DiffTreeNode node;

  /// Open review conversations on this file (always 0 for a folder).
  final int unresolved;
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
    final rowLabel = viewed
        ? l10n.diffTreeFileSemanticsViewed(node.name, status)
        : l10n.diffTreeFileSemantics(node.name, status);
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
      additionColor: palette.additionAccent,
      deletionColor: palette.deletionAccent,
      unresolved: unresolved,
      onTap: () => onSelectFile(node.fileIndex!),
      onOpenInEditor: onOpenFileInEditor == null
          ? null
          : () => onOpenFileInEditor!(path),
      selected: selectedFileIndex == node.fileIndex,
      viewed: viewed,
      statusAccent: accent,
      focusNode: focusNode,
      semanticLabel: unresolved > 0
          ? '$rowLabel, ${l10n.diffFileUnresolvedConversations(unresolved)}'
          : rowLabel,
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.depth,
    required this.leading,
    required this.name,
    required this.onTap,
    required this.selected,
    required this.viewed,
    required this.statusAccent,
    required this.semanticLabel,
    this.additions = 0,
    this.deletions = 0,
    this.additionColor,
    this.deletionColor,
    this.unresolved = 0,
    this.onOpenInEditor,
    this.focusNode,
    this.expanded,
  });

  final int depth;
  final Widget leading;
  final String name;

  /// Lines added and removed in this file; both 0 on a folder row, which
  /// shows no stat.
  final int additions;
  final int deletions;
  final Color? additionColor;
  final Color? deletionColor;

  /// Open review conversations on this file; 0 shows no badge.
  final int unresolved;
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

  /// Height of a row's content, set by the tallest thing a row can carry (the
  /// unresolved badge). Every row takes it, so the list's prototype row is
  /// right whichever row it happens to be.
  static const double _contentHeight = 18;

  /// Narrowest row content that still shows the line stat. Below it the name
  /// would be squeezed to an ellipsis, and the name is what the tree is for.
  static const double _statMinWidth = 170;

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
        // The label above names the row; the painted text, line stat, badge and
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
                        child: LayoutBuilder(
                          builder: (context, constraints) => SizedBox(
                            height: _contentHeight,
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 12,
                                  child: Center(child: leading),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    name,
                                    overflow: TextOverflow.ellipsis,
                                    maxLines: 1,
                                    // Caption's 16/12 line box: a shorter one
                                    // clips Manrope's descenders (g/p/y) on an
                                    // ellipsized name.
                                    style: CcTypography.caption.copyWith(
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
                                    ),
                                  ),
                                ),
                                // Hover affordance: open this file in an
                                // editable tab (file rows only). Ahead of the
                                // stat and badge so they keep their place when
                                // it appears. A square button the height of
                                // the row content (a 32px CcIconButton would
                                // inflate the compact row), with its own
                                // hover wash.
                                if (onOpenInEditor != null && hovered) ...[
                                  const SizedBox(width: 4),
                                  CcTooltip(
                                    message: l10n.openInEditor,
                                    child: CcTappable(
                                      onPressed: onOpenInEditor,
                                      // Hover-only: never a Tab stop (it would
                                      // vanish as soon as the row lost hover).
                                      canRequestFocus: false,
                                      mouseCursor: SystemMouseCursors.click,
                                      borderRadius: AppRadii.brSm,
                                      builder: (context, states) {
                                        final over = states.contains(
                                          WidgetState.hovered,
                                        );
                                        return Container(
                                          width: _contentHeight,
                                          height: _contentHeight,
                                          alignment: Alignment.center,
                                          decoration: BoxDecoration(
                                            color: over
                                                ? tokens.hoverStrong
                                                : Colors.transparent,
                                            borderRadius: AppRadii.brSm,
                                          ),
                                          child: Icon(
                                            AppIcons.fileCode,
                                            size: 14,
                                            color: over
                                                ? tokens.textPrimary
                                                : tokens.textSecondary,
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ],
                                if ((additions > 0 || deletions > 0) &&
                                    constraints.maxWidth >= _statMinWidth) ...[
                                  const SizedBox(width: 6),
                                  _LineStat(
                                    additions: additions,
                                    deletions: deletions,
                                    additionColor:
                                        additionColor ?? tokens.textTertiary,
                                    deletionColor:
                                        deletionColor ?? tokens.textTertiary,
                                  ),
                                ],
                                if (unresolved > 0) ...[
                                  const SizedBox(width: 6),
                                  _UnresolvedPill(count: unresolved),
                                ],
                              ],
                            ),
                          ),
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

/// A file row's "+12 −3": lines added and removed, a side left out when zero.
class _LineStat extends StatelessWidget {
  const _LineStat({
    required this.additions,
    required this.deletions,
    required this.additionColor,
    required this.deletionColor,
  });

  final int additions;
  final int deletions;
  final Color additionColor;
  final Color deletionColor;

  @override
  Widget build(BuildContext context) {
    final number = NumberFormat.decimalPattern(
      AppLocalizations.of(context).localeName,
    );
    return Text.rich(
      TextSpan(
        children: [
          if (additions > 0)
            TextSpan(
              text: '+${number.format(additions)}',
              style: TextStyle(color: additionColor),
            ),
          if (additions > 0 && deletions > 0) const TextSpan(text: ' '),
          if (deletions > 0)
            TextSpan(
              text: '−${number.format(deletions)}',
              style: TextStyle(color: deletionColor),
            ),
        ],
      ),
      maxLines: 1,
      // RTL carve-out: a diff stat reads added-then-removed in every locale.
      textDirection: TextDirection.ltr,
      style: CcTypography.caption.copyWith(
        fontWeight: FontWeight.w600,
        fontFeatures: const [FontFeature.tabularFigures()],
      ),
    );
  }
}

/// A file row's count of open review conversations: the diff file header's
/// badge at tree-row size, in the same brand tint so the two read as one fact.
class _UnresolvedPill extends StatelessWidget {
  const _UnresolvedPill({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final l10n = AppLocalizations.of(context);
    return CcTooltip(
      message: l10n.diffFileUnresolvedConversations(count),
      child: Container(
        height: _Row._contentHeight,
        padding: const EdgeInsets.symmetric(horizontal: 5),
        decoration: BoxDecoration(
          color: t.bgBrandPrimary,
          borderRadius: AppRadii.brSm,
          border: Border.all(color: t.borderBrand.withValues(alpha: 0.30)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(AppIcons.messageSquare, size: 10, color: t.textBrandPrimary),
            const SizedBox(width: 3),
            Text(
              NumberFormat.decimalPattern(l10n.localeName).format(count),
              style: CcTypography.caption.copyWith(
                color: t.textBrandPrimary,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
