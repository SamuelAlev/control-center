import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_infra/cc_infra.dart';
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
