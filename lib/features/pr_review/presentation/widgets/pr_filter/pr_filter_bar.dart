import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_filter/pr_filter_facets.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pr_filter/pr_filter_menu.dart';
import 'package:control_center/features/pr_review/presentation/widgets/pull_request_list/pr_list_shared.dart';
import 'package:control_center/features/pr_review/providers/pr_filter_providers.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:control_center/shared/icons/app_icons.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The Linear-style active-filters bar shared by the PR queue and the inbox:
/// one segmented chip per active category — `[category] [is/…] [values] [✕]`
/// — plus a "+" trigger opening the full filter menu. Renders nothing while
/// no filter is active, so the zero-filter layout stays clean.
///
/// Tapping a chip's body reopens that category's option flyout anchored at
/// the chip (edit in place); the ✕ clears just that category.
class PrFilterBar extends ConsumerWidget {
  /// Creates a [PrFilterBar].
  const PrFilterBar({super.key, required this.scope});

  /// The surface's filter state + population binding.
  final PrFilterScope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(scope.filters);
    if (!filters.isActive) {
      return const SizedBox.shrink();
    }
    final l10n = AppLocalizations.of(context);

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final category in PrFilterCategory.values)
          if (prFilterCategoryActiveCount(filters, category) > 0)
            _FilterChip(scope: scope, category: category),
        if (filters.quickToReview) _QuickToReviewChip(scope: scope, l10n: l10n),
        _AddFilterTarget(scope: scope),
      ],
    );
  }
}

/// The verb segment between the category and its values.
String _chipVerb(
  AppLocalizations l10n,
  PrFilterCategory category,
  int valueCount,
) {
  return switch (category) {
    PrFilterCategory.content => l10n.prFilterChipContains,
    PrFilterCategory.openedDate ||
    PrFilterCategory.updatedDate => l10n.prFilterChipSince,
    _ => valueCount == 1 ? l10n.prFilterChipIs : l10n.prFilterChipIsAnyOf,
  };
}

/// The chip's value summary: up to two values joined, then a "+N" overflow.
/// The operator's own login renders as "Current user" (and sorts first).
String _chipValues(
  AppLocalizations l10n,
  PrListFilters filters,
  PrFilterCategory category,
  String login,
) {
  List<String> people(Set<String> logins) {
    final sorted = logins.toList()..sort();
    return [
      for (final l in sorted)
        if (l == login) l10n.prFilterCurrentUser,
      for (final l in sorted)
        if (l != login) l,
    ];
  }

  List<String> sortedSet(Set<String> values) => values.toList()..sort();

  final values = switch (category) {
    PrFilterCategory.status => [
      for (final s in PrStatusFilter.values)
        if (filters.statuses.contains(s)) prStatusFilterLabel(l10n, s),
    ],
    PrFilterCategory.author => people(filters.authors),
    PrFilterCategory.reviewer => people(filters.reviewers),
    PrFilterCategory.content => ['"${filters.content}"'],
    PrFilterCategory.repoOwner => sortedSet(filters.repoOwners),
    PrFilterCategory.repoName => sortedSet(filters.repoNames),
    PrFilterCategory.openedDate => [
      if (filters.openedWithin != null)
        prDateWindowLabel(l10n, filters.openedWithin!),
    ],
    PrFilterCategory.updatedDate => [
      if (filters.updatedWithin != null)
        prDateWindowLabel(l10n, filters.updatedWithin!),
    ],
  };
  if (values.length <= 2) {
    return values.join(', ');
  }
  return '${values.take(2).join(', ')} +${values.length - 2}';
}

/// One active-category chip. The body (category · verb · values) opens the
/// category's flyout anchored below the chip; the trailing ✕ clears the
/// category.
class _FilterChip extends ConsumerStatefulWidget {
  const _FilterChip({required this.scope, required this.category});

  final PrFilterScope scope;
  final PrFilterCategory category;

  @override
  ConsumerState<_FilterChip> createState() => _FilterChipState();
}

class _FilterChipState extends ConsumerState<_FilterChip> {
  final CcOverlayController _flyout = CcOverlayController();

