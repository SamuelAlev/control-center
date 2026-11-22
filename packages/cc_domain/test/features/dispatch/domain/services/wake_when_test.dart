import 'package:cc_domain/features/dispatch/domain/services/wake_when.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:test/test.dart';

final _now = DateTime.utc(2026, 11, 19, 10);

WakeTrigger _trigger(String when, {String? tz}) {
  final read = parseWakeWhen(
    when,
    now: _now,
    timeZone: tz,
    isKnownZone: (z) => const {'UTC', 'Europe/Berlin'}.contains(z),
  );
  if (read is! WakeWhenTrigger) {
    fail('$when did not read as a trigger: $read');
  }
  return read.trigger;
}

String _refusal(String when, {String? tz}) {
  final read = parseWakeWhen(
    when,
    now: _now,
    timeZone: tz,
    isKnownZone: (z) => const {'UTC', 'Europe/Berlin'}.contains(z),
  );
  if (read is! WakeWhenInvalid) {
    fail('$when was not refused: $read');
  }
  return read.message;
}

void main() {
  group('durations', () {
    test('read s, m, h and d, alone or combined', () {
      expect(parseWakeDuration('90s'), const Duration(seconds: 90));
      expect(parseWakeDuration('20m'), const Duration(minutes: 20));
      expect(parseWakeDuration('1h30m'), const Duration(minutes: 90));
      expect(parseWakeDuration('7d'), const Duration(days: 7));
      expect(parseWakeDuration(' 2H '), const Duration(hours: 2));
    });

    test('refuse anything else, zero and absurd lengths', () {
      for (final bad in ['', '20', 'm', '1.5h', '-5m', '0m', '5w', '99999d']) {
        expect(parseWakeDuration(bad), isNull, reason: bad);
      }
    });

    test('format back into the compact grammar', () {
      expect(formatWakeDuration(const Duration(minutes: 90)), '1h30m');
      expect(formatWakeDuration(const Duration(days: 1, seconds: 5)), '1d5s');
      expect(formatWakeDuration(const Duration(seconds: 45)), '45s');
    });
  });

  group('the when grammar', () {
    test('in: counts from now', () {
      expect(_trigger('in:20m'), OnceAt(_now.add(const Duration(minutes: 20))));
    });

    test('at: reads an ISO time, without an offset as UTC', () {
      expect(
        _trigger('at:2026-11-20T09:00:00Z'),
        OnceAt(DateTime.utc(2026, 11, 20, 9)),
      );
      expect(
        _trigger('at:2026-11-20T09:00'),
        OnceAt(DateTime.utc(2026, 11, 20, 9)),
      );
      expect(
        _trigger('at:2026-11-20T10:00:00+01:00'),
        OnceAt(DateTime.utc(2026, 11, 20, 9)),
      );
      expect(_trigger('at:2026-11-21'), OnceAt(DateTime.utc(2026, 11, 21)));
    });

    test('at: in the past is refused', () {
      expect(
        _refusal('at:2026-11-19T09:00:00Z'),
        contains('not in the future'),
      );
    });

    test('every: is an interval; under a minute is its own reading', () {
      expect(_trigger('every:30m'), Every(const Duration(minutes: 30)));
      final short = parseWakeWhen('every:30s', now: _now);
      expect(short, isA<WakeWhenTooShort>());
      expect((short as WakeWhenTooShort).interval, const Duration(seconds: 30));
    });

    test('cron: takes five fields and a zone, UTC by default', () {
      expect(_trigger('cron:0 9 * * 1-5'), Cron('0 9 * * 1-5', 'UTC'));
      expect(
        _trigger('cron:0 9 * * 1-5', tz: 'Europe/Berlin'),
        Cron('0 9 * * 1-5', 'Europe/Berlin'),
      );
      expect(_refusal('cron:0 9 * *'), contains('five-field'));
      expect(_refusal('cron:0 0 30 2 *'), contains('never matches'));
      expect(
        _refusal('cron:0 9 * * *', tz: 'Mars/Olympus'),
        contains('IANA time zone'),
      );
    });

    test('next is self-paced', () {
      expect(parseWakeWhen('next', now: _now), isA<WakeWhenNext>());
    });

    test('on: names a watch; ticket and pipeline runs name their id', () {
      expect(_trigger('on:pr_checks'), OnEvent(WakeEventKind.prChecks));
      expect(_trigger('on:pr_review'), OnEvent(WakeEventKind.prReview));
      expect(_trigger('on:pr_merged'), OnEvent(WakeEventKind.prMerged));
      expect(_trigger('on:environment'), OnEvent(WakeEventKind.environment));
      expect(
        _trigger('on:ticket:T-1'),
        OnEvent(WakeEventKind.ticket, targetId: 'T-1'),
      );
      expect(
        _trigger('on:pipeline_run:run-9'),
        OnEvent(WakeEventKind.pipelineRun, targetId: 'run-9'),
      );
      expect(_refusal('on:ticket'), contains('on:ticket:<id>'));
      expect(_refusal('on:environment:env-1'), contains('takes no id'));
      expect(_refusal('on:deploy'), contains('is not a watch'));
    });

    test('a pull request watch watches the space\'s own or names one', () {
      final named = _trigger('on:pr_checks:acme/shop-ui#12') as OnEvent;
      expect(
        named,
        OnEvent(WakeEventKind.prChecks, targetId: 'acme/shop-ui#12'),
      );
      expect(named.pullRequest!.names('ACME', 'Shop-UI', 12), isTrue);
      expect(named.pullRequest!.names('acme', 'shop-ui', 13), isFalse);
      expect(
        (_trigger('on:pr_merged:group/sub/api-server#7') as OnEvent)
            .pullRequest
            .toString(),
        'group/sub/api-server#7',
      );
      expect(OnEvent(WakeEventKind.prReview).pullRequest, isNull);
      for (final bad in ['on:pr_checks:12', 'on:pr_review:acme/shop-ui']) {
        expect(_refusal(bad), contains('owner/name#number'));
      }
      expect(formatWakeWhen(named), 'on:pr_checks:acme/shop-ui#12');
    });

    test('an unknown form shows the whole grammar', () {
      expect(_refusal('soon'), contains(wakeWhenGrammar));
      expect(_refusal('later:5m'), contains(wakeWhenGrammar));
    });

    test('formats every trigger back into the grammar', () {
      for (final when in [
        'every:20m',
        'cron:0 9 * * 1-5',
        'on:pr_checks',
        'on:ticket:T-1',
      ]) {
        expect(formatWakeWhen(_trigger(when)), when);
      }
      expect(formatWakeWhen(const SelfPaced()), 'next');
      expect(
        formatWakeWhen(OnceAt(DateTime.utc(2026, 11, 20, 9))),
        'at:2026-11-20T09:00:00.000Z',
      );
      expect(
        formatWakeZone(Cron('0 9 * * *', 'Europe/Berlin')),
        'Europe/Berlin',
      );
      expect(formatWakeZone(Cron('0 9 * * *', 'UTC')), isNull);
    });
  });
}
