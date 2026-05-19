import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/features/vscode_theme/domain/vscode_editor_theme.dart';
import 'package:control_center/features/vscode_theme/domain/vscode_theme_importer.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Holds the user's imported VS Code editor theme, or null when none is set
/// (in which case CC's own design-system diff/editor colors are used). Persists
/// the raw theme JSON via [AppPreferences] (non-sensitive).
final vscodeEditorThemeProvider =
    NotifierProvider<VsCodeEditorThemeNotifier, VsCodeEditorTheme?>(
      VsCodeEditorThemeNotifier.new,
    );

/// Notifier backing [vscodeEditorThemeProvider].
class VsCodeEditorThemeNotifier extends Notifier<VsCodeEditorTheme?> {
  late AppPreferences _prefs;

  @override
  VsCodeEditorTheme? build() {
    _prefs = ref.watch(appPreferencesProvider);
    final saved = _prefs.getString(vscodeEditorThemeKey);
    if (saved == null || saved.isEmpty) {
      return null;
    }
    try {
      return parseVsCodeTheme(saved);
    } catch (_) {
      // A corrupt stored theme should not block the app.
      return null;
    }
  }

  /// Imports and persists a VS Code theme from raw [jsonString]. Throws
  /// [VsCodeThemeFormatException] if it cannot be parsed (the caller surfaces
  /// the error; nothing is persisted).
  Future<void> import(String jsonString) async {
    final theme = parseVsCodeTheme(jsonString);
    await _prefs.setString(vscodeEditorThemeKey, jsonString);
    state = theme;
  }

  /// Clears the imported theme, reverting to CC's design-system colors.
  Future<void> clear() async {
    await _prefs.remove(vscodeEditorThemeKey);
    state = null;
  }
}
