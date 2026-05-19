import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/primitives/focus_ring.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_radii.dart';
import 'package:cc_ui/src/tokens/design_system_tokens.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// A flat, multi-line text area built directly on [EditableText].
///
/// The multi-line sibling of `CcTextField`: same box decoration, hint, focus
/// ring, and error treatment, but it grows vertically with its content (or up
/// to [maxLines]) and reserves a taller resting height ([minLines] lines). It
/// stays on the widgets layer (no Material, no ink). Desktop-first: no drag
/// selection handles (`selectionControls: null`); keyboard selection works via
/// the default shortcuts.
class CcTextArea extends StatefulWidget {
  /// Creates a [CcTextArea].
  const CcTextArea({
    super.key,
    this.controller,
    this.focusNode,
    this.hintText,
    this.enabled = true,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.errorText,
    this.maxLength,
    this.autofocus = false,
    this.minLines = 3,
    this.maxLines,
  });

  /// External controller; an internal one is created (and disposed) when null.
  final TextEditingController? controller;

  /// External focus node; an internal one is created (and disposed) when null.
  final FocusNode? focusNode;

  /// Placeholder shown behind the text while the field is empty.
  final String? hintText;

  /// Whether the field accepts input.
  final bool enabled;

  /// Called as the text changes.
  final ValueChanged<String>? onChanged;

  /// Called when the user submits.
  final ValueChanged<String>? onSubmitted;

  /// Soft keyboard / input type hint. Defaults to multi-line.
  final TextInputType? keyboardType;

  /// When non-null the field renders in its error state.
  final String? errorText;

  /// Optional hard character limit.
  final int? maxLength;

  /// Whether to focus the field on mount.
  final bool autofocus;

  /// Minimum visible lines (resting height).
  final int minLines;

  /// Maximum visible lines before scrolling; null lets it expand freely.
  final int? maxLines;

  @override
  State<CcTextArea> createState() => _CcTextAreaState();
}

class _CcTextAreaState extends State<CcTextArea> {
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
  void didUpdateWidget(CcTextArea oldWidget) {
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
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      keyboardType: widget.keyboardType ?? TextInputType.multiline,
      textInputAction: TextInputAction.newline,
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      inputFormatters: widget.maxLength != null
          ? [LengthLimitingTextInputFormatter(widget.maxLength)]
          : null,
      style: textStyle,
      cursorColor: input.cursor,
      backgroundCursorColor: input.placeholder,
      selectionColor: input.selection,
      // Desktop-first: no drag handles, rely on keyboard selection.
      selectionControls: null,
      rendererIgnoresPointer: true,
      cursorOpacityAnimates: true,
    );

    // Hint sits behind the editable text, top-aligned, while empty.
    final showHint = widget.hintText != null && _controller.text.isEmpty;

    final Widget field = Stack(
      children: [
        if (showHint)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Text(
              widget.hintText!,
              style: hintStyle,
            ),
          ),
        editable,
      ],
    );

    Widget box = DecoratedBox(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: AppRadii.brSm,
        border: Border.all(color: borderColor),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        child: field,
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
