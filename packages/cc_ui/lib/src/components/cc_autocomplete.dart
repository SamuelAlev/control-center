import 'package:cc_ui/src/components/cc_select.dart';
import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_elevation.dart';
import 'package:cc_ui/src/foundation/cc_overlay_anchor.dart';
import 'package:cc_ui/src/foundation/cc_tappable.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/primitives/focus_ring.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const Color _transparent = Color(0x00000000);

/// Filters [options] for a typed [query]. Return the matches in display order.
typedef CcAutocompleteFilter<T> = List<CcSelectOption<T>> Function(
  List<CcSelectOption<T>> options,
  String query,
);

/// A flat autocomplete field — an input whose typed query filters a list of
/// [CcSelectOption]s, shown in a floating panel anchored below the field.
///
/// The field is an input-styled box wrapping an [EditableText] (no Material).
/// As the user types, [filter] (or a default case-insensitive `contains` on the
/// label) narrows [options]; the matches render in a width-matched floating
/// panel of [CcTappable] rows. Selecting a row fills the field with the option's
/// display string (via [displayString], defaulting to its label), closes the
/// panel, and calls [onSelected]. The field keeps focus while the list is open.
class CcAutocomplete<T> extends StatefulWidget {
  /// Creates a [CcAutocomplete].
  const CcAutocomplete({
    super.key,
    required this.options,
    required this.onSelected,
    this.hintText,
    this.displayString,
    this.filter,
    this.enabled = true,
    this.controller,
    this.focusNode,
    this.semanticLabel,
  });

  /// The full set of options to filter.
  final List<CcSelectOption<T>> options;

  /// Called with the chosen value when a row is selected.
  final ValueChanged<T> onSelected;

  /// Placeholder shown while the field is empty.
  final String? hintText;

  /// Maps an option to the string written into the field on selection and used
  /// for the default filter. Defaults to the option's label.
  final String Function(CcSelectOption<T> option)? displayString;

  /// Custom filter; defaults to a case-insensitive `contains` on the display
  /// string.
  final CcAutocompleteFilter<T>? filter;

  /// Whether the field is interactive.
  final bool enabled;

  /// Optional external text controller.
  final TextEditingController? controller;

  /// Optional external focus node.
  final FocusNode? focusNode;

  /// Accessibility label for the field.
  final String? semanticLabel;

  @override
  State<CcAutocomplete<T>> createState() => _CcAutocompleteState<T>();
}

class _CcAutocompleteState<T> extends State<CcAutocomplete<T>> {
  final CcOverlayController _controller = CcOverlayController();
  TextEditingController? _internalText;
  FocusNode? _internalFocus;
  List<CcSelectOption<T>> _matches = const [];

  TextEditingController get _text =>
      widget.controller ?? (_internalText ??= TextEditingController());

  FocusNode get _focus => widget.focusNode ?? (_internalFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _text.addListener(_onQueryChanged);
    _matches = widget.options;
  }

  @override
  void dispose() {
    _text.removeListener(_onQueryChanged);
    _internalText?.dispose();
    _internalFocus?.dispose();
    _controller.dispose();
    super.dispose();
  }

  String _display(CcSelectOption<T> option) =>
      widget.displayString?.call(option) ?? option.label;

  void _onQueryChanged() {
    final query = _text.text;
    final filter = widget.filter ?? _defaultFilter;
    final next = filter(widget.options, query);
    setState(() => _matches = next);
    if (widget.enabled && next.isNotEmpty) {
      _controller.show();
    } else {
      _controller.hide();
    }
  }