  @override
  void dispose() {
    _flyout.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final filters = ref.watch(widget.scope.filters);
    final login = ref.watch(currentUserLoginProvider);
    final count = prFilterCategoryActiveCount(filters, widget.category);
    if (count == 0) {
      // The last value was cleared from the flyout while it was open.
      return const SizedBox.shrink();
    }
    final categoryLabel = prFilterCategoryLabel(l10n, widget.category);
    final verb = _chipVerb(l10n, widget.category, count);
    final values = _chipValues(l10n, filters, widget.category, login);

    return CcOverlayAnchor(
      controller: _flyout,
      targetAnchor: Alignment.bottomLeft,
      followerAnchor: Alignment.topLeft,
      offset: const Offset(0, 6),
      interceptPointer: true,
      target: _ChipSurface(
        children: [
          CcTappable(
            onPressed: _flyout.toggle,
            semanticLabel: '$categoryLabel $verb $values',
            builder: (context, states) {
              final hovered = states.contains(WidgetState.hovered);
              return ColoredBox(
                color: hovered ? tokens.hover : const Color(0x00000000),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _ChipSegment(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            prFilterCategoryIcon(widget.category),
                            size: 13,
                            color: tokens.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            categoryLabel,
                            style: CcTypography.caption.copyWith(
                              color: tokens.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _ChipDivider(tokens: tokens),
                    _ChipSegment(
                      child: Text(
                        verb,
                        style: CcTypography.caption.copyWith(
                          color: tokens.muted,
                        ),
                      ),
                    ),
                    _ChipDivider(tokens: tokens),
                    _ChipSegment(
                      child: Text(
                        values,
                        overflow: TextOverflow.ellipsis,
                        style: CcTypography.caption.copyWith(
                          color: tokens.textPrimary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          _ChipDivider(tokens: tokens),
          _ChipClear(
            semanticLabel: l10n.prFilterClearCategory(categoryLabel),
            onClear: () => ref
                .read(widget.scope.filters.notifier)
                .replace(clearCategory(filters, widget.category)),
          ),
        ],
      ),
      overlayBuilder: (context, _) =>
          PrFilterFlyout(category: widget.category, scope: widget.scope),
    );
  }
}

/// The boolean quick-to-review chip: no verb/value, just the label and a ✕
/// that toggles the filter off.
class _QuickToReviewChip extends ConsumerWidget {
  const _QuickToReviewChip({required this.scope, required this.l10n});

  final PrFilterScope scope;
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return _ChipSurface(
      children: [
        _ChipSegment(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.zap, size: 13, color: tokens.textSecondary),
              const SizedBox(width: AppSpacing.xs),
              Text(
                l10n.prFilterQuickToReview,
                style: CcTypography.caption.copyWith(
                  color: tokens.textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _ChipDivider(tokens: tokens),
        _ChipClear(
          semanticLabel: l10n.prFilterClearCategory(l10n.prFilterQuickToReview),
          onClear: () => ref.read(scope.filters.notifier).toggleQuickToReview(),
        ),
      ],
    );
  }
}

/// The bar's trailing "+" — opens the full filter menu anchored at itself.
class _AddFilterTarget extends StatefulWidget {
  const _AddFilterTarget({required this.scope});

  final PrFilterScope scope;

  @override
  State<_AddFilterTarget> createState() => _AddFilterTargetState();
}

class _AddFilterTargetState extends State<_AddFilterTarget> {
  final CcOverlayController _menu = CcOverlayController();

  @override
  void dispose() {
    _menu.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return PrFilterMenuAnchor(
      controller: _menu,
      scope: widget.scope,
      alignRight: false,
      target: CcTooltip(
        message: l10n.prFilterAddFilterButton,
        child: CcTappable(
          onPressed: _menu.toggle,
          semanticLabel: l10n.prFilterAddFilterButton,
          borderRadius: AppRadii.brMd,
          focusRingColor: tokens.focusRing,
          builder: (context, states) {
            final hovered = states.contains(WidgetState.hovered);
            return Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: hovered ? tokens.hover : tokens.panel,
                borderRadius: AppRadii.brMd,
                border: Border.all(color: tokens.borderSecondary),
              ),
              child: Icon(
                AppIcons.plus,
                size: 14,
                color: hovered ? tokens.textPrimary : tokens.textSecondary,
              ),
            );
          },
        ),
      ),
    );
  }
}

/// The chip's bordered pill surface, clipping its segment row.
class _ChipSurface extends StatelessWidget {
  const _ChipSurface({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return DecoratedBox(
      decoration: BoxDecoration(
        color: tokens.panel,
        borderRadius: AppRadii.brMd,
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: ClipRRect(
        borderRadius: AppRadii.brMd,
        child: IntrinsicHeight(
          child: Row(mainAxisSize: MainAxisSize.min, children: children),
        ),
      ),
    );
  }
}

class _ChipSegment extends StatelessWidget {
  const _ChipSegment({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // No `alignment:` here — an aligned Container expands to its max
    // constraints, which would blow the chip up to the bar's full width.
    return Container(
      height: 26,
      constraints: const BoxConstraints(maxWidth: 280),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      child: Align(widthFactor: 1, child: child),
    );
  }
}

class _ChipDivider extends StatelessWidget {
  const _ChipDivider({required this.tokens});

  final DesignSystemTokens tokens;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 1,
      height: 26,
      child: ColoredBox(color: tokens.borderSecondary),
    );
  }
}

/// The chip's trailing ✕ segment.
class _ChipClear extends StatelessWidget {
  const _ChipClear({required this.semanticLabel, required this.onClear});

  final String semanticLabel;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    return CcTooltip(
      message: semanticLabel,
      child: CcTappable(
        onPressed: onClear,
        semanticLabel: semanticLabel,
        builder: (context, states) {
          final hovered = states.contains(WidgetState.hovered);
          return Container(
            height: 26,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            color: hovered ? tokens.hover : const Color(0x00000000),
            child: Icon(
              AppIcons.x,
              size: 12,
              color: hovered ? tokens.textPrimary : tokens.textTertiary,
            ),
          );
        },
      ),
    );
  }
}
