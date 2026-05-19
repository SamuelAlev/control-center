import 'dart:async';
import 'dart:math' as math;

import 'package:cc_domain/features/pr_review/domain/entities/pr_user.dart';
import 'package:cc_domain/features/pr_review/domain/entities/pull_request.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_filter/pr_filter_facets.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_shared.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/features/pr_review/providers/pr_list_display_prefs_provider.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:control_center/shared/widgets/github_user_avatar.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The shared filter menu trigger used by both the PR queue and the inbox
/// toolbars: a filter icon (with an active-criteria count) opening the
/// Linear-style anchored menu bound to [scope] — a search field over the
/// filter categories, each category flying out a submenu of checkbox options
/// with live match counts computed against the scope's loaded population.
class PrFilterButton extends ConsumerStatefulWidget {
  /// Creates a [PrFilterButton]. Pass [controller] to open the menu from
  /// outside (the `F` keybinding).
  const PrFilterButton({super.key, required this.scope, this.controller});

  /// The surface's filter state + population binding.
  final PrFilterScope scope;

  /// External open/close controller; an internal one is created when null.
  final CcOverlayController? controller;

  @override
  ConsumerState<PrFilterButton> createState() => _PrFilterButtonState();
}

class _PrFilterButtonState extends ConsumerState<PrFilterButton> {
  CcOverlayController? _internal;

  CcOverlayController get _controller =>
      widget.controller ?? (_internal ??= CcOverlayController());

  @override
  void dispose() {
    _internal?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final count = ref.watch(widget.scope.filters.select((f) => f.count));
    final active = count > 0;

    // Inert chrome (the CcTappable below owns the tap): the icon plus, when
    // filters are active, the criteria count so the state is never icon-only.
    final chrome = Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            AppIcons.listFilter,
            size: 16,
            color: active ? tokens.accent : tokens.textSecondary,
          ),
          if (active) ...[
            const SizedBox(width: 6),
            Text(
              '$count',
              style: CcTypography.caption.copyWith(
                color: tokens.accent,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );

    return PrFilterMenuAnchor(
      controller: _controller,
      scope: widget.scope,
      target: CcTooltip(
        message: l10n.prFilterTooltip,
        child: CcTappable(
          onPressed: _controller.toggle,
          semanticLabel: active
              ? '${l10n.prFilterTooltip}. ${l10n.prFilterActiveCount(count)}'
              : l10n.prFilterTooltip,
          borderRadius: AppRadii.brSm,
          focusRingColor: tokens.focusRing,
          builder: (context, states) => SizedBox(
            height: 40,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: states.contains(WidgetState.hovered)
                    ? tokens.hover
                    : const Color(0x00000000),
                borderRadius: AppRadii.brSm,
              ),
              child: Center(child: chrome),
            ),
          ),
        ),
      ),
    );
  }
}

/// The anchored two-panel filter menu with a pluggable inert [target] — the
/// root category menu plus, when a category is open, its option flyout. Used
/// by [PrFilterButton] (toolbar) and the filter bar's "+" trigger.
///
/// The flyout is part of the same overlay (a second floating panel in the
/// anchored row), so hover-open, pointer travel between panels and Escape
/// dismissal need no cross-overlay coordination. When the trigger sits at a
/// toolbar's right edge ([alignRight], the default) the panel hangs on the
/// trigger's right edge and the flyout opens to the LEFT of the root panel;
/// a left-aligned trigger (the filter bar's "+") flips both.
class PrFilterMenuAnchor extends StatelessWidget {
  /// Creates a [PrFilterMenuAnchor].
  const PrFilterMenuAnchor({
    super.key,
    required this.controller,
    required this.scope,
    required this.target,
    this.alignRight = true,
  });

  /// Open/close controller (the [target] should toggle it).
  final CcOverlayController controller;

  /// The surface's filter state + population binding.
  final PrFilterScope scope;

  /// The trigger widget (owns its own tappable; the anchor adds none).
  final Widget target;

  /// Whether the panel hangs on the trigger's right edge (toolbar buttons)
  /// or its left edge (the filter bar's "+").
  final bool alignRight;

