import 'package:cc_domain/core/domain/value_objects/principal.dart';

/// One recorded action against a rig.
///
/// Every input event lands here, agent or human, with the principal that sent
/// it. This is what makes "who clicked that" answerable after the fact — the
/// watch-lane frames are never persisted, so without the log a take-over is
/// invisible the moment the stream ends.
class RigActionLogEntry {
  /// Creates a [RigActionLogEntry].
  RigActionLogEntry({
    required this.id,
    required this.workspaceId,
    required this.rigId,
    required this.seq,
    required this.verb,
    required this.actor,
    required this.createdAt,
    this.args = const {},
    this.summary = '',
    this.isTakeOver = false,
    this.isError = false,
    this.resultText,
    this.imageHash,
    this.durationMs,
  }) {
    // An audit row nobody can attribute is not an audit row. Every field
    // checked here is one the log is useless without — and this table is the
    // only durable record of a take-over, because the watch-lane frames are
    // never persisted.
    if (workspaceId.isEmpty) {
      throw ArgumentError.value(
        workspaceId,
        'workspaceId',
        'An action log entry must belong to a workspace',
      );
    }
    if (id.isEmpty) {
      throw ArgumentError.value(id, 'id', 'An action log entry needs an id');
    }
    if (rigId.isEmpty) {
      throw ArgumentError.value(
        rigId,
        'rigId',
        'An action log entry must name the rig it acted on',
      );
    }
    if (verb.isEmpty) {
      throw ArgumentError.value(
        verb,
        'verb',
        'An action log entry must name what was done',
      );
    }
    if (seq < 0) {
      throw ArgumentError.value(
        seq,
        'seq',
        'The per-rig sequence is monotonic and starts at 0',
      );
    }
  }

  /// Row id.
  final String id;

  /// Owning workspace.
  final String workspaceId;

  /// The rig acted upon.
  final String rigId;

  /// Monotonic per-rig sequence — the order things actually happened in, which
  /// a timestamp cannot promise when two actions land in the same millisecond.
  final int seq;

  /// The action verb.
  final String verb;

  /// The action's arguments as recorded.
  final Map<String, dynamic> args;

  /// One-line human summary for the action feed.
  final String summary;

  /// Who did it.
  final Principal actor;

  /// Whether this was sent by a human who had taken control.
  final bool isTakeOver;

  /// Whether the action failed.
  final bool isError;

  /// Short result text (truncated) — enough to read the feed without opening
  /// each entry.
  final String? resultText;

  /// SHA-256 of the frame this action produced, when it produced one.
  ///
  /// The bytes are not stored here; this is the join key to the run's retained
  /// agent-lane stills, so replay can show what the model saw without the
  /// audit table carrying megabytes of base64.
  final String? imageHash;

  /// How long the action took.
  final int? durationMs;

  /// When it happened.
  final DateTime createdAt;

  /// JSON form for the RPC surface.
  Map<String, dynamic> toJson() => {
    'id': id,
    'rig_id': rigId,
    'seq': seq,
    'verb': verb,
    'args': args,
    'summary': summary,
    'actor': actor.wire,
    'is_take_over': isTakeOver,
    'is_error': isError,
    if (resultText != null) 'result_text': resultText,
    if (imageHash != null) 'image_hash': imageHash,
    if (durationMs != null) 'duration_ms': durationMs,
    'created_at': createdAt.toIso8601String(),
  };

  /// Identity is the `(rigId, seq)` pair the database already treats as
  /// unique, plus the row id.
  ///
  /// Value equality rather than identity because these travel in lists that
  /// are diffed, de-duplicated and compared across a reload — and an entity
  /// with no `==` silently answers "different" to two reads of the same row.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RigActionLogEntry &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workspaceId == other.workspaceId &&
          rigId == other.rigId &&
          seq == other.seq &&
          verb == other.verb &&
          summary == other.summary &&
          actor == other.actor &&
          isTakeOver == other.isTakeOver &&
          isError == other.isError &&
          resultText == other.resultText &&
          imageHash == other.imageHash &&
          durationMs == other.durationMs &&
          createdAt == other.createdAt;

  @override
  int get hashCode => Object.hash(
    id,
    workspaceId,
    rigId,
    seq,
    verb,
    summary,
    actor,
    isTakeOver,
    isError,
    resultText,
    imageHash,
    durationMs,
    createdAt,
  );

  @override
  String toString() =>
      'RigActionLogEntry($rigId#$seq $verb by ${actor.wire}'
      '${isError ? ' [error]' : ''})';
}
