import 'dart:async';

import 'package:cc_domain/cc_domain.dart' show RpcErrorCodes;
import 'package:cc_rpc/cc_rpc.dart' show RemoteChannelState, RemoteRpcException;
import 'package:control_center/core/offline/offline_mutation_queue.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/core/providers/storage_providers.dart';
import 'package:control_center/core/utils/app_log.dart';
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
  Future<void> save(String? json) => _prefs.setString(_key, json ?? '');
}

/// Whether a flush error means "the server answered and refused" — retrying the
/// identical frame can never succeed, so the entry is dead-lettered instead of
/// blocking every later mutation behind it. Anything else (transport closed,
/// rate limit, internal error) is transient and keeps its place in the queue.
bool isPermanentFlushFailure(Object error) {
  if (error is! RemoteRpcException) {
    return false; // Transport/unknown: assume we can try again.
  }
  return switch (error.code) {
    RpcErrorCodes.validation ||
    RpcErrorCodes.opUnknown ||
    RpcErrorCodes.opVersionUnsupported ||
    RpcErrorCodes.unauthorized ||
    RpcErrorCodes.workspaceMismatch ||
    RpcErrorCodes.notFound ||
    RpcErrorCodes.invalidParams ||
    RpcErrorCodes.methodNotFound => true,
    _ => false,
  };
}

/// The app's offline mutation queue (PRD 19 §11).
final offlineMutationQueueProvider = Provider<OfflineMutationQueue>((ref) {
  return OfflineMutationQueue(
    store: _PrefsQueueStore(ref.watch(appPreferencesProvider)),
    isPermanentFailure: isPermanentFlushFailure,
    onDeadLetter: (dropped) {
      // Never silent: a dropped mutation is the one thing this module promises
      // not to do quietly. The controller also surfaces it to the operator.
      AppLog.e(
        'OfflineQueue',
        'dropped queued mutation ${dropped.mutation.op} '
            '(${dropped.permanent ? 'rejected by server' : 'retry budget exhausted'})',
        dropped.error,
      );
    },
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
/// the connection opens and exposes the pending count for the pill + an
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
  /// a silent drop). Completes once the entry has actually been persisted, so
  /// "queued" means durable rather than scheduled-to-be-written.
  Future<QueuedMutation> enqueue({
    required String idempotencyKey,
    required String op,
    required Map<String, dynamic> args,
  }) async {
    final queue = ref.read(offlineMutationQueueProvider);
    final mutation = queue.enqueue(
      idempotencyKey: idempotencyKey,
      op: op,
      args: args,
    );
    state = queue.length;
    await queue.persisted;
    return mutation;
  }

  /// Mutations the queue gave up on (server rejection or exhausted retries),
  /// most recent last. Surfaced so the operator learns a change was lost
  /// instead of watching a pending count that never moves.
  List<DeadLetteredMutation> get dropped =>
      ref.read(offlineMutationQueueProvider).deadLettered;

  /// Flushes the queue over the live connection now. Idempotent + FIFO; each
  /// entry carries its original key so a mid-flush disconnect re-flushes with
  /// no duplicates (server write-ledger dedupe). Concurrent calls (the
  /// reconnect listener, the build-time microtask) are serialized by the queue.
  Future<void> drainNow() async {
    final queue = ref.read(offlineMutationQueueProvider);
    final client = ref.read(rpcClientProvider);
    try {
      await queue.flush(
        (m) =>
            client.callResult(m.op, m.args, idempotencyKey: m.idempotencyKey),
      );
    } on Object catch (e, st) {
      // The queue itself never throws for a per-entry failure; anything here is
      // a drain-level fault worth a line rather than a silent stall.
      AppLog.e('OfflineQueue', 'drain failed', e, st);
    }
    state = queue.length;
  }
}

/// The pending-mutation count (0 when the queue is empty).
final offlineQueueControllerProvider =
    NotifierProvider<OfflineQueueController, int>(OfflineQueueController.new);
