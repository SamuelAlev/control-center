import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/domain/entities/ide_editor.dart';
import 'package:control_center/core/domain/ports/editor_launcher_port.dart';
import 'package:control_center/core/infrastructure/ide/native_editor_launcher.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;

// The PR worktree provider is wired in the composition root (it depends on the
// filesystem/isolation/registry/token providers); re-exported here so the
// "open in editor" widget reads it alongside the editor providers.
export 'package:control_center/di/providers.dart' show prWorktreePortProvider;

/// Binds the [EditorLauncherPort] to its native, `dart:io`-backed adapter.
final editorLauncherProvider = Provider<EditorLauncherPort>((ref) {
  return NativeEditorLauncher();
});

/// The full editor catalog for the current platform, each flagged
/// [IdeEditor.installed]. Detection runs once and is cached by Riverpod.
final installedEditorsProvider = FutureProvider<List<IdeEditor>>((ref) async {
  return ref.watch(editorLauncherProvider).detectEditors();
});

/// The bundled IDE brand-logo asset paths under `assets/ide_logos/`, read from
/// the asset manifest once (cached by Riverpod). Lets the "open in editor"
/// widget render whichever format ships for a given editor — a vector `.svg`
/// (preferred) or a raster `.png` — without hard-coding the extension per id.
final ideLogoAssetsProvider = FutureProvider<Set<String>>((ref) async {
  final manifest = await AssetManifest.loadFromAssetBundle(rootBundle);
  return {
    for (final asset in manifest.listAssets())
      if (asset.startsWith('assets/ide_logos/')) asset,
  };
});

/// The id of the editor the user last chose for "open in editor", persisted in
/// [SharedPreferences]. `null` until the user picks one — callers fall back to
/// a sensible installed default.
class SelectedIdeNotifier extends Notifier<String?> {
  @override
  String? build() {
    return ref.watch(sharedPreferencesProvider).getString(selectedIdeKey);
  }

  /// Persists the chosen editor id. Pass `null` to clear the preference.
  Future<void> set(String? id) async {
    final prefs = ref.read(sharedPreferencesProvider);
    if (id == null) {
      await prefs.remove(selectedIdeKey);
    } else {
      await prefs.setString(selectedIdeKey, id);
    }
    state = id;
  }
}

/// Read/write provider for the user's preferred editor id.
final selectedIdeProvider =
    NotifierProvider<SelectedIdeNotifier, String?>(SelectedIdeNotifier.new);
