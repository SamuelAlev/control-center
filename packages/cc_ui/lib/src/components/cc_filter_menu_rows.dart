part of 'cc_filter_menu.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Root panel rows
// ─────────────────────────────────────────────────────────────────────────────

class _CategoryRow extends StatelessWidget {
  const _CategoryRow({
    required this.category,
    required this.highlighted,
    required this.open,
    required this.onActivate,
  });

  final CcFilterCategory category;
  final bool highlighted;
  final bool open;
  final VoidCallback onActivate;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final selectedCount = category.selected.length;

    return CcTappable(
      onPressed: onActivate,
      showFocusRing: false,
      canRequestFocus: false,
      semanticLabel: category.label,
      semanticSelected: highlighted,
      semanticExpanded: open,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        final fluidActive = CcFluidHover.isItemActive(context);
        final active = hovered || highlighted || open;
        final wash = pressed
            ? t.hoverStrong
            : open
            ? t.hover
            : fluidActive
            ? _transparent
            : (active ? t.hover : _transparent);
        return Container(
          constraints: const BoxConstraints(minHeight: 40),
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(color: wash),
          // A 2px inset accent bar marks the keyboard-highlighted row.
          foregroundDecoration: highlighted
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
                if (category.icon != null) ...[
                  Icon(category.icon, size: 16, color: t.textSecondary),
                  AppSpacing.hGapSm,
                ],
                Expanded(
                  // The row carries the label already.
                  child: ExcludeSemantics(
                    child: CcTruncatedText(
                      category.label,
                      style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                    ),
                  ),
                ),
                if (selectedCount > 0) ...[
                  AppSpacing.hGapSm,
                  Text(
                    '$selectedCount',
                    style: CcTypography.caption.copyWith(color: t.accent),
                  ),
                ],
                AppSpacing.hGapSm,
                Icon(CcIcons.chevronRight, size: 14, color: t.textTertiary),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Flyout rows
// ─────────────────────────────────────────────────────────────────────────────

class _OptionRow extends StatelessWidget {
  const _OptionRow({
    required this.option,
    required this.checked,
    required this.highlighted,
    required this.onToggle,
  });

  final CcFilterOption option;
  final bool checked;
  final bool highlighted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;

    return CcTappable(
      onPressed: onToggle,
      showFocusRing: false,
      canRequestFocus: false,
      semanticLabel: option.label,
      semanticChecked: checked,
      semanticSelected: highlighted,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        final fluidActive = CcFluidHover.isItemActive(context);
        final wash = pressed
            ? t.hoverStrong
            : fluidActive
            ? _transparent
            : (hovered || highlighted ? t.hover : _transparent);
        return Container(
          constraints: const BoxConstraints(minHeight: 40),
          alignment: AlignmentDirectional.centerStart,
          decoration: BoxDecoration(color: wash),
          foregroundDecoration: highlighted
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
                // The row is the tap target; the checkbox is a passive mirror
                // so its own gesture never competes with the row's tappable.
                // The row is also the checked state, so the box adds no Tab
                // stop and no node.
                IgnorePointer(
                  child: ExcludeFocus(
                    child: ExcludeSemantics(
                      child: CcCheckbox(value: checked, onChanged: (_) {}),
                    ),
                  ),
                ),
                AppSpacing.hGapMd,
                if (option.leading != null) ...[
                  option.leading!,
                  AppSpacing.hGapSm,
                ] else if (option.icon != null) ...[
                  Icon(option.icon, size: 16, color: t.textSecondary),
                  AppSpacing.hGapSm,
                ],
                Expanded(
                  child: ExcludeSemantics(
                    child: CcTruncatedText(
                      option.label,
                      style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                    ),
                  ),
                ),
                AppSpacing.hGapMd,
                Text(
                  option.countLabel ?? '${option.count}',
                  style: CcTypography.caption.copyWith(color: t.textTertiary),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
