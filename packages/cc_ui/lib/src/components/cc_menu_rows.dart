part of 'cc_menu.dart';

/// The hairline separator rendered for a [CcMenuItem.divider].
class _CcMenuDivider extends StatelessWidget {
  const _CcMenuDivider({this.flush = false});

  /// Whether to drop the vertical breathing room — used under the search
  /// field, where the hairline IS the field's bottom edge.
  final bool flush;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final line = SizedBox(
      height: 1,
      child: ColoredBox(color: t.borderSecondary),
    );
    return flush
        ? line
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: line,
          );
  }
}

/// The eyebrow rendered for a [CcMenuItem.section] — the same
/// treatment as `CcSidebarGroup`'s label, so a grouped menu reads as part of
/// the same system as the grouped sidebar.
class _CcMenuSection extends StatelessWidget {
  const _CcMenuSection({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    return Padding(
      // Symmetric horizontals, so direction-neutral by construction.
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.md,
        AppSpacing.xxs,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: CcTypography.label.copyWith(color: t.textTertiary),
      ),
    );
  }
}

/// The "nothing matched" row of a searchable menu.
class _CcMenuEmpty extends StatelessWidget {
  const _CcMenuEmpty({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      child: Text(
        label,
        style: CcTypography.bodySm.copyWith(color: t.textTertiary),
      ),
    );
  }
}

class _CcMenuRow extends StatelessWidget {
  const _CcMenuRow({
    required this.item,
    required this.onActivate,
    this.showCheckGutter = false,
    this.highlighted = false,
    this.expanded = false,
    this.focusable = true,
  });

  final CcMenuItem item;
  final VoidCallback onActivate;

  /// Whether to reserve the leading check-mark gutter (any selectable sibling).
  final bool showCheckGutter;

  /// Whether this row is the keyboard-highlighted one.
  final bool highlighted;

  /// Whether this submenu row's flyout is open.
  final bool expanded;

  /// Whether the row participates in Tab focus traversal, or is driven purely
  /// by [highlighted] (keys handled upstream).
  final bool focusable;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final fg = item.destructive ? t.danger : t.textPrimary;

    return CcTappable(
      onPressed: item.enabled ? onActivate : null,
      borderRadius: AppRadii.brSm,
      showFocusRing: false,
      canRequestFocus: focusable,
      semanticLabel: item.label,
      // The keyboard highlight is the list's active row; focus never moves
      // onto it, so assistive technology learns it from this flag.
      semanticSelected: highlighted,
      semanticChecked: showCheckGutter ? item.selected : null,
      semanticExpanded: item.hasChildren ? expanded : null,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        final focused = states.contains(WidgetState.focused);
        final disabled = states.contains(WidgetState.disabled);
        final fluidActive = CcFluidHover.isItemActive(context);
        final active = hovered || focused || highlighted;
        final wash = pressed
            ? t.hoverStrong
            : fluidActive
            ? const Color(0x00000000)
            : (active ? t.hover : const Color(0x00000000));
        final color = disabled ? t.textDisabled : fg;
        final checkColor = disabled ? t.textDisabled : t.accent;

        return Container(
          constraints: const BoxConstraints(minHeight: 40),
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(color: wash),
          // A 2px inset accent bar marks the keyboard-focused/highlighted row
          // (edge-to-edge menu items have no radius, so focus rides the edge).
          foregroundDecoration: (focused || highlighted) && !disabled
              ? BoxDecoration(
                  border: BorderDirectional(
                    start: BorderSide(color: t.accent, width: 2),
                  ),
                )
              : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                if (showCheckGutter) ...[
                  SizedBox(
                    width: 16,
                    child: item.selected
                        ? Icon(CcIcons.check, size: 14, color: checkColor)
                        : null,
                  ),
                  AppSpacing.hGapSm,
                ],
                if (item.leading case final leading?) ...[
                  leading(color),
                  AppSpacing.hGapSm,
                ] else if (item.icon != null) ...[
                  Icon(item.icon, size: 16, color: color),
                  AppSpacing.hGapSm,
                ],
                Expanded(
                  // The row already carries the label; read it once.
                  child: ExcludeSemantics(
                    child: CcTruncatedText(
                      item.label,
                      style: CcTypography.bodySm.copyWith(color: color),
                    ),
                  ),
                ),
                if (item.trailingChild != null) ...[
                  AppSpacing.hGapMd,
                  item.trailingChild!,
                ] else if (item.trailing != null) ...[
                  AppSpacing.hGapMd,
                  Text(
                    item.trailing!,
                    style: CcTypography.caption.copyWith(
                      color: disabled ? t.textDisabled : t.textTertiary,
                    ),
                  ),
                ],
                if (item.hasChildren) ...[
                  AppSpacing.hGapSm,
                  Icon(
                    CcIcons.chevronRight,
                    size: 14,
                    color: disabled ? t.textDisabled : t.textTertiary,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
