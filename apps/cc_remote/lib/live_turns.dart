import 'dart:async';

import 'package:cc_domain/cc_domain.dart';
import 'package:cc_domain/core/domain/services/active_stream_registry.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_segment.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update.dart';
import 'package:cc_domain/core/domain/value_objects/transcript_update_codec.dart';

/// How many finished transcripts to keep after their turn leaves the relay.
const int _maxFinished = 32;

/// Character budget for [_maxFinished]. One transcript larger than the budget
/// is kept alone; the next one replaces it.
const int _maxFinishedChars = 512 * 1024;

/// Folds `messaging.watchSpaceTurns` for one space and remembers the
/// transcripts the list rows no longer carry.
///
/// A list snapshot elides `segments`. While a turn is in flight the segments
/// live here, off the row, so a token does not rebuild the rest of the thread.
/// When the turn finishes the snapshot is kept, and a row that was already
/// finished before this screen opened is loaded once through [load].
class PhoneTurnRelay {
  /// Creates a relay for [spaceId]. [loadMessage] reads one full message
  /// (the call that still returns `segments`) and is not used for a turn
  /// this relay already watched to completion.
  PhoneTurnRelay({required this.spaceId, required this.loadMessage});

  /// The space whose turns this relay folds.
  final String spaceId;

  /// Fetches the persisted transcript of one message.
  final Future<List<TranscriptSegment>> Function(String messageId) loadMessage;

  final ActiveStreamRegistry _registry = ActiveStreamRegistry();
  final Map<String, List<TranscriptSegment>> _finished = {};
  final Map<String, Future<List<TranscriptSegment>>> _loads = {};
  int _finishedChars = 0;

  /// Message ids as turns register, including a seed. A tile built before its
  /// turn went live listens here so it can attach without a list rebuild.
  Stream<String> get registrations => _registry.registrations;

  /// Whether [messageId] is streaming right now.
  bool isLive(String messageId) => _registry.isActive(messageId);

  /// In-flight segments, or null when the turn is not live.
  List<TranscriptSegment>? liveSegments(String messageId) =>
      _registry.snapshot(messageId);

  /// Segments kept after a turn this relay saw finish, or after [load].
  List<TranscriptSegment>? finishedSegments(String messageId) =>
      _finished[messageId];

  /// Live updates for [messageId], or null when nothing is streaming.
  Stream<TranscriptUpdate>? updatesFor(String messageId) =>
      _registry.updatesFor(messageId);

  /// Folds one relay frame. Unknown frames never reach here.
  void applyEvent(SpaceTurnEvent event) {
    switch (event) {
      case TurnRelaySeed(:final turns):
        final seeded = {for (final turn in turns) turn.messageId};
        for (final id in _registry.activeIn(spaceId).toList()) {
          if (!seeded.contains(id)) {
            unawaited(_registry.unregister(id));
          }
        }
        for (final turn in turns) {
          if (_registry.isActive(turn.messageId)) {
            unawaited(_registry.unregister(turn.messageId));
          }
          _registry.seed(turn.messageId, turn.segments, spaceId: spaceId);
        }
      case TurnRelayUpdates(:final messageId, :final updates):
        for (final update in updates) {
          if (!_registry.isActive(messageId)) {
            _registry.register(messageId, spaceId: spaceId);
          }
          _registry.apply(messageId, update);
          if (update is TurnFinished) {
            final snapshot = _registry.snapshot(messageId);
            if (snapshot != null && snapshot.isNotEmpty) {
              _remember(messageId, snapshot);
            }
            unawaited(_registry.unregister(messageId));
          }
        }
    }
  }

  /// The finished transcript of [messageId]: memory first, otherwise one
  /// call to [loadMessage]. Concurrent callers share that call.
  Future<List<TranscriptSegment>> load(String messageId) {
    final cached = _finished[messageId];
    if (cached != null) {
      return Future<List<TranscriptSegment>>.value(cached);
    }
    final pending = _loads[messageId];
    if (pending != null) {
      return pending;
    }
    final future = _loadFresh(messageId);
    _loads[messageId] = future;
    return future;
  }

