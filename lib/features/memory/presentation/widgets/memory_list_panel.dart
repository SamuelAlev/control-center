import 'package:cc_domain/features/memory/domain/value_objects/memory_domain_scope.dart';
import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/features/memory/presentation/widgets/memory_scope_widgets.dart';
import 'package:control_center/features/settings/presentation/widgets/kit/settings_kit.dart';
import 'package:control_center/l10n/app_localizations.dart';
import 'package:flutter/widgets.dart';

/// Insets of a memory list, in line with the page header.
const EdgeInsetsGeometry kMemoryListPadding = EdgeInsetsDirectional.fromSTEB(
  AppSpacing.xl,
  0,
  AppSpacing.xl,
  AppSpacing.xl,
);

/// Below this width a toolbar's controls drop under its search field.
const double _kToolbarInlineBreakpoint = 720;

/// One slice of a list-shaped panel.
///
/// A workspace holds hundreds of facts, so the list has to stay lazy, and a
/// `SectionCard` wraps its body in a Column that builds every row. Corners are
/// square, so the frame can be drawn a row at a time instead: each slice paints
/// its own sides and bottom rule and the first adds the top.
class MemoryListItem extends StatelessWidget {
  /// Creates a [MemoryListItem].
  const MemoryListItem({super.key, required this.first, required this.child});

  /// Whether this is the panel's top row.
  final bool first;

  /// The row.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final side = BorderSide(color: t.borderSecondary);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: t.bgPrimary,
        border: BorderDirectional(
          top: first ? side : BorderSide.none,
          start: side,
          end: side,
          bottom: side,
        ),
      ),
      child: child,
    );
  }
}

/// The header of one group inside a list panel.
class MemoryGroupRail extends StatelessWidget {
  /// Creates a [MemoryGroupRail].
  const MemoryGroupRail({
    super.key,
    required this.label,
    required this.count,
    this.domainSlug,
  });

  /// The group's name.
  final String label;

  /// How many rows it holds.
  final int count;

  /// The domain behind it, to name the repo it is scoped to.
  final String? domainSlug;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final slug = domainSlug;
    return ColoredBox(
      color: t.rail,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.sm,
        ),
        child: Row(
          children: [
            // Expanded, so the name keeps its place at the start and the chip
            // is pushed all the way to the end. A Spacer beside a Flexible
            // splits the free space between them and leaves it mid-row.
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CcTypography.bodySm.copyWith(
                        color: t.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  CcBadge(label: '$count'),
                ],
              ),
            ),
            if (slug != null && MemoryDomainScope.repoSlugOf(slug) != null) ...[
              const SizedBox(width: AppSpacing.md),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 260),
                child: MemoryScopeChip(domainSlug: slug),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Search, facets and a live count above a memory list, with [controls] beside
/// the search field while there is room for them.
class MemoryListToolbar extends StatelessWidget {
  /// Creates a [MemoryListToolbar].
  const MemoryListToolbar({
    super.key,
    required this.query,
    required this.onQueryChanged,
    required this.searchHint,
    required this.facets,
    required this.facet,
    required this.onFacetChanged,
    required this.shown,
    required this.total,
    this.controls = const [],
  });

  /// The live query.
  final String query;

  /// Fired on every keystroke.
  final ValueChanged<String> onQueryChanged;

  /// Names what is searched.
  final String searchHint;

  /// The facets, in display order.
  final List<SettingsFacet<String>> facets;

  /// The selected facet.
  final String facet;

  /// Fired with the newly selected facet.
  final ValueChanged<String> onFacetChanged;

  /// How many rows the filters leave.
  final int shown;

  /// How many rows there are.
  final int total;

  /// Scope, sort and the like.
  final List<Widget> controls;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsetsDirectional.fromSTEB(
        AppSpacing.xl,
        AppSpacing.md,
        AppSpacing.xl,
        AppSpacing.md,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inline = constraints.maxWidth >= _kToolbarInlineBreakpoint;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              SettingsFilterBar<String>(
                query: query,
                onQueryChanged: onQueryChanged,
                searchHint: searchHint,
                facets: facets,
                selectedFacet: facet,
                onFacetChanged: onFacetChanged,
                resultLabel: l10n.settingsCountOfTotal(shown, total),
                trailing: inline && controls.isNotEmpty
                    ? Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (final (index, control) in controls.indexed) ...[
                            if (index > 0) const SizedBox(width: AppSpacing.sm),
                            control,
                          ],
                        ],
                      )
                    : null,
              ),
              if (!inline && controls.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.sm),
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: controls,
                ),
              ],
            ],
          );
        },
      ),
    );
  }
}
