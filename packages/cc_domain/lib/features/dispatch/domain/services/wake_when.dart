/// The `when` grammar of a wake rule (plan section 9, "Triggers"), shared by
/// `wake_me`, `/loop`, `/schedule` and the `wakeRules.*` operations:
///
/// | `when` | Trigger |
/// | --- | --- |
/// | `in:<duration>` | once, that long from now |
/// | `at:<ISO time>` | once, at that instant (no offset: UTC) |
/// | `every:<duration>` | repeatedly, in epoch-aligned slots |
/// | `cron:<five fields>` | on the cron schedule, in a time zone |
/// | `next` | self-paced (the agent picks the delay each run) |
/// | `on:pr_checks`, `on:pr_review`, `on:pr_merged` (each optionally `:<owner>/<name>#<number>`), `on:environment`, `on:ticket:<id>`, `on:pipeline_run:<id>` | a watch |
///
/// A duration is one or more `<integer><unit>` groups, the unit one of `s`,
/// `m`, `h`, `d` (`90s`, `20m`, `1h30m`, `7d`).
///
/// Pure: the instant `in:` counts from is passed in, and whether a time zone
/// exists is asked of the caller (the zone database lives in the server).
library;

import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/services/cron_schedule.dart';

/// The `data.kind` of a `when` (or a duration) that does not parse, names an
/// instant that is not ahead, or names a time zone or cron that cannot fire.
const String wakeInvalidWhenKind = 'wake_invalid_when';

/// What a `when` asks for.
sealed class WakeWhen {
  const WakeWhen();
}

/// A rule with [trigger] (every form but `next`).
final class WakeWhenTrigger extends WakeWhen {
  /// Creates the reading.
  const WakeWhenTrigger(this.trigger);

  /// The rule's trigger.
  final WakeTrigger trigger;
}

/// `next`: the self-paced rule's chosen delay (inside a run that rule
/// started), or a self-paced rule (a person's `/loop` without `every`).
final class WakeWhenNext extends WakeWhen {
  /// Creates the reading.
  const WakeWhenNext();
}

/// `every:<duration>` under [Every.minInterval]: readable, but the rule
/// service refuses it as `wake_interval_too_short`.
final class WakeWhenTooShort extends WakeWhen {
  /// Creates the reading.
  const WakeWhenTooShort(this.interval);

  /// The interval asked for.
  final Duration interval;
}

/// A `when` that could not be read: [message] says why, in words a model or
/// a person can act on.
final class WakeWhenInvalid extends WakeWhen {
  /// Creates the reading.
  const WakeWhenInvalid(this.message);

  /// Why it could not be read.
  final String message;
}

/// One line per form, with an example each: what a refusal and the first
/// `wake_me` result of a run show the model.
const String wakeWhenGrammar =
    'when: in:20m (once, after a delay) | at:2026-11-20T09:00:00Z (once, at '
    'an ISO time; no offset means UTC) | every:30m (repeatedly, 60 s or more '
    'apart) | cron:0 9 * * 1-5 (five fields; pass tz, an IANA zone, default '
    'the workspace\'s zone) | next (inside a run your self-paced loop '
    'started: the delay to '
    'the next run, given as delay, 1m to 1h) | on:pr_checks | on:pr_review | '
    'on:pr_merged (the space\'s pull request, or name one: '
    'on:pr_checks:acme/shop-ui#12) | on:environment | on:ticket:<id> | '
    'on:pipeline_run:<id> (when that happens). Durations use s, m, h, d '
    '(90s, 20m, 1h30m, 7d).';

final RegExp _durationRe = RegExp(r'^(?:\d+[smhd])+$');
final RegExp _groupRe = RegExp(r'(\d+)([smhd])');

/// Parses a duration (`90s`, `20m`, `1h30m`, `7d`). Null for anything else,
/// zero, or more than 10 years.
Duration? parseWakeDuration(String raw) {
  final text = raw.trim().toLowerCase();
  if (!_durationRe.hasMatch(text)) {
    return null;
  }
  var seconds = 0;
  for (final m in _groupRe.allMatches(text)) {
    final n = int.tryParse(m.group(1)!);
    if (n == null || n > 1000000000) {
      return null;
    }
    seconds += switch (m.group(2)!) {
      's' => n,
      'm' => n * 60,
      'h' => n * 3600,
      _ => n * 86400,
    };
    if (seconds > _maxDurationSeconds) {
      return null;
    }
  }
  return seconds <= 0 ? null : Duration(seconds: seconds);
}

const int _maxDurationSeconds = 10 * 365 * 86400;

/// [d] in the compact grammar (`1h30m`, `45s`, `7d`).
String formatWakeDuration(Duration d) {
  var rest = d.inSeconds;
  if (rest <= 0) {
    return '0s';
  }
  final out = StringBuffer();
  for (final (unit, size) in const [
    ('d', 86400),
    ('h', 3600),
    ('m', 60),
    ('s', 1),
  ]) {
    final n = rest ~/ size;
    if (n > 0) {
      out.write('$n$unit');
      rest -= n * size;
    }
  }
  return out.toString();
}

