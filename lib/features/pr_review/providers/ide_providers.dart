import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/entities/ide_editor.dart';
import 'package:cc_domain/core/domain/ports/editor_launcher_port.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/infrastructure/ide/native_editor_launcher.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Materializes a PR's branch into a worktree on the connected `cc_server` over
/// RPC (`ide.ensureWorktree`) and returns its path; the desktop then launches
/// that path in a LOCAL editor via [editorLauncherProvider] (the headless host
/// can't pop a GUI editor). Replaces the old DB-backed in-process worktree port
/// now that the desktop is a thin client. In the self-serve setup the host is
/// the same machine, so the returned path is local and openable directly.
final prWorktreeRpcProvider = Provider<RemoteIdeRepository>((ref) {
  return RemoteIdeRepository(ref.watch(rpcClientProvider));
});

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
/// [AppPreferences]. `null` until the user picks one — callers fall back to
/// a sensible installed default.
class SelectedIdeNotifier extends Notifier<String?> {
  @override
  String? build() {
    return ref.watch(appPreferencesProvider).getString(selectedIdeKey);
  }

  /// Persists the chosen editor id. Pass `null` to clear the preference.
  Future<void> set(String? id) async {
    final prefs = ref.read(appPreferencesProvider);
    if (id == null) {
      await prefs.remove(selectedIdeKey);
    } else {
      await prefs.setString(selectedIdeKey, id);
    }
    state = id;
  }
}

/// Read/write provider for the user's preferred editor id.
final selectedIdeProvider = NotifierProvider<SelectedIdeNotifier, String?>(
  SelectedIdeNotifier.new,
);
