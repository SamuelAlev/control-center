part of 'messaging_dao.dart';

/// Unicode code points in [text], which is what SQLite `LENGTH` counts.
///
/// `String.length` counts UTF-16 code units, so an emoji is 2. The meter used
/// to sum `LENGTH(content)`. This is that count, and it is what the v12
/// backfill stores.
int _sqliteTextLength(String text) => text.runes.length;

/// `transcriptChars` from a metadata JSON object, or 0 when it is absent.
int _transcriptCharsOf(Map<dynamic, dynamic> metadata) {
  final value = metadata['transcriptChars'];
  if (value is int) {
    return value;
  }
  if (value is num) {
    return value.toInt();
  }
  return 0;
}

/// `metadata['context']`'s provider-reported reading, or nulls when the
/// turn carries none.
({int? tokens, int? window}) _contextOf(Map<dynamic, dynamic> metadata) {
  final context = metadata['context'];
  if (context is! Map) {
    return (tokens: null, window: null);
  }
  int? read(Object? value) => value is num ? value.toInt() : null;
  return (tokens: read(context['tokens']), window: read(context['window']));
}

/// The metadata keys stored in their own columns of `conversation_messages`
/// (`answered`, `plan_status`, `steer_state`) instead of in the JSON.
///
/// Hot queries filter on them. The write path lifts them out of the map; the
/// mapper puts them back, so domain code still reads them from `metadata`.
const promotedMetadataKeys = ['answered', 'planStatus', 'steerState'];

/// The metadata keys that describe a turn's transcript and are never stored
/// in the JSON.
///
/// `segments` is written as the message's `transcript_segments` rows and put
/// back by the reads that render a turn; `segments_elided` and
/// `segment_count` are what a list read says about those rows instead.
const transcriptMetadataKeys = ['segments', 'segments_elided', 'segment_count'];

/// The promoted keys of [metadata], its transcript, and the map without
/// either.
///
/// A `planStatus` or `steerState` that names no state is refused here with
/// an [ArgumentError] naming it, rather than by the column's `CHECK`.
({
  bool answered,
  String? planStatus,
  String? steerState,
  List<Map<dynamic, dynamic>>? segments,
  Map<dynamic, dynamic> rest,
})
_liftPromoted(Map<dynamic, dynamic> metadata) {
  final planStatus = metadata['planStatus'];
  final steerState = metadata['steerState'];
  if (planStatus is String &&
      PlanMessageStatus.tryFromWire(planStatus) == null) {
    throw ArgumentError.value(planStatus, 'planStatus', 'unknown plan state');
  }
  if (steerState is String && SteeringState.tryFromWire(steerState) == null) {
    throw ArgumentError.value(steerState, 'steerState', 'unknown steer state');
  }
  final segments = metadata['segments'];
  return (
    answered: metadata['answered'] == true,
    planStatus: planStatus is String ? planStatus : null,
    steerState: steerState is String ? steerState : null,
    segments: segments is List
        ? [
            for (final segment in segments)
              if (segment is Map) segment,
          ]
        : null,
    rest: Map<dynamic, dynamic>.from(metadata)
      ..removeWhere(
        (key, _) =>
            promotedMetadataKeys.contains(key) ||
            transcriptMetadataKeys.contains(key),
      ),
  );
}

/// The transcript facts a metadata map states: whether the turn finished
/// (`streamComplete`) and how (`outcome`), each null when the map does not
/// say.
({bool? complete, String? outcome}) _turnStateOf(
  Map<dynamic, dynamic> metadata,
) {
  final complete = metadata['streamComplete'];
  final outcome = metadata['outcome'];
  return (
    complete: complete is bool ? complete : null,
    outcome: outcome is String && turnOutcomeFromString(outcome) != null
        ? outcome
        : null,
  );
}

/// [segments] as the rows `transcript_segments` stores: position → encoded
/// segment.
Map<int, String> _segmentBodies(List<Map<dynamic, dynamic>> segments) => {
  for (var i = 0; i < segments.length; i++) i: jsonEncode(segments[i]),
};

/// Every stored value derived from one metadata cell, from a single decode:
/// the transcript size, the context reading, the promoted keys, the
/// transcript and the JSON to store (without the promoted keys or the
/// transcript).
///
/// The stored text is [raw] itself when it holds neither, so a plain message
/// stays byte-identical.
///
/// An empty [raw] stores no metadata. Anything else that is not a JSON
/// object is refused with an [ArgumentError]: the column only holds objects,
/// and the hot queries read it with `json_extract`.
({
  int transcriptChars,
  ({int? tokens, int? window}) context,
  bool answered,
  String? planStatus,
  String? steerState,
  List<Map<dynamic, dynamic>>? segments,
  ({bool? complete, String? outcome}) turn,
  String? metadata,
})
_stampMetadataJson(String? raw) {
  if (raw == null || raw.isEmpty) {
    return (
      transcriptChars: 0,
      context: (tokens: null, window: null),
      answered: false,
      planStatus: null,
      steerState: null,
      segments: null,
      turn: (complete: null, outcome: null),
      metadata: null,
    );
  }
  final Object? decoded;
  try {
    decoded = jsonDecode(raw);
  } on FormatException {
    throw ArgumentError.value(raw, 'metadata', 'not JSON');
  }
  if (decoded is! Map<dynamic, dynamic>) {
    throw ArgumentError.value(raw, 'metadata', 'not a JSON object');
  }
  final lifted = _liftPromoted(decoded);
  return (
    transcriptChars: _transcriptCharsOf(decoded),
    context: _contextOf(decoded),
    answered: lifted.answered,
    planStatus: lifted.planStatus,
    steerState: lifted.steerState,
    segments: lifted.segments,
    turn: _turnStateOf(decoded),
    metadata: lifted.rest.length == decoded.length
        ? raw
        : jsonEncode(lifted.rest),
  );
}

/// A message row as a list read returns it: the row, and what the list says
/// about its transcript without reading a segment.
///
/// `hasTranscript` is whether the message owns a transcript at all;
/// `segmentCount` is its length once the turn finished, and null before (a
/// streaming turn's count grows on every flush, and a list must not change
/// with it).
typedef ListedMessageRow = ({
  ConversationMessagesTableData data,
  bool hasTranscript,
  int? segmentCount,
});
