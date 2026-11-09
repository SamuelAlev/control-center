import 'package:cc_domain/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:test/test.dart';

/// Covers [PipelineTrigger], the [CronCatchUpPolicy] enum and the cron/interval
/// parse helpers on the trigger: synthetic event-type constants, the `matches`
/// payload filter (scalar + list semantics, empty = match-all), the
/// `intervalSeconds` / `cronSchedule` accessors for both schedule forms,
/// `isWebhook`, `copyWith` (incl. the `clear*` flags) and value equality.
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
        throwsA(isA<ArgumentError>()),
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
        throwsA(isA<ArgumentError>()),
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
    test('equal when every field matches', () {
      final createdAt = DateTime.utc(2026, 1, 1);
      PipelineTrigger make() => PipelineTrigger(
        id: 't1',
        eventType: 'e',
        templateId: 'tpl',
        workspaceId: 'ws',
        enabled: true,
        cronExpression: '0 0 * * *',
        timezone: 'Europe/Berlin',
        webhookToken: 'w',
        eventFilters: const {
          'status': ['merged'],
        },
        match: const {
          'status': ['merged', 'closed'],
        },
        createdAt: createdAt,
      );
      expect(make(), make());
      expect(make().hashCode, make().hashCode);
    });

    test('covers every field, so an edit is never mistaken for a no-op', () {
      // The editor and the template toggle compare triggers to decide whether
      // a save changed anything; equality on a subset dropped schedule and
      // filter edits.
      final createdAt = DateTime.utc(2026, 1, 1);
      final base = PipelineTrigger(
        id: 't1',
        eventType: 'e',
        templateId: 'tpl',
        workspaceId: 'ws',
        enabled: true,
        createdAt: createdAt,
      );
      final variants = <String, PipelineTrigger>{
        'cronExpression': base.copyWith(cronExpression: '0 0 * * *'),
        'timezone': base.copyWith(timezone: 'Europe/Berlin'),
        'webhookToken': base.copyWith(webhookToken: 'w'),
        'nextRunAt': base.copyWith(nextRunAt: DateTime.utc(2026, 2)),
        'lastFiredAt': base.copyWith(lastFiredAt: DateTime.utc(2026, 2)),
        'match': base.copyWith(match: const {'status': 'merged'}),
        'catchUpPolicy': base.copyWith(catchUpPolicy: CronCatchUpPolicy.skip),
        'eventFilters': base.copyWith(
          eventFilters: const {
            'status': ['merged'],
          },
        ),
      };
      for (final entry in variants.entries) {
        expect(entry.value == base, isFalse, reason: entry.key);
      }
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
  group('PipelineTrigger.scheduleError', () {
    PipelineTrigger sched(String? expr) => PipelineTrigger(
      id: 't',
      eventType: PipelineTrigger.scheduleEventType,
      templateId: 'tpl',
      workspaceId: 'ws',
      cronExpression: expr,
    );

    test('accepts a positive interval and a satisfiable cron', () {
      expect(sched('every:60').scheduleError, isNull);
      expect(sched('0 9 * * 1-5').scheduleError, isNull);
    });

    test('rejects empty, non-positive, unparsable and unsatisfiable', () {
      for (final bad in [
        null,
        '  ',
        'every:0',
        'every:-1',
        'every:abc',
        'not a cron',
        '0 0 31 2 *',
      ]) {
        expect(sched(bad).scheduleError, isNotNull, reason: '$bad');
      }
    });

    test('does not apply to non-scheduled triggers', () {
      expect(
        PipelineTrigger(
          id: 't',
          eventType: 'TicketAssigned',
          templateId: 'tpl',
          workspaceId: 'ws',
        ).scheduleError,
        isNull,
      );
    });
  });
}