  @override
  Widget build(BuildContext context) {
    return CcOverlayAnchor(
      controller: controller,
      targetAnchor: alignRight ? Alignment.bottomRight : Alignment.bottomLeft,
      followerAnchor: alignRight ? Alignment.topRight : Alignment.topLeft,
      offset: const Offset(0, 6),
      interceptPointer: true,
      target: target,
      overlayBuilder: (context, _) => _FilterMenuOverlay(
        controller: controller,
        scope: scope,
        flyoutOpensLeft: alignRight,
      ),
    );
  }
}

/// The two-panel overlay body: the root menu (pinned under the trigger) and,
/// when a category is open, its flyout beside it, top-aligned with the
/// hovered row.
class _FilterMenuOverlay extends ConsumerStatefulWidget {
  const _FilterMenuOverlay({
    required this.controller,
    required this.scope,
    required this.flyoutOpensLeft,
  });

  final CcOverlayController controller;
  final PrFilterScope scope;
  final bool flyoutOpensLeft;

  @override
  ConsumerState<_FilterMenuOverlay> createState() => _FilterMenuOverlayState();
}

class _FilterMenuOverlayState extends ConsumerState<_FilterMenuOverlay> {
  static const double _rootWidth = 264;

  final GlobalKey _rootPanelKey = GlobalKey();
  final FocusScopeNode _scope = FocusScopeNode(
    traversalEdgeBehavior: TraversalEdgeBehavior.closedLoop,
  );
  final TextEditingController _search = TextEditingController();

  PrFilterCategory? _openCategory;
  double _flyoutTop = 0;
  Timer? _hoverTimer;

  @override
  void dispose() {
    _hoverTimer?.cancel();
    _scope.dispose();
    _search.dispose();
    super.dispose();
  }

  // Opens [category]'s flyout aligned with the row that triggered it.
  void _openFlyout(PrFilterCategory category, BuildContext rowContext) {
    _hoverTimer?.cancel();
    final rowBox = rowContext.findRenderObject() as RenderBox?;
    final panelBox =
        _rootPanelKey.currentContext?.findRenderObject() as RenderBox?;
    double top = 0;
    if (rowBox != null && panelBox != null && rowBox.attached) {
      top = rowBox.localToGlobal(Offset.zero, ancestor: panelBox).dy;
    }
    setState(() {
      _openCategory = category;
      _flyoutTop = math.max(0, top);
    });
  }

  void _scheduleFlyout(PrFilterCategory category, BuildContext rowContext) {
    if (_openCategory == category) {
      return;
    }
    _hoverTimer?.cancel();
    // A short dwell so sweeping the pointer down the menu doesn't thrash
    // flyouts, but intent (resting on a row) opens without a click.
    _hoverTimer = Timer(const Duration(milliseconds: 180), () {
      if (mounted && rowContext.mounted) {
        _openFlyout(category, rowContext);
      }
    });
  }

  void _cancelScheduled() => _hoverTimer?.cancel();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filters = ref.watch(widget.scope.filters);
    final includeDrafts = ref.watch(
      prListDisplayPrefsProvider.select((p) => p.showDrafts),
    );
    final login = ref.watch(currentUserLoginProvider);
    ref.watch(viewerGitHubTeamsProvider);
    final allPrs = ref.watch(widget.scope.population);
    final query = _search.text.trim();

