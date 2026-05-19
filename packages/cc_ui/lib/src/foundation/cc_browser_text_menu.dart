import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Hands right-click back to the BROWSER while the pointer is over a focused
/// text field, so the web build gets the browser's own input menu (Cut / Copy /
/// Paste / Undo / spellcheck / everything the platform offers) instead of a
/// drawn imitation.
///
/// Flutter web ships with the browser context menu enabled, and this app turns
/// it off at boot (`bootstrap_web.dart`) for a good reason: with it on, the
/// browser's page menu covers every `showCcMenuAt` menu in the app — space
/// rows, editor tabs, tickets, the explorer — and the engine suppresses
/// Flutter's selection toolbars entirely. So it cannot simply be left on.
///
/// The narrow re-enable is what this is: a claim is held only while the
/// pointer is inside a text field THAT ALSO HAS FOCUS, which is precisely when
/// the engine has a real `<input>`/`<textarea>` positioned over that field for
/// the browser to open its input menu on. Right-click anywhere else and the
/// app's own menus are still in charge.
///
/// Claims are reference-counted by owner, because focus and hover cross over:
/// blurring one field and focusing another arrives as two events in an order
/// nobody controls, and a boolean would flicker the browser menu off in
/// between.
///
/// Off web every member is a no-op — `BrowserContextMenu` asserts `kIsWeb`.
abstract final class CcBrowserTextMenu {
  const CcBrowserTextMenu._();

  static final Set<Object> _claims = <Object>{};
  static bool _enabled = false;

  /// Whether any field currently wants the browser to own right-click.
  @visibleForTesting
  static bool get debugClaimed => _claims.isNotEmpty;

  /// Registers or withdraws [owner]'s claim. Safe to call on every build and
  /// from `dispose`.
  static void claim(Object owner, {required bool wanted}) {
    if (!kIsWeb) {
      return;
    }
    final changed = wanted ? _claims.add(owner) : _claims.remove(owner);
    if (changed) {
      _sync();
    }
  }

  static void _sync() {
    final wanted = _claims.isNotEmpty;
    if (wanted == _enabled) {
      return;
    }
    _enabled = wanted;
    unawaited(
      wanted
          ? BrowserContextMenu.enableContextMenu()
          : BrowserContextMenu.disableContextMenu(),
    );
  }
}
