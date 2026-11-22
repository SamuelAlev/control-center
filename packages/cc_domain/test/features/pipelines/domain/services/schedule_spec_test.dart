import 'package:cc_domain/features/dispatch/domain/entities/wake_rule.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:cc_domain/features/pipelines/domain/services/pipeline_cron_scheduler.dart';
import 'package:cc_domain/features/pipelines/domain/services/schedule_spec.dart';
import 'package:test/test.dart';

final _t0 = DateTime.utc(2026, 11, 19, 10, 7);

WakeRule _rule(WakeTrigger trigger) => WakeRule(
  id: 'r',
  workspaceId: 'ws',
  spaceId: 'sp',
  conversationId: 'c',
  agentId: 'a',
  trigger: trigger,
  note: 'n',
  costCapMicros: 100,
  expiresAt: _t0.add(const Duration(days: 7)),
  origin: WakeRuleOrigin.agent,
  createdAt: _t0,
  updatedAt: _t0,
);

void main() {
  final scheduler = PipelineCronScheduler();

  test('a pipeline trigger and a wake rule are both schedule specs', () {
    final trigger = PipelineTrigger(
      id: 't',
      eventType: 'schedule',
      templateId: 'tpl',
      workspaceId: 'ws',
      cronExpression: '*/20 * * * *',
    );
    expect(trigger, isA<ScheduleSpec>());
    expect(_rule(Every(const Duration(minutes: 20))), isA<ScheduleSpec>());
  });

  test('an every: rule reads its interval and has no cron', () {
    final rule = _rule(Every(const Duration(minutes: 20)));
    expect(rule.intervalSeconds, 1200);
    expect(rule.cronSchedule, isNull);
    expect(rule.timezone, isNull);
  });

  test('a cron: rule reads its expression and zone', () {
    final rule = _rule(Cron('0 9 * * 1-5', 'Europe/Berlin'));
    expect(rule.intervalSeconds, isNull);
    expect(rule.cronSchedule?.expression, '0 9 * * 1-5');
    expect(rule.timezone, 'Europe/Berlin');
  });

  test('one-offs, loops and watches have no slots', () {
    for (final trigger in <WakeTrigger>[
      OnceAt(_t0.add(const Duration(hours: 1))),
      const SelfPaced(),
      OnEvent(WakeEventKind.prChecks),
    ]) {
      expect(scheduler.nextSlotAfter(_rule(trigger), _t0), isNull);
    }
  });

  test('interval slots are epoch-aligned, like a pipeline trigger\'s', () {
    final rule = _rule(Every(const Duration(minutes: 20)));
    expect(scheduler.slotOf(rule, _t0), DateTime.utc(2026, 11, 19, 10));
    expect(
      scheduler.nextSlotAfter(rule, _t0),
      DateTime.utc(2026, 11, 19, 10, 20),
    );
    // A slot boundary itself is not "after" itself.
    expect(
      scheduler.nextSlotAfter(rule, DateTime.utc(2026, 11, 19, 10, 20)),
      DateTime.utc(2026, 11, 19, 10, 40),
    );
  });

  test('cron slots without converters are read in UTC', () {
    final rule = _rule(Cron('0 9 * * *', 'UTC'));
    expect(scheduler.nextSlotAfter(rule, _t0), DateTime.utc(2026, 11, 20, 9));
  });
}
