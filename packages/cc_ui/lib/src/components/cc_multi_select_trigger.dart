part of 'cc_multi_select.dart';

class _CcMultiSelectTrigger<T> extends StatelessWidget {
  const _CcMultiSelectTrigger({
    required this.options,
    required this.values,
    required this.hintText,
    required this.enabled,
    required this.showChips,
    required this.filterable,
    required this.countLabel,
    required this.chevronIcon,
    required this.isOpen,
    required this.semanticLabel,
    required this.triggerFocusNode,
    required this.filterController,
    required this.filterFocusNode,
    required this.tapGroup,
    required this.onPressed,
    required this.onClearAll,
    required this.onRemoveValue,
    required this.onClearFilter,
  });

  final List<CcSelectOption<T>> options;
  final Set<T> values;
  final String? hintText;
  final bool enabled;
  final bool showChips;
  final bool filterable;
  final String Function(int count)? countLabel;
  final IconData chevronIcon;
  final bool isOpen;
  final String? semanticLabel;

  /// The trigger's own focus stop.
  final FocusNode triggerFocusNode;

  /// Text controller for the filterable field's typed query.
  final TextEditingController filterController;

  /// Focus node for the filterable field's editable text.
  final FocusNode filterFocusNode;

  /// Tap-region group shared with the panel, so toggling a row never blurs
  /// the filter field.
  final Object tapGroup;

  final VoidCallback? onPressed;

  /// Clears the whole selection from the trigger's count tag ✕.
  final VoidCallback? onClearAll;

  /// Removes a single value from a summary chip's ✕ (showChips mode).
  final ValueChanged<T>? onRemoveValue;

  /// Clears the typed filter text (never the selection).
  final VoidCallback? onClearFilter;

  List<CcSelectOption<T>> get _selectedOptions =>
      options.where((o) => values.contains(o.value)).toList(growable: false);

  /// Whether the field currently shows an interactive clear affordance (the
  /// count tag's ✕, removable chips, or the clear-filter ✕) — that plus the
  /// interactive chevron is exactly when Carbon puts a vertical divider
  /// between the two interactive elements.
  bool get _showsInteractiveClear {
    if (!enabled) {
      return false;
    }
    if (filterable && isOpen && filterController.text.isNotEmpty) {
      return true;
    }
    if (values.isEmpty) {
      return false;
    }
    return showChips ? onRemoveValue != null : onClearAll != null;
  }

