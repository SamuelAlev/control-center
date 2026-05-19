import 'dart:convert';

import 'package:control_center/features/vscode_theme/domain/vscode_editor_theme.dart';
import 'package:flutter/widgets.dart';

/// Thrown when a string is not a parseable VS Code theme.
class VsCodeThemeFormatException implements Exception {
  /// Creates a [VsCodeThemeFormatException].
  const VsCodeThemeFormatException(this.message);

  /// What went wrong.
  final String message;

  @override
  String toString() => 'VsCodeThemeFormatException: $message';
}

/// Parses a VS Code color theme (the JSON shape used by `*-color-theme.json`)
/// into a compact [VsCodeEditorTheme]. Throws [VsCodeThemeFormatException] on
/// invalid JSON or a non-object root.
///
/// Reads the `colors` workbench map for editor/diff/gutter roles and folds the
/// `tokenColors` TextMate rules into a small syntax map. Tolerates the common
/// variations (`type` vs inferred brightness, `#rgb`/`#rrggbb`/`#rrggbbaa`,
/// scopes as a string or a list) and falls back to sensible defaults so a
/// partial theme still imports.
VsCodeEditorTheme parseVsCodeTheme(String jsonString) {
  final Object? decoded;
  try {
    decoded = jsonDecode(jsonString);
  } catch (e) {
    throw VsCodeThemeFormatException('not valid JSON: $e');
  }
  if (decoded is! Map<String, dynamic>) {
    throw const VsCodeThemeFormatException('root is not a JSON object');
  }
  return vsCodeThemeFromMap(decoded);
}

/// Builds a [VsCodeEditorTheme] from an already-decoded VS Code theme map.
VsCodeEditorTheme vsCodeThemeFromMap(Map<String, dynamic> map) {
  final colors = (map['colors'] as Map?)?.cast<String, dynamic>() ?? const {};
  final background =
      _color(colors['editor.background']) ?? const Color(0xFF1E1E1E);
  final foreground =
      _color(colors['editor.foreground']) ?? const Color(0xFFD4D4D4);
  final brightness = _brightness(map['type'], background);

  return VsCodeEditorTheme(
    name: (map['name'] as String?)?.trim().isNotEmpty == true
        ? map['name'] as String
        : 'Imported theme',
    brightness: brightness,
    background: background,
    foreground: foreground,
    lineNumber:
        _color(colors['editorLineNumber.foreground']) ??
        foreground.withValues(alpha: 0.45),
    addedBackground:
        _color(colors['diffEditor.insertedTextBackground']) ??
        _color(colors['diffEditor.insertedLineBackground']) ??
        (brightness == Brightness.dark
            ? const Color(0x3322863A)
            : const Color(0x2222863A)),
    removedBackground:
        _color(colors['diffEditor.removedTextBackground']) ??
        _color(colors['diffEditor.removedLineBackground']) ??
        (brightness == Brightness.dark
            ? const Color(0x33F85149)
            : const Color(0x22F85149)),
    selection:
        _color(colors['editor.selectionBackground']) ??
        foreground.withValues(alpha: 0.15),
    syntax: _syntax(map['tokenColors']),
  );
}

/// VS Code TextMate scope → CC syntax role.
const Map<String, String> _scopeRoles = {
  'keyword': 'keyword',
  'storage': 'keyword',
  'string': 'string',
  'comment': 'comment',
  'entity.name.function': 'function',
  'support.function': 'function',
  'constant.numeric': 'number',
  'entity.name.type': 'type',
  'support.type': 'type',
};

Map<String, Color> _syntax(Object? tokenColors) {
  if (tokenColors is! List) {
    return const {};
  }
  final out = <String, Color>{};
  for (final entry in tokenColors) {
    if (entry is! Map) {
      continue;
    }
    final settings = (entry['settings'] as Map?)?.cast<String, dynamic>();
    final color = _color(settings?['foreground']);
    if (color == null) {
      continue;
    }
    for (final scope in _scopes(entry['scope'])) {
      for (final mapping in _scopeRoles.entries) {
        if (scope.startsWith(mapping.key)) {
          out.putIfAbsent(mapping.value, () => color);
        }
      }
    }
  }
  return out;
}

Iterable<String> _scopes(Object? scope) {
  if (scope is String) {
    return scope.split(',').map((s) => s.trim());
  }
  if (scope is List) {
    return scope.whereType<String>();
  }
  return const [];
}

Brightness _brightness(Object? type, Color background) {
  if (type is String) {
    if (type.toLowerCase() == 'light') {
      return Brightness.light;
    }
    if (type.toLowerCase() == 'dark') {
      return Brightness.dark;
    }
  }
  // Infer from luminance when `type` is absent.
  return background.computeLuminance() > 0.5
      ? Brightness.light
      : Brightness.dark;
}

/// Parses a `#rgb`, `#rrggbb`, or `#rrggbbaa` hex string into a [Color].
Color? _color(Object? value) {
  if (value is! String) {
    return null;
  }
  var hex = value.trim();
  if (!hex.startsWith('#')) {
    return null;
  }
  hex = hex.substring(1);
  if (hex.length == 3) {
    hex = hex.split('').map((c) => '$c$c').join();
  }
  if (hex.length == 6) {
    final rgb = int.tryParse(hex, radix: 16);
    return rgb == null ? null : Color(0xFF000000 | rgb);
  }
  if (hex.length == 8) {
    // VS Code uses #RRGGBBAA; Flutter's Color is 0xAARRGGBB.
    final rgba = int.tryParse(hex, radix: 16);
    if (rgba == null) {
      return null;
    }
    final a = rgba & 0xFF;
    final rgb = (rgba >> 8) & 0xFFFFFF;
    return Color((a << 24) | rgb);
  }
  return null;
}
