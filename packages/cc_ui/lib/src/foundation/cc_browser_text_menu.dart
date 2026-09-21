import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Re-enables the browser input context menu only while the pointer is over a
/// focused text field (web). Global browser menu stays off at boot so it does
/// not cover `showCcMenuAt` / selection toolbars. Claims are reference-counted
/// by owner (focus/hover cross-over must not flicker). Off-web: no-ops.
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
