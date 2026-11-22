/// What happens to a request nobody answers (plan section 12, "When nobody
/// answers"): how long a run the server started waits on a person before
/// its approval counts as denied and its question as unanswered, and the
/// hour the daily digest of what is waiting goes out.
library;

import 'dart:convert';

/// The workspace setting that holds a workspace's [UnattendedPolicy].
const String unattendedPolicySettingKey = 'unattended_requests';

/// The answer an `--unattended assume` goal's question gets when nobody
/// answered it within [unattendedAssumeAfter]. Copied from the plan; pinned.
const String unattendedAssumeAnswer =
    'nobody is available: state your assumption, proceed only if the stop '
    'conditions allow it, and record it';

/// How long a question of an `--unattended assume` goal waits before it is
/// released with [unattendedAssumeAnswer]. Approvals are never released.
const Duration unattendedAssumeAfter = Duration(minutes: 10);

/// The hold detail of a goal paused because a request of its segment went
/// unanswered (`hold: needsReview`).
const String goalHoldUnanswered = 'unanswered';

/// A workspace's handling of unanswered requests, stored as JSON under
/// [unattendedPolicySettingKey]:
///
/// ```json
/// {"expiry_minutes": 4320, "digest_hour": 9}
/// ```
///
/// The setting is written raw by an admin (`workspace_settings.set`), so it
/// is read leniently: a missing or unreadable value is the default, and a
/// number out of range is clamped into it.
class UnattendedPolicy {
  /// Creates a policy. Throws [ArgumentError] for an expiry outside
  /// [minExpiry]..[maxExpiry] or an hour outside 0..23.
  UnattendedPolicy({this.expiry = defaultExpiry, this.digestHour = 9}) {
    if (expiry < minExpiry || expiry > maxExpiry) {
      throw ArgumentError.value(expiry, 'expiry', 'must be 1 hour to 7 days');
    }
    if (digestHour < 0 || digestHour > 23) {
      throw ArgumentError.value(digestHour, 'digestHour', 'must be 0 to 23');
    }
  }

  /// Reads the stored setting text. Null, empty or unreadable text is the
  /// defaults; an out-of-range number is clamped.
  factory UnattendedPolicy.fromSetting(String? stored) {
    if (stored == null || stored.trim().isEmpty) {
      return UnattendedPolicy();
    }
    Object? decoded;
    try {
      decoded = jsonDecode(stored);
    } on FormatException {
      return UnattendedPolicy();
    }
    if (decoded is! Map) {
      return UnattendedPolicy();
    }
    int? whole(Object? v) =>
        v is num && v == v.roundToDouble() ? v.toInt() : null;
    final minutes = whole(decoded['expiry_minutes']);
    final hour = whole(decoded['digest_hour']);
    return UnattendedPolicy(
      expiry: minutes == null
          ? defaultExpiry
          : Duration(
              minutes: minutes.clamp(minExpiry.inMinutes, maxExpiry.inMinutes),
            ),
      digestHour: hour == null ? 9 : hour.clamp(0, 23),
    );
  }

  /// The default expiry: 72 hours, so a request made on a Friday evening
  /// still waits on Monday morning.
  static const Duration defaultExpiry = Duration(hours: 72);

  /// The shortest expiry a workspace may set.
  static const Duration minExpiry = Duration(hours: 1);

  /// The longest expiry a workspace may set.
  static const Duration maxExpiry = Duration(days: 7);

  /// How long a request of a run the server started waits for a person.
  final Duration expiry;

  /// The local hour (in the workspace's time zone) the daily digest is sent.
  final int digestHour;

  /// The stored JSON shape.
  Map<String, Object?> toJson() => {
    'expiry_minutes': expiry.inMinutes,
    'digest_hour': digestHour,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UnattendedPolicy &&
          expiry == other.expiry &&
          digestHour == other.digestHour;

  @override
  int get hashCode => Object.hash(expiry, digestHour);
}

/// [d] in words for the texts below: `24 hours`, `1 hour`, `3 days`,
/// `90 minutes`.
String formatUnattendedDuration(Duration d) {
  String unit(int n, String word) => n == 1 ? '1 $word' : '$n ${word}s';
  if (d.inMinutes % (24 * 60) == 0 && d.inDays > 1) {
    return unit(d.inDays, 'day');
  }
  if (d.inMinutes % 60 == 0 && d.inHours > 0) {
    return unit(d.inHours, 'hour');
  }
  return unit(d.inMinutes, 'minute');
}

/// What a question's `ask_user` result says when nobody answered it within
/// the workspace's [expiry]: the run is told, and its segment ends.
String unattendedQuestionNotice(Duration expiry) =>
    'Nobody answered this question within '
    '${formatUnattendedDuration(expiry)}, so it is withdrawn and counts as '
    'unanswered. Do not ask again and do not assume an answer: end your turn '
    'now, saying what is done, what remains and what the answer would '
    'decide.';

/// What the run is told when nobody answered its approval request [title]
/// within [expiry]: the request counts as denied.
String unattendedApprovalNotice(String title, Duration expiry) =>
    'Nobody answered the approval request "${_oneLine(title)}" within '
    '${formatUnattendedDuration(expiry)}, so it counts as denied: nothing was '
    'approved. Do not retry it: end your turn now, saying what is done, what '
    'remains and what the approval would have allowed.';

/// What a run is told when its approval request [title] is refused without
/// a card because an earlier request in the same run went unanswered.
String unattendedAfterExpiryApprovalNotice(String title) =>
    'The approval request "${_oneLine(title)}" was refused without asking '
    'anyone: an earlier request in this run went unanswered, so nobody is '
    'there to answer. Nothing was approved. Do not ask again: finish what you '
    'can without approvals or answers, then end your turn, saying what is '
    'done and what remains.';

/// What a question's `ask_user` result says when it is not shown because an
/// earlier request in the same run went unanswered.
const String unattendedAfterExpiryQuestionNotice =
    'This question was not shown to anyone: an earlier request in this run '
    'went unanswered, so nobody is there to answer. It counts as unanswered. '
    'Do not ask again and do not assume an answer: finish what you can '
    'without it, then end your turn, saying what is done, what remains and '
    'what the answer would decide.';

/// The conversation row that says a request went unanswered. [what] is
/// `approval` or `question`; [summary] its title or text.
String unattendedExpiredRow({
  required String what,
  required String summary,
  required Duration expiry,
  required bool goalPaused,
}) {
  final outcome = what == 'approval'
      ? 'it counts as denied'
      : 'it is withdrawn';
  return 'Nobody answered the $what "${_oneLine(summary)}" within '
      '${formatUnattendedDuration(expiry)}, so $outcome.'
      '${goalPaused ? ' The goal is paused until a person reviews it.' : ''}';
}

String _oneLine(String text) {
  final line = text.trim().replaceAll(RegExp(r'\s+'), ' ');
  return line.length <= 200 ? line : '${line.substring(0, 199)}…';
}