    final root = PrFilterPanel(
      key: _rootPanelKey,
      width: _rootWidth,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: CcTextField(
              controller: _search,
              size: CcTextFieldSize.sm,
              hintText: l10n.prFilterAddFilter,
              autofocus: true,
              prefix: const Icon(AppIcons.search, size: 14),
              suffix: const CcKbd(keyLabel: 'F'),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const CcDivider(),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
              child: query.isEmpty
                  ? _categoryList(l10n, filters, allPrs, login, includeDrafts)
                  : _searchResults(
                      l10n,
                      filters,
                      allPrs,
                      login,
                      includeDrafts,
                      query,
                    ),
            ),
          ),
        ],
      ),
    );

    final openCategory = _openCategory;
    final flyout = openCategory == null
        ? null
        : Padding(
            padding: EdgeInsets.only(top: _flyoutTop),
            child: PrFilterFlyout(
              key: ValueKey(openCategory),
              category: openCategory,
              scope: widget.scope,
            ),
          );
    // Arrow keys walk the menu rows (the closedLoop scope wraps around);
    // Escape dismissal is CcOverlayAnchor's.
    return FocusScope(
      node: _scope,
      child: Shortcuts(
        shortcuts: const {
          SingleActivator(LogicalKeyboardKey.arrowDown): NextFocusIntent(),
          SingleActivator(LogicalKeyboardKey.arrowUp): PreviousFocusIntent(),
        },
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.flyoutOpensLeft && flyout != null) ...[
              flyout,
              const SizedBox(width: AppSpacing.xs),
            ],
            root,
            if (!widget.flyoutOpensLeft && flyout != null) ...[
              const SizedBox(width: AppSpacing.xs),
              flyout,
            ],
          ],
        ),
      ),
    );
  }

  Widget _categoryList(
    AppLocalizations l10n,
    PrListFilters filters,
    List<PullRequest> allPrs,
    String login,
    bool includeDrafts,
  ) {
    Widget category(PrFilterCategory c) => _CategoryRow(
      icon: prFilterCategoryIcon(c),
      label: prFilterCategoryLabel(l10n, c),
      activeCount: prFilterCategoryActiveCount(filters, c),
      open: _openCategory == c,
      onHover: (rowContext) => _scheduleFlyout(c, rowContext),
      onHoverEnd: _cancelScheduled,
      onOpen: (rowContext) => _openFlyout(c, rowContext),
    );

    final viewerTeams =
        ref.read(viewerGitHubTeamsProvider).value ??
        const <String, Set<String>>{};
    final quickCount = quickToReviewCount(
      allPrs,
      filters: filters,
      currentLogin: login,
      includeDrafts: includeDrafts,
      viewerTeamsByOrg: viewerTeams,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        category(PrFilterCategory.status),
        category(PrFilterCategory.author),
        category(PrFilterCategory.reviewer),
        category(PrFilterCategory.content),
        const CcDivider(),
        category(PrFilterCategory.repoOwner),
        category(PrFilterCategory.repoName),
        const CcDivider(),
        category(PrFilterCategory.openedDate),
        category(PrFilterCategory.updatedDate),
        const CcDivider(),
        _LeafToggleRow(
          icon: AppIcons.zap,
          label: l10n.prFilterQuickToReview,
          count: quickCount,
          selected: filters.quickToReview,
          onToggle: () {
            ref.read(widget.scope.filters.notifier).toggleQuickToReview();
          },
        ),
        if (filters.isActive) ...[
          const CcDivider(),
          _ClearFiltersRow(
            onClear: () {
              ref.read(widget.scope.filters.notifier).clear();
              widget.controller.hide();
            },
          ),
        ],
      ],
    );
  }

  /// Flat search across every category's options: typing narrows to matching
  /// values (authors, repos, statuses, windows); toggling one applies it and
  /// clears the query so the updated category list shows again.
  Widget _searchResults(
    AppLocalizations l10n,
    PrListFilters filters,
    List<PullRequest> allPrs,
    String login,
    bool includeDrafts,
    String query,
  ) {
    final notifier = ref.read(widget.scope.filters.notifier);
    final needle = query.toLowerCase();
    final results = <_SearchEntry>[];

    final viewerTeams =
        ref.read(viewerGitHubTeamsProvider).value ??
        const <String, Set<String>>{};
    List<PullRequest> population(PrFilterCategory c) => facetPopulation(
      allPrs,
      category: c,
      filters: filters,
      currentLogin: login,
      includeDrafts: includeDrafts,
      viewerTeamsByOrg: viewerTeams,
    );

    for (final option in statusFacetOptions(
      population(PrFilterCategory.status),
      filters: filters,
    )) {
      final label = prStatusFilterLabel(l10n, option.value);
      if (label.toLowerCase().contains(needle)) {
        results.add(
          _SearchEntry(
            label: label,
            categoryLabel: prFilterCategoryLabel(l10n, PrFilterCategory.status),
            icon: prStatusFilterIcon(option.value),
            count: option.count,
            selected: option.selected,
            onToggle: () => notifier.toggleStatus(option.value),
          ),
        );
      }
    }
    for (final category in [
      PrFilterCategory.author,
      PrFilterCategory.reviewer,
    ]) {
      final isAuthor = category == PrFilterCategory.author;
      final pop = population(category);
      final options = isAuthor
          ? authorFacetOptions(
              allPrs,
              pop,
              filters: filters,
              currentLogin: login,
            )
          : reviewerFacetOptions(
              allPrs,
              pop,
              filters: filters,
              currentLogin: login,
            );
      for (final option in options) {
        if (option.value.contains(needle)) {
          results.add(
            _SearchEntry(
              label: option.user?.login ?? option.value,
              categoryLabel: prFilterCategoryLabel(l10n, category),
              user: option.user,
              count: option.count,
              selected: option.selected,
              onToggle: isAuthor
                  ? () => notifier.toggleAuthor(option.value)
                  : () => notifier.toggleReviewer(option.value),
            ),
          );
        }
      }
    }
    for (final (category, ownerAxis) in [
      (PrFilterCategory.repoOwner, true),
      (PrFilterCategory.repoName, false),
    ]) {
      for (final option in repoFacetOptions(
        allPrs,
        population(category),
        filters: filters,
        ownerAxis: ownerAxis,
      )) {
        if (option.value.contains(needle)) {
          results.add(
            _SearchEntry(
              label: option.value,
              categoryLabel: prFilterCategoryLabel(l10n, category),
              icon: prFilterCategoryIcon(category),
              count: option.count,
              selected: option.selected,
              onToggle: ownerAxis
                  ? () => notifier.toggleRepoOwner(option.value)
                  : () => notifier.toggleRepoName(option.value),
            ),
          );
        }
      }
    }
    if (l10n.prFilterQuickToReview.toLowerCase().contains(needle)) {
      results.add(
        _SearchEntry(
          label: l10n.prFilterQuickToReview,
          categoryLabel: l10n.prFilterQuickToReview,
          icon: AppIcons.zap,
          count: quickToReviewCount(
            allPrs,
            filters: filters,
            currentLogin: login,
            includeDrafts: includeDrafts,
            viewerTeamsByOrg: viewerTeams,
          ),
          selected: filters.quickToReview,
          onToggle: notifier.toggleQuickToReview,
        ),
      );
    }

    if (results.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Text(
          l10n.prFilterNoOptions,
          style: CcTypography.bodySm.copyWith(
            color: (context.designSystem ?? DesignSystemTokens.light()).muted,
          ),
        ),
      );
    }

    const cap = 14;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in results.take(cap))
          _OptionRow(
            label: entry.label,
            trailingLabel: entry.categoryLabel,
            icon: entry.icon,
            user: entry.user,
            count: entry.count,
            selected: entry.selected,
            onToggle: () {
              entry.onToggle();
              _search.clear();
              setState(() {});
            },
          ),
      ],
    );
  }
}

