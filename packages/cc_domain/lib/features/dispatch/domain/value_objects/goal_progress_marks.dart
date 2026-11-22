import 'dart:convert';

import 'package:cc_domain/features/dispatch/domain/value_objects/json_safe.dart';
import 'package:cc_domain/features/evals/domain/value_objects/agent_config_hash.dart'
    show canonicalHash;

/// What a goal remembers about its progress between segments
/// (`agent_goal_runs.progress_marks`, JSON text; plan section 8 as amended
/// by the second review's finding 5):
///
/// - the last [maxMarks] marks it has had, one per segment end: a hash of
///   the worktree fingerprint, the checklist and the segment's activity
///   digest. A segment whose mark was seen before made no progress, however
///   it differs from the segment just before (a file changed and changed
///   back, one checklist item flipped each segment);
/// - the stretch it has waited without progress, whatever it waited on (the
///   third review's finding 4: the stretch is the goal's, not the owed
///   rows'): [waitSince] and [waits] (segments that ended waiting with no
///   progress). Each such wait doubles the fallback ([fallback]: 20, 40, 80
///   minutes, at most 4 hours). Only progress ends the stretch (and a
///   person's Resume);
/// - of those, [freshWaits]: the waits on something the goal set up anew,
///   i.e. owed work with an id the wait before did not owe ([owed]): a new
///   `wake_me`, ask, watch or delegated ticket each segment. Work that is
///   finishing (an ask answered, a ticket done) only drops ids, so it is
///   never fresh, and a wait that drops one id and adds another is fresh
///   once.
///
/// The goal stops for a person ([stalled]) after [maxWait] of the stretch
/// or [maxFreshWaits] fresh waits, whichever comes first. A long wait on
/// one unchanged ask, or on answers arriving one by one, is fresh at most
/// once, so only the 24 hours stop it.
final class GoalProgressMarks {
  /// Creates the record. Throws [ArgumentError] for more than [maxMarks]
  /// marks, an empty mark, a negative [waits] or [freshWaits] more than
  /// [waits]. [owed] is kept sorted and without repeats.
  GoalProgressMarks({
    List<String> marks = const [],
    Iterable<String> owed = const [],
    DateTime? waitSince,
    this.waits = 0,
    this.freshWaits = 0,
  }) : marks = List.unmodifiable(marks),
       owed = List.unmodifiable(owed.toSet().toList()..sort()),
       waitSince = waitSince?.toUtc() {
    if (marks.length > maxMarks) {
      throw ArgumentError.value(marks.length, 'marks', 'at most $maxMarks');
    }
    if (marks.any((m) => m.isEmpty)) {
      throw ArgumentError.value(marks, 'marks', 'must not be empty');
    }
    if (waits < 0) {
      throw ArgumentError.value(waits, 'waits', 'must not be negative');
    }
    if (freshWaits < 0 || freshWaits > waits) {
      throw ArgumentError.value(freshWaits, 'freshWaits', 'must be 0..waits');
    }
  }

  /// Nothing remembered yet.
  static final GoalProgressMarks empty = GoalProgressMarks();

  /// How many marks are remembered.
  static const int maxMarks = 8;

  /// How long a goal waits without progress before it pauses for a person
  /// (`stalled_waiting`).
  static const Duration maxWait = Duration(hours: 24);

  /// How many waits on fresh owed work without progress pause it.
  static const int maxFreshWaits = 6;

  /// The first wait's fallback.
  static const Duration firstFallback = Duration(minutes: 20);

  /// The longest fallback.
  static const Duration maxFallback = Duration(hours: 4);

  /// The marks, oldest first.
  final List<String> marks;

  /// The ids of the owed work the goal waited on last, sorted; empty when
  /// it is not waiting.
  final List<String> owed;

  /// When the goal began waiting without progress, in UTC; null when it is
  /// not in such a stretch.
  final DateTime? waitSince;

  /// The segments of the stretch: each ended waiting, with no progress.
  final int waits;

  /// Those of [waits] that waited on owed work with an id the wait before
  /// did not owe: something the goal set up anew.
  final int freshWaits;

  /// The mark of a segment's end.
  static String markOf({
    required String? fingerprint,
    required String? checklist,
    required String? activity,
  }) => canonicalHash([fingerprint, checklist, activity]);

  /// Whether [mark] was seen before.
  bool seen(String mark) => marks.contains(mark);

  /// The record with [mark] as the newest mark, the oldest dropped past
  /// [maxMarks].
  GoalProgressMarks remember(String mark) {
    final next = [
      for (final m in marks)
        if (m != mark) m,
      mark,
    ];
    return GoalProgressMarks(
      marks: next.length > maxMarks
          ? next.sublist(next.length - maxMarks)
          : next,
      owed: owed,
      waitSince: waitSince,
      waits: waits,
      freshWaits: freshWaits,
    );
  }

