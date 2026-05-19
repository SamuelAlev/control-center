import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/constants/keybindings.dart';
import 'package:control_center/core/keybindings/keybinding_dispatcher.dart';
import 'package:control_center/core/keybindings/text_undo_shortcuts.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
/// Regression coverage for text-field undo/redo (⌘Z / ⇧⌘Z).
///
/// The app's key pipeline is the [KeybindingDispatcher] (a HardwareKeyboard
/// handler), NOT the focus tree — `DefaultTextEditingShortcuts`' delivery of
/// undo/redo intents does not fire under the native-windowing runtime for keys
/// pressed while a text input connection is live, which killed ⌘Z in every
/// input while typing and IME (text-input channel) kept working. The fix has
/// two halves, pinned here:
///
/// 1. The dispatcher bridges the platform undo/redo strokes to the focused
///    field by invoking the same intents `DefaultTextEditingShortcuts` would
///    have (`_bridgeTextUndoRedo`).
/// 2. A `Shortcuts` inside `MaterialApp.builder` shadows the framework's own
///    undo/redo mappings (`kTextUndoNeutralizerShortcuts`), so wherever the
///    focus tree DOES work the bridge stays the only actor — one keypress,
///    exactly one undo step.
Future<void> _pressUndo(WidgetTester tester, {bool shift = false}) async {
  await tester.sendKeyDownEvent(LogicalKeyboardKey.metaLeft);
  if (shift) {
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
  await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
  if (shift) {
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
  }
  await tester.sendKeyUpEvent(LogicalKeyboardKey.metaLeft);
  await tester.pump();
}

/// Types [first] and [second] as two separate undo batches (the framework's
/// UndoHistory throttles pushes at 500ms; pumping past it between batches
/// guarantees two stack entries).
Future<void> _typeTwoBatches(WidgetTester tester, String first, String second) async {
  await tester.enterText(find.byType(EditableText), first);
  await tester.pump(const Duration(milliseconds: 600));
  await tester.enterText(find.byType(EditableText), second);
  await tester.pump(const Duration(milliseconds: 600));
}

Widget _fieldApp({
  required TextEditingController controller,
  bool neutralizer = false,
}) {
  final field = CcTextField(controller: controller, autofocus: true);
  return CcTheme(
    data: CcThemeData.light(),
    child: MaterialApp(
      // The real app installs the shadow via MaterialApp.builder; mirror that
      // placement (inside WidgetsApp's DefaultTextEditingShortcuts).
      builder:
          neutralizer
              ? (context, child) =>
                  installTextUndoShadow(child ?? const SizedBox.shrink())
              : null,
      home: Material(child: field),
    ),
  );
}

void main() {
  testWidgets('dispatcher bridges ⌘Z/⇧⌘Z to the focused field, exactly one step', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    var appUndoFired = 0;
    final dispatcher = KeybindingDispatcher(
      bindings: KeybindingRegistry.all,
      platform: TargetPlatform.macOS,
    );
    final handle = dispatcher.registerScope({
      'sys.undo': () => appUndoFired++,
      'sys.redo': () => appUndoFired++,
    });
    final controller = TextEditingController();
    await tester.pumpWidget(_fieldApp(controller: controller, neutralizer: true));
    await tester.pump();

    await _typeTwoBatches(tester, 'hello', 'hello world');
    expect(controller.text, 'hello world');

    await _pressUndo(tester);
    expect(controller.text, 'hello', reason: '⌘Z must undo exactly one batch');
    expect(appUndoFired, 0, reason: 'app-level undo must not fire while typing');

    await _pressUndo(tester, shift: true);
    expect(controller.text, 'hello world', reason: '⇧⌘Z must redo exactly one batch');
    expect(appUndoFired, 0);

    handle.dispose();
    dispatcher.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets(
    'undo past the stack floor restores the focus-entry baseline (first word is removable)',
    (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final dispatcher = KeybindingDispatcher(
        bindings: KeybindingRegistry.all,
        platform: TargetPlatform.macOS,
      );
      final controller = TextEditingController();
      await tester.pumpWidget(_fieldApp(controller: controller, neutralizer: true));
      await tester.pump();

      // Type continuously from the moment the field mounts, WITHOUT pumping
      // past the 500ms throttle between mount and the first keystrokes. The
      // framework's UndoHistory then coalesces the empty baseline away — its
      // pending throttled push is overwritten by the typed text — so the
      // stack's lowest entry is the first typed snapshot. The bridge's
      // terminal undo must still reach the empty baseline.
      await tester.enterText(find.byType(EditableText), 'hello world');
      await tester.pump(const Duration(milliseconds: 600));
      await tester.enterText(find.byType(EditableText), 'hello world and more');
      await tester.pump(const Duration(milliseconds: 600));
      expect(controller.text, 'hello world and more');

      await _pressUndo(tester);
      expect(controller.text, 'hello world');
      await _pressUndo(tester);
      // Framework floor: the stack has nothing older than the first snapshot.
      // The bridge falls through to the focus-entry baseline ('').
      expect(
        controller.text,
        '',
        reason: 'the first inputted word must be removable via ⌘Z',
      );

      // Holding ⌘Z must not loop: once the baseline is restored, further
      // presses are no-ops. The loop happened because the restore armed
      // UndoHistory's pending throttled push and the next undo() cancelled it
      // and bounced the text back to the stack top — '' ↔ first word forever.
      await _pressUndo(tester);
      await _pressUndo(tester);
      await _pressUndo(tester);
      expect(controller.text, '', reason: 'held/repeated ⌘Z must stay at the baseline');

      dispatcher.dispose();
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('the shadow alone (no dispatcher) leaves ⌘Z inert — no double undo anywhere', (tester) async {
      debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
      final controller = TextEditingController();
      await tester.pumpWidget(_fieldApp(controller: controller, neutralizer: true));
      await tester.pump();

      await _typeTwoBatches(tester, 'hello', 'hello world');
      await _pressUndo(tester);
      // The shadow mapping consumed the stroke; only the dispatcher's bridge
      // (absent here) performs undo. This is what guarantees no double-undo in
      // runtimes where the focus tree works.
      expect(controller.text, 'hello world');
      debugDefaultTargetPlatformOverride = null;
    },
  );

  testWidgets('stock behaviour is untouched without the neutralizer or dispatcher', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final controller = TextEditingController();
    await tester.pumpWidget(_fieldApp(controller: controller));
    await tester.pump();

    await _typeTwoBatches(tester, 'hello', 'hello world');
    await _pressUndo(tester);
    expect(controller.text, 'hello', reason: 'DefaultTextEditingShortcuts path still works');
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('sys.undo still owns ⌘Z when no field is focused', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    var appUndoFired = 0;
    final dispatcher = KeybindingDispatcher(
      bindings: KeybindingRegistry.all,
      platform: TargetPlatform.macOS,
    );
    final handle = dispatcher.registerScope({
      'sys.undo': () => appUndoFired++,
      'sys.redo': () => appUndoFired++,
    });
    await tester.pumpWidget(
      const MaterialApp(home: Material(child: SizedBox.expand())),
    );
    await tester.pump();
    expect(dispatcher.debugContext['textInputFocus'], isNot(true));

    await _pressUndo(tester);
    expect(appUndoFired, 1, reason: 'app-level undo fires outside text fields');

    handle.dispose();
    dispatcher.dispose();
    debugDefaultTargetPlatformOverride = null;
  });

  testWidgets('non-Apple platforms bridge Ctrl+Z / Ctrl+Shift+Z', (tester) async {
    debugDefaultTargetPlatformOverride = TargetPlatform.linux;
    final dispatcher = KeybindingDispatcher(
      bindings: KeybindingRegistry.all,
      platform: TargetPlatform.linux,
    );
    final controller = TextEditingController();
    await tester.pumpWidget(_fieldApp(controller: controller, neutralizer: true));
    await tester.pump();

    await _typeTwoBatches(tester, 'hello', 'hello world');
    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(controller.text, 'hello', reason: 'Ctrl+Z must undo on Linux/Windows');

    await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyDownEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.keyZ);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.shiftLeft);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);
    await tester.pump();
    expect(controller.text, 'hello world', reason: 'Ctrl+Shift+Z must redo');
    dispatcher.dispose();
    debugDefaultTargetPlatformOverride = null;
  });
}
