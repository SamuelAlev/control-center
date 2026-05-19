import 'dart:async';

import 'package:cc_data/cc_data.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Maps each adopted store (PRD 16 §6) to its kill-switch preference key.
///
/// Read by [syncEngineProvider]'s `storeEnabled` and written by the Settings →
/// Advanced → "Sync engine" toggles (`SyncEngineSection`). Keep this map in
/// sync with the stores `ClientSyncEngine.storeFor` recognizes ('tickets',
/// 'messaging', 'notes').
const Map<String, String> syncEngineStoreKeys = {
  'tickets': 'sync_delta_tickets',
  'messaging': 'sync_delta_messaging',
  'notes': 'sync_delta_notes',
};

/// The client half of the deterministic sync engine (PRD 16 §6), built over
/// the single [rpcClientProvider] every `RpcX` repository already shares.
///
/// `storeEnabled` reads each store's kill-switch preference — default TRUE.
/// The OFF position is the pre-PRD-16 full-snapshot behavior; these toggles
/// are an emergency escape hatch, not a staged opt-in, so the engine ships ON.
/// Repositories call `ref.watch(syncEngineProvider).storeFor(store, workspaceId)`
/// and fall back to their legacy snapshot subscription when it returns null
/// (kill-switch OFF, or the store demoted itself after an untrustworthy feed).
///
/// Disposed with the provider, so its live `sync.watch` subscriptions close
/// when the app tears down (or a test's provider container is disposed).
final syncEngineProvider = Provider<ClientSyncEngine>((ref) {
  final prefs = ref.watch(appPreferencesProvider);
  final engine = ClientSyncEngine(
    client: ref.watch(rpcClientProvider),
    storeEnabled: (store) {
      final key = syncEngineStoreKeys[store];
      // An unrecognized store name has no kill-switch — treat it as enabled
      // rather than silently degrading a future store to snapshot mode.
      return key == null || (prefs.getBool(key) ?? true);
    },
  );
  ref.onDispose(() {
    unawaited(engine.dispose());
  });
  return engine;
});