  /// What the trigger reads as its value: the chips' labels, or the count.
  String? _semanticValue(CcStrings strings) {
    if (values.isEmpty) {
      return null;
    }
    if (showChips) {
      return _selectedOptions.map((o) => o.label).join(', ');
    }
    return countLabel?.call(values.length) ??
        strings.selectedCount(values.length);
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final strings = context.ccStrings;
    final input = CcInputTokens.resolve(t);
    final duration = CcMotion.resolve(context, CcMotion.fast);
    final hasValue = values.isNotEmpty;
    final editing = filterable && isOpen && enabled;

    // The ✕ buttons and the filter text sit on top of the trigger, not inside
    // it: a button nested in a button is one screen-reader node and one Tab
    // stop, and the trigger's Space/Enter shortcuts would eat the typed text.
    // The trigger fills the box underneath and paints the chrome; the layer
    // above lets every tap but the ✕ buttons and the text fall through to it.
    Widget chrome(bool fieldHovered) => Positioned.fill(
      child: CcTappable(
        onPressed: onPressed,
        focusNode: triggerFocusNode,
        // While the filter text is up it is the field's focus stop.
        canRequestFocus: !editing,
        borderRadius: AppRadii.brSm,
        // A filterable field signals text entry with the I-beam on hover.
        mouseCursor: filterable && enabled ? SystemMouseCursors.text : null,
        semanticLabel: semanticLabel ?? hintText,
        semanticValue: _semanticValue(strings),
        semanticExpanded: isOpen,
        builder: (context, states) => _CcTriggerChrome(
          enabled: enabled,
          isOpen: isOpen,
          // Hovering a ✕ or the text is still hovering the field.
          hovered: fieldHovered || states.contains(WidgetState.hovered),
        ),
      ),
    );

    final content = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: editing
                ? _buildEditingSummary(t, input, hasValue, strings)
                : _buildSummary(t, input, enabled, hasValue, strings),
          ),
          if (editing && filterController.text.isNotEmpty) ...[
            AppSpacing.hGapSm,
            // Clears the typed filter text only — never the selection.
            CcTooltip(
              message: strings.clear,
              child: CcTappable(
                onPressed: onClearFilter,
                borderRadius: AppRadii.brXs,
                semanticLabel: strings.clear,
                builder: (context, states) => Icon(
                  CcIcons.x,
                  size: 14,
                  color: states.contains(WidgetState.hovered)
                      ? t.textPrimary
                      : t.textTertiary,
                ),
              ),
            ),
          ],
          if (_showsInteractiveClear) ...[
            AppSpacing.hGapSm,
            const IgnorePointer(child: _CcFieldDivider()),
          ],
          AppSpacing.hGapSm,
          IgnorePointer(
            child: AnimatedRotation(
              turns: isOpen ? 0.5 : 0,
              duration: duration,
              curve: CcMotion.standard,
              child: Icon(
                chevronIcon,
                size: 16,
                color: enabled ? t.fgTertiary : t.fgDisabled,
              ),
            ),
          ),
        ],
      ),
    );

    return _HoverRegion(
      builder: (hovered) => Stack(children: [chrome(hovered), content]),
    );
  }

  /// The open filterable field: the count tag stays pinned at the left and
  /// the rest of the row is the editable query text.
  Widget _buildEditingSummary(
    DesignSystemTokens t,
    CcInputTokens input,
    bool hasValue,
    CcStrings strings,
  ) {
    final count = values.length;
    return Row(
      children: [
        if (hasValue && !showChips) ...[
          _CcCountTag(
            label: countLabel?.call(count) ?? strings.selectedCount(count),
            enabled: enabled,
            clearLabel: strings.clearAll,
            onClear: onClearAll,
          ),
          AppSpacing.hGapSm,
        ],
        Expanded(
          child: EditableText(
            controller: filterController,
            focusNode: filterFocusNode,
            groupId: tapGroup,
            style: CcTypography.bodySm.copyWith(color: input.text),
            cursorColor: t.accent,
            backgroundCursorColor: t.hover,
            maxLines: 1,
            // Enter toggles the highlighted row; the caret stays to keep
            // filtering.
            onEditingComplete: ccSubmitKeepsFocus(filterController, null),
            // A click outside lands on the panel's barrier, which closes the
            // panel and hands focus back to the trigger. Dropping focus here
            // first (the desktop default) would leave it nowhere.
            onTapOutside: (_) {},
          ),
        ),
      ],
    );
  }

  /// The summary is read through the trigger's name and value, so its text
  /// stays out of the semantics tree and lets taps through to the trigger.
  Widget _buildSummary(
    DesignSystemTokens t,
    CcInputTokens input,
    bool enabled,
    bool hasValue,
    CcStrings strings,
  ) {
    if (!hasValue) {
      return IgnorePointer(
        child: ExcludeSemantics(
          child: Text(
            hintText ?? '',
            style: CcTypography.bodySm.copyWith(
              color: enabled ? input.placeholder : t.textDisabled,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (showChips) {
      final selected = _selectedOptions;
      return Wrap(
        spacing: AppSpacing.xs,
        runSpacing: AppSpacing.xs,
        children: [
          for (final option in selected)
            _CcSummaryChip(
              label: option.label,
              enabled: enabled,
              removeLabel: strings.remove(option.label),
              onRemove: onRemoveValue == null
                  ? null
                  : () => onRemoveValue!(option.value),
            ),
        ],
      );
    }

    // A count tag (with its own ✕ to clear the whole selection in place)
    // sits before the persistent hint text, so the field keeps saying what
    // it selects even while values are chosen.
    final count = values.length;
    final text = countLabel?.call(count) ?? strings.selectedCount(count);
    return Row(
      children: [
        _CcCountTag(
          label: text,
          enabled: enabled,
          clearLabel: strings.clearAll,
          onClear: onClearAll,
        ),
        if (hintText != null) ...[
          AppSpacing.hGapSm,
          Flexible(
            child: IgnorePointer(
              child: ExcludeSemantics(
                child: Text(
                  hintText!,
                  style: CcTypography.bodySm.copyWith(
                    color: enabled ? input.placeholder : t.textDisabled,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// A 1px vertical separator between two interactive elements inside an input
/// field (e.g. a clear ✕ and the chevron). Never drawn next to non-interactive
/// content and never between the caret and the placeholder/value text.
class _CcFieldDivider extends StatelessWidget {
  const _CcFieldDivider();

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    return Container(width: 1, height: 20, color: t.borderPrimary);
  }
}

/// Reports whether the pointer is anywhere over [builder]'s result, including
/// over children that win the hit test above the trigger.
class _HoverRegion extends StatefulWidget {
  const _HoverRegion({required this.builder});

  final Widget Function(bool hovered) builder;

  @override
  State<_HoverRegion> createState() => _HoverRegionState();
}

class _HoverRegionState extends State<_HoverRegion> {
  bool _hovered = false;

  void _set(bool hovered) {
    if (_hovered != hovered) {
      setState(() => _hovered = hovered);
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _set(true),
      onExit: (_) => _set(false),
      child: widget.builder(_hovered),
    );
  }
}

/// A decorated box that never takes a hit itself, so a tap on a tag's fill
/// reaches the trigger underneath while its ✕ stays its own target.
class _PassThroughBox extends StatelessWidget {
  const _PassThroughBox({required this.decoration, required this.child});

  final Decoration decoration;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: IgnorePointer(child: DecoratedBox(decoration: decoration)),
        ),
        child,
      ],
    );
  }
}

/// The trigger's box: fill, hover wash, resting underline and open outline.
class _CcTriggerChrome extends StatelessWidget {
  const _CcTriggerChrome({
    required this.enabled,
    required this.isOpen,
    required this.hovered,
  });

  final bool enabled;
  final bool isOpen;
  final bool hovered;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final input = CcInputTokens.resolve(t);
    // Field chrome: 1px bottom underline at rest; open draws the 2px accent
    // outline over the whole box (foregroundDecoration, no layout shift).
    final underlineColor = !enabled ? t.borderDisabled : input.border;
    final outlineColor = enabled && isOpen ? input.borderFocused : _transparent;
    return Container(
      decoration: BoxDecoration(
        color: !enabled
            ? t.bgDisabled
            : hovered
            ? t.bgSecondaryHover
            : input.bg,
        border: Border(bottom: BorderSide(color: underlineColor)),
      ),
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: outlineColor, width: 2),
      ),
    );
  }
}

/// The selection-count tag in the trigger: the count summary plus a ✕ that
/// clears the whole selection without opening the panel.
class _CcCountTag extends StatelessWidget {
  const _CcCountTag({
    required this.label,
    required this.enabled,
    required this.clearLabel,
    required this.onClear,
  });

  final String label;
  final bool enabled;
  final String clearLabel;
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final fg = enabled ? t.textPrimary : t.textDisabled;
    return _PassThroughBox(
      decoration: BoxDecoration(
        color: enabled ? t.bgSecondary : t.bgDisabled,
        borderRadius: AppRadii.brSm,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Read as the trigger's value.
            IgnorePointer(
              child: ExcludeSemantics(
                child: Text(
                  label,
                  style: CcTypography.caption.copyWith(color: fg),
                ),
              ),
            ),
            if (onClear != null) ...[
              const SizedBox(width: AppSpacing.xs),
              CcTooltip(
                message: clearLabel,
                child: CcTappable(
                  onPressed: onClear,
                  borderRadius: AppRadii.brXs,
                  semanticLabel: clearLabel,
                  builder: (context, states) => Icon(
                    CcIcons.x,
                    size: 12,
                    color: states.contains(WidgetState.hovered)
                        ? t.textPrimary
                        : t.textTertiary,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _CcSummaryChip extends StatelessWidget {
  const _CcSummaryChip({
    required this.label,
    required this.enabled,
    required this.removeLabel,
    this.onRemove,
  });

  final String label;
  final bool enabled;
  final String removeLabel;

  /// Dismisses this chip's value from the selection (a dismissible tag).
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final fg = enabled ? t.textPrimary : t.textDisabled;
    return _PassThroughBox(
      decoration: BoxDecoration(
        color: enabled ? t.surface : t.bgDisabled,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: t.borderPrimary),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.sm,
          vertical: AppSpacing.xxs,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Read as part of the trigger's value.
            Flexible(
              child: IgnorePointer(
                child: ExcludeSemantics(
                  child: Text(
                    label,
                    style: CcTypography.caption.copyWith(color: fg),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            if (enabled && onRemove != null) ...[
              const SizedBox(width: AppSpacing.xs),
              CcTappable(
                onPressed: onRemove,
                borderRadius: AppRadii.brXs,
                semanticLabel: removeLabel,
                builder: (context, states) => Icon(
                  CcIcons.x,
                  size: 12,
                  color: states.contains(WidgetState.hovered)
                      ? t.textPrimary
                      : t.textTertiary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
