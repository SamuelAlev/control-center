import 'package:control_center/core/constants/keybindings.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

/// Locks the browser-reserved keybinding table (FINDINGS §12.7).
///
/// On web, ⌘/Ctrl + {T, W, N, 1–9} are non-cancelable browser accelerators the
/// page can never observe, so any single-stroke command-modified binding on one
/// of those triggers is DEAD on web (it must be a desktop-only affordance the
/// UI dims on web). This test pins (a) exactly which triggers are reserved and
/// (b) exactly which registry bindings are dead-on-web — so a regression that
/// adds a new dead shortcut, or silently changes the reserved set, fails here
/// and forces a conscious decision.
void main() {
  Keybinding cmdKey(LogicalKeyboardKey key, {bool shift = false}) =>
      Keybinding.key(
        id: 'test',
        category: KeybindingCategory.system,
        scope: 'global',
        key: key,
        cmd: true,
        shift: shift,
      );

  group('browser-reserved trigger table', () {
    const reserved = [
      LogicalKeyboardKey.keyT,
      LogicalKeyboardKey.keyW,
      LogicalKeyboardKey.keyN,
      LogicalKeyboardKey.digit1,
      LogicalKeyboardKey.digit2,
      LogicalKeyboardKey.digit3,
      LogicalKeyboardKey.digit4,
      LogicalKeyboardKey.digit5,
      LogicalKeyboardKey.digit6,
      LogicalKeyboardKey.digit7,
      LogicalKeyboardKey.digit8,
      LogicalKeyboardKey.digit9,
    ];

    // Keys the PAGE can still intercept on web (⌘S/⌘F/⌘K/…) — must NOT be
    // treated as reserved, or we'd wrongly disable working web shortcuts.
    const notReserved = [
      LogicalKeyboardKey.keyK,
      LogicalKeyboardKey.keyF,
      LogicalKeyboardKey.keyS,
      LogicalKeyboardKey.keyB,
      LogicalKeyboardKey.keyR,
      LogicalKeyboardKey.comma,
      LogicalKeyboardKey.bracketLeft,
      LogicalKeyboardKey.digit0,
    ];

    test('exactly {T,W,N,1-9} + command modifier are reserved', () {
      for (final k in reserved) {
        expect(
          cmdKey(k).isReservedInBrowser,
          isTrue,
          reason: '$k must be reserved',
        );
      }
      for (final k in notReserved) {
        expect(
          cmdKey(k).isReservedInBrowser,
          isFalse,
          reason: '$k must NOT be reserved',
        );
      }
    });

    test('a reserved trigger without the command modifier is not reserved', () {
      // Plain "T" (no ⌘) reaches the page fine.
      final plainT = Keybinding.key(
        id: 't',
        category: KeybindingCategory.system,
        scope: 'global',
        key: LogicalKeyboardKey.keyT,
      );
      expect(plainT.isReservedInBrowser, isFalse);
    });

    test('shift+command on a reserved trigger stays reserved (e.g. ⌘⇧T)', () {
      // Chrome's ⌘⇧T (reopen closed tab) is also a browser accelerator.
      expect(
        cmdKey(LogicalKeyboardKey.keyT, shift: true).isReservedInBrowser,
        isTrue,
      );
    });
  });

  group('registry dead-on-web bindings are the known set', () {
    // Every registry binding that can never fire in a browser tab. Each is a
    // deliberate desktop-primary affordance (the settings page dims these on
    // web). Adding a NEW command-modified {T,W,N,1-9} binding changes this set
    // and MUST be a conscious decision — update this list only when you have
    // confirmed the new shortcut is desktop-only and surfaced honestly on web.
    final expected = <String>{
      // ⌘⇧T toggle theme, ⌘⇧W workspace switcher, ⌘⌥1–9 workspace jump.
      'sys.toggle-theme', 'sys.workspace-switcher',
      'sys.workspace-1', 'sys.workspace-2', 'sys.workspace-3',
      'sys.workspace-4', 'sys.workspace-5', 'sys.workspace-6',
      'sys.workspace-7', 'sys.workspace-8', 'sys.workspace-9',
      // ⌘N new space, ⌘T IDE new tab, ⌘W IDE close tab.
      'msg.new-space', 'msg.ide-new-tab', 'msg.ide-close-tab',
      // ⌘W close the active tab in the PR workbench (desktop-only, like the
      // messaging IDE's ⌘W).
      'pr.detail-close-tab',
      // ⌘N new workspace / new agent / add repo.
      'ws.new', 'settings.agents-new', 'settings.repos-add',
    };

    test('all() reserved-in-browser ids match the reviewed set', () {
      final actual = KeybindingRegistry.all
          .where((b) => b.isReservedInBrowser)
          .map((b) => b.id)
          .toSet();
      expect(actual, expected);
    });
  });
}