/// How many of [category]'s values are part of the active filter (the root
/// menu rows' and the filter bar chips' count badges).
int prFilterCategoryActiveCount(
  PrListFilters filters,
  PrFilterCategory category,
) {
  return switch (category) {
    PrFilterCategory.status => filters.statuses.length,
    PrFilterCategory.author => filters.authors.length,
    PrFilterCategory.reviewer => filters.reviewers.length,
    PrFilterCategory.content => filters.content.isEmpty ? 0 : 1,
    PrFilterCategory.repoOwner => filters.repoOwners.length,
    PrFilterCategory.repoName => filters.repoNames.length,
    PrFilterCategory.openedDate => filters.openedWithin == null ? 0 : 1,
    PrFilterCategory.updatedDate => filters.updatedWithin == null ? 0 : 1,
  };
}

/// One search-result row's data.
class _SearchEntry {
  const _SearchEntry({
    required this.label,
    required this.categoryLabel,
    required this.count,
    required this.selected,
    required this.onToggle,
    this.icon,
    this.user,
  });

  final String label;
  final String categoryLabel;
  final int count;
  final bool selected;
  final VoidCallback onToggle;
  final IconData? icon;
  final PrUser? user;
}

/// The floating-panel chrome shared by the root menu, the category flyouts,
/// and the filter bar's chip-anchored flyouts — the CcPopover recipe.
class PrFilterPanel extends StatelessWidget {
  /// Creates a [PrFilterPanel].
  const PrFilterPanel({super.key, required this.width, required this.child});

