import 'dart:async';

import 'package:cc_domain/features/presence/domain/value_objects/participant_presence.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A space's active take-over of its worktree (PRD 16 §8), or the absence
/// of one. Explicit take-over: (1) pauses the agent at a turn boundary, (2)
/// snapshots the worktree, (3) hands the human the code-server editor on the
/// SAME worktree, (4) hand-back posts a diff summary the agent re-reads.
class SpaceTakeover {
  /// Creates a [SpaceTakeover].
  const SpaceTakeover({
    required this.userId,
    required this.displayName,
    required this.since,
    required this.pausedRunIds,
    required this.stoppedRunIds,
  });

  /// Parses a `takeover` wire map (from `begin`/`status`/`watch`).
  factory SpaceTakeover.fromWire(Map<String, dynamic> wire) => SpaceTakeover(
    userId: wire['user_id'] as String? ?? '',
    displayName: wire['display_name'] as String? ?? '',
    since: DateTime.tryParse(wire['since'] as String? ?? ''),
    pausedRunIds: ((wire['paused_run_ids'] as List?) ?? const [])
        .whereType<String>()
        .toList(growable: false),
    stoppedRunIds: ((wire['stopped_run_ids'] as List?) ?? const [])
        .whereType<String>()
        .toList(growable: false),
  );

  /// The user id holding the take-over.
  final String userId;

  /// Display name of the holder (for the banner text).
  final String displayName;

  /// When the take-over began.
  final DateTime? since;

  /// Agent run ids paused at a turn boundary by this take-over.
  final List<String> pausedRunIds;

  /// Agent run ids stopped outright by this take-over.
  final List<String> stoppedRunIds;
}

/// Per-space take-over status, live from `takeover.watch` — watched by the
/// header's take-over button and the conversation pane's take-over banner.
/// The server re-emits whenever the marker is claimed or cleared, by anyone,
/// so no client polls and a hand-back shows up at once on every surface.
final takeoverStatusProvider = StreamProvider.autoDispose
    .family<SpaceTakeover?, String>(
      (ref, spaceId) => ref
          .watch(rpcClientProvider)
          .subscribe('takeover.watch', {'space_id': spaceId})
          .map((data) {
            final raw = data['takeover'];
            return raw is Map
                ? SpaceTakeover.fromWire(raw.cast<String, dynamic>())
                : null;
          }),
    );

/// Begins a take-over of [spaceId]'s worktree via `takeover.begin`. Throws
/// [RemoteRpcException] on failure (e.g. already taken over by someone else)
/// — the caller surfaces `e.message`.
Future<void> beginSpaceTakeover(RemoteRpcClient rpcClient, String spaceId) {
  return rpcClient.call('takeover.begin', {'space_id': spaceId});
}

/// Hands [spaceId]'s worktree back via `takeover.handBack`, with an
/// optional [note] the agent's next turn re-reads. Throws [RemoteRpcException]
/// on failure.
Future<void> handBackSpaceTakeover(
  RemoteRpcClient rpcClient,
  String spaceId, {
  String? note,
}) {
  final trimmed = note?.trim();
  final cleanNote = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  return rpcClient.call('takeover.handBack', {
    'space_id': spaceId,
    'note': ?cleanNote,
  });
}

/// Bumped to ask the messaging IDE layout to open (or focus) the code-server
/// editor tab for a space — used right after a take-over begins so the
/// human lands straight in the shared worktree editor (PRD 16 §8). The layout
/// listens via `ref.listen` and calls its own `openEditor()`.
class CodeServerTabRequestNotifier extends Notifier<int> {
  /// Creates a [CodeServerTabRequestNotifier] scoped to [spaceId].
  CodeServerTabRequestNotifier(this.spaceId);

  /// The space this request targets.
  final String spaceId;

  @override
  int build() => 0;

  /// Requests that the code-server tab for this space be opened/focused.
  void request() => state++;
}

/// Per-space open-code-server-tab request counter.
final codeServerTabRequestProvider =
    NotifierProvider.family<CodeServerTabRequestNotifier, int, String>(
      CodeServerTabRequestNotifier.new,
    );

/// Reactively keeps this client's `worktree` soft-claim (PRD 16 §14) in sync
/// with whether IT holds the active take-over for the given space id, per
/// the server's own truth (polled via [takeoverStatusProvider]). Watched from
/// the conversation pane's take-over banner.
///
/// Deliberately does NOT release the claim in `ref.onDispose` — Riverpod
/// forbids mutating other providers' state from within lifecycle callbacks
/// (`onDispose` runs under a guard that rejects it) and it would be the wrong
/// fix anyway: the claim represents "I hold the take-over" server-side truth,
/// not "the banner is mounted". Hand-back (or someone else taking over) flips
/// the poll to non-mine and this same listener removes the claim reactively;
/// if the app closes outright, the whole presence entry expires on its own.
final takeoverClaimSyncProvider = Provider.autoDispose.family<void, String>((
  ref,
  spaceId,
) {
  ref.listen<AsyncValue<SpaceTakeover?>>(takeoverStatusProvider(spaceId), (
    previous,
    next,
  ) {
    final info = next.value;
    final myUserId = ref.read(currentUserIdProvider);
    final isMine = info != null && myUserId != null && info.userId == myUserId;
    final myPresence = ref.read(myPresenceProvider.notifier);
    if (isMine) {
      myPresence.addClaim(SoftClaim(entityType: 'worktree', entityId: spaceId));
    } else {
      myPresence.removeClaim(entityType: 'worktree', entityId: spaceId);
    }
  }, fireImmediately: true);
});
