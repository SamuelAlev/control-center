import 'package:cc_data/cc_data.dart';
import 'package:cc_domain/core/domain/entities/ide_editor.dart';
import 'package:control_center/core/constants/app_constants.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter/services.dart' show AssetManifest, rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Materializes a PR's branch into a worktree on the connected `cc_server` and
/// opens it in an editor on the host (`ide.ensureWorktree` /
/// `ide.openPrInEditor` / `ide.detectEditors`). The server owns the checkout
/// and the process launch; the thin client only names the editor.
final prWorktreeRpcProvider = Provider<RemoteIdeRepository>((ref) {
  return RemoteIdeRepository(ref.watch(rpcClientProvider));
});

/// The full editor catalog for the current platform, each flagged
/// [IdeEditor.installed]. Detection runs once and is cached by Riverpod.
final installedEditorsProvider = FutureProvider<List<IdeEditor>>((ref) async {
  return ref.watch(prWorktreeRpcProvider).detectEditors();
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

/// Order used when the user has not chosen an editor. A real editor wins over
/// a terminal; the first installed id in this list is the default.
const List<String> kPreferredIdeIds = [
  'cursor',
  'vscode',
  'zed',
  'windsurf',
  'antigravity',
  'intellij',
  'webstorm',
  'pycharm',
  'sublime',
  'warp',
];

/// The editor "Open in …" should name: the remembered choice when it is
/// installed, otherwise the first [kPreferredIdeIds] entry that is.
IdeEditor? preferredInstalledIde(
  List<IdeEditor> installed,
  String? selectedId,
) {
  if (selectedId != null) {
    for (final editor in installed) {
      if (editor.id == selectedId) {
        return editor;
      }
    }
  }
  for (final id in kPreferredIdeIds) {
    for (final editor in installed) {
      if (editor.id == id) {
        return editor;
      }
    }
  }
  return installed.isEmpty ? null : installed.first;
}

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