  /// The panel's fixed width.
  final double width;

  /// The panel content.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final card = CcCardTokens.panel(t);
    return Container(
      width: width,
      constraints: const BoxConstraints(maxHeight: 420),
      decoration: BoxDecoration(
        color: card.bg,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: card.border),
        boxShadow: CcElevation.floating,
      ),
      child: ClipRRect(borderRadius: AppRadii.brLg, child: child),
    );
  }
}

/// The icon of a filter category (menu rows and filter bar chips).
IconData prFilterCategoryIcon(PrFilterCategory category) => switch (category) {
  PrFilterCategory.status => AppIcons.circleDot,
  PrFilterCategory.author => AppIcons.user,
  PrFilterCategory.reviewer => AppIcons.userCheck,
  PrFilterCategory.content => AppIcons.type,
  PrFilterCategory.repoOwner => AppIcons.building2,
  PrFilterCategory.repoName => AppIcons.folderGit2,
  PrFilterCategory.openedDate => AppIcons.calendar,
  PrFilterCategory.updatedDate => AppIcons.calendarClock,
};

/// The localized label of a filter category (menu rows and filter bar chips).
String prFilterCategoryLabel(
  AppLocalizations l10n,
  PrFilterCategory category,
) => switch (category) {
  PrFilterCategory.status => l10n.prFilterCategoryStatus,
  PrFilterCategory.author => l10n.prFilterCategoryAuthor,
  PrFilterCategory.reviewer => l10n.prFilterCategoryReviewer,
  PrFilterCategory.content => l10n.prFilterCategoryContent,
  PrFilterCategory.repoOwner => l10n.prFilterCategoryRepoOwner,
  PrFilterCategory.repoName => l10n.prFilterCategoryRepoName,
  PrFilterCategory.openedDate => l10n.prFilterCategoryOpenedDate,
  PrFilterCategory.updatedDate => l10n.prFilterCategoryUpdatedDate,
};

/// The localized label of a date window ("1 week ago").
String prDateWindowLabel(AppLocalizations l10n, PrDateWindow window) =>
    switch (window) {
      PrDateWindow.day => l10n.prDateWindowDay,
      PrDateWindow.threeDays => l10n.prDateWindowThreeDays,
      PrDateWindow.week => l10n.prDateWindowWeek,
      PrDateWindow.month => l10n.prDateWindowMonth,
      PrDateWindow.threeMonths => l10n.prDateWindowThreeMonths,
      PrDateWindow.sixMonths => l10n.prDateWindowSixMonths,
      PrDateWindow.year => l10n.prDateWindowYear,
    };

