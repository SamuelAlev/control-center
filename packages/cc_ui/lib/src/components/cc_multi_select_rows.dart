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
      semanticChecked: allSelected || someSelected,
      semanticMixed: someSelected && !allSelected,
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
                // target, the Tab stop and the checked state.
                _PassiveCheckbox(
                  value: allSelected,
                  indeterminate: someSelected && !allSelected,
                ),
                AppSpacing.hGapMd,
                Expanded(
                  child: ExcludeSemantics(
                    child: Text(
                      label,
                      style: CcTypography.bodySm.copyWith(
                        color: t.textPrimary,
                        fontWeight: CcTypography.mediumWeight,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
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
      semanticLabel: context.ccStrings.clearAll,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        return DecoratedBox(
          decoration: BoxDecoration(color: hovered ? t.hover : _transparent),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm,
            ),
            child: ExcludeSemantics(
              child: Text(
                context.ccStrings.clearAll,
                style: CcTypography.caption.copyWith(color: t.accent),
              ),
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
                _PassiveCheckbox(value: checked),
                AppSpacing.hGapMd,
                Expanded(
                  child: ExcludeSemantics(
                    child: CcTruncatedText(
                      option.label,
                      style: CcTypography.bodySm.copyWith(color: t.textPrimary),
                    ),
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

/// A checkbox drawn only for show: the row around it takes the taps, the Tab
/// stop and reports the checked state, so the box adds none of those.
class _PassiveCheckbox extends StatelessWidget {
  const _PassiveCheckbox({required this.value, this.indeterminate = false});

  final bool value;
  final bool indeterminate;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: ExcludeFocus(
        child: ExcludeSemantics(
          child: CcCheckbox(
            value: value,
            indeterminate: indeterminate,
            onChanged: (_) {},
          ),
        ),
      ),
    );
  }
}
