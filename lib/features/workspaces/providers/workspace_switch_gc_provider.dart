import 'dart:async' show unawaited;

import 'package:cc_data/cc_data.dart' show SyncedStore;
import 'package:control_center/core/providers/sync_engine_provider.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/ticketing/providers/ticketing_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reclaims the previous workspace's client-side mirrors on workspace switch.
///
/// The deterministic sync engine keeps one [SyncedStore] per (store,
/// workspace) — a full in-memory row mirror of tickets/channels/messages fed
/// by a live `sync.watch` subscription. Without eviction, every workspace
/// visited in a session stays fully resident (rows + subscription) for the
/// rest of the session. This sink evicts the inactive workspaces' stores and
/// invalidates the providers that consumed their (now completed) streams, so
/// a return visit re-seeds lazily instead of rendering a frozen snapshot.
///
/// A pure side-effect sink kept alive for the app's lifetime by
/// `ControlCenterApp`, mirroring `rpcClientWorkspaceSyncProvider`.
final workspaceSwitchGcProvider = Provider<void>((ref) {
  ref.listen<String?>(activeWorkspaceIdProvider, (prev, next) {
    if (next == null || prev == null || prev == next) {
      return;
    }
    unawaited(ref.read(syncEngineProvider).evictInactive(next));
    // The evicted stores' adopted streams completed on dispose; invalidate
    // their consumers so the previous workspace re-seeds when revisited.
    ref
      ..invalidate(workspaceTicketsProvider(prev))
      ..invalidate(myAssignedTicketsProvider(prev))
      ..invalidate(ticketByIdProvider)
      ..invalidate(workspaceChannelsProvider(prev))
      ..invalidate(channelsProvider);
  });
});
