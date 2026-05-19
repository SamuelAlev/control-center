import 'package:control_center/features/pipelines/domain/entities/pipeline_trigger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PipelineTrigger', () {
    final now = DateTime(2025, 1, 1);

    PipelineTrigger trigger0({
      String eventType = 'ExternalPrDetected',
      String templateId = 'tpl',
      String workspaceId = 'ws',
      bool enabled = false,
      String? cronExpression,
      Map<String, dynamic> match = const {},
      DateTime? lastFiredAt,
    }) =>
        PipelineTrigger(
          id: 'trig-1',
          eventType: eventType,
          templateId: templateId,
          workspaceId: workspaceId,
          enabled: enabled,
          cronExpression: cronExpression,
          match: match,
          lastFiredAt: lastFiredAt,
          createdAt: now,
        );

    test('constructor asserts non-empty eventType and templateId',
        timeout: const Timeout.factor(2), () {
      expect(
        () => PipelineTrigger(
          id: 'x',
          eventType: '',
          templateId: 't',
          workspaceId: 'w',
        ),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => PipelineTrigger(
          id: 'x',
          eventType: 'e',
          templateId: '',
          workspaceId: 'w',
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('createdAt defaults to now when not provided', timeout: const Timeout.factor(2), () {
      final before = DateTime.now();
      final trigger = PipelineTrigger(
        id: 'x',
        eventType: 'e',
        templateId: 't',
        workspaceId: 'w',
      );
      final after = DateTime.now();
      expect(trigger.createdAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(trigger.createdAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('static constants', timeout: const Timeout.factor(2), () {
      expect(PipelineTrigger.scheduleEventType, 'schedule');
      expect(PipelineTrigger.manualEventType, 'manual');
    });

    test('matches returns true for empty filter', timeout: const Timeout.factor(2), () {
      final trigger = trigger0();
      expect(trigger.matches({'anything': 'here'}), isTrue);
      expect(trigger.matches({}), isTrue);
    });

    test('matches returns true when payload matches scalar filter',
        timeout: const Timeout.factor(2), () {
      final trigger = trigger0(match: {'status': 'merged'});
      expect(trigger.matches({'status': 'merged'}), isTrue);
      expect(trigger.matches({'status': 'closed'}), isFalse);
    });

    test('matches returns true when payload value is in list filter',
        timeout: const Timeout.factor(2), () {
      final trigger = trigger0(match: {
        'status': ['merged', 'closed'],
      });
      expect(trigger.matches({'status': 'merged'}), isTrue);
      expect(trigger.matches({'status': 'closed'}), isTrue);
      expect(trigger.matches({'status': 'opened'}), isFalse);
    });

    test('matches returns false when payload key is missing', timeout: const Timeout.factor(2), () {
      final trigger = trigger0(match: {'status': 'merged'});
      expect(trigger.matches({}), isFalse);
    });

    test('matches with multiple filters — all must match', timeout: const Timeout.factor(2), () {
      final trigger = trigger0(match: {
        'status': 'merged',
        'repo': 'acme/app',
      });
      expect(
        trigger.matches({'status': 'merged', 'repo': 'acme/app'}),
        isTrue,
      );
      expect(
        trigger.matches({'status': 'merged', 'repo': 'other'}),
        isFalse,
      );
    });

    test('intervalSeconds parses every:<seconds>', timeout: const Timeout.factor(2), () {
      expect(trigger0(cronExpression: 'every:60').intervalSeconds, 60);
      expect(trigger0(cronExpression: 'every: 300').intervalSeconds, 300);
    });

    test('intervalSeconds returns null for non-interval expressions',
        timeout: const Timeout.factor(2), () {
      expect(trigger0(cronExpression: null).intervalSeconds, isNull);
      expect(trigger0(cronExpression: '0 * * * *').intervalSeconds, isNull);
      expect(trigger0(cronExpression: 'every:abc').intervalSeconds, isNull);
    });

    test('copyWith overrides fields', timeout: const Timeout.factor(2), () {
      final trigger = trigger0();
      final copy = trigger.copyWith(
        enabled: true,
        cronExpression: 'every:60',
        lastFiredAt: now,
      );
      expect(copy.enabled, isTrue);
      expect(copy.cronExpression, 'every:60');
      expect(copy.lastFiredAt, now);
      // Immutable fields preserved
      expect(copy.id, 'trig-1');
      expect(copy.eventType, 'ExternalPrDetected');
    });

    test('equality compares id, eventType, templateId, workspaceId, enabled',
        timeout: const Timeout.factor(2), () {
      final a = trigger0();
      final b = trigger0();
      expect(a, equals(b));
      expect(a.hashCode, equals(b.hashCode));

      final c = trigger0(enabled: true);
      expect(a, isNot(equals(c)));

      final d = trigger0(eventType: 'Other');
      expect(a, isNot(equals(d)));
    });

    test('equality ignores cronExpression, match, lastFiredAt', timeout: const Timeout.factor(2), () {
      final a = trigger0(cronExpression: 'every:60', match: {'x': 1});
      final b = trigger0(cronExpression: null, match: {});
      expect(a, equals(b));
    });
  });
}