/// Parses [when]. [now] is the instant `in:` counts from; [timeZone] is the
/// zone a `cron:` is read in (`UTC` when null or empty); [isKnownZone] says
/// whether a zone exists (every zone does when null).
///
/// Refuses (as [WakeWhenInvalid]) what can never fire: an unknown form, a bad
/// duration, an `at:` that is not ahead of [now], a cron that never matches,
/// an unknown zone, a watch without (or with a stray) target. The limits of
/// a rule (the 60-second minimum, the expiry) are the rule service's.
WakeWhen parseWakeWhen(
  String when, {
  required DateTime now,
  String? timeZone,
  bool Function(String zone)? isKnownZone,
}) {
  final text = when.trim();
  if (text == 'next') {
    return const WakeWhenNext();
  }
  final colon = text.indexOf(':');
  if (colon <= 0) {
    return WakeWhenInvalid('"$text" is not a when. $wakeWhenGrammar');
  }
  final form = text.substring(0, colon).trim().toLowerCase();
  final value = text.substring(colon + 1).trim();
  switch (form) {
    case 'in':
      final d = parseWakeDuration(value);
      if (d == null) {
        return WakeWhenInvalid(
          '"$value" is not a duration: use s, m, h or d (20m, 1h30m).',
        );
      }
      return WakeWhenTrigger(OnceAt(now.toUtc().add(d)));
    case 'at':
      final at = parseWakeInstant(value);
      if (at == null) {
        return WakeWhenInvalid(
          '"$value" is not an ISO time (2026-11-20T09:00:00Z; no offset '
          'means UTC).',
        );
      }
      if (!at.isAfter(now.toUtc())) {
        return WakeWhenInvalid(
          '$value is not in the future (it is now '
          '${now.toUtc().toIso8601String()}).',
        );
      }
      return WakeWhenTrigger(OnceAt(at));
    case 'every':
      final d = parseWakeDuration(value);
      if (d == null) {
        return WakeWhenInvalid(
          '"$value" is not a duration: use s, m, h or d (30m, 2h).',
        );
      }
      if (d < Every.minInterval) {
        return WakeWhenTooShort(d);
      }
      return WakeWhenTrigger(Every(d));
    case 'cron':
      final schedule = CronSchedule.tryParse(value);
      if (schedule == null) {
        return WakeWhenInvalid(
          '"$value" is not a five-field cron (minute hour day-of-month '
          'month day-of-week).',
        );
      }
      if (schedule.nextAfter(DateTime.utc(2000)) == null) {
        return WakeWhenInvalid('"$value" never matches a real date.');
      }
      final zone = (timeZone == null || timeZone.trim().isEmpty)
          ? 'UTC'
          : timeZone.trim();
      if (isKnownZone != null && !isKnownZone(zone)) {
        return WakeWhenInvalid(
          '"$zone" is not an IANA time zone (Europe/Berlin, America/New_York, '
          'UTC).',
        );
      }
      return WakeWhenTrigger(Cron(schedule.expression.trim(), zone));
    case 'on':
      return _parseWatch(value);
    default:
      return WakeWhenInvalid('"$form:" is not a when form. $wakeWhenGrammar');
  }
}

WakeWhen _parseWatch(String value) {
  final colon = value.indexOf(':');
  final name = (colon < 0 ? value : value.substring(0, colon)).trim();
  final target = colon < 0 ? null : value.substring(colon + 1).trim();
  final kind = WakeEventKindWire.tryParse(name);
  if (kind == null) {
    return WakeWhenInvalid(
      '"on:$value" is not a watch: on:pr_checks, on:pr_review, on:pr_merged, '
      'on:environment, on:ticket:<id>, on:pipeline_run:<id>.',
    );
  }
  if (OnEvent.needsTarget(kind)) {
    if (target == null || target.isEmpty) {
      return WakeWhenInvalid(
        'on:${kind.wire} names its id: on:${kind.wire}:<id>.',
      );
    }
    return WakeWhenTrigger(OnEvent(kind, targetId: target));
  }
  if (target != null && OnEvent.isPullRequest(kind)) {
    final ref = WakePullRequestRef.tryParse(target);
    if (ref == null) {
      return WakeWhenInvalid(
        'on:${kind.wire} names a pull request as owner/name#number '
        '(on:${kind.wire}:acme/shop-ui#12), or none for the space\'s own.',
      );
    }
    return WakeWhenTrigger(OnEvent(kind, targetId: ref.toString()));
  }
  if (target != null) {
    return WakeWhenInvalid(
      'on:${kind.wire} watches this space\'s environment; it takes no id.',
    );
  }
  return WakeWhenTrigger(OnEvent(kind));
}

/// Parses an ISO 8601 instant; one without an offset is read as UTC. Null
/// when it does not parse.
DateTime? parseWakeInstant(String raw) {
  final text = raw.trim();
  if (text.isEmpty) {
    return null;
  }
  final hasOffset =
      text.endsWith('Z') ||
      text.endsWith('z') ||
      (text.length > 10 &&
          RegExp(r'[+-]\d{2}:?\d{2}$').hasMatch(text.substring(10)));
  final dated = text.length == 10 ? '${text}T00:00:00' : text;
  final parsed = DateTime.tryParse(hasOffset ? dated : '${dated}Z');
  return parsed?.toUtc();
}

/// [trigger] in the `when` grammar (`every:20m`, `cron:0 9 * * 1-5`, `next`,
/// `on:ticket:T-1`, `at:2026-11-20T09:00:00.000Z`). A cron's zone is not
/// part of it (see [formatWakeZone]).
String formatWakeWhen(WakeTrigger trigger) => switch (trigger) {
  OnceAt(:final at) => 'at:${at.toUtc().toIso8601String()}',
  Every(:final interval) => 'every:${formatWakeDuration(interval)}',
  Cron(:final expression) => 'cron:$expression',
  SelfPaced() => 'next',
  OnEvent(:final eventKind, :final targetId) =>
    targetId == null
        ? 'on:${eventKind.wire}'
        : 'on:${eventKind.wire}:$targetId',
};

/// The zone of a `cron:` trigger when it is not UTC, else null.
String? formatWakeZone(WakeTrigger trigger) => switch (trigger) {
  Cron(:final timeZone) when timeZone != 'UTC' && timeZone != 'Etc/UTC' =>
    timeZone,
  _ => null,
};