  Future<List<TranscriptSegment>> _loadFresh(String messageId) async {
    try {
      final segments = await loadMessage(messageId);
      if (segments.isNotEmpty) {
        _remember(messageId, segments);
      }
      return segments;
    } finally {
      final dropped = _loads.remove(messageId);
      if (dropped != null) {
        // This method is [dropped]. Awaiting it here never completes.
        unawaited(dropped);
      }
    }
  }

  void _remember(String messageId, List<TranscriptSegment> segments) {
    final previous = _finished.remove(messageId);
    if (previous != null) {
      _finishedChars -= _chars(previous);
    }
    _finished[messageId] = segments;
    _finishedChars += _chars(segments);
    while (_finished.length > _maxFinished ||
        (_finishedChars > _maxFinishedChars && _finished.length > 1)) {
      final oldest = _finished.keys.first;
      final removed = _finished.remove(oldest);
      if (removed != null) {
        _finishedChars -= _chars(removed);
      }
    }
  }
}

int _chars(List<TranscriptSegment> segments) {
  var total = 0;
  for (final segment in segments) {
    switch (segment) {
      case ReasoningSegment(:final text):
      case TextSegment(:final text):
        total += text.length;
      case ToolSegment(:final toolName, :final outputs):
        total += toolName.length + outputs.length;
      case ErrorSegment(:final message):
        total += message.length;
      case ViolationSegment(:final message, :final target):
        total += message.length + (target?.length ?? 0);
    }
  }
  return total;
}

/// What one phone row should draw from a lite message plus [turns].
class PhoneTurnPresentation {
  /// Creates a presentation.
  const PhoneTurnPresentation({
    required this.segments,
    required this.showTranscript,
    required this.streamComplete,
    required this.fetch,
  });

  /// Segments to render. Empty while a finished row's transcript is loading.
  final List<TranscriptSegment> segments;

  /// Agent transcript chrome, including the live "working" tail.
  final bool showTranscript;

  /// False while the turn is still streaming.
  final bool streamComplete;

  /// Load the persisted transcript. False while the turn is streaming and
  /// when the segments are already in hand — a streaming fetch would pull a
  /// transcript the next flush immediately replaces.
  final bool fetch;
}

/// Resolves [message] against [turns]. [fetched] is a transcript already
/// loaded for this row; null means it has not been requested yet.
PhoneTurnPresentation presentPhoneTurn({
  required MessageDto message,
  required bool isMine,
  PhoneTurnRelay? turns,
  List<TranscriptSegment>? fetched,
}) {
  final metadata = message.metadata;
  final meta = metadata is Map<dynamic, dynamic> ? metadata : null;
  final inline = decodeTranscript(meta?['segments']);
  final live = turns?.isLive(message.id) ?? false;
  final remembered = live
      ? (turns?.liveSegments(message.id) ?? const <TranscriptSegment>[])
      : (turns?.finishedSegments(message.id) ?? const <TranscriptSegment>[]);
  final segments = inline.isNotEmpty
      ? inline
      : (remembered.isNotEmpty
            ? remembered
            : (fetched ?? const <TranscriptSegment>[]));
  final elided = meta?['segments_elided'] == true;
  final isAgentTurn =
      !isMine &&
      message.senderType != 'user' &&
      (message.messageType == 'agent_turn' ||
          segments.isNotEmpty ||
          elided ||
          live);
  final streamComplete = live
      ? false
      : ((meta?['streamComplete'] as bool?) ?? !isAgentTurn);
  final hasSegments =
      inline.isNotEmpty || remembered.isNotEmpty || fetched != null;
  return PhoneTurnPresentation(
    segments: segments,
    showTranscript: isAgentTurn && (segments.isNotEmpty || !streamComplete),
    streamComplete: streamComplete,
    fetch:
        turns != null &&
        !hasSegments &&
        !live &&
        meta != null &&
        meta['segments'] is! List &&
        elided &&
        meta['streamComplete'] != false,
  );
}