  /// The record after a segment that ended waiting on the owed work [ids]
  /// at [now]. With [progressed] the stretch ends (the goal still waits,
  /// from a first fallback); otherwise it goes on, whatever [ids] are, one
  /// wait more, and a fresh one when [ids] hold one the last wait did not
  /// owe ([isFresh]).
  GoalProgressMarks waited({
    required Iterable<String> ids,
    required bool progressed,
    required DateTime now,
  }) {
    if (progressed) {
      return GoalProgressMarks(marks: marks, owed: ids);
    }
    final since = waitSince;
    return GoalProgressMarks(
      marks: marks,
      owed: ids,
      waitSince: since ?? now,
      waits: since == null ? 1 : waits + 1,
      freshWaits: freshWaits + (isFresh(ids) ? 1 : 0),
    );
  }

  /// Whether waiting on [ids] waits on something the last wait did not owe:
  /// work set up since. Fewer ids (work finishing) is never fresh.
  bool isFresh(Iterable<String> ids) {
    final before = owed.toSet();
    return ids.any((id) => !before.contains(id));
  }

  /// The record after progress (or a person's Resume): no stretch.
  GoalProgressMarks endWait() => owed.isEmpty && waitSince == null && waits == 0
      ? this
      : GoalProgressMarks(marks: marks);

  /// The fallback after the current wait: [firstFallback] doubled for each
  /// earlier wait in the stretch, at most [maxFallback].
  Duration get fallback {
    final shift = waits <= 1 ? 0 : waits - 1;
    final minutes = firstFallback.inMinutes << (shift > 8 ? 8 : shift);
    final delay = Duration(minutes: minutes);
    return delay > maxFallback ? maxFallback : delay;
  }

  /// Whether the stretch stops the goal at [now]: [maxWait] of it, or
  /// [maxFreshWaits] fresh waits.
  bool stalled(DateTime now) {
    final since = waitSince;
    return freshWaits >= maxFreshWaits ||
        (since != null && !now.toUtc().isBefore(since.add(maxWait)));
  }

  /// How long the stretch has lasted at [now] (zero outside one).
  Duration waitedFor(DateTime now) {
    final since = waitSince;
    return since == null ? Duration.zero : now.toUtc().difference(since);
  }

  /// The stored JSON object.
  Map<String, Object?> toJson() => {
    'marks': marks,
    if (owed.isNotEmpty) 'owed': owed,
    'waitSince': ?waitSince?.toIso8601String(),
    if (waits > 0) 'waits': waits,
    if (freshWaits > 0) 'freshWaits': freshWaits,
  };

  /// [toJson] encoded, as the column stores it.
  String encode() => jsonEncode(toJson());

  /// Decodes the stored column; [empty] for null, empty or malformed text.
  /// Never throws.
  static GoalProgressMarks parse(String? raw) {
    if (raw == null || raw.isEmpty) {
      return empty;
    }
    try {
      final json = jsonDecode(raw);
      if (json is! Map) {
        return empty;
      }
      final marks = [
        for (final m in JsonSafe.strings(json['marks']))
          if (m.isNotEmpty) m,
      ];
      final waits = (JsonSafe.intOrNull(json['waits']) ?? 0).clamp(0, 1 << 20);
      return GoalProgressMarks(
        marks: marks.length > maxMarks
            ? marks.sublist(marks.length - maxMarks)
            : marks,
        owed: [
          for (final id in JsonSafe.strings(json['owed']))
            if (id.isNotEmpty) id,
        ],
        waitSince: JsonSafe.dateOrNull(json['waitSince']),
        waits: waits,
        freshWaits: (JsonSafe.intOrNull(json['freshWaits']) ?? 0).clamp(
          0,
          waits,
        ),
      );
    } on FormatException {
      return empty;
    } on ArgumentError {
      return empty;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is GoalProgressMarks &&
          JsonSafe.equals(marks, other.marks) &&
          JsonSafe.equals(owed, other.owed) &&
          (waitSince == null
              ? other.waitSince == null
              : other.waitSince != null &&
                    waitSince!.isAtSameMomentAs(other.waitSince!)) &&
          waits == other.waits &&
          freshWaits == other.freshWaits;

  @override
  int get hashCode => Object.hash(
    Object.hashAll(marks),
    Object.hashAll(owed),
    waitSince?.millisecondsSinceEpoch,
    waits,
    freshWaits,
  );

  @override
  String toString() => 'GoalProgressMarks(${toJson()})';
}
