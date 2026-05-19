import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:test/test.dart';

/// Covers [PipelineTrigger], the [CronCatchUpPolicy] enum, and the cron/interval
/// parse helpers on the trigger: synthetic event-type constants, the `matches`
/// payload filter (scalar + list semantics, empty = match-all), the
/// `intervalSeconds` / `cronSchedule` accessors for both schedule forms,
/// `isWebhook`, `copyWith` (incl. the `clear*` flags), and value equality.
void main() {
  group('CronCatchUpPolicy', () {
    test('fromName parses each stored name', () {
      expect(
        CronCatchUpPolicy.fromName('catchUpLatestOnly'),
        CronCatchUpPolicy.catchUpLatestOnly,
      );
      expect(CronCatchUpPolicy.fromName('skip'), CronCatchUpPolicy.skip);
    });

    test('fromName defaults to catchUpLatestOnly for null or unknown', () {
      expect(
        CronCatchUpPolicy.fromName(null),
        CronCatchUpPolicy.catchUpLatestOnly,
      );
      expect(
        CronCatchUpPolicy.fromName('nope'),
        CronCatchUpPolicy.catchUpLatestOnly,
      );
    });
  });

  group('PipelineTrigger constants and construction', () {
    test('exposes synthetic event-type constants', () {
      expect(PipelineTrigger.scheduleEventType, 'schedule');
      expect(PipelineTrigger.manualEventType, 'manual');
      expect(PipelineTrigger.webhookEventType, 'webhook');
    });

    test('round-trips every field through the constructor', () {
      final createdAt = DateTime.utc(2026, 1, 1);
      final trigger = PipelineTrigger(
        id: 't1',
        eventType: 'ExternalPrDetected',
        templateId: 'tpl',
        workspaceId: 'ws',
        enabled: true,
        cronExpression: '0 9 * * *',
        timezone: 'America/New_York',
        nextRunAt: DateTime.utc(2026, 7, 13, 9),
        webhookToken: 'tok',
        eventFilters: const {
          'events': ['push'],
        },
        match: const {
          'status': ['merged'],
        },
        lastFiredAt: DateTime.utc(2026, 7, 12),
        catchUpPolicy: CronCatchUpPolicy.skip,
        createdAt: createdAt,
      );
      expect(trigger.id, 't1');
      expect(trigger.eventType, 'ExternalPrDetected');
      expect(trigger.templateId, 'tpl');
      expect(trigger.workspaceId, 'ws');
      expect(trigger.enabled, isTrue);
      expect(trigger.cronExpression, '0 9 * * *');
      expect(trigger.timezone, 'America/New_York');
      expect(trigger.nextRunAt, DateTime.utc(2026, 7, 13, 9));
      expect(trigger.webhookToken, 'tok');
      expect(trigger.eventFilters, {
        'events': ['push'],
      });
      expect(trigger.match, {
        'status': ['merged'],
      });
      expect(trigger.lastFiredAt, DateTime.utc(2026, 7, 12));
      expect(trigger.catchUpPolicy, CronCatchUpPolicy.skip);
      expect(trigger.createdAt, createdAt);
    });

    test('defaults optional fields and stamps createdAt when omitted', () {
      final before = DateTime.now();
      final trigger = PipelineTrigger(
        id: 't1',
        eventType: 'schedule',
        templateId: 'tpl',
        workspaceId: 'ws',
      );
      final after = DateTime.now();
      expect(trigger.enabled, isFalse);
      expect(trigger.cronExpression, isNull);
      expect(trigger.timezone, isNull);
      expect(trigger.nextRunAt, isNull);
      expect(trigger.webhookToken, isNull);
      expect(trigger.eventFilters, isEmpty);
      expect(trigger.match, isEmpty);
      expect(trigger.lastFiredAt, isNull);
      expect(trigger.catchUpPolicy, CronCatchUpPolicy.catchUpLatestOnly);
      // createdAt defaults to now when not supplied.
      expect(!trigger.createdAt.isBefore(before), isTrue);
      expect(!trigger.createdAt.isAfter(after), isTrue);
    });

    test('throws when eventType is empty', () {
      expect(
        () => PipelineTrigger(
          id: 't1',
          eventType: '',
          templateId: 'tpl',
          workspaceId: 'ws',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('throws when templateId is empty', () {
      expect(
        () => PipelineTrigger(
          id: 't1',
          eventType: 'schedule',
          templateId: '',
          workspaceId: 'ws',
        ),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('PipelineTrigger.matches payload filter', () {
    PipelineTrigger triggerWith(Map<String, dynamic> match) => PipelineTrigger(
      id: 't1',
      eventType: 'e',
      templateId: 'tpl',
      workspaceId: 'ws',
      match: match,
    );

    test('an empty filter always matches', () {
      final trigger = triggerWith(const {});
      expect(trigger.matches(const {}), isTrue);
      expect(trigger.matches(const {'anything': 1}), isTrue);
    });

    test('a scalar filter matches when the payload value is equal', () {
      final trigger = triggerWith(const {'status': 'open'});
      expect(trigger.matches(const {'status': 'open'}), isTrue);
      expect(trigger.matches(const {'status': 'closed'}), isFalse);
      expect(trigger.matches(const {'other': 'x'}), isFalse);
    });

    test('a list filter matches when the payload value is in the list', () {
      final trigger = triggerWith(const {
        'status': ['merged', 'closed'],
      });
      expect(trigger.matches(const {'status': 'merged'}), isTrue);
      expect(trigger.matches(const {'status': 'closed'}), isTrue);
      expect(trigger.matches(const {'status': 'open'}), isFalse);
    });

    test('every entry must match for a multi-key filter', () {
      final trigger = triggerWith(const {
        'status': 'open',
        'repo': ['a', 'b'],
      });
      expect(trigger.matches(const {'status': 'open', 'repo': 'a'}), isTrue);
      expect(trigger.matches(const {'status': 'closed', 'repo': 'a'}), isFalse);
      expect(trigger.matches(const {'status': 'open', 'repo': 'c'}), isFalse);
    });
  });

  group('PipelineTrigger interval and cron accessors', () {
    test('intervalSeconds parses an every:<seconds> expression', () {
      final trigger = PipelineTrigger(
        id: 't1',
        eventType: 'schedule',
        templateId: 'tpl',
        workspaceId: 'ws',
        cronExpression: 'every:300',
      );
      expect(trigger.intervalSeconds, 300);
      expect(trigger.cronSchedule, isNull);
    });

    test('intervalSeconds trims surrounding whitespace around the number', () {
      final trigger = PipelineTrigger(
        id: 't1',
        eventType: 'schedule',
        templateId: 'tpl',
        workspaceId: 'ws',
        cronExpression: 'every:  120 ',
      );
      expect(trigger.intervalSeconds, 120);
    });

    test('intervalSeconds is null for a non-interval expression', () {
      final trigger = PipelineTrigger(
        id: 't1',
        eventType: 'schedule',
        templateId: 'tpl',
        workspaceId: 'ws',
        cronExpression: '0 9 * * *',
      );
      expect(trigger.intervalSeconds, isNull);
    });

    test('intervalSeconds is null when no expression is set', () {
      final trigger = PipelineTrigger(
        id: 't1',
        eventType: 'schedule',
        templateId: 'tpl',
        workspaceId: 'ws',
      );
      expect(trigger.intervalSeconds, isNull);
    });

    test('intervalSeconds is null when the seconds are non-numeric', () {
      final trigger = PipelineTrigger(
        id: 't1',
        eventType: 'schedule',
        templateId: 'tpl',
        workspaceId: 'ws',
        cronExpression: 'every:soon',
      );
      expect(trigger.intervalSeconds, isNull);
    });

    test('cronSchedule parses a 5-field cron expression', () {
      final trigger = PipelineTrigger(
        id: 't1',
        eventType: 'schedule',
        templateId: 'tpl',
        workspaceId: 'ws',
        cronExpression: '*/15 * * * *',
      );
      final schedule = trigger.cronSchedule!;
      expect(schedule.minutes, {0, 15, 30, 45});
      expect(trigger.intervalSeconds, isNull);
    });

    test('cronSchedule is null for an interval expression', () {
      final trigger = PipelineTrigger(
        id: 't1',
        eventType: 'schedule',
        templateId: 'tpl',
        workspaceId: 'ws',
        cronExpression: 'every:300',
      );
      expect(trigger.cronSchedule, isNull);
    });

    test('cronSchedule is null when no expression is set', () {
      final trigger = PipelineTrigger(
        id: 't1',
        eventType: 'schedule',
        templateId: 'tpl',
        workspaceId: 'ws',
      );
      expect(trigger.cronSchedule, isNull);
    });
  });

  group('PipelineTrigger.isWebhook', () {
    PipelineTrigger t({required String eventType, String? webhookToken}) =>
        PipelineTrigger(
          id: 't1',
          eventType: eventType,
          templateId: 'tpl',
          workspaceId: 'ws',
          webhookToken: webhookToken,
        );

    test('true when the synthetic webhook event type is used', () {
      expect(t(eventType: 'webhook').isWebhook, isTrue);
    });

    test('true when a non-empty webhook token is present', () {
      expect(t(eventType: 'e', webhookToken: 'tok').isWebhook, isTrue);
    });

    test('false when neither condition holds', () {
      expect(t(eventType: 'e').isWebhook, isFalse);
    });

    test('false when the webhook token is empty', () {
      expect(t(eventType: 'e', webhookToken: '').isWebhook, isFalse);
    });
  });

  group('PipelineTrigger.copyWith', () {
    final base = PipelineTrigger(
      id: 't1',
      eventType: 'e',
      templateId: 'tpl',
      workspaceId: 'ws',
      enabled: true,
      nextRunAt: DateTime.utc(2026, 7, 13, 9),
      lastFiredAt: DateTime.utc(2026, 7, 12),
      catchUpPolicy: CronCatchUpPolicy.catchUpLatestOnly,
    );

    test('a no-op copyWith is equal to the original', () {
      expect(base.copyWith(), base);
    });

    test('overrides each scalar field independently', () {
      expect(base.copyWith(enabled: false).enabled, isFalse);
      expect(
        base.copyWith(cronExpression: '0 0 * * *').cronExpression,
        '0 0 * * *',
      );
      expect(base.copyWith(timezone: 'UTC').timezone, 'UTC');
      expect(
        base.copyWith(nextRunAt: DateTime.utc(2026, 8, 1)).nextRunAt,
        DateTime.utc(2026, 8, 1),
      );
      expect(base.copyWith(webhookToken: 'w').webhookToken, 'w');
      expect(base.copyWith(eventFilters: const {'a': 1}).eventFilters, {
        'a': 1,
      });
      expect(base.copyWith(match: const {'b': 2}).match, {'b': 2});
      expect(
        base.copyWith(lastFiredAt: DateTime.utc(2026, 7, 1)).lastFiredAt,
        DateTime.utc(2026, 7, 1),
      );
      expect(
        base.copyWith(catchUpPolicy: CronCatchUpPolicy.skip).catchUpPolicy,
        CronCatchUpPolicy.skip,
      );
    });

    test('preserves identity fields and untouched fields', () {
      final next = base.copyWith(enabled: false);
      expect(next.id, 't1');
      expect(next.eventType, 'e');
      expect(next.templateId, 'tpl');
      expect(next.workspaceId, 'ws');
      expect(next.nextRunAt, DateTime.utc(2026, 7, 13, 9));
      expect(next.lastFiredAt, DateTime.utc(2026, 7, 12));
      expect(next.catchUpPolicy, CronCatchUpPolicy.catchUpLatestOnly);
    });

    test('clearNextRunAt resets nextRunAt to null', () {
      final next = base.copyWith(clearNextRunAt: true);
      expect(next.nextRunAt, isNull);
    });

    test('clearLastFiredAt resets lastFiredAt to null', () {
      final next = base.copyWith(clearLastFiredAt: true);
      expect(next.lastFiredAt, isNull);
    });

    test('clear flags take precedence over a supplied value', () {
      final next = base.copyWith(
        nextRunAt: DateTime.utc(2030, 1, 1),
        lastFiredAt: DateTime.utc(2030, 1, 1),
        clearNextRunAt: true,
        clearLastFiredAt: true,
      );
      expect(next.nextRunAt, isNull);
      expect(next.lastFiredAt, isNull);
    });
  });

  group('PipelineTrigger equality and hashCode', () {
    test('equal by the identity-and-status subset of fields', () {
      final createdAt = DateTime.utc(2026, 1, 1);
      final a = PipelineTrigger(
        id: 't1',
        eventType: 'e',
        templateId: 'tpl',
        workspaceId: 'ws',
        enabled: true,
        createdAt: createdAt,
      );
      final b = PipelineTrigger(
        id: 't1',
        eventType: 'e',
        templateId: 'tpl',
        workspaceId: 'ws',
        enabled: true,
        // Other fields differ, but equality keys on the first five.
        cronExpression: '0 0 * * *',
        webhookToken: 'w',
        createdAt: createdAt,
      );
      expect(a, b);
      expect(a.hashCode, b.hashCode);
    });

    test('differ when any equality field changes', () {
      final a = PipelineTrigger(
        id: 't1',
        eventType: 'e',
        templateId: 'tpl',
        workspaceId: 'ws',
        enabled: true,
      );
      expect(
        a ==
            PipelineTrigger(
              id: 'other',
              eventType: 'e',
              templateId: 'tpl',
              workspaceId: 'ws',
            ),
        isFalse,
      );
      expect(
        a ==
            PipelineTrigger(
              id: 't1',
              eventType: 'other',
              templateId: 'tpl',
              workspaceId: 'ws',
            ),
        isFalse,
      );
      expect(
        a ==
            PipelineTrigger(
              id: 't1',
              eventType: 'e',
              templateId: 'other',
              workspaceId: 'ws',
            ),
        isFalse,
      );
      expect(
        a ==
            PipelineTrigger(
              id: 't1',
              eventType: 'e',
              templateId: 'tpl',
              workspaceId: 'other',
            ),
        isFalse,
      );
      expect(
        a ==
            PipelineTrigger(
              id: 't1',
              eventType: 'e',
              templateId: 'tpl',
              workspaceId: 'ws',
              enabled: false,
            ),
        isFalse,
      );
    });

    test('refuses non-PipelineTrigger operands', () {
      final trigger = PipelineTrigger(
        id: 't1',
        eventType: 'e',
        templateId: 'tpl',
        workspaceId: 'ws',
      );
      expect(trigger == Object(), isFalse);
    });
  });
}
