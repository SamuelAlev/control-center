import 'dart:io';

import 'package:cc_ui/cc_ui.dart';
import 'package:control_center/core/theme/app_fonts.dart';
import 'package:control_center/core/theme/font_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A compact keyboard shortcut chip that renders modifier keys in a
/// platform-aware style (⌘ / ⌥ / ⇧ / ⌃ on macOS; Ctrl / Alt / Shift on
/// Windows and Linux).
///
/// Use [Kbd.symbol] when you already have a pre-formatted label string:
///
/// ```dart
/// Kbd.symbol(label: 'esc')
/// Kbd.symbol(label: '⌘K')
/// ```
///
/// Use [Kbd.key] when you want the widget to build the label from a
/// [LogicalKeyboardKey] and modifier flags:
///
/// ```dart
/// Kbd.key(key: LogicalKeyboardKey.keyK, meta: true)
/// ```
class Kbd extends ConsumerWidget {
  /// Creates a [Kbd] from a raw label string.
  const Kbd.symbol({
    super.key,
    required this.label,
    this.onTap,
    this.compact = true,
  }) : _key = null,
       _meta = false,
       _control = false,
       _shift = false,
       _alt = false;

  /// Creates a [Kbd] from a [LogicalKeyboardKey] and modifiers. The
  /// displayed label adapts to the current platform automatically.
  const Kbd.key({
    super.key,
    required LogicalKeyboardKey shortcutKey,
    bool meta = false,
    bool control = false,
    bool shift = false,
    bool alt = false,
    this.onTap,
    this.compact = true,
  }) : label = null,
       _key = shortcutKey,
       _meta = meta,
       _control = control,
       _shift = shift,
       _alt = alt;

  /// Pre-formatted label used by [Kbd.symbol].
  final String? label;

  /// Optional tap callback (e.g. for an interactive "press me" hint).
  final VoidCallback? onTap;

  /// When `true` the chip is smaller and more tightly padded — suitable for
  /// inline use inside menus, toolbars and palette rows. When `false` it is
  /// larger and more readable — suitable for the keybindings settings page.
  final bool compact;

  final LogicalKeyboardKey? _key;
  final bool _meta;
  final bool _control;
  final bool _shift;
  final bool _alt;

  static String _keyDisplay(LogicalKeyboardKey key) {
    if (key == LogicalKeyboardKey.escape) {
      return 'Esc';
    }
    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      return '↵';
    }
    if (key == LogicalKeyboardKey.arrowUp) {
      return '↑';
    }
    if (key == LogicalKeyboardKey.arrowDown) {
      return '↓';
    }
    if (key == LogicalKeyboardKey.arrowLeft) {
      return '←';
    }
    if (key == LogicalKeyboardKey.arrowRight) {
      return '→';
    }
    if (key == LogicalKeyboardKey.backspace) {
      return '⌫';
    }
    if (key == LogicalKeyboardKey.delete) {
      return 'Del';
    }
    if (key == LogicalKeyboardKey.tab) {
      return 'Tab';
    }
    if (key == LogicalKeyboardKey.space) {
      return 'Space';
    }
    return key.keyLabel;
  }

  String _buildLabel() {
    if (label != null) {
      return label!;
    }

    final isMac = Platform.isMacOS;
    final parts = <String>[];
    if (_meta || _control) {
      parts.add(isMac ? '⌘' : 'Ctrl');
    }
    if (_alt) {
      parts.add(isMac ? '⌥' : 'Alt');
    }
    if (_shift) {
      parts.add(isMac ? '⇧' : 'Shift');
    }
    parts.add(_keyDisplay(_key!));
    return parts.join(isMac ? '' : '+');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tokens = context.designSystem ?? DesignSystemTokens.light();
    final codeFontFamily = ref.watch(codeFontFamilyProvider);
    final text = _buildLabel();
    final fontSize = compact ? 12.0 : 13.0;
    final hPad = compact ? 6.0 : 8.0;
    final vPad = compact ? 2.0 : 3.0;
    final radius = compact ? 5.0 : 6.0;

    final chip = Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: tokens.bgSecondary,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: tokens.borderSecondary),
      ),
      child: Text(
        text,
        style: AppFonts.codeStyleDynamic(
          codeFontFamily,
          fontSize: fontSize,
          height: 1.3,
          color: tokens.textTertiary,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.4,
        ),
      ),
    );

    if (onTap == null) {
      return chip;
    }

    return CcTappable(
      onPressed: onTap,
      mouseCursor: SystemMouseCursors.click,
      builder: (context, states) => chip,
    );
  }
}
