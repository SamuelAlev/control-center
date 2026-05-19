import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The embedded-editor (code-server) auto-save behaviour, mapped 1:1 onto VS
/// Code's `files.autoSave` values. Seeded into the session's `settings.json` on
/// every open (see `CodeServerService`), so a change applies the next time an
/// editor tab opens.
enum EditorAutoSaveMode {
  /// Never auto-save — the file stays dirty until an explicit save (the per-tab
  /// unsaved-changes dot and the Save/Don't-save close dialog are most relevant
  /// here).
  off('off'),

  /// Auto-save a short delay (~1s) after the last edit. The app default.
  afterDelay('afterDelay'),

  /// Auto-save when the editor loses focus (e.g. switching tabs).
  onFocusChange('onFocusChange');

  const EditorAutoSaveMode(this.wireValue);

  /// The exact `files.autoSave` string written into code-server's settings.
  final String wireValue;

  /// Parses a persisted / wire value back to a mode, defaulting to [afterDelay]
  /// for anything unrecognised (including the legacy null).
  static EditorAutoSaveMode fromWire(String? value) {
    for (final mode in EditorAutoSaveMode.values) {
      if (mode.wireValue == value) {
        return mode;
      }
    }
    return EditorAutoSaveMode.afterDelay;
  }
}

/// The current editor auto-save preference, persisted via [AppPreferences]
/// (non-sensitive, mirrors `themeModeProvider`). Read by the code-server session
/// provider to push `auto_save` on `codeServer.open`.
final editorAutoSaveModeProvider =
    NotifierProvider<EditorAutoSaveNotifier, EditorAutoSaveMode>(
      EditorAutoSaveNotifier.new,
    );

/// Notifier that loads/persists the editor auto-save preference.
class EditorAutoSaveNotifier extends Notifier<EditorAutoSaveMode> {
  late AppPreferences _prefs;

  @override
  EditorAutoSaveMode build() {
    _prefs = ref.watch(appPreferencesProvider);
    return EditorAutoSaveMode.fromWire(_prefs.getString(editorAutoSaveKey));
  }

  /// Sets the auto-save mode and persists it.
  void setMode(EditorAutoSaveMode mode) {
    _prefs.setString(editorAutoSaveKey, mode.wireValue);
    state = mode;
  }
}
