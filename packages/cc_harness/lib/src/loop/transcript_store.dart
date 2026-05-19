import 'package:cc_harness/src/messages.dart';

/// A run's provider-facing history, as it was at the last turn boundary.
class HarnessTranscript {
  /// Creates a [HarnessTranscript].
  const HarnessTranscript({
    required this.messages,
    this.checkpoints = const {},
    this.turns = 0,
  });

  /// Rebuilds from [toJson]'s output.
  factory HarnessTranscript.fromJson(Map<String, dynamic> json) {
    // Type-tested rather than cast: this reads a file that a crash may have
    // truncated or an older build may have written differently, and throwing
    // here would take the run down for a record whose only job is to make the
    // run cheaper.
    final rawMessages = json['messages'];
    final messages = [
      if (rawMessages is List)
        for (final raw in rawMessages)
          if (raw is Map) HarnessMessage.fromJson(raw.cast<String, dynamic>()),
    ];
    final checkpoints = <String, int>{};
    final rawCheckpoints = json['checkpoints'];
    if (rawCheckpoints is Map) {
      for (final entry in rawCheckpoints.entries) {
        final index = entry.value;
        // A checkpoint past the end of the restored history is dropped, not
        // clamped: clamping would silently retarget the rewind at whatever
        // happens to be last, which is exactly the failure the label existed
        // to prevent.
        if (index is int && index >= 0 && index <= messages.length) {
          checkpoints['${entry.key}'] = index;
        }
      }
    }
    return HarnessTranscript(
      messages: messages,
      checkpoints: checkpoints,
      turns: json['turns'] is int ? json['turns'] as int : 0,
    );
  }

  /// The message list, in order.
  final List<HarnessMessage> messages;

  /// `checkpoint` label → index into [messages].
  ///
  /// Persisted WITH the messages and never separately: an index into a list
  /// that is not the list it indexes points at a different message, and a
  /// rewind to the wrong point silently discards work while reporting success.
  final Map<String, int> checkpoints;

  /// How many model turns produced it.
  final int turns;

  /// Serializes for storage.
  Map<String, dynamic> toJson() => {
    'messages': [for (final m in messages) m.toJson()],
    'checkpoints': checkpoints,
    'turns': turns,
  };
}

/// Persists a run's history so a later run can continue it.
///
/// **What this buys, and why the loop cannot do it alone.** Every harness run
/// starts from an empty list today and rebuilds continuity from a `<context>`
/// blob in the prompt — a summary of the conversation rather than the
/// conversation. Three things follow from that and all three are fixed by the
/// same store:
///
///   * **Resume is a re-tell, not a resume.** The model never sees its own
///     earlier reasoning or tool results, only a description of them.
///   * **Rewind dies with the process.** A `checkpoint` is an index into the
///     live list, so a restart loses every label the model set.
///   * **Retry cannot tell "nothing to retry" from "nothing loaded".** After a
///     restart the failed turn is gone from live state, so the only honest
///     source for whether a partial turn happened is the persisted one.
///
/// **Save points are turn boundaries, never mid-turn.** A history captured
/// between a tool_use and its tool_result is one no provider will accept, so a
/// crash at that instant must restore the turn BEFORE, not a half-turn that
/// cannot be replayed.
abstract class HarnessTranscriptStore {
  /// Loads the transcript for [key], or null when there is none.
  Future<HarnessTranscript?> load(String key);

  /// Saves [transcript] under [key].
  ///
  /// Must not throw: a store that cannot write costs continuity, never the
  /// run in progress.
  Future<void> save(String key, HarnessTranscript transcript);

  /// Forgets [key] — the conversation was deleted or explicitly reset.
  Future<void> clear(String key);
}

/// The default: remembers nothing.
///
/// Used when no host wired a store, so the loop never has to branch on null.
class NoopHarnessTranscriptStore implements HarnessTranscriptStore {
  /// Creates a [NoopHarnessTranscriptStore].
  const NoopHarnessTranscriptStore();

  @override
  Future<HarnessTranscript?> load(String key) async => null;

  @override
  Future<void> save(String key, HarnessTranscript transcript) async {}

  @override
  Future<void> clear(String key) async {}
}

/// In-memory store, for tests and for a single-process session.
class InMemoryHarnessTranscriptStore implements HarnessTranscriptStore {
  /// Creates an [InMemoryHarnessTranscriptStore].
  InMemoryHarnessTranscriptStore();

  final Map<String, HarnessTranscript> _byKey = {};

  /// How many transcripts are held.
  int get length => _byKey.length;

  @override
  Future<HarnessTranscript?> load(String key) async => _byKey[key];

  @override
  Future<void> save(String key, HarnessTranscript transcript) async {
    _byKey[key] = transcript;
  }

  @override
  Future<void> clear(String key) async => _byKey.remove(key);
}

/// Trims a transcript to what is worth carrying across a restart.
///
/// **Why trim at all.** A resumed run pays for every message it restores, on
/// every turn, forever — and the tail of a long conversation is where the work
/// actually is. Restoring 400 messages to continue a task that only needed the
/// last 30 spends the context window on history the compactor would have shed
/// anyway.
///
/// **Why it cuts at a boundary and not at a count.** A `tool` message whose
/// matching `assistant` tool_use was dropped is a `tool_result` with no
/// `tool_use`, which providers reject outright — so the cut moves BACKWARD to
/// the first message that is not an orphaned result. A transcript that cannot
/// be sent is worse than one that is short.
HarnessTranscript trimTranscriptForResume(
  HarnessTranscript transcript, {
  int maxMessages = 200,
}) {
  final messages = transcript.messages;
  if (messages.length <= maxMessages) {
    return transcript;
  }
  var cut = messages.length - maxMessages;
  // Walk forward past any leading tool-result message, whose tool_use is now
  // behind the cut.
  while (cut < messages.length && messages[cut].role == HarnessRole.tool) {
    cut++;
  }
  // And past the assistant turn that opened a tool call whose results we would
  // otherwise start in the middle of.
  final kept = messages.sublist(cut);
  final remapped = <String, int>{};
  for (final entry in transcript.checkpoints.entries) {
    final moved = entry.value - cut;
    // A checkpoint whose target was trimmed away is dropped rather than moved
    // to the new start: rewinding "to the label" and landing somewhere else is
    // the failure a label exists to prevent.
    if (moved >= 0 && moved <= kept.length) {
      remapped[entry.key] = moved;
    }
  }
  return HarnessTranscript(
    messages: kept,
    checkpoints: remapped,
    turns: transcript.turns,
  );
}
