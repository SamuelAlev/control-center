import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// One entry of a text field's right-click menu.
enum CcTextMenuAction {
  /// Remove the selection and put it on the clipboard.
  cut,

  /// Put the selection on the clipboard.
  copy,

  /// Insert the clipboard at the caret.
  paste,

  /// Select the whole field.
  selectAll,
}

/// What the host did when asked to show its own text menu.
typedef CcNativeTextMenuResult = ({
  /// Whether the host actually presented a menu. When false the caller owns
  /// the right-click and should present something itself.
  bool shown,

  /// The entry the user chose, or null when they dismissed the menu.
  CcTextMenuAction? action,
});

/// Asks the host platform to present its OWN text context menu.
///
/// Flutter ships `SystemContextMenu` for this, but `isSupported` is
/// `defaultTargetPlatform == iOS` and the `ContextMenu.showSystemContextMenu`
/// channel method exists only in the iOS embedder — on desktop there is no
/// framework path to the platform menu at all. So the runner provides one
/// (`macos/Runner/TextContextMenuBridge.swift`) and this is its Dart end.
///
/// The host never touches the text: it reports which entry was chosen and the
/// caller performs it through the field's own [TextSelectionDelegate], so
/// "what paste means" has exactly one implementation.
///
/// A host with no bridge (the gallery's runner, a test, Windows, Linux)
/// answers [MissingPluginException]; that is remembered, so a fallback menu is
/// asked for once and then chosen immediately on every later right-click.
abstract final class CcNativeTextMenu {
  const CcNativeTextMenu._();

  static const MethodChannel _channel = MethodChannel(
    'com.controlcenter/text_context_menu',
  );

  /// False once a host has proved it carries no bridge.
  static bool _hostAnswers = true;

  /// Platforms whose runner can present the OS text menu. Web is excluded on
  /// purpose — there the OS menu is the BROWSER's, reached by handing
  /// right-click back to it (see `CcBrowserTextMenu`), not over a channel.
  static bool get isAvailable =>
      _hostAnswers && !kIsWeb && defaultTargetPlatform == TargetPlatform.macOS;

  /// Resets the "this host has no bridge" latch. Test-only.
  @visibleForTesting
  static void debugReset() => _hostAnswers = true;

  /// Presents the host's text menu at [position] (global logical pixels)
  /// offering [actions], in that order.
  static Future<CcNativeTextMenuResult> show({
    required Offset position,
    required List<CcTextMenuAction> actions,
  }) async {
    if (!isAvailable || actions.isEmpty) {
      return (shown: false, action: null);
    }
    final String? chosen;
    try {
      chosen = await _channel.invokeMethod<String>('show', <String, Object>{
        'x': position.dx,
        'y': position.dy,
        'actions': <String>[for (final action in actions) action.name],
      });
    } on MissingPluginException {
      _hostAnswers = false;
      return (shown: false, action: null);
    } on PlatformException {
      return (shown: false, action: null);
    }
    for (final action in actions) {
      if (action.name == chosen) {
        return (shown: true, action: action);
      }
    }
    // Tracking ended without a choice — the menu WAS shown, so the caller must
    // not go on to present a second one.
    return (shown: true, action: null);
  }
}

/// The entries a text menu offers for [state], in display order.
///
/// Deliberately not [EditableTextState.cutEnabled] and friends: those branch on
/// `selectionControls is TextSelectionHandleControls`, and every cc_ui field
/// passes `selectionControls: null` (desktop-first, no drag handles), which
/// drops them into the legacy `toolbarOptions` path — Cut and Copy come back
/// true with nothing selected, and Paste comes back false until an
/// asynchronous clipboard probe has reported in, which on the first
/// right-click after launch is exactly the entry the user came for.
List<CcTextMenuAction> ccTextMenuActionsFor(EditableTextState state) {
  final value = state.textEditingValue;
  final field = state.widget;
  final hasSelection = !value.selection.isCollapsed;
  final allSelected =
      value.selection.start == 0 && value.selection.end == value.text.length;

  return <CcTextMenuAction>[
    if (hasSelection && !field.readOnly && !field.obscureText)
      CcTextMenuAction.cut,
    if (hasSelection && !field.obscureText) CcTextMenuAction.copy,
    if (!field.readOnly) CcTextMenuAction.paste,
    if (value.text.isNotEmpty &&
        !allSelected &&
        field.enableInteractiveSelection &&
        !(field.readOnly && field.obscureText))
      CcTextMenuAction.selectAll,
  ];
}

/// Performs [action] on [state], as a toolbar-caused change (which is what
/// makes the field scroll the result into view and drop any open toolbar).
void performCcTextMenuAction(
  EditableTextState state,
  CcTextMenuAction action,
) {
  switch (action) {
    case CcTextMenuAction.cut:
      state.cutSelection(SelectionChangedCause.toolbar);
    case CcTextMenuAction.copy:
      state.copySelection(SelectionChangedCause.toolbar);
    case CcTextMenuAction.paste:
      state.pasteText(SelectionChangedCause.toolbar);
    case CcTextMenuAction.selectAll:
      state.selectAll(SelectionChangedCause.toolbar);
  }
}
