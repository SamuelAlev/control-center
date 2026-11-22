import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_infra/src/pipelines/timezone_zone_converter.dart';
import 'package:test/test.dart';

void main() {
  final tz = TimezoneZoneConverter.instance;

  test('knows IANA zones and UTC, rejects nonsense', () {
    expect(tz.isKnown('Europe/Berlin'), isTrue);
    expect(tz.isKnown('America/New_York'), isTrue);
    expect(tz.isKnown('UTC'), isTrue);
    expect(tz.isKnown(''), isTrue);
    expect(tz.isKnown('Mars/Olympus_Mons'), isFalse);
  });

  test('knows the backward-link names (the whole IANA list is loaded)', () {
    expect(tz.isKnown('US/Eastern'), isTrue);
    expect(tz.isKnown('Europe/Kiev'), isTrue);
    expect(tz.isKnown('Asia/Calcutta'), isTrue);
  });

  // These fail when the zone data goes back before IANA 2026e. America/Havana
  // (2026f) is not pinned: no `timezone` release carries it yet.
  group('zone data is at least IANA 2026e', () {
    test('British Columbia stays on UTC-7 after 2026-11-01', () {
      final trigger = PipelineTrigger(
        id: 't-bc',
        eventType: PipelineTrigger.scheduleEventType,
        templateId: 'tpl',
        workspaceId: 'ws',
        enabled: true,
        cronExpression: '0 9 * * *',
        timezone: 'America/Vancouver',
        createdAt: DateTime.utc(2026, 11, 22, 18),
      );
      final eval = tz.scheduler().evaluate(
        trigger,
        DateTime.utc(2026, 11, 22, 18),
      );
      // 09:00 on 2026-11-23 is 16:00 UTC (2025c said 17:00, PST).
      expect(eval.nextRunAt, DateTime.utc(2026, 11, 23, 16));
    });

    test('Alberta stays on UTC-6 after 2026-11-01', () {
      expect(
        tz.toUtc(DateTime.utc(2026, 11, 23, 9), 'America/Edmonton'),
        DateTime.utc(2026, 11, 23, 15),
      );
    });

    test('Manitoba stays on UTC-5 after 2026-11-01', () {
      expect(
        tz.toUtc(DateTime.utc(2026, 11, 23, 9), 'America/Winnipeg'),
        DateTime.utc(2026, 11, 23, 14),
      );
    });

    test('Morocco is on UTC+0 after 2026-09-20', () {
      expect(
        tz.toUtc(DateTime.utc(2026, 10, 15, 9), 'Africa/Casablanca'),
        DateTime.utc(2026, 10, 15, 9),
      );
    });
  });

  group('wall times around a DST change', () {
    test('a time in the spring-forward gap moves on by the gap', () {
      // Berlin's 02:00 to 03:00 on 2026-03-29 does not exist: 02:30 is
      // 03:30 CEST.
      expect(
        tz.toUtc(DateTime.utc(2026, 3, 29, 2, 30), 'Europe/Berlin'),
        DateTime.utc(2026, 3, 29, 1, 30),
      );
    });

    test('the repeated hour resolves to the later occurrence east of UTC', () {
      // 02:30 on 2026-10-25 is 00:30Z (CEST) and 01:30Z (CET): the CET one.
      expect(
        tz.toUtc(DateTime.utc(2026, 10, 25, 2, 30), 'Europe/Berlin'),
        DateTime.utc(2026, 10, 25, 1, 30),
      );
    });

    test('the repeated hour resolves to the earlier one west of UTC', () {
      // 01:30 on 2026-11-01 is 05:30Z (EDT) and 06:30Z (EST): the EDT one.
      expect(
        tz.toUtc(DateTime.utc(2026, 11, 1, 1, 30), 'America/New_York'),
        DateTime.utc(2026, 11, 1, 5, 30),
      );
    });
  });

  test('round-trips wall-clock time across DST', () {
    // Berlin is UTC+1 in winter and UTC+2 in summer.
    expect(
      tz.toUtc(DateTime.utc(2026, 1, 15, 9), 'Europe/Berlin'),
      DateTime.utc(2026, 1, 15, 8),
    );
    expect(
      tz.toUtc(DateTime.utc(2026, 7, 15, 9), 'Europe/Berlin'),
      DateTime.utc(2026, 7, 15, 7),
    );
    expect(
      tz.toLocal(DateTime.utc(2026, 7, 15, 7), 'Europe/Berlin'),
      DateTime.utc(2026, 7, 15, 9),
    );
  });

  test('a cron trigger fires at its zone\'s wall-clock time', () {
    final scheduler = tz.scheduler();
    final trigger = PipelineTrigger(
      id: 't1',
      eventType: PipelineTrigger.scheduleEventType,
      templateId: 'tpl',
      workspaceId: 'ws',
      enabled: true,
      cronExpression: '0 9 * * *',
      timezone: 'Europe/Berlin',
      createdAt: DateTime.utc(2026, 7, 14, 12),
    );
    final eval = scheduler.evaluate(trigger, DateTime.utc(2026, 7, 14, 12));
    expect(eval.shouldFire, isFalse);
    // 09:00 CEST on the 15th is 07:00 UTC, not 09:00 UTC.
    expect(eval.nextRunAt, DateTime.utc(2026, 7, 15, 7));
  });
}
