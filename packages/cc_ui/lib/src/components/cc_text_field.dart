import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/primitives/focus_ring.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Vertical density of a [CcTextField].
enum CcTextFieldSize {
  /// Default — comfortable 9px vertical padding.
  md,

  /// Compact — 6px vertical padding for toolbars / dense rows.
  sm,
}

/// A flat, single-line text field built directly on [EditableText].
///
/// A purist replacement for Material's `TextField`: it supplies the box
/// decoration, hint, prefix/suffix, focus ring, and error treatment that
/// Material's `InputDecorator` would normally provide, while staying on the
/// widgets layer (no Material, no ink).
///
/// The resting box is a hairline-bordered [CcInputTokens.bg] surface; gaining
/// keyboard focus swaps the border to [CcInputTokens.borderFocused] and
/// overlays the keyboard-only [FocusRing]. Supplying [errorText] flips the box
/// into the error treatment (danger border + subtle tint). Desktop-first: there
/// are no drag selection handles (`selectionControls: null`); keyboard selection
/// works via the default shortcuts.
class CcTextField extends StatefulWidget {
  /// Creates a [CcTextField].
  const CcTextField({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.prefix,
    this.suffix,
    this.enabled = true,
    this.obscureText = false,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.errorText,
    this.maxLength,
    this.autofocus = false,
    this.inputFormatters,
    this.size = CcTextFieldSize.md,
  });

  /// External controller; an internal one is created (and disposed) when null.
  final TextEditingController? controller;

  /// External focus node; an internal one is created (and disposed) when null.
  final FocusNode? focusNode;

  /// Placeholder shown behind the text while the field is empty.
  final String? hintText;

  /// Optional leading widget (e.g. a search icon).
  final Widget? prefix;

  /// Optional trailing widget (e.g. a clear button).
  final Widget? suffix;

  /// Whether the field accepts input.
  final bool enabled;

  /// Whether to obscure entered characters (passwords).
  final bool obscureText;

  /// Called as the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits (Enter).
  final ValueChanged<String>? onSubmitted;

  /// Soft keyboard / input type hint.
  final TextInputType? keyboardType;

  /// When non-null the field renders in its error state; the text itself is
  /// rendered by the caller elsewhere (this only drives the box treatment).
  final String? errorText;

  /// Optional hard character limit.
  final int? maxLength;

  /// Whether to focus the field on mount.
  final bool autofocus;

  /// Extra input formatters, applied before the optional [maxLength] limiter.
  final List<TextInputFormatter>? inputFormatters;

  /// Vertical density — [CcTextFieldSize.sm] tightens the box for toolbars.
  final CcTextFieldSize size;

  @override
  State<CcTextField> createState() => _CcTextFieldState();
}

class _CcTextFieldState extends State<CcTextField> {
  TextEditingController? _internalController;
  FocusNode? _internalFocus;
  bool _focused = false;

  TextEditingController get _controller =>
      widget.controller ?? (_internalController ??= TextEditingController());

  FocusNode get _focusNode =>
      widget.focusNode ?? (_internalFocus ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_onFocusChange);
    _controller.addListener(_onTextChange);
    _focused = _focusNode.hasFocus;
  }

  @override
  void didUpdateWidget(CcTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.focusNode != widget.focusNode) {
      (oldWidget.focusNode ?? _internalFocus)?.removeListener(_onFocusChange);
      _focusNode.addListener(_onFocusChange);
      _focused = _focusNode.hasFocus;
    }
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _internalController)
          ?.removeListener(_onTextChange);
      _controller.addListener(_onTextChange);
    }
  }

  @override
  void dispose() {
    (widget.focusNode ?? _internalFocus)?.removeListener(_onFocusChange);
    (widget.controller ?? _internalController)?.removeListener(_onTextChange);
    _internalFocus?.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focused != _focusNode.hasFocus && mounted) {
      setState(() => _focused = _focusNode.hasFocus);
    }
  }

  void _onTextChange() {
    // Drive hint visibility off the controller.
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.designSystem ?? DesignSystemTokens.light();
    final input = CcInputTokens.resolve(t);
    final hasError = widget.errorText != null;
    final enabled = widget.enabled;

    final baseStyle = DefaultTextStyle.of(context).style;
    final textStyle = baseStyle.merge(
      TextStyle(color: enabled ? input.text : t.textDisabled),
    );
    final hintStyle = baseStyle.merge(TextStyle(color: input.placeholder));

    final borderColor = hasError
        ? input.borderError
        : (_focused ? input.borderFocused : input.border);
    final bgColor = !enabled
        ? t.bgDisabled
        : (hasError ? input.bgError : input.bg);

    final Widget editable = EditableText(
      controller: _controller,
      focusNode: _focusNode,
      readOnly: !enabled,
      autofocus: widget.autofocus,
      obscureText: widget.obscureText,
      maxLines: 1,
      minLines: 1,
      keyboardType: widget.keyboardType ?? TextInputType.text,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      inputFormatters: [
        ...?widget.inputFormatters,
        if (widget.maxLength != null)
          LengthLimitingTextInputFormatter(widget.maxLength),
      ],
      style: textStyle,
      cursorColor: input.cursor,
      backgroundCursorColor: input.placeholder,
      selectionColor: input.selection,
      // Desktop-first: no drag handles, rely on keyboard selection.
      selectionControls: null,
      rendererIgnoresPointer: true,
      cursorOpacityAnimates: true,
    );

    // Hint sits behind the editable text while empty.
    final showHint =
        widget.hintText != null && _controller.text.isEmpty;

    final Widget field = Stack(
      children: [
        if (showHint)
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                widget.hintText!,
                style: hintStyle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        editable,
      ],
    );

    final Widget row = Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.prefix != null) ...[
          widget.prefix!,
          AppSpacing.hGapSm,
        ],
        Expanded(child: field),
        if (widget.suffix != null) ...[
          AppSpacing.hGapSm,
          widget.suffix!,
        ],
      ],
    );

    Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: 12,
          vertical: widget.size == CcTextFieldSize.sm ? 6 : 9,
        ),
        child: row,
      ),
    );

    // Tapping anywhere in the box focuses the field.
    box = GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: enabled
          ? () {
              if (!_focusNode.hasFocus) {
                _focusNode.requestFocus();
              }
            }
          : null,
      child: box,
    );

    // Keyboard-only focus ring overlaid without shifting layout.
    box = FocusRing(
      focusNode: _focusNode,
      borderRadius: AppRadii.brSm,
      color: hasError ? t.focusRingError : t.focusRing,
      enabled: enabled,
      child: box,
    );

    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.text : SystemMouseCursors.basic,
      child: box,
    );
  }
}
