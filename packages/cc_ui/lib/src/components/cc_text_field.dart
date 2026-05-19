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

/// Vertical density of a [CcTextField].
enum CcTextFieldSize {
  /// Default — ~40px tall (matches the md button height).
  md,

  /// Compact — ~32px tall for toolbars / dense rows.
  sm,
}

/// A flat, single-line text field built directly on [EditableText].
///
/// A purist replacement for Material's `TextField`: it supplies the box
/// decoration, hint, prefix/suffix, focus treatment and error treatment that
/// Material's `InputDecorator` would normally provide, while staying on the
/// widgets layer (no Material, no ink).
///
/// The resting box is a quiet [CcInputTokens.bg] fill closed by a single 1px
/// bottom underline; gaining focus (keyboard or pointer) draws a 2px
/// [CcInputTokens.borderFocused] outline around the box via
/// `foregroundDecoration`, so layout never shifts. Supplying [errorText]
/// swaps the outline to danger (+ subtle tint). Desktop-first: there are no
/// drag selection handles (`selectionControls: null`), but pointer selection
/// (click-drag, double-click word select) is wired via a
/// [TextSelectionGestureDetectorBuilder]; keyboard selection works via the
/// default shortcuts.
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
    this.warnText,
    this.label,
    this.helperText,
    this.readOnly = false,
    this.maxLength,
    this.autofocus = false,
    this.inputFormatters,
    this.size = CcTextFieldSize.md,
    this.chromeless = false,
    this.maxLines = 1,
    this.minLines = 1,
    this.textStyle,
    this.initialValue,
    this.textInputAction,
    this.textAlign = TextAlign.start,
    this.expands = false,
    this.onEditingComplete,
  }) : assert(
         maxLines == null || minLines == null || maxLines >= minLines,
         'CcTextField needs maxLines >= minLines',
       );

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

  /// When non-null the field renders in its error state and the message is
  /// shown beneath the box (with a danger glyph).
  final String? errorText;

  /// When non-null (and there is no error) the field renders in its warn state
  /// and the message is shown beneath the box with a warning glyph.
  final String? warnText;

  /// Optional persistent label rendered above the box (required for
  /// accessible fields — prefer this over a placeholder-only affordance).
  final String? label;

  /// Optional helper text rendered beneath the box when there is no error.
  final String? helperText;

  /// Whether the field is read-only: focusable and selectable, but not editable
  /// (distinct from [enabled], which fully disables and mutes the field).
  final bool readOnly;

  /// Optional hard character limit.
  final int? maxLength;

  /// Whether to focus the field on mount.
  final bool autofocus;

  /// Extra input formatters, applied before the optional [maxLength] limiter.
  final List<TextInputFormatter>? inputFormatters;

  /// Vertical density — [CcTextFieldSize.sm] tightens the box for toolbars.
  final CcTextFieldSize size;

  /// Drops ALL field chrome: no fill, no underline, no focus outline and no
  /// inner padding — just the editable text, hint and prefix/suffix.
  ///
  /// For inputs embedded in a surface that already draws its own container
  /// (a search row inside a popover, a composer inside a bordered card). The
  /// host owns the box; this owns the text. Prefer the default decorated field
  /// for standalone inputs — chromeless removes the focus affordance, so the
  /// host must provide one.
  final bool chromeless;

  /// Maximum visible lines; null grows without bound. Any value other than 1
  /// makes the field multiline (and defaults [keyboardType] to
  /// [TextInputType.multiline]).
  final int? maxLines;

  /// Minimum visible lines the box reserves.
  final int? minLines;

  /// Overrides the resolved text style (e.g. a monospace family for code).
  /// Merged last, so an explicit color here wins over the token default.
  final TextStyle? textStyle;

  /// Seeds the text when no [controller] is supplied. Ignored when a
  /// [controller] is given — that controller's text is the source of truth.
  final String? initialValue;

  /// Keyboard action button (e.g. [TextInputAction.next] in a form chain).
  final TextInputAction? textInputAction;

  /// Horizontal alignment of the text (e.g. right-aligned numerics).
  final TextAlign textAlign;

  /// Whether the field expands to fill its parent's height instead of sizing to
  /// its content. Requires an unbounded [maxLines] (pass `maxLines: null`) and
  /// a parent that provides a bounded height.
  final bool expands;

  /// Called when the user finishes editing (Enter / focus loss on desktop).
  final VoidCallback? onEditingComplete;

  /// Whether this field spans more than one line.
  bool get isMultiline => maxLines != 1;

  @override
  State<CcTextField> createState() => _CcTextFieldState();
}

