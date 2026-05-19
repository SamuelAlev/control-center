import 'package:cc_ui/src/components/cc_text_context_menu.dart';
import 'package:cc_ui/src/foundation/cc_component_tokens.dart';
import 'package:cc_ui/src/foundation/cc_text_selection_gestures.dart';
import 'package:cc_ui/src/foundation/cc_typography.dart';
import 'package:cc_ui/src/theme/cc_theme.dart';
import 'package:cc_ui/src/tokens/app_spacing.dart';
import 'package:flutter/widgets.dart';

/// The borderless search field pinned at the top of a floating panel — an
/// [EditableText] with a placeholder, no box chrome (the panel's divider below
/// it is the only separation) and pointer selection wired the same way as
/// `CcTextField` (click-drag, double-click word select).
///
/// Shared by every panel that filters as you type (a searchable `CcMenu`, a
/// `CcFilterMenu` flyout) so the two cannot drift into looking like different
/// controls.
///
/// The host owns the keyboard: this widget deliberately installs no key
/// handling of its own, so an ancestor [Focus] can claim Up/Down/Enter/Escape
/// for the row list while the caret stays in the field. That is the whole
/// reason a panel's list runs on an explicit highlight index rather than on
/// focus traversal — focus cannot be in the field and on a row at once.
class CcPanelSearchField extends StatefulWidget {
  /// Creates a [CcPanelSearchField].
  const CcPanelSearchField({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText,
    this.autofocus = false,
    this.onChanged,
  });

  /// The query text being edited.
  final TextEditingController controller;

  /// Focus node for the field; the panel usually autofocuses it.
  final FocusNode focusNode;

  /// Placeholder shown while the query is empty.
  final String? hintText;

  /// Whether the field takes focus as the panel opens.
  final bool autofocus;

  /// Called on every keystroke with the new query.
  final ValueChanged<String>? onChanged;

  @override
  State<CcPanelSearchField> createState() => _CcPanelSearchFieldState();
}

class _CcPanelSearchFieldState extends State<CcPanelSearchField>
    implements TextSelectionGestureDetectorBuilderDelegate {
  @override
  final GlobalKey<EditableTextState> editableTextKey =
      GlobalKey<EditableTextState>();

  @override
  bool get forcePressEnabled => false;

  @override
  bool get selectionEnabled => true;

  late final CcTextSelectionGestureDetectorBuilder _selectionGestureBuilder =
      CcTextSelectionGestureDetectorBuilder(delegate: this);

  @override
  Widget build(BuildContext context) {
    final t = context.ds;
    final input = CcInputTokens.resolve(t);
    final textStyle = DefaultTextStyle.of(
      context,
    ).style.merge(CcTypography.bodySm.copyWith(color: t.textPrimary));

    final editable = EditableText(
      key: editableTextKey,
      controller: widget.controller,
      focusNode: widget.focusNode,
      autofocus: widget.autofocus,
      maxLines: 1,
      minLines: 1,
      keyboardType: TextInputType.text,
      onChanged: widget.onChanged,
      style: textStyle,
      cursorColor: input.cursor,
      backgroundCursorColor: input.placeholder,
      selectionColor: input.selection,
      // Desktop-first: no drag handles; pointer selection comes from the
      // gesture detector below, keyboard selection from default shortcuts.
      selectionControls: null,
      // Right-click menu (cut/copy/paste/select all); also what makes
      // EditableText build a TextSelectionOverlay at all.
      contextMenuBuilder: ccTextContextMenuBuilder,
      rendererIgnoresPointer: true,
      cursorOpacityAnimates: true,
    );

    return _selectionGestureBuilder.buildGestureDetector(
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm + AppSpacing.xxs,
        ),
        child: Stack(
          alignment: Alignment.centerLeft,
          children: [
            // Hint sits behind the editable text while empty.
            if (widget.hintText != null)
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: widget.controller,
                builder: (context, value, _) => value.text.isEmpty
                    ? Text(
                        widget.hintText!,
                        style: CcTypography.bodySm.copyWith(
                          color: input.placeholder,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      )
                    : const SizedBox.shrink(),
              ),
            editable,
          ],
        ),
      ),
    );
  }
}
