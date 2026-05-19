import 'package:cc_ui/src/components/cc_icons.dart';
import 'package:cc_ui/src/components/cc_text_context_menu.dart';
import 'package:cc_ui/src/foundation/cc_browser_text_menu.dart';
import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_text_selection_gestures.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

const Color _transparent = Color(0x00000000);

/// A flat, multi-line text area built directly on [EditableText].
///
/// The multi-line sibling of `CcTextField`: same box decoration, hint, focus
/// ring and error treatment, but it grows vertically with its content (or up
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
    this.warnText,
    this.label,
    this.helperText,
    this.readOnly = false,
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

  /// When non-null the field renders in its error state and the message is
  /// shown beneath the box (with a danger glyph).
  final String? errorText;

  /// When non-null (and there is no error) the field renders in its warn state
  /// and the message is shown beneath the box with a warning glyph.
  final String? warnText;

  /// Optional persistent label rendered above the box.
  final String? label;

  /// Optional helper text rendered beneath the box when there is no error.
  final String? helperText;

  /// Whether the field is read-only: focusable and selectable, but not editable.
  final bool readOnly;

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

class _CcTextAreaState extends State<CcTextArea>
    implements TextSelectionGestureDetectorBuilderDelegate {
  TextEditingController? _internalController;
  FocusNode? _internalFocus;
  bool _focused = false;

  // --- TextSelectionGestureDetectorBuilderDelegate ---
  // Routes pointer gestures (tap-to-place-caret, click-drag selection,
  // double-click word selection, triple-click line selection) to the
  // EditableText, which on its own supports only keyboard-driven selection —
  // a bare RenderEditable places the caret on tap and nothing more, so a
  // prompt could be typed into but never selected with the mouse.
  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => true;

  late final CcTextSelectionGestureDetectorBuilder _selectionGestureBuilder =
      CcTextSelectionGestureDetectorBuilder(delegate: this);

  /// Whether the pointer is inside the field. Paired with [_focused] it is the
  /// exact window in which the browser should own right-click on web; it never
  /// affects what [build] produces, so it deliberately does not `setState`.
  bool _hovered = false;

  void _syncBrowserMenu() =>
      CcBrowserTextMenu.claim(this, wanted: _focused && _hovered);

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
      (oldWidget.controller ?? _internalController)?.removeListener(
        _onTextChange,
      );
      _controller.addListener(_onTextChange);
    }
  }

  @override
  void dispose() {
    CcBrowserTextMenu.claim(this, wanted: false);
    (widget.focusNode ?? _internalFocus)?.removeListener(_onFocusChange);
    (widget.controller ?? _internalController)?.removeListener(_onTextChange);
    _internalFocus?.dispose();
    _internalController?.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (_focused != _focusNode.hasFocus && mounted) {
      setState(() => _focused = _focusNode.hasFocus);
      _syncBrowserMenu();
    }
  }

  void _onTextChange() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final input = CcInputTokens.resolve(t);
    final hasError = widget.errorText != null;
    final hasWarn = widget.warnText != null && !hasError;
    final enabled = widget.enabled;

    final baseStyle = DefaultTextStyle.of(context).style;
    final textStyle = baseStyle.merge(
      TextStyle(color: enabled ? input.text : t.textDisabled),
    );
    final hintStyle = baseStyle.merge(TextStyle(color: input.placeholder));

    // Field chrome: 1px bottom underline at rest; focus/error/warn draw a
    // 2px outline over the whole box (foregroundDecoration, no layout shift).
    // Transparent (not null) at rest so the foregroundDecoration is ALWAYS
    // present — toggling it null↔non-null would restructure the Container and
    // reparent the child EditableText, dropping its text-input connection.
    final underlineColor = enabled ? input.border : t.borderDisabled;
    final outlineColor = !enabled
        ? _transparent
        : hasError
        ? input.borderError
        : hasWarn
        ? t.warn
        : _focused
        ? input.borderFocused
        : _transparent;
    final bgColor = !enabled
        ? t.bgDisabled
        : (hasError ? input.bgError : (hasWarn ? t.warnSoft : input.bg));

    Widget editable = EditableText(
      key: editableTextKey,
      controller: _controller,
      focusNode: _focusNode,
      readOnly: !enabled || widget.readOnly,
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
      // Only the FOCUSED field paints its selection: EditableText draws the
      // highlight whenever this is non-null, so a blurred field would keep a
      // live-looking selection after the caret moved elsewhere.
      selectionColor: _focused ? input.selection : null,
      // Desktop-first: no drag handles; pointer selection comes from the
      // gesture detector below, keyboard selection from the default shortcuts.
      selectionControls: null,
      // Right-click menu (cut/copy/paste/select all). Supplying a builder is
      // also what makes EditableText build a TextSelectionOverlay at all —
      // with both this and `selectionControls` null it tears the overlay down
      // on every selection change and `showToolbar()` is a silent no-op.
      contextMenuBuilder: ccTextContextMenuBuilder,
      rendererIgnoresPointer: true,
      cursorOpacityAnimates: true,
    );
    if (enabled) {
      editable = _selectionGestureBuilder.buildGestureDetector(
        behavior: HitTestBehavior.translucent,
        child: editable,
      );
    }

    // Hint sits behind the editable text, top-aligned, while empty.
    final showHint = widget.hintText != null && _controller.text.isEmpty;

    final Widget field = Stack(
      children: [
        if (showHint)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Text(widget.hintText!, style: hintStyle),
          ),
        editable,
      ],
    );

    Widget box = Container(
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(bottom: BorderSide(color: underlineColor)),
      ),
      foregroundDecoration: BoxDecoration(
        border: Border.all(color: outlineColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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

    final fieldWithMouse = MouseRegion(
      cursor: enabled ? SystemMouseCursors.text : SystemMouseCursors.basic,
      onEnter: (_) {
        _hovered = true;
        _syncBrowserMenu();
      },
      onExit: (_) {
        _hovered = false;
        _syncBrowserMenu();
      },
      child: box,
    );

    final showLabel = widget.label != null;
    final showError = hasError;
    final showWarn = hasWarn;
    final showHelper = widget.helperText != null && !showError && !showWarn;
    if (!showLabel && !showHelper && !showError && !showWarn) {
      return fieldWithMouse;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(
            widget.label!,
            style: CcTypography.caption.copyWith(color: t.textSecondary),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        fieldWithMouse,
        if (showError) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(CcIcons.circleX, size: 13, color: t.danger),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  widget.errorText!,
                  style: CcTypography.caption.copyWith(color: t.danger),
                ),
              ),
            ],
          ),
        ] else if (showWarn) ...[
          const SizedBox(height: AppSpacing.xs),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(CcIcons.triangleAlert, size: 13, color: t.warn),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  widget.warnText!,
                  style: CcTypography.caption.copyWith(color: t.warn),
                ),
              ),
            ],
          ),
        ] else if (showHelper) ...[
          const SizedBox(height: AppSpacing.xs),
          Text(
            widget.helperText!,
            style: CcTypography.caption.copyWith(color: t.textTertiary),
          ),
        ],
      ],
    );
  }
}
