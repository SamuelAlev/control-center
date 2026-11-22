import 'dart:convert';

import 'package:cc_domain/features/dispatch/domain/value_objects/wake_detail.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_values.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_run_options.dart';
import 'package:cc_domain/features/dispatch/domain/value_objects/wake_trigger.dart';
import 'package:test/test.dart';

void main() {
  group('WakeTrigger', () {
    test('kinds are the stored trigger_kind values', () {
      final triggers = <WakeTrigger>[
        OnceAt(DateTime.utc(2026)),
        Every(const Duration(minutes: 5)),
        Cron('0 9 * * *', 'UTC'),
        const SelfPaced(),
        OnEvent(WakeEventKind.prChecks),
      ];
      expect([for (final t in triggers) t.kind], WakeTrigger.kinds);
      expect(
        [for (final t in triggers) t.repeats],
        [false, true, true, true, true],
      );
    });

    test('OnceAt keeps UTC and compares by instant', () {
      final local = DateTime(2026, 3, 1, 12);
      expect(OnceAt(local).at.isUtc, isTrue);
      expect(OnceAt(local), OnceAt(local.toUtc()));
    });

    test('Every refuses short and fractional intervals', () {
      expect(() => Every(const Duration(seconds: 59)), throwsArgumentError);
      expect(
        () => Every(const Duration(seconds: 90, milliseconds: 1)),
        throwsArgumentError,
      );
      expect(Every(Every.minInterval).interval, Every.minInterval);
    });

    test('Cron needs an expression and a zone', () {
      expect(() => Cron(' ', 'UTC'), throwsArgumentError);
      expect(() => Cron('* * * * *', ''), throwsArgumentError);
      expect(Cron('* * * * *', 'UTC'), Cron('* * * * *', 'UTC'));
      expect(Cron('* * * * *', 'UTC'), isNot(Cron('* * * * *', 'Asia/Tokyo')));
    });

    test('OnEvent targets exactly the kinds that need one', () {
      expect(() => OnEvent(WakeEventKind.ticket), throwsArgumentError);
      expect(
        () => OnEvent(WakeEventKind.pipelineRun, targetId: ''),
        throwsArgumentError,
      );
      expect(
        () => OnEvent(WakeEventKind.prMerged, targetId: 'x'),
        throwsArgumentError,
      );
      expect(
        OnEvent(WakeEventKind.ticket, targetId: 't-1'),
        OnEvent(WakeEventKind.ticket, targetId: 't-1'),
      );
      expect(const SelfPaced(), const SelfPaced());
    });
  });

  group('WakeDetail', () {
    final full = WakeDetail(
      goalId: 'g',
      ruleId: 'r',
      slot: DateTime(2026, 4, 1, 9),
      askId: 'a',
      ticketId: 't',
      pipelineRunId: 'p',
      sourceAgentId: 'sa',
      sourceRunId: 'sr',
      sourceConversationId: 'sc',
      messageId: 'm',
      eventKind: WakeEventKind.environment,
      status: 'failed',
      fields: const {
        'pr': 12,
        'labels': ['a', 'b'],
        'nested': {'ok': true},
      },
    );

    test('round-trips through its column', () {
      expect(WakeDetail.tryParse(full.encode()), full);
      expect(full.slot!.isUtc, isTrue);
      expect(full.isEmpty, isFalse);
    });

    test('omits unset fields', () {
      expect(WakeDetail(goalId: 'g').toJson(), {'goalId': 'g'});
      expect(WakeDetail.empty.toJson(), isEmpty);
      expect(WakeDetail.empty.isEmpty, isTrue);
    });

    test('malformed input degrades instead of throwing', () {
      expect(WakeDetail.tryParse(null), WakeDetail.empty);
      expect(WakeDetail.tryParse('not json'), WakeDetail.empty);
      expect(WakeDetail.tryParse('[1, 2]'), WakeDetail.empty);
      final partial = WakeDetail.tryParse(
        jsonEncode({
          'goalId': 7,
          'ruleId': 'r',
          'eventKind': 'meteor',
          'slot': 'yesterday',
          'fields': 'nope',
        }),
      );
      expect(partial, WakeDetail(ruleId: 'r'));
    });

    test('refuses fields that are not JSON', () {
      expect(
        () => WakeDetail(fields: {'when': DateTime(2026)}),
        throwsArgumentError,
      );
      expect(
        () => WakeDetail(fields: const {'n': double.nan}),
        throwsArgumentError,
      );
    });

    test('equality is deep over fields', () {
      expect(
        WakeDetail(
          fields: const {
            'a': [1],
          },
        ),
        WakeDetail(
          fields: const {
            'a': [1],
          },
        ),
      );
      expect(
        WakeDetail(
          fields: const {
            'a': [1],
          },
        ).hashCode,
        WakeDetail(
          fields: const {
            'a': [1],
          },
        ).hashCode,
      );
      expect(
        WakeDetail(
          fields: const {
            'a': [1],
          },
        ),
        isNot(
          WakeDetail(
            fields: const {
              'a': [2],
            },
          ),
        ),
      );
    });

    test('copyWith keeps and replaces', () {
      final copy = full.copyWith(goalId: 'g2');
      expect(copy.goalId, 'g2');
      expect(copy.ruleId, 'r');
    });
  });

  group('WakeRunOptions', () {
    test('round-trips through its column', () {
      final options = WakeRunOptions(
        freshHistory: true,
        readOnly: true,
        costCapMicros: 250000,
        outputSchema: const {'type': 'object'},
      );
      expect(WakeRunOptions.tryParse(options.encode()), options);
    });

    test('refuses a non-positive cap and a non-JSON schema', () {
      expect(() => WakeRunOptions(costCapMicros: 0), throwsArgumentError);
      expect(
        () => WakeRunOptions(outputSchema: {'x': Object()}),
        throwsArgumentError,
      );
    });

    test('malformed input reads as the defaults', () {
      expect(WakeRunOptions.tryParse(null), isNull);
      expect(WakeRunOptions.tryParse('{'), isNull);
      expect(WakeRunOptions.tryParse('"text"'), isNull);
      expect(
        WakeRunOptions.tryParse('{"costCapMicros": -3, "readOnly": "yes"}'),
        WakeRunOptions(),
      );
    });
  });
}
