part of 'cc_multi_select.dart';

/// The pinned parent select-all row: a tristate checkbox whose unchecked
/// state selects every option and whose checked/indeterminate states clear
/// the selection.
class _CcMultiSelectAllRow extends StatelessWidget {
  const _CcMultiSelectAllRow({
    required this.label,
    required this.allSelected,
    required this.someSelected,
    required this.onToggle,
  });

  final String label;
  final bool allSelected;
  final bool someSelected;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    return CcTappable(
      onPressed: onToggle,
      borderRadius: AppRadii.brSm,
      showFocusRing: false,
      canRequestFocus: false,
      semanticLabel: label,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return DecoratedBox(
          decoration: BoxDecoration(color: hovered ? t.hover : _transparent),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                // Passive mirror, same as the option rows: the row is the tap
                // target.
                IgnorePointer(
                  child: CcCheckbox(
                    value: allSelected,
                    indeterminate: someSelected && !allSelected,
                    onChanged: (_) {},
                  ),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: Text(
                    label,
                    style: CcTypography.bodySm.copyWith(
                      color: t.textPrimary,
                      fontWeight: CcTypography.mediumWeight,
                    ),
                    overflow: TextOverflow.ellipsis,
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

/// A "Clear all" affordance pinned at the top of the open multiselect panel
/// while any value is selected (the count tag clears the selection).
class _CcMultiSelectClearRow extends StatelessWidget {
  const _CcMultiSelectClearRow({required this.onClear});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    return CcTappable(
      onPressed: onClear,
      borderRadius: AppRadii.brSm,
      showFocusRing: false,
      canRequestFocus: false,
      semanticLabel: 'Clear all',
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return DecoratedBox(
          decoration: BoxDecoration(color: hovered ? t.hover : _transparent),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Text(
              'Clear all',
              style: CcTypography.caption.copyWith(color: t.accent),
            ),
          ),
        );
      },
    );
  }
}

class _CcMultiSelectRow<T> extends StatelessWidget {
  const _CcMultiSelectRow({
    required this.option,
    required this.checked,
    required this.highlighted,
    required this.onToggle,
  });

  final CcSelectOption<T> option;
  final bool checked;
  final bool highlighted;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;

    return CcTappable(
      onPressed: onToggle,
      borderRadius: AppRadii.brSm,
      showFocusRing: false,
      // The list node owns the keyboard; a focusable row would answer
      // Enter/Space itself and toggle the focused row, not the highlighted one.
      canRequestFocus: false,
      semanticLabel: option.label,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        final fluidActive = CcFluidHover.isItemActive(context);
        final wash = pressed
            ? t.hoverStrong
            : fluidActive
            ? _transparent
            : (hovered || highlighted)
            ? t.hover
            : _transparent;

        return DecoratedBox(
          decoration: BoxDecoration(color: wash),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: Row(
              children: [
                // The row is the tap target; the checkbox is a passive mirror so
                // its own gesture never competes with the row's CcTappable.
                IgnorePointer(
                  child: CcCheckbox(value: checked, onChanged: (_) {}),
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: CcTruncatedText(
                    option.label,
                    style: CcTypography.bodySm.copyWith(color: t.textPrimary),
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
