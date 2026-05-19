import 'dart:async';

import 'package:cc_domain/features/presence/domain/value_objects/participant_presence.dart';
import 'package:cc_rpc/cc_rpc.dart';
import 'package:control_center/core/providers/rpc_client_provider.dart';
import 'package:control_center/features/identity/providers/identity_providers.dart';
import 'package:control_center/features/presence/providers/presence_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A channel's active take-over of its worktree (PRD 16 §8), or the absence
/// of one. Explicit take-over: (1) pauses the agent at a turn boundary, (2)
/// snapshots the worktree, (3) hands the human the code-server editor on the
/// SAME worktree, (4) hand-back posts a diff summary the agent re-reads.
class ChannelTakeover {
  /// Creates a [ChannelTakeover].
  const ChannelTakeover({
    required this.userId,
    required this.displayName,
    required this.since,
    required this.pausedRunIds,
    required this.stoppedRunIds,
  });

  /// Parses a `takeover` wire map (from `begin`/`status`).
  factory ChannelTakeover.fromWire(Map<String, dynamic> wire) =>
      ChannelTakeover(
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

/// Poll cadence for [TakeoverStatusNotifier] — no server subscription exists
/// for take-over state (PRD 16 §8), so the header button and conversation
/// banner poll while mounted.
const Duration takeoverPollInterval = Duration(seconds: 15);

/// Polls `takeover.status` for one channel every [takeoverPollInterval] while
/// watched, auto-disposing (and cancelling its timer) once unwatched.
class TakeoverStatusNotifier extends AsyncNotifier<ChannelTakeover?> {
  /// Creates a [TakeoverStatusNotifier] scoped to [channelId].
  TakeoverStatusNotifier(this.channelId);

  /// The channel this status tracks.
  final String channelId;

  Timer? _timer;

  @override
  Future<ChannelTakeover?> build() async {
    ref.onDispose(() {
      _timer?.cancel();
      _timer = null;
    });
    _timer = Timer.periodic(takeoverPollInterval, (_) => _refreshSilent());
    return _fetch();
  }

  Future<ChannelTakeover?> _fetch() async {
    final data = await ref.read(rpcClientProvider).call('takeover.status', {
      'channel_id': channelId,
    });
    final raw = data['takeover'];
    if (raw is! Map) {
      return null;
    }
    return ChannelTakeover.fromWire(raw.cast<String, dynamic>());
  }

  /// Force-refreshes — called right after a begin/hand-back action so the UI
  /// doesn't wait out the poll interval.
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(_fetch);
  }

  Future<void> _refreshSilent() async {
    final next = await AsyncValue.guard(_fetch);
    if (next.hasValue) {
      state = next;
    }
  }
}

/// Per-channel take-over status — watched by the header's take-over button
/// and the conversation pane's take-over banner.
final takeoverStatusProvider = AsyncNotifierProvider.family
    .autoDispose<TakeoverStatusNotifier, ChannelTakeover?, String>(
      TakeoverStatusNotifier.new,
    );

/// Begins a take-over of [channelId]'s worktree via `takeover.begin`. Throws
/// [RemoteRpcException] on failure (e.g. already taken over by someone else)
/// — the caller surfaces `e.message`.
Future<void> beginChannelTakeover(RemoteRpcClient rpcClient, String channelId) {
  return rpcClient.call('takeover.begin', {'channel_id': channelId});
}

/// Hands [channelId]'s worktree back via `takeover.handBack`, with an
/// optional [note] the agent's next turn re-reads. Throws [RemoteRpcException]
/// on failure.
Future<void> handBackChannelTakeover(
  RemoteRpcClient rpcClient,
  String channelId, {
  String? note,
}) {
  final trimmed = note?.trim();
  final cleanNote = (trimmed == null || trimmed.isEmpty) ? null : trimmed;
  return rpcClient.call('takeover.handBack', {
    'channel_id': channelId,
    'note': ?cleanNote,
  });
}

/// Bumped to ask the messaging IDE layout to open (or focus) the code-server
/// editor tab for a channel — used right after a take-over begins so the
/// human lands straight in the shared worktree editor (PRD 16 §8). The layout
/// listens via `ref.listen` and calls its own `openEditor()`.
class OpenCodeServerTabRequestNotifier extends Notifier<int> {
  /// Creates an [OpenCodeServerTabRequestNotifier] scoped to [channelId].
  OpenCodeServerTabRequestNotifier(this.channelId);

  /// The channel this request targets.
  final String channelId;

  @override
  int build() => 0;

  /// Requests that the code-server tab for this channel be opened/focused.
  void request() => state++;
}

/// Per-channel open-code-server-tab request counter.
final openCodeServerTabRequestProvider =
    NotifierProvider.family<OpenCodeServerTabRequestNotifier, int, String>(
      OpenCodeServerTabRequestNotifier.new,
    );

/// Reactively keeps this client's `worktree` soft-claim (PRD 16 §14) in sync
/// with whether IT holds the active take-over for the given channel id, per
/// the server's own truth (polled via [takeoverStatusProvider]). Watched from
/// the conversation pane's take-over banner.
///
/// Deliberately does NOT release the claim in `ref.onDispose` — Riverpod
/// forbids mutating other providers' state from within lifecycle callbacks
/// (`onDispose` runs under a guard that rejects it), and it would be the wrong
/// fix anyway: the claim represents "I hold the take-over" server-side truth,
/// not "the banner is mounted". Hand-back (or someone else taking over) flips
/// the poll to non-mine and this same listener removes the claim reactively;
/// if the app closes outright, the whole presence entry expires on its own.
final takeoverClaimSyncProvider = Provider.autoDispose.family<void, String>((
  ref,
  channelId,
) {
  ref.listen<AsyncValue<ChannelTakeover?>>(takeoverStatusProvider(channelId), (
    previous,
    next,
  ) {
    final info = next.value;
    final myUserId = ref.read(currentUserIdProvider);
    final isMine = info != null && myUserId != null && info.userId == myUserId;
    final myPresence = ref.read(myPresenceProvider.notifier);
    if (isMine) {
      myPresence.addClaim(
        SoftClaim(entityType: 'worktree', entityId: channelId),
      );
    } else {
      myPresence.removeClaim(entityType: 'worktree', entityId: channelId);
    }
  }, fireImmediately: true);
});
