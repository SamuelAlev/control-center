import 'dart:convert';

import 'package:cc_domain/features/dispatch/domain/value_objects/wake_rule_limits.dart';
import 'package:test/test.dart';

void main() {
  test('the defaults are the plan\'s numbers', () {
    final d = WakeRuleLimits.defaults;
    expect(d.perConversation, 10);
    expect(d.perAgent, 50);
    expect(d.perWorkspace, 500);
    expect(d.costCapMicros, 50000000);
    expect(d.defaultTimeZone, 'UTC');
    expect(WakeRuleBounds.agentDefaultExpiry, const Duration(days: 7));
    expect(WakeRuleBounds.agentMaxExpiry, const Duration(days: 30));
    expect(WakeRuleBounds.personDefaultExpiry, const Duration(days: 30));
    expect(WakeRuleBounds.personMaxExpiry, const Duration(days: 365));
    expect(WakeRuleBounds.agentDefaultMaxRuns, 50);
    expect(WakeRuleBounds.maxRunsCeiling, 500);
    expect(WakeRuleBounds.watchDefaultMaxRuns, 10);
  });

  test('round-trips through the stored JSON', () {
    final limits = WakeRuleLimits(
      perConversation: 3,
      perAgent: 7,
      perWorkspace: 40,
      costCapMicros: 1000000,
      defaultTimeZone: 'Europe/Berlin',
    );
    expect(WakeRuleLimits.fromSetting(jsonEncode(limits.toJson())), limits);
    expect(limits.toJson(), {
      'per_conversation': 3,
      'per_agent': 7,
      'per_workspace': 40,
      'cost_cap_micros': 1000000,
      'default_time_zone': 'Europe/Berlin',
    });
  });

  test('a missing key keeps its default', () {
    expect(
      WakeRuleLimits.fromJson(const {'per_agent': 9}),
      WakeRuleLimits(perAgent: 9),
    );
  });

  test('refuses values out of range', () {
    expect(() => WakeRuleLimits(perConversation: 0), throwsArgumentError);
    expect(() => WakeRuleLimits(perAgent: 1001), throwsArgumentError);
    expect(() => WakeRuleLimits(perWorkspace: 10001), throwsArgumentError);
    expect(
      () => WakeRuleLimits(costCapMicros: 10000000001),
      throwsArgumentError,
    );
    expect(() => WakeRuleLimits(defaultTimeZone: ' '), throwsArgumentError);
    expect(
      () => WakeRuleLimits.fromJson(const {'per_agent': 'many'}),
      throwsFormatException,
    );
  });

  test('an unreadable stored row reads as the defaults, not as no caps', () {
    expect(WakeRuleLimits.fromSetting(null), WakeRuleLimits.defaults);
    expect(WakeRuleLimits.fromSetting('not json'), WakeRuleLimits.defaults);
    expect(
      WakeRuleLimits.fromSetting('{"per_agent": -4}'),
      WakeRuleLimits.defaults,
    );
  });
}
