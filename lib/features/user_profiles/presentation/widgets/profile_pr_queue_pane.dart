import 'dart:math' as math;

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_table/pr_repo_rail.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_table/pr_repo_section_card.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_table/pr_repo_view.dart';
import 'package:control_center/features/pr_review/providers/pr_table_providers.dart';
import 'package:control_center/shared/widgets/pinned_header_bleed_guard.dart';
import 'package:flutter/widgets.dart';

/// One profile-page [CustomScrollView]: identity/metrics scroll away, the
/// state filter and table header pin, the repo rail sticks beside the table,
/// and the scrollbar rides the pane edge — not a nested table viewport.
class ProfilePrQueuePane extends StatefulWidget {
  /// Creates the profile PR queue scroll surface.
  const ProfilePrQueuePane({
    super.key,
    required this.pageStorageKey,
    required this.filter,
    required this.sections,
    this.leading,
    this.fill,
  });

  /// Restores this profile's scroll offset.
  final String pageStorageKey;

  /// Identity + metrics, already padded. Null in queue-only tests.
  final Widget? leading;

  /// All / Open / Merged / Closed control. Null while loading or failed.
  final Widget? filter;

  /// Repos to show in the rail and table. Empty with [fill] set is the
  /// empty/search-miss state.
  final List<PrRepoSectionData> sections;

  /// Fills the remaining viewport (spinner, error, empty). Null when the
  /// table is shown.
  final Widget? fill;

  @override
  State<ProfilePrQueuePane> createState() => _ProfilePrQueuePaneState();
}

class _ProfilePrQueuePaneState extends State<ProfilePrQueuePane> {
  final ScrollController _controller = ScrollController();
  final GlobalKey _leadingKey = GlobalKey();
  final GlobalKey _filterKey = GlobalKey();

  /// The repo whose card is shown. Null until the user picks one — the build
  /// falls back to the first section so the first repo is preselected.
  String? _selectedRepoId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sections = widget.sections;
    final ids = {for (final s in sections) s.repo.id};
    final selectedId =
        (_selectedRepoId != null && ids.contains(_selectedRepoId))
        ? _selectedRepoId!
        : (sections.isEmpty ? null : sections.first.repo.id);
    final selected = selectedId == null
        ? null
        : sections.firstWhere((s) => s.repo.id == selectedId);

    final showRail = selected != null && widget.fill == null;

    return Stack(
      fit: StackFit.expand,
      children: [
        CcScrollArea(
          fadeStart: false,
          child: CustomScrollView(
            key: PageStorageKey(widget.pageStorageKey),
            controller: _controller,
            slivers: [
              if (widget.leading != null)
                SliverToBoxAdapter(
                  child: KeyedSubtree(key: _leadingKey, child: widget.leading!),
                ),
              if (widget.fill != null) ...[
                if (widget.filter != null) _filterSliver(),
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Padding(
                    padding: const EdgeInsetsDirectional.symmetric(
                      horizontal: AppSpacing.xl,
                    ),
                    child: widget.fill,
                  ),
                ),
              ] else if (selected != null)
                SliverMainAxisGroup(
                  slivers: [
                    if (widget.filter != null) _filterSliver(),
                    SliverPadding(
                      padding: const EdgeInsetsDirectional.fromSTEB(
                        AppSpacing.xl + kPrRepoRailWidth + AppSpacing.xl,
                        0,
                        AppSpacing.xl,
                        AppSpacing.xxl,
                      ),
                      sliver: PrRepoSectionCard(items: selected.items),
                    ),
                  ],
                ),
            ],
          ),
        ),
        if (showRail)
          _StickyRepoRail(
            controller: _controller,
            leadingKey: widget.leading != null ? _leadingKey : null,
            filterKey: _filterKey,
            child: PrRepoRail(
              entries: [
                for (final section in sections)
                  (repo: section.repo, count: section.items.length),
              ],
              selectedRepoId: selectedId,
              onSelect: (id) => setState(() => _selectedRepoId = id),
            ),
          ),
      ],
    );
  }

  Widget _filterSliver() {
    return PinnedHeaderSliver(
      child: PinnedHeaderBleedGuard(
        child: KeyedSubtree(key: _filterKey, child: widget.filter!),
      ),
    );
  }
}

/// Overlay rail that tracks the page scroll until the filter pins, then
/// stays under it. Kept out of the sliver tree: a pinned sliver inside
/// [SliverCrossAxisGroup] cannot keep paintOrigin, so the rail would
/// scroll away with the rows.
class _StickyRepoRail extends StatefulWidget {
  const _StickyRepoRail({
    required this.controller,
    required this.filterKey,
    required this.child,
    this.leadingKey,
  });

  final ScrollController controller;
  final GlobalKey? leadingKey;
  final GlobalKey filterKey;
  final Widget child;

  @override
  State<_StickyRepoRail> createState() => _StickyRepoRailState();
}

class _StickyRepoRailState extends State<_StickyRepoRail> {
  double _top = 0;
  bool _ready = false;
  bool _syncScheduled = false;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scheduleSync);
    _scheduleSync();
  }

  @override
  void didUpdateWidget(_StickyRepoRail oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller.removeListener(_scheduleSync);
      widget.controller.addListener(_scheduleSync);
    }
    _scheduleSync();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scheduleSync);
    super.dispose();
  }

  void _scheduleSync() {
    if (_syncScheduled) {
      return;
    }
    _syncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _syncScheduled = false;
      if (mounted) {
        _sync();
      }
    });
  }

  double _extentOf(GlobalKey? key) {
    if (key == null) {
      return 0;
    }
    final box = key.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || !box.hasSize) {
      return 0;
    }
    return box.size.height;
  }

  void _sync() {
    final leadingH = _extentOf(widget.leadingKey);
    final filterH = _extentOf(widget.filterKey);
    if (filterH == 0) {
      return;
    }
    final offset = widget.controller.hasClients
        ? widget.controller.offset
        : 0.0;
    final top = math.max(filterH, leadingH + filterH - offset);
    if (!_ready || top != _top) {
      setState(() {
        _ready = true;
        _top = top;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const SizedBox.shrink();
    }
    return PositionedDirectional(
      start: AppSpacing.xl,
      top: _top,
      bottom: 0,
      width: kPrRepoRailWidth,
      child: SingleChildScrollView(primary: false, child: widget.child),
    );
  }
}