class _CcTextFieldState extends State<CcTextField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  TextEditingController? _internalController;
  FocusNode? _internalFocus;
  bool _focused = false;

  // --- TextSelectionGestureDetectorBuilderDelegate ---
  // Routes pointer gestures (tap-to-place-caret, click-drag selection,
  // double-click word selection) to the EditableText, which otherwise only
  // supports keyboard-driven selection.
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
      widget.controller ??
      (_internalController ??= TextEditingController(
        text: widget.initialValue ?? '',
      ));

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
      (oldWidget.controller ?? _internalController)?.removeListener(
        _onTextChange,
      );
      _controller.addListener(_onTextChange);
      // A swapped controller can flip emptiness without firing a change.
      _textIsEmpty = _controller.text.isEmpty;
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

  /// Whether the controller's text is currently empty; only a FLIP of this
  /// changes what [build] produces.
  late bool _textIsEmpty = _controller.text.isEmpty;

  void _onFocusChange() {
    if (_focused != _focusNode.hasFocus && mounted) {
      setState(() => _focused = _focusNode.hasFocus);
      _syncBrowserMenu();
    }
  }

  void _onTextChange() {
    // Drive hint visibility off the controller — but ONLY on the transition,
    // the way `_onFocusChange` already does. Rebuilding on every keystroke
    // rebuilt the whole decorator stack and re-merged three style chains to
    // change nothing, on the field a user types into continuously.
    final isEmpty = _controller.text.isEmpty;
    if (_textIsEmpty != isEmpty && mounted) {
      setState(() => _textIsEmpty = isEmpty);
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
    // The caller's textStyle merges LAST so an explicit family/size/color at
    // the call site wins over the token default.
    final textStyle = baseStyle
        .merge(TextStyle(color: enabled ? input.text : t.textDisabled))
        .merge(widget.textStyle);
    final hintStyle = baseStyle
        .merge(TextStyle(color: input.placeholder))
        .merge(widget.textStyle?.copyWith(color: input.placeholder));

    // Field chrome: 1px bottom underline at rest; focus/error/warn draw a
    // 2px outline over the whole box (foregroundDecoration, no layout shift).
    // The outline color is transparent at rest rather than null so the
    // foregroundDecoration is ALWAYS present — toggling it null↔non-null would
    // restructure the Container and reparent the child EditableText, tearing
    // down its text-input connection mid-typing.
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
      obscureText: widget.obscureText,
      maxLines: widget.maxLines,
      minLines: widget.minLines,
      expands: widget.expands,
      textAlign: widget.textAlign,
      textInputAction: widget.textInputAction,
      keyboardType:
          widget.keyboardType ??
          (widget.isMultiline ? TextInputType.multiline : TextInputType.text),
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      onEditingComplete: widget.onEditingComplete,
      inputFormatters: [
        ...?widget.inputFormatters,
        if (widget.maxLength != null)
          LengthLimitingTextInputFormatter(widget.maxLength),
      ],
      style: textStyle,
      cursorColor: input.cursor,
      backgroundCursorColor: input.placeholder,
      // Only the FOCUSED field paints its selection. EditableText paints the
      // highlight whenever `selectionColor` is non-null, so a blurred field
      // otherwise keeps a live-looking selection while the caret and every
      // keyboard action have moved elsewhere (Material's TextField gates it
      // the same way).
      selectionColor: _focused ? input.selection : null,
      // Desktop-first: no drag handles; pointer selection comes from the
      // gesture detector below, keyboard selection from the default shortcuts.
      selectionControls: null,
      // Right-click menu (cut/copy/paste/select all). Supplying a builder is
      // also what makes EditableText build a TextSelectionOverlay at all —
      // with both this and `selectionControls` null it tears the overlay down
      // on every selection change and `showToolbar()` is a silent no-op.
      contextMenuBuilder: ccTextContextMenuBuilder,
      // Pointer handling lives in the selection gesture detector wrapping the
      // EditableText — it places the caret on tap, selects on click-drag and
      // selects the word under a double-click.
      rendererIgnoresPointer: true,
      cursorOpacityAnimates: true,
    );
    if (enabled) {
      editable = _selectionGestureBuilder.buildGestureDetector(
        behavior: HitTestBehavior.translucent,
        child: editable,
      );
    }

    // Hint sits behind the editable text while empty.
    final showHint = widget.hintText != null && _controller.text.isEmpty;

    final Widget field = Stack(
      children: [
        if (showHint)
          Positioned.fill(
            child: Align(
              // A multiline field's hint sits on the first line, not the
              // vertical centre of the grown box.
              alignment: widget.isMultiline
                  ? Alignment.topLeft
                  : Alignment.centerLeft,
              child: Text(
                widget.hintText!,
                style: hintStyle,
                maxLines: widget.isMultiline ? null : 1,
                overflow: widget.isMultiline
                    ? TextOverflow.clip
                    : TextOverflow.ellipsis,
              ),
            ),
          ),
        editable,
      ],
    );

    final Widget row = Row(
      crossAxisAlignment: widget.isMultiline
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.center,
      children: [
        if (widget.prefix != null) ...[widget.prefix!, AppSpacing.hGapSm],
        Expanded(child: field),
        if (widget.suffix != null) ...[AppSpacing.hGapSm, widget.suffix!],
      ],
    );

    // Chromeless fields hand the box to the host surface — no fill, underline,
    // outline, or padding of our own.
    Widget box = widget.chromeless
        ? row
        : Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(bottom: BorderSide(color: underlineColor)),
            ),
            foregroundDecoration: BoxDecoration(
              border: Border.all(color: outlineColor, width: 2),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 12,
                vertical: widget.size == CcTextFieldSize.sm ? 6 : 10,
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

    // Field anatomy: an optional persistent label above the box and a
    // helper or error message below. When none are supplied the field renders
    // as the bare box (backward compatible).
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
