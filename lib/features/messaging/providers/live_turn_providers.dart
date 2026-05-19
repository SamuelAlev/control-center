import 'dart:async';
import 'dart:collection';

import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update_codec.dart';
import 'package:control_center/di/providers.dart';
import 'package:control_center/features/messaging/providers/messaging_providers.dart';
import 'package:control_center/features/workspaces/providers/workspace_scope.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Bounded LRU of finalized transcripts, keyed by message id.
///
/// Finalized transcripts are immutable, so a hit is correct forever; the cap
/// only bounds memory. List watch emissions ship messages WITHOUT their
/// `segments` payload (`segments_elided`), so this cache — seeded by the live
/// relay on turn finish and backfilled by [messageTranscriptProvider] — is
/// where agent-turn bubbles get their transcript from.
class TranscriptLruCache {
  /// Creates a cache holding at most [capacity] transcripts.
  TranscriptLruCache({this.capacity = 256});

  /// Maximum number of cached transcripts.
  final int capacity;

  final LinkedHashMap<String, List<TranscriptSegment>> _entries =
      LinkedHashMap();

  /// The cached transcript for [messageId], or null. Refreshes LRU order.
  List<TranscriptSegment>? get(String messageId) {
    final hit = _entries.remove(messageId);
    if (hit == null) {
      return null;
    }
    _entries[messageId] = hit;
    return hit;
  }

  /// Stores [segments] for [messageId], evicting the least-recently used
  /// entry beyond [capacity].
  void put(String messageId, List<TranscriptSegment> segments) {
    _entries.remove(messageId);
    _entries[messageId] = List<TranscriptSegment>.unmodifiable(segments);
    while (_entries.length > capacity) {
      _entries.remove(_entries.keys.first);
    }
  }
}

/// Process-lifetime transcript cache shared by the relay fold and the
/// per-message fetch provider.
final transcriptCacheProvider = Provider<TranscriptLruCache>(
  (_) => TranscriptLruCache(),
);

/// The finalized transcript of one agent-turn message.
///
/// Cache-first: a hit (seeded by the relay on turn finish, or a previous
/// fetch) resolves synchronously; a miss pulls the full message once via
/// `messaging.getMessageById` (the only surface that still carries
/// `segments`). Live turns never come through here — the bubble reads the
/// active-stream registry while `isActive`.
final messageTranscriptProvider = FutureProvider.autoDispose
    .family<List<TranscriptSegment>, String>((ref, messageId) async {
      final cache = ref.watch(transcriptCacheProvider);
      final hit = cache.get(messageId);
      if (hit != null) {
        return hit;
      }
      final message = await ref
          .watch(messagingRepositoryProvider)
          .getMessageById(ref.requireWorkspaceId(), messageId);
      final segments = message?.transcript ?? const <TranscriptSegment>[];
      cache.put(messageId, segments);
      return segments;
    });

/// Live turn relay fold for one space.
///
/// Watched by the conversation feed while it is visible: subscribes to
/// `messaging.watchSpaceTurns` and folds the seed + update frames into the
/// client-side `ActiveStreamRegistry` — the same registry the agent-turn
/// bubbles already render from. On `TurnFinished` the final snapshot is
/// copied into [transcriptCacheProvider] BEFORE unregistering, so the bubble
/// never flashes empty between the live stream ending and the (lite) list
/// row landing.
///
/// Disposal (feed hidden/closed) cancels the RPC subscription and drops the
/// turns this fold registered; a later re-watch re-seeds from the server
/// snapshot, which is also the reconnect story.
final spaceTurnRelayProvider = Provider.autoDispose.family<void, String>((
  ref,
  spaceId,
) {
  final registry = ref.watch(activeStreamRegistryProvider);
  final relay = ref.watch(spaceTurnRelayPortProvider);
  final cache = ref.watch(transcriptCacheProvider);

  // Turns THIS fold registered (owned): dropped on dispose/re-seed.
  final live = <String>{};

  void finish(String messageId) {
    final snapshot = registry.snapshot(messageId);
    // Only cache a snapshot that actually carries segments. A turn whose only
    // relayed frame is `TurnFinished` (adopted on that frame, so its snapshot is
    // a non-null EMPTY list) would otherwise poison the LRU with `[]` — and
    // because the bubble treats any cache hit as authoritative, the real
    // transcript could never be fetched for the rest of the process. That is how
    // an error-only turn rendered permanently blank.
    if (snapshot != null && snapshot.isNotEmpty) {
      cache.put(messageId, snapshot);
    }
    live.remove(messageId);
    unawaited(registry.unregister(messageId));
  }

  final sub = relay.watchSpaceTurns(spaceId).listen((event) {
    switch (event) {
      case TurnRelaySeed(:final turns):
        // Reconnect reconciliation: the seed is authoritative. Drop owned
        // turns that are no longer active (their final row arrives via the
        // list watch), re-seed the rest with the full server snapshot.
        final seeded = {for (final t in turns) t.messageId};
        for (final id in live.toList()) {
          if (!seeded.contains(id)) {
            live.remove(id);
            unawaited(registry.unregister(id));
          }
        }
        for (final t in turns) {
          if (registry.isActive(t.messageId)) {
            unawaited(registry.unregister(t.messageId));
          }
          registry.seed(t.messageId, t.segments, spaceId: spaceId);
          live.add(t.messageId);
        }
      case TurnRelayUpdates(:final messageId, :final updates):
        for (final update in updates) {
          if (!registry.isActive(messageId)) {
            // A turn that opened mid-subscription: adopt it on first update.
            registry.register(messageId, spaceId: spaceId);
            live.add(messageId);
          }
          registry.apply(messageId, update);
          if (update is TurnFinished) {
            finish(messageId);
          }
        }
    }
  });

  ref.onDispose(() {
    unawaited(sub.cancel());
    for (final id in live) {
      unawaited(registry.unregister(id));
    }
  });
});