  List<CcSelectOption<T>> _defaultFilter(
    List<CcSelectOption<T>> options,
    String query,
  ) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      return options;
    }
    return options
        .where((o) => _display(o).toLowerCase().contains(q))
        .toList(growable: false);
  }

  void _select(CcSelectOption<T> option) {
    final value = _display(option);
    _text
      ..text = value
      ..selection = TextSelection.collapsed(offset: value.length);
    _controller.hide();
    // Keep the field focused after selection.
    _focus.requestFocus();
    widget.onSelected(option.value);
  }

  void _onFieldTap() {
    if (!widget.enabled) {
      return;
    }
    _focus.requestFocus();
    if (_matches.isNotEmpty) {
      _controller.show();
    }
  }

  @override
  Widget build(BuildContext context) {
    return CcOverlayAnchor(
      controller: _controller,
      matchTargetWidth: true,
      barrierDismissible: true,
      target: _CcAutocompleteField(
        controller: _text,
        focusNode: _focus,
        hintText: widget.hintText,
        enabled: widget.enabled,
        semanticLabel: widget.semanticLabel,
        onTap: _onFieldTap,
      ),
      overlayBuilder: _buildPanel,
    );
  }

  Widget _buildPanel(BuildContext context, Size? targetSize) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final card = CcCardTokens.panel(t);

    if (_matches.isEmpty) {
      return const SizedBox.shrink();
    }

    return DecoratedBox(
      decoration: BoxDecoration(
        color: card.bg,
        borderRadius: AppRadii.brLg,
        border: Border.all(color: card.border),
        boxShadow: CcElevation.floating,
      ),
      child: ClipRRect(
        borderRadius: AppRadii.brLg,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final option in _matches)
                _CcAutocompleteRow<T>(
                  option: option,
                  onPressed: () => _select(option),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// The input-styled field used by [CcAutocomplete].
class _CcAutocompleteField extends StatelessWidget {
  const _CcAutocompleteField({
    required this.controller,
    required this.focusNode,
    required this.hintText,
    required this.enabled,
    required this.semanticLabel,
    required this.onTap,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? hintText;
  final bool enabled;
  final String? semanticLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final input = CcInputTokens.resolve(t);
    final textStyle = CcTypography.bodySm.copyWith(
      color: enabled ? input.text : t.textDisabled,
    );

    return Semantics(
      textField: true,
      label: semanticLabel,
      child: FocusRing(
        focusNode: focusNode,
        borderRadius: AppRadii.brSm,
        enabled: enabled,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: enabled ? input.bg : t.bgDisabled,
              borderRadius: AppRadii.brSm,
              border: Border.all(color: input.border),
            ),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              child: Stack(
                children: [
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: controller,
                    builder: (context, value, _) {
                      if (value.text.isNotEmpty) {
                        return const SizedBox.shrink();
                      }
                      return Text(
                        hintText ?? '',
                        style: textStyle.copyWith(color: input.placeholder),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      );
                    },
                  ),
                  EditableText(
                    controller: controller,
                    focusNode: focusNode,
                    readOnly: !enabled,
                    style: textStyle,
                    cursorColor: input.cursor,
                    backgroundCursorColor: input.placeholder,
                    selectionColor: input.selection,
                    maxLines: 1,
                    keyboardType: TextInputType.text,
                    textInputAction: TextInputAction.done,
                    cursorWidth: 1.5,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _CcAutocompleteRow<T> extends StatelessWidget {
  const _CcAutocompleteRow({
    required this.option,
    required this.onPressed,
  });

  final CcSelectOption<T> option;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();

    return CcTappable(
      onPressed: onPressed,
      borderRadius: AppRadii.brSm,
      showFocusRing: false,
      canRequestFocus: false,
      semanticLabel: option.label,
      builder: (context, states) {
        final hovered = states.contains(WidgetState.hovered);
        final pressed = states.contains(WidgetState.pressed);
        final wash = pressed
            ? t.hoverStrong
            : hovered
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
                if (option.icon != null) ...[
                  Icon(option.icon, size: 16, color: t.textSecondary),
                  AppSpacing.hGapSm,
                ],
                Expanded(
                  child: Text(
                    option.label,
                    style: CcTypography.bodySm.copyWith(color: t.textPrimary),
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
