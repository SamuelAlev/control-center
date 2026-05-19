import 'dart:async';

import 'package:cc_rpc/cc_rpc.dart' show RemoteChannelState;
import 'package:control_center/core/offline/offline_mutation_queue.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Persists the offline queue through the app's key-value store (localStorage
/// on web, native prefs on desktop), so queued mutations survive a reload.
class _PrefsQueueStore implements OfflineQueueStore {
  _PrefsQueueStore(this._prefs);

  final AppPreferences _prefs;
  static const _key = 'offline_mutation_queue';

  @override
  String? load() => _prefs.getString(_key);

  @override
  void save(String? json) {
    // AppPreferences.setString is async but effectively synchronous on the
    // localStorage/prefs backends; fire-and-forget keeps the queue's sync API.
    unawaited(_prefs.setString(_key, json ?? ''));
  }
}

/// The app's offline mutation queue (PRD 19 §11).
final offlineMutationQueueProvider = Provider<OfflineMutationQueue>((ref) {
  return OfflineMutationQueue(
    store: _PrefsQueueStore(ref.watch(appPreferencesProvider)),
  );
});

/// The live transport state — re-subscribes to the new client on reconnect
/// (the client does not reconnect in place; a reconnect swaps `rpcClientProvider`).
final rpcConnectionStateProvider = StreamProvider<RemoteChannelState>(
  (ref) => ref.watch(rpcClientProvider).connectionState,
);

/// Whether the client is currently connected (drives the offline pill).
final isOnlineProvider = Provider<bool>((ref) {
  final state = ref.watch(rpcConnectionStateProvider).value;
  // Before the first emission, trust the client's current flag.
  return state == null
      ? ref.watch(rpcClientProvider).isOpen
      : state == RemoteChannelState.open;
});

/// Owns the offline queue's lifecycle: drains it (FIFO, idempotent) whenever
/// the connection opens, and exposes the pending count for the pill + an
/// [enqueue] the mutation layer calls while disconnected.
class OfflineQueueController extends Notifier<int> {
  @override
  int build() {
    final queue = ref.watch(offlineMutationQueueProvider);
    // Drain on every (re)connect: a fresh `open` emission means the transport
    // is live again, so the backlog can flush deterministically.
    ref.listen(rpcConnectionStateProvider, (_, next) {
      if (next.value == RemoteChannelState.open && queue.isNotEmpty) {
        unawaited(drainNow());
      }
    });
    // Also flush anything already pending if we build while connected.
    if (ref.read(rpcClientProvider).isOpen && queue.isNotEmpty) {
      Future.microtask(drainNow);
    }
    return queue.length;
  }

  /// Enqueues a mutation to apply on reconnect. Throws
  /// [OfflineQueueFullException] past the caps (the caller surfaces it — never
  /// a silent drop).
  QueuedMutation enqueue({
    required String idempotencyKey,
    required String op,
    required Map<String, dynamic> args,
  }) {
    final queue = ref.read(offlineMutationQueueProvider);
    final mutation = queue.enqueue(
      idempotencyKey: idempotencyKey,
      op: op,
      args: args,
    );
    state = queue.length;
    return mutation;
  }

  /// Flushes the queue over the live connection now. Idempotent + FIFO; each
  /// entry carries its original key so a mid-flush disconnect re-flushes with
  /// no duplicates (server write-ledger dedupe).
  Future<void> drainNow() async {
    final queue = ref.read(offlineMutationQueueProvider);
    final client = ref.read(rpcClientProvider);
    await queue.flush(
      (m) => client.callResult(m.op, m.args, idempotencyKey: m.idempotencyKey),
    );
    state = queue.length;
  }
}

/// The pending-mutation count (0 when the queue is empty).
final offlineQueueControllerProvider =
    NotifierProvider<OfflineQueueController, int>(OfflineQueueController.new);