/// A root-menu category row: icon + label, an active-selection count and a
/// submenu chevron. Hovering (with a dwell) or activating opens the flyout.
class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.icon,
    required this.label,
    required this.activeCount,
    required this.open,
    required this.onHover,
    required this.onHoverEnd,
    required this.onOpen,
  });

  final IconData icon;
  final String label;
  final int activeCount;
  final bool open;
  final void Function(BuildContext rowContext) onHover;
  final VoidCallback onHoverEnd;
  final void Function(BuildContext rowContext) onOpen;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return Builder(
      builder: (rowContext) => CcTappable(
        onPressed: () => onOpen(rowContext),
        semanticLabel: label,
        builder: (context, states) {
          final hovered = states.contains(WidgetState.hovered) || open;
          return MouseRegion(
            onEnter: (_) => onHover(rowContext),
            onExit: (_) => onHoverEnd(),
            child: Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              color: hovered ? tokens.hover : const Color(0x00000000),
              child: Row(
                children: [
                  Icon(icon, size: 15, color: tokens.textSecondary),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: CcTypography.bodySm.copyWith(
                        color: tokens.textPrimary,
                      ),
                    ),
                  ),
                  if (activeCount > 0) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 1,
                      ),
                      decoration: BoxDecoration(
                        color: tokens.accentSoft,
                        borderRadius: AppRadii.brSm,
                      ),
                      child: Text(
                        '$activeCount',
                        style: CcTypography.caption.copyWith(
                          color: tokens.accent,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Icon(
                    AppIcons.chevronRight,
                    size: 14,
                    color: tokens.textTertiary,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

/// A root-menu leaf filter (quick to review): toggles directly, no flyout.
class _LeafToggleRow extends StatelessWidget {
  const _LeafToggleRow({
    required this.icon,
    required this.label,
    required this.count,
    required this.selected,
    required this.onToggle,
  });

  final IconData icon;
  final String label;
  final int count;
  final bool selected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return CcTappable(
      onPressed: onToggle,
      semanticLabel: '$label. ${l10n.prFilterMatchCount(count)}',
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          color: hovered ? tokens.hover : const Color(0x00000000),
          child: Row(
            children: [
              Icon(icon, size: 15, color: tokens.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: CcTypography.bodySm.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              Text(
                l10n.prFilterMatchCount(count),
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              _PassiveCheck(checked: selected, visible: selected || hovered),
            ],
          ),
        );
      },
    );
  }
}

/// The "clear filters" footer row shown while any filter is active.
class _ClearFiltersRow extends StatelessWidget {
  const _ClearFiltersRow({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return CcTappable(
      onPressed: onClear,
      semanticLabel: l10n.prFilterClearAll,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          color: hovered ? tokens.hover : const Color(0x00000000),
          child: Row(
            children: [
              Icon(AppIcons.filterX, size: 15, color: tokens.textSecondary),
              const SizedBox(width: AppSpacing.md),
              Text(
                l10n.prFilterClearAll,
                style: CcTypography.bodySm.copyWith(color: tokens.textPrimary),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A category's flyout panel: a filter field over its checkbox option rows
/// with counts, hiding zero-count options behind a reveal-able footer. The
/// content category renders a text field instead of options. Self-sufficient
/// (reads population, login and draft visibility itself), so the filter bar
/// can anchor one directly at a chip.
class PrFilterFlyout extends ConsumerStatefulWidget {
  /// Creates a [PrFilterFlyout].
  const PrFilterFlyout({
    super.key,
    required this.category,
    required this.scope,
    this.width = 320,
  });

  /// The category whose options the flyout shows.
  final PrFilterCategory category;

  /// The surface's filter state + population binding.
  final PrFilterScope scope;

  /// The panel's width.
  final double width;

  @override
  ConsumerState<PrFilterFlyout> createState() => _PrFilterFlyoutState();
}

class _PrFilterFlyoutState extends ConsumerState<PrFilterFlyout> {
  final TextEditingController _query = TextEditingController();
  // Initialized in initState (NOT a `late final` reading `ref` in its
  // initializer): dispose() touches the controller and a lazy initializer
  // first evaluated there would call `ref.read` during unmount and throw.
  late final TextEditingController _content;
  bool _showAll = false;

  @override
  void initState() {
    super.initState();
    _content = TextEditingController(
      text: ref.read(widget.scope.filters).content,
    );
  }

  @override
  void dispose() {
    _query.dispose();
    _content.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final filters = ref.watch(widget.scope.filters);

    if (widget.category == PrFilterCategory.content) {
      return PrFilterPanel(
        width: widget.width,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.sm),
          child: CcTextField(
            size: CcTextFieldSize.sm,
            hintText: l10n.prFilterContentHint,
            autofocus: true,
            prefix: const Icon(AppIcons.type, size: 14),
            controller: _content,
            onChanged: (value) =>
                ref.read(widget.scope.filters.notifier).setContent(value),
          ),
        ),
      );
    }

    final options = _options(filters);
    final needle = _query.text.trim().toLowerCase();
    final matching = needle.isEmpty
        ? options
        : [
            for (final o in options)
              if (o.label.toLowerCase().contains(needle)) o,
          ];
    final visible = _showAll
        ? matching
        : [
            for (final o in matching)
              if (o.count > 0 || o.selected) o,
          ];
    final hidden = matching.length - visible.length;

    return PrFilterPanel(
      width: widget.width,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(AppSpacing.sm),
            child: CcTextField(
              controller: _query,
              size: CcTextFieldSize.sm,
              hintText: l10n.prFilterFieldHint,
              autofocus: true,
              prefix: const Icon(AppIcons.search, size: 14),
              onChanged: (_) => setState(() {}),
            ),
          ),
          const CcDivider(),
          Flexible(
            child: visible.isEmpty && hidden == 0
                ? Padding(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    child: Text(
                      l10n.prFilterNoOptions,
                      style: CcTypography.bodySm.copyWith(
                        color:
                            (context.designSystem ?? DesignSystemTokens.light())
                                .muted,
                      ),
                    ),
                  )
                : ListView(
                    shrinkWrap: true,
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSpacing.xs,
                    ),
                    children: [
                      for (final option in visible)
                        _OptionRow(
                          label: option.label,
                          icon: option.icon,
                          user: option.user,
                          count: option.count,
                          selected: option.selected,
                          onToggle: option.onToggle,
                        ),
                    ],
                  ),
          ),
          if (hidden > 0) ...[
            const CcDivider(),
            _HiddenOptionsFooter(
              count: hidden,
              revealed: _showAll,
              onToggle: () => setState(() => _showAll = !_showAll),
            ),
          ],
        ],
      ),
    );
  }

  /// The category's option rows, localized and bound to their toggles.
  List<_FlyoutOption> _options(PrListFilters filters) {
    final l10n = AppLocalizations.of(context);
    final notifier = ref.read(widget.scope.filters.notifier);
    final allPrs = ref.watch(widget.scope.population);
    final login = ref.watch(currentUserLoginProvider);
    final includeDrafts = ref.watch(
      prListDisplayPrefsProvider.select((p) => p.showDrafts),
    );
    final viewerTeams =
        ref.watch(viewerGitHubTeamsProvider).value ??
        const <String, Set<String>>{};
    final population = facetPopulation(
      allPrs,
      category: widget.category,
      filters: filters,
      currentLogin: login,
      includeDrafts: includeDrafts,
      viewerTeamsByOrg: viewerTeams,
    );

    switch (widget.category) {
      case PrFilterCategory.status:
        return [
          for (final o in statusFacetOptions(population, filters: filters))
            _FlyoutOption(
              label: prStatusFilterLabel(l10n, o.value),
              icon: prStatusFilterIcon(o.value),
              count: o.count,
              selected: o.selected,
              onToggle: () => notifier.toggleStatus(o.value),
            ),
        ];
      case PrFilterCategory.author:
        return [
          for (final o in authorFacetOptions(
            allPrs,
            population,
            filters: filters,
            currentLogin: login,
          ))
            _FlyoutOption(
              label: o.user?.login ?? o.value,
              user: o.user,
              count: o.count,
              selected: o.selected,
              onToggle: () => notifier.toggleAuthor(o.value),
            ),
        ];
      case PrFilterCategory.reviewer:
        return [
          for (final o in reviewerFacetOptions(
            allPrs,
            population,
            filters: filters,
            currentLogin: login,
          ))
            _FlyoutOption(
              label: o.user?.login ?? o.value,
              user: o.user,
              count: o.count,
              selected: o.selected,
              onToggle: () => notifier.toggleReviewer(o.value),
            ),
        ];
      case PrFilterCategory.content:
        return const [];
      case PrFilterCategory.repoOwner:
      case PrFilterCategory.repoName:
        final ownerAxis = widget.category == PrFilterCategory.repoOwner;
        return [
          for (final o in repoFacetOptions(
            allPrs,
            population,
            filters: filters,
            ownerAxis: ownerAxis,
          ))
            _FlyoutOption(
              label: o.value,
              count: o.count,
              selected: o.selected,
              onToggle: ownerAxis
                  ? () => notifier.toggleRepoOwner(o.value)
                  : () => notifier.toggleRepoName(o.value),
            ),
        ];
      case PrFilterCategory.openedDate:
      case PrFilterCategory.updatedDate:
        final openedAxis = widget.category == PrFilterCategory.openedDate;
        return [
          for (final o in dateFacetOptions(
            population,
            filters: filters,
            openedAxis: openedAxis,
          ))
            _FlyoutOption(
              label: prDateWindowLabel(l10n, o.value),
              count: o.count,
              selected: o.selected,
              onToggle: openedAxis
                  ? () => notifier.setOpenedWithin(o.value)
                  : () => notifier.setUpdatedWithin(o.value),
            ),
        ];
    }
  }
}

/// A localized, toggle-bound flyout option.
class _FlyoutOption {
  const _FlyoutOption({
    required this.label,
    required this.count,
    required this.selected,
    required this.onToggle,
    this.icon,
    this.user,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onToggle;
  final IconData? icon;
  final PrUser? user;
}

/// One option row: a passive checkbox (visible on hover/focus/selection), a
/// leading icon or avatar, the label and the match count. Toggling keeps the
/// flyout open so several options can be combined.
class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.label,
    required this.count,
    required this.selected,
    required this.onToggle,
    this.icon,
    this.user,
    this.trailingLabel,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onToggle;
  final IconData? icon;
  final PrUser? user;
  final String? trailingLabel;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return CcTappable(
      onPressed: onToggle,
      semanticLabel: '$label. ${l10n.prFilterMatchCount(count)}',
      builder: (context, states) {
        final hovered =
            states.contains(WidgetState.hovered) ||
            states.contains(WidgetState.focused);
        return Container(
          height: 32,
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          color: hovered ? tokens.hover : const Color(0x00000000),
          child: Row(
            children: [
              _PassiveCheck(checked: selected, visible: selected || hovered),
              const SizedBox(width: AppSpacing.sm),
              if (user != null) ...[
                GitHubUserAvatar(
                  login: user!.login,
                  avatarUrl: user!.avatarUrl,
                  size: 18,
                  showHoverCard: false,
                ),
                const SizedBox(width: AppSpacing.sm),
              ] else if (icon != null) ...[
                Icon(icon, size: 15, color: tokens.textSecondary),
                const SizedBox(width: AppSpacing.sm),
              ],
              Expanded(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: CcTypography.bodySm.copyWith(
                    color: tokens.textPrimary,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                trailingLabel ?? l10n.prFilterMatchCount(count),
                style: CcTypography.caption.copyWith(
                  color: tokens.textTertiary,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// The muted footer summarizing options hidden for matching nothing; tapping
/// reveals (or re-hides) them.
class _HiddenOptionsFooter extends StatelessWidget {
  const _HiddenOptionsFooter({
    required this.count,
    required this.revealed,
    required this.onToggle,
  });

  final int count;
  final bool revealed;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final l10n = AppLocalizations.of(context);
    return CcTappable(
      onPressed: onToggle,
      semanticLabel: l10n.prFilterHiddenOptions(count),
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return Container(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          color: hovered ? tokens.hover : const Color(0x00000000),
          child: Row(
            children: [
              Icon(
                revealed ? AppIcons.eye : AppIcons.circleSlash,
                size: 14,
                color: tokens.textTertiary,
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  l10n.prFilterHiddenOptions(count),
                  style: CcTypography.caption.copyWith(
                    color: tokens.textTertiary,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// A 16px passive checkbox mirror (the row owns the tap), faded in on
/// hover/focus so unselected rows stay quiet.
class _PassiveCheck extends StatelessWidget {
  const _PassiveCheck({required this.checked, required this.visible});

  final bool checked;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: const Duration(milliseconds: 100),
      child: Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: checked ? tokens.accent : tokens.panel,
          borderRadius: AppRadii.brSm,
          border: Border.all(
            color: checked ? tokens.accent : tokens.lineStrong,
          ),
        ),
        child: checked
            ? Icon(AppIcons.check, size: 11, color: tokens.accentOn)
            : null,
      ),
    );
  }
}
